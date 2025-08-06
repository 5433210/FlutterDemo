import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';

// Context interface for gesture operations
abstract class GestureContext {
  String get currentTool;
  List<Map<String, dynamic>> get elements;
  bool get hasSelectedElements;
  bool get isMultiSelectMode;

  Future<GestureDispatchResult> clearSelection();
  Future<GestureDispatchResult> deselectElement(String elementId);
  Future<GestureDispatchResult> fastPanCanvas({
    required double velocity,
    required double direction,
  });
  Future<GestureDispatchResult> finalizeElementDrag(String elementId);
  bool isElementSelected(String elementId);
  Future<GestureDispatchResult> rotateElements({
    required double rotationAngle,
    required Offset center,
  });
  Future<GestureDispatchResult> scaleElements({
    required double scaleRatio,
    required Offset center,
  });
  Future<GestureDispatchResult> selectElement(String elementId);
  Future<GestureDispatchResult> showContextMenu(Offset position);
  Future<GestureDispatchResult> updateElementDrag({
    required String elementId,
    required Offset delta,
    bool isBatched = false,
  });
}

class GestureDispatchResult {
  final bool handled;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  factory GestureDispatchResult.handled({Map<String, dynamic>? metadata}) {
    return GestureDispatchResult._(
      handled: true,
      metadata: metadata ?? {},
    );
  }

  factory GestureDispatchResult.unhandled({String? reason}) {
    return GestureDispatchResult._(
      handled: false,
      errorMessage: reason,
    );
  }

  GestureDispatchResult._({
    required this.handled,
    this.errorMessage,
    this.metadata = const {},
  });
}

/// Enhanced gesture dispatcher with intelligent routing and conflict resolution
class SmartGestureDispatcher {
  // Performance targets
  static const Duration _responseTimeTarget = Duration(milliseconds: 20);
  static const int _maxGestureHistory = 50;
  static const double _velocityThreshold = 500.0; // pixels per second

  // Gesture tracking
  final Map<int, _GestureTracker> _activeGestures = {};
  final List<_GestureEvent> _gestureHistory = [];

  // Performance monitoring
  final Stopwatch _performanceStopwatch = Stopwatch();
  final List<Duration> _responseTimes = [];

  // Conflict resolution
  Timer? _conflictResolutionTimer;
  _GestureConflict? _currentConflict;

  /// Dispatch a pointer event through the intelligent routing system
  Future<GestureDispatchResult> dispatchPointerEvent({
    required PointerEvent event,
    required GestureContext context,
  }) async {
    _performanceStopwatch.start();

    try {
      // Update gesture tracking
      _updateGestureTracking(event);

      // Detect gesture type with confidence scoring
      final gestureType = await _detectGestureType(event, context);

      // Resolve conflicts if multiple gestures detected
      final resolvedGesture =
          await _resolveGestureConflicts(gestureType, context);

      // Route to appropriate handler
      final result = await _routeGesture(resolvedGesture, event, context);

      // Update performance metrics
      _updatePerformanceMetrics();

      return result;
    } finally {
      _performanceStopwatch.stop();
    }
  }

  /// Cleanup resources
  void dispose() {
    _conflictResolutionTimer?.cancel();
    _activeGestures.clear();
    _gestureHistory.clear();
    _responseTimes.clear();
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    if (_responseTimes.isEmpty) {
      return {
        'averageResponseTime': 0,
        'maxResponseTime': 0,
        'gestureCount': 0
      };
    }

    final avgTime =
        _responseTimes.fold(0, (sum, time) => sum + time.inMicroseconds) ~/
            _responseTimes.length;
    final maxTime =
        _responseTimes.map((t) => t.inMicroseconds).reduce(math.max);

    return {
      'averageResponseTime': avgTime / 1000, // Convert to milliseconds
      'maxResponseTime': maxTime / 1000,
      'gestureCount': _gestureHistory.length,
      'activeGestures': _activeGestures.length,
    };
  }

