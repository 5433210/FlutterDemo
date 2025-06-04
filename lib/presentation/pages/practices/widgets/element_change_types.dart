/// Class for tracking specific element changes
class ElementChangeInfo {
  final String elementId;
  final ElementChangeType changeType;
  final Map<String, dynamic> oldProperties;
  final Map<String, dynamic> newProperties;
  final DateTime timestamp;

  const ElementChangeInfo({
    required this.elementId,
    required this.changeType,
    required this.oldProperties,
    required this.newProperties,
    required this.timestamp,
  });

  /// Create an ElementChangeInfo by analyzing differences
  factory ElementChangeInfo.fromChanges({
    required String elementId,
    required Map<String, dynamic> oldProperties,
    required Map<String, dynamic> newProperties,
  }) {
    return ElementChangeInfo(
      elementId: elementId,
      changeType: analyzeChangeType(oldProperties, newProperties),
      oldProperties: Map.from(oldProperties),
      newProperties: Map.from(newProperties),
      timestamp: DateTime.now(),
    );
  }

  /// Check if this change affects rendering bounds
  bool get affectsRenderBounds {
    return changeType == ElementChangeType.sizeOnly ||
        changeType == ElementChangeType.positionOnly ||
        changeType == ElementChangeType.sizeAndPosition ||
        changeType == ElementChangeType.rotation ||
        changeType == ElementChangeType.created ||
        changeType == ElementChangeType.deleted ||
        changeType == ElementChangeType.visibility;
  }

  /// Check if this change only affects content within existing bounds
  bool get isContentOnlyChange {
    return changeType == ElementChangeType.contentOnly ||
        changeType == ElementChangeType.opacity;
  }

  @override
  String toString() {
    return 'ElementChangeInfo(elementId: $elementId, changeType: $changeType, '
        'timestamp: $timestamp)';
  }

  /// Analyze the change type based on property differences
  static ElementChangeType analyzeChangeType(
    Map<String, dynamic> oldProps,
    Map<String, dynamic> newProps,
  ) {
    final changedKeys = <String>{};

    // Find all changed keys
    for (final key in newProps.keys) {
      if (oldProps[key] != newProps[key]) {
        changedKeys.add(key);
      }
    }

    // Check for deleted keys
    for (final key in oldProps.keys) {
      if (!newProps.containsKey(key)) {
        changedKeys.add(key);
      }
    }

    if (changedKeys.isEmpty) {
      return ElementChangeType.contentOnly; // Default fallback
    }

    // Categorize changes
    final positionKeys = {'x', 'y'};
    final sizeKeys = {'width', 'height'};
    final transformKeys = {'rotation'};
    final visibilityKeys = {'hidden'};
    final opacityKeys = {'opacity'};

    final hasPositionChange = changedKeys.any(positionKeys.contains);
    final hasSizeChange = changedKeys.any(sizeKeys.contains);
    final hasTransformChange = changedKeys.any(transformKeys.contains);
    final hasVisibilityChange = changedKeys.any(visibilityKeys.contains);
    final hasOpacityChange = changedKeys.any(opacityKeys.contains);

    // Determine change type based on what changed
    if (hasVisibilityChange) {
      return ElementChangeType.visibility;
    }

    if (hasOpacityChange && changedKeys.length == 1) {
      return ElementChangeType.opacity;
    }

    if (hasTransformChange && changedKeys.length == 1) {
      return ElementChangeType.rotation;
    }

    if (hasPositionChange && hasSizeChange) {
      return ElementChangeType.sizeAndPosition;
    }

    if (hasPositionChange && changedKeys.length <= 2) {
      return ElementChangeType.positionOnly;
    }

    if (hasSizeChange && changedKeys.length <= 2) {
      return ElementChangeType.sizeOnly;
    }

    if (changedKeys.length > 2 ||
        (hasPositionChange || hasSizeChange || hasTransformChange)) {
      return ElementChangeType.multiple;
    }

    return ElementChangeType.contentOnly;
  }
}

/// Element change detection and management types for dual-layer architecture

/// Enum defining different types of element changes
enum ElementChangeType {
  /// Only content properties changed (text, color, etc.)
  contentOnly,

  /// Only size changed (width, height)
  sizeOnly,

  /// Only position changed (x, y)
  positionOnly,

  /// Both size and position changed
  sizeAndPosition,

  /// Element was newly created
  created,

  /// Element was deleted
  deleted,

  /// Element visibility changed (hidden/shown)
  visibility,

  /// Element opacity changed
  opacity,

  /// Element rotation changed
  rotation,

  /// Multiple properties changed
  multiple,
}
