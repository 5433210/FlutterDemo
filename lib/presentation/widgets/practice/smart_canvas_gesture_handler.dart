import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../pages/practices/helpers/element_utils.dart';
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
  Offset? _selectionBoxStart;
  Offset? _selectionBoxEnd;
  List<String> _panStartSelectedElementIds = [];
  bool _isPanningEmptyArea = false;
  Offset? _panEndPosition;

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
    _responseStopwatch.start();

    try {
      // Create synthetic pointer event for dispatcher
      final pointerEvent = _createSyntheticPointerEvent(
        PointerDownEvent,
        details.localPosition,
      );

      final result = await _gestureDispatcher.dispatchPointerEvent(
        event: pointerEvent,
        context: this,
      );

      if (!result.handled) {
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
    _responseStopwatch.start();

    try {
      // Handle selection box updates first (highest priority)
      if (_isSelectionBoxActive) {
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
    if (isBatched) {
      dragStateManager.updateDragOffset(delta);
    } else {
      // Direct update for immediate response
      dragStateManager.updateDragOffset(delta);
    }
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
    dragStateManager.endDrag();

    final List<String> elementIds = [];
    final List<Map<String, dynamic>> oldPositions = [];
    final List<Map<String, dynamic>> newPositions = [];

    for (final elementId in controller.state.selectedElementIds) {
      final element = controller.state.currentPageElements.firstWhere(
        (e) => e['id'] == elementId,
        orElse: () => <String, dynamic>{},
      );

      if (element.isEmpty) continue;

      final startPosition = _elementStartPositions[elementId];
      if (startPosition == null) continue;

      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();

      if (startPosition.dx != x || startPosition.dy != y) {
        elementIds.add(elementId);
        oldPositions.add({'x': startPosition.dx, 'y': startPosition.dy});
        newPositions.add({'x': x, 'y': y});
      }
    }

    if (elementIds.isNotEmpty) {
      controller.createElementTranslationOperation(
        elementIds: elementIds,
        oldPositions: oldPositions,
        newPositions: newPositions,
      );
    }

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
    final rawDx = currentPosition.dx - _dragStart.dx;
    final rawDy = currentPosition.dy - _dragStart.dy;
    final dx = rawDx * inverseScale;
    final dy = rawDy * inverseScale;

    _elementStartPosition = Offset(dx, dy);
    _panEndPosition = currentPosition;
    onDragUpdate();
  }

  void _handleElementDragUpdate(Offset currentPosition) {
    final dx = currentPosition.dx - _dragStart.dx;
    final dy = currentPosition.dy - _dragStart.dy;

    dragStateManager.updateDragOffset(Offset(dx, dy));
    onDragUpdate();
  }

  void _handleElementSelection(
      String id, Map<String, dynamic> element, bool isMultiSelect) {
    final isCurrentlySelected =
        controller.state.selectedElementIds.contains(id);
    final isLocked = element['locked'] == true;

    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    if (layerId != null) {
      final layer = controller.state.getLayerById(layerId);
      if (layer != null) {
        isLayerLocked = layer['isLocked'] == true;
      }
    }

    if (isLocked || isLayerLocked) {
      controller.state.selectedLayerId = null;
      controller.selectElement(id, isMultiSelect: isMultiSelect);
    } else {
      controller.state.selectedLayerId = null;

      if (isCurrentlySelected && !isMultiSelect) {
        controller.clearSelection();
      } else {
        controller.selectElement(id, isMultiSelect: isMultiSelect);
      }
    }
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
    } else {
      _finalizeCanvasPan();
    }
  }

  Future<void> _handleLegacyPanStart(
      DragStartDetails details, List<Map<String, dynamic>> elements) async {
    debugPrint(
        'handlePanStart - currentTool: ${controller.state.currentTool}, isPreviewMode: ${controller.state.isPreviewMode}');

    _dragStart = details.localPosition;
    _currentMode = _GestureMode.pan;

    // Check if we're in select mode
    if (controller.state.currentTool == 'select' &&
        !controller.state.isPreviewMode) {
      bool hitSelectedElement = false;

      // Check for hits on selected elements
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
          hitSelectedElement = true;

          // Check if element is locked
          final isLocked = element['locked'] == true;
          bool isLayerLocked = false;
          if (layerId != null) {
            final layer = controller.state.getLayerById(layerId);
            if (layer != null) {
              isLayerLocked = layer['isLocked'] == true;
            }
          }

          if (!isLocked && !isLayerLocked) {
            _setupElementDragging(elements);
            return;
          }
          break;
        }
      }

      // If didn't hit selected element, start selection box
      if (!hitSelectedElement) {
        _startSelectionBox(details.localPosition);
        return;
      }
    }

    _setupCanvasPanning(elements);
  }

  Future<void> _handleLegacyPanUpdate(DragUpdateDetails details) async {
    final currentPosition = details.localPosition;
    final scaleFactor = getScaleFactor();
    final inverseScale = scaleFactor > 0 ? 1.0 / scaleFactor : 1.0;

    if (controller.state.isPreviewMode) {
      _handlePreviewModePan(currentPosition, inverseScale);
      return;
    }

    if (dragStateManager.isDragging) {
      _handleElementDragUpdate(currentPosition);
    } else {
      _handleCanvasPanUpdate(currentPosition, inverseScale);
    }
  }

  Future<void> _handleLegacyTapUp(
      TapUpDetails details, List<Map<String, dynamic>> elements) async {
    bool hitElement = false;
    final isMultiSelect = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isShiftPressed;

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
        _handleElementSelection(id, element, isMultiSelect);
        break;
      }
    }

    if (!hitElement && !isMultiSelect) {
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
    _elementStartPosition = Offset.zero;
    _panStartSelectedElementIds =
        List.from(controller.state.selectedElementIds);
    _currentMode = _GestureMode.canvasPan;
    onDragStart(false, _dragStart, _elementStartPosition, {});
  }

  void _setupElementDragging(List<Map<String, dynamic>> elements) {
    _elementStartPositions.clear();

    for (final selectedId in controller.state.selectedElementIds) {
      final selectedElement =
          ElementUtils.findElementById(elements, selectedId);
      if (selectedElement != null) {
        _elementStartPositions[selectedId] = Offset(
          (selectedElement['x'] as num).toDouble(),
          (selectedElement['y'] as num).toDouble(),
        );
      }
    }

    dragStateManager.startDrag(
      elementIds: controller.state.selectedElementIds.toSet(),
      startPosition: _dragStart,
      elementStartPositions: _elementStartPositions,
    );

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
