import 'dart:async';

import 'package:flutter/material.dart';

import 'layer_types.dart';
import 'viewport_culling_manager.dart';

/// Manages all layers in the canvas rendering system
class LayerRenderManager {
  /// Map of layer types to their configurations
  final Map<RenderLayerType, LayerConfig> _layerConfigs = {};

  /// Map of layer types to their widget builders
  final Map<RenderLayerType, Widget Function(LayerConfig)> _layerBuilders = {};

  /// Map of layer types to their performance metrics
  final Map<RenderLayerType, LayerPerformanceMetrics> _layerMetrics = {};

  /// Viewport culling manager for performance optimization
  final ViewportCullingManager _viewportCullingManager =
      ViewportCullingManager();

  /// Stream controller for layer updates
  final StreamController<LayerUpdateEvent> _updateController =
      StreamController<LayerUpdateEvent>.broadcast();

  /// Layer update event notifier
  final ValueNotifier<int> _updateNotifier = ValueNotifier(0);

  /// Whether the layer manager is disposed
  bool _isDisposed = false;

  /// All configured layer types
  Set<RenderLayerType> get layerTypes => _layerConfigs.keys.toSet();

  /// Notifier for layer updates
  ValueNotifier<int> get updateNotifier => _updateNotifier;

  /// Stream of layer update events
  Stream<LayerUpdateEvent> get updateStream => _updateController.stream;

  /// Get viewport culling manager
  ViewportCullingManager get viewportCullingManager => _viewportCullingManager;

  /// Build the complete layer stack
  Widget buildLayerStack({
    List<RenderLayerType>? layerOrder,
    Widget? background,
  }) {
    if (_isDisposed) {
      return const SizedBox.shrink();
    }

    // Use default layer order if not specified
    final order = layerOrder ??
        [
          RenderLayerType.staticBackground,
          RenderLayerType.content,
          RenderLayerType.dragPreview,
          RenderLayerType.interaction,
          RenderLayerType.uiOverlay,
        ];

    final layers = <Widget>[];

    // Add background if provided
    if (background != null) {
      layers.add(background);
    }

    // Add layers in order
    for (final layerType in order) {
      final widget = getLayerWidget(layerType);
      if (widget != null) {
        layers.add(widget);
      }
    }

    if (layers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: layers,
    );
  }

  /// Dim layer (show with reduced opacity)
  void dimLayer(RenderLayerType type) {
    setLayerVisibility(type, LayerVisibility.dimmed);
  }

  /// Dispose the layer manager
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _updateController.close();
    _layerConfigs.clear();
    _layerBuilders.clear();
    _layerMetrics.clear();

