import 'dart:math';

import 'package:flutter/material.dart';

import '../events/canvas_gesture_event.dart';
import '../interaction/canvas_interaction_system.dart';
import '../selection/selection_manager.dart';

// Using CanvasGestureEvent and CanvasGestureType from events/canvas_gesture_event.dart

/// Element categories for organization
enum ElementCategory {
  text,
  media,
  content,
  graphics,
}

/// Element constraints for validation
class ElementConstraints {
  final double? minWidth;
  final double? minHeight;
  final double? maxWidth;
  final double? maxHeight;
  final bool aspectRatioLocked;
  final double? aspectRatio;

  const ElementConstraints({
    this.minWidth,
    this.minHeight,
    this.maxWidth,
    this.maxHeight,
    this.aspectRatioLocked = false,
    this.aspectRatio,
  });

  bool validateBounds(Rect bounds) {
    if (minWidth != null && bounds.width < minWidth!) return false;
    if (minHeight != null && bounds.height < minHeight!) return false;
    if (maxWidth != null && bounds.width > maxWidth!) return false;
    if (maxHeight != null && bounds.height > maxHeight!) return false;

    if (aspectRatioLocked && aspectRatio != null) {
      final currentRatio = bounds.width / bounds.height;
      const tolerance = 0.1;
      if ((currentRatio - aspectRatio!).abs() > tolerance) return false;
    }

    return true;
  }
}

/// Element creation event listener
abstract class ElementCreationListener {
  void onCreationStateChanged(bool isCreating, ElementCreationType? type);
  void onElementCreated(ElementInstance element);
  void onElementDeleted(ElementInstance element);
  void onElementUpdated(ElementInstance element);
}

/// Element creation modes
enum ElementCreationMode {
  dragToSize, // Drag to define size
  clickToPlace, // Click to place with default size
  fixedSize, // Fixed size, click to place
}

/// Comprehensive element creation and management system for the Canvas
/// Integrates with SelectionManager and CanvasInteractionSystem for unified element handling
class ElementCreationSystem {
  final SelectionManager _selectionManager;
  final CanvasInteractionSystem _interactionSystem;
  final Map<String, ElementDefinition> _elementDefinitions = {};
  final Map<String, ElementInstance> _elementInstances = {};
  final List<ElementCreationListener> _listeners = [];

  // Creation state
  ElementCreationType? _currentCreationType;
  Offset? _creationStartPoint;
  ElementInstance? _previewElement;
  bool _isCreating = false;

  // Element templates and defaults
  final Map<ElementCreationType, ElementTemplate> _templates = {};

  ElementCreationSystem({
    required SelectionManager selectionManager,
    required CanvasInteractionSystem interactionSystem,
  })  : _selectionManager = selectionManager,
        _interactionSystem = interactionSystem {
    _initializeDefaultTemplates();
    _setupInteractionHandlers();
  }

  ElementCreationType? get currentCreationType => _currentCreationType;

  Map<String, ElementDefinition> get elementDefinitions =>
      Map.unmodifiable(_elementDefinitions);

  Map<String, ElementInstance> get elementInstances =>
      Map.unmodifiable(_elementInstances);

  // Getters
  bool get isCreating => _isCreating;

  ElementInstance? get previewElement => _previewElement;

  // Event listeners
  void addListener(ElementCreationListener listener) {
    _listeners.add(listener);
  }

  /// Cancel current element creation
  void cancelCreation() {
    _currentCreationType = null;
    _isCreating = false;
    _creationStartPoint = null;
    _previewElement = null;

    _notifyCreationStateChanged();
  }

  /// Create element at specific position with default size
  ElementInstance? createElementAtPosition(
    ElementCreationType type,
    Offset position, {
    Map<String, dynamic>? properties,
  }) {
    final template = _templates[type];
    if (template == null) return null;

    final elementId = _generateElementId();
    final elementProperties =
        Map<String, dynamic>.from(template.defaultProperties);

    if (properties != null) {
      elementProperties.addAll(properties);
    }

    final element = ElementInstance(
      id: elementId,
      type: type,
      bounds: Rect.fromLTWH(
        position.dx - template.defaultWidth / 2,
        position.dy - template.defaultHeight / 2,
        template.defaultWidth,
        template.defaultHeight,
      ),
      properties: elementProperties,
      isPreview: false,
    );

    _elementInstances[element.id] = element;
    _registerElementDefinition(element);
    _notifyElementCreated(element);

    return element;
  }

