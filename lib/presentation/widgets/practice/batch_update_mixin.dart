import 'dart:async';

import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../pages/practices/widgets/state_change_dispatcher.dart';
import 'batch_update_options.dart';
import 'practice_edit_state.dart';
import 'undo_operations.dart';
import 'undo_redo_manager.dart';

/// 批量更新管理 Mixin
/// 负责批量更新元素属性的管理，包括延迟提交和批处理优化
mixin BatchUpdateMixin on ChangeNotifier {
  // 抽象接口
  PracticeEditState get state;
  UndoRedoManager get undoRedoManager;
  void checkDisposed();

  // 批量更新相关字段
  final Map<String, Map<String, dynamic>> _pendingUpdates = {};
  Timer? _commitTimer;
  StateChangeDispatcher? _stateDispatcher;

  /// 获取状态变更分发器
  StateChangeDispatcher? get stateDispatcher => _stateDispatcher;

  /// 设置状态变化分发器（用于分层状态管理）
  void setStateDispatcher(StateChangeDispatcher? dispatcher) {
    _stateDispatcher = dispatcher;
    EditPageLogger.controllerDebug('设置状态分发器',
        data: {'hasDispatcher': dispatcher != null});
  }

  /// 立即刷新所有待处理的更新
  void flushBatchUpdates() {
    _commitTimer?.cancel();
    if (_pendingUpdates.isNotEmpty) {
      _flushPendingUpdates(const BatchUpdateOptions(
        recordUndoOperation: true,
        notifyListeners: true,
      ));
    }
  }

  /// 批量更新单个元素属性
  ///
  /// [elementId] 要更新的元素ID
  /// [properties] 要更新的属性映射
  /// [options] 批量更新选项
  void batchUpdateSingleElementProperties(
    String elementId,
    Map<String, dynamic> properties, {
    BatchUpdateOptions? options,
  }) {
    checkDisposed();

    final updateOptions = options ?? const BatchUpdateOptions();

    EditPageLogger.controllerDebug('批量更新元素属性',
        data: {'elementId': elementId, 'propertyCount': properties.length});

    // 如果有待处理的更新，合并属性
    if (_pendingUpdates.containsKey(elementId)) {
      _pendingUpdates[elementId]!.addAll(properties);
    } else {
      _pendingUpdates[elementId] = Map<String, dynamic>.from(properties);
    }

    // 如果启用了延迟提交，设置定时器
    if (updateOptions.enableDelayedCommit) {
      _scheduleCommit(updateOptions);
    } else {
      // 立即提交
      _flushPendingUpdates(updateOptions);
    }
  }

  /// 释放批量更新相关资源
  void disposeBatchUpdate() {
    _commitTimer?.cancel();
    _commitTimer = null;
    _pendingUpdates.clear();
    _stateDispatcher = null;
  }

  /// 调度批量提交
  void _scheduleCommit(BatchUpdateOptions options) {
    _commitTimer?.cancel();
    _commitTimer = Timer(Duration(milliseconds: options.commitDelayMs), () {
      if (_pendingUpdates.isNotEmpty) {
        _flushPendingUpdates(options);
      }
    });
  }

  /// 刷新待处理的更新
  void _flushPendingUpdates(BatchUpdateOptions options) {
    if (_pendingUpdates.isEmpty) return;

    final updatesToCommit =
        Map<String, Map<String, dynamic>>.from(_pendingUpdates);
    _pendingUpdates.clear();

    EditPageLogger.controllerInfo('批量更新提交',
        data: {'updateCount': updatesToCommit.length});

    _executeBatchUpdate(updatesToCommit, options);
  }

  /// 执行批量更新的核心逻辑
  void _executeBatchUpdate(
    Map<String, Map<String, dynamic>> batchUpdates,
    BatchUpdateOptions options,
  ) {
    if (state.currentPageIndex < 0 ||
        state.currentPageIndex >= state.pages.length) {
      EditPageLogger.controllerWarning('批量更新失败',
          data: {'reason': '无效页面索引', 'pageIndex': state.currentPageIndex});
      return;
    }

    final page = state.pages[state.currentPageIndex];
    final elements = page['elements'] as List<dynamic>;

    // 记录旧的属性用于撤销操作
    final Map<String, Map<String, dynamic>> oldProperties = {};
    final Map<String, Map<String, dynamic>> newProperties = {};
    final List<String> updatedElementIds = [];

    // 批量处理更新
    for (final entry in batchUpdates.entries) {
      final elementId = entry.key;
      final properties = entry.value;

      final elementIndex = elements.indexWhere((e) => e['id'] == elementId);
      if (elementIndex >= 0) {
        final element = elements[elementIndex] as Map<String, dynamic>;

        // 记录旧属性
        oldProperties[elementId] = Map<String, dynamic>.from(element);

        // 更新属性
        final newElement = {...element};
        properties.forEach((key, value) {
          if (key == 'content' && element.containsKey('content')) {
            // 对于content对象，合并而不是替换
            newElement['content'] = {
              ...(element['content'] as Map<String, dynamic>),
              ...(value as Map<String, dynamic>),
            };
          } else {
            newElement[key] = value;
          }
        });

        // 应用更新
        elements[elementIndex] = newElement;
        newProperties[elementId] = newElement;
        updatedElementIds.add(elementId);

        // 如果是当前选中的元素，更新selectedElement
        if (state.selectedElementIds.contains(elementId)) {
          state.selectedElement = newElement;
        }
      }
    }

    if (updatedElementIds.isNotEmpty) {
      // 如果启用了撤销/重做记录，创建批量操作
      if (options.recordUndoOperation) {
        final operations = <UndoableOperation>[];

        for (final elementId in updatedElementIds) {
          final oldProps = oldProperties[elementId]!;
          final newProps = newProperties[elementId]!;

          operations.add(ElementPropertyOperation(
            elementId: elementId,
            oldProperties: oldProps,
            newProperties: newProps,
            pageIndex: state.currentPageIndex,
            pageId: state.currentPage?['id'] ?? 'unknown',
            updateElement: (id, props) {
              if (state.currentPageIndex >= 0 &&
                  state.currentPageIndex < state.pages.length) {
                final page = state.pages[state.currentPageIndex];
                final elements = page['elements'] as List<dynamic>;
                final elementIndex = elements.indexWhere((e) => e['id'] == id);

                if (elementIndex >= 0) {
                  elements[elementIndex] = props;

                  // 如果是当前选中的元素，更新selectedElement
                  if (state.selectedElementIds.contains(id)) {
                    state.selectedElement = props;
                  }
                }
              }
            },
          ));
        }

        // 创建批量操作
        final batchOperation = BatchOperation(
          operations: operations,
          description: '批量更新${updatedElementIds.length}个元素',
        );

        undoRedoManager.addOperation(batchOperation);
      }

      state.hasUnsavedChanges = true;

      // 分层状态管理 - 通过StateChangeDispatcher分发状态变化
      if (_stateDispatcher != null) {
        _stateDispatcher!.dispatch(StateChangeEvent(
          type: StateChangeType.elementUpdate,
          data: {
            'elementIds': updatedElementIds,
            'updateType': 'batch',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
        ));
      }

      // 如果没有StateChangeDispatcher，回退到直接通知
      if (options.notifyListeners) {
        notifyListeners();
      }

      EditPageLogger.controllerInfo('批量更新完成', data: {
        'affectedElements': updatedElementIds.length,
        'elementIds': updatedElementIds,
        'hasUndoRecord': options.recordUndoOperation,
        'hasStateDispatcher': _stateDispatcher != null
      });
    }
  }
}
