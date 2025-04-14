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
import 'character_refresh_notifier.dart';
import 'erase_providers.dart';
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
    ref: ref, // Pass ref to access the refresh notifier
  );
});

class CharacterCollectionNotifier
    extends StateNotifier<CharacterCollectionState> {
  final CharacterService _characterService;
  final ToolModeNotifier _toolModeNotifier;
  final SelectedRegionNotifier _selectedRegionNotifier;
  final Ref _ref; // Store ref for refresh notifications

  Uint8List? _currentPageImage;
  String? _currentWorkId;
  String? _currentPageId;

  CharacterCollectionNotifier({
    required CharacterService characterService,
    required ToolModeNotifier toolModeNotifier,
    required SelectedRegionNotifier selectedRegionNotifier,
    required Ref ref,
  })  : _characterService = characterService,
        _toolModeNotifier = toolModeNotifier,
        _selectedRegionNotifier = selectedRegionNotifier,
        _ref = ref,
        super(CharacterCollectionState.initial());

  // 添加区域到多选集合中
  void addToSelection(String id) {
    if (state.regions.any((r) => r.id == id)) {
      // Update the region's isSelected property
      final updatedRegions = state.regions.map((r) {
        if (r.id == id) {
          return r.copyWith(isSelected: true);
        }
        return r;
      }).toList();

      state = state.copyWith(
        regions: updatedRegions,
      );
    }
  }

  // 取消编辑
  void cancelEdit() {
    _selectedRegionNotifier.clearRegion();

    // Update regions to clear selections
    final updatedRegions = state.regions
        .map((r) => r.isSelected ? r.copyWith(isSelected: false) : r)
        .toList();

    state = state.copyWith(
        currentId: null, regions: updatedRegions, isAdjusting: false);
  }

  // 清除错误消息
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 清理已选择的区域
  void clearSelectedRegions() {
    _selectedRegionNotifier.clearRegion();

    // Update regions to clear selections
    final updatedRegions = state.regions
        .map((r) => r.isSelected ? r.copyWith(isSelected: false) : r)
        .toList();

    state = state.copyWith(
      currentId: null,
      regions: updatedRegions,
    );
  }

  // 多选功能：清除所有选择
  void clearSelections() {
    // Update regions to clear selections
    final updatedRegions = state.regions
        .map((r) => r.isSelected ? r.copyWith(isSelected: false) : r)
        .toList();

    state = state.copyWith(
      regions: updatedRegions,
    );
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

      // 2. 创建新区域, set isSelected and isModified properties
      final region = CharacterRegion.create(
        pageId: _currentPageId!,
        rect: rect,
        options: const ProcessingOptions(),
        isSelected: true, // New region is selected by default
        isModified: true, // New region is modified by default
      );

      // 清理现有选择状态
      _selectedRegionNotifier.clearRegion();

      // 设置新的选中区域并立即进入可调节状态
      _selectedRegionNotifier.setRegion(region);

      // 更新区域列表和状态
      final updatedRegions = [...state.regions, region];

      // Maintain selectedIds and modifiedIds for transition period

      AppLogger.debug('创建新选区 - modifiedIds更新', data: {
        'regionId': region.id,
      });

      state = state.copyWith(
        regions: updatedRegions,
        currentId: region.id,
        isAdjusting: true, // 立即进入可调节状态
      );

      AppLogger.debug('创建新选区 - 状态更新完成', data: {
        'regionId': region.id,
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
      );

      // Notify about character deletion
      _ref
          .read(characterRefreshNotifierProvider.notifier)
          .notifyEvent(RefreshEventType.characterDeleted);
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

      // Notify about character deletion
      _ref
          .read(characterRefreshNotifierProvider.notifier)
          .notifyEvent(RefreshEventType.characterDeleted);
    } catch (e) {
      state = state.copyWith(
        processing: false,
        error: e.toString(),
      );
    }
  }

  /// 完成当前的调整操作
  void finishCurrentAdjustment() {
    if (!state.isAdjusting || state.currentId == null) return;

    state = state.copyWith(
      isAdjusting: false,
    );

    AppLogger.debug('完成调整 - 结束', data: {
      'regionId': state.currentId,
    });
  }

  List<CharacterRegion> getModifiedCharacters() {
    return state.regions.where((r) => r.isModified).toList();
  }

  /// 获取区域的视觉状态
  CharacterRegionState getRegionState(String id) {
    final region = state.regions.firstWhere(
      (r) => r.id == id,
      orElse: () => null as CharacterRegion,
    );

    final isSelected = region.isSelected;
    final isAdjusting = state.isAdjusting && state.currentId == id;

    if (isAdjusting) {
      return CharacterRegionState.adjusting;
    } else if (isSelected) {
      return CharacterRegionState.selected;
    } else {
      return CharacterRegionState.normal;
    }
  }

  List<CharacterRegion> getSelectedCharacters() {
    return state.regions.where((r) => r.isSelected).toList();
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

  bool isCharacterModified(String id) {
    final region = state.regions.firstWhere(
      (r) => r.id == id,
      orElse: () => null as CharacterRegion,
    );
    return region.isModified ?? false;
  }

  // New helper methods for isSelected and isModified properties

  bool isCharacterSelected(String id) {
    final region = state.regions.firstWhere(
      (r) => r.id == id,
      orElse: () => null as CharacterRegion,
    );
    return region.isSelected ?? false;
  }

  // 加载作品数据
  Future<void> loadWorkData(String workId,
      {String? pageId, String? defaultSelectedRegionId}) async {
    AppLogger.debug('开始加载选区数据', data: {
      'workId': workId,
      'pageId': pageId,
      'hasCurrentImage': _currentPageImage != null,
      'defaultSelectedRegionId': defaultSelectedRegionId,
    });

    // 更新状态，但不立即清除选中状态，等区域数据加载后再处理
    state = state.copyWith(
      loading: true,
      error: null,
    );

    try {
      // 更新当前上下文
      _currentWorkId = workId;
      _currentPageId = pageId;

      AppLogger.debug('验证当前页面图像状态', data: {
        'currentWorkId': _currentWorkId,
        'currentPageId': _currentPageId,
        'hasImage': _currentPageImage != null,
        'imageLength': _currentPageImage?.length,
      });

      if (_currentPageImage == null) {
        AppLogger.error('页面图像未设置', data: {
          'workId': workId,
          'pageId': pageId,
          'lastKnownState': state.toString(),
        });
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

      // 更新状态，但保留选中状态
      state = state.copyWith(
        workId: workId,
        pageId: pageId,
        regions: regions,
        loading: false,
      );

      // 如果有默认选中的选区ID，并且该选区存在于加载的区域中，则选中它
      if (defaultSelectedRegionId != null) {
        final targetRegion = regions.firstWhere(
          (r) => r.id == defaultSelectedRegionId,
          orElse: () => null as CharacterRegion,
        );

        // Update the region's isSelected property
        final newRegions = regions
            .map((r) => r.id == defaultSelectedRegionId
                ? r.copyWith(isSelected: true)
                : r)
            .toList();

        // Update the state
        state = state.copyWith(
          currentId: defaultSelectedRegionId,
          regions: newRegions,
        );

        _selectedRegionNotifier
            .setRegion(targetRegion.copyWith(isSelected: true));

        AppLogger.debug('已选中默认选区', data: {
          'regionId': defaultSelectedRegionId,
        });
      }

      // If we're selecting a specific region, load its erase data
      if (defaultSelectedRegionId != null) {
        final selectedRegion = regions.firstWhere(
          (r) =>
              r.id == defaultSelectedRegionId ||
              r.characterId == defaultSelectedRegionId,
          orElse: () => regions.isEmpty
              ? CharacterRegion.create(
                  pageId: '',
                  rect: Rect.zero,
                  options: const ProcessingOptions())
              : regions.first,
        );

        AppLogger.debug('Selected region for eraser data', data: {
          'regionId': selectedRegion.id,
          'characterId': selectedRegion.characterId,
          'hasEraseData': selectedRegion.eraseData != null,
          'eraseDataCount': selectedRegion.eraseData?.length ?? 0,
        });

        // Initialize eraser state with this region's data
        _ref.read(eraseStateProvider.notifier).clear();
        if (selectedRegion.eraseData != null &&
            selectedRegion.eraseData!.isNotEmpty) {
          _ref
              .read(eraseStateProvider.notifier)
              .initializeWithSavedPaths(selectedRegion.eraseData!);
        }
      }
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

  void markAllAsSaved() {
    final updatedRegions =
        state.regions.map((r) => r.copyWith(isModified: false)).toList();

    state = state.copyWith(
      regions: updatedRegions,
    );
  }

  /// 标记区域为已修改
  void markAsModified(String id) {
    final index = state.regions.indexWhere((r) => r.id == id);
    if (index < 0) return;

    final updatedRegions = [...state.regions];
    updatedRegions[index] = updatedRegions[index].copyWith(isModified: true);

    state = state.copyWith(
      regions: updatedRegions,
    );
  }

  /// 标记区域为已保存
  void markAsSaved(String id) {
    AppLogger.debug('尝试标记区域为已保存', data: {
      'regionId': id,
    });

    // Find the region
    final index = state.regions.indexWhere((r) => r.id == id);
    if (index < 0) {
      AppLogger.warning('在regions列表中未找到要标记为已保存的区域', data: {'regionId': id});
      return;
    }

    // Update the region to be saved and not modified
    final updatedRegions = [...state.regions];
    updatedRegions[index] = updatedRegions[index].copyWith(isModified: false);

    AppLogger.debug('markAsSaved 完成状态更新', data: {
      'regionId': id,
    });
  }

  // Method to update all regions from external sources
  Future<void> refreshRegions() async {
    if (state.pageId == null) return;

    try {
      state = state.copyWith(loading: true);

      // Get fresh data from the service
      final regions = await _characterService.getPageRegions(state.pageId!);

      // Preserve selection and modification states from current regions
      final updatedRegions = regions.map((newRegion) {
        // Find corresponding region in current state to preserve states
        final existingRegion = state.regions.firstWhere(
          (r) => r.id == newRegion.id,
          orElse: () => newRegion,
        );

        return newRegion.copyWith(
          isSelected: existingRegion.isSelected,
          isModified: existingRegion.isModified,
        );
      }).toList();

      state = state.copyWith(
        regions: updatedRegions,
        loading: false,
      );

      // Make sure selectedRegionProvider is in sync
      syncSelectedRegionWithState();
    } catch (e, stack) {
      AppLogger.error('刷新区域数据失败', error: e, stackTrace: stack);
      state = state.copyWith(
        loading: false,
        error: '刷新区域数据失败: ${e.toString()}',
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
    // Get IDs of regions with isSelected = true
    final selectedIds =
        state.regions.where((r) => r.isSelected).map((r) => r.id).toList();

    if (selectedIds.isEmpty) return false;

    // 这里实际上只是提供一个接口，实际的确认对话框逻辑在UI层实现
    // 返回true表示可以继续删除操作
    return true;
  }

  // 保存当前编辑的区域
  Future<void> saveCurrentRegion(ProcessingOptions options) async {
    AppLogger.debug('saveCurrentRegion 调用',
        data: {'currentId': state.currentId});
    if (state.currentId == null) return;

    try {
      state = state.copyWith(processing: true);

      final region = _selectedRegionNotifier.getCurrentRegion();
      if (region == null) {
        throw Exception('No region selected');
      }

      AppLogger.debug('保存选区', data: {
        'regionId': region.id,
        'isModified': region.isModified,
      });

      final exists = region.characterId != null;
      final originalId = region.id; // Store original ID to detect first save
      List<Map<String, dynamic>>? eraseData =
          region.eraseData; // Store erase data before save

      if (exists) {
        // 更新现有区域
        AppLogger.debug('保存现有区域', data: {'regionId': region.id});

        // 如果有图像数据，传递给服务层进行更新
        await _characterService.updateCharacter(
          region.id,
          region,
          region.character,
          options,
          _currentPageImage!,
        );

        // 更新区域列表 - 设置 isModified = false
        final updatedRegions = [...state.regions];
        final index = updatedRegions.indexWhere((r) => r.id == region.id);
        updatedRegions[index] = region.copyWith(isModified: false);

        state = state.copyWith(
          regions: updatedRegions,
          processing: false,
          isAdjusting: false, // 退出调整状态
        );
        AppLogger.debug('状态更新完成 (现有区域)', data: {
          'hasUnsavedChanges': state.hasUnsavedChanges,
        });

        // Notify about character save
        _ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.characterSaved);
      } else {
        // 创建新区域
        AppLogger.debug('创建并保存新区域', data: {'tempRegionId': region.id});
        if (_currentPageImage == null || _currentPageId == null) {
          throw Exception('Page image or ID not available');
        }

        AppLogger.debug('使用当前页面图像创建新区域',
            data: {'imageDataLength': _currentPageImage!.length});

        // 提取并处理字符，明确设置isSaved为true
        final characterEntity = await _characterService.createCharacter(
          _currentWorkId ?? '',
          _currentPageId!,
          region.rect,
          region.rotation,
          region.options,
          _currentPageImage!,
          eraseData,
          region.character,
        );
        AppLogger.debug('数据库操作完成，获取到 CharacterEntity',
            data: {'entityId': characterEntity.id});

        // 更新为正确的ID并标记为已保存，保留擦除数据
        final newRegion = region.copyWith(
          id: characterEntity.id,
          isModified: false, // Not modified after save
          characterId: characterEntity.id, // 设置关联的Character ID
          eraseData: eraseData, // Ensure erase data is preserved
        );
        AppLogger.debug('创建了新的 Region 对象', data: {
          'newRegionId': newRegion.id,
          'characterId': newRegion.characterId,
          'hasEraseData': newRegion.eraseData != null,
          'eraseDataCount': newRegion.eraseData?.length ?? 0,
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

        state = state.copyWith(
          regions: updatedRegions,
          currentId: newRegion.id, // 确保当前ID更新为新的ID
          processing: false,
          isAdjusting: false, // 退出调整状态
        );
        AppLogger.debug('状态更新完成 (新区域)', data: {
          'hasUnsavedChanges': state.hasUnsavedChanges,
        });
        _selectedRegionNotifier.setRegion(newRegion);
        AppLogger.debug('SelectedRegionProvider 更新完成...');

        // Detect first-time save and handle erase data refresh
        final isFirstSave = originalId != newRegion.id;
        if (isFirstSave && eraseData != null && eraseData.isNotEmpty) {
          AppLogger.debug('检测到首次保存，强制重新加载擦除数据', data: {
            'originalId': originalId,
            'newId': newRegion.id,
            'eraseDataCount': eraseData.length,
          });

          // More robust approach with multiple attempts and stronger refresh
          _reloadEraseDataWithRetry(eraseData, newRegion.id);
        }

        // Notify about character save
        _ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.characterSaved);
      }

      // After save is complete, ensure we reload the current erase data
      final savedRegion = _selectedRegionNotifier.getCurrentRegion();
      if (savedRegion != null) {
        AppLogger.debug('Region saved - checking erase data', data: {
          'savedRegionId': savedRegion.id,
          'characterId': savedRegion.characterId,
          'hasEraseData': savedRegion.eraseData != null,
          'eraseDataCount': savedRegion.eraseData?.length ?? 0,
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
    // Update all regions to be selected
    final updatedRegions =
        state.regions.map((r) => r.copyWith(isSelected: true)).toList();

    state = state.copyWith(regions: updatedRegions);
  }

  /// 选择指定的区域
  void selectRegion(String? id) {
    AppLogger.debug('选择区域', data: {
      'regionId': id,
      'currentId': state.currentId,
      'isAdjusting': state.isAdjusting,
    });

    // 如果当前正在调整，先完成调整
    if (state.isAdjusting) {
      finishCurrentAdjustment();
    }

    // 如果是清除选择
    if (id == null) {
      _selectedRegionNotifier.clearRegion();

      // Update all regions to be not selected
      final updatedRegions = state.regions
          .map((r) => r.isSelected ? r.copyWith(isSelected: false) : r)
          .toList();

      state = state.copyWith(
        currentId: null,
        regions: updatedRegions,
      );
      AppLogger.debug('清除选区');
      return;
    }

    // 查找目标区域
    final region = state.regions.firstWhere(
      (r) => r.id == id,
      orElse: () => null as CharacterRegion,
    );

    // Update all regions, only the target region is selected
    final updatedRegions =
        state.regions.map((r) => r.copyWith(isSelected: r.id == id)).toList();

    // 更新选中状态
    _selectedRegionNotifier.setRegion(region);
    state = state.copyWith(
      currentId: id,
      regions: updatedRegions,
      error: null,
    );

    AppLogger.debug('选区更新完成', data: {
      'regionId': id,
      'currentId': state.currentId,
    });
  }

  // 设置调整状态
  void setAdjusting(bool isAdjusting) {
    if (state.isAdjusting != isAdjusting) {
      // 如果正在退出调整状态，先完成当前调整
      if (state.isAdjusting && !isAdjusting) {
        finishCurrentAdjustment();
      }

      state = state.copyWith(isAdjusting: isAdjusting);
      AppLogger.debug('Set Adjusting State',
          data: {'isAdjusting': isAdjusting});
    }
  }

  /// 设置当前页面图像
  /// 1. 解码并验证图像数据
  /// 2. 更新图像数据，但保留现有状态
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

      // 2. 更新图像数据，但保留现有状态
      _currentPageImage = imageData;

      // 验证_currentPageImage是否正确设置
      AppLogger.debug('验证图像设置状态', data: {
        'imageSet': _currentPageImage != null,
        'imageLength': _currentPageImage?.length,
        'isOriginalData': _currentPageImage == imageData,
      });

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

  // Sync selectedRegionProvider with state
  void syncSelectedRegionWithState() {
    // If there's a currentId, ensure selectedRegionProvider has the corresponding region
    if (state.currentId != null) {
      final region = state.regions.firstWhere(
        (r) => r.id == state.currentId,
        orElse: () => null as CharacterRegion,
      );

      _selectedRegionNotifier.setRegion(region);
    } else {
      // If no currentId, clear selectedRegion
      _selectedRegionNotifier.clearRegion();
    }
  }

  // 多选功能：切换选择状态
  void toggleSelection(String id) {
    // Find the region and update its isSelected property
    final updatedRegions = state.regions.map((r) {
      if (r.id == id) {
        return r.copyWith(isSelected: !r.isSelected);
      }
      return r;
    }).toList();

    state = state.copyWith(regions: updatedRegions);
  }

  // 从多选集合中移除区域
  void unselectRegion(String id) {
    // Find the region and update its isSelected property
    final updatedRegions = state.regions.map((r) {
      if (r.id == id) {
        return r.copyWith(isSelected: false);
      }
      return r;
    }).toList();

    // 如果当前正在编辑的区域被取消选择，则也清除currentId
    final newCurrentId = (state.currentId == id) ? null : state.currentId;

    if (newCurrentId == null) {
      _selectedRegionNotifier.clearRegion();
    }

    state = state.copyWith(
      regions: updatedRegions,
      currentId: newCurrentId,
    );
  }

  // Add an update method for the RegionsPainter to use
  void updateRegionDisplay(CharacterRegion region) {
    final index = state.regions.indexWhere((r) => r.id == region.id);
    if (index < 0) return;

    final updatedRegions = [...state.regions];
    updatedRegions[index] = region;

    state = state.copyWith(regions: updatedRegions);

    // Notify about region update
    _ref
        .read(characterRefreshNotifierProvider.notifier)
        .notifyEvent(RefreshEventType.regionUpdated);
  }

  // 更新选中区域
  void updateSelectedRegion(CharacterRegion region) {
    if (state.currentId == null) return;

    // 找到当前区域的索引
    final index = state.regions.indexWhere((r) => r.id == state.currentId);

    if (index >= 0) {
      // 获取旧区域以便比较是否有实际内容变化
      final oldRegion = state.regions[index];

      // 检查擦除数据是否有变化
      bool hasEraseDataChanges =
          _hasEraseDataChanged(oldRegion.eraseData, region.eraseData);

      // 检查是否有实际内容变化（例如位置、大小、旋转等）
      bool hasContentChanges = oldRegion.rect != region.rect ||
          oldRegion.rotation != region.rotation ||
          oldRegion.character != region.character ||
          hasEraseDataChanges ||
          oldRegion.options != region.options;

      AppLogger.debug('检查区域内容变化', data: {
        'regionId': region.id,
        'hasContentChanges': hasContentChanges,
        'hasEraseDataChanges': hasEraseDataChanges,
        'oldRect': oldRegion.rect.toString(),
        'newRect': region.rect.toString(),
        'oldRotation': oldRegion.rotation,
        'newRotation': region.rotation,
        'rotationChanged': oldRegion.rotation != region.rotation,
        'oldCharacter': oldRegion.character,
        'newCharacter': region.character,
        'characterChanged': oldRegion.character != region.character,
        'optionsChanged': oldRegion.options != region.options,
      });

      // Update region with new properties, maintaining isSelected and setting isModified if changed
      final updatedRegion = region.copyWith(
          isSelected: oldRegion.isSelected,
          isModified: hasContentChanges || oldRegion.isModified);

      // 更新区域列表
      final updatedRegions = [...state.regions];
      updatedRegions[index] = updatedRegion;

      // 更新状态
      state = state.copyWith(
        regions: updatedRegions,
      );

      AppLogger.debug('区域更新完成', data: {
        'regionId': region.id,
        'hasContentChanges': hasContentChanges,
      });

      // 更新选中区域
      _selectedRegionNotifier.setRegion(updatedRegion);
    }
  }

  // 检查擦除路径数据是否有变化 - Update to handle eraseData instead of erasePoints
  bool _hasEraseDataChanged(List<Map<String, dynamic>>? oldData,
      List<Map<String, dynamic>>? newData) {
    // 如果一个为null而另一个不为null，则视为有变化
    if ((oldData == null && newData != null) ||
        (oldData != null && newData == null)) {
      return true;
    }

    // 如果两者都为null，则没有变化
    if (oldData == null && newData == null) {
      return false;
    }

    // 如果路径数量不同，则有变化
    if (oldData!.length != newData!.length) {
      return true;
    }

    // 简化判断：如果有擦除数据，认为有变化
    // 实际应用中可能需要更精确的比较
    if (oldData.isNotEmpty || newData.isNotEmpty) {
      return true;
    }
    return false;
  }

  // New helper method to more aggressively reload erase data with retries
  Future<void> _reloadEraseDataWithRetry(
      List<Map<String, dynamic>> eraseData, String newId) async {
    // Clear erase state immediately
    _ref.read(eraseStateProvider.notifier).clear();

    // Wait for state to be cleared
    await Future.delayed(const Duration(milliseconds: 50));

    // First attempt
    AppLogger.debug('擦除数据重载 - 第1次尝试', data: {'pathCount': eraseData.length});
    _ref.read(eraseStateProvider.notifier).initializeWithSavedPaths(eraseData);

    // Force a full UI refresh and give time for rendering
    await Future.delayed(const Duration(milliseconds: 250));

    // Second attempt with path verification
    _ref.read(eraseStateProvider.notifier).clear();
    await Future.delayed(const Duration(milliseconds: 50));

    AppLogger.debug('擦除数据重载 - 第2次尝试', data: {'pathCount': eraseData.length});
    _ref.read(eraseStateProvider.notifier).initializeWithSavedPaths(eraseData);

    // Final verification - check if paths are visible
    await Future.delayed(const Duration(milliseconds: 100));
    final pathRenderData = _ref.read(pathRenderDataProvider);

    AppLogger.debug('擦除数据重载完成 - 路径状态', data: {
      'characterId': newId,
      'visiblePaths': pathRenderData.completedPaths.length,
      'originalPathCount': eraseData.length
    });

    // Notify refresh to force UI update
    _ref
        .read(characterRefreshNotifierProvider.notifier)
        .notifyEvent(RefreshEventType.eraseDataReloaded);
  }
}

// 添加状态管理扩展方法
extension StateManagement on CharacterCollectionNotifier {
  /// 处理区域点击逻辑
  /// 根据当前工具模式转换区域状态
  void handleRegionClick(String id) {
    final currentTool = _toolModeNotifier.currentMode;
    // Find the region first to ensure it exists before proceeding
    final region = state.regions.firstWhere(
      (r) => r.id == id,
      orElse: () => null as CharacterRegion,
    );

    AppLogger.debug('处理区域点击', data: {
      'regionId': id,
      'currentTool': currentTool.toString(),
      'isAdjusting': state.isAdjusting,
      'isSelected': region.isSelected,
    });

    // 如果当前正在调整，先完成调整
    if (state.isAdjusting) {
      finishCurrentAdjustment();
    }

    // 根据工具模式处理点击
    switch (currentTool) {
      case Tool.pan:
        _handlePanModeClick(id);
        break;
      case Tool.select:
        _handleSelectModeClick(id);
        break;

      default:
        // 其他工具模式默认处理为Pan模式
        _handlePanModeClick(id);
        break;
    }
  }

  /// 处理Pan模式下的点击
  void _handlePanModeClick(String id) {
    AppLogger.debug('Handling Pan Mode Click', data: {'regionId': id});

    final region = state.regions.firstWhere(
      (r) => r.id == id,
      orElse: () => null as CharacterRegion,
    );

    // 如果当前区域已被选中，则取消选择
    if (region.isSelected) {
      unselectRegion(id);
      AppLogger.debug('Pan Mode Click: Deselected region',
          data: {'regionId': id});
    } else {
      // 如果未选中，则选中该区域
      selectRegion(id);
      AppLogger.debug('Pan Mode Click: Selected region',
          data: {'regionId': id});
    }
  }

  /// 处理Select模式下的点击
  /// Select模式下点击直接进入调整模式
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
    final region = state.regions.firstWhere(
      (r) => r.id == id,
      orElse: () => null as CharacterRegion,
    );

    _selectedRegionNotifier.setRegion(region);

    // 3. 更新状态 - 如果已经在调整该选区，则不重新进入调整状态
    bool shouldEnterAdjusting = !state.isAdjusting || state.currentId != id;

    // Update all regions, only the target region is selected
    final updatedRegions =
        state.regions.map((r) => r.copyWith(isSelected: r.id == id)).toList();

    // 重要：选择区域，但不添加到modifiedIds中
    state = state.copyWith(
      regions: updatedRegions,
      currentId: id,
      isAdjusting: shouldEnterAdjusting, // 只有在需要时才进入调整状态
      error: null,
    );

    AppLogger.debug('Select Mode Click - State Update Complete', data: {
      'newStateRegionId': state.currentId,
      'newStateIsAdjusting': state.isAdjusting,
      'wasAlreadyAdjusting': !shouldEnterAdjusting,
    });
  }
}