  /// Delete element
  bool deleteElement(String elementId) {
    final element = _elementInstances.remove(elementId);
    if (element == null) return false;

    _elementDefinitions.remove(elementId);
    _selectionManager.removeElementBounds(elementId);
    _notifyElementDeleted(element);

    return true;
  }

  /// Dispose resources
  void dispose() {
    _listeners.clear();
    _elementInstances.clear();
    _elementDefinitions.clear();
    _templates.clear();
  }

  /// Duplicate existing element
  ElementInstance? duplicateElement(String elementId, {Offset? offset}) {
    final originalElement = _elementInstances[elementId];
    if (originalElement == null) return null;

    final duplicateId = _generateElementId();
    final duplicateOffset = offset ?? const Offset(20, 20);

    final duplicateElement = ElementInstance(
      id: duplicateId,
      type: originalElement.type,
      bounds: originalElement.bounds
          .translate(duplicateOffset.dx, duplicateOffset.dy),
      properties: Map.from(originalElement.properties),
      isPreview: false,
    );

    _elementInstances[duplicateId] = duplicateElement;
    _registerElementDefinition(duplicateElement);
    _notifyElementCreated(duplicateElement);

    return duplicateElement;
  }

  /// Get element at position (for point selection)
  ElementInstance? getElementAtPosition(Offset position) {
    // Search from top to bottom (reverse Z-order)
    final elements = _elementInstances.values.toList().reversed;

    for (final element in elements) {
      if (element.bounds.contains(position)) {
        return element;
      }
    }

    return null;
  }

  /// Get elements within bounds (for area selection)
  List<ElementInstance> getElementsInBounds(Rect bounds) {
    return _elementInstances.values
        .where((element) => bounds.overlaps(element.bounds))
        .toList();
  }

  void removeListener(ElementCreationListener listener) {
    _listeners.remove(listener);
  }

  /// Start element creation process
  void startCreation(ElementCreationType type, {Offset? position}) {
    _currentCreationType = type;
    _isCreating = true;
    _creationStartPoint = position;

    // Clear current selection when starting creation
    _selectionManager.clearSelection();

    // Create preview element if position is provided
    if (position != null) {
      _createPreviewElement(position);
    }

    _notifyCreationStateChanged();
  }

  /// Update element bounds
  bool updateElementBounds(String elementId, Rect bounds) {
    final element = _elementInstances[elementId];
    if (element == null) return false;

    final updatedElement = element.copyWith(bounds: bounds);
    _elementInstances[elementId] = updatedElement;
    _notifyElementUpdated(updatedElement);

    return true;
  }

  /// Update element properties
  bool updateElementProperties(
      String elementId, Map<String, dynamic> properties) {
    final element = _elementInstances[elementId];
    if (element == null) return false;

    final updatedElement = element.copyWith(properties: {
      ...element.properties,
      ...properties,
    });

    _elementInstances[elementId] = updatedElement;
    _notifyElementUpdated(updatedElement);

    return true;
  }

  /// Calculate bounds for drag-to-size creation
  Rect _calculateDragBounds(Offset start, Offset end) {
    final left = min(start.dx, end.dx);
    final top = min(start.dy, end.dy);
    final right = max(start.dx, end.dx);
    final bottom = max(start.dy, end.dy);

    // Ensure minimum size
    const minSize = 10.0;
    final width = max(right - left, minSize);
    final height = max(bottom - top, minSize);

    return Rect.fromLTWH(left, top, width, height);
  }

  /// Create preview element for visual feedback
  void _createPreviewElement(Offset position) {
    if (_currentCreationType == null) return;

    final template = _templates[_currentCreationType!]!;
    final elementId = _generateElementId();

    _previewElement = ElementInstance(
      id: elementId,
      type: _currentCreationType!,
      bounds: Rect.fromLTWH(
        position.dx,
        position.dy,
        template.defaultWidth,
        template.defaultHeight,
      ),
      properties: Map.from(template.defaultProperties),
      isPreview: true,
    );
  }

  /// Finalize element creation and add to canvas
  ElementInstance? _finalizeElementCreation(Offset position) {
    if (_previewElement == null || _currentCreationType == null) return null;

    // Validate element bounds
    if (_previewElement!.bounds.width < 5 ||
        _previewElement!.bounds.height < 5) {
      return null; // Too small to be useful
    }

    // Create final element instance
    final element = _previewElement!.copyWith(isPreview: false);

    // Add to element instances
    _elementInstances[element.id] = element;

    // Register element definition if not exists
    _registerElementDefinition(element);

    return element;
  }

