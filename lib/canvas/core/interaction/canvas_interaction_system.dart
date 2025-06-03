// filepath: lib/canvas/core/interaction/canvas_interaction_system.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

import '../events/canvas_gesture_event.dart';
import '../interfaces/element_data.dart';
import '../interfaces/element_data_extensions.dart';
import '../selection/selection_manager.dart';

/// Defines the current interaction mode for the canvas
enum CanvasInteractionMode {
  select,
  pan,
  draw,
  erase,
}

/// Comprehensive Canvas interaction system with advanced features
class CanvasInteractionSystem extends ChangeNotifier {
  final SelectionManager selectionManager;
  CanvasInteractionMode _currentMode = CanvasInteractionMode.select;
  Offset panOffset = Offset.zero;
  double zoomLevel = 1.0;
  // Interaction state
  InteractionMode _mode = InteractionMode.select;
  bool _isPanning = false;
  bool _isDragging = false;
  bool _isResizing = false;
  bool _isRotating = false;

  // Mouse/touch tracking
  Offset? _lastPointerPosition;
  Offset? _dragStartPosition;
  final Set<int> _activePointers = {};

  // Gesture handling
  final List<bool Function(CanvasGestureEvent)> _gestureHandlers = [];

  // Transform state
  Matrix4 _transform = Matrix4.identity();
  double _scale = 1.0;
  Offset _translation = Offset.zero;

  // Snapping system
  final SnapSystem _snapSystem = SnapSystem();
  bool _snapEnabled = true;

  // Grid system
  final GridSystem _gridSystem = GridSystem();
  bool _gridEnabled = false;

  // Multi-touch handling
  final Map<int, Offset> _pointerPositions = {};
  double? _initialPinchDistance;
  double? _initialPinchScale;

  // Element resize/rotate state
  ResizeHandle? _activeResizeHandle;
  String? _resizingElementId;
  String? _rotatingElementId;
  Rect? _initialElementBounds;
  double _initialRotation = 0.0;
  Offset? _rotationCenter;

  // Interaction callbacks
  Function(String elementId, Offset delta)? onElementDrag;
  Function(String elementId, Rect newBounds)? onElementResize;
  Function(String elementId, double angle)? onElementRotate;
  Function(Matrix4 transform)? onCanvasTransform;
  Function(Offset position)? onCanvasTap;
  Function(Offset start, Offset end)? onCanvasDrag;

  /// Constructor
  CanvasInteractionSystem({required this.selectionManager});

  ResizeHandle? get activeResizeHandle => _activeResizeHandle;

  /// Get current interaction mode
  CanvasInteractionMode get currentMode => _currentMode;

  /// Set current interaction mode
  set currentMode(CanvasInteractionMode mode) {
    _currentMode = mode;
  }

  bool get gridEnabled => _gridEnabled;
  GridSystem get gridSystem => _gridSystem;
  bool get isDragging => _isDragging;
  bool get isPanning => _isPanning;

  bool get isResizing => _isResizing;
  bool get isRotating => _isRotating;

  /// Getters
  InteractionMode get mode => _mode;
  String? get resizingElementId => _resizingElementId;
  String? get rotatingElementId => _rotatingElementId;
  double get scale => _scale;
  bool get snapEnabled => _snapEnabled;

  set snapEnabled(bool value) {
    _snapEnabled = value;
    notifyListeners();
  }

  Matrix4 get transform => Matrix4.copy(_transform);

  Offset get translation => _translation;

  /// Add gesture handler for canvas interactions
  void addGestureHandler(bool Function(CanvasGestureEvent) handler) {
    _gestureHandlers.add(handler);
  }

  /// Apply grid snapping
  Offset applyGridSnapping(Offset position) {
    if (!_gridEnabled) return position;

    return _gridSystem.snapToGrid(position);
  }

  /// Apply snapping to a delta movement
  Offset applySnapping(String elementId, Offset delta) {
    // Implement snapping logic here
    if (!snapEnabled) return delta;
    return delta;
  }

  /// Transform point from canvas to screen coordinates
  Offset canvasToScreen(Offset canvasPoint) {
    final vector =
        _transform.transform3(Vector3(canvasPoint.dx, canvasPoint.dy, 0));
    return Offset(vector.x, vector.y);
  }

  @override
  void dispose() {
    _activePointers.clear();
    _pointerPositions.clear();
    super.dispose();
  }

  /// End element drag operation
  void endElementDrag() {
    _isDragging = false;
    _dragStartPosition = null;
    notifyListeners();
  }

