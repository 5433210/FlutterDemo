import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../widgets/practice/drag_state_manager.dart';
import '../../../../../widgets/practice/guideline_alignment/guideline_layer.dart';
import '../../../../../widgets/practice/guideline_alignment/guideline_types.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';
import '../../../helpers/element_utils.dart';
import '../../content_render_controller.dart';
import '../../content_render_layer.dart';
import '../../drag_preview_layer.dart';
import '../../free_control_points.dart';
import '../../layers/layer_types.dart';
import '../../selected_elements_highlight.dart';
import 'canvas_ui_components.dart';

/// 拖拽配置
class CanvasDragConfig {
  static bool enableDragPreview = true;
  static bool showPerformanceOverlay = false;
}

/// 画布层级构建器
/// 负责构建画布中各个层级的Widget
mixin CanvasLayerBuilders {
  /// 获取活动的参考线列表（由使用此mixin的类实现）
  List<Guideline> get activeGuidelines;

  /// 获取内容渲染控制器（由使用此mixin的类实现）
  ContentRenderController get contentRenderController;

  /// 获取BuildContext（由使用此mixin的类实现）
  BuildContext get context;

  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;

  /// 获取拖拽状态管理器（由使用此mixin的类实现）
  DragStateManager get dragStateManager;

  /// 获取是否预览模式（由使用此mixin的类实现）
  bool get isPreviewMode;

  /// 获取选择框状态通知器（由使用此mixin的类实现）
  ValueNotifier<SelectionBoxState> get selectionBoxNotifier;

  /// 获取转换控制器（由使用此mixin的类实现）
  TransformationController get transformationController;

  /// 构建背景层（网格、页面背景）
  Widget buildBackgroundLayer(LayerConfig config) {
    // 🚀 优化：移除ListenableBuilder，避免Controller变化触发背景层重建
    // 背景层应该相对静态，只在页面切换或网格设置变化时重建
    final currentPage = controller.state.currentPage;
    if (currentPage == null) return const SizedBox.shrink();

    EditPageLogger.canvasDebug(
      '构建背景层（优化版）',
      data: {
        'hasGrid': controller.state.gridVisible,
        'isPreviewMode': isPreviewMode,
        'optimization': 'no_controller_listener',
        'avoidedExtraRebuild': true,
      },
    );

    // 🔧 正确解析页面背景颜色
    Color backgroundColor = Colors.white;
    try {
      final background = currentPage['background'] as Map<String, dynamic>?;
      EditPageLogger.canvasDebug('背景层构建', data: {'background': '$background'});

      if (background != null && background['type'] == 'color') {
        final colorStr = background['value'] as String? ?? '#FFFFFF';
        EditPageLogger.canvasDebug('背景颜色字符串', data: {'colorStr': colorStr});

        // 解析颜色字符串
        if (colorStr.startsWith('#')) {
          final hex = colorStr.substring(1);
          if (hex.length == 6) {
            backgroundColor = Color(int.parse('FF$hex', radix: 16));
            EditPageLogger.canvasDebug('解析6位颜色',
                data: {'backgroundColor': '$backgroundColor'});
          } else if (hex.length == 8) {
            backgroundColor = Color(int.parse(hex, radix: 16));
            EditPageLogger.canvasDebug('解析8位颜色',
                data: {'backgroundColor': '$backgroundColor'});
          }
        }
      } else {
        EditPageLogger.canvasDebug('使用默认白色背景',
            data: {'reason': '没有背景数据或类型不是color'});
      }
    } catch (e) {
      EditPageLogger.editPageError('背景色解析失败，使用默认白色', error: e);
      backgroundColor = Colors.white;
    }

    EditPageLogger.canvasDebug('背景层最终配置', data: {
      'backgroundColor': '$backgroundColor',
      'gridVisible': controller.state.gridVisible,
      'isPreviewMode': isPreviewMode,
      'gridSize': controller.state.gridSize
    });

    // 🔧 网格只在编辑模式下显示，预览模式、导出、缩略图生成时不显示
    final showGrid = controller.state.gridVisible && !isPreviewMode;

    Widget childWidget;
    if (showGrid) {
      EditPageLogger.canvasDebug('网格开启且为编辑模式，绘制网格');
      final gridColor = _getGridColor(backgroundColor, context);
      childWidget = CustomPaint(
        painter: CanvasGridPainter(
          gridSize: controller.state.gridSize,
          gridColor: gridColor,
        ),
        size: Size.infinite,
      );
    } else {
      if (controller.state.gridVisible && isPreviewMode) {
        EditPageLogger.canvasDebug('预览模式下隐藏网格', data: {
          'reason': '网格不参与预览渲染、缩略图生成和文件导出',
          'gridVisible': controller.state.gridVisible,
          'isPreviewMode': isPreviewMode,
        });
      } else {
        EditPageLogger.canvasDebug('网格关闭，使用SizedBox.expand');
      }
      childWidget = const SizedBox.expand();
    }

    final container = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      child: childWidget,
    );

    return container;
  }

  Widget buildContentLayer(LayerConfig config) {
    final currentPage = controller.state.currentPage;
    final elements = controller.state.currentPageElements;

    if (currentPage == null) {
      return const SizedBox.shrink();
    }

    AppLogger.debug(
      '构建内容层',
      tag: 'Canvas',
      data: {
        'elementsCount': elements.length,
        'selectedCount': controller.state.selectedElementIds.length,
      },
    );

    final pageSize = ElementUtils.calculatePixelSize(currentPage);
    Color backgroundColor = Colors.white;

    try {
      final background = currentPage['background'] as Map<String, dynamic>?;
      if (background != null && background['type'] == 'color') {
        final colorStr = background['value'] as String? ?? '#FFFFFF';
        backgroundColor = ElementUtils.parseColor(colorStr);
      }
    } catch (e) {
      AppLogger.warning(
        '背景色解析失败',
        tag: 'Canvas',
        error: e,
      );
    }

    return ContentRenderLayer.withFullParams(
      elements: elements,
      layers: controller.state.layers,
      renderController: contentRenderController,
      isPreviewMode: isPreviewMode,
      pageSize: pageSize,
      backgroundColor: backgroundColor,
      selectedElementIds: controller.state.selectedElementIds.toSet(),
    );
  }

  /// 构建控制点
  Widget buildControlPoints(
    String elementId,
    double x,
    double y,
    double width,
    double height,
    double rotation,
  ) {
    // AppLogger.debug(
    //   '构建控制点',
    //   tag: 'Canvas',
    //   data: {
    //     'elementId': elementId,
    //     'position': '($x, $y)',
    //     'size': '${width}x$height',
    //     'rotation': rotation,
    //   },
    // );

    // 使用绝对定位确保控制点始终可见
    return AbsorbPointer(
      absorbing: false, // 确保控制点可以接收事件
      child: GestureDetector(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // 透明覆盖层确保控制点接收事件
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // 实际控制点
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  key: ValueKey(
                      'control_points_repaint_${elementId}_${(x * 1000).toInt()}_${(y * 1000).toInt()}_${(width * 100).toInt()}_${(height * 100).toInt()}'),
                  child: Builder(builder: (context) {
                    // 获取当前缩放值
                    final scale =
                        transformationController.value.getMaxScaleOnAxis();

                    // 检查是否正在拖拽并使用预览位置更新控制点
                    final isElementBeingDragged = dragStateManager.isDragging &&
                        dragStateManager.isElementDragging(elementId);

                    double displayX = x;
                    double displayY = y;
                    double displayWidth = width;
                    double displayHeight = height;
                    double displayRotation = rotation;

                    if (isElementBeingDragged) {
                      // 获取预览属性
                      final previewProperties = dragStateManager
                          .getElementPreviewProperties(elementId);
                      if (previewProperties != null) {
                        // 使用完整的预览属性
                        displayX =
                            (previewProperties['x'] as num?)?.toDouble() ?? x;
                        displayY =
                            (previewProperties['y'] as num?)?.toDouble() ?? y;
                        displayWidth =
                            (previewProperties['width'] as num?)?.toDouble() ??
                                width;
                        displayHeight =
                            (previewProperties['height'] as num?)?.toDouble() ??
                                height;
                        displayRotation =
                            (previewProperties['rotation'] as num?)
                                    ?.toDouble() ??
                                rotation;

                        AppLogger.debug(
                          '控制点使用预览属性',
                          tag: 'Canvas',
                          data: {
                            'position': '($displayX, $displayY)',
                            'size': '${displayWidth}x$displayHeight',
                            'rotation': displayRotation,
                          },
                        );
                      } else {
                        // 回退到位置预览
                        final previewPosition = dragStateManager
                            .getElementPreviewPosition(elementId);
                        if (previewPosition != null) {
                          displayX = previewPosition.dx;
                          displayY = previewPosition.dy;
                        }
                      }
                    }

                    return FreeControlPoints(
                      key: ValueKey(
                          'control_points_${elementId}_${scale.toStringAsFixed(2)}_${displayX.toInt()}_${displayY.toInt()}'),
                      elementId: elementId,
                      x: displayX,
                      y: displayY,
                      width: displayWidth,
                      height: displayHeight,
                      rotation: displayRotation,
                      initialScale: scale,
                      onControlPointUpdate: handleControlPointUpdate,
                      onControlPointDragEnd: handleControlPointDragEnd,
                      onControlPointDragStart: handleControlPointDragStart,
                      onControlPointDragEndWithState:
                          handleControlPointDragEndWithState,
                    );
                  }),
                ),
              ),

              // 添加透明覆盖层确保控制点可以立即响应事件
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: true, // 忽略指针事件，让控制点接收事件
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建拖拽预览层
  Widget buildDragPreviewLayer(LayerConfig config) {
    if (!config.shouldRender ||
        !DragConfig.enableDragPreview ||
        isPreviewMode) {
      EditPageLogger.canvasDebug('拖拽预览层跳过构建', data: {
        'shouldRender': config.shouldRender,
        'enableDragPreview': DragConfig.enableDragPreview,
        'isPreviewMode': isPreviewMode,
      });
      return const SizedBox.shrink();
    }

    AppLogger.debug(
      '构建拖拽预览层',
      tag: 'Canvas',
      data: {'isDragging': dragStateManager.isDragging},
    );

    return DragPreviewLayer(
      dragStateManager: dragStateManager,
      elements: controller.state.currentPageElements,
    );
  }

  /// 构建内容层（元素渲染）
  /// 构建参考线层
  Widget buildGuidelineLayer(LayerConfig config) {
    final currentPage = controller.state.currentPage;
    if (currentPage == null || isPreviewMode) {
      return const SizedBox.shrink();
    }

    // 检查是否启用参考线对齐
    if (controller.state.alignmentMode != AlignmentMode.guideline) {
      return const SizedBox.shrink();
    }

    final pageSize = ElementUtils.calculatePixelSize(currentPage);
    final scale = transformationController.value.getMaxScaleOnAxis();

    // 创建视口边界用于优化渲染
    final viewportBounds = Rect.fromLTWH(0, 0, pageSize.width, pageSize.height);

    EditPageLogger.editPageDebug('构建参考线层', data: {
      'activeGuidelines': activeGuidelines.length,
      'scale': scale,
      'pageSize': '${pageSize.width}x${pageSize.height}',
      'operation': 'build_guideline_layer',
    });

    return RepaintBoundary(
      child: GuidelineLayer(
        guidelines: activeGuidelines,
        canvasSize: pageSize,
        scale: scale,
        viewportBounds: viewportBounds,
      ),
    );
  }

  /// 🚀 优化的交互层构建方法 - 独立监听选择状态变化
  Widget buildInteractionLayer(LayerConfig config) {
    if (!config.shouldRender || isPreviewMode) {
      return const SizedBox.shrink();
    }

    EditPageLogger.canvasDebug(
      '构建交互层（优化版）',
      data: {
        'optimization': 'independent_interaction_layer',
        'avoidCanvasRebuild': true,
      },
    );

    // 🚀 使用智能监听器构建独立的交互层
    return _SmartInteractionLayer(
      controller: controller,
      transformationController: transformationController,
      selectionBoxNotifier: selectionBoxNotifier,
      dragStateManager: dragStateManager,
      onControlPointUpdate: handleControlPointUpdate,
      onControlPointDragEnd: handleControlPointDragEnd,
      onControlPointDragStart: handleControlPointDragStart,
      onControlPointDragEndWithState: handleControlPointDragEndWithState,
    );
  }

  /// 构建指定类型的层级Widget
  Widget buildLayerWidget(RenderLayerType layerType, LayerConfig config) {
    switch (layerType) {
      case RenderLayerType.staticBackground:
        return buildBackgroundLayer(config);
      case RenderLayerType.content:
        return buildContentLayer(config);
      case RenderLayerType.dragPreview:
        return buildDragPreviewLayer(config);
      case RenderLayerType.interaction:
        return buildInteractionLayer(config);
      case RenderLayerType.guideline:
        return buildGuidelineLayer(config);
      case RenderLayerType.uiOverlay:
        return buildUIOverlayLayer(config);
    }
  }

  /// 构建UI覆盖层（暂时未使用）
  Widget buildUIOverlayLayer(LayerConfig config) {
    return const SizedBox.shrink();
  }

  void dispose() {
    // 清理资源
    AppLogger.debug('画布图层构建器销毁', tag: 'Canvas');
    // 🔧 注意：mixin不能调用super.dispose()，这是正常的
    // dispose链将由主类的super.dispose()调用处理
  }

  void handleControlPointDragEnd(int controlPointIndex);

  void handleControlPointDragEndWithState(
      int controlPointIndex, Map<String, double> finalState);

  void handleControlPointDragStart(int controlPointIndex);

  /// 控制点事件处理方法（由使用此mixin的类实现）
  void handleControlPointUpdate(int controlPointIndex, Offset delta);

  /// 计算适合背景色的网格颜色
  Color _getGridColor(Color backgroundColor, BuildContext context) {
    // 计算背景亮度
    final brightness = backgroundColor.computeLuminance();

    // 根据背景亮度选择对比度合适的网格颜色
    Color gridColor;
    if (brightness > 0.5) {
      // 亮色背景使用优雅的灰色网格
      gridColor = const Color(0xFF90A4AE).withValues(alpha: 0.4); // 蓝灰色，更优雅
    } else {
      // 深色背景使用淡白色网格
      gridColor = Colors.white.withValues(alpha: 0.25); // 降低透明度，更柔和
    }

    EditPageLogger.canvasDebug('网格颜色计算',
        data: {'brightness': brightness, 'gridColor': '$gridColor'});
    return gridColor;
  }
}

