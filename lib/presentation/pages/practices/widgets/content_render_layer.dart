import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/practice/element_renderers.dart';
import '../../../widgets/practice/performance_monitor.dart';
import 'content_render_controller.dart';
import 'element_change_types.dart';

/// Content rendering layer widget for isolated content rendering
class ContentRenderLayer extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> elements;
  final List<Map<String, dynamic>> layers;
  final ContentRenderController renderController;
  final bool isPreviewMode;
  final Size pageSize;
  final Color backgroundColor;
  final Set<String> selectedElementIds;

  const ContentRenderLayer({
    super.key,
    required this.elements,
    required this.layers,
    required this.renderController,
    required this.isPreviewMode,
    required this.pageSize,
    required this.backgroundColor,
    required this.selectedElementIds,
  });

  @override
  ConsumerState<ContentRenderLayer> createState() => _ContentRenderLayerState();
}

/// Widget cache entry for performance optimization
class ElementWidgetCacheEntry {
  final Widget widget;
  final DateTime lastAccess;
  final Map<String, dynamic> properties;

  ElementWidgetCacheEntry({
    required this.widget,
    required this.lastAccess,
    required this.properties,
  });
}

class _ContentRenderLayerState extends ConsumerState<ContentRenderLayer> {
  /// Cache for element widgets to avoid rebuilding unchanged elements
  final Map<String, ElementWidgetCacheEntry> _elementWidgetCache = {};

  /// Track which elements need to be re-rendered
  final Set<String> _elementsNeedingUpdate = {};

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

    // Log element details
    for (final element in widget.elements) {
      final id = element['id'] as String?;
      final type = element['type'] as String?;
      final x = element['x'];
      final y = element['y'];
      final width = element['width'];
      final height = element['height'];
      print(
          '🎨 ContentRenderLayer: - Element $id ($type) at ($x, $y) size ${width}x$height');
    }

    // Clean up old cache entries periodically
    _cleanupCache();

    // Sort elements by layer order
    final sortedElements = _sortElementsByLayer(widget.elements, widget.layers);

