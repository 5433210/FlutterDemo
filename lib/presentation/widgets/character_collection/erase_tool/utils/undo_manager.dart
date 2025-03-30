import 'dart:collection';

import '../models/erase_operation.dart';

/// 撤销/重做管理器
/// 负责管理操作历史，支持撤销和重做功能
class UndoManager {
  /// 最大历史记录数量
  final int maxHistorySize;

  /// 撤销栈
  final ListQueue<EraseOperation> _undoStack = ListQueue<EraseOperation>();

  /// 重做栈
  final ListQueue<EraseOperation> _redoStack = ListQueue<EraseOperation>();

  /// 状态变更监听器
  final List<Function(EraseOperation, bool)> _stateChangeListeners = [];

  /// 构造函数
  UndoManager({this.maxHistorySize = 50});

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  /// 获取重做栈中的所有操作
  List<EraseOperation> get redoOperations => List.unmodifiable(_redoStack);

  /// 获取撤销栈中的所有操作
  List<EraseOperation> get undoOperations => List.unmodifiable(_undoStack);

  /// 添加状态变更监听器
  void addStateChangeListener(Function(EraseOperation, bool) listener) {
    _stateChangeListeners.add(listener);
  }

  /// 清空历史记录
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  /// 记录一个操作
  void push(EraseOperation operation) {
    // 添加到撤销栈
    _undoStack.addLast(operation);

    // 清空重做栈
    _redoStack.clear();

    // 如果历史记录超过最大数量，清理最老的记录
    _trimHistory();

    // 通知监听器
    _notifyStateChange(operation, false);
  }

  /// 重做操作
  /// 返回被重做的操作，如果没有可重做的操作则返回null
  EraseOperation? redo() {
    if (_redoStack.isEmpty) return null;

    final operation = _redoStack.removeLast();
    _undoStack.addLast(operation);

    // 通知监听器
    _notifyStateChange(operation, false);

    return operation;
  }

  /// 移除状态变更监听器
  void removeStateChangeListener(Function(EraseOperation, bool) listener) {
    _stateChangeListeners.remove(listener);
  }

  /// 尝试合并最近的操作
  /// 如果最近两个操作可以合并，则合并它们并返回true
  bool tryMergeLastOperations() {
    if (_undoStack.length < 2) return false;

    final lastOp = _undoStack.removeLast();
    final prevOp = _undoStack.removeLast();

    // 检查是否可以合并
    if (lastOp.canMergeWith(prevOp)) {
      // 创建新的合并操作
      final newPoints = [...prevOp.points, ...lastOp.points];
      final mergedOp = EraseOperation(
        id: prevOp.id,
        points: newPoints,
        brushSize: prevOp.brushSize,
        timestamp: prevOp.timestamp,
      );

      // 将合并后的操作添加回撤销栈
      _undoStack.addLast(mergedOp);
      return true;
    } else {
      // 无法合并，恢复原来的操作
      _undoStack.addLast(prevOp);
      _undoStack.addLast(lastOp);
      return false;
    }
  }

  /// 撤销操作
  /// 返回被撤销的操作，如果没有可撤销的操作则返回null
  EraseOperation? undo() {
    if (_undoStack.isEmpty) return null;

    final operation = _undoStack.removeLast();
    _redoStack.addLast(operation);

    // 通知监听器
    _notifyStateChange(operation, true);

    return operation;
  }

  /// 通知状态变更
  void _notifyStateChange(EraseOperation operation, bool isUndo) {
    for (final listener in _stateChangeListeners) {
      listener(operation, isUndo);
    }
  }

  /// 裁剪历史记录，保持在最大数量以内
  void _trimHistory() {
    while (_undoStack.length > maxHistorySize) {
      _undoStack.removeFirst();
    }
  }
}
