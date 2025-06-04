import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/practice/element_cache_manager.dart';
import '../../../widgets/practice/element_renderers.dart';
import '../../../widgets/practice/performance_monitor.dart';
import 'content_render_controller.dart';
import 'element_change_types.dart';
import 'layers/viewport_culling_manager.dart';

/// Content rendering layer widget for isolated content rendering
class ContentRenderLayer extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> elements;
  final List<Map<String, dynamic>> layers;
  final ContentRenderController renderController;
  final bool isPreviewMode;
  final Size pageSize;
  final Color backgroundColor;
  final Set<String> selectedElementIds;
  final ViewportCullingManager? viewportCullingManager;

  const ContentRenderLayer({
    super.key,
    required this.elements,
    required this.layers,
    required this.renderController,
    required this.isPreviewMode,
    required this.pageSize,
    required this.backgroundColor,
    required this.selectedElementIds,
    this.viewportCullingManager,
  });

  @override
  ConsumerState<ContentRenderLayer> createState() => _ContentRenderLayerState();
}

class _ContentRenderLayerState extends ConsumerState<ContentRenderLayer> {
  /// Advanced element cache manager
  late ElementCacheManager _cacheManager;

  /// Performance monitor for tracking render performance
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  @override
  Widget build(BuildContext context) {
    // Track performance for ContentRenderLayer rebuilds
    _performanceMonitor.trackWidgetRebuild('ContentRenderLayer');

    print('🎨 ContentRenderLayer: build() called');
    print(
        '🎨 ContentRenderLayer: Elements to render: ${widget.elements.length}');
    print(
        '🎨 ContentRenderLayer: Selected elements: ${widget.selectedElementIds.length}');
    print(
        '🎨 ContentRenderLayer: Cache metrics: ${_cacheManager.metrics.getReport()}');

    // Sort elements by layer order
    final sortedElements = _sortElementsByLayer(widget.elements, widget.layers);

    // Apply viewport culling if available
    final visibleElements = widget.viewportCullingManager != null
        ? widget.viewportCullingManager!.cullElements(sortedElements)
        : sortedElements;

    // Log culling metrics
    if (widget.viewportCullingManager != null) {
      final cullingMetrics = widget.viewportCullingManager!.getMetrics();
      print('🎯 Viewport Culling: $cullingMetrics');
    }

    // Trigger cache cleanup for efficient memory management
    _cacheManager.cleanupCache();
    return RepaintBoundary(
      child: Container(
        width: widget.pageSize.width,
        height: widget.pageSize.height,
        color: widget.backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: visibleElements.map((element) {
            // Skip hidden elements in preview mode
            final isHidden = element['hidden'] == true;
            if (isHidden && widget.isPreviewMode) {
              return const SizedBox.shrink();
            }

            // Skip elements on hidden layers
            final layerId = element['layerId'] as String?;
            if (layerId != null && _isLayerHidden(layerId)) {
              return const SizedBox.shrink();
            }

            // Get element properties
            final elementX = (element['x'] as num).toDouble();
            final elementY = (element['y'] as num).toDouble();
            final elementWidth = (element['width'] as num).toDouble();
            final elementHeight = (element['height'] as num).toDouble();
            final elementRotation =
                (element['rotation'] as num?)?.toDouble() ?? 0.0;
            final elementOpacity =
                (element['opacity'] as num?)?.toDouble() ?? 1.0;
            final elementId = element['id'] as String;

            // Skip rendering elements that are being drawn by the drag preview layer
            if (widget.renderController.shouldSkipElementRendering(elementId)) {
              return const SizedBox.shrink();
            }

            return Positioned(
              left: elementX,
              top: elementY,
              child: RepaintBoundary(
                key: ValueKey('element_repaint_$elementId'),
                child: Transform.rotate(
                  angle: elementRotation * 3.14159265359 / 180,
                  child: Opacity(
                    opacity: isHidden && !widget.isPreviewMode
                        ? 0.5
                        : elementOpacity,
                    child: SizedBox(
                      width: elementWidth,
                      height: elementHeight,
                      child: _getOrCreateElementWidget(element),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(ContentRenderLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for element additions/removals/modifications
    _updateElementsCache(oldWidget.elements, widget.elements);
  }

  @override
  void dispose() {
    // Perform cleanup
    _cacheManager.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Initialize advanced cache manager with appropriate strategy
    _cacheManager = ElementCacheManager(
      strategy: CacheStrategy.priorityBased,
      // For higher performance, increase cache size but monitor memory usage
      maxSize: 500,
      // 50MB memory threshold - adjust based on target devices
      memoryThreshold: 50 * 1024 * 1024,
    );

    // Initialize selective rebuilding system
    widget.renderController.initializeSelectiveRebuilding(_cacheManager);

    // Initialize controller with current elements
    widget.renderController.initializeElements(widget.elements);

    // Listen to changes via stream only (more efficient than broad listener)
    widget.renderController.changeStream.listen(_handleElementChange);

    // Warm up the cache with visible elements
    _warmupCache(widget.elements);
  }

  /// Estimate memory size of an element in bytes
  int _estimateElementSize(Map<String, dynamic> element) {
    final elementType = element['type'] as String;
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    // Base size for element metadata (properties, etc.)
    int baseSize = 1024; // ~1KB for element properties

    switch (elementType) {
      case 'text':
        // Text elements are relatively small
        final text = element['text'] as String?;
        final textLength = text?.length ?? 0;
        // Estimate: base + text length + some overhead for text styling
        return baseSize + textLength * 2 + 512;

      case 'image':
        // Images are much larger in memory
        // Conservative estimate based on dimensions
        // Assuming 4 bytes per pixel (RGBA)
        final pixelCount = width * height;
        return baseSize + (pixelCount * 4).toInt();

      case 'collection':
        // Collections can be complex and have nested elements
        // This is a rough estimate
        return baseSize + (width * height * 0.5).toInt();

      case 'group':
        // Groups contain other elements, but we're not counting children here
        // Just accounting for the group container overhead
        return baseSize + 2048;

      default:
        return baseSize;
    }
  }

  /// Get or create cached widget for an element using the advanced cache manager
  Widget _getOrCreateElementWidget(Map<String, dynamic> element) {
    final elementId = element['id'] as String;
    final elementType = element['type'] as String;

    // Check if element should be rebuilt using selective rebuilding
    final shouldRebuild =
        widget.renderController.shouldRebuildElement(elementId);

    // Try to get the element from cache first (if rebuild not needed)
    if (!shouldRebuild) {
      final cachedWidget =
          _cacheManager.getElementWidget(elementId, elementType);
      if (cachedWidget != null) {
        // Mark rebuild manager that we skipped rebuild
        widget.renderController.rebuildManager
            ?.skipElementRebuild(elementId, 'Cache hit and not dirty');
        return cachedWidget;
      }
    }

    // Mark that we're starting rebuild
    widget.renderController.rebuildManager?.startElementRebuild(elementId);

    // Create a new widget
    final renderStartTime = DateTime.now();
    final newWidget = _renderElement(element);
    final renderDuration = DateTime.now().difference(renderStartTime);

    // Calculate element size for memory tracking
    final estimatedSize = _estimateElementSize(element);

    // Cache priority based on element type and visibility
    CachePriority priority = CachePriority.medium;

    // Prioritize elements by type and visibility
    if (widget.selectedElementIds.contains(elementId)) {
      // Selected elements get higher priority
      priority = CachePriority.high;
    } else if (elementType == 'image') {
      // Images are expensive to render, keep them cached
      priority = CachePriority.high;
    }

    // Store in cache with size information and priority
    _cacheManager.storeElementWidget(
      elementId,
      newWidget,
      Map<String, dynamic>.from(element),
      estimatedSize: estimatedSize,
      priority: priority,
      elementType: elementType,
    );

    // Complete rebuild tracking
    widget.renderController.rebuildManager
        ?.completeElementRebuild(elementId, newWidget);

    // Log performance data for complex elements
    if (renderDuration.inMilliseconds > 8) {
      // Half a frame at 60fps
      print(
          '⚠️ ContentRenderLayer: Slow element render - $elementId ($elementType) took ${renderDuration.inMilliseconds}ms');
    }

    return newWidget;
  }

  /// Handle specific element changes
  void _handleElementChange(ElementChangeInfo changeInfo) {
    debugPrint(
        'ContentRenderLayer: Handling element change - ${changeInfo.changeType} for ${changeInfo.elementId}');

    switch (changeInfo.changeType) {
      case ElementChangeType.contentOnly:
      case ElementChangeType.opacity:
        // Only update the specific element widget
        _cacheManager.markElementForUpdate(changeInfo.elementId);
        break;

      case ElementChangeType.sizeOnly:
      case ElementChangeType.positionOnly:
      case ElementChangeType.sizeAndPosition:
      case ElementChangeType.rotation:
        // Update element and potentially affect layout
        _cacheManager.markElementForUpdate(changeInfo.elementId);
        break;

      case ElementChangeType.visibility:
      case ElementChangeType.created:
      case ElementChangeType.deleted:
        // Full update needed
        _cacheManager.markAllElementsForUpdate(widget.elements);
        break;

      case ElementChangeType.multiple:
        // Conservative approach - update everything
        _cacheManager.markAllElementsForUpdate(widget.elements);
        break;
    }

    // Request rebuild to reflect changes
    setState(() {});
  }

  /// Check if a layer is hidden
  bool _isLayerHidden(String layerId) {
    final layer = widget.layers.firstWhere(
      (l) => l['id'] == layerId,
      orElse: () => <String, dynamic>{},
    );
    return layer.isNotEmpty && layer['isVisible'] == false;
  }

  /// Deep comparison of two maps
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key)) return false;

      final value1 = map1[key];
      final value2 = map2[key];

      if (value1 is Map && value2 is Map) {
        if (!_mapsEqual(
            value1.cast<String, dynamic>(), value2.cast<String, dynamic>())) {
          return false;
        }
      } else if (value1 != value2) {
        return false;
      }
    }

    return true;
  }

  /// Render a single element
  Widget _renderElement(Map<String, dynamic> element) {
    final type = element['type'] as String;
    final elementId = element['id'] as String?;

    // Create a copy of the element to avoid modifying the original data
    final elementCopy = Map<String, dynamic>.from(element);

    // Handle preview position for elements being dragged
    if (elementId != null &&
        widget.renderController.isElementDragging(elementId)) {
      if (!widget.renderController.shouldSkipElementRendering(elementId)) {
        // Only render preview if not using the dedicated preview layer
        final previewPosition =
            widget.renderController.getElementPreviewPosition(elementId);
        if (previewPosition != null) {
          // Use preview position instead of actual position
          elementCopy['x'] = previewPosition.dx;
          elementCopy['y'] = previewPosition.dy;
          print(
              '🎨 ContentRenderLayer: Using preview position for dragging element $elementId: $previewPosition');
        }
      }
    }

    print('🎨 ContentRenderLayer: Rendering element $elementId ($type)');

    // Performance tracking for complex rendering operations
    final renderStart = DateTime.now();

    Widget result;
    switch (type) {
      case 'text':
        result = ElementRenderers.buildTextElement(elementCopy,
            isPreviewMode: widget.isPreviewMode);
        break;
      case 'image':
        result = ElementRenderers.buildImageElement(elementCopy,
            isPreviewMode: widget.isPreviewMode);
        break;
      case 'collection':
        result = ElementRenderers.buildCollectionElement(elementCopy,
            ref: ref, isPreviewMode: widget.isPreviewMode);
        break;
      case 'group':
        result = ElementRenderers.buildGroupElement(elementCopy,
            isSelected: widget.selectedElementIds.contains(elementId),
            ref: ref,
            isPreviewMode: widget.isPreviewMode);
        break;
      default:
        print(
            '🎨 ContentRenderLayer: Unknown element type: $type for element $elementId');
        result = Container(
          color: Colors.grey.withAlpha(51),
          child: Center(child: Text('Unknown element type: $type')),
        );
    }

    final renderTime = DateTime.now().difference(renderStart).inMilliseconds;
    if (renderTime > 8) {
      // Log slow rendering operations (> half frame at 60fps)
      print(
          '⚠️ ContentRenderLayer: Slow render for $elementId ($type): ${renderTime}ms');
    }

    return result;
  }

  /// Sort elements by layer order
  List<Map<String, dynamic>> _sortElementsByLayer(
    List<Map<String, dynamic>> elements,
    List<Map<String, dynamic>> layers,
  ) {
    // Create a map of layer ID to layer order
    final layerOrder = <String, int>{};
    for (int i = 0; i < layers.length; i++) {
      layerOrder[layers[i]['id'] as String] = i;
    }

    // Sort elements by layer order
    final sortedElements = List<Map<String, dynamic>>.from(elements);
    sortedElements.sort((a, b) {
      final layerA = a['layerId'] as String?;
      final layerB = b['layerId'] as String?;

      final orderA = layerA != null ? (layerOrder[layerA] ?? 999) : 999;
      final orderB = layerB != null ? (layerOrder[layerB] ?? 999) : 999;

      return orderA.compareTo(orderB);
    });

    return sortedElements;
  }

  /// Update elements cache when widget updates
  void _updateElementsCache(
    List<Map<String, dynamic>> oldElements,
    List<Map<String, dynamic>> newElements,
  ) {
    final oldElementIds = oldElements.map((e) => e['id'] as String).toSet();
    final newElementIds = newElements.map((e) => e['id'] as String).toSet();

    // Find added, removed, and potentially modified elements
    final addedElements = newElementIds.difference(oldElementIds);
    final removedElements = oldElementIds.difference(newElementIds);

    // Handle removed elements
    for (final elementId in removedElements) {
      widget.renderController.notifyElementDeleted(elementId: elementId);
    }

    // Handle added elements
    for (final elementId in addedElements) {
      final element = newElements.firstWhere((e) => e['id'] == elementId);
      widget.renderController.notifyElementCreated(
        elementId: elementId,
        properties: element,
      );
      _cacheManager.markElementForUpdate(elementId);
    }

    // Check for modified elements
    for (final element in newElements) {
      final elementId = element['id'] as String;
      if (oldElementIds.contains(elementId)) {
        final oldElement = oldElements.firstWhere((e) => e['id'] == elementId);

        // Compare properties to detect changes
        if (!_mapsEqual(oldElement, element)) {
          widget.renderController.notifyElementChanged(
            elementId: elementId,
            newProperties: element,
          );
          _cacheManager.markElementForUpdate(elementId);
        }
      }
    }
  }

  /// Prepare cache with frequently used elements
  void _warmupCache(List<Map<String, dynamic>> elements) {
    // Determine which elements are likely to be needed soon
    // Start with visible elements in the current viewport

    // We can further optimize by prioritizing elements that are:
    // 1. Currently visible
    // 2. Recently interacted with
    // 3. Expensive to render (like images)

    final highPriorityElements = <Map<String, dynamic>>[];

    // Process elements to identify high priority ones
    for (final element in elements) {
      final elementType = element['type'] as String;

      // Prioritize images and complex elements
      if (elementType == 'image' || elementType == 'collection') {
        highPriorityElements.add(element);
      }
    }

    // Limit the number of elements to pre-cache to avoid startup delay
    final elementsToPrecache = highPriorityElements.take(10).toList();

    // Pre-render high priority elements
    if (elementsToPrecache.isNotEmpty) {
      print(
          '🔄 ContentRenderLayer: Pre-caching ${elementsToPrecache.length} high-priority elements');

      // Use a microtask to avoid blocking the UI thread during initialization
      Future.microtask(() {
        for (final element in elementsToPrecache) {
          final elementId = element['id'] as String;
          if (!_cacheManager.doesElementNeedUpdate(elementId)) {
            _getOrCreateElementWidget(element);
          }
        }
        print('✅ ContentRenderLayer: Pre-caching complete');
      });
    }
  }
}
