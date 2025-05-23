import 'dart:math';

import 'package:flutter/material.dart';

import 'custom_cursors.dart';

/// 画布级别的控制点组件，直接在画布上渲染所有控制点
class CanvasControlPoints extends StatefulWidget {
  final String elementId;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double initialScale;
  final Function(int, Offset) onControlPointUpdate;
  final Function(int)? onControlPointDragEnd;

  const CanvasControlPoints({
    Key? key,
    required this.elementId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.onControlPointUpdate,
    this.onControlPointDragEnd,
    this.initialScale = 1.0,
  }) : super(key: key);

  @override
  State<CanvasControlPoints> createState() => _CanvasControlPointsState();
}

/// 绘制元素边框
class ElementBorderPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  ElementBorderPainter({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制半透明填充
    final fillPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    // 绘制边框
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 绘制元素边框 - 连接四个角点
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy); // 左上
    path.lineTo(points[2].dx, points[2].dy); // 右上
    path.lineTo(points[4].dx, points[4].dy); // 右下
    path.lineTo(points[6].dx, points[6].dy); // 左下
    path.close(); // 闭合路径

    // 先绘制填充
    canvas.drawPath(path, fillPaint);

    // 再绘制边框
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant ElementBorderPainter oldDelegate) {
    return points != oldDelegate.points ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

/// 绘制旋转控制点连接线
class RotationLinePainter extends CustomPainter {
  final double centerX;
  final double centerY;
  final double rotationX;
  final double rotationY;

  RotationLinePainter({
    required this.centerX,
    required this.centerY,
    required this.rotationX,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 使用更明显的颜色和更粗的线条
    final paint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.7) // 使用半透明的蓝色
      ..strokeWidth = 2.0 // 使用更细的线条
      ..style = PaintingStyle.stroke;

    // 绘制从元素中心到旋转控制点的连接线
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(rotationX, rotationY),
      paint,
    );

    // 在中心点绘制一个小圆点，使其更明显
    // 绘制中心点十字线
    final centerPaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 绘制水平线
    canvas.drawLine(
      Offset(centerX - 6, centerY),
      Offset(centerX + 6, centerY),
      centerPaint,
    );
    // 绘制垂直线
    canvas.drawLine(
      Offset(centerX, centerY - 6),
      Offset(centerX, centerY + 6),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RotationLinePainter oldDelegate) {
    return centerX != oldDelegate.centerX ||
        centerY != oldDelegate.centerY ||
        rotationX != oldDelegate.rotationX ||
        rotationY != oldDelegate.rotationY;
  }
}

class _CanvasControlPointsState extends State<CanvasControlPoints> {
  // 跟踪是否正在进行旋转操作
  bool _isRotating = false;
  // 添加变量跟踪累积偏移量和当前拖拽的控制点索引
  // final Map<int, Offset> _accumulatedDeltas = {};
  int? _currentDraggingPoint;

  // 获取当前缩放比例
  double get _currentScale {
    if (!mounted) {
      debugPrint('控制点未挂载，使用初始缩放比例: ${widget.initialScale}');
      return widget.initialScale;
    }

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      debugPrint('无法获取RenderBox，使用初始缩放比例: ${widget.initialScale}');
      return widget.initialScale;
    }

    try {
      final matrix = renderBox.getTransformTo(null);
      final scale = matrix.getMaxScaleOnAxis();
      debugPrint('从矩阵获取当前缩放比例: $scale');
      return scale;
    } catch (e) {
      debugPrint('获取缩放矩阵出错: $e，使用初始缩放比例: ${widget.initialScale}');
      return widget.initialScale;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算元素中心点
    final centerX = widget.x + widget.width / 2;
    final centerY = widget.y + widget.height / 2;

    // 计算旋转角度（弧度）
    final angle = widget.rotation * pi / 180; // 获取当前实际缩放比例
    final scale = _currentScale;

    // 调试信息
    debugPrint('控制点当前缩放比例: $scale，反向缩放系数: ${_getScaleFactor(scale)}');

    // 控制点基础大小和缩放后的大小
    const baseControlPointSize = 8.0;
    final scaleFactor = _getScaleFactor(scale);
    final controlPointSize = baseControlPointSize * scaleFactor;

    // 计算8个控制点的位置（考虑旋转和缩放）- 控制点在元素外部
    // 注意：这里的顺序必须与_handleResize方法中的case顺序一致
    final offset = (scale < 1.0 ? controlPointSize : baseControlPointSize) / 2;
    final unrotatedPoints = [
      // 索引0: 左上角
      Offset(widget.x - offset, widget.y - offset),
      // 索引1: 上中
      Offset(widget.x + widget.width / 2, widget.y - offset),
      // 索引2: 右上角
      Offset(widget.x + widget.width + offset, widget.y - offset),
      // 索引3: 右中
      Offset(widget.x + widget.width + offset, widget.y + widget.height / 2),
      // 索引4: 右下角
      Offset(
          widget.x + widget.width + offset, widget.y + widget.height + offset),
      // 索引5: 下中
      Offset(widget.x + widget.width / 2, widget.y + widget.height + offset),
      // 索引6: 左下角
      Offset(widget.x - offset, widget.y + widget.height + offset),
      // 索引7: 左中
      Offset(widget.x - offset, widget.y + widget.height / 2),
    ];

    // 对每个点进行旋转
    final points = unrotatedPoints
        .map((point) =>
            _rotatePoint(point.dx, point.dy, centerX, centerY, angle))
        .toList();

    // 使用当前缩放比例计算旋转点距离（减小距离使其更接近元素）
    final rotationDistance = 40.0 * _getScaleFactor(scale);
    final rotationPoint = _rotatePoint(
      centerX,
      widget.y - rotationDistance, // 上方距离根据缩放调整
      centerX,
      centerY,
      angle,
    );

    return Stack(
      clipBehavior: Clip.none, // 允许子元素超出边界
      children: [
        // 绘制元素边框
        CustomPaint(
          painter: ElementBorderPainter(
            points: points,
            color: Colors.blue,
            strokeWidth: 1.0,
          ),
          size: Size.infinite,
        ),

        // 绘制旋转控制点连接线
        CustomPaint(
          painter: _isRotating
              ? RotationLinePainter(
                  centerX: centerX,
                  centerY: centerY,
                  rotationX: rotationPoint.dx,
                  rotationY: rotationPoint.dy,
                )
              : null,
          size: Size.infinite,
        ),

        // 添加一个透明的覆盖层确保鼠标事件被正确捕获
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),

        // 左上角控制点
        _buildControlPoint(0, points[0], CustomCursors.resizeTopLeft),

        // 上中控制点
        _buildControlPoint(1, points[1], CustomCursors.resizeTop),

        // 右上角控制点
        _buildControlPoint(2, points[2], CustomCursors.resizeTopRight),

        // 右中控制点
        _buildControlPoint(3, points[3], CustomCursors.resizeRight),

        // 右下角控制点
        _buildControlPoint(4, points[4], CustomCursors.resizeBottomRight),

        // 下中控制点
        _buildControlPoint(5, points[5], CustomCursors.resizeBottom),

        // 左下角控制点
        _buildControlPoint(6, points[6], CustomCursors.resizeBottomLeft),

        // 左中控制点
        _buildControlPoint(7, points[7], CustomCursors.resizeLeft),

        // 旋转控制点 - 使用自定义旋转光标，位于元素中心
        _buildControlPoint(8, rotationPoint, CustomCursors.rotate,
            isRotation: true),
      ],
      // ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在依赖变化时（比如初始化或者缩放变化）强制更新控制点
    setState(() {});
  }

  @override
  void didUpdateWidget(CanvasControlPoints oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当控制点位置、大小或缩放比例发生变化时，记录日志并强制刷新
    if (oldWidget.x != widget.x ||
        oldWidget.y != widget.y ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.rotation != widget.rotation ||
        oldWidget.initialScale != widget.initialScale) {
      debugPrint(
          '控制点属性已更新: x=${widget.x}, y=${widget.y}, width=${widget.width}, height=${widget.height}, rotation=${widget.rotation}, scale=${widget.initialScale}');

      // 强制刷新控制点以适应新的缩放比例
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
  }

  /// 构建单个控制点
  Widget _buildControlPoint(int index, Offset position, MouseCursor cursor,
      {bool isRotation = false}) {
    // 获取当前缩放比例 - 每次构建控制点时重新获取最新的缩放比例
    final currentScale = _currentScale;

    // 根据缩放比例计算控制点大小
    const baseControlPointSize = 16.0;
    // 让感应区域与可视区域大小一致
    const baseHitAreaSize = baseControlPointSize;

    // 获取适当的缩放系数 - 当缩放比例小于1时需要反向放大控制点
    final scaleFactor = _getScaleFactor(currentScale);

    // 计算控制点和点击区域的最终大小
    final controlPointSize = baseControlPointSize * scaleFactor;
    final hitAreaSize = baseHitAreaSize * scaleFactor;

    debugPrint(
        '构建控制点 $index: 当前缩放=$currentScale, 缩放系数=$scaleFactor, 控制点大小=$controlPointSize, 点击区域=$hitAreaSize');

    // 计算点击区域位置
    final left = position.dx - hitAreaSize / 2;
    final top = position.dy - hitAreaSize / 2;

    // 添加详细的调试信息
    String controlPointName;
    switch (index) {
      case 0:
        controlPointName = '左上角';
        break;
      case 1:
        controlPointName = '上中';
        break;
      case 2:
        controlPointName = '右上角';
        break;
      case 3:
        controlPointName = '右中';
        break;
      case 4:
        controlPointName = '右下角';
        break;
      case 5:
        controlPointName = '下中';
        break;
      case 6:
        controlPointName = '左下角';
        break;
      case 7:
        controlPointName = '左中';
        break;
      case 8:
        controlPointName = '旋转';
        break;
      default:
        controlPointName = '未知';
    }

    debugPrint(
        '构建控制点 $index ($controlPointName) 在位置 $position，点击区域: ($left, $top, $hitAreaSize, $hitAreaSize)');

    return Positioned(
      left: left,
      top: top,
      width: hitAreaSize,
      height: hitAreaSize,
      child: Material(
        color: Colors.transparent, // 使用透明背景
        child: MouseRegion(
          cursor: cursor,
          opaque: true, // 确保鼠标事件不会穿透
          hitTestBehavior: HitTestBehavior.opaque, // 使用opaque确保即使透明区域也能接收事件
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // 使用opaque确保即使透明区域也能接收事件
            onPanStart: (details) {
              debugPrint('控制点 $index 开始拖拽: ${details.localPosition}');
              if (isRotation) {
                setState(() {
                  _isRotating = true;
                });
              }
              // 初始化累积偏移量和当前拖拽的控制点索引
              // _accumulatedDeltas[index] = Offset.zero;
              // _currentDraggingPoint = index;
              // 立即触发一次更新，确保控制点能够立即响应
              widget.onControlPointUpdate(index, Offset.zero);
            },
            onPanUpdate: (details) {
              try {
                // 计算相对于元素中心的位置，用于处理缩放
                final RenderBox renderBox =
                    context.findRenderObject() as RenderBox;
                final matrix = renderBox.getTransformTo(null);
                final scale = matrix.getMaxScaleOnAxis();

                // 根据缩放比例调整delta
                final adjustedDelta = Offset(
                  details.delta.dx * scale,
                  details.delta.dy * scale,
                );

                debugPrint(
                    '控制点 $index 拖拽更新: 原始delta=${details.delta}, 缩放比例=$scale, 调整后delta=$adjustedDelta');

                // // 更新累积偏移量
                // _accumulatedDeltas[index] =
                //     _accumulatedDeltas[index]! + adjustedDelta;

                // 确保立即处理控制点更新
                widget.onControlPointUpdate(index, adjustedDelta);
              } catch (e) {
                debugPrint('控制点更新错误: $e');
              }
            },
            onPanEnd: (details) {
              debugPrint('控制点 $index 结束拖拽');
              if (isRotation) {
                setState(() {
                  _isRotating = false;
                });
              }

              // // 处理网格吸附逻辑
              // final accumulatedDelta = _accumulatedDeltas[index]!;
              // debugPrint('控制点 $index 结束拖拽，最终累积偏移量: $accumulatedDelta');

              // 调用拖拽结束回调，通知外部可以进行网格吸附处理
              widget.onControlPointDragEnd?.call(index);

              // 清除累积偏移量
              // _accumulatedDeltas.remove(index);
              _currentDraggingPoint = null;
            },
            child: Container(
              // decoration: BoxDecoration(
              //   // 添加一个半透明的背景，帮助调试时可视化点击区域
              //   color: Colors.transparent,
              //   border: isRotation
              //       ? Border.all(color: Colors.blue.withAlpha(25), width: 1.0)
              //       : null,
              // ),
              child: Center(
                child: Container(
                  width: controlPointSize,
                  height: controlPointSize,
                  decoration: BoxDecoration(
                    color: isRotation ? const Color(0xFF2196F3) : Colors.white,
                    shape: isRotation ? BoxShape.circle : BoxShape.rectangle,
                    border: Border.all(
                      color:
                          isRotation ? Colors.white : const Color(0xFF2196F3),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        spreadRadius: 1.5 * scaleFactor,
                        blurRadius: 2.0 * scaleFactor,
                        offset: Offset(0, 2.0 * scaleFactor),
                      ),
                    ],
                  ),
                  // 为旋转控制点添加图标，使其更明显
                  // child: isRotation
                  //     ? Transform.scale(
                  //         scale: scaleFactor,
                  //         child: const Icon(
                  //           Icons.rotate_right,
                  //           color: Colors.white,
                  //           size: 12.0,
                  //         ),
                  //       )
                  //     : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 计算缩放系数 - 在缩放比例小于1时，进行反向放大
  double _getScaleFactor(double scale) {
    // 当缩放比例小于1时（即缩小时），控制点应该相对放大
    // 当缩放比例大于等于1时（即放大或不变时），控制点保持原始大小
    final factor = scale < 1.0 ? 1.0 / scale : 1.0;
    debugPrint('计算缩放系数: 当前比例=$scale, 使用系数=$factor');
    return factor * 0.5;
  }

  /// 旋转一个点
  Offset _rotatePoint(
      double px, double py, double cx, double cy, double angle) {
    final s = sin(angle);
    final c = cos(angle);

    // 平移到原点
    final translatedX = px - cx;
    final translatedY = py - cy;

    // 旋转
    final rotatedX = translatedX * c - translatedY * s;
    final rotatedY = translatedX * s + translatedY * c;

    // 平移回去
    return Offset(rotatedX + cx, rotatedY + cy);
  }
}
