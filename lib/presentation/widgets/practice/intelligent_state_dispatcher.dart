import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'practice_edit_controller.dart';

/// 🚀 智能状态分发器
/// 精确控制组件重建，避免全局Canvas重建
class IntelligentStateDispatcher {
  final PracticeEditController _controller;

  // 🔧 分层监听器管理
  final Map<String, Set<VoidCallback>> _layerListeners = {};
  final Map<String, Set<VoidCallback>> _elementListeners = {};
  final Map<String, Set<VoidCallback>> _uiListeners = {};

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

    // 检查状态是否实际发生变化
    if (_hasNoActualChange(changeType, eventData)) {
      _skippedDispatches++;
      return;
    }

    // 记录分发统计
    _totalDispatches++;
    _dispatchCounts[changeType] = (_dispatchCounts[changeType] ?? 0) + 1;

    EditPageLogger.performanceInfo(
      '智能状态分发开始',
      data: {
        'changeType': changeType,
        'operation': operation,
        'affectedElements': affectedElements?.length ?? 0,
        'affectedLayers': affectedLayers?.length ?? 0,
        'affectedUIComponents': affectedUIComponents?.length ?? 0,
        'stats': {
          'totalDispatches': _totalDispatches,
          'skippedDispatches': _skippedDispatches,
          'skipRate': _totalDispatches > 0
              ? _skippedDispatches / _totalDispatches
              : 0.0,
          'dispatchCounts': Map.from(_dispatchCounts),
          'layerListenerCounts':
              _layerListeners.map((k, v) => MapEntry(k, v.length)),
          'elementListenerCounts':
              _elementListeners.map((k, v) => MapEntry(k, v.length)),
          'uiListenerCounts': _uiListeners.map((k, v) => MapEntry(k, v.length)),
        },
      },
    );

    bool hasListeners = false;
    int notificationCount = 0;

    // 1. 通知特定元素的监听器
    if (affectedElements != null) {
      for (final elementId in affectedElements) {
        _notifyElementListeners(elementId, changeType);
        final elementListeners = _elementListeners[elementId];
        if (elementListeners != null && elementListeners.isNotEmpty) {
          hasListeners = true;
          notificationCount += elementListeners.length;
        }
      }
    }

    // 2. 通知相关图层的监听器
    if (affectedLayers != null) {
      for (final layerId in affectedLayers) {
        _notifyLayerListeners(layerId, changeType);
        final layerListeners = _layerListeners[layerId];
        if (layerListeners != null && layerListeners.isNotEmpty) {
          hasListeners = true;
          notificationCount += layerListeners.length;
        }
      }
    }

    // 3. 通知UI组件的监听器
    if (affectedUIComponents != null) {
      for (final uiComponent in affectedUIComponents) {
        _notifyUIListeners(uiComponent, changeType);
        final uiListeners = _uiListeners[uiComponent];
        if (uiListeners != null && uiListeners.isNotEmpty) {
          hasListeners = true;
          notificationCount += uiListeners.length;
        }
      }
    }

