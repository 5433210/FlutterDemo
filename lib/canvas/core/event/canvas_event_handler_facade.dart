import 'package:flutter/material.dart';

import '../effects/canvas_effects_system.dart';
import '../element/element_creation_system.dart';
import '../interaction/canvas_interaction_system.dart';
import '../selection/selection_manager.dart';
import 'canvas_event_handler.dart';
import 'canvas_event_handler_impl.dart';

/// Facade for canvas event handling that delegates to the implementation
class CanvasEventHandlerFacade extends CanvasEventHandler {
  late final CanvasEventHandlerImpl _impl;

  CanvasEventHandlerFacade({
    required CanvasInteractionSystem interactionSystem,
    required SelectionManager selectionManager,
    required ElementCreationSystem elementCreationSystem,
    required CanvasEffectsSystem effectsSystem,
    Function(String elementId, Map<String, dynamic> properties)?
        onElementUpdate,
    Function(String elementId, Map<String, dynamic> properties)?
        onElementUpdateEnd,
    Function(String elementId)? onElementSelect,
    Function(List<String> elementIds)? onMultiSelect,
    Function()? onCanvasUpdate,
  }) {
    _impl = CanvasEventHandlerImpl(
      interactionSystem: interactionSystem,
      selectionManager: selectionManager,
      elementCreationSystem: elementCreationSystem,
      effectsSystem: effectsSystem,
      onElementUpdate: onElementUpdate,
      onElementUpdateEnd: onElementUpdateEnd,
      onElementSelect: onElementSelect,
      onMultiSelect: onMultiSelect,
      onCanvasUpdate: onCanvasUpdate,
    );
  }

  @override
  CanvasInteractionMode get currentMode => _impl.currentMode;

  @override
  set currentMode(CanvasInteractionMode mode) => _impl.currentMode = mode;

  @override
  Offset get panOffset => _impl.panOffset;

  @override
  double get zoomLevel => _impl.zoomLevel;

  @override
  set zoomLevel(double zoom) => _impl.zoomLevel = zoom;

  @override
  void handleLongPress(LongPressStartDetails details) =>
      _impl.handleLongPress(details);

  @override
  void handlePanEnd(DragEndDetails details) => _impl.handlePanEnd(details);

  @override
  void handlePanStart(DragStartDetails details) =>
      _impl.handlePanStart(details);

  @override
  void handlePanUpdate(DragUpdateDetails details) =>
      _impl.handlePanUpdate(details);

  @override
  void handlePointerDown(PointerDownEvent event) =>
      _impl.handlePointerDown(event);

  @override
  void handlePointerMove(PointerMoveEvent event) =>
      _impl.handlePointerMove(event);

  @override
  void handlePointerUp(PointerUpEvent event) => _impl.handlePointerUp(event);

  @override
  void handleScaleEnd(ScaleEndDetails details) => _impl.handleScaleEnd(details);

  @override
  void handleScaleStart(ScaleStartDetails details) =>
      _impl.handleScaleStart(details);

  @override
  void handleScaleUpdate(ScaleUpdateDetails details) =>
      _impl.handleScaleUpdate(details);

  @override
  void zoomIn({Offset? focalPoint}) => _impl.zoomIn(focalPoint: focalPoint);

  @override
  void zoomOut({Offset? focalPoint}) => _impl.zoomOut(focalPoint: focalPoint);

  @override
  void zoomToFit(Size viewportSize, List<Map<String, dynamic>> elements) =>
      _impl.zoomToFit(viewportSize, elements);
}
