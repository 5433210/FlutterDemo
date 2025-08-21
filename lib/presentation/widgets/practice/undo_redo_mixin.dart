import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'practice_edit_state.dart';
import 'undo_redo_manager.dart';

/// 撤销重做功能 Mixin
mixin UndoRedoMixin on ChangeNotifier {
  // 抽象接口
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  void markUnsaved();
  void checkDisposed();

  /// 撤销操作
  void undo() {
    checkDisposed();
    if (undoRedoManager.canUndo) {
      EditPageLogger.controllerDebug(
        '执行撤销操作',
        data: {
          'canUndo': undoRedoManager.canUndo,
          'canRedo': undoRedoManager.canRedo,
        },
      );
      undoRedoManager.undo();
      markUnsaved();

      // 🔧 修复：撤销操作后强制刷新画布以立即显示变化
      _forceCanvasRefreshAfterUndo();

      notifyListeners();
    } else {
      EditPageLogger.controllerDebug('撤销操作被忽略：无可撤销操作');
    }
  }

  /// 强制画布刷新以显示撤销操作的结果
  void _forceCanvasRefreshAfterUndo() {
    try {
      // 检查当前对象是否有智能状态分发器
      final thisObj = this as dynamic;
      if (thisObj.intelligentDispatcher != null) {
        final dispatcher = thisObj.intelligentDispatcher;

        // 通知UI组件（包括画布）需要立即刷新
        dispatcher.notify(
          changeType: 'undo_operation_refresh',
          eventData: {
            'operation': 'force_canvas_refresh_after_undo',
            'timestamp': DateTime.now().toIso8601String(),
            'reason': '撤销操作后强制画布刷新',
          },
          operation: 'undo_force_refresh',
          affectedLayers: ['content', 'interaction'],
          affectedUIComponents: ['canvas', 'property_panel'],
        );

        EditPageLogger.controllerDebug(
          '撤销操作后强制画布刷新',
          data: {
            'method': 'intelligent_dispatcher_notify',
            'optimization': 'undo_canvas_force_refresh',
          },
        );
      }
    } catch (e) {
      EditPageLogger.controllerDebug(
        '撤销操作后强制画布刷新失败（正常情况）',
        data: {
          'error': e.toString(),
          'note': '当前对象可能没有智能分发器，使用标准通知机制',
        },
      );
    }
  }

  /// 重做操作
  void redo() {
    checkDisposed();
    if (undoRedoManager.canRedo) {
      EditPageLogger.controllerDebug(
        '执行重做操作',
        data: {
          'canUndo': undoRedoManager.canUndo,
          'canRedo': undoRedoManager.canRedo,
        },
      );
      undoRedoManager.redo();
      markUnsaved();

      // 🔧 修复：重做操作后强制刷新画布以立即显示变化
      _forceCanvasRefreshAfterRedo();

      notifyListeners();
    } else {
      EditPageLogger.controllerDebug('重做操作被忽略：无可重做操作');
    }
  }

  /// 强制画布刷新以显示重做操作的结果
  void _forceCanvasRefreshAfterRedo() {
    try {
      // 检查当前对象是否有智能状态分发器
      final thisObj = this as dynamic;
      if (thisObj.intelligentDispatcher != null) {
        final dispatcher = thisObj.intelligentDispatcher;

        // 通知UI组件（包括画布）需要立即刷新
        dispatcher.notify(
          changeType: 'redo_operation_refresh',
          eventData: {
            'operation': 'force_canvas_refresh_after_redo',
            'timestamp': DateTime.now().toIso8601String(),
            'reason': '重做操作后强制画布刷新',
          },
          operation: 'redo_force_refresh',
          affectedLayers: ['content', 'interaction'],
          affectedUIComponents: ['canvas', 'property_panel'],
        );

        EditPageLogger.controllerDebug(
          '重做操作后强制画布刷新',
          data: {
            'method': 'intelligent_dispatcher_notify',
            'optimization': 'redo_canvas_force_refresh',
          },
        );
      }
    } catch (e) {
      EditPageLogger.controllerDebug(
        '重做操作后强制画布刷新失败（正常情况）',
        data: {
          'error': e.toString(),
          'note': '当前对象可能没有智能分发器，使用标准通知机制',
        },
      );
    }
  }

  /// 清除撤销重做历史（如果支持的话）
  void clearUndoRedoHistory() {
    checkDisposed();
    EditPageLogger.controllerDebug(
      '清除撤销重做历史',
      data: {
        'previousCanUndo': state.canUndo,
        'previousCanRedo': state.canRedo,
      },
    );
    // 实际的清除逻辑需要根据UndoRedoManager的具体实现
    state.canUndo = false;
    state.canRedo = false;
    notifyListeners();
  }

  /// 是否可以撤销
  bool get canUndo => undoRedoManager.canUndo;

  /// 是否可以重做
  bool get canRedo => undoRedoManager.canRedo;
}