  /// Apply intelligent conflict resolution rules
  Future<_SmartGestureType> _applyConflictResolutionRules(
    _SmartGestureType gesture,
    GestureContext context,
  ) async {
    // Rule 1: Element operations have higher priority than canvas operations
    if (gesture.type == _GestureTypeEnum.elementDrag &&
        context.hasSelectedElements) {
      return gesture.copyWith(
          confidence: math.min(1.0, gesture.confidence + 0.1));
    }

    // Rule 2: Multi-touch has priority over single-touch
    if (gesture.isMultiTouch && _activeGestures.length > 1) {
      return gesture.copyWith(
          confidence: math.min(1.0, gesture.confidence + 0.15));
    }

    // Rule 3: Fast gestures for immediate response
    if (gesture.type == _GestureTypeEnum.fastPan) {
      return gesture.copyWith(
          confidence: math.min(1.0, gesture.confidence + 0.2));
    }

    // Rule 4: Context-based prioritization
    if (context.currentTool == 'select' &&
        gesture.type == _GestureTypeEnum.selectionBox) {
      return gesture.copyWith(
          confidence: math.min(1.0, gesture.confidence + 0.1));
    }

    return gesture;
  }

  double _calculateAverageVelocity(List<_GestureTracker> trackers) {
    if (trackers.isEmpty) return 0.0;

    final totalVelocity =
        trackers.fold(0.0, (sum, tracker) => sum + tracker.velocity);
    return totalVelocity / trackers.length;
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

  double _calculateDirection(Offset start, Offset current) {
    return math.atan2(current.dy - start.dy, current.dx - start.dx);
  }

  double _calculateDistance(Offset a, Offset b) {
    return math.sqrt(math.pow(a.dx - b.dx, 2) + math.pow(a.dy - b.dy, 2));
  }

  Offset _calculatePanDirection(List<_GestureTracker> trackers) {
    if (trackers.isEmpty) return Offset.zero;

    double totalDx = 0, totalDy = 0;
    for (final tracker in trackers) {
      final delta = tracker.currentPosition - tracker.startPosition;
      totalDx += delta.dx;
      totalDy += delta.dy;
    }

    return Offset(totalDx / trackers.length, totalDy / trackers.length);
  }

  double _calculateRotationAngle(
      Offset start1, Offset start2, Offset current1, Offset current2) {
    final startAngle = math.atan2(start2.dy - start1.dy, start2.dx - start1.dx);
    final currentAngle =
        math.atan2(current2.dy - current1.dy, current2.dx - current1.dx);
    return currentAngle - startAngle;
  }

  double _calculateRotationConfidence(double rotationAngle) {
    // Higher confidence for larger rotation angles
    return math.min(1.0, rotationAngle.abs() * 2.0);
  }

  double _calculateScaleConfidence(double scaleRatio) {
    // Higher confidence for more obvious scale changes
    final scaleChange = (scaleRatio - 1.0).abs();
    return math.min(1.0, scaleChange * 2.0);
  }

  /// Detect gesture type with confidence scoring
  Future<_SmartGestureType> _detectGestureType(
      PointerEvent event, GestureContext context) async {
    final tracker = _activeGestures[event.pointer];
    if (tracker == null) return _SmartGestureType.unknown();

    // Multi-touch detection
    if (_activeGestures.length > 1) {
      return await _detectMultiTouchGesture(context);
    }

    // Single touch gesture detection
    return await _detectSingleTouchGesture(tracker, context);
  }

  /// Detect multi-touch gestures (scale, rotate, multi-select)
  Future<_SmartGestureType> _detectMultiTouchGesture(
      GestureContext context) async {
    if (_activeGestures.length < 2) {
      return _SmartGestureType.unknown();
    }

    final gestures = _activeGestures.values.toList();
    final firstTracker = gestures[0];
    final secondTracker = gestures[1];

    // Calculate distance between touch points
    final currentDistance = _calculateDistance(
      firstTracker.currentPosition,
      secondTracker.currentPosition,
    );

    final initialDistance = _calculateDistance(
      firstTracker.startPosition,
      secondTracker.startPosition,
    );

    // Scale detection
    if ((currentDistance - initialDistance).abs() > 20.0) {
      final scaleRatio = currentDistance / initialDistance;
      return _SmartGestureType.multiScale(
        confidence: _calculateScaleConfidence(scaleRatio),
        scaleRatio: scaleRatio,
        center: _calculateCenter(
            [firstTracker.currentPosition, secondTracker.currentPosition]),
      );
    }

    // Rotation detection
    final rotationAngle = _calculateRotationAngle(
      firstTracker.startPosition,
      secondTracker.startPosition,
      firstTracker.currentPosition,
      secondTracker.currentPosition,
    );

    if (rotationAngle.abs() > 0.1) {
      // ~5.7 degrees
      return _SmartGestureType.multiRotate(
        confidence: _calculateRotationConfidence(rotationAngle),
        rotationAngle: rotationAngle,
        center: _calculateCenter(
            [firstTracker.currentPosition, secondTracker.currentPosition]),
      );
    }

    // Multi-point pan
    final avgVelocity = _calculateAverageVelocity(gestures);
    if (avgVelocity > 50.0) {
      return _SmartGestureType.multiPan(
        confidence: 0.8,
        velocity: avgVelocity,
        direction: _calculatePanDirection(gestures),
      );
    }

    return _SmartGestureType.unknown();
  }

  /// Detect single touch gestures with enhanced accuracy
  Future<_SmartGestureType> _detectSingleTouchGesture(
    _GestureTracker tracker,
    GestureContext context,
  ) async {
    final velocity = tracker.velocity;
    final distance =
        _calculateDistance(tracker.startPosition, tracker.currentPosition);

    // Static tap detection - 🔧 降低距离阈值以改善拖拽检测
    if (distance < 1.0 && velocity < 50.0) {
      final tapType = await _determineTapType(tracker, context);
      final hitTarget = await _performHitTest(tracker.currentPosition, context);

      return _SmartGestureType.tap(
        confidence: 0.95,
        position: tracker.currentPosition,
        tapType: tapType,
        elementId: hitTarget.elementId,
      );
    }

    // Fast gesture detection for immediate response
    if (velocity > _velocityThreshold) {
      return _SmartGestureType.fastPan(
        confidence: 0.9,
        velocity: velocity,
        direction:
            _calculateDirection(tracker.startPosition, tracker.currentPosition),
      );
    }

    // Drag detection with element hit testing - 🔧 降低距离阈值
    if (distance > 1.0) {
      final hitTarget = await _performHitTest(tracker.currentPosition, context);

      if (hitTarget.isElement && hitTarget.elementId != null) {
        return _SmartGestureType.elementDrag(
          confidence: 0.85,
          elementId: hitTarget.elementId!,
          startPosition: tracker.startPosition,
          currentPosition: tracker.currentPosition,
        );
      } else if (hitTarget.isSelectionBox) {
        return _SmartGestureType.selectionBox(
          confidence: 0.8,
          startPosition: tracker.startPosition,
          currentPosition: tracker.currentPosition,
        );
      } else {
        return _SmartGestureType.canvasPan(
          confidence: 0.7,
          startPosition: tracker.startPosition,
          currentPosition: tracker.currentPosition,
        );
      }
    }

    return _SmartGestureType.unknown();
  }

  Future<_TapType> _determineTapType(
      _GestureTracker tracker, GestureContext context) async {
    final hitTarget = await _performHitTest(tracker.currentPosition, context);

    if (hitTarget.isElement && hitTarget.elementId != null) {
      final isSelected = context.isElementSelected(hitTarget.elementId!);
      final isMultiSelect = context.isMultiSelectMode;

      if (isSelected && !isMultiSelect) {
        return _TapType.elementDeselect;
      } else {
        return _TapType.elementSelect;
      }
    } else {
      if (context.hasSelectedElements && !context.isMultiSelectMode) {
        return _TapType.clearSelection;
      }
    }

    return _TapType.normal;
  }

  Future<GestureDispatchResult> _handleCanvasPanGesture(
      _SmartGestureType gesture,
      PointerEvent event,
      GestureContext context) async {
    // Implementation for canvas panning
    return GestureDispatchResult.handled();
  }

  /// Handle element drag with optimized performance
  Future<GestureDispatchResult> _handleElementDragGesture(
    _SmartGestureType gesture,
    PointerEvent event,
    GestureContext context,
  ) async {
    final dragData = gesture.elementDragData!;

    // Use batched updates for performance
    if (event is PointerMoveEvent) {
      return await context.updateElementDrag(
        elementId: dragData.elementId,
        delta: dragData.currentPosition - dragData.startPosition,
        isBatched: true,
      );
    } else if (event is PointerUpEvent) {
      return await context.finalizeElementDrag(dragData.elementId);
    }

    return GestureDispatchResult.handled();
  }

  /// Handle fast pan for immediate response
  Future<GestureDispatchResult> _handleFastPanGesture(
    _SmartGestureType gesture,
    PointerEvent event,
    GestureContext context,
  ) async {
    // Immediate response for fast gestures
    return await context.fastPanCanvas(
      velocity: gesture.fastPanData!.velocity,
      direction: gesture.fastPanData!.direction,
    );
  }

  Future<GestureDispatchResult> _handleMultiPanGesture(
      _SmartGestureType gesture,
      PointerEvent event,
      GestureContext context) async {
    // Implementation for multi-touch panning
    return GestureDispatchResult.handled();
  }

  /// Handle multi-touch rotation gestures
  Future<GestureDispatchResult> _handleMultiRotateGesture(
    _SmartGestureType gesture,
    PointerEvent event,
    GestureContext context,
  ) async {
    final rotateData = gesture.multiRotateData!;

    return await context.rotateElements(
      rotationAngle: rotateData.rotationAngle,
      center: rotateData.center,
    );
  }

  /// Handle multi-touch scale gestures
  Future<GestureDispatchResult> _handleMultiScaleGesture(
    _SmartGestureType gesture,
    PointerEvent event,
    GestureContext context,
  ) async {
    final scaleData = gesture.multiScaleData!;

    return await context.scaleElements(
      scaleRatio: scaleData.scaleRatio,
      center: scaleData.center,
    );
  }

  // Additional gesture handler methods would be implemented here
  Future<GestureDispatchResult> _handleSelectionBoxGesture(
      _SmartGestureType gesture,
      PointerEvent event,
      GestureContext context) async {
    // Implementation for selection box handling
    return GestureDispatchResult.handled();
  }

  /// Handle tap gestures with intelligent routing
  Future<GestureDispatchResult> _handleTapGesture(
    _SmartGestureType gesture,
    PointerEvent event,
    GestureContext context,
  ) async {
    if (gesture.tapData == null) {
      return GestureDispatchResult.unhandled(reason: 'Tap data is null');
    }

    final tapData = gesture.tapData!;

    switch (tapData.tapType) {
      case _TapType.elementSelect:
        if (tapData.elementId == null) {
          return GestureDispatchResult.unhandled(reason: 'Element ID is null');
        }
        return await context.selectElement(tapData.elementId!);

      case _TapType.elementDeselect:
        if (tapData.elementId == null) {
          return GestureDispatchResult.unhandled(reason: 'Element ID is null');
        }
        return await context.deselectElement(tapData.elementId!);

      case _TapType.clearSelection:
        return await context.clearSelection();

      case _TapType.contextMenu:
        if (gesture.position == null) {
          return GestureDispatchResult.unhandled(reason: 'Position is null');
        }
        return await context.showContextMenu(gesture.position!);

      default:
        return GestureDispatchResult.unhandled();
    }
  }

  bool _isPointInElement(Offset point, Map<String, dynamic> element) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    return point.dx >= x &&
        point.dx <= x + width &&
        point.dy >= y &&
        point.dy <= y + height;
  }