  /// Generate unique element ID
  String _generateElementId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'element_${timestamp}_$random';
  }

  /// Get element category for organization
  ElementCategory _getElementCategory(ElementCreationType type) {
    switch (type) {
      case ElementCreationType.text:
        return ElementCategory.text;
      case ElementCreationType.image:
        return ElementCategory.media;
      case ElementCreationType.collection:
        return ElementCategory.content;
      case ElementCreationType.shape:
        return ElementCategory.graphics;
    }
  }

  /// Get element constraints for validation
  ElementConstraints _getElementConstraints(ElementCreationType type) {
    switch (type) {
      case ElementCreationType.text:
        return const ElementConstraints(
          minWidth: 20.0,
          minHeight: 10.0,
          maxWidth: 1000.0,
          maxHeight: 500.0,
          aspectRatioLocked: false,
        );
      case ElementCreationType.image:
        return const ElementConstraints(
          minWidth: 10.0,
          minHeight: 10.0,
          maxWidth: 2000.0,
          maxHeight: 2000.0,
          aspectRatioLocked: true,
        );
      case ElementCreationType.collection:
        return const ElementConstraints(
          minWidth: 50.0,
          minHeight: 50.0,
          maxWidth: 500.0,
          maxHeight: 500.0,
          aspectRatioLocked: true,
        );
      case ElementCreationType.shape:
        return const ElementConstraints(
          minWidth: 10.0,
          minHeight: 10.0,
          maxWidth: 1000.0,
          maxHeight: 1000.0,
          aspectRatioLocked: false,
        );
    }
  }

  /// Get display name for element type
  String _getElementDisplayName(ElementCreationType type) {
    switch (type) {
      case ElementCreationType.text:
        return 'Text';
      case ElementCreationType.image:
        return 'Image';
      case ElementCreationType.collection:
        return 'Collection';
      case ElementCreationType.shape:
        return 'Shape';
    }
  }

  /// Handle canvas interaction events for element creation
  bool _handleCanvasInteraction(CanvasGestureEvent event) {
    if (!_isCreating || _currentCreationType == null) return false;

    switch (event.type) {
      case CanvasGestureType.tapDown:
        return _handleCreationStart(event.position);
      case CanvasGestureType.panUpdate:
        return _handleCreationUpdate(event.position);
      case CanvasGestureType.tapUp:
      case CanvasGestureType.panEnd:
        return _handleCreationEnd(event.position);
      default:
        return false;
    }
  }

  /// Handle creation end (mouse up / touch end)
  bool _handleCreationEnd(Offset position) {
    if (_previewElement == null || _creationStartPoint == null)
      return false; // Finalize element creation
    final element = _finalizeElementCreation(position);
    if (element != null) {
      // Select the newly created element
      _selectionManager.selectElement(element.id);
      _notifyElementCreated(element);
    }

    // Reset creation state
    _previewElement = null;
    _creationStartPoint = null;

    return true;
  }

  /// Handle creation start (mouse down / touch start)
  bool _handleCreationStart(Offset position) {
    if (_currentCreationType == null) return false;

    _creationStartPoint = position;
    _createPreviewElement(position);
    return true;
  }

  /// Handle creation update (drag)
  bool _handleCreationUpdate(Offset position) {
    if (_previewElement == null || _creationStartPoint == null) return false;

    _updatePreviewElement(position);
    return true;
  }

  /// Initialize default element templates
  void _initializeDefaultTemplates() {
    // Text element template
    _templates[ElementCreationType.text] = const ElementTemplate(
      type: ElementCreationType.text,
      defaultWidth: 120.0,
      defaultHeight: 40.0,
      defaultProperties: {
        'text': 'New Text',
        'fontSize': 16.0,
        'fontFamily': 'Arial',
        'color': Colors.black,
        'fontWeight': FontWeight.normal,
        'fontStyle': FontStyle.normal,
        'alignment': TextAlign.left,
      },
    );

    // Image element template
    _templates[ElementCreationType.image] = const ElementTemplate(
      type: ElementCreationType.image,
      defaultWidth: 200.0,
      defaultHeight: 150.0,
      defaultProperties: {
        'imagePath': '',
        'fit': BoxFit.cover,
        'opacity': 1.0,
        'borderRadius': 0.0,
      },
    );

    // Collection element template
    _templates[ElementCreationType.collection] = const ElementTemplate(
      type: ElementCreationType.collection,
      defaultWidth: 100.0,
      defaultHeight: 100.0,
      defaultProperties: {
        'collectionId': '',
        'characterId': '',
        'style': 'default',
        'color': Colors.black,
      },
    );

    // Shape element template
    _templates[ElementCreationType.shape] = const ElementTemplate(
      type: ElementCreationType.shape,
      defaultWidth: 100.0,
      defaultHeight: 100.0,
      defaultProperties: {
        'shapeType': ShapeType.rectangle,
        'fillColor': Colors.blue,
        'strokeColor': Colors.black,
        'strokeWidth': 2.0,
        'borderRadius': 0.0,
      },
    );
  }

  void _notifyCreationStateChanged() {
    for (final listener in _listeners) {
      listener.onCreationStateChanged(_isCreating, _currentCreationType);
    }
  }

  void _notifyElementCreated(ElementInstance element) {
    for (final listener in _listeners) {
      listener.onElementCreated(element);
    }
  }

  void _notifyElementDeleted(ElementInstance element) {
    for (final listener in _listeners) {
      listener.onElementDeleted(element);
    }
  }

  void _notifyElementUpdated(ElementInstance element) {
    for (final listener in _listeners) {
      listener.onElementUpdated(element);
    }
  }

  /// Register element definition for type management
  void _registerElementDefinition(ElementInstance element) {
    if (_elementDefinitions.containsKey(element.id)) return;

    _elementDefinitions[element.id] = ElementDefinition(
      id: element.id,
      type: element.type,
      category: _getElementCategory(element.type),
      displayName: _getElementDisplayName(element.type),
      properties: element.properties,
      constraints: _getElementConstraints(element.type),
    );
  }

  /// Setup interaction handlers for element creation
  void _setupInteractionHandlers() {
    _interactionSystem.addGestureHandler(_handleCanvasInteraction);
  }

  /// Update preview element during creation
  void _updatePreviewElement(Offset currentPosition) {
    if (_previewElement == null || _creationStartPoint == null) return;

    final startPoint = _creationStartPoint!;
    final template = _templates[_currentCreationType!]!;

    // Calculate bounds based on creation mode
    Rect newBounds;
    switch (template.creationMode) {
      case ElementCreationMode.dragToSize:
        newBounds = _calculateDragBounds(startPoint, currentPosition);
        break;
      case ElementCreationMode.clickToPlace:
        newBounds = Rect.fromLTWH(
          currentPosition.dx - template.defaultWidth / 2,
          currentPosition.dy - template.defaultHeight / 2,
          template.defaultWidth,
          template.defaultHeight,
        );
        break;
      case ElementCreationMode.fixedSize:
        newBounds = Rect.fromLTWH(
          startPoint.dx,
          startPoint.dy,
          template.defaultWidth,
          template.defaultHeight,
        );
        break;
    }

    _previewElement = _previewElement!.copyWith(bounds: newBounds);
  }
}