/// 选择框绘制器
class SelectionBoxPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Color color;

  SelectionBoxPainter({
    required this.startPoint,
    required this.endPoint,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 创建选择框的矩形
    final rect = Rect.fromPoints(startPoint, endPoint);

    // 创建虚线效果的画笔
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 绘制选择框
    canvas.drawRect(rect, paint);

    // 添加半透明填充
    final fillPaint = Paint()
      ..color = color.withValues(alpha: .1)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, fillPaint);
  }

  @override
  bool shouldRepaint(SelectionBoxPainter oldDelegate) {
    return startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint ||
        color != oldDelegate.color;
  }
}

/// 🚀 独立的智能交互层组件
/// 直接监听智能状态分发器，不依赖Canvas重建
class _SmartInteractionLayer extends StatefulWidget {
  final PracticeEditController controller;
  final TransformationController transformationController;
  final ValueNotifier<SelectionBoxState> selectionBoxNotifier;
  final DragStateManager dragStateManager;
  final Function(int, Offset) onControlPointUpdate;
  final Function(int) onControlPointDragEnd;
  final Function(int) onControlPointDragStart;
  final Function(int, Map<String, double>) onControlPointDragEndWithState;

  const _SmartInteractionLayer({
    required this.controller,
    required this.transformationController,
    required this.selectionBoxNotifier,
    required this.dragStateManager,
    required this.onControlPointUpdate,
    required this.onControlPointDragEnd,
    required this.onControlPointDragStart,
    required this.onControlPointDragEndWithState,
  });

