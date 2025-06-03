// filepath: lib/canvas/core/events/canvas_gesture_event.dart

import 'dart:ui';

/// Canvas gesture event data
class CanvasGestureEvent {
  final CanvasGestureType type;
  final Offset position;
  final Offset? delta;
  final double? scale;
  final double? rotation;
  final int? pointer;
  final Duration? timestamp;

  const CanvasGestureEvent({
    required this.type,
    required this.position,
    this.delta,
    this.scale,
    this.rotation,
    this.pointer,
    this.timestamp,
  });

  /// Create a double tap event
  factory CanvasGestureEvent.doubleTap(Offset position) {
    return CanvasGestureEvent(
      type: CanvasGestureType.doubleTap,
      position: position,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a long press event
  factory CanvasGestureEvent.longPress(Offset position) {
    return CanvasGestureEvent(
      type: CanvasGestureType.longPress,
      position: position,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a pan end event
  factory CanvasGestureEvent.panEnd(Offset position) {
    return CanvasGestureEvent(
      type: CanvasGestureType.panEnd,
      position: position,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a pan start event
  factory CanvasGestureEvent.panStart(Offset position) {
    return CanvasGestureEvent(
      type: CanvasGestureType.panStart,
      position: position,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a pan update event
  factory CanvasGestureEvent.panUpdate(Offset position, Offset delta) {
    return CanvasGestureEvent(
      type: CanvasGestureType.panUpdate,
      position: position,
      delta: delta,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a scale end event
  factory CanvasGestureEvent.scaleEnd(Offset position) {
    return CanvasGestureEvent(
      type: CanvasGestureType.scaleEnd,
      position: position,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a scale start event
  factory CanvasGestureEvent.scaleStart(Offset position) {
    return CanvasGestureEvent(
      type: CanvasGestureType.scaleStart,
      position: position,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a scale update event
  factory CanvasGestureEvent.scaleUpdate(
      Offset position, double scale, double rotation) {
    return CanvasGestureEvent(
      type: CanvasGestureType.scaleUpdate,
      position: position,
      scale: scale,
      rotation: rotation,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a tap event
  factory CanvasGestureEvent.tap(Offset position) {
    return CanvasGestureEvent(
      type: CanvasGestureType.tap,
      position: position,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a tap down event
  factory CanvasGestureEvent.tapDown(Offset position, {int? pointer}) {
    return CanvasGestureEvent(
      type: CanvasGestureType.tapDown,
      position: position,
      pointer: pointer,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  /// Create a tap up event
  factory CanvasGestureEvent.tapUp(Offset position, {int? pointer}) {
    return CanvasGestureEvent(
      type: CanvasGestureType.tapUp,
      position: position,
      pointer: pointer,
      timestamp: Duration(milliseconds: DateTime.now().millisecondsSinceEpoch),
    );
  }

  @override
  String toString() {
    return 'CanvasGestureEvent(type: $type, position: $position, delta: $delta, scale: $scale, rotation: $rotation)';
  }
}

/// Canvas gesture event types
enum CanvasGestureType {
  tapDown,
  tapUp,
  tap,
  panStart,
  panUpdate,
  panEnd,
  scaleStart,
  scaleUpdate,
  scaleEnd,
  longPress,
  doubleTap,
}

/// Resize handle types
enum ResizeHandle {
  topLeft,
  topCenter,
  topRight,
  leftCenter,
  rightCenter,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Resize handle data for hit testing
class ResizeHandleData {
  final ResizeHandle handle;
  final Rect bounds;

  const ResizeHandleData({
    required this.handle,
    required this.bounds,
  });
}
