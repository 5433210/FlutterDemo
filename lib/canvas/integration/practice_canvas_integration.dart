import 'package:flutter/material.dart';

import '../../presentation/widgets/practice/practice_edit_controller.dart';
import '../core/effects/canvas_effects_system.dart';
import '../core/element/element_creation_system.dart';
import '../core/event/canvas_event_handler_facade.dart';
import '../core/interaction/canvas_interaction_system.dart';
import '../core/selection/selection_manager.dart';

/// Integration adapter that connects the new Canvas systems with the existing
/// PracticeEditController and maintains backward compatibility
class PracticeCanvasIntegration {
  // Canvas systems
  late final CanvasInteractionSystem _interactionSystem;
  late final SelectionManager _selectionManager;
  late final ElementCreationSystem _elementCreationSystem;
  late final CanvasEffectsSystem _effectsSystem;
  late final CanvasEventHandlerFacade _eventHandler;

  // Reference to existing controller
  final PracticeEditController _practiceController;

  // Integration state
  bool _isInitialized = false;
  final Map<String, dynamic> _pendingElementUpdates = {};

  PracticeCanvasIntegration({
    required PracticeEditController practiceController,
  }) : _practiceController = practiceController {
    _initializeSystems();
  }

  /// Get current interaction mode
  CanvasInteractionMode get currentMode => _eventHandler.currentMode;

  /// Set interaction mode
  set currentMode(CanvasInteractionMode mode) {
    _eventHandler.currentMode = mode;
  }

  /// Get effects system for direct access
  CanvasEffectsSystem get effectsSystem => _effectsSystem;

  /// Get element creation system for direct access
  ElementCreationSystem get elementCreationSystem => _elementCreationSystem;

  /// Get event handler for direct access
  CanvasEventHandlerFacade get eventHandler => _eventHandler;

  /// Get interaction system for direct access
  CanvasInteractionSystem get interactionSystem => _interactionSystem;

  /// Get selection manager for direct access
  SelectionManager get selectionManager => _selectionManager;

  /// Get zoom level
  double get zoomLevel => _eventHandler.zoomLevel;

  /// Set zoom level
  set zoomLevel(double zoom) {
    _eventHandler.zoomLevel = zoom;
    _practiceController.state.canvasScale = zoom;
    _practiceController.notifyListeners();
  }

  /// Apply effect to selected elements
  void applyEffectToSelected(
      String effectType, Map<String, dynamic> effectConfig) {
    for (final elementId in _selectionManager.selectedIds) {
      _effectsSystem.applyEffect(elementId, effectType, effectConfig);
    }
    _practiceController.notifyListeners();
  }

  /// Dispose of resources
  void dispose() {
    _selectionManager.dispose();
    _effectsSystem.dispose();
    _pendingElementUpdates.clear();
  }

  /// Enter element creation mode
  void enterElementCreationMode(String elementType) {
    _elementCreationSystem.startCreation(ElementCreationType.values.firstWhere(
      (e) => e.toString().split('.').last == elementType,
      orElse: () => ElementCreationType.text,
    ));
  }

  /// Exit element creation mode
  void exitElementCreationMode() {
    _elementCreationSystem.cancelCreation();
  }

  /// Handle long press
  void handleLongPress(LongPressStartDetails details) {
    _eventHandler.handleLongPress(details);
  }

  /// Handle pan end (for compatibility)
  void handlePanEnd(DragEndDetails details) {
    _eventHandler.handlePanEnd(details);
  }

  /// Handle pan start (for compatibility)
  void handlePanStart(DragStartDetails details) {
    _eventHandler.handlePanStart(details);
  }

  /// Handle pan update (for compatibility)
  void handlePanUpdate(DragUpdateDetails details) {
    _eventHandler.handlePanUpdate(details);
  }

  /// Handle pointer down events
  void handlePointerDown(PointerDownEvent event) {
    _eventHandler.handlePointerDown(event);
  }

  /// Handle pointer move events
  void handlePointerMove(PointerMoveEvent event) {
    _eventHandler.handlePointerMove(event);
  }

  /// Handle pointer up events
  void handlePointerUp(PointerUpEvent event) {
    _eventHandler.handlePointerUp(event);
  }

  /// Handle tap
  void handleTap(TapUpDetails details) {
    // Convert TapUpDetails to appropriate event handler call
    // This functionality needs to be implemented in the event handler
  }

  /// Remove effect from selected elements
  void removeEffectFromSelected(String effectType) {
    for (final elementId in _selectionManager.selectedIds) {
      _effectsSystem.removeEffect(elementId, effectType);
    }
    _practiceController.notifyListeners();
  }

  /// Reset view
  void resetView() {
    // Reset zoom and pan to defaults
    _eventHandler.zoomLevel = 1.0;
    // Reset pan is handled through the interaction system
    _interactionSystem.resetView();
  }

