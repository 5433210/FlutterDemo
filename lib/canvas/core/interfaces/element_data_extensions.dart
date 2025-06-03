// filepath: lib/canvas/core/interfaces/element_data_extensions.dart

import 'dart:ui';

import 'element_data.dart';

/// Extensions for working with collections of ElementData
extension ElementDataCollection on Iterable<ElementData> {
  /// Get the bounding rect that contains all elements
  Rect? get combinedBounds {
    if (isEmpty) return null;

    Rect? result;
    for (final element in this) {
      result = result?.expandToInclude(element.bounds) ?? element.bounds;
    }
    return result;
  }

  /// Get interactive elements (visible and unlocked)
  Iterable<ElementData> get interactiveElements {
    return where((element) => element.visible && !element.locked);
  }

  /// Get unlocked elements only
  Iterable<ElementData> get unlockedElements {
    return where((element) => !element.locked);
  }

  /// Get visible elements only
  Iterable<ElementData> get visibleElements {
    return where((element) => element.visible);
  }

  /// Get elements at the given point
  Iterable<ElementData> elementsAtPoint(Offset point) {
    return where((element) => element.containsPoint(point));
  }

  /// Get elements that overlap with the given area
  Iterable<ElementData> elementsInArea(Rect area) {
    return where((element) => element.isWithinArea(area));
  }

  /// Sort elements by z-index (bottom to top)
  List<ElementData> sortedByZIndex() {
    final list = toList();
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  /// Sort elements by z-index (top to bottom)
  List<ElementData> sortedByZIndexDescending() {
    final list = toList();
    list.sort((a, b) => b.zIndex.compareTo(a.zIndex));
    return list;
  }
}

/// Extensions for ElementData to provide convenient access to position and size properties
extension ElementDataGeometry on ElementData {
  /// Bottom edge Y coordinate
  double get bottom => bounds.bottom;

  /// Bottom-left corner
  Offset get bottomLeft => bounds.bottomLeft;

  /// Bottom-right corner
  Offset get bottomRight => bounds.bottomRight;

  /// Center point of the element
  Offset get center => bounds.center;

  /// Height of the element
  double get height => bounds.height;

  /// Right edge X coordinate
  double get right => bounds.right;

  /// Top-left corner
  Offset get topLeft => bounds.topLeft;

  /// Top-right corner
  Offset get topRight => bounds.topRight;

  /// Width of the element
  double get width => bounds.width;

  /// X coordinate (left edge)
  double get x => bounds.left;

  /// Y coordinate (top edge)
  double get y => bounds.top;

  /// Get the minimal bounding rect that contains this element and another
  Rect boundingRectWith(ElementData other) {
    return bounds.expandToInclude(other.bounds);
  }

  /// Check if point is inside element bounds
  bool containsPoint(Offset point) {
    return bounds.contains(point);
  }

  /// Get distance to another element's center
  double distanceTo(ElementData other) {
    return (center - other.center).distance;
  }

  /// Check if element is within a rectangular area
  bool isWithinArea(Rect area) {
    return area.overlaps(bounds);
  }

  /// Check if this element overlaps with another
  bool overlaps(ElementData other) {
    return bounds.overlaps(other.bounds);
  }

  /// Create new ElementData rotated around center
  ElementData rotated(double angle, {Offset? center}) {
    return copyWith(rotation: rotation + angle);
  }

  /// Create new ElementData scaled by factor
  ElementData scaled(double factor, {Offset? center}) {
    final scaleCenter = center ?? bounds.center;
    final scaledWidth = width * factor;
    final scaledHeight = height * factor;
    final newX = scaleCenter.dx - (scaledWidth / 2);
    final newY = scaleCenter.dy - (scaledHeight / 2);

    return copyWith(
      bounds: Rect.fromLTWH(newX, newY, scaledWidth, scaledHeight),
    );
  }

  /// Create new ElementData moved by delta
  ElementData translated(Offset delta) {
    return copyWith(
      bounds: bounds.translate(delta.dx, delta.dy),
    );
  }

  /// Create new ElementData with updated bounds
  ElementData withBounds(Rect newBounds) {
    return copyWith(bounds: newBounds);
  }

  /// Create new ElementData with updated position
  ElementData withPosition(double x, double y) {
    return copyWith(
      bounds: Rect.fromLTWH(x, y, width, height),
    );
  }

  /// Create new ElementData with updated size
  ElementData withSize(double width, double height) {
    return copyWith(
      bounds: Rect.fromLTWH(x, y, width, height),
    );
  }
}
