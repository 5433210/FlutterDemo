import 'package:flutter/material.dart';

import 'optimized_render_delegate_impl.dart';

/// Facade for the optimized rendering delegation system
/// See optimized_render_delegate_impl.dart for the implementation
class OptimizedRenderDelegate {
  static final OptimizedRenderDelegate _instance =
      OptimizedRenderDelegate._internal();

  final OptimizedRenderDelegateImpl _impl = OptimizedRenderDelegateImpl();

  factory OptimizedRenderDelegate() => _instance;

  OptimizedRenderDelegate._internal();

  /// Clear all caches
  void clearCache() {
    _impl.clearCache();
  }

  /// Get render statistics
  Map<String, dynamic> getRenderStats() {
    return _impl.getRenderStats();
  }

  /// Initialize the render delegate with specialized renderers
  void initialize() {
    _impl.initialize();
  }

  /// Mark an element as dirty (needs re-rendering)
  void markElementDirty(String elementId) {
    _impl.markElementDirty(elementId);
  }

  /// Mark multiple elements as dirty
  void markElementsDirty(List<String> elementIds) {
    _impl.markElementsDirty(elementIds);
  }

  /// Render a single element with optimization
  Future<void> renderElement(
    Canvas canvas,
    Map<String, dynamic> element, {
    bool enableCaching = true,
    bool force = false,
  }) async {
    await _impl.renderElement(canvas, element,
        enableCaching: enableCaching, force: force);
  }

  /// Render a set of elements with culling and optimization
  Future<void> renderElements(
    Canvas canvas,
    List<Map<String, dynamic>> elements, {
    Rect? clipRect,
    double scale = 1.0,
    bool enableCaching = true,
    bool enableCulling = true,
  }) async {
    await _impl.renderElements(canvas, elements,
        clipRect: clipRect,
        scale: scale,
        enableCaching: enableCaching,
        enableCulling: enableCulling);
  }

  /// Set the viewport for culling optimization
  void setViewport(Rect viewport, double scale) {
    _impl.setViewport(viewport, scale);
  }
}

/// Render item for optimization
class RenderItem {
  final Map<String, dynamic> element;
  final int priority;

  const RenderItem({
    required this.element,
    required this.priority,
  });
}

/// Render plan for batch optimization
class RenderPlan {
  final List<RenderItem> items;
  final bool enableCulling;
  final double scale;
  final List<Map<String, dynamic>> visibleElements;
  final List<Map<String, dynamic>> culledElements;
  final Rect? viewport;

  const RenderPlan({
    required this.items,
    required this.visibleElements,
    required this.culledElements,
    this.viewport,
    this.enableCulling = true,
    this.scale = 1.0,
  });
}
