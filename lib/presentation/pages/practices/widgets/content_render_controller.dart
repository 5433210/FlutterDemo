import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../widgets/practice/dirty_tracker.dart';
import '../../../widgets/practice/drag_state_manager.dart';
import '../../../widgets/practice/element_cache_manager.dart';
import '../../../widgets/practice/selective_rebuild_manager.dart';
import 'element_change_types.dart';

/// Controller for managing content rendering layer updates and notifications
class ContentRenderController extends ChangeNotifier {
  static const Duration _notificationThrottle =
      Duration(milliseconds: 16); // 60 FPS
  final List<ElementChangeInfo> _changeHistory = [];
  final Map<String, Map<String, dynamic>> _lastKnownProperties = {};

  final StreamController<ElementChangeInfo> _changeStreamController =
      StreamController<ElementChangeInfo>.broadcast();

  // 拖拽状态管理器引用
  DragStateManager? _dragStateManager;

  // 需要跳过渲染的元素列表 (将在DragPreviewLayer中显示)
  final Set<String> _elementsToSkip = <String>{};
  // 🔧 拖拽状态跟踪变量
  bool _lastIsDragging = false;
  bool _lastIsDragPreviewActive = false;

  Set<String> _lastDraggingElementIds = <String>{};
  // Smart rebuilding system components
  late final DirtyTracker _dirtyTracker;

  SelectiveRebuildManager? _rebuildManager;
  // 🚀 节流通知相关
  Timer? _notificationTimer;
  bool _hasPendingUpdate = false;
  DateTime _lastNotificationTime = DateTime.now();

  /// Initialize the controller with optional selective rebuilding
  ContentRenderController({
    bool enableSelectiveRebuilding = true,
  }) {
    _dirtyTracker = DirtyTracker();

    if (enableSelectiveRebuilding) {
      // Note: rebuildManager will be initialized when cacheManager is available
      // This is done in ContentRenderLayer when it creates the cache manager
    }
  }

  /// Get the change history
  List<ElementChangeInfo> get changeHistory =>
      List.unmodifiable(_changeHistory);

  /// Stream of element changes for reactive updates
  Stream<ElementChangeInfo> get changeStream => _changeStreamController.stream;

  /// Get the dirty tracker for selective rebuilding
  DirtyTracker get dirtyTracker => _dirtyTracker;

  /// 流式元素变更通知
  Stream<ElementChangeInfo> get elementChanges =>
      _changeStreamController.stream;

  /// 获取需要跳过渲染的元素列表
  Set<String> get elementsToSkip => Set.unmodifiable(_elementsToSkip);

  // 是否正在拖拽中
  bool get isDragging => _dragStateManager?.isDragging ?? false;

  /// Get selective rebuild manager (may be null if not enabled)
  SelectiveRebuildManager? get rebuildManager => _rebuildManager;

