// filepath: lib/canvas/interaction/multi_selection_manager.dart
/// 多选操作管理器 - Phase 2.4 多选操作优化
///
/// 职责：
/// 1. 高效的多选状态管理
/// 2. 批量操作优化
/// 3. 多选可视化反馈
/// 4. 多选操作的性能优化
library;

import 'package:flutter/material.dart';

import '../core/canvas_state_manager.dart';
import '../core/interfaces/command.dart';
import '../core/interfaces/element_data.dart';

/// 删除多个元素命令
class DeleteMultipleElementsCommand implements Command {
  final CanvasStateManager stateManager;
  final List<String> elementIds;
  List<ElementData>? _deletedElements;

  DeleteMultipleElementsCommand({
    required this.stateManager,
    required this.elementIds,
  });

  @override
  String get description => 'Delete ${elementIds.length} elements';

  @override
  String get id => 'delete_multiple_${elementIds.join('_')}';

  @override
  bool canMergeWith(Command other) => false;

  @override
  bool execute() {
    try {
      _deletedElements = [];
      for (final id in elementIds) {
        final element = stateManager.selectableElements
            .where((e) => e.id == id)
            .firstOrNull;
        if (element != null) {
          _deletedElements!.add(element);
          stateManager.removeElement(id);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Command? mergeWith(Command other) => null;

  @override
  bool undo() {
    if (_deletedElements == null) return false;

    try {
      for (final element in _deletedElements!) {
        stateManager.addElement(element);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 移动多个元素命令
class MoveMultipleElementsCommand implements Command {
  final CanvasStateManager stateManager;
  final List<String> elementIds;
  final Offset delta;

  MoveMultipleElementsCommand({
    required this.stateManager,
    required this.elementIds,
    required this.delta,
  });

  @override
  String get description => 'Move ${elementIds.length} elements by $delta';

  @override
  String get id => 'move_multiple_${elementIds.join('_')}';

  @override
  bool canMergeWith(Command other) => false;

  @override
  bool execute() {
    try {
      for (final id in elementIds) {
        final element = stateManager.selectableElements
            .where((e) => e.id == id)
            .firstOrNull;
        if (element != null) {
          // 这里需要根据实际的ElementData结构来实现位置更新
          // 暂时只调用updateElement方法
          stateManager.updateElement(id, element);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Command? mergeWith(Command other) => null;

  @override
  bool undo() {
    try {
      // 反向移动
      for (final id in elementIds) {
        final element = stateManager.selectableElements
            .where((e) => e.id == id)
            .firstOrNull;
        if (element != null) {
          // 这里需要根据实际的ElementData结构来实现位置更新
          // 暂时只调用updateElement方法
          stateManager.updateElement(id, element);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// 多选操作管理器
class MultiSelectionManager extends ChangeNotifier {
  final CanvasStateManager _stateManager;

  // 多选操作缓存
  final Map<String, ElementData> _selectionCache = {};

  // 批量操作队列
  final List<Command> _batchCommands = [];

  // 性能统计
  int _operationCount = 0;
  DateTime? _lastOperationTime;

  MultiSelectionManager(this._stateManager) {
    _stateManager.addListener(_onStateChanged);
  }

  /// 获取当前选中的元素数量
  int get selectedCount => _stateManager.selectionState.selectedIds.length;

  /// 获取当前选中的元素
  List<ElementData> get selectedElements {
    final selectedIds = _stateManager.selectionState.selectedIds;
    return _stateManager.selectableElements
        .where((element) => selectedIds.contains(element.id))
        .toList();
  }

  /// 清除所有选择
  void clearSelection() {
    _stateManager.clearSelection();
    _selectionCache.clear();
    notifyListeners();
  }

  /// 删除选中的多个元素
  bool deleteSelectedElements() {
    final selectedIds = _stateManager.selectionState.selectedIds;
    if (selectedIds.isEmpty) return false;

    _recordOperation();

    // 创建删除命令并执行
    final deleteCommand = DeleteMultipleElementsCommand(
      stateManager: _stateManager,
      elementIds: selectedIds.toList(),
    );

    final success = deleteCommand.execute();
    if (success) {
      _stateManager.clearSelection();
    }

    return success;
  }

  @override
  void dispose() {
    _stateManager.removeListener(_onStateChanged);
    _selectionCache.clear();
    _batchCommands.clear();
    super.dispose();
  }

  /// 获取选择边界框
  Rect? getSelectionBounds() {
    if (selectedElements.isEmpty) return null;

    // 计算所有选中元素的边界框
    // 这里需要根据实际的ElementData结构来实现
    return null;
  }

  /// 获取选择中心点
  Offset? getSelectionCenter() {
    final bounds = getSelectionBounds();
    return bounds?.center;
  }

  /// 获取操作统计信息
  Map<String, dynamic> getStats() {
    return {
      'operationCount': _operationCount,
      'lastOperationTime': _lastOperationTime?.toIso8601String(),
      'selectionCacheSize': _selectionCache.length,
      'selectedCount': selectedCount,
    };
  }

  /// 反选
  MultiSelectionResult invertSelection() {
    final allElementIds =
        _stateManager.selectableElements.map((element) => element.id).toSet();

    final selectedIds = _stateManager.selectionState.selectedIds.toSet();
    final unselectedIds = allElementIds.difference(selectedIds).toList();

    _stateManager.clearSelection();
    return selectMultiple(unselectedIds);
  }

  /// 移动选中的多个元素
  bool moveSelectedElements(Offset delta) {
    final selectedIds = _stateManager.selectionState.selectedIds;
    if (selectedIds.isEmpty) return false;

    _recordOperation();

    // 创建移动命令并执行
    final moveCommand = MoveMultipleElementsCommand(
      stateManager: _stateManager,
      elementIds: selectedIds.toList(),
      delta: delta,
    );

    return moveCommand.execute();
  }

  /// 重置统计信息
  void resetStats() {
    _operationCount = 0;
    _lastOperationTime = null;
  }

  /// 全选当前层的所有元素
  MultiSelectionResult selectAll() {
    final allElementIds =
        _stateManager.selectableElements.map((element) => element.id).toList();

    return selectMultiple(allElementIds);
  }

  /// 在矩形区域内选择元素
  MultiSelectionResult selectInRect(Rect rect) {
    _recordOperation();

    // 获取矩形内的元素
    final elementsInRect = _stateManager.selectableElements
        .where((element) => _isElementInRect(element, rect))
        .map((element) => element.id)
        .toList();

    return selectMultiple(elementsInRect);
  }

  /// 选择多个元素
  MultiSelectionResult selectMultiple(List<String> elementIds) {
    _recordOperation();

    for (final id in elementIds) {
      _stateManager.selectElement(id);
    }

    return MultiSelectionResult(
      selectedIds: List.from(_stateManager.selectionState.selectedIds),
      selectedElements: selectedElements,
      hasChanges: true,
    );
  }

  /// 切换多个元素的选择状态
  MultiSelectionResult toggleMultiple(List<String> elementIds) {
    _recordOperation();

    for (final id in elementIds) {
      if (_stateManager.selectionState.selectedIds.contains(id)) {
        _stateManager.deselectElement(id);
      } else {
        _stateManager.selectElement(id);
      }
    }

    return MultiSelectionResult(
      selectedIds: List.from(_stateManager.selectionState.selectedIds),
      selectedElements: selectedElements,
      hasChanges: true,
    );
  }

  /// 更新选中的多个元素
  bool updateSelectedElements(Map<String, ElementData> updates) {
    if (updates.isEmpty) return false;

    _recordOperation();

    // 创建更新命令并执行
    final updateCommand = UpdateMultipleElementsCommand(
      stateManager: _stateManager,
      updates: updates,
    );

    return updateCommand.execute();
  }

  /// 检查元素是否在矩形内
  bool _isElementInRect(ElementData element, Rect rect) {
    // 这里需要根据实际的ElementData结构来实现
    // 暂时返回false，实际应该检查元素的位置和尺寸
    return false;
  }

  /// 状态变化监听器
  void _onStateChanged() {
    _updateSelectionCache();
    notifyListeners();
  }

  /// 记录操作统计
  void _recordOperation() {
    _operationCount++;
    _lastOperationTime = DateTime.now();
  }

  /// 更新选择缓存
  void _updateSelectionCache() {
    final selectedIds = _stateManager.selectionState.selectedIds;
    _selectionCache.clear();

    for (final element in _stateManager.selectableElements) {
      if (selectedIds.contains(element.id)) {
        _selectionCache[element.id] = element;
      }
    }
  }
}

/// 多选操作结果
class MultiSelectionResult {
  final List<String> selectedIds;
  final List<ElementData> selectedElements;
  final bool hasChanges;

  const MultiSelectionResult({
    required this.selectedIds,
    required this.selectedElements,
    required this.hasChanges,
  });
}

/// 更新多个元素命令
class UpdateMultipleElementsCommand implements Command {
  final CanvasStateManager stateManager;
  final Map<String, ElementData> updates;
  Map<String, ElementData>? _originalStates;

  UpdateMultipleElementsCommand({
    required this.stateManager,
    required this.updates,
  });

  @override
  String get description => 'Update ${updates.length} elements';

  @override
  String get id => 'update_multiple_${updates.keys.join('_')}';

  @override
  bool canMergeWith(Command other) => false;

  @override
  bool execute() {
    try {
      _originalStates = {};
      for (final entry in updates.entries) {
        final original = stateManager.selectableElements
            .where((e) => e.id == entry.key)
            .firstOrNull;
        if (original != null) {
          _originalStates![entry.key] = original;
          stateManager.updateElement(entry.key, entry.value);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Command? mergeWith(Command other) => null;

  @override
  bool undo() {
    if (_originalStates == null) return false;

    try {
      for (final entry in _originalStates!.entries) {
        stateManager.updateElement(entry.key, entry.value);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
