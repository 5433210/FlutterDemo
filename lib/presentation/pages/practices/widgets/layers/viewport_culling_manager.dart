import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Enhanced culling configuration
class CullingConfig {
  final CullingStrategy strategy;
  final double baseBuffer;
  final double zoomMultiplier;
  final int elementCountThreshold;
  final bool enableFastMode;

  const CullingConfig({
    this.strategy = CullingStrategy.adaptive,
    this.baseBuffer = 50.0,
    this.zoomMultiplier = 1.5,
    this.elementCountThreshold = 1000,
    this.enableFastMode = false,
  });
}

/// Culling strategy for different performance scenarios
enum CullingStrategy {
  /// Basic culling with fixed buffer
  basic,

  /// Adaptive culling that adjusts based on zoom level and element count
  adaptive,

  /// Aggressive culling for maximum performance
  aggressive,

  /// Conservative culling for best visual quality
  conservative,
}

/// Viewport culling manager for optimizing rendering performance
/// by skipping elements that are not visible in the current viewport
class ViewportCullingManager {
  /// Base culling buffer to include elements slightly outside viewport
  /// for smooth scrolling/zooming experience
  static const double _baseCullingBuffer = 50.0;

  /// Current viewport bounds in canvas coordinates
  Rect? _currentViewport;

  /// Current zoom level for optimization
  double _currentZoomLevel = 1.0;

  /// Dynamic culling buffer based on zoom level
  double _dynamicCullingBuffer = _baseCullingBuffer;

  /// Performance metrics
  int _totalElements = 0;
  int _visibleElements = 0;
  int _culledElements = 0;

  /// Culling performance settings
  CullingStrategy _strategy = CullingStrategy.adaptive;
  bool _enableZoomOptimization = true;
  bool _enableFastCulling = false;

  /// Get current culling buffer
  double get currentCullingBuffer => _dynamicCullingBuffer;

  /// Get current viewport bounds
  Rect? get currentViewport => _currentViewport;

  /// Get current zoom level
  double get currentZoomLevel => _currentZoomLevel;

  /// Check if viewport culling is active
  bool get isActive => _currentViewport != null;

  /// Clear viewport (disables culling)
  void clearViewport() {
    _currentViewport = null;
    _currentZoomLevel = 1.0;
    _dynamicCullingBuffer = _baseCullingBuffer;
  }

  /// Configure culling strategy
  void configureCulling({
    CullingStrategy? strategy,
    bool? enableZoomOptimization,
    bool? enableFastCulling,
  }) {
    _strategy = strategy ?? _strategy;
    _enableZoomOptimization = enableZoomOptimization ?? _enableZoomOptimization;
    _enableFastCulling = enableFastCulling ?? _enableFastCulling;
  }

  /// Cull elements that are outside the viewport (maintained for backward compatibility)
  List<Map<String, dynamic>> cullElements(List<Map<String, dynamic>> elements) {
    return cullElementsAdvanced(elements);
  }

  /// Enhanced element culling with strategy-based optimization
  List<Map<String, dynamic>> cullElementsAdvanced(
    List<Map<String, dynamic>> elements, {
    bool enableSpatialOptimization = true,
  }) {
    if (_currentViewport == null) {
      return elements;
    }

    // Reset metrics for this frame
    _resetMetrics();

    // Choose culling method based on element count and zoom level
    if (_enableFastCulling && elements.length > 500) {
      return _fastCullElements(elements);
    } else if (enableSpatialOptimization && elements.length > 100) {
      return _spatialCullElements(elements);
    } else {
      return _basicCullElements(elements);
    }
  }