  void agStateChanged() {
    EditPageLogger.canvasDebug('拖拽状态变化，触发重建', data: {
      'isDragging': _dragStateManager?.isDragging,
      'draggingElementIds': _dragStateManager?.draggingElementIds
    });

    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'drag_state_changed',
      data: {
        'isDragging': _dragStateManager?.isDragging,
        'draggingElementIds': _dragStateManager?.draggingElementIds,
      },
    );
  }

  /// Clear change history
  void clearHistory() {
    _changeHistory.clear();
  }

  @override
  void dispose() {
    // 使用三重保护确保super.dispose()一定被调用
    bool superDisposeCompleted = false;

    try {
      try {
        _notificationTimer?.cancel();
      } catch (e) {
        debugPrint('取消通知计时器失败: $e');
      }

      try {
        _changeStreamController.close();
      } catch (e) {
        debugPrint('关闭stream controller失败: $e');
      }

      try {
        _dirtyTracker.dispose();
      } catch (e) {
        debugPrint('dispose dirty tracker失败: $e');
      }

      try {
        _rebuildManager?.dispose();
      } catch (e) {
        debugPrint('dispose rebuild manager失败: $e');
      }

      try {
        // 移除拖拽状态监听器
        _dragStateManager?.removeListener(_onDragStateChanged);
      } catch (e) {
        debugPrint('移除拖拽状态监听器失败: $e');
      }
    } catch (e) {
      debugPrint('ContentRenderController dispose过程中发生异常: $e');
    } finally {
      // 无论如何都确保super.dispose()被调用
      if (!superDisposeCompleted) {
        try {
          super.dispose();
          superDisposeCompleted = true;
        } catch (disposeError) {
          debugPrint(
              'ContentRenderController super.dispose()调用失败: $disposeError');
          // 尝试第三次调用
          try {
            super.dispose();
            superDisposeCompleted = true;
          } catch (finalError) {
            debugPrint(
                'ContentRenderController 最终super.dispose()调用失败: $finalError');
            // 即使最终失败，也标记为完成，避免无限循环
            superDisposeCompleted = true;
          }
        }
      }
    }

    // 额外的安全检查：如果所有尝试都失败，强制标记完成
    if (!superDisposeCompleted) {
      debugPrint('警告：ContentRenderController super.dispose()可能未能成功调用');
    }
  }

  /// Get changes for a specific element
  List<ElementChangeInfo> getChangesForElement(String elementId) {
    return _changeHistory
        .where((change) => change.elementId == elementId)
        .toList();
  }

  /// 获取元素的预览位置（如果正在拖拽中）
  Offset? getElementPreviewPosition(String elementId) {
    if (_dragStateManager == null || !_dragStateManager!.isDragging) {
      return null;
    }
    return _dragStateManager!.getElementPreviewPosition(elementId);
  }

  /// Get last known properties for an element
  Map<String, dynamic>? getLastKnownProperties(String elementId) {
    return _lastKnownProperties[elementId];
  }

  /// Get rebuild strategy for an element
  RebuildStrategy getRebuildStrategy(
      String elementId, ElementChangeType changeType) {
    return _rebuildManager?.getRebuildStrategy(elementId, changeType) ??
        RebuildStrategy.fullRebuild;
  }

  /// Get recent changes within a time window
  List<ElementChangeInfo> getRecentChanges(Duration timeWindow) {
    final cutoff = DateTime.now().subtract(timeWindow);
    return _changeHistory
        .where((change) => change.timestamp.isAfter(cutoff))
        .toList();
  }

  /// Initialize element properties tracking
  void initializeElement({
    required String elementId,
    required Map<String, dynamic> properties,
  }) {
    EditPageLogger.canvasDebug('初始化元素属性跟踪', data: {
      'elementId': elementId,
      'properties': properties.keys.join(', ')
    });
    _lastKnownProperties[elementId] = Map.from(properties);
  }

  /// Initialize multiple elements at once
  void initializeElements(List<Map<String, dynamic>> elements) {
    EditPageLogger.canvasDebug('批量初始化元素',
        data: {'elementCount': elements.length});
    for (final element in elements) {
      final elementId = element['id'] as String;
      final elementType = element['type'] as String?;
      EditPageLogger.canvasDebug('初始化元素',
          data: {'elementId': elementId, 'type': elementType});
      _lastKnownProperties[elementId] = Map.from(element);
    }
  }

  /// Initialize selective rebuild manager with cache manager
  void initializeSelectiveRebuilding(ElementCacheManager cacheManager) {
    _rebuildManager = SelectiveRebuildManager(
      dirtyTracker: _dirtyTracker,
      cacheManager: cacheManager,
    );
  }

  /// 检查元素是否正在被拖拽
  bool isElementDragging(String elementId) {
    if (_dragStateManager == null) return false;
    return _dragStateManager!.isElementDragging(elementId);
  }

  /// Check if element is being tracked
  bool isElementTracked(String elementId) {
    return _lastKnownProperties.containsKey(elementId);
  }

  /// Mark element as clean after rebuilding
  void markElementClean(String elementId) {
    _dirtyTracker.markElementClean(elementId);
  }

  /// Mark an element as dirty for rebuilding
  void markElementDirty(String elementId, ElementChangeType changeType) {
    _dirtyTracker.markElementDirty(elementId, changeType);
  }

  /// Mark multiple elements as dirty
  void markElementsDirty(Map<String, ElementChangeType> elements) {
    _dirtyTracker.markElementsDirty(elements);
  }

  /// Notify about element property changes
  void notifyElementChanged({
    required String elementId,
    required Map<String, dynamic> newProperties,
  }) {
    EditPageLogger.canvasDebug('元素属性变更通知', data: {
      'elementId': elementId,
      'newProperties': newProperties.keys.join(', ')
    });

    final oldProperties =
        _lastKnownProperties[elementId] ?? <String, dynamic>{};

    // Create change info
    final changeInfo = ElementChangeInfo.fromChanges(
      elementId: elementId,
      oldProperties: oldProperties,
      newProperties: newProperties,
    );

    // Update stored properties
    _lastKnownProperties[elementId] = Map.from(newProperties);

    // Add to history
    _changeHistory.add(changeInfo);

    // Limit history size
    if (_changeHistory.length > 100) {
      _changeHistory.removeAt(0);
    }

    // Mark element as dirty for selective rebuilding
    _dirtyTracker.markElementDirty(elementId, changeInfo.changeType);

    // Notify through stream only (avoid triggering broad notifyListeners)
    _changeStreamController.add(changeInfo);

    EditPageLogger.canvasDebug('元素变更类型', data: {
      'changeType': '${changeInfo.changeType}',
      'elementId': elementId
    });
  }

  /// Notify about element creation
  void notifyElementCreated({
    required String elementId,
    required Map<String, dynamic> properties,
  }) {
    final changeInfo = ElementChangeInfo(
      elementId: elementId,
      changeType: ElementChangeType.created,
      oldProperties: <String, dynamic>{},
      newProperties: Map.from(properties),
      timestamp: DateTime.now(),
    );
    _lastKnownProperties[elementId] = Map.from(properties);
    _changeHistory.add(changeInfo);

    if (_changeHistory.length > 100) {
      _changeHistory.removeAt(0);
    }

    // Mark new element as dirty
    _dirtyTracker.markElementDirty(elementId, ElementChangeType.created);

    _changeStreamController.add(changeInfo);

    EditPageLogger.canvasDebug('元素创建通知', data: {'elementId': elementId});
  }

  /// Notify about element deletion
  void notifyElementDeleted({
    required String elementId,
  }) {
    final oldProperties =
        _lastKnownProperties[elementId] ?? <String, dynamic>{};

    final changeInfo = ElementChangeInfo(
      elementId: elementId,
      changeType: ElementChangeType.deleted,
      oldProperties: Map.from(oldProperties),
      newProperties: <String, dynamic>{},
      timestamp: DateTime.now(),
    );
    _lastKnownProperties.remove(elementId);
    _changeHistory.add(changeInfo);

    if (_changeHistory.length > 100) {
      _changeHistory.removeAt(0);
    }

    // Remove element from dirty tracking
    _dirtyTracker.removeElement(elementId);
    _rebuildManager?.removeElement(elementId);

    _changeStreamController.add(changeInfo);

    EditPageLogger.canvasDebug('元素删除通知', data: {'elementId': elementId});
  }

  /// 刷新所有受监控的元素
  void refreshAll(String reason) {
    EditPageLogger.canvasDebug('刷新所有受监控元素',
        data: {'reason': reason, 'elementCount': _lastKnownProperties.length});

    // 标记所有受跟踪的元素为脏状态
    for (final elementId in _lastKnownProperties.keys) {
      markElementDirty(elementId, ElementChangeType.multiple);
    }

    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'refresh_all',
      data: {
        'reason': reason,
        'elementCount': _lastKnownProperties.length,
      },
    );

    EditPageLogger.canvasDebug('元素刷新完成',
        data: {'refreshedCount': _lastKnownProperties.length});
  }

  /// Reset controller state
  void reset() {
    _changeHistory.clear();
    _lastKnownProperties.clear();

    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'reset',
      data: {
        'historyCleared': true,
        'propertiesCleared': true,
      },
    );
  }

  /// 设置拖拽状态管理器
  void setDragStateManager(DragStateManager dragStateManager) {
    // 移除旧的监听器
    _dragStateManager?.removeListener(_onDragStateChanged);

    _dragStateManager = dragStateManager;

    // 添加新的监听器
    _dragStateManager?.addListener(_onDragStateChanged);

    EditPageLogger.canvasDebug('DragStateManager连接完成',
        data: {'hasListener': true});
  }

  /// Check if an element should be rebuilt
  bool shouldRebuildElement(String elementId) {
    return _rebuildManager?.shouldRebuildElement(elementId) ?? true;
  }

  /// 检查元素是否应该跳过渲染（由于拖拽预览层已处理）
  bool shouldSkipElementRendering(String elementId) {
    // 🔧 添加详细调试信息，包括DragStateManager实例信息
    final dragStateManager = _dragStateManager;
    final isDragStateManagerActive = dragStateManager != null;
    final isDragging = dragStateManager?.isDragging ?? false;
    final isDragPreviewActive = dragStateManager?.isDragPreviewActive ?? false;
    final isElementDragging =
        dragStateManager?.isElementDragging(elementId) ?? false;
    final enableDragPreview = DragConfig.enableDragPreview;
    final draggingElementIds =
        dragStateManager?.draggingElementIds ?? <String>{};
    final isSingleSelection = draggingElementIds.length == 1;

    // 快速退出 - 如果拖拽状态管理器无效，始终显示元素
    if (!isDragStateManagerActive) {
      return false;
    } // 快速退出 - 如果不在拖拽中，始终显示元素
    if (!isDragging || !isDragPreviewActive) {
      return false;
    } // 🔧 强化单选检查：确保单选时的元素能够正确隐藏
    if (isSingleSelection && draggingElementIds.contains(elementId)) {
      if (enableDragPreview) {
        return true;
      }
    }

    // 核心逻辑 - 仅当元素正在被拖拽且拖拽预览层启用时，才跳过元素渲染
    final shouldSkip = isElementDragging && enableDragPreview;

    return shouldSkip;
  }

  /// 拖拽状态变化处理方法
  void _onDragStateChanged() {
    // 当拖拽状态发生变化时更新渲染控制器的状态
    if (_dragStateManager != null) {
      final isDragging = _dragStateManager!.isDragging;
      final draggingElementIds = _dragStateManager!.draggingElementIds;
      final isDragPreviewActive = _dragStateManager!.isDragPreviewActive;

      // 🔧 使用实例变量进行状态跟踪

      // 添加调试信息
      EditPageLogger.canvasDebug('拖拽状态变更处理', data: {
        'isDragging': isDragging,
        'isDragPreviewActive': isDragPreviewActive,
        'draggingElementIds': draggingElementIds,
        'lastIsDragging': _lastIsDragging,
        'lastIsDragPreviewActive': _lastIsDragPreviewActive,
        'lastDraggingElementIds': _lastDraggingElementIds.toList(),
      });

      // 更新需要跳过渲染的元素列表（这些元素将在DragPreviewLayer中显示）
      _elementsToSkip.clear();
      if (isDragging && isDragPreviewActive) {
        _elementsToSkip.addAll(draggingElementIds);

        // 标记拖拽元素为脏状态，使其在下次内容层重建时重新渲染
        for (final elementId in draggingElementIds) {
          markElementDirty(elementId, ElementChangeType.multiple);
        }

        EditPageLogger.canvasDebug('拖拽开始：标记元素为脏状态', data: {
          'draggingElementIds': draggingElementIds.toList(),
          'optimization': 'mark_dragging_elements_dirty'
        });
      }

      // 🔧 更精确的拖拽开始和结束检测
      final isJustStartedDragging = isDragging &&
          isDragPreviewActive &&
          draggingElementIds.isNotEmpty &&
          (!_lastIsDragging ||
              !_lastIsDragPreviewActive ||
              _lastDraggingElementIds.isEmpty);

      final isJustEndedDragging = !isDragging &&
          !isDragPreviewActive &&
          draggingElementIds.isEmpty &&
          (_lastIsDragging ||
              _lastIsDragPreviewActive ||
              _lastDraggingElementIds.isNotEmpty);

      if (isJustStartedDragging) {
        // 拖拽刚开始：强制重建以隐藏原始元素
        EditPageLogger.canvasError('🔧🔧🔧 拖拽开始：强制ContentRenderLayer重建', data: {
          'reason': '隐藏拖拽中的原始元素',
          'draggingElementIds': draggingElementIds.toList(),
          'elementCount': draggingElementIds.length,
          'isSingleSelection': draggingElementIds.length == 1,
          'rebuildTrigger': 'drag_start',
          'precise': 'just_started_dragging',
        });

        // 强制元素缓存失效，确保shouldSkipElementRendering被调用
        for (final elementId in draggingElementIds) {
          EditPageLogger.canvasError('🔧🔧🔧 强制元素缓存失效', data: {
            'elementId': elementId,
            'reason': '确保拖拽时重新评估元素渲染',
            'fix': 'force_cache_invalidation',
          });

          markElementDirty(elementId, ElementChangeType.visibility);
          _rebuildManager?.removeElement(elementId);
        }

        // 立即通知，绕过节流机制
        EditPageLogger.canvasError('🔧🔧🔧 拖拽开始立即通知，绕过节流', data: {
          'reason': '确保拖拽时元素立即隐藏',
          'bypass': 'throttle_mechanism',
        });
        super.notifyListeners();
      } else if (isJustEndedDragging) {
        // 拖拽刚结束：强制重建以在新位置显示元素
        EditPageLogger.canvasError('🔧🔧🔧 拖拽结束：强制ContentRenderLayer重建', data: {
          'reason': '恢复元素在新位置的显示',
          'rebuildTrigger': 'drag_end',
          'precise': 'just_ended_dragging',
        });
        super.notifyListeners();
      } else {
        // 🔧 关键优化：拖拽过程中不触发ContentRenderLayer重建
        // 只有拖拽开始和结束时才需要重建ContentRenderLayer
        // 拖拽过程中的元素移动由DragPreviewLayer处理
        EditPageLogger.canvasDebug('拖拽过程中跳过ContentRenderLayer重建', data: {
          'reason': '拖拽过程中只需要DragPreviewLayer更新',
          'isDragging': isDragging,
          'isDragPreviewActive': isDragPreviewActive,
          'draggingElementIds': draggingElementIds,
          'isJustStarted': isJustStartedDragging,
          'isJustEnded': isJustEndedDragging,
          'optimization': 'skip_content_rebuild_during_drag',
        });

        // 🔧 不调用任何通知方法，保持ContentRenderLayer稳定
        // 拖拽过程中的视觉更新完全由DragPreviewLayer负责
      }

      // 🔧 更新历史状态用于下次比较
      _lastIsDragging = isDragging;
      _lastIsDragPreviewActive = isDragPreviewActive;
      _lastDraggingElementIds = Set.from(draggingElementIds);

      EditPageLogger.canvasDebug('拖拽状态更新完成', data: {
        'isDragging': isDragging,
        'draggingElementIds': draggingElementIds,
        'rebuildTriggered': isJustStartedDragging || isJustEndedDragging,
      });
    }
  }

  /// 🚀 节流通知方法 - 避免内容渲染控制器过于频繁地触发UI更新
  void _throttledNotifyListeners({
    required String operation,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _notificationThrottle) {
      _lastNotificationTime = now;

      // 🔧 优化：减少节流通知的日志输出频率
      if (operation == 'drag_state_update' || operation.contains('drag')) {
        // 拖拽相关操作减少日志
        if (now.millisecondsSinceEpoch % 100 == 0) {
          // 只输出1%的日志
          EditPageLogger.canvasDebug(
            '内容渲染控制器节流通知',
            data: {
              'operation': operation,
              'optimization': 'throttled_notification_reduced_logging',
              'reason': 'avoid_global_ui_rebuild',
              ...?data,
            },
          );
        }
      } else {
        EditPageLogger.canvasDebug(
          '内容渲染控制器跳过通知',
          data: {
            'operation': operation,
            'optimization': 'skip_content_render_notification',
            'reason': 'avoid_global_ui_rebuild',
            ...?data,
          },
        );
      }

      // super.notifyListeners(); // 🚀 已禁用以避免触发ContentRenderLayer重建
    } else {
      // 缓存待处理的更新
      if (!_hasPendingUpdate) {
        _hasPendingUpdate = true;
        _notificationTimer?.cancel();
        _notificationTimer = Timer(_notificationThrottle, () {
          _hasPendingUpdate = false;

          // 🔧 优化：延迟通知也减少日志
          if (operation == 'drag_state_update' || operation.contains('drag')) {
            // 拖拽相关操作几乎不输出延迟日志
            if (now.millisecondsSinceEpoch % 1000 == 0) {
              // 只输出0.1%的日志
              EditPageLogger.canvasDebug(
                '内容渲染控制器延迟节流通知',
                data: {
                  'operation': operation,
                  'optimization':
                      'delayed_throttled_notification_minimal_logging',
                  'reason': 'avoid_global_ui_rebuild',
                  ...?data,
                },
              );
            }
          } else {
            EditPageLogger.canvasDebug(
              '内容渲染控制器跳过延迟通知',
              data: {
                'operation': operation,
                'optimization': 'skip_delayed_content_render_notification',
                'reason': 'avoid_global_ui_rebuild',
                ...?data,
              },
            );
          }

          // super.notifyListeners(); // 🚀 已禁用以避免触发ContentRenderLayer重建
        });
      }
    }
  }
}
