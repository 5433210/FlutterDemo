import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'practice_edit_controller.dart';

/// 🚀 智能状态分发器
/// 精确控制组件重建，避免全局Canvas重建
class IntelligentStateDispatcher {
  // ignore: unused_field
  final PracticeEditController _controller; // 為未來狀態管理功能預留

  // 🔍[TRACKING] 静态分发计数器
  static int _dispatchCount = 0;

  // 🔧 分层监听器管理
  final Map<String, Set<VoidCallback>> _layerListeners = {};
  final Map<String, Set<VoidCallback>> _elementListeners = {};
  final Map<String, Set<VoidCallback>> _uiListeners = {};

  // 🔧 操作监听器管理（用于撤销/重做等特殊操作）
  final Map<String, Set<VoidCallback>> _operationListeners = {};

  // 🔧 状态变化缓存
  final Map<String, dynamic> _lastStates = {};

  // 🔧 性能统计
  int _totalDispatches = 0;
  int _skippedDispatches = 0;
  final Map<String, int> _dispatchCounts = {};

  IntelligentStateDispatcher(this._controller);

  /// 清理过期状态缓存
  void cleanupExpiredStates() {
    if (_lastStates.length > 100) {
      final keys = _lastStates.keys.toList();
      final keysToRemove = keys.take(keys.length - 50).toList();

      for (final key in keysToRemove) {
        _lastStates.remove(key);
      }

      EditPageLogger.performanceInfo(
        '清理过期状态缓存',
        data: {
          'removedCount': keysToRemove.length,
          'remainingCount': _lastStates.length,
          'optimization': 'state_cache_cleanup',
        },
      );
    }
  }

