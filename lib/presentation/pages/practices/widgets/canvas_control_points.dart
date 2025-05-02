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
  final Function(int, Offset) onControlPointUpdate;

  const CanvasControlPoints({
    Key? key,
    required this.elementId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.onControlPointUpdate,
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
      ..color = color.withAlpha(30) // 非常淡的填充
      ..style = PaintingStyle.fill;

    // 绘制边框
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // // 绘制虚线边框
    // final dashPaint = Paint()
    //   ..color = Colors.yellow
    //   ..strokeWidth = strokeWidth - 1.0
    //   ..style = PaintingStyle.stroke;

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

    // // 绘制虚线边框
    // const dashLength = 5.0;
    // const gapLength = 5.0;

    // // 绘制左上到右上
    // _drawDashedLine(
    //     canvas, points[0], points[2], dashPaint, dashLength, gapLength);
    // // 绘制右上到右下
    // _drawDashedLine(
    //     canvas, points[2], points[4], dashPaint, dashLength, gapLength);
    // // 绘制右下到左下
    // _drawDashedLine(
    //     canvas, points[4], points[6], dashPaint, dashLength, gapLength);
    // // 绘制左下到左上
    // _drawDashedLine(
    //     canvas, points[6], points[0], dashPaint, dashLength, gapLength);

    // // 在每个角点绘制一个小圆点
    // final cornerPaint = Paint()
    //   ..color = Colors.yellow
    //   ..style = PaintingStyle.fill;

    // for (var i = 0; i < 8; i += 2) {
    //   // 只绘制四个角点
    //   canvas.drawCircle(points[i], 4.0, cornerPaint);
    // }
  }

  @override
  bool shouldRepaint(covariant ElementBorderPainter oldDelegate) {
    return points != oldDelegate.points ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }

  // 绘制虚线
  // void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
  //     double dashLength, double gapLength) {
  //   final dx = end.dx - start.dx;
  //   final dy = end.dy - start.dy;
  //   final distance = sqrt(dx * dx + dy * dy);
  //   final unitX = dx / distance;
  //   final unitY = dy / distance;

  //   var currentDistance = 0.0;
  //   while (currentDistance < distance) {
  //     final startX = start.dx + unitX * currentDistance;
  //     final startY = start.dy + unitY * currentDistance;
  //     final endX =
  //         start.dx + unitX * min(currentDistance + dashLength, distance);
  //     final endY =
  //         start.dy + unitX * min(currentDistance + dashLength, distance);

  //     canvas.drawLine(
  //       Offset(startX, startY),
  //       Offset(endX, endY),
  //       paint,
  //     );

  //     currentDistance += dashLength + gapLength;
  //   }
  // }
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
      ..color = Colors.red
      ..strokeWidth = 4.0 // 进一步增加线条宽度
      ..style = PaintingStyle.stroke;

    // 绘制从元素中心到旋转控制点的连接线
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(rotationX, rotationY),
      paint,
    );

    // 在中心点绘制一个小圆点，使其更明显
    final centerPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 8.0, centerPaint); // 增加圆点大小

    // // 添加一个虚线效果，使旋转线更加明显
    // final dashPaint = Paint()
    //   ..color = Colors.yellow
    //   ..strokeWidth = 2.0
    //   ..style = PaintingStyle.stroke;

    // // 绘制虚线
    // const dashLength = 5.0;
    // const gapLength = 5.0;
    // final dx = rotationX - centerX;
    // final dy = rotationY - centerY;
    // final distance = sqrt(dx * dx + dy * dy);
    // final unitX = dx / distance;
    // final unitY = dy / distance;

    // var currentDistance = 0.0;
    // while (currentDistance < distance) {
    //   final startX = centerX + unitX * currentDistance;
    //   final startY = centerY + unitY * currentDistance;
    //   final endX =
    //       centerX + unitX * min(currentDistance + dashLength, distance);
    //   final endY =
    //       centerY + unitY * min(currentDistance + dashLength, distance);

    //   // canvas.drawLine(
    //   //   Offset(startX, startY),
    //   //   Offset(endX, endY),
    //   //   dashPaint,
    //   // );

    //   currentDistance += dashLength + gapLength;
    // }
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
  @override
  Widget build(BuildContext context) {
    // 计算元素中心点
    final centerX = widget.x + widget.width / 2;
    final centerY = widget.y + widget.height / 2;

    // 计算旋转角度（弧度）
    final angle = widget.rotation * pi / 180;

    // 控制点大小
    const controlPointSize = 8.0;

    // 计算8个控制点的位置（考虑旋转）- 控制点在元素外部
    // 注意：这里的顺序必须与_handleResize方法中的case顺序一致
    final unrotatedPoints = [
      // 索引0: 左上角
      Offset(widget.x - controlPointSize / 2, widget.y - controlPointSize / 2),
      // 索引1: 上中
      Offset(widget.x + widget.width / 2, widget.y - controlPointSize / 2),
      // 索引2: 右上角
      Offset(widget.x + widget.width + controlPointSize / 2,
          widget.y - controlPointSize / 2),
      // 索引3: 右中
      Offset(widget.x + widget.width + controlPointSize / 2,
          widget.y + widget.height / 2),
      // 索引4: 右下角
      Offset(widget.x + widget.width + controlPointSize / 2,
          widget.y + widget.height + controlPointSize / 2),
      // 索引5: 下中
      Offset(widget.x + widget.width / 2,
          widget.y + widget.height + controlPointSize / 2),
      // 索引6: 左下角
      Offset(widget.x - controlPointSize / 2,
          widget.y + widget.height + controlPointSize / 2),
      // 索引7: 左中
      Offset(widget.x - controlPointSize / 2, widget.y + widget.height / 2),
    ];

    // 对每个点进行旋转
    final points = unrotatedPoints
        .map((point) =>
            _rotatePoint(point.dx, point.dy, centerX, centerY, angle))
        .toList();

    // 旋转控制点位于元素上方60像素
    final rotationPoint = _rotatePoint(
      centerX,
      widget.y - 60, // 上方60像素
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
          painter: RotationLinePainter(
            centerX: centerX,
            centerY: centerY,
            rotationX: rotationPoint.dx,
            rotationY: rotationPoint.dy,
          ),
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
  void didUpdateWidget(CanvasControlPoints oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 当控制点位置或大小发生变化时，记录日志
    if (oldWidget.x != widget.x ||
        oldWidget.y != widget.y ||
        oldWidget.width != widget.width ||
        oldWidget.height != widget.height ||
        oldWidget.rotation != widget.rotation) {
      debugPrint(
          '控制点属性已更新: x=${widget.x}, y=${widget.y}, width=${widget.width}, height=${widget.height}, rotation=${widget.rotation}');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  /// 构建单个控制点
  Widget _buildControlPoint(int index, Offset position, MouseCursor cursor,
      {bool isRotation = false}) {
    // 增大控制点大小，使其更容易点击
    const controlPointSize = 16.0;
    // 增大点击区域大小，大幅提高可点击范围
    const hitAreaSize = 60.0;

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
              // 立即触发一次更新，确保控制点能够立即响应
              widget.onControlPointUpdate(index, Offset.zero);
            },
            onPanUpdate: (details) {
              // 获取控制点名称
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
                  '控制点 $index ($controlPointName) 拖拽更新: delta=${details.delta}');
              try {
                // 确保立即处理控制点更新
                widget.onControlPointUpdate(index, details.delta);
              } catch (e) {
                debugPrint('控制点更新错误: $e');
              }
            },
            onPanEnd: (details) {
              debugPrint('控制点 $index 结束拖拽');
            },
            child: Container(
              decoration: BoxDecoration(
                // 添加一个半透明的背景，帮助调试时可视化点击区域
                color: Colors.transparent,
                border: isRotation
                    ? Border.all(color: Colors.blue.withAlpha(25), width: 1.0)
                    : null,
              ),
              child: Center(
                child: Container(
                  width: controlPointSize,
                  height: controlPointSize,
                  decoration: BoxDecoration(
                    color: isRotation ? Colors.blue : Colors.white,
                    shape: isRotation ? BoxShape.circle : BoxShape.rectangle,
                    border: Border.all(
                      color: isRotation ? Colors.white : Colors.blue,
                      width: isRotation ? 2.0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(128),
                        spreadRadius: 2,
                        blurRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // 为旋转控制点添加图标，使其更明显
                  child: isRotation
                      ? const Center(
                          child: Icon(
                            Icons.rotate_right,
                            color: Colors.white,
                            size: 12.0,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