  Future<_HitTestResult> _performHitTest(
      Offset position, GestureContext context) async {
    // Check for element hits (from top to bottom for correct layering)
    for (final element in context.elements.reversed) {
      if (_isPointInElement(position, element)) {
        return _HitTestResult.element(element['id'] as String);
      }
    }

    // Check for selection box area
    if (context.currentTool == 'select') {
      return _HitTestResult.selectionBox();
    }

    return _HitTestResult.canvas();
  }

  void _recordGestureEvent(_SmartGestureType gesture, Duration timeStamp) {
    _gestureHistory.add(_GestureEvent(
      type: gesture.type,
      confidence: gesture.confidence,
      timeStamp: timeStamp,
    ));

    // Limit history size
    if (_gestureHistory.length > _maxGestureHistory) {
      _gestureHistory.removeAt(0);
    }
  }

  /// Resolve gesture conflicts using priority and confidence scoring
  Future<_SmartGestureType> _resolveGestureConflicts(
    _SmartGestureType primaryGesture,
    GestureContext context,
  ) async {
    // If no conflict or confidence is high enough, return primary gesture
    if (_currentConflict == null || primaryGesture.confidence > 0.9) {
      return primaryGesture;
    }

    // Apply conflict resolution rules
    return await _applyConflictResolutionRules(primaryGesture, context);
  }