  /// End element resize operation
  void endElementResize() {
    _isResizing = false;
    _resizingElementId = null;
    _activeResizeHandle = null;
    _dragStartPosition = null;
    _initialElementBounds = null;
    notifyListeners();
  }

  /// End element rotation operation
  void endElementRotation() {
    _isRotating = false;
    _rotatingElementId = null;
    _dragStartPosition = null;
    _rotationCenter = null;
    _initialRotation = 0.0;
    notifyListeners();
  }

  /// Get element at screen position
  String? getElementAtPosition(
      Offset screenPosition, List<ElementData> elements) {
    final canvasPosition = screenToCanvas(screenPosition);

    // Check from top to bottom (reverse order for proper hit testing)
    for (int i = elements.length - 1; i >= 0; i--) {
      final element = elements[i];
      if (_isPointInElement(canvasPosition, element)) {
        return element.id;
      }
    }
    return null;
  }

  /// Calculate resize handle bounds for hit testing
  List<ResizeHandleData> getResizeHandles(Rect elementBounds) {
    const handleSize = 8.0;

    return [
      // Corner handles
      ResizeHandleData(
        handle: ResizeHandle.topLeft,
        bounds: Rect.fromCenter(
          center: elementBounds.topLeft,
          width: handleSize,
          height: handleSize,
        ),
      ),
      ResizeHandleData(
        handle: ResizeHandle.topRight,
        bounds: Rect.fromCenter(
          center: elementBounds.topRight,
          width: handleSize,
          height: handleSize,
        ),
      ),
      ResizeHandleData(
        handle: ResizeHandle.bottomLeft,
        bounds: Rect.fromCenter(
          center: elementBounds.bottomLeft,
          width: handleSize,
          height: handleSize,
        ),
      ),
      ResizeHandleData(
        handle: ResizeHandle.bottomRight,
        bounds: Rect.fromCenter(
          center: elementBounds.bottomRight,
          width: handleSize,
          height: handleSize,
        ),
      ),
      // Edge handles
      ResizeHandleData(
        handle: ResizeHandle.topCenter,
        bounds: Rect.fromCenter(
          center: Offset(elementBounds.center.dx, elementBounds.top),
          width: handleSize,
          height: handleSize,
        ),
      ),
      ResizeHandleData(
        handle: ResizeHandle.bottomCenter,
        bounds: Rect.fromCenter(
          center: Offset(elementBounds.center.dx, elementBounds.bottom),
          width: handleSize,
          height: handleSize,
        ),
      ),
      ResizeHandleData(
        handle: ResizeHandle.leftCenter,
        bounds: Rect.fromCenter(
          center: Offset(elementBounds.left, elementBounds.center.dy),
          width: handleSize,
          height: handleSize,
        ),
      ),
      ResizeHandleData(
        handle: ResizeHandle.rightCenter,
        bounds: Rect.fromCenter(
          center: Offset(elementBounds.right, elementBounds.center.dy),
          width: handleSize,
          height: handleSize,
        ),
      ),
    ];
  }

  /// Calculate rotation handle position
  Offset getRotationHandlePosition(Rect elementBounds) {
    return Offset(elementBounds.center.dx, elementBounds.top - 20);
  }

  /// Handle multi-touch end
  void handleMultiTouchEnd() {
    // Handle multi-touch gesture end
  }

  /// Handle multi-touch start
  void handleMultiTouchStart(List<PointerEvent> pointers) {
    // Initialize multi-touch gesture
  }

  void handlePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _pointerPositions.remove(event.pointer);

