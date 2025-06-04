import 'dart:async';

import 'package:flutter/material.dart';

/// 拖拽配置类
class DragConfig {
  /// 批量更新延迟时间（默认16ms = 60FPS）
  static const Duration batchUpdateDelay = Duration(milliseconds: 16);

  /// 拖拽开始阈值（像素）
  static const double dragStartThreshold = 5.0;

  /// 是否启用拖拽预览层
  static bool enableDragPreview = true;

  /// 是否启用批量更新
  static bool enableBatchUpdate = true;

  /// 拖拽预览透明度
  static double dragPreviewOpacity = 0.7;

  /// 调试模式
  static bool debugMode = false;

  /// 是否显示性能覆盖层
  static bool showPerformanceOverlay = false;

  /// 是否追踪拖拽帧率
  static bool trackDragFPS = true;
}

/// 拖拽状态管理器
///
/// 负责独立管理拖拽状态，分离拖拽预览和实际数据提交，
/// 实现拖拽过程中的批量位置更新和性能优化
class DragStateManager extends ChangeNotifier {
  static const Duration _batchUpdateDelay = Duration(milliseconds: 16); // 60FPS
  // 拖拽状态相关
  bool _isDragging = false;
  bool _isDragPreviewActive = false;

  Set<String> _draggingElementIds = <String>{};
  // 拖拽起始位置
  Offset _dragStartPosition = Offset.zero;

  Offset _currentDragOffset = Offset.zero;

  // 元素起始位置缓存
  final Map<String, Offset> _elementStartPositions = <String, Offset>{};

  // 实时拖拽位置（用于预览层）
  final Map<String, Offset> _previewPositions = <String, Offset>{};
  // 批量更新相关
  Timer? _batchUpdateTimer;
  final Map<String, Map<String, dynamic>> _pendingUpdates =
      <String, Map<String, dynamic>>{};
  // 回调函数
  Function(Map<String, Map<String, dynamic>> batchUpdates)? _onBatchUpdate;

  // 性能监控相关
  DateTime? _dragStartTime;
  DateTime? _lastUpdateTime;
  int _updateCount = 0;
  int _batchUpdateCount = 0;
  double _avgUpdateTime = 0.0;
  final List<double> _updateTimes = [];
  final List<int> _frameRates = [];

  double get averageUpdateTime => _avgUpdateTime;
  int get batchUpdateCount => _batchUpdateCount;
  Offset get currentDragOffset => _currentDragOffset;
  Duration? get dragDuration => _dragStartTime != null
      ? DateTime.now().difference(_dragStartTime!)
      : null;
  Set<String> get draggingElementIds => Set.unmodifiable(_draggingElementIds);
  Offset get dragStartPosition => _dragStartPosition;
  Map<String, Offset> get elementStartPositions =>
      Map.unmodifiable(_elementStartPositions);

  List<int> get frameRates => List.unmodifiable(_frameRates);
  // Getters
  bool get isDragging => _isDragging;
  bool get isDragPreviewActive => _isDragPreviewActive;
  Map<String, Offset> get previewPositions =>
      Map.unmodifiable(_previewPositions);
  // 性能监控相关的 getters
  int get updateCount => _updateCount;
  List<double> get updateTimes => List.unmodifiable(_updateTimes);

  /// 取消拖拽操作
  void cancelDrag() {
    debugPrint('❌ DragStateManager.cancelDrag() - 取消拖拽');
    endDrag(shouldCommitChanges: false);
  }

  @override
  void dispose() {
    debugPrint('🗑️ DragStateManager.dispose() - 释放资源');
    _batchUpdateTimer?.cancel();
    super.dispose();
  }