  /// Route gesture to appropriate handler based on type and context
  Future<GestureDispatchResult> _routeGesture(
    _SmartGestureType gesture,
    PointerEvent event,
    GestureContext context,
  ) async {
    // Record gesture event for analysis
    _recordGestureEvent(gesture, event.timeStamp);

    switch (gesture.type) {
      case _GestureTypeEnum.tap:
        return await _handleTapGesture(gesture, event, context);

      case _GestureTypeEnum.elementDrag:
        return await _handleElementDragGesture(gesture, event, context);

      case _GestureTypeEnum.selectionBox:
        return await _handleSelectionBoxGesture(gesture, event, context);

      case _GestureTypeEnum.canvasPan:
        return await _handleCanvasPanGesture(gesture, event, context);

      case _GestureTypeEnum.multiScale:
        return await _handleMultiScaleGesture(gesture, event, context);

      case _GestureTypeEnum.multiRotate:
        return await _handleMultiRotateGesture(gesture, event, context);

      case _GestureTypeEnum.multiPan:
        return await _handleMultiPanGesture(gesture, event, context);

      case _GestureTypeEnum.fastPan:
        return await _handleFastPanGesture(gesture, event, context);

      default:
        return GestureDispatchResult.unhandled();
    }
  }

  // Helper methods for calculations and utilities

