import 'package:flutter/foundation.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'undo_operations.dart';

/// 撤销/重做管理器
class UndoRedoManager {
  // 撤销栈
  final List<UndoableOperation> _undoStack = [];

  // 重做栈
  final List<UndoableOperation> _redoStack = [];

  // 最大栈大小
  final int _maxStackSize;

  // 状态变化回调
  final VoidCallback? onStateChanged;

  /// 构造函数
  UndoRedoManager({
    int maxStackSize = 100,
    this.onStateChanged,
  }) : _maxStackSize = maxStackSize;

  /// 是否可以重做
  bool get canRedo => _redoStack.isNotEmpty;

  /// 是否可以撤销
  bool get canUndo => _undoStack.isNotEmpty;

  /// 添加操作
  void addOperation(UndoableOperation operation, {bool executeImmediately = true}) {
    try {
      // 条件执行操作
      if (executeImmediately) {
        operation.execute();
      }

      // 添加到撤销栈
      _undoStack.add(operation);

      // 清空重做栈
      _redoStack.clear();

      // 如果超过最大栈大小，移除最早的操作
      if (_undoStack.length > _maxStackSize) {
        _undoStack.removeAt(0);
        EditPageLogger.controllerInfo('撤销栈超过最大大小，移除最早操作', data: {'maxStackSize': _maxStackSize});
      }

      // 通知状态变化
      if (onStateChanged != null) {
        onStateChanged!();
      }
    } catch (e) {
      EditPageLogger.controllerError('添加撤销重做操作失败', error: e, data: {'operationType': operation.runtimeType.toString()});
    }
  }

  /// 清空历史
  void clearHistory() {
    _undoStack.clear();
    _redoStack.clear();

    // 通知状态变化
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  /// 重做操作
  void redo() {
    if (!canRedo) return;

    // 从重做栈中取出最后一个操作
    final operation = _redoStack.removeLast();

    // 执行操作
    operation.execute();

    // 添加到撤销栈
    _undoStack.add(operation);

    // 通知状态变化
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  /// 撤销操作
  void undo() {
    if (!canUndo) return;

    // 从撤销栈中取出最后一个操作
    final operation = _undoStack.removeLast();

    // 撤销操作
    operation.undo();

    // 添加到重做栈
    _redoStack.add(operation);

    // 通知状态变化
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }
}
