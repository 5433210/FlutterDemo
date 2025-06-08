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
      notifyListeners();
    } else {
      EditPageLogger.controllerDebug('撤销操作被忽略：无可撤销操作');
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
      notifyListeners();
    } else {
      EditPageLogger.controllerDebug('重做操作被忽略：无可重做操作');
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