  /// Get culling performance metrics
  ViewportCullingMetrics getMetrics() {
    return ViewportCullingMetrics(
      totalElements: _totalElements,
      visibleElements: _visibleElements,
      culledElements: _culledElements,
      cullingRatio: _totalElements > 0 ? _culledElements / _totalElements : 0.0,
      viewport: _currentViewport,
      zoomLevel: _currentZoomLevel,
      cullingBuffer: _dynamicCullingBuffer,
      strategy: _strategy,
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

    // Update zoom level for optimization
    _currentZoomLevel = scale;
    _updateCullingBuffer();

    // Calculate viewport bounds in content coordinates
    final viewportLeft = (-translation.x) / scale;
    final viewportTop = (-translation.y) / scale;
    final viewportWidth = canvasSize.width / scale;
    final viewportHeight = canvasSize.height / scale;

    // Apply dynamic culling buffer
    _currentViewport = Rect.fromLTWH(
      viewportLeft - _dynamicCullingBuffer,
      viewportTop - _dynamicCullingBuffer,
      viewportWidth + (_dynamicCullingBuffer * 2),
      viewportHeight + (_dynamicCullingBuffer * 2),
    );
  }

  /// Basic culling with full intersection testing
  List<Map<String, dynamic>> _basicCullElements(
      List<Map<String, dynamic>> elements) {
    final visibleElements = <Map<String, dynamic>>[];

    for (final element in elements) {
      if (isElementVisible(element)) {
        visibleElements.add(element);
      }
    }

    return visibleElements;
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

  /// Fast culling for large element sets using bounding box approximation
  List<Map<String, dynamic>> _fastCullElements(
      List<Map<String, dynamic>> elements) {
    final visibleElements = <Map<String, dynamic>>[];
    final viewport = _currentViewport!;

    for (final element in elements) {
      _totalElements++;

      // Quick bounding box check without rotation consideration
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      final elementRect = Rect.fromLTWH(x, y, width, height);

      if (viewport.overlaps(elementRect)) {
        visibleElements.add(element);
        _visibleElements++;
      } else {
        _culledElements++;
      }
    }

    return visibleElements;
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

  /// Spatial culling with grid-based optimization
  List<Map<String, dynamic>> _spatialCullElements(
      List<Map<String, dynamic>> elements) {
    final visibleElements = <Map<String, dynamic>>[];
    final viewport = _currentViewport!;

    // Group elements by spatial grid for faster intersection testing
    final spatialGrid = <String, List<Map<String, dynamic>>>{};
    const gridSize = 200.0; // Grid cell size

    // Distribute elements into spatial grid
    for (final element in elements) {
      final x = (element['x'] as num).toDouble();
      final y = (element['y'] as num).toDouble();
      final gridX = (x / gridSize).floor();
      final gridY = (y / gridSize).floor();
      final gridKey = '${gridX}_$gridY';

      spatialGrid.putIfAbsent(gridKey, () => []).add(element);
    }

    // Only test elements in grid cells that intersect with viewport
    final viewportMinX = (viewport.left / gridSize).floor();
    final viewportMaxX = (viewport.right / gridSize).ceil();
    final viewportMinY = (viewport.top / gridSize).floor();
    final viewportMaxY = (viewport.bottom / gridSize).ceil();

    for (int gridX = viewportMinX; gridX <= viewportMaxX; gridX++) {
      for (int gridY = viewportMinY; gridY <= viewportMaxY; gridY++) {
        final gridKey = '${gridX}_$gridY';
        final cellElements = spatialGrid[gridKey];

        if (cellElements != null) {
          for (final element in cellElements) {
            _totalElements++;
            if (isElementVisible(element)) {
              visibleElements.add(element);
            }
          }
        }
      }
    }

    return visibleElements;
  }

  /// Update culling buffer based on zoom level and strategy
  void _updateCullingBuffer() {
    if (!_enableZoomOptimization) {
      _dynamicCullingBuffer = _baseCullingBuffer;
      return;
    }

    switch (_strategy) {
      case CullingStrategy.basic:
        _dynamicCullingBuffer = _baseCullingBuffer;
        break;

      case CullingStrategy.adaptive:
        // Larger buffer at higher zoom levels for smooth experience
        // Smaller buffer at lower zoom levels for better performance
        if (_currentZoomLevel > 2.0) {
          _dynamicCullingBuffer = _baseCullingBuffer * 2.0;
        } else if (_currentZoomLevel > 1.0) {
          _dynamicCullingBuffer = _baseCullingBuffer * _currentZoomLevel;
        } else {
          // At zoom out, reduce buffer for better performance
          _dynamicCullingBuffer =
              _baseCullingBuffer * math.max(0.5, _currentZoomLevel);
        }
        break;

      case CullingStrategy.aggressive:
        // Minimal buffer for maximum performance
        _dynamicCullingBuffer = _baseCullingBuffer * 0.5;
        break;

      case CullingStrategy.conservative:
        // Large buffer for best visual quality
        _dynamicCullingBuffer = _baseCullingBuffer * 2.0;
        break;
    }
  }
}

/// Viewport culling performance metrics
class ViewportCullingMetrics {
  final int totalElements;
  final int visibleElements;
  final int culledElements;
  final double cullingRatio;
  final Rect? viewport;
  final double zoomLevel;
  final double cullingBuffer;
  final CullingStrategy strategy;

  const ViewportCullingMetrics({
    required this.totalElements,
    required this.visibleElements,
    required this.culledElements,
    required this.cullingRatio,
    required this.viewport,
    this.zoomLevel = 1.0,
    this.cullingBuffer = 50.0,
    this.strategy = CullingStrategy.basic,
  });

  /// Check if culling is effective (> 10% elements culled)
  bool get isEffective => cullingRatio > 0.1;

  /// Check if zoom level optimization is beneficial
  bool get isZoomOptimized => zoomLevel != 1.0 && cullingBuffer != 50.0;

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
- Zoom Level: ${zoomLevel.toStringAsFixed(2)}x
- Culling Buffer: ${cullingBuffer.toStringAsFixed(1)}px
- Strategy: ${strategy.name}
- Viewport: ${viewport?.toString() ?? 'Not set'}
''';
  }

  @override
  String toString() {
    return 'ViewportCullingMetrics(visible: $visibleElements/$totalElements, culled: ${(cullingRatio * 100).toStringAsFixed(1)}%, zoom: ${zoomLevel.toStringAsFixed(2)}x, strategy: ${strategy.name})';
  }
}
