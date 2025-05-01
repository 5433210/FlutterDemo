import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../../../widgets/practice/element_renderers.dart';
import '../../../widgets/practice/practice_edit_controller.dart';
import '../helpers/element_utils.dart';
import 'canvas_control_points.dart';
import 'canvas_gesture_handler.dart';

/// Canvas widget for practice editing
class PracticeEditCanvas extends ConsumerStatefulWidget {
  final PracticeEditController controller;
  final bool isPreviewMode;
  final GlobalKey canvasKey;
  final TransformationController transformationController;

  const PracticeEditCanvas({
    Key? key,
    required this.controller,
    required this.isPreviewMode,
    required this.canvasKey,
    required this.transformationController,
  }) : super(key: key);

  @override
  ConsumerState<PracticeEditCanvas> createState() => _PracticeEditCanvasState();
}

/// Grid painter for showing grid lines on the canvas
class _GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;

  _GridPainter({
    required this.gridSize,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    // Draw vertical grid lines
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal grid lines
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor;
  }
}

class _PracticeEditCanvasState extends ConsumerState<PracticeEditCanvas> {
  // Drag state variables
  bool _isDragging = false;
  Offset _dragStart = Offset.zero;
  Offset _elementStartPosition = Offset.zero;
  final Map<String, Offset> _elementStartPositions = {};

  // Canvas gesture handler
  late CanvasGestureHandler _gestureHandler;

  @override
  Widget build(BuildContext context) {
    if (widget.controller.state.pages.isEmpty) {
      return const Center(child: Text('No pages available'));
    }

    final currentPage = widget.controller.state.currentPage;
    if (currentPage == null) {
      return const Center(child: Text('Current page does not exist'));
    }

    final elements = widget.controller.state.currentPageElements;
    return _buildCanvas(currentPage, elements);
  }

  @override
  void initState() {
    super.initState();

    // 初始化缩放监听
    widget.transformationController.addListener(_handleTransformationChange);

    // Initialize gesture handler
    _gestureHandler = CanvasGestureHandler(
      controller: widget.controller,
      onDragStart: (isDragging, dragStart, elementPosition, elementPositions) {
        setState(() {
          _isDragging = isDragging;
          _dragStart = dragStart;
          _elementStartPosition = elementPosition;
          _elementStartPositions.clear();
          _elementStartPositions.addAll(elementPositions);
        });
      },
      onDragUpdate: () {
        setState(() {
          // 如果不是在拖拽元素，则处理画布平移
          if (!_isDragging) {
            // 计算拖拽偏移量
            final dx = _elementStartPosition.dx;
            final dy = _elementStartPosition.dy;

            // 如果偏移量太小，可能不会有明显的平移效果
            if (dx.abs() < 0.01 && dy.abs() < 0.01) {
              debugPrint('【平移】onDragUpdate: 偏移量太小，跳过平移');
              return;
            }

            // 创建新的变换矩阵
            final Matrix4 newMatrix = Matrix4.identity();

            // 设置与当前相同的缩放因子
            final scale =
                widget.transformationController.value.getMaxScaleOnAxis();
            newMatrix.setEntry(0, 0, scale);
            newMatrix.setEntry(1, 1, scale);
            newMatrix.setEntry(2, 2, scale);

            // 获取当前平移值
            final Vector3 translation =
                widget.transformationController.value.getTranslation();

            // 设置新的平移值
            newMatrix.setTranslation(Vector3(
              translation.x + dx,
              translation.y + dy,
              0.0,
            ));

            // 应用新变换
            final oldMatrix = widget.transformationController.value;
            widget.transformationController.value = newMatrix;

            // 检查变换是否真的改变了
            if (oldMatrix == widget.transformationController.value) {
              // debugPrint('【平移】onDragUpdate: 警告 - 变换矩阵没有改变！');
            }
          } else {
            // debugPrint('【平移】onDragUpdate: 正在拖拽元素，不处理平移');
          }
        });
      },
      onDragEnd: () {
        debugPrint('【平移】onDragEnd: 被调用，当前_isDragging=$_isDragging');

        setState(() {
          _isDragging = false;
          debugPrint('【平移】onDragEnd: 状态更新后，_isDragging=$_isDragging');
        });
      },
    );
  }