    debugPrint('🎨 LayerRenderManager: Disposed');
  }

  /// Get layer configuration
  LayerConfig? getLayerConfig(RenderLayerType type) => _layerConfigs[type];

  /// Get layer performance metrics
  LayerPerformanceMetrics? getLayerMetrics(RenderLayerType type) =>
      _layerMetrics[type];

  /// Get layers with performance issues
  Set<RenderLayerType> getLayersWithIssues() {
    return _layerMetrics.entries
        .where((entry) => !entry.value.isPerformingWell)
        .map((entry) => entry.key)
        .toSet();
  }

  /// Get layer widget
  Widget? getLayerWidget(RenderLayerType type) {
    debugPrint('🎨 LayerRenderManager: 请求构建层级 $type');
    
    final config = _layerConfigs[type];
    final builder = _layerBuilders[type];

    if (config == null || builder == null) {
      debugPrint('⚠️ LayerRenderManager: No config or builder for layer $type');
      return null;
    }

    if (!config.shouldRender) {
      debugPrint('🎨 LayerRenderManager: 层级 $type 不应该渲染 (shouldRender=false)');
      return const SizedBox.shrink();
    }

    debugPrint('🎨 LayerRenderManager: 调用层级 $type 的builder');
    final widget = builder(config);
    debugPrint('🎨 LayerRenderManager: 层级 $type 的widget已构建: ${widget.runtimeType}');
    
    return widget;
  }

  /// Get performance summary for all layers
  Map<RenderLayerType, String> getPerformanceSummary() {
    final summary = <RenderLayerType, String>{};

    for (final entry in _layerMetrics.entries) {
      final metrics = entry.value;
      summary[entry.key] = '${metrics.performanceRating} '
          '(${metrics.averageRenderTime.inMilliseconds}ms avg, '
          '${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}% cache hits)';
    }

    return summary;
  }

  /// Check if any layers are performing poorly
  bool hasPerformanceIssues() {
    return _layerMetrics.values.any((metrics) => !metrics.isPerformingWell);
  }

  /// Hide layer
  void hideLayer(RenderLayerType type) {
    setLayerVisibility(type, LayerVisibility.hidden);
  }

  /// Mark layer as needing update
  void markLayerDirty(RenderLayerType type, {String? reason}) {
    if (_isDisposed) return;

    debugPrint(
        '🎨 LayerRenderManager: Layer $type marked dirty${reason != null ? ' ($reason)' : ''}');
    _notifyLayerUpdate(LayerUpdateEvent.needsRebuild(type, reason));
  }

  /// Mark multiple layers as needing update
  void markLayersDirty(Set<RenderLayerType> types, {String? reason}) {
    for (final type in types) {
      markLayerDirty(type, reason: reason);
    }
  }

  /// Optimize layer performance automatically
  void optimizePerformance() {
    if (_isDisposed) return;

    final problematicLayers = getLayersWithIssues();

    for (final layerType in problematicLayers) {
      final config = _layerConfigs[layerType];
      if (config != null) {
        // Enable optimized rendering for poorly performing layers
        updateLayerConfig(
            layerType,
            config.copyWith(
              visibility: LayerVisibility.optimized,
            ));

        debugPrint('🎨 LayerRenderManager: Auto-optimizing layer $layerType');
      }
    }
  }

  /// Register a layer with its configuration and builder
  void registerLayer({
    required RenderLayerType type,
    required LayerConfig config,
    required Widget Function(LayerConfig) builder,
  }) {
    if (_isDisposed) return;

    _layerConfigs[type] = config;
    _layerBuilders[type] = builder;

    debugPrint('🎨 LayerRenderManager: Registered layer $type');
    _notifyLayerUpdate(LayerUpdateEvent.registered(type, config));
  }

  /// Set layer opacity
  void setLayerOpacity(RenderLayerType type, double opacity) {
    final config = _layerConfigs[type];
    if (config != null && config.opacity != opacity) {
      updateLayerConfig(type, config.copyWith(opacity: opacity));
    }
  }

  /// Set layer visibility
  void setLayerVisibility(RenderLayerType type, LayerVisibility visibility) {
    final config = _layerConfigs[type];
    if (config != null && config.visibility != visibility) {
      updateLayerConfig(type, config.copyWith(visibility: visibility));
    }
  }

  /// Show layer
  void showLayer(RenderLayerType type) {
    setLayerVisibility(type, LayerVisibility.visible);
  }

  /// Update layer configuration
  void updateLayerConfig(RenderLayerType type, LayerConfig newConfig) {
    if (_isDisposed) return;

    final oldConfig = _layerConfigs[type];
    if (oldConfig != null && oldConfig != newConfig) {
      _layerConfigs[type] = newConfig;
      debugPrint('🎨 LayerRenderManager: Updated layer $type config');
      _notifyLayerUpdate(
          LayerUpdateEvent.configChanged(type, oldConfig, newConfig));
    }
  }

  /// Update layer performance metrics
  void updateLayerMetrics(
      RenderLayerType type, LayerPerformanceMetrics metrics) {
    if (_isDisposed) return;

    _layerMetrics[type] = metrics;
    // Note: Performance metrics are stored in _layerMetrics for layer-specific tracking
    debugPrint('🎨 LayerRenderManager: Updated metrics for layer $type - '
        '${metrics.averageRenderTime.inMilliseconds}ms avg, '
        '${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}% cache hits');
  }

  /// Update viewport for culling optimization
  void updateViewport({
    required Matrix4 transformMatrix,
    required Size canvasSize,
    required Size contentSize,
  }) {
    _viewportCullingManager.updateViewport(
      transformMatrix: transformMatrix,
      canvasSize: canvasSize,
      contentSize: contentSize,
    );
  }

  /// Notify listeners of layer updates
  void _notifyLayerUpdate(LayerUpdateEvent event) {
    if (_isDisposed) return;

    _updateController.add(event);
    _updateNotifier.value++;
  }
}

/// Layer update event types
class LayerUpdateEvent {
  final RenderLayerType layerType;
  final LayerUpdateType updateType;
  final LayerConfig? config;
  final LayerConfig? oldConfig;
  final String? reason;
  final DateTime timestamp;

  factory LayerUpdateEvent.configChanged(
    RenderLayerType type,
    LayerConfig oldConfig,
    LayerConfig newConfig,
  ) {
    return LayerUpdateEvent._(
      layerType: type,
      updateType: LayerUpdateType.configChanged,
      config: newConfig,
      oldConfig: oldConfig,
      timestamp: DateTime.now(),
    );
  }

  factory LayerUpdateEvent.needsRebuild(RenderLayerType type, String? reason) {
    return LayerUpdateEvent._(
      layerType: type,
      updateType: LayerUpdateType.needsRebuild,
      reason: reason,
      timestamp: DateTime.now(),
    );
  }

  factory LayerUpdateEvent.registered(
      RenderLayerType type, LayerConfig config) {
    return LayerUpdateEvent._(
      layerType: type,
      updateType: LayerUpdateType.registered,
      config: config,
      timestamp: DateTime.now(),
    );
  }

  const LayerUpdateEvent._({
    required this.layerType,
    required this.updateType,
    this.config,
    this.oldConfig,
    this.reason,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'LayerUpdateEvent(type: $layerType, update: $updateType, reason: $reason)';
  }
}

/// Types of layer updates
enum LayerUpdateType {
  registered,
  configChanged,
  needsRebuild,
}