  /// 智能分发状态变更通知
  void dispatch({
    required String changeType,
    required Map<String, dynamic> eventData,
    required String operation,
    List<String>? affectedElements,
    List<String>? affectedLayers,
    List<String>? affectedUIComponents,
  }) {
    final dispatchStartTime = DateTime.now();
    _dispatchCount++;

    // 🚀 优化：只在重要里程碑或错误时记录分发开始跨信息
    if (_dispatchCount % 25 == 0 || changeType.contains('error')) {
      EditPageLogger.performanceInfo(
        '智能状态分发里程碑',
        data: {
          'dispatchNumber': _dispatchCount,
          'changeType': changeType,
          'operation': operation,
          'affectedElements': affectedElements?.length ?? 0,
          'optimization': 'intelligent_dispatch_milestone',
        },
      );
    }

    // 检查状态是否实际发生变化
    if (_hasNoActualChange(changeType, eventData)) {
      _skippedDispatches++;
      // 🚀 优化：减少跳过分发的日志频率
      if (_skippedDispatches % 10 == 0) {
        EditPageLogger.performanceInfo(
          '智能状态分发跳过里程碑',
          data: {
            'dispatchNumber': _dispatchCount,
            'changeType': changeType,
            'skippedCount': _skippedDispatches,
            'skipReason': 'no_actual_change',
            'optimization': 'intelligent_dispatch_skip_milestone',
          },
        );
      }
      return;
    }

    // 记录分发统计
    _totalDispatches++;
    _dispatchCounts[changeType] = (_dispatchCounts[changeType] ?? 0) + 1;

    bool hasListeners = false;
    int notificationCount = 0;
    final notificationDetails = <String, Map<String, dynamic>>{};

    // 1. 通知特定元素的监听器
    if (affectedElements != null) {
      for (final elementId in affectedElements) {
        final elementListeners = _elementListeners[elementId];
        if (elementListeners != null && elementListeners.isNotEmpty) {
          _notifyElementListeners(elementId, changeType);
          hasListeners = true;
          notificationCount += elementListeners.length;
          notificationDetails['element_$elementId'] = {
            'type': 'element',
            'id': elementId,
            'listenerCount': elementListeners.length,
          };
        }
      }
    }

    // 2. 通知相关图层的监听器
    if (affectedLayers != null) {
      for (final layerId in affectedLayers) {
        final layerListeners = _layerListeners[layerId];
        if (layerListeners != null && layerListeners.isNotEmpty) {
          _notifyLayerListeners(layerId, changeType);
          hasListeners = true;
          notificationCount += layerListeners.length;
          notificationDetails['layer_$layerId'] = {
            'type': 'layer',
            'id': layerId,
            'listenerCount': layerListeners.length,
          };
        }
      }
    }

    // 3. 通知UI组件的监听器
    if (affectedUIComponents != null) {
      for (final uiComponent in affectedUIComponents) {
        final uiListeners = _uiListeners[uiComponent];
        if (uiListeners != null && uiListeners.isNotEmpty) {
          _notifyUIListeners(uiComponent, changeType);
          hasListeners = true;
          notificationCount += uiListeners.length;
          notificationDetails['ui_$uiComponent'] = {
            'type': 'ui_component',
            'id': uiComponent,
            'listenerCount': uiListeners.length,
          };
        }
      }
    }

    // 4. 🔧 通知操作监听器（用于撤销/重做等特殊操作）
    final operationListeners = _operationListeners[operation];
    if (operationListeners != null && operationListeners.isNotEmpty) {
      _notifyOperationListeners(operation, changeType);
      hasListeners = true;
      notificationCount += operationListeners.length;
      notificationDetails['operation_$operation'] = {
        'type': 'operation',
        'id': operation,
        'listenerCount': operationListeners.length,
      };
    }

    // 4. 根据变更类型进行精确分发
    if (notificationCount > 0) {
      hasListeners = true;
    }

    // 🔧 可选：添加一些特殊的逻辑判断，但不进行重复通知
    switch (changeType) {
      case 'element_update':
      case 'element_batch_update':
      case 'element_batch_update_undo_redo':
      case 'element_undo_redo':
      case 'element_order_update':
        // 特殊逻辑：如果是变换操作，确保交互层被通知（如果还没有被通知的话）
        if ((operation.contains('transform') ||
                operation.contains('position') ||
                operation.contains('size')) &&
            (affectedLayers == null ||
                !affectedLayers.contains('interaction'))) {
          final interactionListeners = _layerListeners['interaction'];
          if (interactionListeners != null && interactionListeners.isNotEmpty) {
            _notifyLayerListeners('interaction', changeType);
            notificationCount += interactionListeners.length;
            hasListeners = true;
            notificationDetails['layer_interaction_auto'] = {
              'type': 'layer_auto',
              'id': 'interaction',
              'listenerCount': interactionListeners.length,
              'reason': 'transform_operation_auto_notify',
            };
          }
        }
        break;

      default:
        // 其他类型不需要特殊处理，完全依赖参数化通知
        break;
    }

    final dispatchDuration = DateTime.now().difference(dispatchStartTime);

    if (hasListeners) {
      _skippedDispatches--;
    }

    // 🚀 优化：只在重要里程碑、错误或性能问题时记录分发完成
    final shouldLogCompletion = _dispatchCount % 25 == 0 ||
        changeType.contains('error') ||
        dispatchDuration.inMilliseconds > 5;

    if (shouldLogCompletion) {
      EditPageLogger.performanceInfo(
        '智能状态分发完成里程碑',
        data: {
          'dispatchNumber': _dispatchCount,
          'changeType': changeType,
          'operation': operation,
          'hasListeners': hasListeners,
          'notificationCount': notificationCount,
          'dispatchDurationMs': dispatchDuration.inMilliseconds,
          'optimization': 'intelligent_dispatch_milestone_complete',
        },
      );
    }
  }

  /// � notify方法的别名，用于向后兼容
  void notify({
    required String changeType,
    required Map<String, dynamic> eventData,
    required String operation,
    List<String>? affectedElements,
    List<String>? affectedLayers,
    List<String>? affectedUIComponents,
  }) {
    dispatch(
      changeType: changeType,
      eventData: eventData,
      operation: operation,
      affectedElements: affectedElements,
      affectedLayers: affectedLayers,
      affectedUIComponents: affectedUIComponents,
    );
  }

  /// �🚀 分发拖拽变化 - 只影响拖拽预览层
  void dispatchDragChange({
    required bool isDragging,
    required List<String> draggingElementIds,
    Map<String, Offset>? elementPositions,
  }) {
    dispatch(
      changeType: 'drag_change',
      eventData: {
        'isDragging': isDragging,
        'draggingIds': draggingElementIds,
        'positions': elementPositions ?? {},
      },
      operation: 'drag_change',
      affectedLayers: ['drag_preview'], // 拖拽主要影响预览层
      affectedElements: draggingElementIds, // 影响被拖拽的元素
    );
  }

  /// 🚀 分发元素变化 - 只影响相关组件
  void dispatchElementChange({
    required String elementId,
    required String changeType,
    required Map<String, dynamic> elementData,
  }) {
    dispatch(
      changeType: 'element_$changeType',
      eventData: elementData,
      operation: 'element_change',
      affectedElements: [elementId],
      affectedLayers: ['content'], // 元素变化通常影响内容层
      affectedUIComponents: ['property_panel'], // 可能影响属性面板
    );
  }

