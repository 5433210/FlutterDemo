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
  // 🔍[TRACKING] 重建计数器
  int _buildCount = 0;
  int _didUpdateWidgetCount = 0;

  // 性能监控器
  late PerformanceMonitor _performanceMonitor;

  // 元素缓存管理器
  late ElementCacheManager _cacheManager;

  // 🔧 拖拽状态跟踪，用于智能监听切换
  bool _lastKnownDragState = false;

  @override
  Widget build(BuildContext context) {
    // 🔍[TRACKING] ContentRenderLayer重建跟踪
    final buildStartTime = DateTime.now();
    _buildCount++;

    // Track performance for ContentRenderLayer rebuilds
    _performanceMonitor.trackWidgetRebuild('ContentRenderLayer');

    // 🔧 优化：只在关键时刻输出日志
    final currentDragState = widget.renderController.isDragging;
    final isDragStateChanged = currentDragState != _lastKnownDragState;

    // 只在拖拽状态变化时输出详细日志
    if (isDragStateChanged) {
      _lastKnownDragState = currentDragState;

      // 输出性能指标
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final buildDuration = DateTime.now().difference(buildStartTime);
        EditPageLogger.performanceInfo(
          'ContentRenderLayer关键重建完成',
          data: {
            'buildNumber': _buildCount,
            'buildDuration': '${buildDuration.inMilliseconds}ms',
            'dragStateChanged': true,
            'newDragState': currentDragState,
            'optimization': 'critical_rebuild_performance',
          },
        );
      });
    } else {
      // 非拖拽状态变化的重建（这不应该频繁发生）
      if (_buildCount % 20 == 0) {
        // 每20次输出一次警告
        EditPageLogger.performanceWarning('ContentRenderLayer意外重建', data: {
          'buildNumber': _buildCount,
          'currentDragState': currentDragState,
          'reason': '非拖拽状态变化引起的重建',
          'suggestion': '检查是否有其他组件触发了不必要的重建',
        });
      }
    }

    // 🔧 使用ListenableBuilder，但现在ContentRenderController已经实现了精确的通知控制
    // 所以重建应该只在拖拽开始和结束时发生
    return ListenableBuilder(
      listenable: widget.renderController,
      builder: (context, child) {
        return _buildContent(context);
      },
    );
  }

  @override
  void didUpdateWidget(ContentRenderLayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔍[TRACKING] didUpdateWidget调用跟踪
    _didUpdateWidgetCount++;

    EditPageLogger.rendererDebug('ContentRenderLayer.didUpdateWidget调用', data: {
      'didUpdateCount': _didUpdateWidgetCount,
      'buildCount': _buildCount,
      'trigger': 'Widget属性变化',
      'optimization': 'content_layer_update_tracking',
    });

    // Get current and old elements
    final oldElements = oldWidget.elements ??
        oldWidget.controller?.state.currentPageElements ??
        [];
    final currentElements =
        widget.elements ?? widget.controller?.state.currentPageElements ?? [];

    // 🔧 新增：检查图层变化
    final oldLayers =
        oldWidget.layers ?? oldWidget.controller?.state.layers ?? [];
    final currentLayers =
        widget.layers ?? widget.controller?.state.layers ?? [];

    // 检查图层是否发生变化
    final layersChanged = _hasLayersChanged(oldLayers, currentLayers);
    final elementsChanged = oldElements.length != currentElements.length;

    // 🔧 关键修复：检查元素顺序是否发生变化
    final elementOrderChanged =
        _hasElementOrderChanged(oldElements, currentElements);

    // 🚀 优化：只在实际发生变化或重要里程碑时记录变化分析
    final hasActualChanges = elementsChanged || layersChanged || elementOrderChanged;
    if (hasActualChanges || _didUpdateWidgetCount % 50 == 0) {
      EditPageLogger.rendererDebug('ContentRenderLayer变化分析', data: {
        'oldElementsCount': oldElements.length,
        'currentElementsCount': currentElements.length,
        'elementsChanged': elementsChanged,
        'layersChanged': layersChanged,
        'elementOrderChanged': elementOrderChanged,
        'didUpdateCount': _didUpdateWidgetCount,
        'changeDetected': hasActualChanges,
        'optimization': hasActualChanges ? 'content_layer_actual_change' : 'content_layer_milestone',
      });
    }

    // 如果图层发生了变化，强制清理缓存以确保重绘
    if (layersChanged) {
      EditPageLogger.rendererDebug('🔧 图层变化检测到，强制清理缓存', data: {
        'reason': 'layer_visibility_or_properties_changed',
        'action': 'force_cache_clear_and_rebuild',
      });

      // 清理缓存以确保使用最新的图层状态
      _cacheManager.cleanupCache(force: true);

      // 标记需要重建
      if (mounted) {
        setState(() {
          // 强制重绘以反映图层变化
        });
      }
    }

    // 处理元素顺序变化，确保重绘
    if (elementOrderChanged) {
      EditPageLogger.rendererDebug('元素顺序变化检测到，开始重建渲染', data: {
        'elementCount': currentElements.length,
      });

      // 将所有元素标记为脏状态，强制重建
      for (final element in currentElements) {
        final elementId = element['id'] as String;
        widget.renderController
            .markElementDirty(elementId, ElementChangeType.multiple);
      }

      // 强制清理缓存以确保使用最新的元素顺序
      _cacheManager.cleanupCache(force: true);

      // 标记所有元素需要更新，确保缓存系统重建所有元素
      _cacheManager.markAllElementsForUpdate(currentElements);

      // 标记需要重建
      if (mounted) {
        setState(() {
          // 强制重绘以反映元素顺序变化
        });
      }
    }

    // Check for element additions/removals/modifications
    _updateElementsCache(oldElements, currentElements);
  }

  @override
  void dispose() {
    // 使用三重保护确保super.dispose()一定被调用
    bool superDisposeCompleted = false;

    try {
      try {
        _cacheManager.dispose();
      } catch (e) {
        debugPrint('dispose cache manager失败: $e');
      }
    } catch (e) {
      debugPrint('ContentRenderLayer dispose过程中发生异常: $e');
    } finally {
      // 无论如何都确保super.dispose()被调用
      if (!superDisposeCompleted) {
        try {
          super.dispose();
          superDisposeCompleted = true;
        } catch (disposeError) {
          debugPrint('ContentRenderLayer super.dispose()调用失败: $disposeError');
          // 尝试第三次调用
          try {
            super.dispose();
            superDisposeCompleted = true;
          } catch (finalError) {
            debugPrint('ContentRenderLayer 最终super.dispose()调用失败: $finalError');
            // 即使最终失败，也标记为完成，避免无限循环
            superDisposeCompleted = true;
          }
        }
      }
    }

    // 额外的安全检查：如果所有尝试都失败，强制标记完成
    if (!superDisposeCompleted) {
      debugPrint('警告：ContentRenderLayer super.dispose()可能未能成功调用');
    }
  }

  @override
  void initState() {
    super.initState();

    // 初始化性能监控器
    _performanceMonitor = PerformanceMonitor();

    // 🚀 初始化元素缓存管理器
    _cacheManager = ElementCacheManager(
      strategy: CacheStrategy.priorityBased,
      maxSize: 50, // 最多缓存50个元素
      memoryThreshold: 25 * 1024 * 1024, // 25MB内存阈值
    );

    // 初始化渲染控制器的选择性重建功能
    widget.renderController.initializeSelectiveRebuilding(_cacheManager);

    EditPageLogger.rendererDebug('ContentRenderLayer初始化完成', data: {
      'cacheMaxSize': 50,
      'enableMetrics': true,
      'optimization': 'content_layer_initialization',
    });

    // 🔧 初始化拖拽状态跟踪
    _lastKnownDragState = widget.renderController.isDragging;

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

    final isDragging = widget.renderController.isDragging;

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
    // 在需要时记录重建日志
    final wasDragStateChanged = isDragging != _lastKnownDragState;
    if (wasDragStateChanged) {
      EditPageLogger.rendererDebug('拖拽状态变化', data: {
        'isDragging': isDragging,
      });
    }

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
      EditPageLogger.rendererDebug('视口裁剪指标', data: {'metrics': cullingMetrics});

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
        // 背景色由静态背景层处理
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.hardEdge,
          children: visibleElements.map((element) {
            final currentElementId = element['id'] as String;

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
            final elementType = element['type'] as String;

            // 🔧 优化：移除频繁的元素处理日志

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

            // 🔧 获取元素widget（现在在_getOrCreateElementWidget中处理拖拽隐藏检查）
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

            // 组合元素不需要额外的Transform.rotate，因为子元素已经在内部被正确处理
            final needsRotation = elementType != 'group';

            return Positioned(
              left: elementX,
              top: elementY,
              child: RepaintBoundary(
                key: ValueKey('element_repaint_$elementId'),
                child: needsRotation
                    ? Transform.rotate(
                        angle: elementRotation * 3.14159265359 / 180,
                        child: Opacity(
                          opacity:
                              isHidden && !isPreviewMode ? 0.5 : finalOpacity,
                          child: SizedBox(
                            width: elementWidth,
                            height: elementHeight,
                            child: elementWidget,
                          ),
                        ),
                      )
                    : Opacity(
                        opacity:
                            isHidden && !isPreviewMode ? 0.5 : finalOpacity,
                        child: SizedBox(
                          width: elementWidth,
                          height: elementHeight,
                          child: elementWidget,
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

    // 🔧 关键修复：优先检查元素是否应该跳过渲染（拖拽隐藏检查）
    // 这个检查必须在缓存检查之前进行，确保拖拽中的元素被正确隐藏
    final shouldSkip =
        widget.renderController.shouldSkipElementRendering(elementId);

    if (shouldSkip) {
      return const SizedBox.shrink();
    }

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
      EditPageLogger.performanceWarning('慢速元素渲染', data: {
        'elementId': elementId,
        'elementType': elementType,
        'renderTime': renderDuration.inMilliseconds,
        'threshold': 8
      });
    }

    return newWidget;
  }

  /// Handle element change notifications from the controller
  void _handleElementChange(ElementChangeInfo changeInfo) {
    if (mounted) {
      EditPageLogger.rendererDebug('处理元素变化', data: {
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

      // 🚀 优化：跳过setState调用，避免额外重建
      // ContentRenderLayer的重建应该通过didUpdateWidget机制处理
      // 元素变化会通过智能状态分发器精确通知相关组件
      EditPageLogger.rendererDebug(
        'ContentRenderLayer跳过setState（优化版）',
        data: {
          'optimization': 'skip_content_layer_setstate',
          'reason': '避免额外重建，依靠didUpdateWidget机制',
          'changeType': changeInfo.changeType.toString(),
          'elementId': changeInfo.elementId,
        },
      );

      // if (mounted) {
      //   setState(() {}); // 🚀 已禁用以避免额外重建
      // }
    }
  }

  /// 检查元素顺序是否发生了变化
  bool _hasElementOrderChanged(List<Map<String, dynamic>> oldElements,
      List<Map<String, dynamic>> currentElements) {
    // 🚀 优化：减少元素顺序检查的详细日志
    // 只在实际发生顺序变化或元素数量变化时记录

    // 如果数量不同，不是单纯的顺序变化
    if (oldElements.length != currentElements.length) {
      // 🚀 优化：只在元素数量变化时记录
      EditPageLogger.rendererDebug('🔧 元素数量变化', data: {
        'oldCount': oldElements.length,
        'currentCount': currentElements.length,
      });
      return false;
    }

    // 检查元素ID的顺序是否发生变化
    bool orderChanged = false;
    for (int i = 0; i < oldElements.length; i++) {
      final oldElementId = oldElements[i]['id'] as String?;
      final currentElementId = currentElements[i]['id'] as String?;

      if (oldElementId != currentElementId) {
        // 🚀 优化：只在发现实际顺序变化时记录
        EditPageLogger.rendererDebug('🔧 发现元素顺序变化', data: {
          'position': i,
          'oldElementId': oldElementId,
          'currentElementId': currentElementId,
        });
        orderChanged = true;
        break;
      }
    }

    if (!orderChanged) {
      // 🚀 优化：移除“无顺序变化”的重复日志
      return false;
    }

    // 进一步验证：确保这确实是顺序变化而不是元素替换
    // 检查新列表是否包含所有旧元素的ID
    final oldElementIds = oldElements.map((e) => e['id'] as String).toSet();
    final currentElementIds =
        currentElements.map((e) => e['id'] as String).toSet();

    final isSameElements = oldElementIds.length == currentElementIds.length &&
        oldElementIds.every((id) => currentElementIds.contains(id));

    EditPageLogger.rendererDebug('🔧 验证是否为真正的顺序变化', data: {
      'orderChanged': orderChanged,
      'isSameElements': isSameElements,
      'result': orderChanged && isSameElements,
      'oldElementIds': oldElementIds.toList(),
      'currentElementIds': currentElementIds.toList(),
    });

    if (orderChanged && isSameElements) {
      EditPageLogger.rendererDebug('🔧 ✅ 确认为元素顺序变化！');
      return true;
    } else {
      EditPageLogger.rendererDebug('🔧 ❌ 不是纯粹的顺序变化');
      return false;
    }
  }

  /// 检查图层是否发生了变化
  bool _hasLayersChanged(List<Map<String, dynamic>> oldLayers,
      List<Map<String, dynamic>> currentLayers) {
    // 首先检查数量是否变化
    if (oldLayers.length != currentLayers.length) {
      return true;
    }

    // 检查每个图层的关键属性是否变化
    for (int i = 0; i < oldLayers.length; i++) {
      final oldLayer = oldLayers[i];
      final currentLayer = currentLayers[i];

      // 检查ID是否匹配
      if (oldLayer['id'] != currentLayer['id']) {
        return true;
      }

      // 检查影响渲染的关键属性
      final oldVisible = oldLayer['isVisible'] as bool? ?? true;
      final currentVisible = currentLayer['isVisible'] as bool? ?? true;

      final oldOpacity = (oldLayer['opacity'] as num?)?.toDouble() ?? 1.0;
      final currentOpacity =
          (currentLayer['opacity'] as num?)?.toDouble() ?? 1.0;

      final oldLocked = oldLayer['isLocked'] as bool? ?? false;
      final currentLocked = currentLayer['isLocked'] as bool? ?? false;

      // 如果任何关键属性发生变化，则认为图层已变化
      if (oldVisible != currentVisible ||
          oldOpacity != currentOpacity ||
          oldLocked != currentLocked) {
        return true;
      }
    }

    return false;
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
          EditPageLogger.rendererDebug('使用拖拽预览位置', data: {
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
        result = ElementRenderers.buildCollectionElement(context, elementCopy,
            ref: ref, isPreviewMode: widget.isPreviewMode == true);
        break;
      case 'group':
        result = ElementRenderers.buildGroupElement(context, elementCopy,
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
      EditPageLogger.performanceWarning('渲染性能警告', data: {
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
      EditPageLogger.rendererDebug('开始预缓存高优先级元素',
          data: {'elementCount': elementsToPrecache.length});

      // Use a microtask to avoid blocking the UI thread during initialization
      Future.microtask(() {
        for (final element in elementsToPrecache) {
          final elementId = element['id'] as String;
          if (!_cacheManager.doesElementNeedUpdate(elementId)) {
            _getOrCreateElementWidget(element);
          }
        }
        EditPageLogger.rendererDebug('预缓存完成');
      });
    }
  }
}