  /// 结束拖拽操作
  void endDrag({bool shouldCommitChanges = true}) {
    debugPrint('🔥 DragStateManager.endDrag() - 结束拖拽');
    debugPrint('   提交更改: $shouldCommitChanges');

    // 取消批量更新定时器
    _batchUpdateTimer?.cancel();

    if (shouldCommitChanges) {
      // 最终提交所有更改
      _commitFinalPositions();
    }

    // 记录拖拽性能数据
    if (DragConfig.trackDragFPS && _dragStartTime != null) {
      final dragEndTime = DateTime.now();
      final dragDuration = dragEndTime.difference(_dragStartTime!);

      // 计算平均帧率
      double avgFps = 0;
      if (_frameRates.isNotEmpty) {
        avgFps =
            _frameRates.fold(0, (sum, fps) => sum + fps) / _frameRates.length;
      }

      debugPrint('📊 DragStateManager - 拖拽性能汇总:');
      debugPrint('   拖拽持续时间: ${dragDuration.inMilliseconds}ms');
      debugPrint('   总更新次数: $_updateCount');
      debugPrint('   批量更新次数: $_batchUpdateCount');
      debugPrint('   平均更新时间: ${_avgUpdateTime.toStringAsFixed(2)}ms');
      debugPrint('   平均帧率: ${avgFps.toStringAsFixed(1)} FPS');

      // 检查是否有性能问题
      if (avgFps < 55) {
        debugPrint('⚠️ 警告: 拖拽帧率低于理想值 (60 FPS)');
      }
    }

    // 重置状态
    _isDragging = false;
    _isDragPreviewActive = false;
    _draggingElementIds.clear();
    _dragStartPosition = Offset.zero;
    _currentDragOffset = Offset.zero;
    _elementStartPositions.clear();
    _previewPositions.clear();
    _pendingUpdates.clear();

    notifyListeners();
  }

  /// 获取拖拽统计信息
  Map<String, dynamic> getDragStatistics() {
    return {
      'isDragging': _isDragging,
      'draggingElementCount': _draggingElementIds.length,
      'currentOffset': _currentDragOffset,
      'hasPendingUpdates': _pendingUpdates.isNotEmpty,
      'pendingUpdateCount': _pendingUpdates.length,
    };
  }

  /// 获取元素的预览位置
  Offset? getElementPreviewPosition(String elementId) {
    return _previewPositions[elementId];
  }

  /// 获取元素的起始位置
  Offset? getElementStartPosition(String elementId) {
    return _elementStartPositions[elementId];
  }

  /// 获取拖拽元素的轻量级预览数据
  /// 用于优化拖拽预览层的渲染性能
  Map<String, Map<String, dynamic>> getLightweightPreviewData() {
    final result = <String, Map<String, dynamic>>{};

    // 如果没有拖拽中的元素，返回空映射
    if (!_isDragging || _draggingElementIds.isEmpty) {
      return result;
    }

    // 为每个拖拽中的元素创建轻量级预览数据
    for (final elementId in _draggingElementIds) {
      final previewPosition = _previewPositions[elementId];
      final startPosition = _elementStartPositions[elementId];

      if (previewPosition != null) {
        result[elementId] = {
          'position': previewPosition,
          'startPosition': startPosition,
          'dragOffset': _currentDragOffset,
        };
      }
    }

    return result;
  }

  /// 获取性能优化配置
  Map<String, dynamic> getPerformanceOptimizationConfig() {
    return {
      'enableBatchUpdate': DragConfig.enableBatchUpdate,
      'batchUpdateDelay': DragConfig.batchUpdateDelay.inMilliseconds,
      'enableDragPreview': DragConfig.enableDragPreview,
      'dragPreviewOpacity': DragConfig.dragPreviewOpacity,
      'trackDragFPS': DragConfig.trackDragFPS,
    };
  }

  /// 获取性能报告数据
  Map<String, dynamic> getPerformanceReport() {
    final currentFps = _frameRates.isNotEmpty ? _frameRates.last : 0;
    final avgFps = _frameRates.isNotEmpty
        ? _frameRates.fold(0, (sum, fps) => sum + fps) / _frameRates.length
        : 0;

    return {
      'updateCount': _updateCount,
      'batchUpdateCount': _batchUpdateCount,
      'avgUpdateTime': _avgUpdateTime,
      'currentFps': currentFps,
      'avgFps': avgFps,
      'dragDuration': _dragStartTime != null
          ? DateTime.now().difference(_dragStartTime!).inMilliseconds
          : 0,
      'elementCount': _draggingElementIds.length,
      'isPerformanceCritical': currentFps < 45, // 帧率低于45时标记为性能关键
    };
  }

  /// 检查元素是否正在被拖拽
  bool isElementDragging(String elementId) {
    return _draggingElementIds.contains(elementId);
  }

  /// 设置更新回调
  void setUpdateCallbacks({
    Function(Map<String, Map<String, dynamic>> batchUpdates)? onBatchUpdate,
  }) {
    _onBatchUpdate = onBatchUpdate;
  }