  void _updateGestureTracking(PointerEvent event) {
    switch (event.runtimeType) {
      case PointerDownEvent:
        _activeGestures[event.pointer] = _GestureTracker(
          pointerId: event.pointer,
          startPosition: event.localPosition,
          currentPosition: event.localPosition,
          startTime: event.timeStamp,
        );
        break;

      case PointerMoveEvent:
        final tracker = _activeGestures[event.pointer];
        if (tracker != null) {
          tracker.updatePosition(event.localPosition, event.timeStamp);
        }
        break;

      case PointerUpEvent:
      case PointerCancelEvent:
        _activeGestures.remove(event.pointer);
        break;
    }
  }

  void _updatePerformanceMetrics() {
    final responseTime = _performanceStopwatch.elapsed;
    _responseTimes.add(responseTime);

    // Limit metrics history
    if (_responseTimes.length > 100) {
      _responseTimes.removeAt(0);
    }

    // Log performance warning if response time exceeds target
    if (responseTime > _responseTimeTarget) {
      EditPageLogger.performanceWarning('手势响应时间超出目标', data: {
        'actualMs': responseTime.inMilliseconds,
        'targetMs': _responseTimeTarget.inMilliseconds
      });
    }

    _performanceStopwatch.reset();
  }
}

class _CanvasPanData {
  final Offset startPosition;
  final Offset currentPosition;

