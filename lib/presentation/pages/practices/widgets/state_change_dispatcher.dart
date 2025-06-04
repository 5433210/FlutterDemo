import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../widgets/practice/practice_edit_controller.dart';
import 'canvas_structure_listener.dart';
import 'layers/layer_types.dart';

/// 状态变化分发器 - 统一管理画布状态变化的分发和处理
/// 实现高效的状态同步和层级间通信
class StateChangeDispatcher {
  /// 批处理间隔（毫秒）
  static const int _batchIntervalMs = 16; // ~60fps
  final PracticeEditController _controller;

  final CanvasStructureListener _structureListener;

  /// 状态变化队列
  final List<StateChangeEvent> _changeQueue = [];

  /// 批处理计时器
  Timer? _batchTimer;

  /// 是否正在处理批次
  bool _processingBatch = false;

  /// 状态变化统计
  final Map<StateChangeType, int> _changeStats = {};

  /// 是否已释放
  bool _isDisposed = false;

  StateChangeDispatcher(this._controller, this._structureListener) {
    _initializeDispatcher();
  }

  /// 获取状态变化统计
  Map<StateChangeType, int> get changeStats => Map.unmodifiable(_changeStats);

  /// 是否正在处理批次
  bool get isProcessingBatch => _processingBatch;

  /// 获取队列长度
  int get queueLength => _changeQueue.length;

  /// 分发状态变化
  void dispatch(StateChangeEvent event) {
    if (_isDisposed) return;

    // 添加到队列
    _changeQueue.add(event);

    // 更新统计
    _changeStats[event.type] = (_changeStats[event.type] ?? 0) + 1;

    // 启动批处理计时器
    _scheduleBatchProcessing();

    debugPrint(
        '📤 StateChangeDispatcher: 分发事件 - ${event.type} (队列长度: ${_changeQueue.length})');
  }

  /// 释放资源
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _batchTimer?.cancel();
    _changeQueue.clear();
    _changeStats.clear();

