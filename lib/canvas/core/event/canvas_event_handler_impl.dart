import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../effects/canvas_effects_system.dart';
import '../element/element_creation_system.dart';
import '../interaction/canvas_interaction_system.dart';
import '../performance/canvas_performance_optimizer.dart';
import '../selection/selection_manager.dart';
import 'canvas_event_handler.dart';

/// Event handling integration system that unifies new Canvas systems
/// with existing drag/resize/rotate operations
class CanvasEventHandlerImpl implements CanvasEventHandler {
  // Performance optimization
  static const Duration _throttleDuration = Duration(milliseconds: 16);

  // Dependencies
  final CanvasInteractionSystem _interactionSystem;
  final SelectionManager _selectionManager;
  final ElementCreationSystem _elementCreationSystem;
  final CanvasEffectsSystem _effectsSystem;
  final CanvasPerformanceOptimizer _performanceOptimizer;

  // Current operation state
  CanvasOperation _currentOperation = CanvasOperation.none;
  String? _activeElementId;
  String? _activeHandleType;

  // Gesture tracking
  final Map<int, PointerInfo> _activePointers = {};
  Offset? _lastPanPosition;
  DateTime _lastUpdateTime = DateTime.now();

  // Event callbacks to existing system
  final Function(String elementId, Map<String, dynamic> properties)?
      onElementUpdate;
  final Function(String elementId, Map<String, dynamic> properties)?
      onElementUpdateEnd;
  final Function(String elementId)? onElementSelect;
  final Function(List<String> elementIds)? onMultiSelect;
  final Function()? onCanvasUpdate;

  CanvasEventHandlerImpl({
    required CanvasInteractionSystem interactionSystem,
    required SelectionManager selectionManager,
    required ElementCreationSystem elementCreationSystem,
    required CanvasEffectsSystem effectsSystem,
    this.onElementUpdate,
    this.onElementUpdateEnd,
    this.onElementSelect,
    this.onMultiSelect,
    this.onCanvasUpdate,
  })  : _interactionSystem = interactionSystem,
        _selectionManager = selectionManager,
        _elementCreationSystem = elementCreationSystem,
        _effectsSystem = effectsSystem,
        _performanceOptimizer = CanvasPerformanceOptimizer();

  /// Get current interaction mode
  @override
  CanvasInteractionMode get currentMode => _interactionSystem.currentMode;

  /// Set interaction mode
  @override
  set currentMode(CanvasInteractionMode mode) {
    _interactionSystem.currentMode = mode;
  }

  /// Get current pan offset
  @override
  Offset get panOffset => _interactionSystem.panOffset;

  /// Get current zoom level
  @override
  double get zoomLevel => _interactionSystem.zoomLevel;

  /// Set zoom level
  @override
  set zoomLevel(double zoom) {
    _interactionSystem.setZoom(zoom);
    onCanvasUpdate?.call();
  }

  /// Handle long press for context menu
  @override
  void handleLongPress(LongPressStartDetails details) {
    final canvasPosition =
        _interactionSystem.screenToCanvas(details.localPosition);
    final hitResult = _performHitTest(canvasPosition);

    if (hitResult.type == HitTestType.element) {
      // Show context menu for element
      _showElementContextMenu(hitResult.elementId!, details.globalPosition);
    }
  }

  /// Handle pan end events (for compatibility with existing system)
  @override
  void handlePanEnd(DragEndDetails details) {
    final pointerEvent = PointerUpEvent(
      pointer: 1,
      position: details.globalPosition,
    );
    handlePointerUp(pointerEvent);
  }

  /// Handle pan start events (for compatibility with existing system)
  @override
  void handlePanStart(DragStartDetails details) {
    final pointerEvent = PointerDownEvent(
      pointer: 1,
      position: details.globalPosition,
    );
    handlePointerDown(pointerEvent);
  }

  /// Handle pan update events (for compatibility with existing system)
  @override
  void handlePanUpdate(DragUpdateDetails details) {
    final pointerEvent = PointerMoveEvent(
      pointer: 1,
      position: details.globalPosition,
      delta: details.delta,
    );
    handlePointerMove(pointerEvent);
  }