    if (_activePointers.isEmpty) {
      _cancelAllInteractions();
    }
  }

  /// Handle pointer events
  void handlePointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    _pointerPositions[event.pointer] = event.localPosition;
    _lastPointerPosition = event.localPosition;

    if (_activePointers.length == 1) {
      _handleSinglePointerDown(event);
    } else if (_activePointers.length == 2) {
      _handleTwoPointerDown(event);
    }
  }

  void handlePointerMove(PointerMoveEvent event) {
    _pointerPositions[event.pointer] = event.localPosition;
    _lastPointerPosition = event.localPosition;

    if (_activePointers.length == 1) {
      _handleSinglePointerMove(event);
    } else if (_activePointers.length == 2) {
      _handleTwoPointerMove(event);
    }
  }

  void handlePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    _pointerPositions.remove(event.pointer);

    if (_activePointers.isEmpty) {
      _handleAllPointersUp(event);
    } else if (_activePointers.length == 1) {
      // Reset single pointer interactions
      _initialPinchDistance = null;
      _initialPinchScale = null;
    }
  }

  /// Check if position hits resize handle
  ResizeHandle? hitTestResizeHandle(Offset position, Rect elementBounds) {
    final handles = getResizeHandles(elementBounds);

    for (final handleData in handles) {
      if (handleData.bounds.contains(position)) {
        return handleData.handle;
      }
    }

    return null;
  }

  /// Check if position hits rotation handle
  bool hitTestRotationHandle(Offset position, Rect elementBounds) {
    const handleSize = 8.0;
    final rotationHandlePos = getRotationHandlePosition(elementBounds);
    final handleBounds = Rect.fromCenter(
      center: rotationHandlePos,
      width: handleSize,
      height: handleSize,
    );

    return handleBounds.contains(position);
  }

  /// Check if multi-select is active (e.g. Shift key pressed)
  bool isMultiSelectActive() {
    // Return true if multi-select is active
    return false;
  }

  /// Pan the canvas
  void pan(Offset delta) {
    panOffset += delta / zoomLevel;
  }

  /// Process gesture event through registered handlers
  bool processGestureEvent(CanvasGestureEvent event) {
    for (final handler in _gestureHandlers) {
      if (handler(event)) return true;
    }
    return false;
  }

  /// Remove gesture handler
  void removeGestureHandler(bool Function(CanvasGestureEvent) handler) {
    _gestureHandlers.remove(handler);
  }

  /// Reset view to fit content
  void resetView({Size? canvasSize, Rect? contentBounds}) {
    if (canvasSize != null && contentBounds != null) {
      // Calculate transform to fit content
      final scaleX = canvasSize.width / contentBounds.width;
      final scaleY = canvasSize.height / contentBounds.height;
      final fitScale = math.min(scaleX, scaleY) * 0.9; // Add 10% padding

      final centerX = canvasSize.width / 2;
      final centerY = canvasSize.height / 2;
      final contentCenterX = contentBounds.center.dx;
      final contentCenterY = contentBounds.center.dy;

      _transform = Matrix4.identity()
        ..translate(centerX, centerY)
        ..scale(fitScale)
        ..translate(-contentCenterX, -contentCenterY);

      _extractTransformComponents();
      onCanvasTransform?.call(_transform);
      notifyListeners();
    } else {
      // Reset to identity
      _transform = Matrix4.identity();
      _scale = 1.0;
      _translation = Offset.zero;
      onCanvasTransform?.call(_transform);
      notifyListeners();
    }
  }

  /// Transform point from screen to canvas coordinates
  Offset screenToCanvas(Offset screenPoint) {
    final inverse = Matrix4.tryInvert(_transform);
    if (inverse != null) {
      final vector =
          inverse.transform3(Vector3(screenPoint.dx, screenPoint.dy, 0));
      return Offset(vector.x, vector.y);
    }
    return screenPoint;
  }

  /// Set the canvas size for coordinate transformations
  void setCanvasSize(Size size) {
    // Update internal state if needed
    notifyListeners();
  }

  /// Set interaction mode
  void setMode(InteractionMode mode) {
    if (_mode != mode) {
      // Cancel any ongoing interactions when changing modes
      _cancelAllInteractions();
      _mode = mode;
      notifyListeners();
    }
  }

  /// Set the viewport for rendering
  void setViewport(Rect viewport) {
    // Update internal state if needed
    notifyListeners();
  }

  /// Set zoom level
  void setZoom(double zoom) {
    if (zoom != _scale) {
      const center = Offset.zero; // Use canvas center for zoom
      _applyScaleAroundPoint(zoom / _scale, center);
    }
  }

  /// Start element drag operation
  void startElementDrag(String elementId, Offset startPosition) {
    if (!selectionManager.isSelected(elementId)) {
      selectionManager.selectElement(elementId);
    }

    _isDragging = true;
    _dragStartPosition = screenToCanvas(startPosition);

    // Update snap points excluding selected elements
    final allElements = _getAllElementsForSnapping();
    _snapSystem.updateSnapPoints(allElements, excludeElementId: elementId);

    notifyListeners();
  }

  /// Start element resize operation
  void startElementResize(String elementId, ResizeHandle handle,
      Offset startPosition, Rect elementBounds) {
    _isResizing = true;
    _resizingElementId = elementId;
    _activeResizeHandle = handle;
    _dragStartPosition = screenToCanvas(startPosition);
    _initialElementBounds = elementBounds;

    // Update snap points
    final allElements = _getAllElementsForSnapping();
    _snapSystem.updateSnapPoints(allElements, excludeElementId: elementId);

    notifyListeners();
  }

  /// Start element rotation operation
  void startElementRotation(String elementId, Offset startPosition,
      Rect elementBounds, double initialRotation) {
    _isRotating = true;
    _rotatingElementId = elementId;
    _dragStartPosition = screenToCanvas(startPosition);
    _rotationCenter = elementBounds.center;
    _initialRotation = initialRotation;

    notifyListeners();
  }

  /// Toggle grid
  void toggleGrid() {
    _gridEnabled = !_gridEnabled;
    notifyListeners();
  }

  /// Toggle snap
  void toggleSnap() {
    _snapEnabled = !_snapEnabled;
    notifyListeners();
  }

  /// Update element drag
  void updateElementDrag(Offset currentPosition) {
    if (!_isDragging || _dragStartPosition == null) return;

    final canvasPosition = screenToCanvas(currentPosition);
    var delta = canvasPosition - _dragStartPosition!;

    // Apply snapping
    if (_snapEnabled) {
      final snappedPosition = _snapSystem.snapPosition(canvasPosition);
      delta = snappedPosition - _dragStartPosition!;
    }

    // Apply to selected elements
    for (final elementId in selectionManager.selectedIds) {
      onElementDrag?.call(elementId, delta);
    }
  }

  /// Update element resize
  void updateElementResize(Offset currentPosition) {
    if (!_isResizing ||
        _dragStartPosition == null ||
        _initialElementBounds == null ||
        _activeResizeHandle == null ||
        _resizingElementId == null) return;

    final canvasPosition = screenToCanvas(currentPosition);
    var delta = canvasPosition - _dragStartPosition!;

    // Apply snapping
    if (_snapEnabled) {
      final snappedPosition = _snapSystem.snapPosition(canvasPosition);
      delta = snappedPosition - _dragStartPosition!;
    }

    // Calculate new bounds based on resize handle
    final newBounds = _calculateResizedBounds(
        _initialElementBounds!, _activeResizeHandle!, delta);

    onElementResize?.call(_resizingElementId!, newBounds);
  }

  /// Update element rotation
  void updateElementRotation(Offset currentPosition) {
    if (!_isRotating ||
        _dragStartPosition == null ||
        _rotationCenter == null ||
        _rotatingElementId == null) return;

    final canvasPosition = screenToCanvas(currentPosition);

    // Calculate rotation angle
    final startVector = _dragStartPosition! - _rotationCenter!;
    final currentVector = canvasPosition - _rotationCenter!;

    final startAngle = math.atan2(startVector.dy, startVector.dx);
    final currentAngle = math.atan2(currentVector.dy, currentVector.dx);

    var deltaAngle = currentAngle - startAngle;

    // Snap to 15-degree increments when snapping is enabled
    if (_snapEnabled) {
      const snapAngle = math.pi / 12; // 15 degrees
      deltaAngle = (deltaAngle / snapAngle).round() * snapAngle;
    }

    final newRotation = _initialRotation + deltaAngle;
    onElementRotate?.call(_rotatingElementId!, newRotation);
  }

  /// Update canvas transform
  void updateTransform(Matrix4 newTransform) {
    _transform = Matrix4.copy(newTransform);
    _extractTransformComponents();
    onCanvasTransform?.call(_transform);
    notifyListeners();
  }

  /// Zoom to fit selected elements
  void zoomToFitElements(List<Map<String, dynamic>> elements) {
    // Implement zoom to fit logic
  }

  void _applyScaleAroundPoint(double scaleFactor, Offset center) {
    // Transform center to canvas coordinates
    final canvasCenter = screenToCanvas(center);

    // Apply scale around center
    _transform
      ..translate(canvasCenter.dx, canvasCenter.dy)
      ..scale(scaleFactor)
      ..translate(-canvasCenter.dx, -canvasCenter.dy);

    _extractTransformComponents();
    onCanvasTransform?.call(_transform);
    notifyListeners();
  }

  /// Calculate new bounds after resize
  Rect _calculateResizedBounds(
      Rect originalBounds, ResizeHandle handle, Offset delta) {
    var left = originalBounds.left;
    var top = originalBounds.top;
    var right = originalBounds.right;
    var bottom = originalBounds.bottom;

    switch (handle) {
      case ResizeHandle.topLeft:
        left += delta.dx;
        top += delta.dy;
        break;
      case ResizeHandle.topCenter:
        top += delta.dy;
        break;
      case ResizeHandle.topRight:
        right += delta.dx;
        top += delta.dy;
        break;
      case ResizeHandle.leftCenter:
        left += delta.dx;
        break;
      case ResizeHandle.rightCenter:
        right += delta.dx;
        break;
      case ResizeHandle.bottomLeft:
        left += delta.dx;
        bottom += delta.dy;
        break;
      case ResizeHandle.bottomCenter:
        bottom += delta.dy;
        break;
      case ResizeHandle.bottomRight:
        right += delta.dx;
        bottom += delta.dy;
        break;
    }

    // Ensure minimum size
    const minSize = 10.0;
    if (right - left < minSize) {
      if (handle == ResizeHandle.topLeft ||
          handle == ResizeHandle.leftCenter ||
          handle == ResizeHandle.bottomLeft) {
        left = right - minSize;
      } else {
        right = left + minSize;
      }
    }

    if (bottom - top < minSize) {
      if (handle == ResizeHandle.topLeft ||
          handle == ResizeHandle.topCenter ||
          handle == ResizeHandle.topRight) {
        top = bottom - minSize;
      } else {
        bottom = top + minSize;
      }
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _cancelAllInteractions() {
    _isPanning = false;
    _isDragging = false;
    _isResizing = false;
    _isRotating = false;
    _dragStartPosition = null;
    selectionManager.cancelBoxSelection();
    notifyListeners();
  }

  void _endDragging() {
    _isDragging = false;
    _dragStartPosition = null;
    notifyListeners();
  }

  void _endPanning() {
    _isPanning = false;
    _dragStartPosition = null;
    notifyListeners();
  }

  void _extractTransformComponents() {
    // Extract scale and translation from transform matrix
    final m = _transform.storage;
    _scale = math.sqrt(m[0] * m[0] + m[1] * m[1]);
    _translation = Offset(m[12], m[13]);
  }

  /// Get all elements for snapping calculations
  List<ElementData> _getAllElementsForSnapping() {
    // This would need to be provided by the integration layer
    // For now, return empty list
    return [];
  }

  void _handleAllPointersUp(PointerUpEvent event) {
    if (_isPanning) {
      _endPanning();
    } else if (_isDragging) {
      _endDragging();
    } else if (selectionManager.isBoxSelecting) {
      selectionManager.completeBoxSelection();
    }

    _initialPinchDistance = null;
    _initialPinchScale = null;
  }

  void _handleSelectPointerDown(Offset screenPos, Offset canvasPos) {
    // Check for UI control handles first
    // Then check for elements
    // Finally start box selection if nothing is hit

    _dragStartPosition = canvasPos;

    // Start box selection for now (simplified)
    selectionManager.startBoxSelection(canvasPos);
  }

  /// Private methods
  void _handleSinglePointerDown(PointerDownEvent event) {
    final screenPos = event.localPosition;
    final canvasPos = screenToCanvas(screenPos);

    switch (_mode) {
      case InteractionMode.select:
        _handleSelectPointerDown(screenPos, canvasPos);
        break;
      case InteractionMode.pan:
        _startPanning(screenPos);
        break;
      case InteractionMode.draw:
        // Handle drawing mode
        break;
    }
  }

  void _handleSinglePointerMove(PointerMoveEvent event) {
    if (_lastPointerPosition == null) return;

    final delta = event.localPosition - _lastPointerPosition!;

    if (_isPanning) {
      _updatePanning(delta);
    } else if (_isDragging) {
      _updateDragging(event.localPosition);
    } else if (selectionManager.isBoxSelecting) {
      selectionManager.updateBoxSelection(screenToCanvas(event.localPosition));
    }
  }

  void _handleTwoPointerDown(PointerDownEvent event) {
    // Start pinch-to-zoom
    final positions = _pointerPositions.values.toList();
    if (positions.length >= 2) {
      _initialPinchDistance = (positions[0] - positions[1]).distance;
      _initialPinchScale = _scale;
    }
  }

  void _handleTwoPointerMove(PointerMoveEvent event) {
    final positions = _pointerPositions.values.toList();
    if (positions.length >= 2 &&
        _initialPinchDistance != null &&
        _initialPinchScale != null) {
      final currentDistance = (positions[0] - positions[1]).distance;
      final scaleChange = currentDistance / _initialPinchDistance!;
      final newScale = (_initialPinchScale! * scaleChange).clamp(0.1, 5.0);

      // Calculate center point for scaling
      final center = (positions[0] + positions[1]) / 2;

      _applyScaleAroundPoint(newScale / _scale, center);
    }
  }

  bool _isPointInElement(Offset point, ElementData element) {
    final rect = Rect.fromLTWH(
      element.x,
      element.y,
      element.width,
      element.height,
    );
    return rect.contains(point);
  }

  void _startPanning(Offset startPosition) {
    _isPanning = true;
    _dragStartPosition = startPosition;
    notifyListeners();
  }

  void _updateDragging(Offset currentPosition) {
    if (_isDragging && _dragStartPosition != null) {
      final delta = screenToCanvas(currentPosition) - _dragStartPosition!;

      // Apply snapping to selected elements
      for (final elementId in selectionManager.selectedIds) {
        // Apply snapping with the correct arguments
        final snappedDelta = applySnapping(elementId, delta);
        onElementDrag?.call(elementId, snappedDelta);
      }
    }
  }

  void _updatePanning(Offset delta) {
    if (_isPanning) {
      _transform.translate(delta.dx, delta.dy);
      _extractTransformComponents();
      onCanvasTransform?.call(_transform);
      notifyListeners();
    }
  }
}

/// Grid line data
class GridLine {
  final Offset start;
  final Offset end;
  final Color color;

  const GridLine({
    required this.start,
    required this.end,
    required this.color,
  });
}

/// Grid system for canvas alignment
class GridSystem {
  double gridSize = 20.0;
  Color gridColor = const Color(0x33000000);
  bool showGrid = true;

  /// Get grid lines for rendering
  List<GridLine> getGridLines(Rect viewBounds) {
    final lines = <GridLine>[];

    if (!showGrid) return lines;

    // Calculate grid bounds
    final left = (viewBounds.left / gridSize).floor() * gridSize;
    final right = (viewBounds.right / gridSize).ceil() * gridSize;
    final top = (viewBounds.top / gridSize).floor() * gridSize;
    final bottom = (viewBounds.bottom / gridSize).ceil() * gridSize;

    // Vertical lines
    for (double x = left; x <= right; x += gridSize) {
      lines.add(GridLine(
        start: Offset(x, viewBounds.top),
        end: Offset(x, viewBounds.bottom),
        color: gridColor,
      ));
    }

    // Horizontal lines
    for (double y = top; y <= bottom; y += gridSize) {
      lines.add(GridLine(
        start: Offset(viewBounds.left, y),
        end: Offset(viewBounds.right, y),
        color: gridColor,
      ));
    }

    return lines;
  }

  /// Snap point to grid
  Offset snapToGrid(Offset point) {
    return Offset(
      (point.dx / gridSize).round() * gridSize,
      (point.dy / gridSize).round() * gridSize,
    );
  }
}

/// Interaction modes
enum InteractionMode {
  select,
  pan,
  draw,
}

/// Resize handle enum
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

  ResizeHandleData({
    required this.handle,
    required this.bounds,
  });
}