  /// 🚀 分发选择变化 - 只影响交互层和UI
  void dispatchSelectionChange({
    required List<String> selectedElementIds,
    required List<String> previouslySelectedIds,
  }) {
    dispatch(
      changeType: 'selection_change',
      eventData: {
        'selectedIds': selectedElementIds,
        'previousIds': previouslySelectedIds,
        'selectionCount': selectedElementIds.length,
      },
      operation: 'selection_change',
      affectedLayers: ['interaction'], // 选择变化主要影响交互层
      affectedUIComponents: ['property_panel', 'toolbar'], // 影响属性面板和工具栏
    );
  }

  /// 释放资源
  void dispose() {
    _layerListeners.clear();
    _elementListeners.clear();
    _uiListeners.clear();
    _lastStates.clear();
  }

  /// 获取分发统计信息
  Map<String, dynamic> getDispatchStats() {
    return {
      'totalDispatches': _totalDispatches,
      'skippedDispatches': _skippedDispatches,
      'skipRate':
          _totalDispatches > 0 ? _skippedDispatches / _totalDispatches : 0.0,
      'dispatchCounts': Map.from(_dispatchCounts),
      'layerListenerCounts':
          _layerListeners.map((k, v) => MapEntry(k, v.length)),
      'elementListenerCounts':
          _elementListeners.map((k, v) => MapEntry(k, v.length)),
      'uiListenerCounts': _uiListeners.map((k, v) => MapEntry(k, v.length)),
    };
  }

  /// 🔍 检查是否有注册的监听器
  bool hasRegisteredListeners({
    List<String>? affectedLayers,
    List<String>? affectedUIComponents,
    List<String>? affectedElements,
  }) {
    // 检查层级监听器
    if (affectedLayers != null) {
      for (final layer in affectedLayers) {
        if (_layerListeners[layer]?.isNotEmpty == true) {
          return true;
        }
      }
    }

    // 检查UI监听器
    if (affectedUIComponents != null) {
      for (final component in affectedUIComponents) {
        if (_uiListeners[component]?.isNotEmpty == true) {
          return true;
        }
      }
    }

    // 检查元素监听器
    if (affectedElements != null) {
      for (final element in affectedElements) {
        if (_elementListeners[element]?.isNotEmpty == true) {
          return true;
        }
      }
    }

    return false;
  }

  /// 🔍 检查特定UI组件是否有监听器
  bool hasUIComponentListener(String uiComponent) {
    return _uiListeners[uiComponent]?.isNotEmpty == true;
  }

  /// 注册元素监听器
  void registerElementListener(String elementId, VoidCallback listener) {
    _elementListeners.putIfAbsent(elementId, () => <VoidCallback>{});
    _elementListeners[elementId]!.add(listener);

    EditPageLogger.performanceInfo(
      '注册元素监听器',
      data: {
        'elementId': elementId,
        'listenerCount': _elementListeners[elementId]!.length,
        'optimization': 'element_listener_registration',
      },
    );
  }

  /// 注册层级监听器
  void registerLayerListener(String layerType, VoidCallback listener) {
    _layerListeners.putIfAbsent(layerType, () => <VoidCallback>{});
    _layerListeners[layerType]!.add(listener);

    EditPageLogger.performanceInfo(
      '注册层级监听器',
      data: {
        'layerType': layerType,
        'listenerCount': _layerListeners[layerType]!.length,
        'optimization': 'layer_listener_registration',
      },
    );
  }

  /// 注册UI监听器
  void registerUIListener(String uiComponent, VoidCallback listener) {
    _uiListeners.putIfAbsent(uiComponent, () => <VoidCallback>{});
    _uiListeners[uiComponent]!.add(listener);

    EditPageLogger.performanceInfo(
      '注册UI监听器',
      data: {
        'uiComponent': uiComponent,
        'listenerCount': _uiListeners[uiComponent]!.length,
        'optimization': 'ui_listener_registration',
      },
    );
  }

  void removeElementListener(String elementId, VoidCallback listener) {
    _elementListeners[elementId]?.remove(listener);
  }

  /// 移除监听器
  void removeLayerListener(String layerType, VoidCallback listener) {
    _layerListeners[layerType]?.remove(listener);
  }

  void removeUIListener(String uiComponent, VoidCallback listener) {
    _uiListeners[uiComponent]?.remove(listener);
  }