    debugPrint('📤 StateChangeDispatcher: 已释放资源');
  }

  /// 立即处理所有待处理的变化
  void flush() {
    _batchTimer?.cancel();
    _processBatch();
  }

  /// 初始化分发器
  void _initializeDispatcher() {
    debugPrint('📤 StateChangeDispatcher: 初始化完成');
  }

  /// 处理批次
  void _processBatch() {
    if (_processingBatch || _changeQueue.isEmpty) {
      return;
    }

    _processingBatch = true;
    _batchTimer?.cancel();
    _batchTimer = null;

    try {
      final batchEvents = List<StateChangeEvent>.from(_changeQueue);
      _changeQueue.clear();

      debugPrint(
          '📤 StateChangeDispatcher: 开始处理批次 - ${batchEvents.length} 个事件');

      // 按类型分组处理
      final groupedEvents = <StateChangeType, List<StateChangeEvent>>{};
      for (final event in batchEvents) {
        groupedEvents.putIfAbsent(event.type, () => []).add(event);
      }

      // 按优先级顺序处理
      final priorityOrder = [
        StateChangeType.dragStart,
        StateChangeType.dragUpdate,
        StateChangeType.dragEnd,
        StateChangeType.selectionChange,
        StateChangeType.elementUpdate,
        StateChangeType.toolChange,
        StateChangeType.viewportChange,
        StateChangeType.layerVisibilityChange,
        StateChangeType.pageChange,
      ];

      for (final type in priorityOrder) {
        final events = groupedEvents[type];
        if (events != null && events.isNotEmpty) {
          _processEventsByType(type, events);
        }
      }

      debugPrint('📤 StateChangeDispatcher: 批次处理完成');
    } catch (e) {
      debugPrint('📤 StateChangeDispatcher: 批次处理错误 - $e');
    } finally {
      _processingBatch = false;

      // 如果队列中还有事件，继续处理
      if (_changeQueue.isNotEmpty) {
        _scheduleBatchProcessing();
      }
    }
  }

  /// 处理拖拽结束事件
  void _processDragEndEvents(List<StateChangeEvent> events) {
    final latestEvent = events.last;

    _structureListener.dispatchToLayer(
      RenderLayerType.dragPreview,
      DragStateChangeEvent(
        isDragging: false,
        elementIds: latestEvent.data['elementIds'] ?? [],
        timestamp: DateTime.now(),
      ),
    );

    _structureListener.dispatchToLayer(
      RenderLayerType.content,
      ElementsChangeEvent(
        elements: _controller.state.currentPageElements,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 处理拖拽开始事件
  void _processDragStartEvents(List<StateChangeEvent> events) {
    final latestEvent = events.last;

    _structureListener.dispatchToLayer(
      RenderLayerType.dragPreview,
      DragStateChangeEvent(
        isDragging: true,
        elementIds: latestEvent.data['elementIds'] ?? [],
        timestamp: DateTime.now(),
      ),
    );

    _structureListener.dispatchToLayer(
      RenderLayerType.interaction,
      DragStateChangeEvent(
        isDragging: true,
        elementIds: latestEvent.data['elementIds'] ?? [],
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 处理拖拽更新事件
  void _processDragUpdateEvents(List<StateChangeEvent> events) {
    // 只处理最新的拖拽更新，避免过度更新
    final latestEvent = events.last;

    _structureListener.dispatchToLayer(
      RenderLayerType.dragPreview,
      DragStateChangeEvent(
        isDragging: true,
        elementIds: latestEvent.data['elementIds'] ?? [],
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 处理元素更新事件
  void _processElementUpdateEvents(List<StateChangeEvent> events) {
    // 合并所有元素更新
    final allElements = _controller.state.currentPageElements;

    _structureListener.dispatchToLayer(
      RenderLayerType.content,
      ElementsChangeEvent(
        elements: allElements,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 按类型处理事件
  void _processEventsByType(
      StateChangeType type, List<StateChangeEvent> events) {
    switch (type) {
      case StateChangeType.dragStart:
        _processDragStartEvents(events);
        break;
      case StateChangeType.dragUpdate:
        _processDragUpdateEvents(events);
        break;
      case StateChangeType.dragEnd:
        _processDragEndEvents(events);
        break;
      case StateChangeType.selectionChange:
        _processSelectionChangeEvents(events);
        break;
      case StateChangeType.elementUpdate:
        _processElementUpdateEvents(events);
        break;
      case StateChangeType.toolChange:
        _processToolChangeEvents(events);
        break;
      case StateChangeType.viewportChange:
        _processViewportChangeEvents(events);
        break;
      case StateChangeType.layerVisibilityChange:
        _processLayerVisibilityChangeEvents(events);
        break;
      case StateChangeType.pageChange:
        _processPageChangeEvents(events);
        break;
    }
  }

  /// 处理图层可见性变化事件
  void _processLayerVisibilityChangeEvents(List<StateChangeEvent> events) {
    for (final event in events) {
      _structureListener.dispatchToLayer(
        RenderLayerType.content,
        LayerVisibilityChangeEvent(
          layerId: event.data['layerId'] ?? '',
          visible: event.data['visible'] ?? true,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  /// 处理页面变化事件
  void _processPageChangeEvents(List<StateChangeEvent> events) {
    final latestEvent = events.last;

    _structureListener.dispatchToLayer(
      RenderLayerType.staticBackground,
      PageBackgroundChangeEvent(
        page: _controller.state.currentPage,
        timestamp: DateTime.now(),
      ),
    );

    _structureListener.dispatchToLayer(
      RenderLayerType.content,
      ElementsChangeEvent(
        elements: _controller.state.currentPageElements,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 处理选择变化事件
  void _processSelectionChangeEvents(List<StateChangeEvent> events) {
    final latestEvent = events.last;

    _structureListener.dispatchToLayer(
      RenderLayerType.interaction,
      SelectionChangeEvent(
        selectedIds: Set<String>.from(latestEvent.data['selectedIds'] ?? []),
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 处理工具变化事件
  void _processToolChangeEvents(List<StateChangeEvent> events) {
    final latestEvent = events.last;

    _structureListener.dispatchToLayer(
      RenderLayerType.interaction,
      ToolChangeEvent(
        newTool: latestEvent.data['newTool'] ?? '',
        timestamp: DateTime.now(),
      ),
    );
  }

  /// 处理视口变化事件
  void _processViewportChangeEvents(List<StateChangeEvent> events) {
    // 处理视口变化，可能触发视口裁剪更新
    debugPrint('📤 StateChangeDispatcher: 处理视口变化事件');
  }

  /// 安排批处理
  void _scheduleBatchProcessing() {
    if (_batchTimer != null || _processingBatch) {
      return;
    }

    _batchTimer = Timer(const Duration(milliseconds: _batchIntervalMs), () {
      _processBatch();
    });
  }
}

/// 状态变化事件
class StateChangeEvent {
  final StateChangeType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  StateChangeEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// 状态变化类型
enum StateChangeType {
  dragStart,
  dragUpdate,
  dragEnd,
  selectionChange,
  elementUpdate,
  toolChange,
  viewportChange,
  layerVisibilityChange,
  pageChange,
}
