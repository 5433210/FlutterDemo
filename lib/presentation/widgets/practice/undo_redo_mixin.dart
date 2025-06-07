import 'package:flutter/material.dart';

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
      undoRedoManager.undo();
      markUnsaved();
      notifyListeners();
    }
  }

  /// 重做操作
  void redo() {
    checkDisposed();
    if (undoRedoManager.canRedo) {
      undoRedoManager.redo();
      markUnsaved();
      notifyListeners();
    }
  }

  /// 清除撤销重做历史（如果支持的话）
  void clearUndoRedoHistory() {
    checkDisposed();
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