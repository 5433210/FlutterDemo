import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../pages/practices/helpers/element_utils.dart';
import 'batch_update_options.dart';
import 'drag_state_manager.dart';
import 'guideline_alignment/guideline_manager.dart';
import 'guideline_alignment/guideline_types.dart';
import 'practice_edit_controller.dart';
import 'smart_gesture_dispatcher.dart';

/// Enhanced gesture handler with smart dispatch system and multi-touch support
class SmartCanvasGestureHandler implements GestureContext {
  final PracticeEditController controller;
  final DragStateManager dragStateManager;
  final Function(bool, Offset, Offset, Map<String, Offset>) onDragStart;
  final VoidCallback onDragUpdate;
  final VoidCallback onDragEnd;
  final double Function() getScaleFactor;

  // Smart gesture dispatcher
  late final SmartGestureDispatcher _gestureDispatcher;

  // Enhanced gesture tracking
  final Map<int, _PointerTracker> _activePointers = {};
  final List<_GestureEventRecord> _gestureHistory = [];

  // Multi-touch state
  bool _isMultiTouchActive = false;
  _MultiTouchState? _multiTouchState;

  // Performance monitoring
  final Stopwatch _responseStopwatch = Stopwatch();
  final List<Duration> _responseTimes = [];

  // Conflict resolution
  Timer? _conflictResolutionTimer;
  _GestureMode _currentMode = _GestureMode.idle;

  // Legacy compatibility
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;
  final Map<String, Offset> _elementStartPositions = {};
  bool _isSelectionBoxActive = false;
  bool _isPanningEmptyArea = false;
  bool _isPanStartHandling = false;
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  Offset? _panEndPosition;
  bool _isDragging = false;

  // 防止重复创建撤销操作的记录
  final Set<String> _recentTranslationOperations = {};

  SmartCanvasGestureHandler({
    required this.controller,
    required this.dragStateManager,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.getScaleFactor,
  }) {
    _gestureDispatcher = SmartGestureDispatcher();
  }

  // _GestureContext implementation
  @override
  String get currentTool => controller.state.currentTool;

  @override
  List<Map<String, dynamic>> get elements =>
      controller.state.currentPageElements.cast<Map<String, dynamic>>();

  @override
  bool get hasSelectedElements =>
      controller.state.selectedElementIds.isNotEmpty;

  @override
  bool get isMultiSelectMode =>
      HardwareKeyboard.instance.isControlPressed ||
      HardwareKeyboard.instance.isShiftPressed;

  // Legacy compatibility getters
  bool get isSelectionBoxActive => _isSelectionBoxActive;

  Offset? get selectionBoxEnd => _selectionBoxEnd;

  Offset? get selectionBoxStart => _selectionBoxStart;

  void cancelSelectionBox() {
    _isSelectionBoxActive = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;
    onDragUpdate();
  }

  @override
  Future<GestureDispatchResult> clearSelection() async {
    controller.clearSelection();
    onDragUpdate();
    return GestureDispatchResult.handled();
  }

  @override
  Future<GestureDispatchResult> deselectElement(String elementId) async {
    // 🔧 修复：使用正确的deselectElement方法
    controller.deselectElement(elementId);
    onDragUpdate();
    return GestureDispatchResult.handled();
  }

  /// Cleanup resources
  void dispose() {
    EditPageLogger.canvasDebug('手势处理器销毁', data: {
      'timestamp': DateTime.now().toIso8601String(),
      'activePointers': _activePointers.length,
      'gestureHistory': _gestureHistory.length,
    });

    // 释放手势分发器
    _gestureDispatcher.dispose();

    // 取消冲突解决定时器
    _conflictResolutionTimer?.cancel();

    // 清理所有状态
    _activePointers.clear();
    _gestureHistory.clear();
    _responseTimes.clear();

    // 重置多指触控状态
    _isMultiTouchActive = false;
    _multiTouchState = null;
    _currentMode = _GestureMode.idle;

    // 清理拖拽相关状态
    _dragStart = Offset.zero;
    _elementStartPosition = Offset.zero;
    _elementStartPositions.clear();
    _isSelectionBoxActive = false;
    _isPanningEmptyArea = false;
    _isPanStartHandling = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;
    _panEndPosition = null;
    _isDragging = false;
    _recentTranslationOperations.clear();
  }

  @override
  Future<GestureDispatchResult> fastPanCanvas({
    required double velocity,
    required double direction,
  }) async {
    return await _handleFastCanvasPan(velocity, direction);
  }

  @override
  Future<GestureDispatchResult> finalizeElementDrag(String elementId) async {
    _finalizeElementDrag();
    return GestureDispatchResult.handled();
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final gestureStats = _gestureDispatcher.getPerformanceStats();

    if (_responseTimes.isEmpty) {
      return {
        ...gestureStats,
        'handlerResponseTime': 0,
        'handlerMaxTime': 0,
        'multiTouchActive': _isMultiTouchActive,
        'currentMode': _currentMode.toString(),
      };
    }

    final avgTime =
        _responseTimes.fold(0, (sum, time) => sum + time.inMicroseconds) ~/
            _responseTimes.length;
    final maxTime = _responseTimes
        .map((t) => t.inMicroseconds)
        .reduce((a, b) => a > b ? a : b);

    return {
      ...gestureStats,
      'handlerResponseTime': avgTime / 1000,
      'handlerMaxTime': maxTime / 1000,
      'multiTouchActive': _isMultiTouchActive,
      'currentMode': _currentMode.toString(),
      'activePointers': _activePointers.length,
    };
  }

  // Enhanced gesture handling methods

