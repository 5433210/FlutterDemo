import 'package:flutter/material.dart';

import '../interaction/canvas_interaction_system.dart';

/// Event handling integration system that unifies new Canvas systems
/// with existing drag/resize/rotate operations
abstract class CanvasEventHandler {
  /// Get current interaction mode
  CanvasInteractionMode get currentMode;

  /// Set interaction mode
  set currentMode(CanvasInteractionMode mode);

  /// Get current pan offset
  Offset get panOffset;

  /// Get current zoom level
  double get zoomLevel;

  /// Set zoom level
  set zoomLevel(double zoom);

  /// Handle long press for context menu
  void handleLongPress(LongPressStartDetails details);

  /// Handle pan end events (for compatibility with existing system)
  void handlePanEnd(DragEndDetails details);

  /// Handle pan start events (for compatibility with existing system)
  void handlePanStart(DragStartDetails details);

  /// Handle pan update events (for compatibility with existing system)
  void handlePanUpdate(DragUpdateDetails details);

  /// Handle pointer down events
  void handlePointerDown(PointerDownEvent event);

  /// Handle pointer move events
  void handlePointerMove(PointerMoveEvent event);

  /// Handle pointer up events
  void handlePointerUp(PointerUpEvent event);

  /// Handle scale end (for pinch gesture)
  void handleScaleEnd(ScaleEndDetails details);

  /// Handle scale start (for pinch gesture)
  void handleScaleStart(ScaleStartDetails details);

  /// Handle scale update (for pinch gesture)
  void handleScaleUpdate(ScaleUpdateDetails details);

  /// Handle zoom in action
  void zoomIn({Offset? focalPoint});

  /// Handle zoom out action
  void zoomOut({Offset? focalPoint});

  /// Handle zoom to fit action
  void zoomToFit(Size viewportSize, List<Map<String, dynamic>> elements);
}

/// Types of canvas operations
enum CanvasOperation {
  none,
  elementDrag,
  elementResize,
  elementRotate,
  canvasPan,
  boxSelection,
  elementCreation,
  multiTouch,
}

/// Hit test result
class HitTestResult {
  final HitTestType type;
  final String? elementId;
  final String? handleType;
  final Offset position;
  final Map<String, dynamic>? element;

  HitTestResult({
    required this.type,
    this.elementId,
    this.handleType,
    required this.position,
    this.element,
  });
}

/// Types of hit test results
enum HitTestType {
  element,
  controlHandle,
  canvas,
}

/// Pointer information for tracking
class PointerInfo {
  final int id;
  final Offset startPosition;
  Offset currentPosition;
  Offset canvasPosition;

  PointerInfo({
    required this.id,
    required this.startPosition,
    required this.currentPosition,
    required this.canvasPosition,
  });
}

enum SelectionMode {
  single,
  multiple,
  additive,
}

/// Selection outline for rendering

// For implementation details, see canvas_event_handler_impl.dart
/// Selection outline for rendering
class SelectionOutline {
  final Rect bounds;
  final bool isMultiple;
  final Set<String> selectedIds;

  const SelectionOutline({
    required this.bounds,
    required this.isMultiple,
    required this.selectedIds,
  });
}
