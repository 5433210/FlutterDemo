import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../widgets/practice/practice_edit_controller.dart';
import 'layers/layer_types.dart';

/// 智能结构监听器 - 负责监听画布状态变化并路由到相应的渲染层级
/// 实现分层+元素级混合优化策略的核心调度组件
class CanvasStructureListener {
  final PracticeEditController _controller;
  final Map<RenderLayerType, Function(dynamic)> _layerHandlers = {};
  final Map<String, StreamSubscription> _subscriptions = {};

  /// 层级变化监听器
  final ValueNotifier<Map<RenderLayerType, LayerChangeEvent>> _layerChanges =
      ValueNotifier({});

  /// 性能统计
  final Map<RenderLayerType, LayerPerformanceStats> _performanceStats = {};

  /// 是否已释放
  bool _isDisposed = false;

  CanvasStructureListener(this._controller) {
    _initializeLayerHandlers();
    _startListening();
  }

  /// 获取层级变化通知器
  ValueNotifier<Map<RenderLayerType, LayerChangeEvent>> get layerChanges =>
      _layerChanges;

  /// 分发变化事件到相应层级
  void dispatchToLayer(RenderLayerType type, dynamic event) {
    if (_isDisposed) return;

    final handler = _layerHandlers[type];
    if (handler != null) {
      final stopwatch = Stopwatch()..start();

      try {
        handler(event);
        _updateLayerChange(
            type,
            LayerChangeEvent(
              type: LayerChangeType.update,
              timestamp: DateTime.now(),
              data: event,
            ));
      } catch (e) {
        debugPrint('📡 CanvasStructureListener: 层级处理器错误 - $type: $e');
        _updateLayerChange(
            type,
            LayerChangeEvent(
              type: LayerChangeType.error,
              timestamp: DateTime.now(),
              data: e,
            ));
      } finally {
        stopwatch.stop();
        _updatePerformanceStats(type, stopwatch.elapsedMicroseconds);
      }
    }
  }

  /// 释放资源
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    // 取消所有订阅
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();

    // 清理数据
    _layerHandlers.clear();
    _performanceStats.clear();
    _layerChanges.dispose();

    debugPrint('📡 CanvasStructureListener: 已释放资源');
  }

  /// 获取指定层级的性能统计
  LayerPerformanceStats? getLayerPerformanceStats(RenderLayerType type) {
    return _performanceStats[type];
  }

  /// 注册层级处理器
  void registerLayerHandler(RenderLayerType type, Function(dynamic) handler) {
    if (_isDisposed) return;
    _layerHandlers[type] = handler;
    debugPrint('📡 CanvasStructureListener: 注册层级处理器 - $type');
  }

  /// 取消注册层级处理器
  void unregisterLayerHandler(RenderLayerType type) {
    _layerHandlers.remove(type);
    debugPrint('📡 CanvasStructureListener: 取消注册层级处理器 - $type');
  }

  /// 处理页面变化
  void _handlePagesChange() {
    final currentPage = _controller.state.currentPage;
    final elements = _controller.state.currentPageElements;

    // 分发到StaticBackground层级
    dispatchToLayer(
        RenderLayerType.staticBackground,
        PageBackgroundChangeEvent(
          page: currentPage,
          timestamp: DateTime.now(),
        ));

    // 分发到Content层级
    dispatchToLayer(
        RenderLayerType.content,
        ElementsChangeEvent(
          elements: elements,
          timestamp: DateTime.now(),
        ));
  }

  /// 处理选择变化
  void _handleSelectionChange() {
    final selectedIds = _controller.state.selectedElementIds;

    // 分发到Interaction层级
    dispatchToLayer(
        RenderLayerType.interaction,
        SelectionChangeEvent(
          selectedIds: selectedIds.toSet(),
          timestamp: DateTime.now(),
        ));
  }

  /// 处理工具变化
  void _handleToolChange() {
    final currentTool = _controller.state.currentTool;

    // 分发到Interaction层级
    dispatchToLayer(
        RenderLayerType.interaction,
        ToolChangeEvent(
          newTool: currentTool,
          timestamp: DateTime.now(),
        ));
  }

  /// 初始化层级处理器
  void _initializeLayerHandlers() {
    // StaticBackground 层级处理器
    registerLayerHandler(RenderLayerType.staticBackground, (event) {
      if (event is PageBackgroundChangeEvent) {
        debugPrint('📡 StaticBackground: 处理页面背景变化');
      } else if (event is GridSettingsChangeEvent) {
        debugPrint('📡 StaticBackground: 处理网格设置变化');
      }
    });

    // Content 层级处理器
    registerLayerHandler(RenderLayerType.content, (event) {
      if (event is ElementsChangeEvent) {
        debugPrint('📡 Content: 处理元素变化 - ${event.elements.length} 个元素');
      } else if (event is LayerVisibilityChangeEvent) {
        debugPrint('📡 Content: 处理图层可见性变化');
      }
    });

    // DragPreview 层级处理器
    registerLayerHandler(RenderLayerType.dragPreview, (event) {
      if (event is DragStateChangeEvent) {
        debugPrint(
            '📡 DragPreview: 处理拖拽状态变化 - ${event.isDragging ? "开始" : "结束"}');
      }
    });

    // Interaction 层级处理器
    registerLayerHandler(RenderLayerType.interaction, (event) {
      if (event is SelectionChangeEvent) {
        debugPrint(
            '📡 Interaction: 处理选择变化 - ${event.selectedIds.length} 个选中元素');
      } else if (event is ToolChangeEvent) {
        debugPrint('📡 Interaction: 处理工具变化 - ${event.newTool}');
      }
    });
  }

  /// 开始监听控制器变化
  void _startListening() {
    // 监听页面变化
    _subscriptions['pages'] = _controller.addListener(() {
      _handlePagesChange();
    }) as StreamSubscription;

    // 监听工具变化
    _subscriptions['tools'] = _controller.addListener(() {
      _handleToolChange();
    }) as StreamSubscription;

    // 监听选择变化
    _subscriptions['selection'] = _controller.addListener(() {
      _handleSelectionChange();
    }) as StreamSubscription;
  }

  /// 更新层级变化
  void _updateLayerChange(RenderLayerType type, LayerChangeEvent event) {
    final currentChanges =
        Map<RenderLayerType, LayerChangeEvent>.from(_layerChanges.value);
    currentChanges[type] = event;
    _layerChanges.value = currentChanges;
  }

  /// 更新性能统计
  void _updatePerformanceStats(RenderLayerType type, int microseconds) {
    final stats = _performanceStats[type] ?? LayerPerformanceStats(type);
    stats.recordProcessingTime(microseconds);
    _performanceStats[type] = stats;
  }
}