  /// Set canvas size for coordinate transformations
  void setCanvasSize(Size size) {
    _interactionSystem.setCanvasSize(size);
  }

  /// Set canvas viewport for rendering
  void setViewport(Rect viewport) {
    _interactionSystem.setViewport(viewport);
  }

  /// Sync canvas settings from practice controller
  void syncCanvasSettings() {
    // Sync zoom
    final practiceZoom = _practiceController.canvasScale;
    if ((_interactionSystem.zoomLevel - practiceZoom).abs() > 0.001) {
      _interactionSystem.setZoom(practiceZoom);
    }

    // Sync grid and snap settings
    final shouldEnableGrid = _practiceController.state.gridVisible;
    if (_interactionSystem.gridEnabled != shouldEnableGrid) {
      _interactionSystem.toggleGrid();
    }

    final shouldEnableSnap = _practiceController.state.snapEnabled;
    if (_interactionSystem.snapEnabled != shouldEnableSnap) {
      _interactionSystem.toggleSnap();
    }
  }

  /// Sync selection from practice controller
  void syncSelection() {
    final practiceSelection = _practiceController.state.selectedElementIds;
    final canvasSelection = _selectionManager.selectedIds;

    if (!_setsEqual(practiceSelection.toSet(), canvasSelection)) {
      _selectionManager.clearSelection();
      for (final elementId in practiceSelection) {
        _selectionManager.selectElement(elementId, addToSelection: true);
      }
    }
  }

  /// Zoom to fit
  void zoomToFit() {
    const viewportSize =
        Size(800, 600); // Default viewport size, should be passed from UI
    final elements = _getAllElements();
    _eventHandler.zoomToFit(viewportSize, elements);
  }

  /// Create generic property update operation
  void _createPropertyUpdateOperation(
      String elementId, Map<String, dynamic> updates) {
    // For now, use the practice controller's updateElementProperty method
    // This could be enhanced to create more specific operations
    for (final entry in updates.entries) {
      _practiceController.updateElementProperty(
          elementId, entry.key, entry.value);
    }
  }

  /// Create resize operation for undo/redo
  void _createResizeOperation(String elementId, Map<String, dynamic> updates) {
    final element = _getElementById(elementId);
    if (element == null) return;

    final oldSize = <String, dynamic>{};
    final newSize = <String, dynamic>{};

    for (final key in ['x', 'y', 'width', 'height']) {
      if (updates.containsKey(key)) {
        final oldValue =
            (element[key] as num).toDouble() - (updates[key] as num).toDouble();
        oldSize[key] = oldValue;
        newSize[key] = updates[key];
      }
    }

    _practiceController.createElementResizeOperation(
      elementIds: [elementId],
      oldSizes: [oldSize],
      newSizes: [newSize],
    );
  }

  /// Create rotation operation for undo/redo
  void _createRotationOperation(
      String elementId, Map<String, dynamic> updates) {
    final element = _getElementById(elementId);
    if (element == null) return;

    final oldRotation = (element['rotation'] as num).toDouble() -
        (updates['rotation'] as num).toDouble();
    final newRotation = updates['rotation'] as double;

    _practiceController.createElementRotationOperation(
      elementIds: [elementId],
      oldRotations: [oldRotation],
      newRotations: [newRotation],
    );
  }

  /// Create translation operation for undo/redo
  void _createTranslationOperation(
      String elementId, Map<String, dynamic> updates) {
    final element = _getElementById(elementId);
    if (element == null) return;

    final oldX =
        (element['x'] as num).toDouble() - (updates['x'] as num).toDouble();
    final oldY =
        (element['y'] as num).toDouble() - (updates['y'] as num).toDouble();

    _practiceController.createElementTranslationOperation(
      elementIds: [elementId],
      oldPositions: [
        {'x': oldX, 'y': oldY}
      ],
      newPositions: [
        {'x': updates['x'], 'y': updates['y']}
      ],
    );
  }

  /// Get all elements from current page
  List<Map<String, dynamic>> _getAllElements() {
    return _practiceController.state.currentPageElements;
  }

  /// Get element by ID from practice controller
  Map<String, dynamic>? _getElementById(String elementId) {
    final elements = _getAllElements();
    try {
      return elements.firstWhere((e) => e['id'] == elementId);
    } catch (e) {
      return null;
    }
  }

  /// Handle canvas update
  void _handleCanvasUpdate() {
    _practiceController.notifyListeners();
  }

  /// Handle element selection
  void _handleElementSelect(String elementId) {
    if (elementId.isEmpty) {
      _practiceController.clearSelection();
    } else {
      _practiceController.selectElement(elementId);
    }
  }

