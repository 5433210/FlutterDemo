import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../widgets/practice/performance_monitor.dart';
import 'layer_types.dart';

/// Base class for all canvas rendering layers
abstract class BaseCanvasLayer extends StatefulWidget {
  final LayerConfig config;
  final String layerId;

  const BaseCanvasLayer({
    super.key,
    required this.config,
    required this.layerId,
  });

  @override
  BaseCanvasLayerState createState();
}

/// Base state class for canvas layers with performance tracking
abstract class BaseCanvasLayerState<T extends BaseCanvasLayer>
    extends State<T> {
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();

  /// Performance metrics for this layer
  LayerPerformanceMetrics? _metrics;

  /// Number of frames rendered by this layer
  int _frameCount = 0;

  /// Total render time accumulated
  Duration _totalRenderTime = Duration.zero;

  /// Maximum render time recorded
  Duration _maxRenderTime = Duration.zero;

  /// Cache performance tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;

  /// Last render time for performance monitoring
  DateTime? _lastRenderTime;

  /// Whether this layer needs a repaint
  bool _needsRepaint = false;

  /// Cached widget for performance optimization
  Widget? _cachedWidget;

  /// Performance metrics getter
  LayerPerformanceMetrics? get metrics => _metrics;

  @override
  Widget build(BuildContext context) {
    // Skip rendering if layer is hidden
    if (!widget.config.shouldRender) {
      return const SizedBox.shrink();
    }

    // Use cached widget if available and no repaint needed
    if (!_needsRepaint && _cachedWidget != null) {
      recordCacheHit();
      return _wrapWithOpacity(_cachedWidget!);
    }

    // Record cache miss and measure render time
    recordCacheMiss();
    final renderStart = DateTime.now();

    try {
      // Build layer content
      Widget content = buildLayerContent(context);

      // Apply RepaintBoundary if configured
      if (widget.config.useRepaintBoundary) {
        content = RepaintBoundary(
          key: ValueKey('layer_repaint_${widget.layerId}'),
          child: content,
        );
      }

      // Cache the widget if caching is enabled
      if (widget.config.enableCaching) {
        _cachedWidget = content;
      }

      _needsRepaint = false;

      // Record performance metrics
      final renderTime = DateTime.now().difference(renderStart);
      _recordRenderTime(renderTime);

      return _wrapWithOpacity(content);
    } catch (error, stackTrace) {
      debugPrint('Error rendering layer ${widget.layerId}: $error');
      debugPrint('Stack trace: $stackTrace');

      // Return error placeholder
      return Container(
        color: Colors.red.withOpacity(0.1),
        child: Center(
          child: Text(
            'Layer Error: ${widget.layerId}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
  }

  /// Build the layer content - must be implemented by subclasses
  Widget buildLayerContent(BuildContext context);

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle configuration changes
    if (oldWidget.config != widget.config) {
      onConfigChanged(oldWidget.config, widget.config);

      // Clear cache if layer configuration changed significantly
      if (oldWidget.config.type != widget.config.type ||
          oldWidget.config.enableCaching != widget.config.enableCaching) {
        _cachedWidget = null;
      }

      // Handle visibility changes
      if (oldWidget.config.visibility != widget.config.visibility) {
        onVisibilityChanged(widget.config.visibility);
      }

      markNeedsRepaint();
    }
  }

  @override
  void dispose() {
    _cachedWidget = null;
    super.dispose();
  }

  /// Mark layer as needing repaint
  void markNeedsRepaint() {
    setState(() {
      _needsRepaint = true;
      _cachedWidget = null;
    });
  }

  /// Optional: Handle layer configuration changes
  void onConfigChanged(LayerConfig oldConfig, LayerConfig newConfig) {}

  /// Optional: Handle layer visibility changes
  void onVisibilityChanged(LayerVisibility visibility) {}

  /// Record cache hit for performance tracking
  void recordCacheHit() {
    _cacheHits++;
  }

  /// Record cache miss for performance tracking
  void recordCacheMiss() {
    _cacheMisses++;
  }

  /// Record render time and update performance metrics
  void _recordRenderTime(Duration renderTime) {
    _frameCount++;
    _totalRenderTime += renderTime;
    _lastRenderTime = DateTime.now();

    if (renderTime > _maxRenderTime) {
      _maxRenderTime = renderTime;
    }

    // Update metrics
    final averageRenderTime = Duration(
      microseconds: _totalRenderTime.inMicroseconds ~/ _frameCount,
    );

    _metrics = LayerPerformanceMetrics(
      layerType: widget.config.type,
      frameCount: _frameCount,
      totalRenderTime: _totalRenderTime,
      averageRenderTime: averageRenderTime,
      maxRenderTime: _maxRenderTime,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      lastRenderTime: _lastRenderTime!,
    );

    // Log performance warnings for slow renders
    if (renderTime.inMilliseconds > 16) {
      debugPrint(
          '⚠️ Slow layer render: ${widget.layerId} took ${renderTime.inMilliseconds}ms');
    }

    // Track widget rebuild in performance monitor
    _performanceMonitor.trackWidgetRebuild('Layer_${widget.layerId}');
  }

  /// Wrap content with opacity based on layer configuration
  Widget _wrapWithOpacity(Widget content) {
    final effectiveOpacity = widget.config.effectiveOpacity;

    if (effectiveOpacity < 1.0) {
      return Opacity(
        opacity: effectiveOpacity,
        child: content,
      );
    }

    return content;
  }
}

/// Mixin for layers that respond to user input
mixin InteractiveMixin<T extends BaseCanvasLayer> on BaseCanvasLayerState<T> {
  /// Whether this layer should consume pointer events
  bool get shouldConsumePointerEvents => true;

  /// Build interactive wrapper around layer content
  Widget buildInteractiveWrapper(Widget content) {
    if (!shouldConsumePointerEvents) {
      return content;
    }

    return Listener(
      onPointerDown: onPointerEvent,
      onPointerMove: onPointerEvent,
      onPointerUp: onPointerEvent,
      onPointerCancel: onPointerEvent,
      child: content,
    );
  }

  /// Handle gesture events
  void onGestureEvent(dynamic gestureEvent) {}

  /// Handle pointer events
  void onPointerEvent(PointerEvent event) {}
}

/// Mixin for layers that need periodic updates
mixin PeriodicUpdateMixin<T extends BaseCanvasLayer>
    on BaseCanvasLayerState<T> {
  Timer? _updateTimer;

  @override
  void dispose() {
    stopPeriodicUpdates();
    super.dispose();
  }

  /// Called periodically when updates are enabled
  void onPeriodicUpdate() {
    if (mounted) {
      markNeedsRepaint();
    }
  }

  /// Start periodic updates with the given interval
  void startPeriodicUpdates(Duration interval) {
    stopPeriodicUpdates();
    _updateTimer = Timer.periodic(interval, (_) => onPeriodicUpdate());
  }

  /// Stop periodic updates
  void stopPeriodicUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }
}