    // 4. 根据变更类型进行精确分发
    switch (changeType) {
      // 新增元素操作
      case 'element_add':
      case 'element_paste':
      case 'element_restore':
      case 'element_restore_batch':
        _notifyUIListeners('canvas', changeType);
        _notifyUIListeners('property_panel', changeType);
        _notifyUIListeners('element_list', changeType);
        _notifyLayerListeners('content', changeType);
        _notifyLayerListeners('interaction', changeType);
        hasListeners = true;
        break;

      // 删除元素操作
      case 'element_delete':
      case 'element_delete_batch':
      case 'element_delete_selected':
      case 'element_paste_undo':
      case 'element_remove':
        _notifyUIListeners('canvas', changeType);
        _notifyUIListeners('property_panel', changeType);
        _notifyUIListeners('element_list', changeType);
        _notifyLayerListeners('content', changeType);
        _notifyLayerListeners('interaction', changeType);
        hasListeners = true;
        break;

      // 元素更新操作
      case 'element_update':
      case 'element_batch_update':
      case 'element_batch_update_undo_redo':
      case 'element_undo_redo':
      case 'element_order_update':
        _notifyUIListeners('property_panel', changeType);
        _notifyLayerListeners('content', changeType);
        if (operation.contains('transform') ||
            operation.contains('position') ||
            operation.contains('size')) {
          _notifyUIListeners('canvas', changeType);
          _notifyLayerListeners('interaction', changeType);
        }
        hasListeners = true;
        break;

      // 选择操作
      case 'selection_change':
      case 'element_select':
      case 'element_deselect':
        _notifyUIListeners('property_panel', changeType);
        _notifyUIListeners('toolbar', changeType);
        _notifyLayerListeners('interaction', changeType);
        hasListeners = true;
        break;

      // 页面管理操作
      case 'page_add':
      case 'page_delete':
      case 'page_duplicate':
      case 'page_reorder':
      case 'page_select':
      case 'page_update':
        _notifyUIListeners('page_list', changeType);
        _notifyUIListeners('canvas', changeType);
        if (changeType == 'page_select') {
          _notifyUIListeners('property_panel', changeType);
          _notifyLayerListeners('content', changeType);
          _notifyLayerListeners('interaction', changeType);
        }
        hasListeners = true;
        break;

      // 图层管理操作
      case 'layer_add':
      case 'layer_delete':
      case 'layer_select':
      case 'layer_visibility':
      case 'layer_lock':
      case 'layer_reorder':
      case 'layer_update':
        _notifyUIListeners('layer_panel', changeType);
        _notifyUIListeners('canvas', changeType);
        if (changeType == 'layer_select') {
          _notifyUIListeners('property_panel', changeType);
        }
        _notifyLayerListeners('content', changeType);
        hasListeners = true;
        break;

      // UI状态变化
      case 'ui_tool_change':
      case 'tool_change':
        _notifyUIListeners('toolbar', changeType);
        _notifyUIListeners('property_panel', changeType);
        _notifyUIListeners('canvas_overlay', changeType);
        _notifyLayerListeners('interaction', changeType);
        hasListeners = true;
        break;

      case 'ui_zoom_change':
      case 'ui_grid_toggle':
      case 'ui_snap_toggle':
      case 'ui_view_reset':
        _notifyUIListeners('canvas', changeType);
        _notifyUIListeners('canvas_overlay', changeType);
        _notifyLayerListeners('interaction', changeType);
        hasListeners = true;
        break;

      // 撤销重做操作
      case 'undo_execute':
      case 'redo_execute':
      case 'history_clear':
        _notifyUIListeners('toolbar', changeType);
        _notifyUIListeners('canvas', changeType);
        _notifyUIListeners('property_panel', changeType);
        _notifyLayerListeners('content', changeType);
        _notifyLayerListeners('interaction', changeType);
        hasListeners = true;
        break;

      // 文件操作
      case 'practice_load':
      case 'practice_save':
      case 'practice_save_as':
      case 'practice_title_update':
      case 'file_load':
      case 'file_save':
      case 'file_save_as':
        _notifyUIListeners('title_bar', changeType);
        _notifyUIListeners('status_bar', changeType);
        _notifyUIListeners('file_menu', changeType);
        if (changeType.contains('load')) {
          _notifyUIListeners('page_list', changeType);
          _notifyUIListeners('canvas', changeType);
          _notifyUIListeners('property_panel', changeType);
          _notifyUIListeners('toolbar', changeType);
          _notifyLayerListeners('content', changeType);
          _notifyLayerListeners('interaction', changeType);
        }
        hasListeners = true;
        break;

      // 元素高级操作
      case 'element_add_group_element':
      case 'element_remove_element':
      case 'element_ungroup_remove_element':
      case 'element_align_elements':
      case 'element_distribute_elements':
        _notifyUIListeners('canvas', changeType);
        _notifyUIListeners('property_panel', changeType);
        _notifyLayerListeners('content', changeType);
        _notifyLayerListeners('interaction', changeType);
        hasListeners = true;
        break;

      // 默认：全局通知
      default:
        EditPageLogger.performanceWarning(
          '未识别的变更类型，使用全局通知',
          data: {
            'changeType': changeType,
            'operation': operation,
          },
        );
        _notifyUIListeners('canvas', changeType);
        _notifyUIListeners('property_panel', changeType);
        _notifyLayerListeners('content', changeType);
        hasListeners = true;
        break;
    }

    final dispatchDuration = DateTime.now().difference(dispatchStartTime);

    if (hasListeners) {
      _skippedDispatches--;
    }

    EditPageLogger.performanceInfo(
      '智能状态分发完成',
      data: {
        'changeType': changeType,
        'operation': operation,
        'hasListeners': hasListeners,
        'notificationCount': notificationCount,
        'dispatchDurationMs': dispatchDuration.inMilliseconds,
        'skippedDispatches': _skippedDispatches,
      },
    );
  }

  /// 🚀 分发拖拽变化 - 只影响拖拽预览层
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
}