  /// 🔧 注册操作监听器（用于撤销/重做等特殊操作）
  void registerOperationListener(String operation, VoidCallback listener) {
    _operationListeners.putIfAbsent(operation, () => <VoidCallback>{});
    _operationListeners[operation]!.add(listener);

    EditPageLogger.performanceInfo(
      '注册操作监听器',
      data: {
        'operation': operation,
        'listenerCount': _operationListeners[operation]!.length,
        'optimization': 'operation_listener_registration',
      },
    );
  }

  /// 移除操作监听器
  void removeOperationListener(String operation, VoidCallback listener) {
    _operationListeners[operation]?.remove(listener);
  }

  /// 检查是否没有实际变化
  bool _hasNoActualChange(String changeType, Map<String, dynamic> eventData) {
    final stateKey = '$changeType:${eventData.hashCode}';
    final lastState = _lastStates[stateKey];

    if (lastState != null && _isStateUnchanged(lastState, eventData)) {
      return true;
    }

    // 更新状态缓存
    _lastStates[stateKey] = Map.from(eventData);
    return false;
  }

  /// 检查状态是否未变化
  bool _isStateUnchanged(dynamic lastState, dynamic currentState) {
    if (lastState is Map && currentState is Map) {
      if (lastState.length != currentState.length) return false;

      for (final key in lastState.keys) {
        if (!currentState.containsKey(key) ||
            lastState[key] != currentState[key]) {
          return false;
        }
      }
      return true;
    }

    return lastState == currentState;
  }

  /// 通知元素监听器
  void _notifyElementListeners(String elementId, String changeType) {
    final listeners = _elementListeners[elementId];
    if (listeners != null && listeners.isNotEmpty) {
      EditPageLogger.performanceInfo(
        '通知元素监听器',
        data: {
          'elementId': elementId,
          'changeType': changeType,
          'listenerCount': listeners.length,
          'optimization': 'element_notification',
        },
      );

      for (final listener in listeners) {
        try {
          listener();
        } catch (e) {
          EditPageLogger.performanceWarning(
            '元素监听器执行失败',
            data: {
              'elementId': elementId,
              'changeType': changeType,
              'error': e.toString(),
            },
          );
        }
      }
    }
  }

  /// 通知层级监听器
  void _notifyLayerListeners(String layerType, String changeType) {
    final listeners = _layerListeners[layerType];
    if (listeners != null && listeners.isNotEmpty) {
      EditPageLogger.performanceInfo(
        '通知层级监听器',
        data: {
          'layerType': layerType,
          'changeType': changeType,
          'listenerCount': listeners.length,
          'optimization': 'layer_notification',
        },
      );

      for (final listener in listeners) {
        try {
          listener();
        } catch (e) {
          EditPageLogger.performanceWarning(
            '层级监听器执行失败',
            data: {
              'layerType': layerType,
              'changeType': changeType,
              'error': e.toString(),
            },
          );
        }
      }
    }
  }

  /// 通知UI监听器
  void _notifyUIListeners(String uiComponent, String changeType) {
    final listeners = _uiListeners[uiComponent];
    if (listeners != null && listeners.isNotEmpty) {
      EditPageLogger.performanceInfo(
        '通知UI监听器',
        data: {
          'uiComponent': uiComponent,
          'changeType': changeType,
          'listenerCount': listeners.length,
          'optimization': 'ui_notification',
        },
      );

      for (final listener in listeners) {
        try {
          listener();
        } catch (e) {
          EditPageLogger.performanceWarning(
            'UI监听器执行失败',
            data: {
              'uiComponent': uiComponent,
              'changeType': changeType,
              'error': e.toString(),
            },
          );
        }
      }
    }
  }

  /// 🔧 通知操作监听器（用于撤销/重做等特殊操作）
  void _notifyOperationListeners(String operation, String changeType) {
    final listeners = _operationListeners[operation];
    if (listeners != null && listeners.isNotEmpty) {
      EditPageLogger.performanceInfo(
        '通知操作监听器',
        data: {
          'operation': operation,
          'changeType': changeType,
          'listenerCount': listeners.length,
          'optimization': 'operation_notification',
        },
      );

      for (final listener in listeners) {
        try {
          listener();
        } catch (e) {
          EditPageLogger.performanceWarning(
            '操作监听器执行失败',
            data: {
              'operation': operation,
              'changeType': changeType,
              'error': e.toString(),
            },
          );
        }
      }
    }
  }
}