  _CanvasPanData({
    required this.startPosition,
    required this.currentPosition,
  });
}

class _ElementDragData {
  final String elementId;
  final Offset startPosition;
  final Offset currentPosition;

  _ElementDragData({
    required this.elementId,
    required this.startPosition,
    required this.currentPosition,
  });
}

class _FastPanData {
  final double velocity;
  final double direction;

  _FastPanData({
    required this.velocity,
    required this.direction,
  });
}

class _GestureConflict {
  final List<_SmartGestureType> conflictingGestures;
  final Duration detectedAt;

  _GestureConflict({
    required this.conflictingGestures,
    required this.detectedAt,
  });
}

class _GestureEvent {
  final _GestureTypeEnum type;
  final double confidence;
  final Duration timeStamp;

  _GestureEvent({
    required this.type,
    required this.confidence,
    required this.timeStamp,
  });
}

// Supporting classes and enums

class _GestureTracker {
  final int pointerId;
  final Offset startPosition;
  final Duration startTime;

  Offset currentPosition;
  Duration? lastUpdateTime;
  double velocity = 0.0;

  _GestureTracker({
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
        velocity = (distance * 1000000) / timeDelta; // pixels per second
      }
    }

    currentPosition = newPosition;
    lastUpdateTime = timeStamp;
  }
}

enum _GestureTypeEnum {
  unknown,
  tap,
  elementDrag,
  selectionBox,
  canvasPan,
  multiScale,
  multiRotate,
  multiPan,
  fastPan,
}

class _HitTestResult {
  final bool isElement;
  final bool isSelectionBox;
  final bool isCanvas;
  final String? elementId;

  factory _HitTestResult.canvas() {
    return _HitTestResult._(isCanvas: true);
  }

  factory _HitTestResult.element(String elementId) {
    return _HitTestResult._(isElement: true, elementId: elementId);
  }

  factory _HitTestResult.selectionBox() {
    return _HitTestResult._(isSelectionBox: true);
  }

  _HitTestResult._({
    this.isElement = false,
    this.isSelectionBox = false,
    this.isCanvas = false,
    this.elementId,
  });
}

class _MultiPanData {
  final double velocity;
  final Offset direction;

  _MultiPanData({
    required this.velocity,
    required this.direction,
  });
}

class _MultiRotateData {
  final double rotationAngle;
  final Offset center;

  _MultiRotateData({
    required this.rotationAngle,
    required this.center,
  });
}

class _MultiScaleData {
  final double scaleRatio;
  final Offset center;

  _MultiScaleData({
    required this.scaleRatio,
    required this.center,
  });
}

class _SelectionBoxData {
  final Offset startPosition;
  final Offset currentPosition;

  _SelectionBoxData({
    required this.startPosition,
    required this.currentPosition,
  });
}

class _SmartGestureType {
  final _GestureTypeEnum type;
  final double confidence;
  final Offset? position;
  final bool isMultiTouch;

  // Specific gesture data
  final _TapData? tapData;
  final _ElementDragData? elementDragData;
  final _SelectionBoxData? selectionBoxData;
  final _CanvasPanData? canvasPanData;
  final _MultiScaleData? multiScaleData;
  final _MultiRotateData? multiRotateData;
  final _MultiPanData? multiPanData;
  final _FastPanData? fastPanData;

  factory _SmartGestureType.canvasPan({
    required double confidence,
    required Offset startPosition,
    required Offset currentPosition,
  }) =>
      _SmartGestureType._(
        type: _GestureTypeEnum.canvasPan,
        confidence: confidence,
        canvasPanData: _CanvasPanData(
          startPosition: startPosition,
          currentPosition: currentPosition,
        ),
      );