/// Snapping system for precise element positioning
class SnapSystem {
  static const double defaultSnapDistance = 10.0;

  double snapDistance = defaultSnapDistance;
  bool snapToElements = true;
  bool snapToGrid = true;
  bool snapToGuides = true;
  final List<Offset> _snapPoints = [];
  // Note: _guides will be used for custom guides in future implementation

  /// Snap position to nearest snap point
  Offset snapPosition(Offset position, {String? excludeElementId}) {
    if (!snapToElements) return position;

    Offset? closestPoint;
    double closestDistance = snapDistance;

    for (final snapPoint in _snapPoints) {
      final distance = (position - snapPoint).distance;
      if (distance < closestDistance) {
        closestDistance = distance;
        closestPoint = snapPoint;
      }
    }

    return closestPoint ?? position;
  }

  /// Add snap points from elements
  void updateSnapPoints(List<ElementData> elements,
      {String? excludeElementId}) {
    _snapPoints.clear();

    for (final element in elements) {
      if (element.id == excludeElementId) continue;

      final rect =
          Rect.fromLTWH(element.x, element.y, element.width, element.height);

      // Add corner points
      _snapPoints.addAll([
        rect.topLeft,
        rect.topRight,
        rect.bottomLeft,
        rect.bottomRight,
      ]);

      // Add center points
      _snapPoints.addAll([
        rect.center,
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
      ]);
    }
  }
}
