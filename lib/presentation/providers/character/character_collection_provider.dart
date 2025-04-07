import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/services/character/character_service.dart';
import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/character_region_state.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../domain/models/character/undo_action.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../viewmodels/states/character_collection_state.dart';
import 'selected_region_provider.dart';
import 'tool_mode_provider.dart';

final characterCollectionProvider = StateNotifierProvider<
    CharacterCollectionNotifier, CharacterCollectionState>((ref) {
  final characterService = ref.watch(characterServiceProvider);
  final toolModeNotifier = ref.watch(toolModeProvider.notifier);
  final selectedRegionNotifier = ref.watch(selectedRegionProvider.notifier);

  return CharacterCollectionNotifier(
    characterService: characterService,
    toolModeNotifier: toolModeNotifier,
    selectedRegionNotifier: selectedRegionNotifier,
  );
});

class CharacterCollectionNotifier
    extends StateNotifier<CharacterCollectionState> {
  final CharacterService _characterService;
  final ToolModeNotifier _toolModeNotifier;
  final SelectedRegionNotifier _selectedRegionNotifier;

  Uint8List? _currentPageImage;
  String? _currentWorkId;
  String? _currentPageId;

  CharacterCollectionNotifier({
    required CharacterService characterService,
    required ToolModeNotifier toolModeNotifier,
    required SelectedRegionNotifier selectedRegionNotifier,
  })  : _characterService = characterService,
        _toolModeNotifier = toolModeNotifier,
        _selectedRegionNotifier = selectedRegionNotifier,
        super(CharacterCollectionState.initial());

  // 添加区域到多选集合中
  void addToSelection(String id) {
    if (state.regions.any((r) => r.id == id)) {
      final updatedSelectedIds = {...state.selectedIds, id};

      state = state.copyWith(
        selectedIds: updatedSelectedIds,
      );
    }
  }

  // 取消编辑
  void cancelEdit() {
    _selectedRegionNotifier.clearRegion();
    state =
        state.copyWith(currentId: null, selectedIds: {}, isAdjusting: false);
  }

  // 清除错误消息
  void clearError() {
    state = state.copyWith(error: null);
  }

// 清理已选择的区域
  void clearSelectedRegions() {
    _selectedRegionNotifier.clearRegion();
    state = state.copyWith(
      currentId: null,
      selectedIds: {},
    );
  }

// 多选功能：清除所有选择
  void clearSelections() {
    state = state.copyWith(selectedIds: {});
  }

  // 清理所有状态
  void clearState() {
    _currentPageImage = null;
    _currentWorkId = null;
    _currentPageId = null;
    _selectedRegionNotifier.clearRegion();
    state = CharacterCollectionState.initial();
  }

  /// 创建新的框选区域
  /// 1. 验证必要条件
  /// 2. 创建新区域并处理选区状态
  /// 3. 记录操作以支持撤销
  CharacterRegion? createRegion(Rect rect) {
    try {
      // 1. 验证条件
      if (_currentPageId == null) {
        throw Exception('当前页面ID未设置，无法创建选区');
      }
      if (_currentPageImage == null) {
        throw Exception('当前页面图像未设置，无法创建选区');
      }
      if (rect.width < 20 || rect.height < 20) {
        throw Exception('选区尺寸过小，最小尺寸为20x20');
      }

      AppLogger.debug('开始创建新选区', data: {
        'rect': '${rect.left.toStringAsFixed(1)},'
            '${rect.top.toStringAsFixed(1)},'
            '${rect.width.toStringAsFixed(1)}x'
            '${rect.height.toStringAsFixed(1)}',
        'pageId': _currentPageId,
      });

      // 2. 创建新区域
      final region = CharacterRegion.create(
        pageId: _currentPageId!,
        rect: rect,
        options: const ProcessingOptions(),
      );

      // 清理现有选择状态
      _selectedRegionNotifier.clearRegion();

      // 设置新的选中区域并立即进入可调节状态
      _selectedRegionNotifier.setRegion(region);

      // 更新区域列表和状态
      final updatedRegions = [...state.regions, region];

      // 将新创建的区域标记为未保存
      final modifiedIds = {...state.modifiedIds, region.id};

      state = state.copyWith(
        regions: updatedRegions,
        currentId: region.id,
        selectedIds: {region.id}, // 更新多选状态
        modifiedIds: modifiedIds, // 更新修改状态
        isAdjusting: true, // 立即进入可调节状态
      );

      AppLogger.debug('新选区创建完成', data: {
        'regionId': region.id,
        'totalRegions': updatedRegions.length,
      });

      return region;
    } catch (e, stack) {
      AppLogger.error('创建选区失败',
          error: e, stackTrace: stack, data: {'rect': rect.toString()});

      state = state.copyWith(
        error: '创建选区失败: ${e.toString()}',
      );
      return null;
    }
  }

  // 批量删除区域
  Future<void> deleteBatchRegions(List<String> ids) async {
    if (ids.isEmpty) return;

    try {
      state = state.copyWith(processing: true);

      // 保存被删除的区域以便撤销
      final deletedRegions =
          state.regions.where((r) => ids.contains(r.id)).toList();

      // 删除区域
      await _characterService.deleteBatchCharacters(ids);

      // 更新区域列表
      final updatedRegions =
          state.regions.where((r) => !ids.contains(r.id)).toList();

      // 批量撤销操作
      final batchActions =
          deletedRegions.map((r) => UndoAction.delete(r.id, r)).toList();
      final undoAction = UndoAction.batch(batchActions);
      final undoStack = [...state.undoStack, undoAction];

      // 如果删除了当前选中的区域，则清除选中状态
      final newCurrentId =
          ids.contains(state.currentId) ? null : state.currentId;
      if (newCurrentId == null) {
        _selectedRegionNotifier.clearRegion();
      }

      state = state.copyWith(
        regions: updatedRegions,
        currentId: newCurrentId,
        undoStack: undoStack,
        processing: false,
        selectedIds: {},
      );
    } catch (e) {
      state = state.copyWith(
        processing: false,
        error: e.toString(),
      );
    }
  }

  // 删除区域
  Future<void> deleteRegion(String id) async {
    try {
      state = state.copyWith(processing: true);

      // 保存被删除的区域以便撤销
      final deletedRegion = state.regions.firstWhere((r) => r.id == id);

      // 删除区域
      await _characterService.deleteCharacter(id);

      // 更新区域列表
      final updatedRegions = state.regions.where((r) => r.id != id).toList();

      // 添加撤销操作
      final undoAction = UndoAction.delete(id, deletedRegion);
      final undoStack = [...state.undoStack, undoAction];

      // 如果删除的是当前选中的区域，则清除选中状态
      final newCurrentId = state.currentId == id ? null : state.currentId;
      if (newCurrentId == null) {
        _selectedRegionNotifier.clearRegion();
      }

      state = state.copyWith(
        regions: updatedRegions,
        currentId: newCurrentId,
        undoStack: undoStack,
        processing: false,
      );
    } catch (e) {
      state = state.copyWith(
        processing: false,
        error: e.toString(),
      );
    }
  }

  /// 完成当前的调整操作 (Likely called when clicking blank area or changing tool)
  void finishCurrentAdjustment() {
    // Only finish adjustment if we are actually adjusting something
    if (!state.isAdjusting || state.currentId == null) return;

    final currentRegionId = state.currentId!;
    AppLogger.debug('Finishing Adjustment (Provider)', data: {
      'currentId': currentRegionId,
      'isAdjusting': state.isAdjusting,
      'selectedIds': state.selectedIds.toString(),
      'modifiedIds': state.modifiedIds.toList(),
    });

    // Find the region that *was* being adjusted
    final matchingAdjustedRegions =
        state.regions.where((r) => r.id == currentRegionId).toList();
    final CharacterRegion? adjustedRegion = matchingAdjustedRegions.isNotEmpty
        ? matchingAdjustedRegions.first
        : null;

    // 检查是否真的做了内容修改
    // 如果没有实际内容修改，从modifiedIds中移除
    final Set<String> updatedModifiedIds = {...state.modifiedIds};
    if (adjustedRegion != null &&
        updatedModifiedIds.contains(currentRegionId)) {
      // 查找原始区域以比较是否有实际内容变化
      final originalRegion = _findOriginalRegion(currentRegionId);
      if (originalRegion != null &&
          _isRegionUnchanged(originalRegion, adjustedRegion)) {
        updatedModifiedIds.remove(currentRegionId);
        AppLogger.debug('区域未实际修改，从modifiedIds中移除', data: {
          'regionId': currentRegionId,
          'isSaved': adjustedRegion.isSaved,
        });
      }
    }

    // Reset state: Exit adjusting, clear selection. isSaved status determines color via painter.
    state = state.copyWith(
      isAdjusting: false,
      currentId: null,
      selectedIds: {},
      modifiedIds: updatedModifiedIds, // 更新修改状态
    );

    AppLogger.debug('Finished Adjustment - State Reset (Provider)', data: {
      'regionId': currentRegionId,
      'newState_isAdjusting': state.isAdjusting,
      'newState_currentId': state.currentId,
      'newState_selectedIds': state.selectedIds.toString(),
      'newState_modifiedIds': state.modifiedIds.toList(),
    });

    // Potentially trigger a save action if it was modified? Or rely on user action?
    // Current design implies it just transitions to Normal (Saved/Unsaved)
  }

  /// 获取区域的视觉状态
  CharacterRegionState getRegionState(String id) {
    final isSelected = state.selectedIds.contains(id);
    final isAdjusting = state.isAdjusting && state.currentId == id;

    if (isAdjusting) {
      return CharacterRegionState.adjusting;
    } else if (isSelected) {
      return CharacterRegionState.selected;
    } else {
      return CharacterRegionState.normal;
    }
  }

  // 获取缩略图路径
  Future<String?> getThumbnailPath(String regionId) async {
    try {
      return await _characterService.getCharacterThumbnailPath(regionId);
    } catch (e) {
      AppLogger.error('获取缩略图路径失败', error: e);
      return null;
    }
  }

  // 加载作品数据
  Future<void> loadWorkData(String workId, {String? pageId}) async {
    AppLogger.debug('开始加载选区数据', data: {
      'workId': workId,
      'pageId': pageId,
      'hasCurrentImage': _currentPageImage != null,
    });

    // 清理现有状态
    state = state.copyWith(
      loading: true,
      error: null,
      selectedIds: {}, // 清除选中状态
      currentId: null, // 清除当前选中区域
      regions: [], // 清空区域列表
    );
    _selectedRegionNotifier.clearRegion(); // 清除选中区域

    try {
      // 更新当前上下文
      _currentWorkId = workId;
      _currentPageId = pageId;

      if (_currentPageImage == null) {
        throw Exception('页面图像未设置，无法加载选区数据');
      }

      // 加载区域数据
      AppLogger.debug('从数据库加载选区数据', data: {
        'pageId': pageId ?? 'null',
      });

      final regions = await _characterService.getPageRegions(pageId ?? '');

      AppLogger.debug('选区数据加载完成', data: {
        'regionsCount': regions.length,
        'workId': workId,
        'pageId': pageId,
      });

      // 更新状态
      state = state.copyWith(
        workId: workId,
        pageId: pageId,
        regions: regions,
        loading: false,
      );
    } catch (e, stack) {
      AppLogger.error('加载选区数据失败', error: e, stackTrace: stack, data: {
        'workId': workId,
        'pageId': pageId,
      });

      // 更新错误状态
      state = state.copyWith(
        loading: false,
        error: '加载选区数据失败: ${e.toString()}',
        regions: [], // 确保清空区域列表
      );
    }
  }

  /// 标记区域为已修改
  void markAsModified(String id) {
    if (!state.regions.any((r) => r.id == id)) return;

    state = state.copyWith(
      modifiedIds: {...state.modifiedIds, id},
    );
  }

  /// 标记区域为已保存
  void markAsSaved(String id) {
    AppLogger.debug('尝试标记区域为已保存', data: {
      'regionId': id,
      'currentlyModified': state.modifiedIds.contains(id),
    });

    if (!state.modifiedIds.contains(id)) return;

    final updatedModifiedIds = {...state.modifiedIds}..remove(id);

    // 更新区域的保存状态
    final index = state.regions.indexWhere((r) => r.id == id);
    List<CharacterRegion> updatedRegions = [...state.regions];
    if (index >= 0) {
      final oldRegion = updatedRegions[index];
      updatedRegions[index] = updatedRegions[index].copyWith(isSaved: true);
      AppLogger.debug('更新区域列表中的isSaved状态', data: {
        'regionId': id,
        'oldIsSaved': oldRegion.isSaved,
        'newIsSaved': updatedRegions[index].isSaved,
      });
    } else {
      AppLogger.warning('在regions列表中未找到要标记为已保存的区域', data: {'regionId': id});
    }

    final oldModifiedIds = state.modifiedIds;
    state = state.copyWith(
      modifiedIds: updatedModifiedIds,
      regions: updatedRegions, // 确保更新区域列表
    );
    AppLogger.debug('markAsSaved 完成状态更新', data: {
      'regionId': id,
      'previousModifiedIds': oldModifiedIds,
      'currentModifiedIds': state.modifiedIds,
    });
  }

  // 重做操作
  Future<void> redo() async {
    if (state.redoStack.isEmpty) return;

    try {
      state = state.copyWith(processing: true);

      // 获取最后一个重做操作
      final action = state.redoStack.last;
      final redoStack = state.redoStack.sublist(0, state.redoStack.length - 1);
      final undoStack = [...state.undoStack, action];

      switch (action.type) {
        case UndoActionType.create:
          // 重做创建操作 - 恢复创建的区域
          final region = action.data as CharacterRegion;

          if (_currentPageImage == null) {
            throw Exception('当前页面图像为空');
          }
          AppLogger.debug('使用当前页面图像进行重做操作',
              data: {'imageDataLength': _currentPageImage!.length});

          await _characterService.extractCharacter(
            _currentWorkId ?? '',
            region.pageId,
            region.rect,
            region.options,
            _currentPageImage!,
          );
          final updatedRegions = [...state.regions, region];

          state = state.copyWith(
            regions: updatedRegions,
            redoStack: redoStack,
            undoStack: undoStack,
            processing: false,
          );
          break;

        case UndoActionType.delete:
          // 重做删除操作 - 删除区域
          final data = action.data as Map<String, dynamic>;
          final id = data['id'] as String;
          await _characterService.deleteCharacter(id);
          final updatedRegions =
              state.regions.where((r) => r.id != id).toList();

          state = state.copyWith(
            regions: updatedRegions,
            currentId: state.currentId == id ? null : state.currentId,
            redoStack: redoStack,
            undoStack: undoStack,
            processing: false,
          );

          if (state.currentId == null) {
            _selectedRegionNotifier.clearRegion();
          }
          break;

        case UndoActionType.update:
          // 重做更新操作
          // TODO: 实现重做更新的逻辑
          state = state.copyWith(
            redoStack: redoStack,
            undoStack: undoStack,
            processing: false,
          );
          break;

        case UndoActionType.erase:
          // 重做擦除操作
          // TODO: 实现重做擦除的逻辑
          state = state.copyWith(
            redoStack: redoStack,
            undoStack: undoStack,
            processing: false,
          );
          break;

        case UndoActionType.batch:
          // 重做批量操作
          // TODO: 实现重做批量操作的逻辑
          state = state.copyWith(
            redoStack: redoStack,
            undoStack: undoStack,
            processing: false,
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(
        processing: false,
        error: e.toString(),
      );
    }
  }

  /// 请求删除单个区域
  /// 返回一个Future<bool>表示用户是否确认删除
  Future<bool> requestDeleteRegion(String id) async {
    // 这里实际上只是提供一个接口，实际的确认对话框逻辑在UI层实现
    // 返回true表示可以继续删除操作
    return true;
  }

  /// 请求删除选中的区域
  /// 返回一个Future<bool>表示用户是否确认删除
  /// 注意：此方法不执行实际删除，只是提供一个统一的接口来请求删除
  Future<bool> requestDeleteRegions() async {
    if (state.selectedIds.isEmpty) return false;

    // 这里实际上只是提供一个接口，实际的确认对话框逻辑在UI层实现
    // 返回true表示可以继续删除操作
    return true;
  }

  // 保存当前编辑的区域
  Future<void> saveCurrentRegion() async {
    AppLogger.debug('saveCurrentRegion 调用',
        data: {'currentId': state.currentId});
    if (state.currentId == null) return;

    try {
      state = state.copyWith(processing: true);

      final region = _selectedRegionNotifier.getCurrentRegion();
      if (region == null) {
        throw Exception('No region selected');
      }

      // 检查区域是否存在于列表中
      final exists = state.regions.any((r) => r.id == region.id);

      if (exists) {
        // 更新现有区域
        AppLogger.debug('保存现有区域', data: {'regionId': region.id});
        await _characterService.updateCharacter(
          region.id,
          region.copyWith(isSaved: true), // 明确标记为已保存
          region.character,
        );

        // 更新区域列表
        final updatedRegions = [...state.regions];
        final index = updatedRegions.indexWhere((r) => r.id == region.id);
        updatedRegions[index] = region.copyWith(isSaved: true); // 标记为已保存

        // 从已修改集合中移除，表示已保存
        final Set<String> originalModifiedIds = {...state.modifiedIds};
        final modifiedIds = {...state.modifiedIds}..remove(region.id);
        AppLogger.debug('更新modifiedIds (现有区域)', data: {
          'regionId': region.id,
          'beforeRemove': originalModifiedIds.toList(),
          'afterRemove': modifiedIds.toList(),
          'hasBeenRemoved': !modifiedIds.contains(region.id),
        });

        state = state.copyWith(
          regions: updatedRegions,
          processing: false,
          modifiedIds: modifiedIds, // 更新修改状态
          isAdjusting: false, // 退出调整状态
        );
        AppLogger.debug('状态更新完成 (现有区域)', data: {
          'modifiedIdsCount': state.modifiedIds.length,
          'modifiedIds': state.modifiedIds.toList(),
          'hasUnsavedChanges': state.hasUnsavedChanges,
        });

        // 强制创建一个全新的状态对象
        final newState = CharacterCollectionState(
          workId: state.workId,
          pageId: state.pageId,
          regions: List.from(state.regions), // 确保是新列表实例
          selectedIds: Set.from(state.selectedIds),
          modifiedIds: Set.from(state.modifiedIds), // 确保是新 Set 实例
          currentId: state.currentId,
          currentTool: state.currentTool,
          defaultOptions: state.defaultOptions,
          undoStack: List.from(state.undoStack),
          redoStack: List.from(state.redoStack),
          loading: state.loading,
          processing: state.processing,
          error: state.error,
          isAdjusting: state.isAdjusting,
        );
        state = newState;
        AppLogger.debug('强制应用了全新的 State 对象 (现有区域)', data: {
          'modifiedIdsCount': state.modifiedIds.length,
          'modifiedIds': state.modifiedIds.toList(),
          'hasUnsavedChanges': state.hasUnsavedChanges,
        });
      } else {
        // 创建新区域
        AppLogger.debug('创建并保存新区域', data: {'tempRegionId': region.id});
        if (_currentPageImage == null || _currentPageId == null) {
          throw Exception('Page image or ID not available');
        }

        AppLogger.debug('使用当前页面图像创建新区域',
            data: {'imageDataLength': _currentPageImage!.length});

        // 提取并处理字符，明确设置isSaved为true
        final characterEntity = await _characterService.extractCharacter(
          _currentWorkId ?? '',
          _currentPageId!,
          region.rect,
          region.options,
          _currentPageImage!,
          isSaved: true, // 添加参数，确保数据库中也标记为已保存
        );
        AppLogger.debug('数据库操作完成，获取到 CharacterEntity',
            data: {'entityId': characterEntity.id});

        // 更新为正确的ID并标记为已保存
        final newRegion = region.copyWith(
          id: characterEntity.id,
          isSaved: true,
          characterId: characterEntity.id, // 设置关联的Character ID
        );
        AppLogger.debug('创建了新的 Region 对象', data: {
          'newRegionId': newRegion.id,
          'isSaved': newRegion.isSaved,
          'characterId': newRegion.characterId,
        });

        // 更新区域列表
        final updatedRegions = [...state.regions];
        final index =
            updatedRegions.indexWhere((r) => r.id == region.id); // 查找临时 ID
        if (index >= 0) {
          // 替换已存在的临时区域
          AppLogger.debug('替换临时区域',
              data: {'tempId': region.id, 'newId': newRegion.id});
          updatedRegions[index] = newRegion;
        } else {
          // 添加新区域 (理论上创建新区域时，旧的临时ID应该存在)
          AppLogger.warning('未找到要替换的临时区域，直接添加',
              data: {'tempId': region.id, 'newId': newRegion.id});
          updatedRegions.add(newRegion);
        }

        // 从已修改集合中移除，表示已保存
        final Set<String> originalModifiedIds = {...state.modifiedIds};
        final modifiedIds = {...state.modifiedIds}
          ..remove(region.id) // 移除旧的临时ID
          ..remove(newRegion.id); // 移除新的、已保存的ID
        AppLogger.debug('更新modifiedIds (新区域)', data: {
          'tempRegionId': region.id,
          'newRegionId': newRegion.id,
          'beforeRemove': originalModifiedIds.toList(),
          'afterRemove': modifiedIds.toList(),
          'hasBeenRemovedTemp': !modifiedIds.contains(region.id),
          'hasBeenRemovedNew': !modifiedIds.contains(newRegion.id),
        });

        state = state.copyWith(
          regions: updatedRegions,
          currentId: newRegion.id, // 确保当前ID更新为新的ID
          processing: false,
          modifiedIds: modifiedIds, // 更新修改状态
          isAdjusting: false, // 退出调整状态
        );
        AppLogger.debug('状态更新完成 (新区域)', data: {
          'modifiedIdsCount': state.modifiedIds.length,
          'modifiedIds': state.modifiedIds.toList(),
          'hasUnsavedChanges': state.hasUnsavedChanges,
        });
        _selectedRegionNotifier.setRegion(newRegion);
        AppLogger.debug('SelectedRegionProvider 更新完成...');

        // 强制创建一个全新的状态对象
        final newState = CharacterCollectionState(
          workId: state.workId,
          pageId: state.pageId,
          regions: List.from(state.regions), // 确保是新列表实例
          selectedIds: Set.from(state.selectedIds),
          modifiedIds: Set.from(state.modifiedIds), // 确保是新 Set 实例
          currentId: state.currentId,
          currentTool: state.currentTool,
          defaultOptions: state.defaultOptions,
          undoStack: List.from(state.undoStack),
          redoStack: List.from(state.redoStack),
          loading: state.loading,
          processing: state.processing,
          error: state.error,
          isAdjusting: state.isAdjusting,
        );
        state = newState;
        AppLogger.debug('强制应用了全新的 State 对象 (新区域)', data: {
          'modifiedIdsCount': state.modifiedIds.length,
          'modifiedIds': state.modifiedIds.toList(),
          'hasUnsavedChanges': state.hasUnsavedChanges,
        });
      }
    } catch (e) {
      AppLogger.error('保存区域失败', error: e);
      state = state.copyWith(
        processing: false,
        error: e.toString(),
      );
    }
  }

  // 多选功能：选择所有区域
  void selectAll() {
    final selectedIds = state.regions.map((r) => r.id).toSet();
    state = state.copyWith(selectedIds: selectedIds);
  }

  /// 选择指定的区域 (Now only updates the main state)
  /// Relies on _findAndSetSelectedRegion to update the SelectedRegionNotifier.
  void selectRegion(String? id) {
    // 1. Update the SelectedRegionNotifier first (finds the region)
    final region = _findAndSetSelectedRegion(id);

    // 2. Handle main state update
    if (id == null) {
      // If clearing selection, update main state accordingly
      // Also ensure we exit adjusting mode if we were adjusting
      if (state.currentId != null ||
          state.selectedIds.isNotEmpty ||
          state.isAdjusting) {
        // 在清除选择时检查当前区域是否有实际修改
        // 如果当前存在区域且在modifiedIds中
        if (state.currentId != null &&
            state.modifiedIds.contains(state.currentId!)) {
          final currentRegion = state.regions.firstWhere(
              (r) => r.id == state.currentId!,
              orElse: () => null as CharacterRegion);

          final originalRegion = _findOriginalRegion(currentRegion.id);
          if (originalRegion != null &&
              _isRegionUnchanged(originalRegion, currentRegion)) {
            // 如果没有实际修改，从modifiedIds中移除
            final updatedModifiedIds = {...state.modifiedIds}
              ..remove(currentRegion.id);
            state = state.copyWith(
                currentId: null,
                selectedIds: {},
                isAdjusting: false,
                modifiedIds: updatedModifiedIds);
            return;
          }
        }

        state = state.copyWith(
            currentId: null, selectedIds: {}, isAdjusting: false);
        AppLogger.debug('Cleared main selection state and exited adjusting');
      }
    } else if (region != null) {
      // If a valid region was found and set in the notifier, update main state
      // Importantly, this selectRegion call itself DOES NOT enter adjusting mode.
      state = state.copyWith(
        currentId: id,
        selectedIds: {id}, // Only select the single region
        isAdjusting:
            false, // Explicitly set adjusting to false for simple selection
        error: null, // Clear previous error if selection succeeds
      );
      AppLogger.debug('Updated main selection state (not adjusting)',
          data: {'regionId': id});
    }
    // If region is null due to an error, _findAndSetSelectedRegion already updated the error state.
  }

  // 设置调整状态
  void setAdjusting(bool isAdjusting) {
    if (state.isAdjusting != isAdjusting) {
      state = state.copyWith(isAdjusting: isAdjusting);
      AppLogger.debug('Set Adjusting State',
          data: {'isAdjusting': isAdjusting});
    }
  }

  /// 设置当前页面图像
  /// 1. 解码并验证图像数据
  /// 2. 清理现有状态
  /// 3. 更新图像数据
  void setCurrentPageImage(Uint8List imageData) {
    AppLogger.debug('准备设置当前页面图像', data: {
      'imageDataLength': imageData.length,
      'hasExistingImage': _currentPageImage != null,
    });

    try {
      // 1. 解码并验证图像数据
      final decodedImage = img.decodeImage(imageData);
      if (decodedImage == null) {
        AppLogger.error('图像数据解码失败：解码结果为null');
        throw Exception('Invalid image data: decoded result is null');
      }

      // 2. 清理现有状态
      _currentPageImage = null;
      state = state.copyWith(
        regions: [],
        selectedIds: {},
        currentId: null,
        error: null,
      );
      _selectedRegionNotifier.clearRegion();

      // 3. 更新图像数据
      _currentPageImage = imageData;
      AppLogger.debug('图像数据设置完成', data: {
        'width': decodedImage.width,
        'height': decodedImage.height,
        'channels': decodedImage.numChannels,
      });
    } catch (e, stack) {
      AppLogger.error('设置页面图像失败',
          error: e,
          stackTrace: stack,
          data: {'imageDataLength': imageData.length});
      rethrow;
    }
  }

  // 多选功能：切换选择状态
  void toggleSelection(String id) {
    final selectedIds = <String>{...state.selectedIds};

    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }

    state = state.copyWith(selectedIds: selectedIds);
  }

  // 撤销操作
  Future<void> undo() async {
    if (state.undoStack.isEmpty) return;

    try {
      state = state.copyWith(processing: true);

      // 获取最后一个撤销操作
      final action = state.undoStack.last;
      final undoStack = state.undoStack.sublist(0, state.undoStack.length - 1);
      final redoStack = [...state.redoStack, action];

      switch (action.type) {
        case UndoActionType.create:
          // 撤销创建操作 - 删除区域
          final id = action.data as String;
          await _characterService.deleteCharacter(id);
          final updatedRegions =
              state.regions.where((r) => r.id != id).toList();

          state = state.copyWith(
            regions: updatedRegions,
            currentId: state.currentId == id ? null : state.currentId,
            undoStack: undoStack,
            redoStack: redoStack,
            processing: false,
          );

          if (state.currentId == null) {
            _selectedRegionNotifier.clearRegion();
          }
          break;

        case UndoActionType.delete:
          // 撤销删除操作 - 恢复区域
          final data = action.data as Map<String, dynamic>;
          final id = data['id'] as String;
          final deletedRegion = data['deletedState'] as CharacterRegion;

          if (_currentPageImage == null) {
            throw Exception('当前页面图像为空');
          }

          AppLogger.debug('使用当前页面图像进行撤销操作',
              data: {'imageDataLength': _currentPageImage!.length});

          await _characterService.extractCharacter(
            _currentWorkId ?? '',
            deletedRegion.pageId,
            deletedRegion.rect,
            deletedRegion.options,
            _currentPageImage!,
          );

          final updatedRegions = [...state.regions, deletedRegion];

          state = state.copyWith(
            regions: updatedRegions,
            undoStack: undoStack,
            redoStack: redoStack,
            processing: false,
          );
          break;

        case UndoActionType.update:
          // 撤销更新操作 - 恢复原始状态
          // TODO: 实现撤销更新的逻辑
          state = state.copyWith(
            undoStack: undoStack,
            redoStack: redoStack,
            processing: false,
          );
          break;

        case UndoActionType.erase:
          // 撤销擦除操作
          // TODO: 实现撤销擦除的逻辑
          state = state.copyWith(
            undoStack: undoStack,
            redoStack: redoStack,
            processing: false,
          );
          break;

        case UndoActionType.batch:
          // 撤销批量操作
          // TODO: 实现撤销批量操作的逻辑
          state = state.copyWith(
            undoStack: undoStack,
            redoStack: redoStack,
            processing: false,
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(
        processing: false,
        error: e.toString(),
      );
    }
  }

  // 从多选集合中移除区域
  void unselectRegion(String id) {
    final updatedSelectedIds = {...state.selectedIds}..remove(id);

    // 如果当前正在编辑的区域被取消选择，则也清除currentId
    final newCurrentId = (state.currentId == id) ? null : state.currentId;

    if (newCurrentId == null) {
      _selectedRegionNotifier.clearRegion();
    }

    state = state.copyWith(
      selectedIds: updatedSelectedIds,
      currentId: newCurrentId,
    );
  }

  // 更新选中区域
  void updateSelectedRegion(CharacterRegion region) {
    if (state.currentId == null) return;

    // 找到当前区域的索引
    final index = state.regions.indexWhere((r) => r.id == state.currentId);

    if (index >= 0) {
      // 获取旧区域以便比较是否有实际内容变化
      final oldRegion = state.regions[index];

      // 检查擦除点是否有变化
      bool hasErasePointsChanges =
          _hasErasePointsChanged(oldRegion.erasePoints, region.erasePoints);

      // 检查是否有实际内容变化（例如位置、大小、旋转等）
      bool hasContentChanges = oldRegion.rect != region.rect ||
          oldRegion.rotation != region.rotation ||
          oldRegion.character != region.character ||
          hasErasePointsChanges ||
          oldRegion.options != region.options;

      AppLogger.debug('检查区域内容变化', data: {
        'regionId': region.id,
        'hasContentChanges': hasContentChanges,
        'hasErasePointsChanges': hasErasePointsChanges,
        'oldRect': oldRegion.rect.toString(),
        'newRect': region.rect.toString(),
        'oldRotation': oldRegion.rotation,
        'oldCharacter': oldRegion.character,
        'newCharacter': region.character,
        'newRotation': region.rotation,
      });

      // 更新区域列表
      final updatedRegions = [...state.regions];
      updatedRegions[index] = region;

      // 仅当有实际内容变化时，才将更新的区域添加到已修改集合中
      final modifiedIds = hasContentChanges
          ? {...state.modifiedIds, region.id}
          : state.modifiedIds;

      // 更新状态
      state = state.copyWith(
        regions: updatedRegions,
        modifiedIds: modifiedIds, // 只在内容变化时更新修改状态
      );

      // 更新选中区域
      _selectedRegionNotifier.setRegion(region);
    }
  }

  /// [Internal] Finds the region and updates the SelectedRegionNotifier.
  /// Does NOT update the main collection state. Returns null if not found or error.
  CharacterRegion? _findAndSetSelectedRegion(String? id) {
    try {
      AppLogger.debug('[Internal] Finding region', data: {'targetId': id});
      if (id == null) {
        _selectedRegionNotifier.clearRegion();
        AppLogger.debug('[Internal] Cleared selected region notifier');
        return null;
      }

      // Find region using where + firstOrNull pattern (emulated)
      final matchingRegions = state.regions.where((r) => r.id == id).toList();
      final CharacterRegion? region =
          matchingRegions.isNotEmpty ? matchingRegions.first : null;

      if (region == null) {
        // Update error state if region not found
        state = state.copyWith(error: '查找区域失败: ID $id 未找到');
        _selectedRegionNotifier.clearRegion(); // Ensure notifier is cleared
        return null;
      }

      _selectedRegionNotifier.setRegion(region);
      AppLogger.debug('[Internal] Set selected region notifier',
          data: {'regionId': id});
      return region;
    } catch (e, stack) {
      AppLogger.error('[Internal] Finding region failed',
          error: e, stackTrace: stack, data: {'targetId': id});
      _selectedRegionNotifier.clearRegion();
      state = state.copyWith(error: '查找区域时发生错误: ${e.toString()}');
      return null;
    }
  }

  // 新增: 查找原始区域数据 (用于比较是否有实际修改)
  CharacterRegion? _findOriginalRegion(String id) {
    try {
      // 这里应该是从数据库或缓存中获取原始区域数据
      // 目前简单实现，仅返回当前state中的region
      final regions = state.regions.where((r) => r.id == id).toList();
      return regions.isNotEmpty ? regions.first : null;
    } catch (e) {
      AppLogger.error('查找原始区域数据失败', error: e, data: {'id': id});
      return null;
    }
  }

  // 检查擦除点是否有变化
  bool _hasErasePointsChanged(
      List<Offset>? oldPoints, List<Offset>? newPoints) {
    // 如果一个为null而另一个不为null，则视为有变化
    if ((oldPoints == null && newPoints != null) ||
        (oldPoints != null && newPoints == null)) {
      return true;
    }

    // 如果两者都为null，则没有变化
    if (oldPoints == null && newPoints == null) {
      return false;
    }

    // 如果点的数量不同，则有变化
    if (oldPoints!.length != newPoints!.length) {
      return true;
    }

    // 简化判断：如果有擦除点，认为有变化
    // 实际应用中可能需要更精确的比较
    if (oldPoints.isNotEmpty || newPoints.isNotEmpty) {
      return true;
    }
    return false;
  }

  // 新增: 检查两个区域是否实际内容相同 (没有实质性修改)
  bool _isRegionUnchanged(CharacterRegion original, CharacterRegion current) {
    // 比较关键属性是否有变化
    bool unchanged = original.rect == current.rect &&
        original.rotation == current.rotation &&
        original.character == current.character;

    AppLogger.debug('检查区域是否有实际修改', data: {
      'regionId': original.id,
      'unchanged': unchanged,
      'rectEquals': original.rect == current.rect,
      'rotationEquals': original.rotation == current.rotation,
      'characterEquals': original.character == current.character,
    });

    return unchanged;
  }
}

// 添加状态管理扩展方法
extension StateManagement on CharacterCollectionNotifier {
  /// 处理区域点击逻辑
  /// 根据当前工具模式转换区域状态
  void handleRegionClick(String id) {
    final currentTool = _toolModeNotifier.currentMode;
    // Find the region first to ensure it exists before proceeding
    final matchingRegions = state.regions.where((r) => r.id == id).toList();
    final CharacterRegion? region =
        matchingRegions.isNotEmpty ? matchingRegions.first : null;

    if (region == null) {
      AppLogger.warning('Region clicked but not found in state',
          data: {'regionId': id});
      state = state.copyWith(error: 'Clicked region $id not found');
      return;
    }

    AppLogger.debug('处理区域点击', data: {
      'regionId': id,
      'currentTool': currentTool.toString(),
      'isAdjusting': state.isAdjusting,
      'isSelected': state.selectedIds.contains(id),
    });

    switch (currentTool) {
      case Tool.pan:
        _handlePanModeClick(id);
        break;
      case Tool.select:
        _handleSelectModeClick(id);
        break;
      case Tool.multiSelect:
        // 多选模式已废弃，降级为Pan模式处理
        _handlePanModeClick(id);
        break;
      default:
        // 其他工具模式默认处理为Pan模式
        _handlePanModeClick(id);
        break;
    }
  }

  /// 处理Pan模式下的点击 (Add logging and ensure adjusting is false)
  void _handlePanModeClick(String id) {
    AppLogger.debug('Handling Pan Mode Click', data: {'regionId': id});
    // Ensure we are not in adjusting mode when using Pan click
    if (state.isAdjusting) {
      setAdjusting(false); // Exit adjusting mode
    }

    // Toggle selection state using selectRegion to maintain synchronization
    if (state.selectedIds.contains(id)) {
      // If it's already selected, deselect it by calling selectRegion(null)
      selectRegion(null);
      AppLogger.debug('Pan Mode Click: Deselected region',
          data: {'regionId': id});
    } else {
      // If not selected, select it
      selectRegion(id);
      AppLogger.debug('Pan Mode Click: Selected region',
          data: {'regionId': id});
    }
  }

  /// 处理Select模式下的点击
  /// Select模式下点击直接进入调整模式 (Atomic Update)
  void _handleSelectModeClick(String id) {
    AppLogger.debug('Handling Select Mode Click', data: {
      'regionId': id,
      'currentStateIsAdjusting': state.isAdjusting,
      'currentStateCurrentId': state.currentId
    });

    // 1. 如果当前正在调整其他选区，先保存状态
    if (state.isAdjusting && state.currentId != id) {
      finishCurrentAdjustment(); // 保存当前调整中的选区
    }

    // 2. 查找目标选区
    final regionToSelect = _findAndSetSelectedRegion(id);
    if (regionToSelect == null) {
      AppLogger.warning(
          'Select mode click failed: Region not found or error occurred.',
          data: {'regionId': id});
      return;
    }

    // 3. 更新状态 - 如果已经在调整该选区，则不重新进入调整状态
    bool shouldEnterAdjusting = !state.isAdjusting || state.currentId != id;

    // 重要：只选择区域，不标记为已修改
    // 只有当实际内容发生变化时才应该添加到modifiedIds
    state = state.copyWith(
      currentId: id,
      selectedIds: {id},
      isAdjusting: shouldEnterAdjusting, // 只有在需要时才进入调整状态
      error: null,
      // 不在这里修改modifiedIds
    );

    AppLogger.debug('Select Mode Click - State Update Complete', data: {
      'newStateRegionId': state.currentId,
      'newStateSelectedIds': state.selectedIds,
      'newStateIsAdjusting': state.isAdjusting,
      'wasAlreadyAdjusting': !shouldEnterAdjusting,
      'modifiedIds': state.modifiedIds.toList(),
    });
  }
}