  /// Handle pointer down events
  @override
  void handlePointerDown(PointerDownEvent event) {
    final pointerId = event.pointer;
    final canvasPosition =
        _interactionSystem.screenToCanvas(event.localPosition);

    _activePointers[pointerId] = PointerInfo(
      id: pointerId,
      startPosition: event.localPosition,
      currentPosition: event.localPosition,
      canvasPosition: canvasPosition,
    );

    // Handle multi-touch for pinch-to-zoom
    if (_activePointers.length > 1) {
      _currentOperation = CanvasOperation.multiTouch;
      // Implement multi-touch handling
      return;
    }

    // Determine what was hit
    final hitResult = _performHitTest(canvasPosition);

    switch (hitResult.type) {
      case HitTestType.element:
        _handleElementPointerDown(hitResult, canvasPosition);
        break;
      case HitTestType.controlHandle:
        _handleControlHandlePointerDown(hitResult, canvasPosition);
        break;
      case HitTestType.canvas:
        _handleCanvasPointerDown(canvasPosition);
        break;
    }
  }

  /// Handle pointer move events
  @override
  void handlePointerMove(PointerMoveEvent event) {
    final pointerId = event.pointer;
    if (!_activePointers.containsKey(pointerId)) return;

    final pointerInfo = _activePointers[pointerId]!;
    final previousPosition = pointerInfo.currentPosition;
    final currentPosition = event.localPosition;
    final canvasPosition = _interactionSystem.screenToCanvas(currentPosition);

    // Update pointer tracking
    _activePointers[pointerId] = PointerInfo(
      id: pointerId,
      startPosition: pointerInfo.startPosition,
      currentPosition: currentPosition,
      canvasPosition: canvasPosition,
    );

    // Handle multi-touch gestures
    if (_currentOperation == CanvasOperation.multiTouch) {
      _handleMultiTouchGesture();
      return;
    }

    // Apply throttling to reduce event frequency
    final now = DateTime.now();
    if (now.difference(_lastUpdateTime) < _throttleDuration) {
      return;
    }
    _lastUpdateTime = now;

    // Handle based on current operation
    switch (_currentOperation) {
      case CanvasOperation.elementDrag:
        _handleElementDrag(canvasPosition, previousPosition, currentPosition);
        break;
      case CanvasOperation.elementResize:
        _handleElementResize(canvasPosition, previousPosition, currentPosition);
        break;
      case CanvasOperation.elementRotate:
        _handleElementRotate(canvasPosition, previousPosition, currentPosition);
        break;
      case CanvasOperation.canvasPan:
        _handleCanvasPan(event.delta);
        break;
      case CanvasOperation.boxSelection:
        _handleBoxSelection(canvasPosition);
        break;
      case CanvasOperation.elementCreation:
        _handleElementCreation(canvasPosition);
        break;
      default:
        // No active operation, track hover
        _updateHoverState(canvasPosition);
        break;
    }
  }

  /// Handle pointer up events
  @override
  void handlePointerUp(PointerUpEvent event) {
    final pointerId = event.pointer;
    if (!_activePointers.containsKey(pointerId)) return;

    final pointerInfo = _activePointers[pointerId]!;
    final canvasPosition =
        _interactionSystem.screenToCanvas(event.localPosition);

    // Handle multi-touch release
    if (_activePointers.length > 1) {
      _activePointers.remove(pointerId);
      if (_activePointers.length == 1) {
        // Fall back to normal operation
        _currentOperation = CanvasOperation.none;
      }
      return;
    }

    // Complete current operation
    switch (_currentOperation) {
      case CanvasOperation.elementDrag:
        _completeElementDrag();
        break;
      case CanvasOperation.elementResize:
        _completeElementResize();
        break;
      case CanvasOperation.elementRotate:
        _completeElementRotate();
        break;
      case CanvasOperation.canvasPan:
        // Nothing to complete for pan
        break;
      case CanvasOperation.boxSelection:
        _completeBoxSelection(pointerInfo.startPosition, canvasPosition);
        break;
      case CanvasOperation.elementCreation:
        _completeElementCreation(pointerInfo.startPosition, canvasPosition);
        break;
      default:
        // For click without drag, handle selection
        if ((canvasPosition - pointerInfo.canvasPosition).distance < 5) {
          _handleClick(canvasPosition);
        }
        break;
    }

    // Reset state
    _activePointers.remove(pointerId);
    _currentOperation = CanvasOperation.none;
    _activeElementId = null;
    _activeHandleType = null;
  }