  /// 开始拖拽操作
  void startDrag({
    required Set<String> elementIds,
    required Offset startPosition,
    required Map<String, Offset> elementStartPositions,
  }) {
    debugPrint('🔥 DragStateManager.startDrag() - 开始拖拽');
    debugPrint('   拖拽元素: $elementIds');
    debugPrint('   起始位置: $startPosition');

    _isDragging = true;
    _isDragPreviewActive = true;
    _draggingElementIds = Set.from(elementIds);
    _dragStartPosition = startPosition;
    _currentDragOffset = Offset.zero;

    // 缓存元素起始位置
    _elementStartPositions.clear();
    _elementStartPositions.addAll(elementStartPositions);

    // 初始化预览位置为起始位置
    _previewPositions.clear();
    for (final elementId in elementIds) {
      final startPos = elementStartPositions[elementId];
      if (startPos != null) {
        _previewPositions[elementId] = startPos;
      }
    }

    // 重置性能监控数据
    _dragStartTime = DateTime.now();
    _lastUpdateTime = _dragStartTime;
    _updateCount = 0;
    _batchUpdateCount = 0;
    _avgUpdateTime = 0.0;
    _updateTimes.clear();
    _frameRates.clear();

    notifyListeners();
  }

  /// 更新拖拽偏移量
  void updateDragOffset(Offset newOffset) {
    if (!_isDragging) return;

    final now = DateTime.now();

    // 计算每次更新的时间间隔
    if (_lastUpdateTime != null) {
      final updateTime = now.difference(_lastUpdateTime!).inMilliseconds;
      _updateTimes.add(updateTime.toDouble());

      // 计算帧率 (FPS = 1000ms / 每帧时间)
      if (updateTime > 0) {
        final fps = (1000 / updateTime).round();
        _frameRates.add(fps);
      }

      // 计算平均更新时间
      _avgUpdateTime = _updateTimes.fold(0.0, (sum, time) => sum + time) /
          _updateTimes.length;
    }

    _lastUpdateTime = now;
    _updateCount++;

    _currentDragOffset = newOffset;

    // 更新预览位置
    _updatePreviewPositions();

    // 批量更新实际位置（通过定时器实现节流）
    _scheduleBatchUpdate();

    notifyListeners();

    // 调试信息
    if (DragConfig.debugMode && _updateCount % 10 == 0) {
      debugPrint('📊 DragStateManager - 性能数据:');
      debugPrint('   更新次数: $_updateCount');
      debugPrint('   批量更新次数: $_batchUpdateCount');
      debugPrint('   平均更新时间: ${_avgUpdateTime.toStringAsFixed(2)}ms');
      debugPrint(
          '   当前帧率: ${_frameRates.isNotEmpty ? _frameRates.last : 0} FPS');
    }
  }

  /// 提交最终位置
  void _commitFinalPositions() {
    if (_previewPositions.isEmpty) return;

    debugPrint('💾 DragStateManager.commitFinalPositions() - 提交最终位置');

    final finalUpdates = <String, Map<String, dynamic>>{};

    for (final entry in _previewPositions.entries) {
      finalUpdates[entry.key] = {
        'x': entry.value.dx,
        'y': entry.value.dy,
      };
    }

    if (finalUpdates.isNotEmpty && _onBatchUpdate != null) {
      _onBatchUpdate!(finalUpdates);
    }
  }

  /// 处理批量更新
  void _processBatchUpdate() {
    if (_pendingUpdates.isNotEmpty && _onBatchUpdate != null) {
      final batchData = Map<String, Map<String, dynamic>>.from(_pendingUpdates);
      _pendingUpdates.clear();

      debugPrint('📦 DragStateManager.batchUpdate() - 批量更新元素位置');
      debugPrint('   更新元素数量: ${batchData.length}');

      // 统计批量更新次数
      _batchUpdateCount++;

      _onBatchUpdate!(batchData);
    }
  }

  /// 调度批量更新
  void _scheduleBatchUpdate() {
    // 取消之前的定时器
    _batchUpdateTimer?.cancel();

    // 准备批量更新数据
    for (final elementId in _draggingElementIds) {
      final previewPos = _previewPositions[elementId];
      if (previewPos != null) {
        _pendingUpdates[elementId] = {
          'x': previewPos.dx,
          'y': previewPos.dy,
        };
      }
    }

    // 设置新的定时器进行批量更新
    _batchUpdateTimer = Timer(_batchUpdateDelay, _processBatchUpdate);
  }

  /// 更新预览位置
  void _updatePreviewPositions() {
    for (final elementId in _draggingElementIds) {
      final startPos = _elementStartPositions[elementId];
      if (startPos != null) {
        _previewPositions[elementId] = startPos + _currentDragOffset;
      }
    }
  }
}