  factory _SmartGestureType.elementDrag({
    required double confidence,
    required String elementId,
    required Offset startPosition,
    required Offset currentPosition,
  }) =>
      _SmartGestureType._(
        type: _GestureTypeEnum.elementDrag,
        confidence: confidence,
        elementDragData: _ElementDragData(
          elementId: elementId,
          startPosition: startPosition,
          currentPosition: currentPosition,
        ),
      );

  factory _SmartGestureType.fastPan({
    required double confidence,
    required double velocity,
    required double direction,
  }) =>
      _SmartGestureType._(
        type: _GestureTypeEnum.fastPan,
        confidence: confidence,
        fastPanData: _FastPanData(
          velocity: velocity,
          direction: direction,
        ),
      );

  factory _SmartGestureType.multiPan({
    required double confidence,
    required double velocity,
    required Offset direction,
  }) =>
      _SmartGestureType._(
        type: _GestureTypeEnum.multiPan,
        confidence: confidence,
        isMultiTouch: true,
        multiPanData: _MultiPanData(
          velocity: velocity,
          direction: direction,
        ),
      );

  factory _SmartGestureType.multiRotate({
    required double confidence,
    required double rotationAngle,
    required Offset center,
  }) =>
      _SmartGestureType._(
        type: _GestureTypeEnum.multiRotate,
        confidence: confidence,
        isMultiTouch: true,
        multiRotateData: _MultiRotateData(
          rotationAngle: rotationAngle,
          center: center,
        ),
      );

  factory _SmartGestureType.multiScale({
    required double confidence,
    required double scaleRatio,
    required Offset center,
  }) =>
      _SmartGestureType._(
        type: _GestureTypeEnum.multiScale,
        confidence: confidence,
        isMultiTouch: true,
        multiScaleData: _MultiScaleData(
          scaleRatio: scaleRatio,
          center: center,
        ),
      );

  factory _SmartGestureType.selectionBox({
    required double confidence,
    required Offset startPosition,
    required Offset currentPosition,
  }) =>
      _SmartGestureType._(
        type: _GestureTypeEnum.selectionBox,
        confidence: confidence,
        selectionBoxData: _SelectionBoxData(
          startPosition: startPosition,
          currentPosition: currentPosition,
        ),
      );

  factory _SmartGestureType.tap({
    required double confidence,
    required Offset position,
    required _TapType tapType,
    String? elementId,
  }) {
    return _SmartGestureType._(
      type: _GestureTypeEnum.tap,
      confidence: confidence,
      position: position,
      tapData: _TapData(
        tapType: tapType,
        elementId: elementId,
      ),
    );
  }

  factory _SmartGestureType.unknown() => _SmartGestureType._(
        type: _GestureTypeEnum.unknown,
        confidence: 0.0,
      );

  _SmartGestureType._({
    required this.type,
    required this.confidence,
    this.position,
    this.isMultiTouch = false,
    this.tapData,
    this.elementDragData,
    this.selectionBoxData,
    this.canvasPanData,
    this.multiScaleData,
    this.multiRotateData,
    this.multiPanData,
    this.fastPanData,
  });

  _SmartGestureType copyWith({double? confidence}) {
    return _SmartGestureType._(
      type: type,
      confidence: confidence ?? this.confidence,
      position: position,
      isMultiTouch: isMultiTouch,
      tapData: tapData,
      elementDragData: elementDragData,
      selectionBoxData: selectionBoxData,
      canvasPanData: canvasPanData,
      multiScaleData: multiScaleData,
      multiRotateData: multiRotateData,
      multiPanData: multiPanData,
      fastPanData: fastPanData,
    );
  }
}

// Data classes for different gesture types
class _TapData {
  final _TapType tapType;
  final String? elementId;

  _TapData({required this.tapType, this.elementId});
}

enum _TapType {
  normal,
  elementSelect,
  elementDeselect,
  clearSelection,
  contextMenu,
}
