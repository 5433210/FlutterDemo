import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pages/practices/helpers/element_utils.dart';
import 'batch_update_options.dart';
import 'drag_state_manager.dart';
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
  List<String> _panStartSelectedElementIds = [];
  Offset? _panEndPosition;
  bool _isDragging = false;

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
    // Implementation depends on controller capability
    if (!isMultiSelectMode) {
      controller.clearSelection();
    }
    onDragUpdate();
    return GestureDispatchResult.handled();
  }

  /// Cleanup resources
  void dispose() {
    _gestureDispatcher.dispose();
    _conflictResolutionTimer?.cancel();
    _activePointers.clear();
    _gestureHistory.clear();
    _responseTimes.clear();
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
    debugPrint('Pan operation cancelled');
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
    debugPrint('[DRAG_DEBUG] ===== handlePanStart被调用 =====');
    debugPrint('[DRAG_DEBUG] 点击位置: ${details.localPosition}');
    debugPrint('[DRAG_DEBUG] 当前选中元素: ${controller.state.selectedElementIds}');
    debugPrint('[DRAG_DEBUG] 当前工具: ${controller.state.currentTool}');
    debugPrint('[DRAG_DEBUG] 元素总数: ${elements.length}');
    
    _responseStopwatch.start();

    try {
      // 对于潜在的拖拽操作，直接使用legacy处理避免gesture dispatcher误判
      // 检查是否可能是元素拖拽
      bool isPotentialElementDrag = false;
      if (controller.state.selectedElementIds.isNotEmpty) {
        debugPrint('[DRAG_DEBUG] 检查潜在拖拽：有${controller.state.selectedElementIds.length}个选中元素');
      } else {
        debugPrint('[DRAG_DEBUG] 检查潜在拖拽：没有选中元素');
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
        debugPrint('[DRAG_DEBUG] 检测到潜在拖拽或选择框，使用legacy处理');
        debugPrint('[DRAG_DEBUG] isPotentialElementDrag=$isPotentialElementDrag, currentTool=${controller.state.currentTool}');
        await _handleLegacyPanStart(details, elements);
        return;
      }

      // 其他情况使用新的gesture dispatcher
      debugPrint('[DRAG_DEBUG] 使用SmartGestureDispatcher处理');
      final pointerEvent = _createSyntheticPointerEvent(
        PointerDownEvent,
        details.localPosition,
      );

      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: pointerEvent,
        context: this,
      );

      if (!result.handled) {
        debugPrint('[DRAG_DEBUG] SmartGestureDispatcher未处理，回退到legacy处理');
        // Fallback to legacy handling
        await _handleLegacyPanStart(details, elements);
      } else {
        debugPrint('[DRAG_DEBUG] SmartGestureDispatcher已处理');
      }
    } finally {
      _responseStopwatch.stop();
      _updatePerformanceMetrics();
    }
  }

  /// Enhanced pan update with smart gesture recognition
  Future<void> handlePanUpdate(DragUpdateDetails details) async {
    debugPrint('[DRAG_DEBUG] ===== handlePanUpdate被调用 =====');
    debugPrint('[DRAG_DEBUG] 位置: ${details.localPosition}, isDragging=${dragStateManager.isDragging}');
    
    _responseStopwatch.start();

    try {
      
      // Handle selection box updates first (highest priority)
      if (_isSelectionBoxActive) {
        debugPrint('[DRAG_DEBUG] 选择框活跃，更新选择框');
        _selectionBoxEnd = details.localPosition;
        onDragUpdate();
        return;
      }

      // Create synthetic pointer event for dispatcher
      final pointerEvent = _createSyntheticPointerEvent(
        PointerMoveEvent,
        details.localPosition,
      );

      debugPrint('[DRAG_DEBUG] 尝试SmartGestureDispatcher处理');
      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: pointerEvent,
        context: this,
      );

      if (!result.handled) {
        debugPrint('[DRAG_DEBUG] SmartGestureDispatcher未处理，回退到Legacy路径');
        // Fallback to legacy handling
        await _handleLegacyPanUpdate(details);
      } else {
        debugPrint('[DRAG_DEBUG] SmartGestureDispatcher已处理手势');
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
    if (controller.state.currentTool == 'select') {
      controller.exitSelectMode();
      if (_isSelectionBoxActive) {
        cancelSelectionBox();
      }
      onDragUpdate();
    }
  }

  void handleSecondaryTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) {
    // Implementation for right-click handling
    if (controller.state.currentTool == 'select') {
      controller.state.currentTool = '';
      onDragUpdate();
      return;
    }
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
    debugPrint('Show context menu at $position');
    return GestureDispatchResult.handled();
  }

  @override
  Future<GestureDispatchResult> updateElementDrag({
    required String elementId,
    required Offset delta,
    bool isBatched = false,
  }) async {
    // 🔍[RESIZE_FIX] 元素拖拽 Live阶段：通过SmartGestureDispatcher路径
    debugPrint('🔍[RESIZE_FIX] SmartGestureDispatcher -> updateElementDrag: elementId=$elementId, delta=$delta, isBatched=$isBatched');
    
    if (isBatched) {
      dragStateManager.updateDragOffset(delta);
      // 🔍[RESIZE_FIX] 性能监控：只更新统计，不触发通知
      dragStateManager.updatePerformanceStatsOnly();
    } else {
      // Direct update for immediate response
      dragStateManager.updateDragOffset(delta);
      // 🔍[RESIZE_FIX] 性能监控：只更新统计，不触发通知
      dragStateManager.updatePerformanceStatsOnly();
    }
    
    debugPrint('🔍[RESIZE_FIX] SmartGestureDispatcher路径：跳过Controller更新，保持流畅');
    onDragUpdate();
    return GestureDispatchResult.handled();
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
    final isClick = dragDistance < 3.0;

    if (_isPanningEmptyArea &&
        isClick &&
        !controller.state.isCtrlOrShiftPressed) {
      controller.clearSelection();
    }

    _isPanningEmptyArea = false;
    _panStartSelectedElementIds = [];
    _panEndPosition = null;
    onDragEnd();
  }

  void _finalizeElementDrag() {
    debugPrint('🔍[RESIZE_FIX] Commit阶段: 结束元素拖拽');
    _isDragging = false;

    // 🔍[RESIZE_FIX] Commit阶段：计算最终位置并一次性更新Controller
    final List<String> elementIds = [];
    final List<Map<String, dynamic>> oldPositions = [];
    final List<Map<String, dynamic>> newPositions = [];
    final Map<String, Map<String, dynamic>> finalUpdates = {};

    // 从DragStateManager获取最终拖拽偏移
    final finalOffset = dragStateManager.currentDragOffset;
    debugPrint('🔍[RESIZE_FIX] 最终拖拽偏移: $finalOffset');

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
      debugPrint('🔍[RESIZE_FIX] 批量更新 ${finalUpdates.length} 个元素的最终位置');
      controller.batchUpdateElementProperties(
        finalUpdates,
        options: BatchUpdateOptions.forDragOperation(),
      );
      
      // 创建撤销操作
      controller.createElementTranslationOperation(
        elementIds: elementIds,
        oldPositions: oldPositions,
        newPositions: newPositions,
      );
      
      debugPrint('🔍[RESIZE_FIX] Commit阶段: 元素位置更新完成');
    }

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

  void _handleCanvasPanUpdate(Offset currentPosition, double inverseScale) {
    // 画布平移由InteractiveViewer处理，这里不做任何操作
    debugPrint('【SmartCanvasGestureHandler】画布平移更新被忽略，由InteractiveViewer处理');
    _panEndPosition = currentPosition;
    // 不调用onDragUpdate，让InteractiveViewer处理
  }

  void _handleElementDragUpdate(Offset currentPosition) {
    try {
      debugPrint('[DRAG_DEBUG] _handleElementDragUpdate被调用，当前位置: $currentPosition');
      
      final dx = currentPosition.dx - _dragStart.dx;
      final dy = currentPosition.dy - _dragStart.dy;

      // 获取缩放因子并调整拖拽偏移
      final scaleFactor = getScaleFactor();
      final adjustedDx = dx; // 直接使用原始偏移
      final adjustedDy = dy; // 直接使用原始偏移

      debugPrint('[DRAG_DEBUG] 拖拽偏移计算: dx=$dx, dy=$dy, 缩放因子=$scaleFactor');
      
      // 更新拖拽状态
      dragStateManager.updateDragOffset(Offset(adjustedDx, adjustedDy));
      _isDragging = true;

      debugPrint('[DRAG_DEBUG] updateDragOffset调用完成，准备触发onDragUpdate');

      onDragUpdate();
      debugPrint('[DRAG_DEBUG] _handleElementDragUpdate完成');
      
    } catch (e, stackTrace) {
      debugPrint('[DRAG_DEBUG] ❌ _handleElementDragUpdate异常: $e');
      debugPrint('[DRAG_DEBUG] ❌ 堆栈跟踪: $stackTrace');
    }
  }

  void _handleElementSelection(
      String id, Map<String, dynamic> element, bool isMultiSelect) {
    final isCurrentlySelected =
        controller.state.selectedElementIds.contains(id);
    final isLocked = element['locked'] == true;

    debugPrint('【SmartGestureHandler】处理元素选择: $id, 当前已选中: $isCurrentlySelected, 多选: $isMultiSelect');

    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    if (layerId != null) {
      final layer = controller.state.getLayerById(layerId);
      if (layer != null) {
        isLayerLocked = layer['isLocked'] == true;
      }
    }

    if (isLocked || isLayerLocked) {
      debugPrint('【SmartGestureHandler】元素被锁定，选择元素: $id');
      controller.state.selectedLayerId = null;
      controller.selectElement(id, isMultiSelect: isMultiSelect);
    } else {
      controller.state.selectedLayerId = null;

      if (isCurrentlySelected && isMultiSelect) {
        // 在多选模式下，点击已选中元素会从选择中移除
        debugPrint('【SmartGestureHandler】多选模式，取消选择元素: $id');
        controller.selectElement(id, isMultiSelect: true);
      } else if (isCurrentlySelected && !isMultiSelect) {
        // 在单选模式下，点击已选中元素会取消选择（反选）
        debugPrint('【SmartGestureHandler】单选模式，反选元素: $id');
        controller.clearSelection();
      } else {
        // 选择新元素
        debugPrint('【SmartGestureHandler】选择新元素: $id');
        controller.selectElement(id, isMultiSelect: isMultiSelect);
      }
    }
    
    debugPrint('【SmartGestureHandler】选择处理完成，当前选中: ${controller.state.selectedElementIds}');
  }

  Future<GestureDispatchResult> _handleFastCanvasPan(
      double velocity, double direction) async {
    debugPrint('Fast canvas pan: velocity=$velocity, direction=$direction');

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
    debugPrint('Using legacy gesture handling for ${event.runtimeType}');
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
      debugPrint('【SmartCanvasGestureHandler】idle模式结束，无需处理');
    } else {
      _finalizeCanvasPan();
    }
  }

  Future<void> _handleLegacyPanStart(
      DragStartDetails details, List<Map<String, dynamic>> elements) async {
    debugPrint('[DRAG_DEBUG] ===== _handleLegacyPanStart被调用 =====');
    debugPrint('[DRAG_DEBUG] currentTool: ${controller.state.currentTool}, isPreviewMode: ${controller.state.isPreviewMode}');

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
            debugPrint('[DRAG_DEBUG] 检测到点击已选中元素: $id');
            debugPrint('[DRAG_DEBUG] 当前选中的所有元素: ${controller.state.selectedElementIds}');
            
            // Check if element is locked
            final isLocked = element['locked'] == true;
            bool isLayerLocked = false;
            if (layerId != null) {
              final layer = controller.state.getLayerById(layerId);
              if (layer != null) {
                isLayerLocked = layer['isLocked'] == true;
              }
            }

            debugPrint('[DRAG_DEBUG] 元素锁定状态: isLocked=$isLocked, isLayerLocked=$isLayerLocked');

            if (!isLocked && !isLayerLocked) {
              debugPrint('[DRAG_DEBUG] 开始拖拽已选中元素: $id (工具: ${controller.state.currentTool})');
              debugPrint('[DRAG_DEBUG] 准备调用_setupElementDragging...');
              _setupElementDragging(elements);
              debugPrint('[DRAG_DEBUG] _setupElementDragging调用完成');
              return;
            } else {
              debugPrint('[DRAG_DEBUG] 元素被锁定，无法拖拽');
            }
            break;
          }
        }

        // 2. 如果在select模式下，开始选择框（框选模式）
        if (controller.state.currentTool == 'select') {
          debugPrint('【选择框】开始选择框操作（框选模式）');
          _startSelectionBox(details.localPosition);
          return;
        }
      }

      // 3. 其他情况进行画布平移
      debugPrint('【画布平移】开始画布平移');
      _setupCanvasPanning(elements);
    } finally {
      _isPanStartHandling = false; // 清除PanStart处理标记
    }
  }

  Future<void> _handleLegacyPanUpdate(DragUpdateDetails details) async {
    final currentPosition = details.localPosition;
    final scaleFactor = getScaleFactor();
    final inverseScale = scaleFactor > 0 ? 1.0 / scaleFactor : 1.0;

    debugPrint('[DRAG_DEBUG] PanUpdate: currentPosition=$currentPosition, isDragging=${dragStateManager.isDragging}, mode=$_currentMode');

    if (controller.state.isPreviewMode) {
      _handlePreviewModePan(currentPosition, inverseScale);
      return;
    }

    if (dragStateManager.isDragging) {
      debugPrint('[DRAG_DEBUG] 检测到拖拽状态，调用_handleElementDragUpdate');
      _handleElementDragUpdate(currentPosition);
    } else if (_currentMode == _GestureMode.selectionBox) {
      // 处理选择框更新
      _selectionBoxEnd = currentPosition;
      onDragUpdate();
    } else if (_currentMode == _GestureMode.idle) {
      // idle模式：完全不处理，让InteractiveViewer处理画布平移
      debugPrint('【SmartCanvasGestureHandler】idle模式，不拦截手势');
      return;
    } else {
      // 其他模式的画布平移由InteractiveViewer处理
      debugPrint('【SmartCanvasGestureHandler】画布平移由InteractiveViewer处理');
    }
  }

  Future<void> _handleLegacyTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) async {
    
    // 如果正在处理PanStart事件，跳过TapUp处理，避免时序冲突
    if (_isPanStartHandling) {
      debugPrint('【SmartGestureHandler】正在处理PanStart，跳过TapUp处理');
      return;
    }

    // 如果当前模式不是idle，说明已经进入了特殊手势处理模式，跳过TapUp
    if (_currentMode != _GestureMode.idle) {
      debugPrint('【SmartGestureHandler】当前模式: $_currentMode，跳过TapUp处理');
      return;
    }

    // 如果正在拖拽，不处理tapUp事件，避免干扰拖拽操作
    if (_isDragging || dragStateManager.isDragging) {
      debugPrint('【SmartGestureHandler】正在拖拽，跳过TapUp处理');
      return;
    }

    bool hitElement = false;
    final isMultiSelect = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed;

    debugPrint('【SmartGestureHandler】TapUp - 开始处理点击事件，当前选中: ${controller.state.selectedElementIds}');

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
        debugPrint('【SmartGestureHandler】TapUp - 点击到元素: $id');
        _handleElementSelection(id, element, isMultiSelect);
        break;
      }
    }

    if (!hitElement && !isMultiSelect) {
      debugPrint('【SmartGestureHandler】TapUp - 点击空白区域，清除选择');
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
    debugPrint('Multi-touch pan: delta=$delta');

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

    debugPrint(
        'Multi-touch rotation: angle=${rotationAngle * 180 / pi} degrees, center=$center');

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

    debugPrint('Multi-touch scale: ratio=$scaleRatio, center=$center');

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
    // 画布平移应该由InteractiveViewer处理，这里完全不处理
    debugPrint('【SmartCanvasGestureHandler】不拦截手势，让InteractiveViewer处理画布平移');
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
        elementStartProperties[selectedId] = Map<String, dynamic>.from(selectedElement);
      }
    }

    debugPrint('[DRAG_DEBUG] 准备调用dragStateManager.startDrag...');
    debugPrint('[DRAG_DEBUG] 拖拽参数: elementIds=${controller.state.selectedElementIds.toSet()}, startPosition=$_dragStart');
    
    dragStateManager.startDrag(
      elementIds: controller.state.selectedElementIds.toSet(),
      startPosition: _dragStart,
      elementStartPositions: _elementStartPositions,
      elementStartProperties: elementStartProperties, // 🔧 传递完整属性
    );

    debugPrint('[DRAG_DEBUG] dragStateManager.startDrag调用完成');
    debugPrint('[DRAG_DEBUG] dragStateManager.isDragging = ${dragStateManager.isDragging}');
    debugPrint('【SmartCanvasGestureHandler】开始元素拖拽，选中元素: ${controller.state.selectedElementIds}');
    debugPrint('🔧 已传递 ${elementStartProperties.length} 个元素的初始属性到DragStateManager');
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
      debugPrint(
          'Warning: Gesture response time ${responseTime.inMilliseconds}ms exceeds 20ms target');
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
    this.metadata = const {},
  });
}

enum _GestureMode {
  idle,
  pan,
  elementDrag,
  selectionBox,
  canvasPan,
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
