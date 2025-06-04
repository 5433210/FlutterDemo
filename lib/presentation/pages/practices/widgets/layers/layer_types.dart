/// Layer configuration for individual layers
class LayerConfig {
  final RenderLayerType type;
  final LayerVisibility visibility;
  final LayerPriority priority;
  final double opacity;
  final bool enableCaching;
  final bool useRepaintBoundary;
  final Duration maxRenderTime;

  const LayerConfig({
    required this.type,
    this.visibility = LayerVisibility.visible,
    this.priority = LayerPriority.medium,
    this.opacity = 1.0,
    this.enableCaching = true,
    this.useRepaintBoundary = true,
    this.maxRenderTime = const Duration(milliseconds: 16), // 60fps target
  });

  /// Get effective opacity for rendering
  double get effectiveOpacity {
    switch (visibility) {
      case LayerVisibility.visible:
        return opacity;
      case LayerVisibility.dimmed:
        return opacity * 0.5;
      case LayerVisibility.optimized:
        return opacity * 0.8;
      case LayerVisibility.hidden:
        return 0.0;
    }
  }

  /// Check if layer should be rendered based on visibility
  bool get shouldRender =>
      visibility == LayerVisibility.visible ||
      visibility == LayerVisibility.dimmed ||
      visibility == LayerVisibility.optimized;

  LayerConfig copyWith({
    RenderLayerType? type,
    LayerVisibility? visibility,
    LayerPriority? priority,
    double? opacity,
    bool? enableCaching,
    bool? useRepaintBoundary,
    Duration? maxRenderTime,
  }) {
    return LayerConfig(
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      priority: priority ?? this.priority,
      opacity: opacity ?? this.opacity,
      enableCaching: enableCaching ?? this.enableCaching,
      useRepaintBoundary: useRepaintBoundary ?? this.useRepaintBoundary,
      maxRenderTime: maxRenderTime ?? this.maxRenderTime,
    );
  }

  @override
  String toString() {
    return 'LayerConfig(type: $type, visibility: $visibility, priority: $priority, opacity: $opacity)';
  }
}

/// Layer performance metrics
class LayerPerformanceMetrics {
  final RenderLayerType layerType;
  final int frameCount;
  final Duration totalRenderTime;
  final Duration averageRenderTime;
  final Duration maxRenderTime;
  final int cacheHits;
  final int cacheMisses;
  final DateTime lastRenderTime;

  const LayerPerformanceMetrics({
    required this.layerType,
    required this.frameCount,
    required this.totalRenderTime,
    required this.averageRenderTime,
    required this.maxRenderTime,
    required this.cacheHits,
    required this.cacheMisses,
    required this.lastRenderTime,
  });

  /// Calculate cache hit ratio
  double get cacheHitRatio {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }

  /// Check if layer is performing well (under target render time)
  bool get isPerformingWell =>
      averageRenderTime.inMilliseconds <= 8; // Half frame at 60fps

  /// Get performance rating
  String get performanceRating {
    final avgMs = averageRenderTime.inMilliseconds;
    if (avgMs <= 4) return 'Excellent';
    if (avgMs <= 8) return 'Good';
    if (avgMs <= 16) return 'Fair';
    return 'Poor';
  }

  @override
  String toString() {
    return 'LayerPerformanceMetrics('
        'layer: $layerType, '
        'frames: $frameCount, '
        'avgRender: ${averageRenderTime.inMilliseconds}ms, '
        'cacheHitRatio: ${(cacheHitRatio * 100).toStringAsFixed(1)}%, '
        'performance: $performanceRating'
        ')';
  }
}

/// Layer rendering priority for performance optimization
enum LayerPriority {
  /// Critical layers that must maintain 60fps (interaction layer)
  critical,

  /// High priority layers that should maintain good performance (content layer)
  high,

  /// Medium priority layers that can sacrifice some performance if needed (background)
  medium,

  /// Low priority layers that can be heavily optimized (overlay)
  low,
}

/// Layer visibility state
enum LayerVisibility {
  /// Layer is fully visible and actively rendered
  visible,

  /// Layer is hidden and not rendered
  hidden,

  /// Layer is visible but with reduced opacity
  dimmed,

  /// Layer is visible but rendering is optimized for lower quality/performance
  optimized,
}

/// Layer types and definitions for the M3Canvas layered rendering system
enum RenderLayerType {
  /// Static background layer (grid, page borders) - rarely changes
  staticBackground,

  /// Content layer (all elements) - medium update frequency
  content,

  /// Drag preview layer (lightweight element previews during drag) - high update frequency
  dragPreview,

  /// Interaction layer (selection boxes, control points) - very high update frequency
  interaction,

  /// UI overlay layer (toolbars, menus) - medium update frequency
  uiOverlay,
}