  /// Handle scale end (for pinch gesture)
  @override
  void handleScaleEnd(ScaleEndDetails details) {
    // Clean up any scale-related state
    _currentOperation = CanvasOperation.none;
  }

  /// Handle scale start (for pinch gesture)
  @override
  void handleScaleStart(ScaleStartDetails details) {
    // Mark as multi-touch operation
    _currentOperation = CanvasOperation.multiTouch;
    _lastPanPosition = details.localFocalPoint;
  }

  /// Handle scale update (for pinch gesture)
  @override
  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (_lastPanPosition == null) {
      _lastPanPosition = details.localFocalPoint;
      return;
    }

    // Handle pan
    final delta = details.localFocalPoint - _lastPanPosition!;
    _interactionSystem.pan(delta);
    _lastPanPosition = details.localFocalPoint; // Handle zoom
    if (details.scale != 1.0) {
      final oldZoom = _interactionSystem.zoomLevel;
      final newZoom = oldZoom * details.scale;
      _interactionSystem.setZoom(newZoom);
    }

    onCanvasUpdate?.call();
  }

  /// Handle zoom in action
  @override
  void zoomIn({Offset? focalPoint}) {
    final oldZoom = _interactionSystem.zoomLevel;
    final newZoom = oldZoom * 1.2;
    _interactionSystem.setZoom(newZoom);
    onCanvasUpdate?.call();
  }

  /// Handle zoom out action
  @override
  void zoomOut({Offset? focalPoint}) {
    final oldZoom = _interactionSystem.zoomLevel;
    final newZoom = oldZoom / 1.2;
    _interactionSystem.setZoom(newZoom);
    onCanvasUpdate?.call();
  }

  /// Handle zoom to fit action
  @override
  void zoomToFit(Size viewportSize, List<Map<String, dynamic>> elements) {
    if (elements.isEmpty) return;

    // Calculate bounding box of all elements
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final element in elements) {
      final x = (element['x'] as num?)?.toDouble() ?? 0.0;
      final y = (element['y'] as num?)?.toDouble() ?? 0.0;
      final width = (element['width'] as num?)?.toDouble() ?? 0.0;
      final height = (element['height'] as num?)?.toDouble() ?? 0.0;

      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x + width);
      maxY = math.max(maxY, y + height);
    }

    final contentWidth = maxX - minX;
    final contentHeight = maxY - minY;
    final contentCenter =
        Offset(minX + contentWidth / 2, minY + contentHeight / 2);

    // Calculate optimal zoom level
    final horizontalZoom = viewportSize.width / (contentWidth * 1.1);
    final verticalZoom = viewportSize.height / (contentHeight * 1.1);
    final newZoom = math.min(
        horizontalZoom, verticalZoom); // Apply zoom and center the content
    _interactionSystem.setZoom(newZoom);
    final viewportCenter =
        Offset(viewportSize.width / 2, viewportSize.height / 2);
    final newPanOffset = viewportCenter - contentCenter * newZoom;
    _interactionSystem.panOffset = newPanOffset;

    onCanvasUpdate?.call();
  }

  // Internal implementation methods

  /// Complete box selection operation
  void _completeBoxSelection(Offset startPosition, Offset endPosition) {
    final rect = Rect.fromPoints(
      _interactionSystem.screenToCanvas(startPosition),
      _interactionSystem.screenToCanvas(endPosition),
    );

    // Ensure rectangle has positive width and height
    final selectionRect = Rect.fromLTRB(
      math.min(rect.left, rect.right),
      math.min(rect.top, rect.bottom),
      math.max(rect.left, rect.right),
      math.max(rect.top, rect.bottom),
    );

    // Get elements in the selection area
    final selectedElements = _getElementsInRect(selectionRect);

    if (selectedElements.isNotEmpty) {
      final selectedIds =
          selectedElements.map((e) => e['id'] as String).toList();
      _selectionManager.selectElements(selectedIds.toSet());
      onMultiSelect?.call(selectedIds);
    } else {
      _selectionManager.clearSelection();
    }
  }

  /// Complete element creation operation
  void _completeElementCreation(Offset startPosition, Offset endPosition) {
    final startCanvasPos = _interactionSystem.screenToCanvas(startPosition);
    final endCanvasPos = _interactionSystem.screenToCanvas(endPosition);

    // Calculate bounds with proper size
    final minX = math.min(startCanvasPos.dx, endCanvasPos.dx);
    final minY = math.min(startCanvasPos.dy, endCanvasPos.dy);
    final width = (startCanvasPos.dx - endCanvasPos.dx).abs();
    final height = (startCanvasPos.dy - endCanvasPos.dy)
        .abs(); // Only create if has minimum size
    if (width > 10 && height > 10) {
      _elementCreationSystem.createElementAtPosition(
        ElementCreationType
            .shape, // Default to shape if currentCreationType is null
        Offset(minX, minY),
        properties: {
          'width': width,
          'height': height,
        },
      );
    }
  }

  /// Complete element drag operation
  void _completeElementDrag() {
    if (_activeElementId == null) return;

    // Notify completion of drag
    onElementUpdateEnd?.call(_activeElementId!, {
      'dragged': true,
    });
  }

  /// Complete element resize operation
  void _completeElementResize() {
    if (_activeElementId == null) return;

    // Notify completion of resize
    onElementUpdateEnd?.call(_activeElementId!, {
      'resized': true,
    });
  }

  /// Complete element rotation operation
  void _completeElementRotate() {
    if (_activeElementId == null) return;

    // Notify completion of rotation
    onElementUpdateEnd?.call(_activeElementId!, {
      'rotated': true,
    });
  }

  /// Get element by ID
  Map<String, dynamic>? _getElement(String elementId) {
    // This should be implemented based on your element storage system
    // Placeholder implementation
    return null;
  }

  /// Get element at position
  Map<String, dynamic>? _getElementAt(Offset position) {
    // This should be implemented based on your element storage system
    // Placeholder implementation
    return null;
  }

  /// Get elements that intersect with a rectangle
  List<Map<String, dynamic>> _getElementsInRect(Rect rect) {
    // This should be implemented based on your element storage system
    // Placeholder implementation
    return [];
  }

  /// Handle box selection update
  void _handleBoxSelection(Offset canvasPosition) {
    // This will be used for rendering the selection rectangle
    // Implementation depends on your rendering system
  }

  /// Handle canvas pan operation
  void _handleCanvasPan(Offset delta) {
    _interactionSystem.pan(delta);
    onCanvasUpdate?.call();
  }

  /// Handle a pointer down on the canvas (not on an element)
  void _handleCanvasPointerDown(Offset canvasPosition) {
    switch (_interactionSystem.currentMode) {
      case CanvasInteractionMode.select:
        // Start box selection
        _currentOperation = CanvasOperation.boxSelection;
        break;
      case CanvasInteractionMode.pan:
        // Start canvas panning
        _currentOperation = CanvasOperation.canvasPan;
        break;
      case CanvasInteractionMode.draw:
        // Start element creation
        _currentOperation = CanvasOperation.elementCreation;
        break;
      default:
        // Other modes
        break;
    }
  }

  /// Handle click without drag
  void _handleClick(Offset canvasPosition) {
    final hitResult = _performHitTest(canvasPosition);

    switch (hitResult.type) {
      case HitTestType.element:
        // Toggle selection if already selected, otherwise select
        if (_selectionManager.selectedIds.contains(hitResult.elementId)) {
          _selectionManager.deselectElement(hitResult.elementId!);
        } else {
          _selectionManager.selectElement(hitResult.elementId!);
          onElementSelect?.call(hitResult.elementId!);
        }
        break;
      case HitTestType.canvas:
        // Clear selection when clicking on empty canvas
        _selectionManager.clearSelection();
        break;
      default:
        break;
    }
  }

  /// Handle a pointer down on a control handle
  void _handleControlHandlePointerDown(
      HitTestResult hitResult, Offset canvasPosition) {
    _activeElementId = hitResult.elementId;
    _activeHandleType = hitResult.handleType;

    // Set the appropriate operation based on handle type
    if (hitResult.handleType == 'rotate') {
      _currentOperation = CanvasOperation.elementRotate;
    } else {
      _currentOperation = CanvasOperation.elementResize;
    }
  }

  /// Handle element creation during drag
  void _handleElementCreation(Offset canvasPosition) {
    // This will be used for rendering the preview of the element being created
    // Implementation depends on your element creation system
  }

  /// Handle element drag operation
  void _handleElementDrag(Offset canvasPosition, Offset previousScreenPosition,
      Offset currentScreenPosition) {
    if (_activeElementId == null) return;

    // Calculate delta in canvas coordinates
    final previousCanvasPosition =
        _interactionSystem.screenToCanvas(previousScreenPosition);
    final currentCanvasPosition =
        _interactionSystem.screenToCanvas(currentScreenPosition);
    final delta = currentCanvasPosition - previousCanvasPosition;

    // Notify about the drag update
    onElementUpdate?.call(_activeElementId!, {
      'deltaX': delta.dx,
      'deltaY': delta.dy,
      'dragging': true,
    });
  }

  /// Handle a pointer down on an element
  void _handleElementPointerDown(
      HitTestResult hitResult, Offset canvasPosition) {
    _activeElementId = hitResult.elementId;

    // Select the element if not already selected
    if (!_selectionManager.selectedIds.contains(hitResult.elementId)) {
      _selectionManager.selectElement(hitResult.elementId!);
      onElementSelect?.call(hitResult.elementId!);
    }

    // Start drag operation
    _currentOperation = CanvasOperation.elementDrag;
  }

  /// Handle element resize operation
  void _handleElementResize(Offset canvasPosition,
      Offset previousScreenPosition, Offset currentScreenPosition) {
    if (_activeElementId == null || _activeHandleType == null) return;

    // Calculate delta in canvas coordinates
    final previousCanvasPosition =
        _interactionSystem.screenToCanvas(previousScreenPosition);
    final currentCanvasPosition =
        _interactionSystem.screenToCanvas(currentScreenPosition);
    final delta = currentCanvasPosition - previousCanvasPosition;

    // Notify about the resize update with handle information
    onElementUpdate?.call(_activeElementId!, {
      'handle': _activeHandleType,
      'deltaX': delta.dx,
      'deltaY': delta.dy,
      'resizing': true,
    });
  }

  /// Handle element rotation operation
  void _handleElementRotate(Offset canvasPosition,
      Offset previousScreenPosition, Offset currentScreenPosition) {
    if (_activeElementId == null)
      return; // Get element center for rotation calculations
    final element = _getElement(_activeElementId!);
    if (element == null) return;

    final x = (element['x'] as num?)?.toDouble() ?? 0.0;
    final y = (element['y'] as num?)?.toDouble() ?? 0.0;
    final width = (element['width'] as num?)?.toDouble() ?? 100.0;
    final height = (element['height'] as num?)?.toDouble() ?? 100.0;

    final elementCenter = Offset(
      x + width / 2,
      y + height / 2,
    );

    // Calculate angles from center to previous and current positions
    final previousVector =
        _interactionSystem.screenToCanvas(previousScreenPosition) -
            elementCenter;
    final currentVector =
        _interactionSystem.screenToCanvas(currentScreenPosition) -
            elementCenter;

    final previousAngle = math.atan2(previousVector.dy, previousVector.dx);
    final currentAngle = math.atan2(currentVector.dy, currentVector.dx);

    // Calculate rotation delta
    final deltaAngle = currentAngle - previousAngle;

    // Notify about the rotation update
    onElementUpdate?.call(_activeElementId!, {
      'deltaRotation': deltaAngle,
      'rotating': true,
    });
  }

  /// Handle multi-touch gestures (pinch, etc.)
  void _handleMultiTouchGesture() {
    // Calculate distances between touch points for pinch
    if (_activePointers.length < 2) return;

    final pointers = _activePointers.values.toList();
    final p1Start = pointers[0].startPosition;
    final p1Current = pointers[0].currentPosition;
    final p2Start = pointers[1].startPosition;
    final p2Current = pointers[1].currentPosition;

    // Calculate start and current distances
    final startDistance = (p1Start - p2Start).distance;
    final currentDistance =
        (p1Current - p2Current).distance; // Calculate scale factor
    final scaleFactor = currentDistance / startDistance;

    // Apply zoom around focal point
    final oldZoom = _interactionSystem.zoomLevel;
    final newZoom = oldZoom * scaleFactor;
    _interactionSystem.setZoom(newZoom);

    onCanvasUpdate?.call();
  }

  /// Perform hit testing to determine what's under a point
  HitTestResult _performHitTest(Offset canvasPosition) {
    // Check for control handles first
    final handleResult = _testHandles(canvasPosition);
    if (handleResult != null) {
      return handleResult;
    }

    // Check for elements
    final element = _getElementAt(canvasPosition);
    if (element != null) {
      return HitTestResult(
        type: HitTestType.element,
        elementId: element['id'] as String,
        position: canvasPosition,
        element: element,
      );
    }

    // Nothing hit, return canvas
    return HitTestResult(
      type: HitTestType.canvas,
      position: canvasPosition,
    );
  }

  /// Show context menu for an element
  void _showElementContextMenu(String elementId, Offset globalPosition) {
    // This would be implemented based on your UI framework
    // For example, showing a popup menu
  }

  /// Test if a point hits any control handles of selected elements
  HitTestResult? _testHandles(Offset position) {
    // If no selection, no handles to test
    if (!_selectionManager.hasSelection) return null;

    // Get selection bounds
    final selectionOutline = _selectionManager.getSelectionOutline();
    if (selectionOutline == null) return null;

    // Handle positions would be calculated based on selection bounds
    final bounds = selectionOutline.bounds;

    // Check corner handles (resize)
    const handleSize = 10.0;

    // Test each handle
    final handles = [
      {'type': 'topLeft', 'pos': bounds.topLeft},
      {'type': 'topRight', 'pos': bounds.topRight},
      {'type': 'bottomLeft', 'pos': bounds.bottomLeft},
      {'type': 'bottomRight', 'pos': bounds.bottomRight},
      {'type': 'top', 'pos': Offset(bounds.center.dx, bounds.top)},
      {'type': 'bottom', 'pos': Offset(bounds.center.dx, bounds.bottom)},
      {'type': 'left', 'pos': Offset(bounds.left, bounds.center.dy)},
      {'type': 'right', 'pos': Offset(bounds.right, bounds.center.dy)},
      {'type': 'rotate', 'pos': Offset(bounds.center.dx, bounds.top - 30)},
    ];

    for (final handle in handles) {
      final handlePosition = handle['pos'] as Offset;
      final handleRect = Rect.fromCenter(
        center: handlePosition,
        width: handleSize,
        height: handleSize,
      );

      if (handleRect.contains(position)) {
        return HitTestResult(
          type: HitTestType.controlHandle,
          elementId: _selectionManager.primarySelectedId,
          handleType: handle['type'] as String,
          position: position,
        );
      }
    }

    return null;
  }

  /// Update hover state based on pointer position
  void _updateHoverState(Offset canvasPosition) {
    final element = _getElementAt(canvasPosition);
    final elementId = element?['id'] as String?;
    _selectionManager.setHover(elementId);
  }
}
