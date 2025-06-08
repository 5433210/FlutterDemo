import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../widgets/practice/element_cache_manager.dart';
import '../../../widgets/practice/element_renderers.dart';
import '../../../widgets/practice/performance_monitor.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../helpers/element_utils.dart';
import 'content_render_controller.dart';
import 'element_change_types.dart';
import 'layers/viewport_culling_manager.dart';

/// Content rendering layer widget for isolated content rendering
class ContentRenderLayer extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>>? elements;
  final List<Map<String, dynamic>>? layers;
  final ContentRenderController renderController;
  final bool? isPreviewMode;
  final Size? pageSize;
  final Color? backgroundColor;
  final Set<String>? selectedElementIds;
  final ViewportCullingManager? viewportCullingManager;

  // For LayerRenderManager integration
  final PracticeEditController? controller;

  const ContentRenderLayer({
    super.key,
    required this.renderController,
    this.elements,
    this.layers,
    this.isPreviewMode,
    this.pageSize,
    this.backgroundColor,
    this.selectedElementIds,
    this.viewportCullingManager,
    this.controller,
  });

  // Legacy constructor with full parameters
  const ContentRenderLayer.withFullParams({
    super.key,
    required List<Map<String, dynamic>> elements,
    required List<Map<String, dynamic>> layers,
    required this.renderController,
    required bool isPreviewMode,
    required Size pageSize,
    required Color backgroundColor,
    required Set<String> selectedElementIds,
    this.viewportCullingManager,
  })  : elements = elements,
        layers = layers,
        isPreviewMode = isPreviewMode,
        pageSize = pageSize,
        backgroundColor = backgroundColor,
        selectedElementIds = selectedElementIds,
        controller = null;

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

    return ListenableBuilder(
      listenable: widget.renderController,
      builder: (context, child) {
        EditPageLogger.rendererDebug('ContentRenderLayer重建', 
          data: {'trigger': 'ContentRenderController变化'});
        return _buildContent(context);
      },
    );
  }

  @override
  void didUpdateWidget(ContentRenderLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Get current and old elements
    final oldElements = oldWidget.elements ??
        oldWidget.controller?.state.currentPageElements ??
        [];
    final currentElements =
        widget.elements ?? widget.controller?.state.currentPageElements ?? [];

    // Check for element additions/removals/modifications
    _updateElementsCache(oldElements, currentElements);
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
      // Balanced cache size for better memory management
      maxSize: 200, // 降低到200个元素，避免内存压力
      // 25MB memory threshold - more conservative for mobile devices
      memoryThreshold: 25 * 1024 * 1024,
    );

    // Initialize selective rebuilding system
    widget.renderController.initializeSelectiveRebuilding(_cacheManager);

    // Get initial elements
    final initialElements =
        widget.elements ?? widget.controller?.state.currentPageElements ?? [];

    // Initialize controller with current elements
    widget.renderController.initializeElements(initialElements);

    // Listen to changes via stream only (more efficient than broad listener)
    widget.renderController.changeStream.listen(_handleElementChange);

    // Warm up the cache with visible elements
    _warmupCache(initialElements);
  }

  Widget _buildContent(BuildContext context) {
    // Get data from controller if not provided directly
    final elements =
        widget.elements ?? widget.controller?.state.currentPageElements ?? [];
    final layers = widget.layers ?? widget.controller?.state.layers ?? [];
    final isPreviewMode =
        widget.isPreviewMode ?? widget.controller?.state.isPreviewMode ?? false;
    final selectedElementIds = widget.selectedElementIds ??
        widget.controller?.state.selectedElementIds.toSet() ??
        <String>{};

    // Calculate page size and background color if not provided
    Size pageSize = widget.pageSize ?? const Size(800, 600);
    Color backgroundColor = widget.backgroundColor ?? Colors.white;

    if (widget.controller != null && widget.pageSize == null) {
      final currentPage = widget.controller!.state.currentPage;
      if (currentPage != null) {
        pageSize = ElementUtils.calculatePixelSize(currentPage);

        try {
          final background = currentPage['background'] as Map<String, dynamic>?;
          if (background != null && background['type'] == 'color') {
            final colorStr = background['value'] as String? ?? '#FFFFFF';
            backgroundColor = ElementUtils.parseColor(colorStr);
          }
        } catch (e) {
          EditPageLogger.rendererError('背景颜色解析失败', error: e);
        }
      }
    }
    EditPageLogger.rendererDebug('ContentRenderLayer构建内容', 
      data: {
        'elementsCount': elements.length,
        'selectedCount': selectedElementIds.length,
        'cacheMetrics': _cacheManager.metrics.getReport(),
        'isPreviewMode': isPreviewMode
      });

    // Sort elements by layer order
    final sortedElements = _sortElementsByLayer(elements, layers);

    // Apply viewport culling if available
    final visibleElements = widget.viewportCullingManager != null
        ? widget.viewportCullingManager!.cullElementsAdvanced(
            sortedElements,
            enableSpatialOptimization: sortedElements.length > 50,
          )
        : sortedElements;

    // Log culling metrics
    if (widget.viewportCullingManager != null) {
      final cullingMetrics = widget.viewportCullingManager!.getMetrics();
      EditPageLogger.rendererDebug('视口裁剪指标', 
        data: {'metrics': cullingMetrics});

      // Configure culling strategy based on element count and performance
      if (sortedElements.length > 500) {
        // 降低阈值，更早启用优化
        widget.viewportCullingManager!.configureCulling(
          strategy: CullingStrategy.aggressive,
          enableFastCulling: true,
        );
      } else if (sortedElements.length > 200) {
        // 降低阈值
        widget.viewportCullingManager!.configureCulling(
          strategy: CullingStrategy.adaptive,
          enableFastCulling: true,
        );
      } else if (sortedElements.length > 50) {
        // 添加新阈值
        widget.viewportCullingManager!.configureCulling(
          strategy: CullingStrategy.conservative,
          enableFastCulling: false,
        );
      }
    }

    // Trigger cache cleanup for efficient memory management
    _cacheManager.cleanupCache();

    return RepaintBoundary(
      child: SizedBox(
        width: pageSize.width,
        height: pageSize.height,
        // 🔧 关键修复：移除背景色，让静态背景层透过来
        // color: backgroundColor, // 背景色由静态背景层处理
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: visibleElements.map((element) {
            // Skip hidden elements in preview mode
            final isHidden = element['hidden'] == true;
            if (isHidden && isPreviewMode) {
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

            // 🔧 获取图层透明度
            double layerOpacity = 1.0;
            bool isLayerLocked = false;
            if (layerId != null && widget.layers != null) {
              final layer = widget.layers!.firstWhere(
                (l) => l['id'] == layerId,
                orElse: () => <String, dynamic>{},
              );
              if (layer.isNotEmpty) {
                layerOpacity = (layer['opacity'] as num?)?.toDouble() ?? 1.0;
                isLayerLocked = layer['isLocked'] as bool? ?? false;
              }
            }

            // 🔧 合并元素和图层的透明度
            final finalOpacity = elementOpacity * layerOpacity;

            // Skip rendering elements that are being drawn by the drag preview layer
            if (widget.renderController.shouldSkipElementRendering(elementId)) {
              return const SizedBox.shrink();
            }

            // 🔧 为锁定元素添加视觉指示
            Widget elementWidget = _getOrCreateElementWidget(element);
            
            // 如果元素或图层被锁定，添加锁定标志
            final isElementLocked = element['locked'] as bool? ?? false;
            if (isElementLocked || isLayerLocked) {
              List<Widget> lockIcons = [];
              
              // 元素锁定标志 - 使用实心锁图标
              if (isElementLocked) {
                lockIcons.add(
                  Container(
                    margin: const EdgeInsets.only(bottom: 2),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              
              // 图层锁定标志 - 使用图层锁图标  
              if (isLayerLocked) {
                lockIcons.add(
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.white, width: 0.5),
                    ),
                    child: const Icon(
                      Icons.layers,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                );
              }
              
              elementWidget = Stack(
                children: [
                  elementWidget,
                  // 锁定标志 - 在右上角垂直排列
                  if (!isPreviewMode) // 预览模式下不显示锁定标志
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: lockIcons,
                      ),
                    ),
                ],
              );
            }

            return Positioned(
              left: elementX,
              top: elementY,
              child: RepaintBoundary(
                key: ValueKey('element_repaint_$elementId'),
                child: Transform.rotate(
                  angle: elementRotation * 3.14159265359 / 180,
                  child: Opacity(
                    opacity: isHidden && !isPreviewMode ? 0.5 : finalOpacity,
                    child: SizedBox(
                      width: elementWidth,
                      height: elementHeight,
                      child: elementWidget,
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
    if (widget.selectedElementIds?.contains(elementId) == true) {
      // Selected elements get higher priority
      priority = CachePriority.high;
    } else if (elementType == 'text') {
      // Text elements get higher priority due to complex rendering
      priority = CachePriority.high;
    } else if (elementType == 'image') {
      // Images can be cached with medium priority
      priority = CachePriority.medium;
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

  /// Handle element change notifications from the controller
  void _handleElementChange(ElementChangeInfo changeInfo) {
    if (mounted) {
      EditPageLogger.rendererDebug('处理元素变化', 
        data: {
          'changeType': changeInfo.changeType.toString(),
          'elementId': changeInfo.elementId
        });

      // Get current elements
      final currentElements =
          widget.elements ?? widget.controller?.state.currentPageElements ?? [];

      switch (changeInfo.changeType) {
        case ElementChangeType.created:
        case ElementChangeType.contentOnly:
        case ElementChangeType.sizeOnly:
        case ElementChangeType.positionOnly:
        case ElementChangeType.sizeAndPosition:
        case ElementChangeType.rotation:
        case ElementChangeType.opacity:
        case ElementChangeType.visibility:
          // Update specific element in cache
          _cacheManager.markElementForUpdate(changeInfo.elementId);
          break;

        case ElementChangeType.deleted:
          // Full update needed
          _cacheManager.markAllElementsForUpdate(currentElements);
          break;

        case ElementChangeType.multiple:
          // Conservative approach - update everything
          _cacheManager.markAllElementsForUpdate(currentElements);
          break;
      }

      // Trigger rebuild with new data
      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Check if a layer is hidden
  bool _isLayerHidden(String layerId) {
    final layers = widget.layers;
    if (layers == null) return false;

    final layer = layers.firstWhere(
      (l) => l['id'] == layerId,
      orElse: () => <String, dynamic>{},
    );
    return layer.isNotEmpty ? layer['isVisible'] == false : false;
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
          EditPageLogger.rendererDebug('使用拖拽预览位置', 
            data: {
              'elementId': elementId,
              'previewPosition': '${previewPosition.dx}, ${previewPosition.dy}'
            });
        }
      }
    }

    EditPageLogger.rendererDebug('渲染元素', 
      data: {'elementId': elementId, 'type': type});

    // Performance tracking for complex rendering operations
    final renderStart = DateTime.now();

    Widget result;
    switch (type) {
      case 'text':
        result = ElementRenderers.buildTextElement(elementCopy,
            isPreviewMode: widget.isPreviewMode == true);
        break;
      case 'image':
        result = ElementRenderers.buildImageElement(elementCopy,
            isPreviewMode: widget.isPreviewMode == true);
        break;
      case 'collection':
        result = ElementRenderers.buildCollectionElement(elementCopy,
            ref: ref, isPreviewMode: widget.isPreviewMode == true);
        break;
      case 'group':
        result = ElementRenderers.buildGroupElement(elementCopy,
            isSelected: widget.selectedElementIds?.contains(elementId) == true,
            ref: ref,
            isPreviewMode: widget.isPreviewMode == true);
        break;
      default:
        EditPageLogger.rendererError('未知元素类型', 
          data: {'type': type, 'elementId': elementId});
        result = Container(
          color: Colors.grey.withAlpha(51),
          child: Center(child: Text('Unknown element type: $type')),
        );
    }

    final renderTime = DateTime.now().difference(renderStart).inMilliseconds;
    if (renderTime > 8) {
      // Log slow rendering operations (> half frame at 60fps)
      EditPageLogger.performanceWarning('渲染性能警告', 
        data: {
          'elementId': elementId,
          'type': type,
          'renderTime': renderTime,
          'threshold': 8
        });
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