/// Element creation types
enum ElementCreationType {
  text,
  image,
  collection,
  shape,
}

/// Element definition for type management
class ElementDefinition {
  final String id;
  final ElementCreationType type;
  final ElementCategory category;
  final String displayName;
  final Map<String, dynamic> properties;
  final ElementConstraints constraints;

  const ElementDefinition({
    required this.id,
    required this.type,
    required this.category,
    required this.displayName,
    required this.properties,
    required this.constraints,
  });
}

/// Element instance representation
class ElementInstance {
  final String id;
  final ElementCreationType type;
  final Rect bounds;
  final Map<String, dynamic> properties;
  final bool isPreview;
  final DateTime createdAt;
  final DateTime updatedAt;

  ElementInstance({
    required this.id,
    required this.type,
    required this.bounds,
    required this.properties,
    this.isPreview = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ElementInstance && other.id == id;
  }

  ElementInstance copyWith({
    String? id,
    ElementCreationType? type,
    Rect? bounds,
    Map<String, dynamic>? properties,
    bool? isPreview,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ElementInstance(
      id: id ?? this.id,
      type: type ?? this.type,
      bounds: bounds ?? this.bounds,
      properties: properties ?? this.properties,
      isPreview: isPreview ?? this.isPreview,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Element template definition
class ElementTemplate {
  final ElementCreationType type;
  final double defaultWidth;
  final double defaultHeight;
  final Map<String, dynamic> defaultProperties;
  final ElementCreationMode creationMode;

  const ElementTemplate({
    required this.type,
    required this.defaultWidth,
    required this.defaultHeight,
    required this.defaultProperties,
    this.creationMode = ElementCreationMode.dragToSize,
  });
}

/// Shape types for shape elements
enum ShapeType {
  rectangle,
  circle,
  triangle,
  line,
  arrow,
}