  Rect? getSelectionBoxRect() {
    if (_selectionBoxStart != null && _selectionBoxEnd != null) {
      return Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);
    }
    return null;
  }

  /// Handle pan cancel
  void handlePanCancel() {
    EditPageLogger.canvasDebug('画布平移操作取消');
    _currentMode = _GestureMode.idle;
    _isMultiTouchActive = false;
    _multiTouchState = null;
    onDragEnd();
  }

  /// Enhanced pan end with smart gesture completion
  Future<void> handlePanEnd(DragEndDetails details) async {
    _responseStopwatch.start();

    try {
      // Handle selection box finalization
      if (_isSelectionBoxActive) {
        _finalizeSelectionBox();
        return;
      }

      // Create synthetic pointer event for dispatcher
      final pointerEvent = _createSyntheticPointerEvent(
        PointerUpEvent,
        _dragStart, // Use last known position
      );

      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: pointerEvent,
        context: this,
      );

      if (!result.handled) {
        // Fallback to legacy handling
        await _handleLegacyPanEnd(details);
      }
    } finally {
      _responseStopwatch.stop();
      _updatePerformanceMetrics();
      _currentMode = _GestureMode.idle;
    }
  }

  /// Enhanced pan start with smart gesture detection
  Future<void> handlePanStart(
      DragStartDetails details, List<Map<String, dynamic>> elements) async {
    EditPageLogger.canvasDebug('手势开始处理', data: {
      'position': '${details.localPosition}',
      'selectedElements': controller.state.selectedElementIds.length,
      'currentTool': controller.state.currentTool,
      'elementCount': elements.length,
    });

    _responseStopwatch.start();

    try {
      // 对于潜在的拖拽操作，直接使用legacy处理避免gesture dispatcher误判
      // 检查是否可能是元素拖拽
      bool isPotentialElementDrag = false;
      if (controller.state.selectedElementIds.isNotEmpty) {
        EditPageLogger.canvasDebug('检查潜在拖拽操作', data: {
          'selectedCount': controller.state.selectedElementIds.length
        });
      }

      if (controller.state.selectedElementIds.isNotEmpty) {
        for (int i = elements.length - 1; i >= 0; i--) {
          final element = elements[i];
          final id = element['id'] as String;
          final x = (element['x'] as num).toDouble();
          final y = (element['y'] as num).toDouble();
          final width = (element['width'] as num).toDouble();
          final height = (element['height'] as num).toDouble();

          // Check if element is hidden or locked
          if (element['hidden'] == true) continue;
          final layerId = element['layerId'] as String?;
          if (layerId != null) {
            final layer = controller.state.getLayerById(layerId);
            if (layer != null && layer['isVisible'] == false) continue;
          }

          // Check if clicking inside selected element
          final bool isInside = details.localPosition.dx >= x &&
              details.localPosition.dx <= x + width &&
              details.localPosition.dy >= y &&
              details.localPosition.dy <= y + height;

          if (isInside && controller.state.selectedElementIds.contains(id)) {
            isPotentialElementDrag = true;
            break;
          }
        }
      }

      // 如果是潜在的元素拖拽或选择框操作，直接使用legacy处理
      if (isPotentialElementDrag || controller.state.currentTool == 'select') {
        EditPageLogger.canvasDebug('使用Legacy处理路径', data: {
          'isPotentialDrag': isPotentialElementDrag,
          'currentTool': controller.state.currentTool
        });
        await _handleLegacyPanStart(details, elements);
        return;
      }

      // 其他情况使用新的gesture dispatcher
      EditPageLogger.canvasDebug('使用SmartGestureDispatcher处理');
      final pointerEvent = _createSyntheticPointerEvent(
        PointerDownEvent,
        details.localPosition,
      );

      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: pointerEvent,
        context: this,
      );

      if (!result.handled) {
        EditPageLogger.canvasDebug('回退到Legacy处理');
        // Fallback to legacy handling
        await _handleLegacyPanStart(details, elements);
      }
    } finally {
      _responseStopwatch.stop();
      _updatePerformanceMetrics();
    }
  }

  /// Enhanced pan update with smart gesture recognition
  Future<void> handlePanUpdate(DragUpdateDetails details) async {
    EditPageLogger.canvasDebug('手势更新处理', data: {
      'position': '${details.localPosition}',
      'isDragging': dragStateManager.isDragging,
    });

    _responseStopwatch.start();

    try {
      // Handle selection box updates first (highest priority)
      if (_isSelectionBoxActive) {
        EditPageLogger.canvasDebug('选择框活跃状态更新');
        _selectionBoxEnd = details.localPosition;
        onDragUpdate();
        return;
      }

      // Create synthetic pointer event for dispatcher
      final pointerEvent = _createSyntheticPointerEvent(
        PointerMoveEvent,
        details.localPosition,
      );

      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: pointerEvent,
        context: this,
      );

      if (!result.handled) {
        EditPageLogger.canvasDebug('回退到Legacy路径处理');
        // Fallback to legacy handling
        await _handleLegacyPanUpdate(details);
      }
    } finally {
      _responseStopwatch.stop();
      _updatePerformanceMetrics();
    }
  }

  /// Handle raw pointer events with smart dispatching
  Future<void> handleRawPointerEvent(PointerEvent event) async {
    _responseStopwatch.start();

    try {
      // Update pointer tracking
      _updatePointerTracking(event);

      // Detect and handle multi-touch
      if (_activePointers.length > 1) {
        await _handleMultiTouchEvent(event);
        return;
      }

      // Use smart dispatcher for single-touch events
      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: event,
        context: this,
      );

      if (!result.handled) {
        // Fallback to legacy handling
        await _handleLegacyGesture(event);
      }
    } finally {
      _responseStopwatch.stop();
      _updatePerformanceMetrics();
    }
  }

  /// Handle right-click events
  void handleSecondaryTapDown(TapDownDetails details) {
    // 移除右键退出Select工具状态的功能
    // 保留取消选择框的功能
    if (_isSelectionBoxActive) {
      cancelSelectionBox();
      onDragUpdate();
    }
  }

  void handleSecondaryTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) {
    // 移除右键退出Select工具状态的功能
    // 右键仅用于上下文菜单等其他功能
  }

  /// Enhanced tap handling with smart gesture recognition
  Future<void> handleTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) async {
    _responseStopwatch.start();

    try {
      if (controller.state.isPreviewMode) return;

      // Create synthetic pointer event for dispatcher
      final pointerEvent = _createSyntheticPointerEvent(
        PointerUpEvent,
        details.localPosition,
      );

      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: pointerEvent,
        context: this,
      );

      if (!result.handled) {
        // Fallback to legacy handling
        await _handleLegacyTapUp(details, elements);
      }
    } finally {
      _responseStopwatch.stop();
      _updatePerformanceMetrics();
    }
  }

  @override
  bool isElementSelected(String elementId) {
    return controller.state.selectedElementIds.contains(elementId);
  }

  @override
  Future<GestureDispatchResult> rotateElements({
    required double rotationAngle,
    required Offset center,
  }) async {
    return await _handleMultiTouchRotation(rotationAngle, center);
  }

  @override
  Future<GestureDispatchResult> scaleElements({
    required double scaleRatio,
    required Offset center,
  }) async {
    return await _handleMultiTouchScale(scaleRatio, center);
  }

  @override
  Future<GestureDispatchResult> selectElement(String elementId) async {
    controller.selectElement(elementId, isMultiSelect: isMultiSelectMode);
    onDragUpdate();
    return GestureDispatchResult.handled();
  }

  @override
  Future<GestureDispatchResult> showContextMenu(Offset position) async {
    // Implementation would show context menu
    EditPageLogger.canvasDebug('显示上下文菜单', data: {'position': '$position'});
    return GestureDispatchResult.handled();
  }

  @override
  Future<GestureDispatchResult> updateElementDrag({
    required String elementId,
    required Offset delta,
    bool isBatched = false,
  }) async {
    // 🔍[RESIZE_FIX] 元素拖拽 Live阶段：通过SmartGestureDispatcher路径
    EditPageLogger.canvasDebug('SmartGestureDispatcher元素拖拽更新', data: {
      'elementId': elementId,
      'delta': '$delta',
      'isBatched': isBatched,
    });

    // 🔧 新增：在SmartGestureDispatcher路径中也应用参考线对齐
    var finalOffset = delta;
    if (controller.state.alignmentMode == AlignmentMode.guideline &&
        controller.state.selectedElementIds.length == 1) {
      final alignedOffset = _applyGuidelineAlignment(elementId, delta);
      if (alignedOffset != null) {
        finalOffset = alignedOffset;
      }
    }

    if (isBatched) {
      dragStateManager.updateDragOffset(finalOffset);
      // 🔍[RESIZE_FIX] 性能监控：只更新统计，不触发通知
      dragStateManager.updatePerformanceStatsOnly();
    } else {
      // Direct update for immediate response
      dragStateManager.updateDragOffset(finalOffset);
      // 🔍[RESIZE_FIX] 性能监控：只更新统计，不触发通知
      dragStateManager.updatePerformanceStatsOnly();
    }

    EditPageLogger.canvasDebug(
        'SmartGestureDispatcher路径优化: 跳过Controller更新保持流畅性');
    
    try {
      onDragUpdate();
    } catch (e, stackTrace) {
      EditPageLogger.canvasError('SmartGestureDispatcher拖拽更新回调异常', 
        error: e, 
        stackTrace: stackTrace,
        data: {
          'elementId': elementId,
          'operation': 'updateElementDrag_callback',
          'delta': delta.toString(),
        });
    }
    
    return GestureDispatchResult.handled();
  }

  /// 通用的参考线对齐检测方法
  /// 返回对齐后的偏移量，如果没有对齐则返回null
  Offset? _applyGuidelineAlignment(String elementId, Offset delta) {
    if (controller.state.alignmentMode != AlignmentMode.guideline) {
      return null;
    }

    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) return null;

    final currentBounds = Rect.fromLTWH(
      (element['x'] as num).toDouble() + delta.dx,
      (element['y'] as num).toDouble() + delta.dy,
      (element['width'] as num).toDouble(),
      (element['height'] as num).toDouble(),
    );    // 🔧 修复：在拖拽过程中只生成参考线用于显示，不强制对齐
    // 先生成参考线用于视觉反馈
    GuidelineManager.instance.updateGuidelinesLive(
      elementId: elementId,
      draftPosition: currentBounds.topLeft,
      elementSize: currentBounds.size,
    );

    // 更新活动参考线用于渲染
    controller
        .updateActiveGuidelines(GuidelineManager.instance.activeGuidelines);

    EditPageLogger.canvasDebug('参考线生成完成，显示参考线但不强制对齐', data: {
      'elementId': elementId,
      'delta': delta,
      'guidelinesCount': GuidelineManager.instance.activeGuidelines.length,
      'reason': 'guidelines_displayed_for_visual_feedback_only',
    });

    // 🔧 修复：在拖拽过程中不执行强制对齐，让用户可以自由拖拽
    // 只有在非常接近参考线时（距离小于2像素）才进行轻微的吸附
    final alignmentResult = GuidelineManager.instance.detectAlignment(
      elementId: elementId,
      currentPosition: currentBounds.topLeft,
      elementSize: currentBounds.size,
    );

    if (alignmentResult != null && alignmentResult['hasAlignment'] == true) {
      final alignedPosition = alignmentResult['position'] as Offset;
      final alignedX = alignedPosition.dx - (element['x'] as num).toDouble();
      final alignedY = alignedPosition.dy - (element['y'] as num).toDouble();
      final alignedOffset = Offset(alignedX, alignedY);

      // 计算对齐距离
      final alignmentDistance = (delta - alignedOffset).distance;

      // 🔧 修复：只有在距离非常小时（2像素内）才进行吸附对齐
      if (alignmentDistance <= 2.0) {
        EditPageLogger.canvasDebug('参考线吸附对齐生效', data: {
          'elementId': elementId,
          'originalOffset': delta,
          'alignedOffset': alignedOffset,
          'alignmentDistance': alignmentDistance,
          'threshold': 2.0,
        });
        return alignedOffset;
      } else {
        EditPageLogger.canvasDebug('参考线距离太远，不执行吸附对齐', data: {
          'elementId': elementId,
          'delta': delta,
          'alignmentDistance': alignmentDistance,
          'threshold': 2.0,
          'reason': 'distance_too_large_for_snap_alignment',
        });
        return null;
      }
    } else {
      EditPageLogger.canvasDebug('无参考线对齐，保持自由拖拽', data: {
        'elementId': elementId,
        'delta': delta,
        'reason': 'no_alignment_detected_free_drag',
      });
      return null;
    }
  }

  /// 🚀 新增：在鼠标释放时应用参考线对齐
  Offset? _applyGuidelineAlignmentOnRelease(
      String elementId, Offset currentOffset) {
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) return null;

    final currentPosition = Offset(
      (element['x'] as num).toDouble() + currentOffset.dx,
      (element['y'] as num).toDouble() + currentOffset.dy,
    );

    final elementSize = Size(
      (element['width'] as num).toDouble(),
      (element['height'] as num).toDouble(),
    );

    // 使用新的最佳对齐计算方法
    final alignmentResult = GuidelineManager.instance.calculateBestAlignment(
      elementId: elementId,
      currentPosition: currentPosition,
      elementSize: elementSize,
    );

    if (alignmentResult != null) {
      // 计算对齐后的偏移
      final alignedPosition = alignmentResult['position'] as Offset;
      final alignedX = alignedPosition.dx - (element['x'] as num).toDouble();
      final alignedY = alignedPosition.dy - (element['y'] as num).toDouble();
      final alignedOffset = Offset(alignedX, alignedY);

      EditPageLogger.canvasDebug('参考线对齐应用', data: {
        'elementId': elementId,
        'currentOffset': currentOffset,
        'alignedOffset': alignedOffset,
        'alignmentType': alignmentResult['type'],
        'distance': alignmentResult['distance'],
      });

      return alignedOffset;
    }

    return null;
  }

  double _calculateAngle(Offset a, Offset b) {
    return atan2(b.dy - a.dy, b.dx - a.dx);
  }

  Offset _calculateCenter(List<Offset> points) {
    if (points.isEmpty) return Offset.zero;

    double totalX = 0, totalY = 0;
    for (final point in points) {
      totalX += point.dx;
      totalY += point.dy;
    }

    return Offset(totalX / points.length, totalY / points.length);
  }

  double _calculateDistance(Offset a, Offset b) {
    return sqrt(pow(a.dx - b.dx, 2) + pow(a.dy - b.dy, 2));
  }

  PointerEvent _createSyntheticPointerEvent(Type eventType, Offset position) {
    // Create synthetic pointer events for dispatcher compatibility
    switch (eventType) {
      case PointerDownEvent:
        return PointerDownEvent(
          pointer: 0,
          position: position,
        );
      case PointerMoveEvent:
        return PointerMoveEvent(
          pointer: 0,
          position: position,
        );
      case PointerUpEvent:
        return PointerUpEvent(
          pointer: 0,
          position: position,
        );
      default:
        throw ArgumentError('Unsupported event type: $eventType');
    }
  }

  void _finalizeCanvasPan() {
    final endPoint = _panEndPosition ?? _dragStart;
    final dragDistance = (_dragStart - endPoint).distance;
    final isClick = dragDistance < 1.0; // 🔧 降低点击检测阈值

    if (_isPanningEmptyArea &&
        isClick &&
        !controller.state.isCtrlOrShiftPressed) {
      controller.clearSelection();
    }
    _isPanningEmptyArea = false;
    _panEndPosition = null;
    onDragEnd();
  }

  void _finalizeElementDrag() {
    EditPageLogger.canvasDebug('元素拖拽Commit阶段开始');
    _isDragging = false;

    // 🔍[RESIZE_FIX] Commit阶段：计算最终位置并一次性更新Controller
    final List<String> elementIds = [];
    final List<Map<String, dynamic>> oldPositions = [];
    final List<Map<String, dynamic>> newPositions = [];
    final Map<String, Map<String, dynamic>> finalUpdates = {};

    // 从DragStateManager获取最终拖拽偏移
    var finalOffset = dragStateManager.currentDragOffset;
    EditPageLogger.canvasDebug('最终拖拽偏移计算', data: {'offset': '$finalOffset'});

    // 🚀 新增：在鼠标释放时应用参考线对齐
    if (controller.state.alignmentMode == AlignmentMode.guideline &&
        controller.state.selectedElementIds.length == 1) {
      final elementId = controller.state.selectedElementIds.first;
      final alignedOffset =
          _applyGuidelineAlignmentOnRelease(elementId, finalOffset);
      if (alignedOffset != null) {
        finalOffset = alignedOffset;
        EditPageLogger.canvasDebug('应用参考线对齐', data: {
          'originalOffset': '$finalOffset',
          'alignedOffset': '$alignedOffset',
        });
      }
    }

    for (final elementId in controller.state.selectedElementIds) {
      final startPosition = _elementStartPositions[elementId];
      if (startPosition == null) continue;

      // 计算最终位置
      final finalX = startPosition.dx + finalOffset.dx;
      final finalY = startPosition.dy + finalOffset.dy;

      // 检查是否有实际移动
      if (startPosition.dx != finalX || startPosition.dy != finalY) {
        elementIds.add(elementId);
        oldPositions.add({'x': startPosition.dx, 'y': startPosition.dy});
        newPositions.add({'x': finalX, 'y': finalY});

        // 准备批量更新数据
        finalUpdates[elementId] = {
          'x': finalX,
          'y': finalY,
        };
      }
    }

    // 🔍[RESIZE_FIX] Commit阶段：一次性批量更新Controller
    if (finalUpdates.isNotEmpty) {
      EditPageLogger.canvasDebug('批量更新元素最终位置',
          data: {'updateCount': finalUpdates.length});
      controller.batchUpdateElementProperties(
        finalUpdates,
        options: BatchUpdateOptions.forDragOperation(),
      );

      // 检查是否需要创建撤销操作（防止重复创建）
      final operationKey =
          '${elementIds.join('_')}_${DateTime.now().millisecondsSinceEpoch ~/ 200}';
      if (!_recentTranslationOperations.contains(operationKey)) {
        _recentTranslationOperations.add(operationKey);
        Timer(const Duration(milliseconds: 500), () {
          _recentTranslationOperations.remove(operationKey);
        });

        // 创建撤销操作
        controller.createElementTranslationOperation(
          elementIds: elementIds,
          oldPositions: oldPositions,
          newPositions: newPositions,
        );

        EditPageLogger.canvasDebug('创建平移撤销操作', data: {
          'elementCount': elementIds.length,
          'operationKey': operationKey,
        });
      } else {
        EditPageLogger.canvasDebug('跳过重复平移撤销操作', data: {
          'operationKey': operationKey,
        });
      }

      EditPageLogger.canvasDebug('元素位置更新完成');
    }

    // 🚀 拖拽结束后清空参考线
    controller.clearActiveGuidelines();

    // 结束拖拽状态
    dragStateManager.endDrag();
    onDragEnd();
  }

  void _finalizeSelectionBox() {
    if (_selectionBoxStart == null || _selectionBoxEnd == null) {
      _isSelectionBoxActive = false;
      onDragUpdate();
      return;
    }

    final selectionRect =
        Rect.fromPoints(_selectionBoxStart!, _selectionBoxEnd!);

    if (selectionRect.width < 5 && selectionRect.height < 5) {
      _isSelectionBoxActive = false;
      _selectionBoxStart = null;
      _selectionBoxEnd = null;
      onDragUpdate();
      return;
    }

    final isMultiSelect = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed;

    if (!isMultiSelect) {
      controller.clearSelection();
    }

    // Select elements within selection box
    for (final element in controller.state.currentPageElements) {
      if (element['hidden'] == true) continue;

      final layerId = element['layerId'] as String?;
      if (layerId != null) {
        final layer = controller.state.getLayerById(layerId);
        if (layer != null && layer['isVisible'] == false) continue;
      }

      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();
      final elementRect = Rect.fromLTWH(x, y, width, height);

      if (selectionRect.overlaps(elementRect)) {
        final id = element['id'] as String;
        controller.selectElement(id, isMultiSelect: true);
      }
    }

    _isSelectionBoxActive = false;
    _selectionBoxStart = null;
    _selectionBoxEnd = null;
    onDragUpdate();
  }

  /// 🚀 新增：生成实时参考线用于调试显示
  void _generateRealTimeGuidelines(String elementId, Offset delta) {
    final element = controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) return;

    final draggedPosition = Offset(
      (element['x'] as num).toDouble() + delta.dx,
      (element['y'] as num).toDouble() + delta.dy,
    );

    final draggedSize = Size(
      (element['width'] as num).toDouble(),
      (element['height'] as num).toDouble(),
    );    // 生成实时参考线用于调试显示
    final hasGuidelines = GuidelineManager.instance.generateRealTimeGuidelines(
      elementId: elementId,
      currentPosition: draggedPosition,
      elementSize: draggedSize,
    );

    EditPageLogger.canvasDebug('生成实时参考线', data: {
      'elementId': elementId,
      'draggedPosition': '$draggedPosition',
      'draggedSize': '$draggedSize',
      'hasGuidelines': hasGuidelines,
      'guidelinesCount': controller.state.activeGuidelines.length,
    });
  }

  void _handleElementDragUpdate(Offset currentPosition) {
    try {
      EditPageLogger.canvasDebug('元素拖拽更新', data: {
        'currentPosition': '$currentPosition',
        'startPosition': '$_dragStart'
      });

      final dx = currentPosition.dx - _dragStart.dx;
      final dy = currentPosition.dy - _dragStart.dy;

      var finalOffset = Offset(dx, dy);

      // 🚀 新增：实时生成参考线用于调试显示（不进行对齐）
      if (controller.state.alignmentMode == AlignmentMode.guideline &&
          controller.state.selectedElementIds.length == 1) {
        final elementId = controller.state.selectedElementIds.first;
        _generateRealTimeGuidelines(elementId, Offset(dx, dy));
      }

      // 获取缩放因子并调整拖拽偏移（不影响参考线检测）
      final scaleFactor = getScaleFactor();

      EditPageLogger.canvasDebug('拖拽偏移计算', data: {
        'originalOffset': Offset(dx, dy),
        'finalOffset': finalOffset,
        'scaleFactor': scaleFactor,
        'alignmentMode': controller.state.alignmentMode.name,
        'guidelinesDisplayed': controller.state.activeGuidelines.length,
      });

      // 更新拖拽状态
      dragStateManager.updateDragOffset(finalOffset);
      _isDragging = true;

      EditPageLogger.canvasDebug('拖拽状态更新完成，触发UI更新');

      onDragUpdate();
    } catch (e, stackTrace) {
      EditPageLogger.canvasError('元素拖拽更新异常', 
        error: e, 
        stackTrace: stackTrace,
        data: {
          'elementId': 'unknown',
          'operation': 'element_drag_update',
          'currentPosition': currentPosition.toString(),
        });
    }
  }

  void _handleElementSelection(
      String id, Map<String, dynamic> element, bool isMultiSelect) {
    final isCurrentlySelected =
        controller.state.selectedElementIds.contains(id);
    final isLocked = element['locked'] == true;

    EditPageLogger.canvasDebug('处理元素选择', data: {
      'elementId': id,
      'currentlySelected': isCurrentlySelected,
      'multiSelect': isMultiSelect,
      'locked': isLocked
    });

    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    if (layerId != null) {
      final layer = controller.state.getLayerById(layerId);
      if (layer != null) {
        isLayerLocked = layer['isLocked'] == true;
      }
    }

    if (isLocked || isLayerLocked) {
      EditPageLogger.canvasDebug('元素被锁定，执行锁定元素选择逻辑');
      controller.state.selectedLayerId = null;
      controller.selectElement(id, isMultiSelect: isMultiSelect);
    } else {
      controller.state.selectedLayerId = null;

      if (isCurrentlySelected && !isMultiSelect) {
        // 🔧 修复：在单选模式下，点击已选中元素会取消选择（反选）
        EditPageLogger.canvasDebug('单选模式反选元素');
        controller.clearSelection();
      } else if (isCurrentlySelected && isMultiSelect) {
        // 🔧 修复：在多选模式下，点击已选中元素会从选择中移除
        EditPageLogger.canvasDebug('多选模式反选元素');
        controller.deselectElement(id);
      } else {
        // 选择新元素
        EditPageLogger.canvasDebug('选择新元素');
        controller.selectElement(id, isMultiSelect: isMultiSelect);
      }
    }

    EditPageLogger.canvasDebug('元素选择处理完成',
        data: {'selectedElements': controller.state.selectedElementIds.length});
  }

  Future<GestureDispatchResult> _handleFastCanvasPan(
      double velocity, double direction) async {
    EditPageLogger.canvasDebug('快速画布平移',
        data: {'velocity': velocity, 'direction': direction});

    // Calculate pan delta based on velocity and direction
    final deltaX = cos(direction) * velocity * 0.016; // Assume 60 FPS
    final deltaY = sin(direction) * velocity * 0.016;
    final delta = Offset(deltaX, deltaY);

    _elementStartPosition = delta;
    onDragUpdate();

    return GestureDispatchResult.handled();
  }

  // Legacy gesture handling for fallback

  Future<void> _handleLegacyGesture(PointerEvent event) async {
    // Implement legacy gesture handling as fallback
    EditPageLogger.canvasDebug('使用Legacy手势处理',
        data: {'eventType': '${event.runtimeType}'});
  }

  Future<void> _handleLegacyPanEnd(DragEndDetails details) async {
    if (dragStateManager.isDragging) {
      _finalizeElementDrag();
    } else if (_currentMode == _GestureMode.selectionBox) {
      // 结束选择框操作
      _isSelectionBoxActive = false;
      _currentMode = _GestureMode.idle;
    } else if (_currentMode == _GestureMode.idle) {
      // idle模式：不做任何操作
      EditPageLogger.canvasDebug('idle模式结束，无需处理');
    } else {
      _finalizeCanvasPan();
    }
  }

  Future<void> _handleLegacyPanStart(
      DragStartDetails details, List<Map<String, dynamic>> elements) async {
    EditPageLogger.canvasDebug('Legacy Pan Start处理', data: {
      'currentTool': controller.state.currentTool,
      'isPreviewMode': controller.state.isPreviewMode,
      'elementCount': elements.length
    });

    _isPanStartHandling = true; // 标记正在处理PanStart
    _dragStart = details.localPosition;
    _currentMode = _GestureMode.pan;

    try {
      // 如果不在预览模式，检查手势类型
      if (!controller.state.isPreviewMode) {
        // 1. 首先检查是否点击在已选中的元素上（元素拖拽 - 在任何工具模式下都可以）
        for (int i = elements.length - 1; i >= 0; i--) {
          final element = elements[i];
          final id = element['id'] as String;
          final x = (element['x'] as num).toDouble();
          final y = (element['y'] as num).toDouble();
          final width = (element['width'] as num).toDouble();
          final height = (element['height'] as num).toDouble();

          // Check if element is hidden
          if (element['hidden'] == true) continue;

          // Check if layer is hidden
          final layerId = element['layerId'] as String?;
          bool isLayerHidden = false;
          if (layerId != null) {
            final layer = controller.state.getLayerById(layerId);
            if (layer != null) {
              isLayerHidden = layer['isVisible'] == false;
            }
          }
          if (isLayerHidden) continue;

          // Check if clicking inside element
          final bool isInside = details.localPosition.dx >= x &&
              details.localPosition.dx <= x + width &&
              details.localPosition.dy >= y &&
              details.localPosition.dy <= y + height;

          if (isInside && controller.state.selectedElementIds.contains(id)) {
            EditPageLogger.canvasDebug('检测到点击已选中元素', data: {
              'elementId': id,
              'selectedElementsCount':
                  controller.state.selectedElementIds.length,
              'currentTool': controller.state.currentTool
            });

            // Check if element is locked
            final isLocked = element['locked'] == true;
            bool isLayerLocked = false;
            if (layerId != null) {
              final layer = controller.state.getLayerById(layerId);
              if (layer != null) {
                isLayerLocked = layer['isLocked'] == true;
              }
            }

            EditPageLogger.canvasDebug('检查元素锁定状态',
                data: {'isLocked': isLocked, 'isLayerLocked': isLayerLocked});

            if (!isLocked && !isLayerLocked) {
              EditPageLogger.canvasDebug('开始拖拽已选中元素', data: {
                'elementId': id,
                'tool': controller.state.currentTool
              });
              _setupElementDragging(elements);
              return;
            } else {
              EditPageLogger.editPageWarning('元素被锁定，无法拖拽');
            }
            break;
          }
        }

        // 2. 如果在select模式下，开始选择框（框选模式）
        if (controller.state.currentTool == 'select') {
          EditPageLogger.canvasDebug('开始选择框操作（框选模式）');
          _startSelectionBox(details.localPosition);
          return;
        }
      }

      // 3. 其他情况 - 让InteractiveViewer处理画布平移
      EditPageLogger.canvasDebug('让InteractiveViewer处理画布平移');
      _currentMode = _GestureMode.idle;
    } finally {
      _isPanStartHandling = false; // 清除PanStart处理标记
    }
  }

  Future<void> _handleLegacyPanUpdate(DragUpdateDetails details) async {
    final currentPosition = details.localPosition;
    final scaleFactor = getScaleFactor();
    final inverseScale = scaleFactor > 0 ? 1.0 / scaleFactor : 1.0;

    EditPageLogger.canvasDebug('Legacy Pan Update处理', data: {
      'currentPosition': '$currentPosition',
      'isDragging': dragStateManager.isDragging,
      'mode': '$_currentMode'
    });

    if (controller.state.isPreviewMode) {
      _handlePreviewModePan(currentPosition, inverseScale);
      return;
    }

    if (dragStateManager.isDragging) {
      EditPageLogger.canvasDebug('检测到拖拽状态，调用元素拖拽更新');
      _handleElementDragUpdate(currentPosition);
    } else if (_currentMode == _GestureMode.selectionBox) {
      // 处理选择框更新
      _selectionBoxEnd = currentPosition;
      onDragUpdate();
    } else if (_currentMode == _GestureMode.idle) {
      // idle模式：完全不处理，让InteractiveViewer处理画布平移
      EditPageLogger.canvasDebug('idle模式，不拦截手势');
      return;
    } else {
      // 其他模式的画布平移由InteractiveViewer处理
      EditPageLogger.canvasDebug('画布平移由InteractiveViewer处理');
    }
  }

  Future<void> _handleLegacyTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) async {
    // 如果正在处理PanStart事件，跳过TapUp处理，避免时序冲突
    if (_isPanStartHandling) {
      EditPageLogger.canvasDebug('正在处理PanStart，跳过TapUp处理');
      return;
    }

    // 如果当前模式不是idle，说明已经进入了特殊手势处理模式，跳过TapUp
    if (_currentMode != _GestureMode.idle) {
      EditPageLogger.canvasDebug('当前手势模式非idle，跳过TapUp处理',
          data: {'currentMode': '$_currentMode'});
      return;
    }

    // 如果正在拖拽，不处理tapUp事件，避免干扰拖拽操作
    if (_isDragging || dragStateManager.isDragging) {
      EditPageLogger.canvasDebug('正在拖拽，跳过TapUp处理');
      return;
    }

    bool hitElement = false;
    final isMultiSelect = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed;

    EditPageLogger.canvasDebug('TapUp开始处理点击事件', data: {
      'selectedElements': controller.state.selectedElementIds.length,
      'isMultiSelect': isMultiSelect
    });

    // Check elements from top to bottom
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      final id = element['id'] as String;
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      // Skip hidden elements
      if (element['hidden'] == true) continue;

      // Skip hidden layers
      final layerId = element['layerId'] as String?;
      if (layerId != null) {
        final layer = controller.state.getLayerById(layerId);
        if (layer != null && layer['isVisible'] == false) continue;
      }

      // Check if clicked inside element
      final bool isInside = details.localPosition.dx >= x &&
          details.localPosition.dx <= x + width &&
          details.localPosition.dy >= y &&
          details.localPosition.dy <= y + height;

      if (isInside) {
        hitElement = true;
        EditPageLogger.canvasDebug('TapUp - 点击到元素: $id');
        _handleElementSelection(id, element, isMultiSelect);
        break;
      }
    }

    if (!hitElement && !isMultiSelect) {
      EditPageLogger.canvasDebug('TapUp - 点击空白区域，清除选择');
      controller.clearSelection();
    }
  }

  // Multi-touch gesture handling

  Future<void> _handleMultiTouchEvent(PointerEvent event) async {
    if (_activePointers.length < 2) return;

    final pointers = _activePointers.values.toList();
    final pointer1 = pointers[0];
    final pointer2 = pointers[1];

    // Initialize multi-touch state
    if (_multiTouchState == null) {
      _multiTouchState = _MultiTouchState(
        initialDistance: _calculateDistance(
            pointer1.currentPosition, pointer2.currentPosition),
        initialAngle:
            _calculateAngle(pointer1.currentPosition, pointer2.currentPosition),
        initialCenter: _calculateCenter(
            [pointer1.currentPosition, pointer2.currentPosition]),
      );
      _isMultiTouchActive = true;
      _currentMode = _GestureMode.multiTouch;
      return;
    }

    final currentDistance =
        _calculateDistance(pointer1.currentPosition, pointer2.currentPosition);
    final currentAngle =
        _calculateAngle(pointer1.currentPosition, pointer2.currentPosition);
    final currentCenter =
        _calculateCenter([pointer1.currentPosition, pointer2.currentPosition]);

    // Scale detection
    final scaleRatio = currentDistance / _multiTouchState!.initialDistance;
    if ((scaleRatio - 1.0).abs() > 0.05) {
      // 5% threshold
      await _handleMultiTouchScale(scaleRatio, currentCenter);
    }

    // Rotation detection
    final rotationAngle = currentAngle - _multiTouchState!.initialAngle;
    if (rotationAngle.abs() > 0.05) {
      // ~3 degrees threshold
      await _handleMultiTouchRotation(rotationAngle, currentCenter);
    }

    // Multi-touch pan detection
    final centerDelta = currentCenter - _multiTouchState!.initialCenter;
    if (centerDelta.distance > 5.0) {
      await _handleMultiTouchPan(centerDelta);
    }
  }

  Future<GestureDispatchResult> _handleMultiTouchPan(Offset delta) async {
    EditPageLogger.canvasDebug('多点触控平移', data: {'delta': '$delta'});

    if (hasSelectedElements) {
      // Pan selected elements
      dragStateManager.updateDragOffset(delta);
    } else {
      // Pan canvas
      _elementStartPosition = delta;
    }

    onDragUpdate();
    return GestureDispatchResult.handled();
  }

  Future<GestureDispatchResult> _handleMultiTouchRotation(
      double rotationAngle, Offset center) async {
    if (!hasSelectedElements) {
      return GestureDispatchResult.unhandled(
          reason: 'No elements selected for rotation');
    }

    EditPageLogger.canvasDebug('多点触控旋转', data: {
      'angle': '${rotationAngle * 180 / pi} degrees',
      'center': '$center'
    });

    // Apply rotation to selected elements
    for (final elementId in controller.state.selectedElementIds) {
      final element = elements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isEmpty) continue;

      final currentRotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
      final newRotation = currentRotation + rotationAngle;

      controller.updateElementProperties(elementId, {
        'rotation': newRotation,
      });
    }

    onDragUpdate();
    return GestureDispatchResult.handled();
  }

  Future<GestureDispatchResult> _handleMultiTouchScale(
      double scaleRatio, Offset center) async {
    if (!hasSelectedElements) {
      return GestureDispatchResult.unhandled(
          reason: 'No elements selected for scaling');
    }

    EditPageLogger.canvasDebug('多点触控缩放',
        data: {'scaleRatio': scaleRatio, 'center': '$center'});

    // Apply scale to selected elements
    for (final elementId in controller.state.selectedElementIds) {
      final element = elements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isEmpty) continue;

      final elementCenter = Offset(
        (element['x'] as num).toDouble() +
            (element['width'] as num).toDouble() / 2,
        (element['y'] as num).toDouble() +
            (element['height'] as num).toDouble() / 2,
      );

      // Calculate new size
      final newWidth = (element['width'] as num).toDouble() * scaleRatio;
      final newHeight = (element['height'] as num).toDouble() * scaleRatio;

      // Calculate new position to maintain center
      final newX = elementCenter.dx - newWidth / 2;
      final newY = elementCenter.dy - newHeight / 2;

      controller.updateElementProperties(elementId, {
        'width': newWidth,
        'height': newHeight,
        'x': newX,
        'y': newY,
      });
    }

    onDragUpdate();
    return GestureDispatchResult.handled();
  }

  void _handlePreviewModePan(Offset currentPosition, double inverseScale) {
    final rawDx = currentPosition.dx - _dragStart.dx;
    final rawDy = currentPosition.dy - _dragStart.dy;
    final dx = rawDx * inverseScale;
    final dy = rawDy * inverseScale;

    _elementStartPosition = Offset(dx, dy);
    onDragUpdate();
  }

  void _setupCanvasPanning(List<Map<String, dynamic>> elements) {
    // 🔧 修复：不拦截手势，让InteractiveViewer完全接管画布平移和缩放
    EditPageLogger.canvasDebug('画布平移设置',
        data: {'注意': '不拦截手势，让InteractiveViewer处理'});
    _currentMode = _GestureMode.idle; // 设置为idle，表示不处理任何手势
    // 重要：不设置任何拖拽状态，让GestureDetector的手势穿透到InteractiveViewer
  }

  void _setupElementDragging(List<Map<String, dynamic>> elements) {
    // 立即设置拖拽状态，防止时序问题
    _isDragging = true;
    _elementStartPositions.clear();

    // 🔧 修复多选L形指示器：收集元素的完整初始属性
    final Map<String, Map<String, dynamic>> elementStartProperties = {};

    for (final selectedId in controller.state.selectedElementIds) {
      final selectedElement =
          ElementUtils.findElementById(elements, selectedId);
      if (selectedElement != null) {
        _elementStartPositions[selectedId] = Offset(
          (selectedElement['x'] as num).toDouble(),
          (selectedElement['y'] as num).toDouble(),
        );

        // 保存完整的元素属性
        elementStartProperties[selectedId] =
            Map<String, dynamic>.from(selectedElement);
      }
    }

    EditPageLogger.canvasDebug('准备启动拖拽状态管理器', data: {
      'elementIds': controller.state.selectedElementIds.toSet(),
      'startPosition': '$_dragStart',
      'elementCount': elementStartProperties.length
    });

    dragStateManager.startDrag(
      elementIds: controller.state.selectedElementIds.toSet(),
      startPosition: _dragStart,
      elementStartPositions: _elementStartPositions,
      elementStartProperties: elementStartProperties, // 传递完整属性
    );

    EditPageLogger.canvasDebug('拖拽状态管理器启动完成', data: {
      'isDragging': dragStateManager.isDragging,
      'selectedElements': controller.state.selectedElementIds.length,
      'propertiesCount': elementStartProperties.length
    });
    onDragStart(
        true, _dragStart, _elementStartPosition, _elementStartPositions);
    _currentMode = _GestureMode.elementDrag;
  }

  void _startSelectionBox(Offset position) {
    _isSelectionBoxActive = true;
    _selectionBoxStart = position;
    _selectionBoxEnd = position;
    _currentMode = _GestureMode.selectionBox;
    onDragUpdate();
  }

  void _updatePerformanceMetrics() {
    final responseTime = _responseStopwatch.elapsed;
    _responseTimes.add(responseTime);

    if (_responseTimes.length > 100) {
      _responseTimes.removeAt(0);
    }

    if (responseTime.inMilliseconds > 20) {
      EditPageLogger.editPageWarning('手势响应时间超过目标阈值', data: {
        'responseTime': '${responseTime.inMilliseconds}ms',
        'target': '20ms'
      });
    }

    _responseStopwatch.reset();
  }

  // Helper methods

  void _updatePointerTracking(PointerEvent event) {
    switch (event.runtimeType) {
      case PointerDownEvent:
        _activePointers[event.pointer] = _PointerTracker(
          pointerId: event.pointer,
          startPosition: event.localPosition,
          currentPosition: event.localPosition,
          startTime: event.timeStamp,
        );
        break;

      case PointerMoveEvent:
        final tracker = _activePointers[event.pointer];
        if (tracker != null) {
          tracker.updatePosition(event.localPosition, event.timeStamp);
        }
        break;

      case PointerUpEvent:
      case PointerCancelEvent:
        _activePointers.remove(event.pointer);
        if (_activePointers.isEmpty) {
          _isMultiTouchActive = false;
          _multiTouchState = null;
        }
        break;
    }
  }
}

