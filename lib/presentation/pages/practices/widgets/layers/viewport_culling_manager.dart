import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Viewport culling manager for optimizing rendering performance
/// by skipping elements that are not visible in the current viewport
class ViewportCullingManager {
  /// Culling buffer to include elements slightly outside viewport
  /// for smooth scrolling/zooming experience
  static const double _cullingBuffer = 50.0;

  /// Current viewport bounds in canvas coordinates
  Rect? _currentViewport;

  /// Performance metrics
  int _totalElements = 0;
  int _visibleElements = 0;

  int _culledElements = 0;

  /// Get current viewport bounds
  Rect? get currentViewport => _currentViewport;

  /// Check if viewport culling is active
  bool get isActive => _currentViewport != null;

  /// Clear viewport (disables culling)
  void clearViewport() {
    _currentViewport = null;
  }

  /// Cull elements that are outside the viewport
  List<Map<String, dynamic>> cullElements(List<Map<String, dynamic>> elements) {
    if (_currentViewport == null) {
      return elements;
    }

    // Reset metrics for this frame
    _resetMetrics();

    final visibleElements = <Map<String, dynamic>>[];

    for (final element in elements) {
      if (isElementVisible(element)) {
        visibleElements.add(element);
      }
    }

    return visibleElements;
  }

  /// Get culling performance metrics
  ViewportCullingMetrics getMetrics() {
    return ViewportCullingMetrics(
      totalElements: _totalElements,
      visibleElements: _visibleElements,
      culledElements: _culledElements,
      cullingRatio: _totalElements > 0 ? _culledElements / _totalElements : 0.0,
      viewport: _currentViewport,
    );
  }

  /// Check if an element is visible in the current viewport
  bool isElementVisible(Map<String, dynamic> element) {
    if (_currentViewport == null) {
      // If viewport not set, assume all elements are visible
      return true;
    }

    // Get element bounds
    final elementRect = _getElementBounds(element);

    // Check intersection with viewport
    final isVisible = _currentViewport!.overlaps(elementRect);

    // Update metrics
    _totalElements++;
    if (isVisible) {
      _visibleElements++;
    } else {
      _culledElements++;
    }

    return isVisible;
  }

  /// Update the viewport based on transformation matrix and canvas size
  void updateViewport({
    required Matrix4 transformMatrix,
    required Size canvasSize,
    required Size contentSize,
  }) {
    // Extract scale and translation from transformation matrix
    final scale = transformMatrix.getMaxScaleOnAxis();
    final translation = transformMatrix.getTranslation();

    // Calculate viewport bounds in content coordinates
    final viewportLeft = (-translation.x) / scale;
    final viewportTop = (-translation.y) / scale;
    final viewportWidth = canvasSize.width / scale;
    final viewportHeight = canvasSize.height / scale;

    // Apply culling buffer
    _currentViewport = Rect.fromLTWH(
      viewportLeft - _cullingBuffer,
      viewportTop - _cullingBuffer,
      viewportWidth + (_cullingBuffer * 2),
      viewportHeight + (_cullingBuffer * 2),
    );
  }

  /// Calculate bounding box for a rotated rectangle
  Rect _calculateRotatedBounds(
      double x, double y, double width, double height, double rotation) {
    // Convert rotation to radians
    final radians = rotation * math.pi / 180;

    // Calculate the four corners of the rectangle
    final corners = [
      [0.0, 0.0], // Top-left
      [width, 0.0], // Top-right
      [width, height], // Bottom-right
      [0.0, height], // Bottom-left
    ];

    // Rotate and translate each corner
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    final cosR = math.cos(radians);
    final sinR = math.sin(radians);

    for (final corner in corners) {
      // Rotate around center
      final centerX = width / 2;
      final centerY = height / 2;
      final localX = corner[0] - centerX;
      final localY = corner[1] - centerY;

      final rotatedX = localX * cosR - localY * sinR;
      final rotatedY = localX * sinR + localY * cosR;

      // Translate to final position
      final finalX = x + centerX + rotatedX;
      final finalY = y + centerY + rotatedY;

      minX = math.min(minX, finalX);
      minY = math.min(minY, finalY);
      maxX = math.max(maxX, finalX);
      maxY = math.max(maxY, finalY);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Get element bounds considering rotation
  Rect _getElementBounds(Map<String, dynamic> element) {
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    if (rotation == 0.0) {
      // Simple case: no rotation
      return Rect.fromLTWH(x, y, width, height);
    }

    // Calculate bounds for rotated element
    return _calculateRotatedBounds(x, y, width, height, rotation);
  }

  /// Reset performance metrics
  void _resetMetrics() {
    _totalElements = 0;
    _visibleElements = 0;
    _culledElements = 0;
  }
}

/// Viewport culling performance metrics
class ViewportCullingMetrics {
  final int totalElements;
  final int visibleElements;
  final int culledElements;
  final double cullingRatio;
  final Rect? viewport;

  const ViewportCullingMetrics({
    required this.totalElements,
    required this.visibleElements,
    required this.culledElements,
    required this.cullingRatio,
    required this.viewport,
  });

  /// Check if culling is effective (> 10% elements culled)
  bool get isEffective => cullingRatio > 0.1;

  /// Get performance improvement percentage
  double get performanceImprovement => cullingRatio * 100;

  /// Generate a performance report
  String get report {
    if (totalElements == 0) {
      return 'No elements processed';
    }

    return '''
Viewport Culling Report:
- Total Elements: $totalElements
- Visible Elements: $visibleElements
- Culled Elements: $culledElements
- Culling Ratio: ${(cullingRatio * 100).toStringAsFixed(1)}%
- Performance Improvement: ${performanceImprovement.toStringAsFixed(1)}%
- Viewport: ${viewport?.toString() ?? 'Not set'}
''';
  }

  @override
  String toString() {
    return 'ViewportCullingMetrics(visible: $visibleElements/$totalElements, culled: ${(cullingRatio * 100).toStringAsFixed(1)}%)';
  }
}
