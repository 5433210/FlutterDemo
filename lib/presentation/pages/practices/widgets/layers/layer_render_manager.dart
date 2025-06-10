import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../infrastructure/logging/edit_page_logger_extension.dart';
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
    EditPageLogger.canvasDebug('LayerRenderManager资源释放');
    _isDisposed = true;
    _updateController.close();
    _layerConfigs.clear();
    _layerBuilders.clear();
    _layerMetrics.clear();
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
    EditPageLogger.canvasDebug('请求构建层级', data: {'type': type.toString()});
    
    final config = _layerConfigs[type];
    final builder = _layerBuilders[type];

    if (config == null || builder == null) {
      EditPageLogger.editPageWarning('层级配置或构建器缺失', data: {'type': type.toString()});
      return null;
    }

    if (!config.shouldRender) {
      EditPageLogger.canvasDebug('层级跳过渲染', data: {
        'type': type.toString(),
        'shouldRender': false
      });
      return const SizedBox.shrink();
    }

    EditPageLogger.canvasDebug('调用层级构建器', data: {'type': type.toString()});
    final widget = builder(config);
    EditPageLogger.canvasDebug('层级widget构建完成', data: {
      'type': type.toString(),
      'widgetType': widget.runtimeType.toString()
    });
    
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

    EditPageLogger.canvasDebug('层级标记为脏状态', data: {
      'type': type.toString(),
      'reason': reason ?? 'no reason provided'
    });
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

        EditPageLogger.canvasDebug('自动优化层级性能', data: {
          'layerType': layerType.toString()
        });
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

    EditPageLogger.canvasDebug('注册层级', data: {'type': type.toString()});
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
      EditPageLogger.canvasDebug('更新层级配置', data: {'type': type.toString()});
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
    EditPageLogger.canvasDebug('更新层级性能指标', data: {
      'type': type.toString(),
      'averageRenderTime': '${metrics.averageRenderTime.inMilliseconds}ms',
      'cacheHitRatio': '${(metrics.cacheHitRatio * 100).toStringAsFixed(1)}%'
    });
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

    // 🚀 优化：跳过LayerRenderManager通知机制，避免额外的ContentRenderLayer重建
    // 分层架构的重建应该完全依靠didUpdateWidget和智能状态分发器
    EditPageLogger.canvasDebug(
      'LayerRenderManager跳过通知（优化版）',
      data: {
        'layerType': event.layerType.toString(),
        'updateType': event.updateType.toString(),
        'reason': event.reason,
        'optimization': 'skip_layer_manager_notification',
        'avoidedExtraRebuild': true,
      },
    );

    // _updateController.add(event); // 🚀 已禁用
    // _updateNotifier.value++; // 🚀 已禁用以避免额外重建
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
