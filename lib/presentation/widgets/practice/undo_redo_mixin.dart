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
      // 🔍 获取即将执行的撤销操作信息
      final undoStackInfo = undoRedoManager.getUndoStackInfo();
      final nextUndoOperation =
          undoStackInfo.isNotEmpty ? undoStackInfo.last : null;

      EditPageLogger.controllerInfo(
        '🔄 准备执行撤销操作',
        data: {
          'currentPageIndex': state.currentPageIndex,
          'currentPageId': state.currentPage?['id'],
          'nextUndoOperation': nextUndoOperation,
          'undoStackSize': undoStackInfo.length,
          'canUndo': undoRedoManager.canUndo,
          'canRedo': undoRedoManager.canRedo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 🔧 修复：检查页面上下文，如果不匹配则自动切换页面
      bool needSwitchPage = false;
      if (nextUndoOperation != null && nextUndoOperation['pageIndex'] != null) {
        final operationPageIndex = nextUndoOperation['pageIndex'] as int;
        if (operationPageIndex != state.currentPageIndex) {
          EditPageLogger.controllerInfo(
            '🔄 撤销操作需要切换页面',
            data: {
              'operationPageIndex': operationPageIndex,
              'currentPageIndex': state.currentPageIndex,
              'operationPageId': nextUndoOperation['pageId'],
              'currentPageId': state.currentPage?['id'],
              'operationType': nextUndoOperation['type'],
              'operationDescription': nextUndoOperation['description'],
            },
          );

          // 检查目标页面是否存在
          if (operationPageIndex >= 0 &&
              operationPageIndex < state.pages.length) {
            // 自动切换到操作对应的页面
            _switchToPageForUndoRedo(operationPageIndex);
            needSwitchPage = true;

            EditPageLogger.controllerInfo(
              '✅ 已切换到撤销操作对应的页面',
              data: {
                'newCurrentPageIndex': state.currentPageIndex,
                'targetPageIndex': operationPageIndex,
              },
            );
          } else {
            EditPageLogger.controllerWarning(
              '⚠️ 撤销操作对应的页面不存在，无法切换',
              data: {
                'operationPageIndex': operationPageIndex,
                'totalPages': state.pages.length,
              },
            );
          }
        }
      }

      undoRedoManager.undo();
      markUnsaved();

      // 🔧 修复：撤销操作后强制刷新画布以立即显示变化
      _forceCanvasRefreshAfterUndo();

      notifyListeners();

      EditPageLogger.controllerInfo(
        '✅ 撤销操作执行完成',
        data: {
          'finalPageIndex': state.currentPageIndex,
          'finalPageId': state.currentPage?['id'],
          'remainingUndoOperations': undoRedoManager.getUndoStackInfo().length,
          'canUndoAfter': undoRedoManager.canUndo,
          'canRedoAfter': undoRedoManager.canRedo,
          'switchedPage': needSwitchPage,
        },
      );
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
      // 🔍 获取即将执行的重做操作信息
      final redoStackInfo = undoRedoManager.getRedoStackInfo();
      final nextRedoOperation =
          redoStackInfo.isNotEmpty ? redoStackInfo.last : null;

      EditPageLogger.controllerInfo(
        '🔄 准备执行重做操作',
        data: {
          'currentPageIndex': state.currentPageIndex,
          'currentPageId': state.currentPage?['id'],
          'nextRedoOperation': nextRedoOperation,
          'redoStackSize': redoStackInfo.length,
          'canUndo': undoRedoManager.canUndo,
          'canRedo': undoRedoManager.canRedo,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // 🔧 修复：检查页面上下文，如果不匹配则自动切换页面
      bool needSwitchPage = false;
      if (nextRedoOperation != null && nextRedoOperation['pageIndex'] != null) {
        final operationPageIndex = nextRedoOperation['pageIndex'] as int;
        if (operationPageIndex != state.currentPageIndex) {
          EditPageLogger.controllerInfo(
            '🔄 重做操作需要切换页面',
            data: {
              'operationPageIndex': operationPageIndex,
              'currentPageIndex': state.currentPageIndex,
              'operationPageId': nextRedoOperation['pageId'],
              'currentPageId': state.currentPage?['id'],
              'operationType': nextRedoOperation['type'],
              'operationDescription': nextRedoOperation['description'],
            },
          );

          // 检查目标页面是否存在
          if (operationPageIndex >= 0 &&
              operationPageIndex < state.pages.length) {
            // 自动切换到操作对应的页面
            _switchToPageForUndoRedo(operationPageIndex);
            needSwitchPage = true;

            EditPageLogger.controllerInfo(
              '✅ 已切换到重做操作对应的页面',
              data: {
                'newCurrentPageIndex': state.currentPageIndex,
                'targetPageIndex': operationPageIndex,
              },
            );
          } else {
            EditPageLogger.controllerWarning(
              '⚠️ 重做操作对应的页面不存在，无法切换',
              data: {
                'operationPageIndex': operationPageIndex,
                'totalPages': state.pages.length,
              },
            );
          }
        }
      }

      undoRedoManager.redo();
      markUnsaved();

      // 🔧 修复：重做操作后强制刷新画布以立即显示变化
      _forceCanvasRefreshAfterRedo();

      notifyListeners();

      EditPageLogger.controllerInfo(
        '✅ 重做操作执行完成',
        data: {
          'finalPageIndex': state.currentPageIndex,
          'finalPageId': state.currentPage?['id'],
          'remainingRedoOperations': undoRedoManager.getRedoStackInfo().length,
          'canUndoAfter': undoRedoManager.canUndo,
          'canRedoAfter': undoRedoManager.canRedo,
          'switchedPage': needSwitchPage,
        },
      );
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

  /// 为撤销/重做操作切换到指定页面
  /// 这是一个内部方法，只更新页面索引，不触发完整的页面切换逻辑
  void _switchToPageForUndoRedo(int pageIndex) {
    if (pageIndex >= 0 &&
        pageIndex < state.pages.length &&
        pageIndex != state.currentPageIndex) {
      final oldPageIndex = state.currentPageIndex;

      EditPageLogger.controllerInfo(
        '🔄 撤销/重做页面切换',
        data: {
          'oldPageIndex': oldPageIndex,
          'newPageIndex': pageIndex,
          'reason': 'undo_redo_operation',
          'pageId': state.pages[pageIndex]['id'],
          'pageName': state.pages[pageIndex]['name'],
        },
      );

      // 更新页面索引
      state.currentPageIndex = pageIndex;

      // 清除当前页面的选择状态，因为撤销/重做可能涉及不同的元素
      state.selectedElementIds.clear();
      state.selectedElement = null;

      // 这里不需要调用完整的 notifyListeners()，因为撤销/重做方法会在操作完成后调用
      // notifyListeners() 会在撤销/重做操作完成后被调用

      EditPageLogger.controllerInfo(
        '✅ 撤销/重做页面切换完成',
        data: {
          'finalPageIndex': state.currentPageIndex,
          'clearedSelection': true,
        },
      );
    } else {
      EditPageLogger.controllerWarning(
        '⚠️ 撤销/重做页面切换失败',
        data: {
          'requestedPageIndex': pageIndex,
          'currentPageIndex': state.currentPageIndex,
          'totalPages': state.pages.length,
          'indexValid': pageIndex >= 0 && pageIndex < state.pages.length,
          'indexDifferent': pageIndex != state.currentPageIndex,
        },
      );
    }
  }
}
