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

  // 是否启用undo记录（用于滑块拖动时临时禁用）
  bool undoEnabled = true;

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
      // 🔍 详细追踪页面上下文
      EditPageLogger.controllerInfo(
        '🎯 添加撤销操作到管理器',
        data: {
          'operationType': operation.runtimeType.toString(),
          'operationDescription': operation.description,
          'associatedPageIndex': operation.associatedPageIndex,
          'associatedPageId': operation.associatedPageId,
          'executeImmediately': executeImmediately,
          'undoEnabled': undoEnabled,
          'currentUndoStackSize': _undoStack.length,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 条件执行操作
      if (executeImmediately) {
        EditPageLogger.controllerDebug('⚡ 立即执行操作');
        operation.execute();
      }

      // 如果undo被禁用，不添加到栈中
      if (!undoEnabled) {
        EditPageLogger.controllerDebug('🚫 Undo被禁用，不添加到栈中');
        return;
      }

      // 添加到撤销栈
      _undoStack.add(operation);
      EditPageLogger.controllerDebug(
        '📚 操作已添加到撤销栈',
        data: {
          'newUndoStackSize': _undoStack.length,
          'operationType': operation.runtimeType.toString(),
        },
      );

      // 清空重做栈
      if (_redoStack.isNotEmpty) {
        final clearedCount = _redoStack.length;
        _redoStack.clear();
        EditPageLogger.controllerDebug('🧹 清空重做栈', data: {'clearedOperations': clearedCount});
      }

      // 如果超过最大栈大小，移除最早的操作
      if (_undoStack.length > _maxStackSize) {
        final removedOperation = _undoStack.removeAt(0);
        EditPageLogger.controllerInfo('🗑️ 撤销栈超过最大大小，移除最早操作', data: {
          'maxStackSize': _maxStackSize,
          'removedOperationType': removedOperation.runtimeType.toString(),
          'removedPageIndex': removedOperation.associatedPageIndex,
        });
      }

      // 通知状态变化
      if (onStateChanged != null) {
        onStateChanged!();
      }
    } catch (e, stackTrace) {
      EditPageLogger.controllerError('❌ 添加撤销重做操作失败', error: e, stackTrace: stackTrace, data: {
        'operationType': operation.runtimeType.toString(),
        'pageIndex': operation.associatedPageIndex,
        'pageId': operation.associatedPageId,
      });
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
    if (!canRedo) {
      EditPageLogger.controllerWarning('🚫 无法重做：重做栈为空');
      return;
    }

    // 从重做栈中取出最后一个操作
    final operation = _redoStack.removeLast();

    EditPageLogger.controllerInfo(
      '🔄 执行重做操作',
      data: {
        'operationType': operation.runtimeType.toString(),
        'operationDescription': operation.description,
        'associatedPageIndex': operation.associatedPageIndex,
        'associatedPageId': operation.associatedPageId,
        'remainingRedoOperations': _redoStack.length,
        'currentUndoStackSize': _undoStack.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    try {
      // 执行操作
      operation.execute();

      // 添加到撤销栈
      _undoStack.add(operation);

      EditPageLogger.controllerDebug(
        '✅ 重做操作执行成功',
        data: {
          'newUndoStackSize': _undoStack.length,
          'remainingRedoOperations': _redoStack.length,
        },
      );

      // 通知状态变化
      if (onStateChanged != null) {
        onStateChanged!();
      }
    } catch (e, stackTrace) {
      EditPageLogger.controllerError('❌ 重做操作执行失败', error: e, stackTrace: stackTrace, data: {
        'operationType': operation.runtimeType.toString(),
        'pageIndex': operation.associatedPageIndex,
        'pageId': operation.associatedPageId,
      });
      
      // 出错时将操作放回重做栈
      _redoStack.add(operation);
    }
  }

  /// 撤销操作
  void undo() {
    if (!canUndo) {
      EditPageLogger.controllerWarning('🚫 无法撤销：撤销栈为空');
      return;
    }

    // 从撤销栈中取出最后一个操作
    final operation = _undoStack.removeLast();

    EditPageLogger.controllerInfo(
      '↩️ 执行撤销操作',
      data: {
        'operationType': operation.runtimeType.toString(),
        'operationDescription': operation.description,
        'associatedPageIndex': operation.associatedPageIndex,
        'associatedPageId': operation.associatedPageId,
        'remainingUndoOperations': _undoStack.length,
        'currentRedoStackSize': _redoStack.length,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    try {
      // 撤销操作
      operation.undo();

      // 添加到重做栈
      _redoStack.add(operation);

      EditPageLogger.controllerDebug(
        '✅ 撤销操作执行成功',
        data: {
          'remainingUndoOperations': _undoStack.length,
          'newRedoStackSize': _redoStack.length,
        },
      );

      // 通知状态变化
      if (onStateChanged != null) {
        onStateChanged!();
      }
    } catch (e, stackTrace) {
      EditPageLogger.controllerError('❌ 撤销操作执行失败', error: e, stackTrace: stackTrace, data: {
        'operationType': operation.runtimeType.toString(),
        'pageIndex': operation.associatedPageIndex,
        'pageId': operation.associatedPageId,
      });
      
      // 出错时将操作放回撤销栈
      _undoStack.add(operation);
    }
  }

  /// 获取撤销栈的详细信息（用于调试）
  List<Map<String, dynamic>> getUndoStackInfo() {
    return _undoStack.map((operation) => {
      'type': operation.runtimeType.toString(),
      'description': operation.description,
      'pageIndex': operation.associatedPageIndex,
      'pageId': operation.associatedPageId,
    }).toList();
  }

  /// 获取重做栈的详细信息（用于调试）
  List<Map<String, dynamic>> getRedoStackInfo() {
    return _redoStack.map((operation) => {
      'type': operation.runtimeType.toString(),
      'description': operation.description,
      'pageIndex': operation.associatedPageIndex,
      'pageId': operation.associatedPageId,
    }).toList();
  }

  /// 打印当前撤销/重做栈状态（用于调试）
  void debugPrintStackState() {
    EditPageLogger.controllerInfo(
      '📊 撤销/重做栈状态',
      data: {
        'undoStackSize': _undoStack.length,
        'redoStackSize': _redoStack.length,
        'canUndo': canUndo,
        'canRedo': canRedo,
        'undoStackInfo': getUndoStackInfo(),
        'redoStackInfo': getRedoStackInfo(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}