    return RepaintBoundary(
      child: Container(
        width: widget.pageSize.width,
        height: widget.pageSize.height,
        color: widget.backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: sortedElements.map((element) {
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
            return Positioned(
              left: elementX,
              top: elementY,
              child: RepaintBoundary(
                key: ValueKey('element_repaint_${element['id']}'),
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
    // No need to removeListener since we're not using addListener anymore
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Initialize controller with current elements
    widget.renderController.initializeElements(widget.elements);

    // Listen to changes via stream only (more efficient than broad listener)
    widget.renderController.changeStream.listen(_handleElementChange);
  }

  /// Clean up old cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(minutes: 5));

    _elementWidgetCache.removeWhere((key, entry) {
      return entry.lastAccess.isBefore(cutoff);
    });
  }

  /// Get or create cached widget for an element
  Widget _getOrCreateElementWidget(Map<String, dynamic> element) {
    final elementId = element['id'] as String;

    // Check if we have a valid cached widget
    if (!_elementsNeedingUpdate.contains(elementId) &&
        _elementWidgetCache.containsKey(elementId)) {
      final cached = _elementWidgetCache[elementId]!;

      // Update access time
      _elementWidgetCache[elementId] = ElementWidgetCacheEntry(
        widget: cached.widget,
        lastAccess: DateTime.now(),
        properties: cached.properties,
      );

      return cached.widget;
    }

    // Create new widget
    final widget = _renderElement(element);

    // Cache the widget
    _elementWidgetCache[elementId] = ElementWidgetCacheEntry(
      widget: widget,
      lastAccess: DateTime.now(),
      properties: Map.from(element),
    );

    // Remove from update list
    _elementsNeedingUpdate.remove(elementId);

    return widget;
  }

  /// Handle specific element changes
  void _handleElementChange(ElementChangeInfo changeInfo) {
    debugPrint(
        'ContentRenderLayer: Handling element change - ${changeInfo.changeType} for ${changeInfo.elementId}');

    switch (changeInfo.changeType) {
      case ElementChangeType.contentOnly:
      case ElementChangeType.opacity:
        // Only update the specific element widget
        _markElementForUpdate(changeInfo.elementId);
        break;

      case ElementChangeType.sizeOnly:
      case ElementChangeType.positionOnly:
      case ElementChangeType.sizeAndPosition:
      case ElementChangeType.rotation:
        // Update element and potentially affect layout
        _markElementForUpdate(changeInfo.elementId);
        _invalidateLayoutCaches();
        break;

      case ElementChangeType.visibility:
      case ElementChangeType.created:
      case ElementChangeType.deleted:
        // Full update needed
        _markAllElementsForUpdate();
        break;

      case ElementChangeType.multiple:
        // Conservative approach - update everything
        _markAllElementsForUpdate();
        break;
    }
  }

  /// Invalidate layout-related caches
  void _invalidateLayoutCaches() {
    // For now, we'll clear all caches when layout changes
    // In the future, this could be more selective
    _elementWidgetCache.clear();
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

  /// Mark all elements for update
  void _markAllElementsForUpdate() {
    _elementsNeedingUpdate
        .addAll(widget.elements.map((e) => e['id'] as String));
    _elementWidgetCache.clear();
  }

  /// Mark an element for update in the next render
  void _markElementForUpdate(String elementId) {
    _elementsNeedingUpdate.add(elementId);
    _elementWidgetCache.remove(elementId);
  }

  /// Render a single element
  Widget _renderElement(Map<String, dynamic> element) {
    final type = element['type'] as String;
    final elementId = element['id'] as String?;

    // 创建元素的副本，以便在拖拽时不修改原始数据
    final elementCopy =
        Map<String, dynamic>.from(element); // 检查元素是否正在被拖拽，如果是且未启用拖拽预览，使用预览位置
    // 如果启用了DragPreviewLayer，我们可以跳过对拖拽中元素的渲染，提高性能
    if (elementId != null &&
        widget.renderController.isElementDragging(elementId)) {
      if (widget.renderController.shouldSkipElementRendering(elementId)) {
        // 如果使用独立的拖拽预览层，返回一个空白占位符以提高性能
        // 在拖拽预览层会显示元素的预览，所以这里不需要渲染
        return const SizedBox.shrink();
      } else {
        // 如果未使用独立的拖拽预览层，则在这里渲染拖拽预览
        final previewPosition =
            widget.renderController.getElementPreviewPosition(elementId);
        if (previewPosition != null) {
          // 使用预览位置而不是实际位置
          elementCopy['x'] = previewPosition.dx;
          elementCopy['y'] = previewPosition.dy;
          print(
              '🎨 ContentRenderLayer: Using preview position for dragging element $elementId: $previewPosition');
        }
      }
    }

    final x = elementCopy['x'];
    final y = elementCopy['y'];
    final width = elementCopy['width'];
    final height = elementCopy['height'];

    print(
        '🎨 ContentRenderLayer: Rendering element $elementId ($type) at ($x, $y) size ${width}x$height');

    switch (type) {
      case 'text':
        final result = ElementRenderers.buildTextElement(elementCopy,
            isPreviewMode: widget.isPreviewMode);
        print('🎨 ContentRenderLayer: Text element $elementId rendered');
        return result;
      case 'image':
        final result = ElementRenderers.buildImageElement(elementCopy,
            isPreviewMode: widget.isPreviewMode);
        print('🎨 ContentRenderLayer: Image element $elementId rendered');
        return result;
      case 'collection':
        final result = ElementRenderers.buildCollectionElement(element,
            ref: ref, isPreviewMode: widget.isPreviewMode);
        print('🎨 ContentRenderLayer: Collection element $elementId rendered');
        return result;
      case 'group':
        final result = ElementRenderers.buildGroupElement(element,
            isSelected: widget.selectedElementIds.contains(element['id']),
            ref: ref,
            isPreviewMode: widget.isPreviewMode);
        print('🎨 ContentRenderLayer: Group element $elementId rendered');
        return result;
      default:
        print(
            '🎨 ContentRenderLayer: Unknown element type: $type for element $elementId');
        return Container(
          color: Colors.grey.withAlpha(51),
          child: Center(child: Text('Unknown element type: $type')),
        );
    }
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
      _elementWidgetCache.remove(elementId);
      widget.renderController.notifyElementDeleted(elementId: elementId);
    }

    // Handle added elements
    for (final elementId in addedElements) {
      final element = newElements.firstWhere((e) => e['id'] == elementId);
      widget.renderController.notifyElementCreated(
        elementId: elementId,
        properties: element,
      );
      _markElementForUpdate(elementId);
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
          _markElementForUpdate(elementId);
        }
      }
    }
  }
}
