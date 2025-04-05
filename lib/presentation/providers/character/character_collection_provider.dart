import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../application/services/character/character_service.dart';
import '../../../domain/models/character/character_region.dart';
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

  // 取消编辑
  void cancelEdit() {
    _selectedRegionNotifier.clearRegion();
    state = state.copyWith(currentId: null);
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
  void createRegion(Rect rect) {
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

      // 设置新的选中区域
      _selectedRegionNotifier.setRegion(region);

      // 更新区域列表和状态
      final updatedRegions = [...state.regions, region];
      state = state.copyWith(
        regions: updatedRegions,
        currentId: region.id,
        selectedIds: {region.id}, // 更新多选状态
      );

      AppLogger.debug('新选区创建完成', data: {
        'regionId': region.id,
        'totalRegions': updatedRegions.length,
      });
    } catch (e, stack) {
      AppLogger.error('创建选区失败',
          error: e, stackTrace: stack, data: {'rect': rect.toString()});

      state = state.copyWith(
        error: '创建选区失败: ${e.toString()}',
      );
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

  // 保存当前编辑的区域
  Future<void> saveCurrentRegion() async {
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
        await _characterService.updateCharacter(
          region.id,
          region,
          region.character,
        );

        // 更新区域列表
        final updatedRegions = [...state.regions];
        final index = updatedRegions.indexWhere((r) => r.id == region.id);
        updatedRegions[index] = region;

        state = state.copyWith(
          regions: updatedRegions,
          processing: false,
        );
      } else {
        // 创建新区域
        if (_currentPageImage == null || _currentPageId == null) {
          throw Exception('Page image or ID not available');
        }

        AppLogger.debug('使用当前页面图像创建新区域',
            data: {'imageDataLength': _currentPageImage!.length});

        // 提取并处理字符
        final characterEntity = await _characterService.extractCharacter(
          _currentWorkId ?? '',
          _currentPageId!,
          region.rect,
          region.options,
          _currentPageImage!,
        );

        // 更新为正确的ID
        final newRegion = region.copyWith(id: characterEntity.id);

        // 更新区域列表
        final updatedRegions = [...state.regions, newRegion];

        state = state.copyWith(
          regions: updatedRegions,
          currentId: newRegion.id,
          processing: false,
        );

        // 更新选中区域
        _selectedRegionNotifier.setRegion(newRegion);
      }
    } catch (e) {
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

  /// 选择指定的区域
  /// 1. 处理取消选择的情况
  /// 2. 查找并验证目标区域
  /// 3. 更新选择状态
  void selectRegion(String? id) {
    try {
      AppLogger.debug('处理区域选择', data: {
        'targetId': id,
        'currentId': state.currentId,
        'totalRegions': state.regions.length,
      });

      // 1. 处理取消选择
      if (id == null) {
        _selectedRegionNotifier.clearRegion();
        state = state.copyWith(
          currentId: null,
          selectedIds: {}, // 清除多选状态
        );
        AppLogger.debug('已清除选区');
        return;
      }

      // 2. 查找目标区域
      final region = state.regions.firstWhere(
        (r) => r.id == id,
        orElse: () => throw Exception('找不到指定ID的区域: $id'),
      );

      // 3. 更新选择状态
      _selectedRegionNotifier.setRegion(region);
      state = state.copyWith(
        currentId: id,
        selectedIds: {id}, // 更新多选状态
      );

      AppLogger.debug('区域选择完成', data: {
        'regionId': id,
        'rect': '${region.rect.left.toStringAsFixed(1)},'
            '${region.rect.top.toStringAsFixed(1)},'
            '${region.rect.width.toStringAsFixed(1)}x'
            '${region.rect.height.toStringAsFixed(1)}',
      });
    } catch (e, stack) {
      AppLogger.error('选择区域失败',
          error: e, stackTrace: stack, data: {'targetId': id});

      // 错误时清理选择状态
      _selectedRegionNotifier.clearRegion();
      state = state.copyWith(
        currentId: null,
        selectedIds: {},
        error: '选择区域失败: ${e.toString()}',
      );
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

  // 更新选中区域
  void updateSelectedRegion(CharacterRegion region) {
    if (state.currentId == null) return;

    // 找到当前区域的索引
    final index = state.regions.indexWhere((r) => r.id == state.currentId);

    if (index >= 0) {
      // 更新区域列表
      final updatedRegions = [...state.regions];
      updatedRegions[index] = region;

      // 更新状态
      state = state.copyWith(regions: updatedRegions);

      // 更新选中区域
      _selectedRegionNotifier.setRegion(region);
    }
  }
}