/// 拖拽状态变化事件
class DragStateChangeEvent {
  final bool isDragging;
  final List<String> elementIds;
  final DateTime timestamp;

  DragStateChangeEvent({
    required this.isDragging,
    required this.elementIds,
    required this.timestamp,
  });
}

/// 元素变化事件
class ElementsChangeEvent {
  final List<Map<String, dynamic>> elements;
  final DateTime timestamp;

  ElementsChangeEvent({
    required this.elements,
    required this.timestamp,
  });
}

/// 网格设置变化事件
class GridSettingsChangeEvent {
  final double gridSize;
  final bool visible;
  final DateTime timestamp;

  GridSettingsChangeEvent({
    required this.gridSize,
    required this.visible,
    required this.timestamp,
  });
}

/// 层级变化事件
class LayerChangeEvent {
  final LayerChangeType type;
  final DateTime timestamp;
  final dynamic data;

  LayerChangeEvent({
    required this.type,
    required this.timestamp,
    this.data,
  });
}

/// 层级变化类型
enum LayerChangeType {
  update,
  error,
  performance,
}

/// 层级性能统计
class LayerPerformanceStats {
  final RenderLayerType type;
  final List<int> _processingTimes = [];
  int _totalProcessingTime = 0;
  int _eventCount = 0;

  LayerPerformanceStats(this.type);

  /// 获取平均处理时间（微秒）
  double get averageProcessingTime {
    return _eventCount > 0 ? _totalProcessingTime / _eventCount : 0.0;
  }

  /// 获取事件计数
  int get eventCount => _eventCount;

  /// 获取最大处理时间（微秒）
  int get maxProcessingTime {
    return _processingTimes.isNotEmpty
        ? _processingTimes.reduce((a, b) => a > b ? a : b)
        : 0;
  }

  /// 获取最小处理时间（微秒）
  int get minProcessingTime {
    return _processingTimes.isNotEmpty
        ? _processingTimes.reduce((a, b) => a < b ? a : b)
        : 0;
  }

  /// 记录处理时间
  void recordProcessingTime(int microseconds) {
    _processingTimes.add(microseconds);
    _totalProcessingTime += microseconds;
    _eventCount++;

    // 保持最近100次记录
    if (_processingTimes.length > 100) {
      final removed = _processingTimes.removeAt(0);
      _totalProcessingTime -= removed;
      _eventCount--;
    }
  }
}

/// 图层可见性变化事件
class LayerVisibilityChangeEvent {
  final String layerId;
  final bool visible;
  final DateTime timestamp;

  LayerVisibilityChangeEvent({
    required this.layerId,
    required this.visible,
    required this.timestamp,
  });
}

/// 页面背景变化事件
class PageBackgroundChangeEvent {
  final Map<String, dynamic>? page;
  final DateTime timestamp;

  PageBackgroundChangeEvent({
    required this.page,
    required this.timestamp,
  });
}

/// 选择变化事件
class SelectionChangeEvent {
  final Set<String> selectedIds;
  final DateTime timestamp;

  SelectionChangeEvent({
    required this.selectedIds,
    required this.timestamp,
  });
}

/// 工具变化事件
class ToolChangeEvent {
  final String newTool;
  final DateTime timestamp;

  ToolChangeEvent({
    required this.newTool,
    required this.timestamp,
  });
}
