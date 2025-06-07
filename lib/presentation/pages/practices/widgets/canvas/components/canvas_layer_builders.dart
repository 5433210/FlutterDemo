import 'package:flutter/material.dart';

import '../../../../../../infrastructure/logging/logger.dart';
import '../../../../../widgets/practice/practice_edit_controller.dart';
import '../../../../../widgets/practice/drag_state_manager.dart';
import '../../../helpers/element_utils.dart';
import '../../content_render_controller.dart';
import '../../content_render_layer.dart';
import '../../drag_preview_layer.dart';
import '../../selected_elements_highlight.dart';
import '../../layers/layer_types.dart';
import '../../free_control_points.dart';
import 'canvas_ui_components.dart';

/// 画布层级构建器
/// 负责构建画布中各个层级的Widget
mixin CanvasLayerBuilders {
  /// 获取控制器（由使用此mixin的类实现）
  PracticeEditController get controller;
  
  /// 获取拖拽状态管理器（由使用此mixin的类实现）
  DragStateManager get dragStateManager;
  
  /// 获取内容渲染控制器（由使用此mixin的类实现）
  ContentRenderController get contentRenderController;
  
  /// 获取选择框状态通知器（由使用此mixin的类实现）
  ValueNotifier<SelectionBoxState> get selectionBoxNotifier;
  
  /// 获取转换控制器（由使用此mixin的类实现）
  TransformationController get transformationController;
  
  /// 获取BuildContext（由使用此mixin的类实现）
  BuildContext get context;
  
  /// 获取是否预览模式（由使用此mixin的类实现）
  bool get isPreviewMode;
  
  /// 控制点事件处理方法（由使用此mixin的类实现）
  void handleControlPointUpdate(int controlPointIndex, Offset delta);
  void handleControlPointDragEnd(int controlPointIndex);
  void handleControlPointDragStart(int controlPointIndex);
  void handleControlPointDragEndWithState(int controlPointIndex, Map<String, double> finalState);

  /// 构建背景层（网格、页面背景）
  Widget buildBackgroundLayer(LayerConfig config) {
    final currentPage = controller.state.currentPage;
    if (currentPage == null) return const SizedBox.shrink();

    AppLogger.debug(
      '构建背景层',
      tag: 'Canvas',
      data: {'hasGrid': controller.state.gridVisible},
    );

    return Container(
      decoration: BoxDecoration(
        color: Color(currentPage['backgroundColor'] as int? ?? Colors.white.value),
      ),
      child: controller.state.gridVisible
          ? CustomPaint(
              painter: CanvasGridPainter(
                gridSize: controller.state.gridSize,
                gridColor: Theme.of(context).colorScheme.outline.withValues(alpha: .3),
              ),
              child: Container(),
            )
          : null,
    );
  }

  /// 构建内容层（元素渲染）
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

  /// 构建拖拽预览层
  Widget buildDragPreviewLayer(LayerConfig config) {
    if (!config.shouldRender || !CanvasDragConfig.enableDragPreview || isPreviewMode) {
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

  /// 构建交互层（选择框、控制点）
  Widget buildInteractionLayer(LayerConfig config) {
    if (!config.shouldRender || isPreviewMode) {
      return const SizedBox.shrink();
    }

    AppLogger.debug(
      '构建交互层',
      tag: 'Canvas',
      data: {
        'hasSelection': controller.state.selectedElementIds.isNotEmpty,
        'currentTool': controller.state.currentTool,
      },
    );

    // 获取选中元素的控制点信息
    String? selectedElementId;
    double x = 0, y = 0, width = 0, height = 0, rotation = 0;
    final elements = controller.state.currentPageElements;

    if (controller.state.selectedElementIds.length == 1) {
      selectedElementId = controller.state.selectedElementIds.first;
      final selectedElement = elements.firstWhere(
        (e) => e['id'] == selectedElementId,
        orElse: () => <String, dynamic>{},
      );

      if (selectedElement.isNotEmpty) {
        x = (selectedElement['x'] as num?)?.toDouble() ?? 0.0;
        y = (selectedElement['y'] as num?)?.toDouble() ?? 0.0;
        width = (selectedElement['width'] as num?)?.toDouble() ?? 0.0;
        height = (selectedElement['height'] as num?)?.toDouble() ?? 0.0;
        rotation = (selectedElement['rotation'] as num?)?.toDouble() ?? 0.0;
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
                valueListenable: selectionBoxNotifier,
                builder: (context, selectionBoxState, child) {
                  if (controller.state.currentTool == 'select' &&
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
                  'selected_elements_highlight_${controller.state.selectedElementIds.length}_${controller.state.selectedElementIds.hashCode}'),
              child: SelectedElementsHighlight(
                elements: elements,
                selectedElementIds: controller.state.selectedElementIds.toSet(),
                canvasScale: transformationController.value.getMaxScaleOnAxis(),
                primaryColor: Theme.of(context).colorScheme.primary,
                secondaryColor: Theme.of(context).colorScheme.outline,
                dragStateManager: dragStateManager,
              ),
            ),
          ),
        ),

        // 控制点
        if (selectedElementId != null)
          Positioned.fill(
            child: buildControlPoints(selectedElementId, x, y, width, height, rotation),
          ),
      ],
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
    AppLogger.debug(
      '构建控制点',
      tag: 'Canvas',
      data: {
        'elementId': elementId,
        'position': '($x, $y)',
        'size': '${width}x$height',
        'rotation': rotation,
      },
    );

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
                    final scale = transformationController.value.getMaxScaleOnAxis();
                    
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
                      final previewProperties = dragStateManager.getElementPreviewProperties(elementId);
                      if (previewProperties != null) {
                        // 使用完整的预览属性
                        displayX = (previewProperties['x'] as num?)?.toDouble() ?? x;
                        displayY = (previewProperties['y'] as num?)?.toDouble() ?? y;
                        displayWidth = (previewProperties['width'] as num?)?.toDouble() ?? width;
                        displayHeight = (previewProperties['height'] as num?)?.toDouble() ?? height;
                        displayRotation = (previewProperties['rotation'] as num?)?.toDouble() ?? rotation;
                        
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
                        final previewPosition = dragStateManager.getElementPreviewPosition(elementId);
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
                      onControlPointDragEndWithState: handleControlPointDragEndWithState,
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

  /// 构建UI覆盖层（暂时未使用）
  Widget buildUIOverlayLayer(LayerConfig config) {
    return const SizedBox.shrink();
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
      case RenderLayerType.uiOverlay:
        return buildUIOverlayLayer(config);
    }
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

/// 拖拽配置
class CanvasDragConfig {
  static bool enableDragPreview = true;
  static bool showPerformanceOverlay = false;
} 