  /// Handle element update during interaction (real-time updates)
  void _handleElementUpdate(String elementId, Map<String, dynamic> properties) {
    // Store pending updates for batch processing
    if (!_pendingElementUpdates.containsKey(elementId)) {
      _pendingElementUpdates[elementId] = <String, dynamic>{};
    }

    _pendingElementUpdates[elementId]!.addAll(properties);

    // Apply immediate visual updates through the practice controller
    if (_practiceController.state.currentPageIndex >= 0 &&
        _practiceController.state.currentPageIndex <
            _practiceController.state.pages.length) {
      final page = _practiceController
          .state.pages[_practiceController.state.currentPageIndex];
      final elements = page['elements'] as List<dynamic>;
      final elementIndex = elements.indexWhere((e) => e['id'] == elementId);

      if (elementIndex >= 0) {
        final element = elements[elementIndex] as Map<String, dynamic>;

        // Update element properties directly for immediate visual feedback
        properties.forEach((key, value) {
          element[key] = value;
        });

        // Update selected element if it's the one being modified
        if (_practiceController.state.selectedElementIds.contains(elementId)) {
          _practiceController.state.selectedElement = element;
        }

        // Mark as having unsaved changes
        _practiceController.state.hasUnsavedChanges = true;

        // Notify listeners for immediate UI update
        _practiceController.notifyListeners();
      }
    }
  }

  /// Handle element update end (when operation completes)
  void _handleElementUpdateEnd(
      String elementId, Map<String, dynamic> properties) {
    final pendingUpdates = _pendingElementUpdates.remove(elementId);
    if (pendingUpdates == null || pendingUpdates.isEmpty) return;

    // Create appropriate undo/redo operation based on what changed
    final keys = pendingUpdates.keys.toSet();

    if (keys.length == 2 && keys.contains('x') && keys.contains('y')) {
      // This was a translation operation
      _createTranslationOperation(elementId, pendingUpdates);
    } else if (keys.any((k) => ['width', 'height'].contains(k))) {
      // This was a resize operation
      _createResizeOperation(elementId, pendingUpdates);
    } else if (keys.contains('rotation')) {
      // This was a rotation operation
      _createRotationOperation(elementId, pendingUpdates);
    } else {
      // Generic property update
      _createPropertyUpdateOperation(elementId, pendingUpdates);
    }
  }

  /// Handle multi-element selection
  void _handleMultiSelect(List<String> elementIds) {
    _practiceController.selectElements(elementIds);
  }

  /// Initialize all canvas systems
  void _initializeSystems() {
    if (_isInitialized) return; // Initialize selection manager first
    _selectionManager = SelectionManager();

    // Initialize interaction system with selection manager
    _interactionSystem =
        CanvasInteractionSystem(selectionManager: _selectionManager);

    // Initialize element creation system
    _elementCreationSystem = ElementCreationSystem(
      selectionManager: _selectionManager,
      interactionSystem: _interactionSystem,
    );

    // Initialize effects system
    _effectsSystem =
        CanvasEffectsSystem(); // Initialize event handler with integration callbacks
    _eventHandler = CanvasEventHandlerFacade(
      interactionSystem: _interactionSystem,
      selectionManager: _selectionManager,
      elementCreationSystem: _elementCreationSystem,
      effectsSystem: _effectsSystem,
      onElementUpdate: _handleElementUpdate,
      onElementUpdateEnd: _handleElementUpdateEnd,
      onElementSelect: _handleElementSelect,
      onMultiSelect: _handleMultiSelect,
      onCanvasUpdate: _handleCanvasUpdate,
    );

    // Note: Element provider callbacks are now handled through constructor injection
    // into the interaction and selection systems rather than the event handler

    // Sync initial state
    _syncInitialState();

    _isInitialized = true;
  }

  /// Check if two sets are equal
  bool _setsEqual(Set<String> set1, Set<String> set2) {
    if (set1.length != set2.length) return false;
    for (final item in set1) {
      if (!set2.contains(item)) return false;
    }
    return true;
  }

  /// Sync initial state from practice controller
  void _syncInitialState() {
    // Sync selected elements
    final selectedIds = _practiceController.state.selectedElementIds;
    for (final elementId in selectedIds) {
      _selectionManager.selectElement(elementId, addToSelection: true);
    } // Sync canvas settings
    _interactionSystem.setZoom(_practiceController.canvasScale);

    // Sync grid and snap settings based on practice controller state
    final shouldEnableGrid = _practiceController.state.gridVisible;
    if (_interactionSystem.gridEnabled != shouldEnableGrid) {
      _interactionSystem.toggleGrid();
    }

    final shouldEnableSnap = _practiceController.state.snapEnabled;
    if (_interactionSystem.snapEnabled != shouldEnableSnap) {
      _interactionSystem.toggleSnap();
    }
  }
}