  @override
  State<_SmartInteractionLayer> createState() => _SmartInteractionLayerState();
}

class _SmartInteractionLayerState extends State<_SmartInteractionLayer> {
  // 🚀 使用ValueNotifier代替直接状态变量，避免setState触发Canvas重建
  late ValueNotifier<Set<String>> _selectedElementIdsNotifier;
  late ValueNotifier<String> _currentToolNotifier;
  bool _isRegistered = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: _selectedElementIdsNotifier,
      builder: (context, selectedElementIds, child) {
        return ValueListenableBuilder<String>(
          valueListenable: _currentToolNotifier,
          builder: (context, currentTool, child) {
            EditPageLogger.canvasDebug(
              '智能交互层重建（ValueNotifier驱动）',
              data: {
                'selectedCount': selectedElementIds.length,
                'currentTool': currentTool,
                'optimization': 'valuenotifier_driven_rebuild',
                'avoidedCanvasRebuild': true,
              },
            );

            // 获取选中元素的控制点信息
            String? selectedElementId;
            double x = 0, y = 0, width = 0, height = 0, rotation = 0;
            final elements = widget.controller.state.currentPageElements;

            if (selectedElementIds.length == 1) {
              selectedElementId = selectedElementIds.first;
              final selectedElement = elements.firstWhere(
                (e) => e['id'] == selectedElementId,
                orElse: () => <String, dynamic>{},
              );

              if (selectedElement.isNotEmpty) {
                x = (selectedElement['x'] as num?)?.toDouble() ?? 0.0;
                y = (selectedElement['y'] as num?)?.toDouble() ?? 0.0;
                width = (selectedElement['width'] as num?)?.toDouble() ?? 0.0;
                height = (selectedElement['height'] as num?)?.toDouble() ?? 0.0;
                rotation =
                    (selectedElement['rotation'] as num?)?.toDouble() ?? 0.0;
              }
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                // 选择框
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      key: const ValueKey('selection_box_repaint_boundary'),
                      child: ValueListenableBuilder<SelectionBoxState>(
                        valueListenable: widget.selectionBoxNotifier,
                        builder: (context, selectionBoxState, child) {
                          if (currentTool == 'select' &&
                              selectionBoxState.isActive &&
                              selectionBoxState.startPoint != null &&
                              selectionBoxState.endPoint != null) {
                            return CustomPaint(
                              size: Size.infinite,
                              painter: SelectionBoxPainter(
                                startPoint: selectionBoxState.startPoint!,
                                endPoint: selectionBoxState.endPoint!,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),

                // 多选元素高亮显示
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      key: ValueKey(
                          'selected_elements_highlight_${selectedElementIds.length}_${selectedElementIds.hashCode}'),
                      child: SelectedElementsHighlight(
                        elements: elements,
                        selectedElementIds: selectedElementIds,
                        canvasScale: widget.transformationController.value
                            .getMaxScaleOnAxis(),
                        primaryColor: Theme.of(context).colorScheme.primary,
                        secondaryColor: Theme.of(context).colorScheme.outline,
                        dragStateManager: widget.dragStateManager,
                      ),
                    ),
                  ),
                ),

                // 控制点
                if (selectedElementId != null)
                  Positioned.fill(
                    child: _buildControlPoints(
                        selectedElementId, x, y, width, height, rotation),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _unregisterFromIntelligentDispatcher();
    _selectedElementIdsNotifier.dispose();
    _currentToolNotifier.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _selectedElementIdsNotifier =
        ValueNotifier(widget.controller.state.selectedElementIds.toSet());
    _currentToolNotifier = ValueNotifier(widget.controller.state.currentTool);
    _registerToIntelligentDispatcher();
  }

  /// 构建控制点
  Widget _buildControlPoints(
    String elementId,
    double x,
    double y,
    double width,
    double height,
    double rotation,
  ) {
    // 使用绝对定位确保控制点始终可见
    return AbsorbPointer(
      absorbing: false,
      child: GestureDetector(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // 透明覆盖层确保控制点接收事件
              Positioned.fill(
                child: Container(
                  color: Colors.transparent,
                ),
              ),
              // 实际控制点
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                bottom: 0,
                child: RepaintBoundary(
                  key: ValueKey(
                      'control_points_repaint_${elementId}_${(x * 1000).toInt()}_${(y * 1000).toInt()}_${(width * 100).toInt()}_${(height * 100).toInt()}'),
                  child: Builder(builder: (context) {
                    // 获取当前缩放值
                    final scale = widget.transformationController.value
                        .getMaxScaleOnAxis();

                    // 检查是否正在拖拽并使用预览位置更新控制点
                    final isElementBeingDragged = widget
                            .dragStateManager.isDragging &&
                        widget.dragStateManager.isElementDragging(elementId);

                    double displayX = x;
                    double displayY = y;
                    double displayWidth = width;
                    double displayHeight = height;
                    double displayRotation = rotation;

                    if (isElementBeingDragged) {
                      // 获取预览属性
                      final previewProperties = widget.dragStateManager
                          .getElementPreviewProperties(elementId);
                      if (previewProperties != null) {
                        displayX =
                            (previewProperties['x'] as num?)?.toDouble() ?? x;
                        displayY =
                            (previewProperties['y'] as num?)?.toDouble() ?? y;
                        displayWidth =
                            (previewProperties['width'] as num?)?.toDouble() ??
                                width;
                        displayHeight =
                            (previewProperties['height'] as num?)?.toDouble() ??
                                height;
                        displayRotation =
                            (previewProperties['rotation'] as num?)
                                    ?.toDouble() ??
                                rotation;
                      } else {
                        final previewPosition = widget.dragStateManager
                            .getElementPreviewPosition(elementId);
                        if (previewPosition != null) {
                          displayX = previewPosition.dx;
                          displayY = previewPosition.dy;
                        }
                      }
                    }

                    return FreeControlPoints(
                      key: ValueKey(
                          'control_points_${elementId}_${scale.toStringAsFixed(2)}_${displayX.toInt()}_${displayY.toInt()}'),
                      elementId: elementId,
                      x: displayX,
                      y: displayY,
                      width: displayWidth,
                      height: displayHeight,
                      rotation: displayRotation,
                      initialScale: scale,
                      onControlPointUpdate: widget.onControlPointUpdate,
                      onControlPointDragEnd: widget.onControlPointDragEnd,
                      onControlPointDragStart: widget.onControlPointDragStart,
                      onControlPointDragEndWithState:
                          widget.onControlPointDragEndWithState,
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🚀 注册到智能状态分发器，独立监听选择状态变化
  void _registerToIntelligentDispatcher() {
    final intelligentDispatcher = widget.controller.intelligentDispatcher;
    if (intelligentDispatcher != null && !_isRegistered) {
      // 注册为交互层监听器
      intelligentDispatcher.registerLayerListener('interaction', () {
        if (mounted) {
          // 🚀 使用ValueNotifier更新，避免setState触发Canvas重建
          final newSelectedIds =
              widget.controller.state.selectedElementIds.toSet();
          final newTool = widget.controller.state.currentTool;

          if (_selectedElementIdsNotifier.value != newSelectedIds) {
            _selectedElementIdsNotifier.value = newSelectedIds;
          }

          if (_currentToolNotifier.value != newTool) {
            _currentToolNotifier.value = newTool;
          }

          EditPageLogger.canvasDebug(
            '交互层独立状态更新（无Canvas重建）',
            data: {
              'selectedCount': newSelectedIds.length,
              'currentTool': newTool,
              'optimization': 'valuenotifier_based_interaction_update',
              'avoidedCanvasRebuild': true,
            },
          );
        }
      });

      _isRegistered = true;

      EditPageLogger.canvasDebug(
        '智能交互层已注册监听器（优化版）',
        data: {
          'optimization': 'independent_interaction_monitoring_optimized',
        },
      );
    }
  }

  /// 注销智能状态分发器监听
  void _unregisterFromIntelligentDispatcher() {
    // 注意：当前智能状态分发器的实现可能不支持注销单个监听器
    // 这里只是标记为未注册
    _isRegistered = false;
  }
}