  /// Build the main canvas
  Widget _buildCanvas(
      Map<String, dynamic> currentPage, List<dynamic> elements) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        // Handle dropping new elements onto the canvas
        final RenderBox renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);

        // Calculate page dimensions
        final pageWidth = (currentPage['width'] as num?)?.toDouble() ?? 842.0;
        final pageHeight = (currentPage['height'] as num?)?.toDouble() ?? 595.0;

        // Ensure coordinates are within page boundaries
        double x = localPosition.dx.clamp(0.0, pageWidth);
        double y = localPosition.dy.clamp(0.0, pageHeight);

        // Add element based on dragged type
        switch (details.data) {
          case 'text':
            widget.controller.addTextElementAt(x, y);
            break;
          case 'image':
            widget.controller.addEmptyImageElementAt(x, y);
            break;
          case 'collection':
            widget.controller.addEmptyCollectionElementAt(x, y);
            break;
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: Colors.grey.shade800, // 画布外部的暗色背景，提供更好的对比度
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            panEnabled: widget.isPreviewMode ||
                !_isDragging, // 预览模式下始终启用平移，编辑模式下拖拽元素时禁用
            scaleEnabled: true,
            minScale: 0.1,
            maxScale: 15.0,
            scaleFactor: 200.0, // 增大缩放因子，减小缩放幅度
            transformationController: widget.transformationController,
            onInteractionStart: (ScaleStartDetails details) {},
            onInteractionUpdate: (ScaleUpdateDetails details) {},
            onInteractionEnd: (ScaleEndDetails details) {
              // 更新最终的缩放值
              final scale =
                  widget.transformationController.value.getMaxScaleOnAxis();
              widget.controller.zoomTo(scale);
            },
            constrained: false, // 添加这一行，使内容不受约束
            child: GestureDetector(
              behavior: HitTestBehavior.translucent, // 确保手势事件能够正确传递
              onTapUp: (details) => _gestureHandler.handleTapUp(
                  details, elements.cast<Map<String, dynamic>>()),
              onSecondaryTapUp: (details) =>
                  _gestureHandler.handleSecondaryTapUp(
                      details, elements.cast<Map<String, dynamic>>()),
              onPanStart: (details) => _gestureHandler.handlePanStart(
                  details, elements.cast<Map<String, dynamic>>()),
              onPanUpdate: (details) {
                // 如果不是在拖拽元素且不是在预览模式，直接处理平移
                if (!_isDragging && !widget.isPreviewMode) {
                  // 创建新的变换矩阵
                  final Matrix4 newMatrix = Matrix4.identity();

                  // 设置与当前相同的缩放因子
                  final scale =
                      widget.transformationController.value.getMaxScaleOnAxis();
                  newMatrix.setEntry(0, 0, scale);
                  newMatrix.setEntry(1, 1, scale);
                  newMatrix.setEntry(2, 2, scale);

                  // 获取当前平移值
                  final Vector3 translation =
                      widget.transformationController.value.getTranslation();

                  // 设置新的平移值
                  newMatrix.setTranslation(Vector3(
                    translation.x + details.delta.dx,
                    translation.y + details.delta.dy,
                    0.0,
                  ));

                  widget.transformationController.value = newMatrix;

                  // 强制刷新
                  setState(() {});
                }

                // 调用原来的 handlePanUpdate
                _gestureHandler.handlePanUpdate(details);
              },
              onPanEnd: (details) => _gestureHandler.handlePanEnd(details),
              child: _buildPageContent(
                  currentPage, elements.cast<Map<String, dynamic>>()),
            ),
          ),
        );
      },
    );
  }

  /// Build an element widget
  Widget _buildElementWidget(Map<String, dynamic> element) {
    final id = element['id'] as String;
    final type = element['type'] as String;
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num).toDouble();
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    // Check if element is selected
    final isSelected = widget.controller.state.selectedElementIds.contains(id);

    // Check if element is locked or hidden
    final isLocked = element['locked'] == true;
    final isHidden = element['hidden'] == true;

    // Check if element's layer is locked or hidden
    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    bool isLayerHidden = false;
    double layerOpacity = 1.0;

    if (layerId != null) {
      final layer = widget.controller.state.getLayerById(layerId);
      if (layer != null) {
        isLayerLocked = layer['isLocked'] == true;
        isLayerHidden =
            layer['isVisible'] == false; // isVisible=false means hidden
        layerOpacity = (layer['opacity'] as num?)?.toDouble() ?? 1.0;
      }
    }

    // Build element content based on type
    Widget content;
    switch (type) {
      case 'text':
        content = ElementRenderers.buildTextElement(element,
            isPreviewMode: widget.isPreviewMode);
        break;
      case 'image':
        content = ElementRenderers.buildImageElement(element,
            isPreviewMode: widget.isPreviewMode);
        break;
      case 'collection':
        // 确保传递ref参数，这样集字元素才能加载字符图片
        content = ElementRenderers.buildCollectionElement(
          element,
          ref: ref, // 传递ConsumerState中的ref
          isPreviewMode: widget.isPreviewMode,
        );

        break;
      case 'group':
        content = ElementRenderers.buildGroupElement(
          element,
          isSelected: isSelected,
          ref: ref,
          isPreviewMode: widget.isPreviewMode,
        );
        break;
      default:
        content = Container(
          color: Colors.grey.withAlpha(51), // 0.2 opacity = 51/255
          child: const Center(child: Text('Unknown element type')),
        );
    }

    // 创建一个包含元素的Stack
    return Stack(
      clipBehavior: Clip.none, // 允许子元素超出边界
      children: [
        // 元素本身
        Positioned(
          left: x,
          top: y,
          child: Transform.rotate(
            angle: rotation * 3.1415926 / 180,
            alignment: Alignment.center,
            child: SizedBox(
              width: width,
              height: height,
              child: Opacity(
                // Apply element and layer opacity
                opacity: isHidden || isLayerHidden
                    ? (widget.isPreviewMode ? 0.0 : 0.5)
                    : opacity * layerOpacity,
                child: MouseRegion(
                  // 当鼠标悬停在元素上时，显示移动光标
                  cursor: isSelected
                      ? SystemMouseCursors.move
                      : SystemMouseCursors.basic,
                  onEnter: (_) {},
                  onHover: (_) {},
                  child: Container(
                    width: width,
                    height: height,
                    decoration: widget.isPreviewMode
                        ? null
                        : BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                          ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Element content
                        content,

                        // Lock icon (if element or layer is locked)
                        if ((isLocked || isLayerLocked) &&
                            !widget.isPreviewMode)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withAlpha(179), // 0.7 opacity = 179/255
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  /// Build the page content
  Widget _buildPageContent(
      Map<String, dynamic> page, List<Map<String, dynamic>> elements) {
    // Calculate page dimensions
    final Size pageSize = ElementUtils.calculatePixelSize(page);

    // 获取页面背景颜色
    final backgroundColor = _getPageBackgroundColor(page);

    // 添加调试信息
    // debugPrint(
    //     '【页面内容】构建页面内容: 尺寸=${pageSize.width}x${pageSize.height}, 背景颜色=$backgroundColor');

    return Stack(
      children: [
        // Page background
        Container(
          width: pageSize.width,
          height: pageSize.height,
          color: backgroundColor,
          child: RepaintBoundary(
            key: widget.canvasKey,
            child: AbsorbPointer(
              absorbing: false, // 确保控制点可以接收事件
              child: Stack(
                children: [
                  // 背景层 - 确保背景颜色正确应用
                  Container(
                    width: pageSize.width,
                    height: pageSize.height,
                    color: backgroundColor,
                  ),

                  // Grid (if visible and not in preview mode)
                  if (widget.controller.state.gridVisible &&
                      !widget.isPreviewMode)
                    CustomPaint(
                      size: Size(pageSize.width, pageSize.height),
                      painter: _GridPainter(
                        gridSize: widget.controller.state.gridSize,
                        gridColor:
                            Colors.grey.withAlpha(77), // 0.3 opacity = 77/255
                      ),
                    ),

                  // 渲染所有元素
                  ClipRect(
                    child: Stack(
                      clipBehavior: Clip.hardEdge, // 不允许子元素超出边界
                      children: ElementUtils.sortElementsByLayerOrder(
                              elements, widget.controller.state.layers)
                          .map((element) => _buildElementWidget(element))
                          .toList(),
                    ),
                  ),

                  // 单独渲染控制点，确保它们在最上层
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: false, // 确保控制点可以接收事件
                      child: Builder(builder: (context) {
                        if (!widget.isPreviewMode &&
                            widget.controller.state.selectedElementIds.length ==
                                1) {
                          return _buildSelectedElementControlPoints();
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                    ),
                  ),

                  // 拖拽指示
                  if (_isDragging)
                    Container(
                      width: pageSize.width,
                      height: pageSize.height,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.blue,
                          width: 1,
                          style: BorderStyle.solid,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建选中元素的控制点
  Widget _buildSelectedElementControlPoints() {
    final elementId = widget.controller.state.selectedElementIds.first;
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return const SizedBox.shrink();
    }

    // 获取元素属性
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num).toDouble();
    final isLocked = element['locked'] == true;

    // 获取元素所在图层
    final layerId = element['layerId'] as String?;
    final layer = widget.controller.state.layers.firstWhere(
      (l) => l['id'] == layerId,
      orElse: () => <String, dynamic>{},
    );
    final isLayerLocked = layer.isNotEmpty && layer['locked'] == true;

    // 如果元素或图层被锁定，不显示控制点
    if (isLocked || isLayerLocked) {
      return const SizedBox.shrink();
    }

    // 使用绝对定位的控制点，确保它们始终可见
    return AbsorbPointer(
        absorbing: false, // 确保控制点可以接收事件
        // 添加调试日志
        child: GestureDetector(
          onTapDown: (details) {},
          onTap: () {
            // 点击控制点容器的空白区域时，取消选择

            widget.controller.clearSelection();
          },
          behavior: HitTestBehavior.translucent, // 确保即使点击透明区域也能接收事件
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent, // 透明背景
            child: Stack(
              children: [
                // 元素边框 - 使用绝对定位
                // Positioned(
                //   left: x,
                //   top: y,
                //   width: width,
                //   height: height,
                //   child: Transform.rotate(
                //     angle: rotation * 3.1415926 / 180,
                //     alignment: Alignment.center,
                //     child: Container(
                //       decoration: BoxDecoration(
                //         border: Border.all(color: Colors.red, width: 3),
                //         color: Colors.red.withAlpha(30),
                //       ),
                //     ),
                //   ),
                // ),

                // 实际的控制点 - 使用绝对定位
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: RepaintBoundary(
                    child: CanvasControlPoints(
                      key: ValueKey('control_points_$elementId'),
                      elementId: elementId,
                      x: x,
                      y: y,
                      width: width,
                      height: height,
                      rotation: rotation,
                      onControlPointUpdate: _handleControlPointUpdate,
                    ),
                  ),
                ),

                // 添加一个透明的覆盖层，确保控制点能够立即响应事件
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: true, // 忽略指针事件，让下层控制点接收事件
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  /// 获取页面背景颜色
  Color _getPageBackgroundColor(Map<String, dynamic> page) {
    // 首先尝试使用新格式的背景设置
    if (page.containsKey('background') &&
        page['background'] is Map<String, dynamic>) {
      final background = page['background'] as Map<String, dynamic>;
      final type = background['type'] as String? ?? 'color';
      final value = background['value'] as String? ?? '#FFFFFF';
      final opacity = (background['opacity'] as num?)?.toDouble() ?? 1.0;

      if (type == 'color' && value.isNotEmpty) {
        try {
          // 处理带#前缀的颜色代码
          final colorStr = value.startsWith('#') ? value.substring(1) : value;

          // 确保颜色格式正确
          if (colorStr.length < 6) {
            return Colors.white; // 无效的颜色格式
          }

          // 添加FF前缀表示完全不透明
          final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;

          // 解析颜色
          final baseColor = Color(int.parse(fullColorStr, radix: 16));

          // 应用透明度
          final alpha = (opacity * 255).round();
          final finalColor = baseColor.withAlpha(alpha);

          return finalColor;
        } catch (e) {
          // 解析失败，使用默认颜色
        }
      }
    }

    // 如果新格式不可用，尝试使用旧格式
    final backgroundColor = page['backgroundColor'] as String?;
    final backgroundOpacity =
        (page['backgroundOpacity'] as num?)?.toDouble() ?? 1.0;

    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      try {
        // 处理带#前缀的颜色代码
        final colorStr = backgroundColor.startsWith('#')
            ? backgroundColor.substring(1)
            : backgroundColor;

        // 添加FF前缀表示完全不透明
        final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;

        // 解析颜色
        final baseColor = Color(int.parse(fullColorStr, radix: 16));

        // 应用透明度
        final alpha = (backgroundOpacity * 255).round();
        final finalColor = baseColor.withAlpha(alpha);

        return finalColor;
      } catch (e) {
        // 解析失败，使用默认颜色
      }
    }

    return Colors.white; // 默认白色背景
  }

  /// Handle control point updates
  void _handleControlPointUpdate(int controlPointIndex, Offset delta) {
    // 添加更多调试信息，帮助理解控制点的行为
    final scale = widget.transformationController.value.getMaxScaleOnAxis();

    // 根据当前缩放比例调整偏移量
    final adjustedDelta = Offset(delta.dx / scale, delta.dy / scale);

    // 使用调整后的偏移量
    delta = adjustedDelta;

    if (widget.controller.state.selectedElementIds.isEmpty) {
      return;
    }

    final elementId = widget.controller.state.selectedElementIds.first;

    // 获取元素的当前属性
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // 打印元素的当前属性
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final rotation = (element['rotation'] as num).toDouble();
    final isLocked = element['locked'] == true;

    // 检查元素所在图层是否锁定
    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    if (layerId != null) {
      final layer = widget.controller.state.layers.firstWhere(
        (l) => l['id'] == layerId,
        orElse: () => <String, dynamic>{},
      );
      isLayerLocked = layer.isNotEmpty && layer['locked'] == true;
    }

    // 如果元素或图层被锁定，不允许修改大小或旋转
    if (isLocked || isLayerLocked) {
      return;
    }

    try {
      // 直接处理控制点更新，不使用 Future.microtask
      // 这样可以确保控制点的事件立即得到处理
      if (controlPointIndex == 8) {
        // Rotation control point

        _handleRotation(elementId, delta);
      } else {
        // Resize control point

        _handleResize(elementId, controlPointIndex, delta);
      }
    } catch (e) {
      debugPrint('【控制点】_handleControlPointUpdate: 处理失败: $e');
    }
  }

  /// Handle element resize
  void _handleResize(String elementId, int controlPointIndex, Offset delta) {
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // Get current element properties
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final isLocked = element['locked'] == true;

    // 检查元素所在图层是否锁定
    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    if (layerId != null) {
      final layer = widget.controller.state.layers.firstWhere(
        (l) => l['id'] == layerId,
        orElse: () => <String, dynamic>{},
      );
      isLayerLocked = layer.isNotEmpty && layer['locked'] == true;
    }

    // 如果元素或图层被锁定，不允许修改大小
    if (isLocked || isLayerLocked) {
      return;
    }

    // Calculate new position and size based on control point
    double newX = x;
    double newY = y;
    double newWidth = width;
    double newHeight = height;

    // 打印控制点索引对应的位置
    final controlPointNames = [
      '左上角',
      '上中',
      '右上角',
      '右中',
      '右下角',
      '下中',
      '左下角',
      '左中',
      '旋转点'
    ];

    switch (controlPointIndex) {
      case 0: // Top-left

        newX = x + delta.dx;
        newY = y + delta.dy;
        newWidth = width - delta.dx;
        newHeight = height - delta.dy;
        break;
      case 1: // Top-center

        newY = y + delta.dy;
        newHeight = height - delta.dy;
        break;
      case 2: // Top-right

        newY = y + delta.dy;
        newWidth = width + delta.dx;
        newHeight = height - delta.dy;
        break;
      case 3: // Middle-right

        newWidth = width + delta.dx;
        break;
      case 4: // Bottom-right

        newWidth = width + delta.dx;
        newHeight = height + delta.dy;
        break;
      case 5: // Bottom-center

        newHeight = height + delta.dy;
        break;
      case 6: // Bottom-left

        newX = x + delta.dx;
        newWidth = width - delta.dx;
        newHeight = height + delta.dy;
        break;
      case 7: // Middle-left

        newX = x + delta.dx;
        newWidth = width - delta.dx;
        break;
    }

    // Ensure minimum size
    newWidth = newWidth.clamp(10.0, double.infinity);
    newHeight = newHeight.clamp(10.0, double.infinity);

    try {
      // Update element properties

      widget.controller.updateElementProperties(elementId, {
        'x': newX,
        'y': newY,
        'width': newWidth,
        'height': newHeight,
      });
    } catch (e) {
      debugPrint('【控制点】_handleResize: 更新元素属性失败: $e');
    }
  }

  /// Handle element rotation
  void _handleRotation(String elementId, Offset delta) {
    // This is a simplified implementation
    // A complete implementation would calculate rotation based on element center
    final element = widget.controller.state.currentPageElements.firstWhere(
      (e) => e['id'] == elementId,
      orElse: () => <String, dynamic>{},
    );

    if (element.isEmpty) {
      return;
    }

    // 获取元素的当前属性
    final x = (element['x'] as num).toDouble();
    final y = (element['y'] as num).toDouble();
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();
    final currentRotation = (element['rotation'] as num).toDouble();
    final isLocked = element['locked'] == true;

    // 检查元素所在图层是否锁定
    final layerId = element['layerId'] as String?;
    bool isLayerLocked = false;
    if (layerId != null) {
      final layer = widget.controller.state.layers.firstWhere(
        (l) => l['id'] == layerId,
        orElse: () => <String, dynamic>{},
      );
      isLayerLocked = layer.isNotEmpty && layer['locked'] == true;
    }

    // 如果元素或图层被锁定，不允许旋转
    if (isLocked || isLayerLocked) {
      return;
    }

    // 改进旋转实现，使用更合理的旋转计算方式
    // 水平移动影响更大，垂直移动影响较小
    final angleChange = delta.dx * 1.0 + delta.dy * 0.2;
    final newRotation = (currentRotation + angleChange) % 360;

    try {
      widget.controller.updateElementProperties(elementId, {
        'rotation': newRotation,
      });
    } catch (e) {
      debugPrint('【控制点】_handleRotation: 更新元素旋转属性失败: $e');
    }
  }

  /// 处理缩放变换
  void _handleTransformationChange() {
    final scale = widget.transformationController.value.getMaxScaleOnAxis();
    // final translation = widget.transformationController.value.getTranslation();

    widget.controller.zoomTo(scale);
  }
}