class _GestureEventRecord {
  final _GestureMode mode;
  final Duration timeStamp;
  final Map<String, dynamic> metadata;
  _GestureEventRecord({
    required this.mode,
    required this.timeStamp,
    required this.metadata,
  });
}

enum _GestureMode {
  idle,
  pan,
  elementDrag,
  selectionBox,
  multiTouch,
}

class _MultiTouchState {
  final double initialDistance;
  final double initialAngle;
  final Offset initialCenter;

  _MultiTouchState({
    required this.initialDistance,
    required this.initialAngle,
    required this.initialCenter,
  });
}

// Supporting classes

class _PointerTracker {
  final int pointerId;
  final Offset startPosition;
  final Duration startTime;

  Offset currentPosition;
  Duration? lastUpdateTime;
  double velocity = 0.0;

  _PointerTracker({
    required this.pointerId,
    required this.startPosition,
    required this.currentPosition,
    required this.startTime,
  });

  void updatePosition(Offset newPosition, Duration timeStamp) {
    if (lastUpdateTime != null) {
      final timeDelta =
          timeStamp.inMicroseconds - lastUpdateTime!.inMicroseconds;
      if (timeDelta > 0) {
        final distance = (newPosition - currentPosition).distance;
        velocity = (distance * 1000000) / timeDelta;
      }
    }

    currentPosition = newPosition;
    lastUpdateTime = timeStamp;
  }
}
