import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/character/detected_outline.dart';
import 'base_layer.dart';

/// UI图层，处理用户交互和显示光标
class UILayer extends BaseLayer {
  final Function(Offset)? onPointerDown;
  final Function(Offset, Offset)? onPointerMove;
  final Function(Offset)? onPointerUp;
  final Function(Offset)? onPan;
  final MouseCursor cursor;
  final DetectedOutline? outline;
  final Size? imageSize;
  final bool altKeyPressed;
  final double brushSize;
  final Offset? cursorPosition;

  const UILayer({
    Key? key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPan,
    this.cursor = SystemMouseCursors.precise,
    this.outline,
    this.imageSize,
    this.altKeyPressed = false,
    this.brushSize = 10.0,
    this.cursorPosition,
  }) : super(key: key);

  @override
  bool get isComplexPainting => outline != null;

  @override
  bool get willChangePainting => cursorPosition != null;

  @override
  Widget build(BuildContext context) {
    // 记录当前使用的光标，便于调试
    final currentCursor = altKeyPressed ? SystemMouseCursors.move : cursor;
    print(
        'UI图层 - 当前光标: ${altKeyPressed ? "移动" : "擦除"}, Alt键状态: $altKeyPressed');

    return MouseRegion(
      cursor: currentCursor,
      onHover: (event) {
        // 只更新光标位置，不触发擦除操作
        _updateCursorPosition(event.localPosition);
      },
      child: GestureDetector(
        // 仅当拖动且非Alt模式时处理擦除
        onPanStart: (details) {
          print('手势开始: ${details.localPosition}, Alt键: $altKeyPressed');
          if (onPointerDown != null) {
            onPointerDown!(details.localPosition); // 函数内部会根据Alt键状态决定行为
          }
        },
        onPanUpdate: (details) {
          print(
              '手势更新: ${details.localPosition}, 增量: ${details.delta}, Alt键: $altKeyPressed');
          if (onPointerMove != null) {
            onPointerMove!(
                details.localPosition, details.delta); // 函数内部会根据Alt键状态决定行为
          }
        },
        onPanEnd: (_) {
          print('手势结束, Alt键: $altKeyPressed');
          if (cursorPosition != null && onPointerUp != null) {
            onPointerUp!(cursorPosition!); // 函数内部会根据Alt键状态决定行为
          }
        },
        child: Container(
          color: Colors.transparent,
          child: super.build(context),
        ),
      ),
    );
  }

  @override
  CustomPainter createPainter() => _UIPainter(
        outline: outline,
        imageSize: imageSize,
        brushSize: brushSize,
        cursorPosition: cursorPosition,
        altKeyPressed: altKeyPressed,
      );

  // 辅助方法：仅更新光标位置
  void _updateCursorPosition(Offset position) {
    // 如果有onPointerMove回调，调用它但设置delta为Zero，表示只是光标移动而非擦除
    onPointerMove?.call(position, Offset.zero);
  }
}

class _UIPainter extends CustomPainter {
  final DetectedOutline? outline;
  final Size? imageSize;
  final double brushSize;
  final Offset? cursorPosition;
  final bool altKeyPressed;

  _UIPainter({
    this.outline,
    this.imageSize,
    this.brushSize = 10.0,
    this.cursorPosition,
    this.altKeyPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (outline != null && imageSize != null) {
      _drawOutline(canvas, size);
    }

    // 根据模式显示不同光标
    if (cursorPosition != null) {
      if (altKeyPressed) {
        // 平移模式 - 绘制带有"Pan"标签的手型光标
        _drawPanCursor(canvas, cursorPosition!);
      } else {
        // 擦除模式 - 绘制带有"Erase"标签的圆形光标
        _drawBrushCursor(canvas, cursorPosition!);
      }
    }
  }

  @override
  bool shouldRepaint(_UIPainter oldDelegate) =>
      outline != oldDelegate.outline ||
      imageSize != oldDelegate.imageSize ||
      brushSize != oldDelegate.brushSize ||
      cursorPosition != oldDelegate.cursorPosition ||
      altKeyPressed != oldDelegate.altKeyPressed;

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // 绘制主线
    canvas.drawLine(start, end, paint);

    // 计算箭头方向
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    // 计算垂直方向
    final perpX = -unitY;
    final perpY = unitX;

    // 计算箭头的两个端点
    const arrowSize = 4.0;
    final arrowPoint1 = Offset(
      end.dx - unitX * arrowSize + perpX * arrowSize,
      end.dy - unitY * arrowSize + perpY * arrowSize,
    );
    final arrowPoint2 = Offset(
      end.dx - unitX * arrowSize - perpX * arrowSize,
      end.dy - unitY * arrowSize - perpY * arrowSize,
    );

    // 绘制箭头
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.blue);
  }

  void _drawBrushCursor(Canvas canvas, Offset position) {
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final innerPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(position, brushSize / 2, outlinePaint);
    canvas.drawCircle(position, brushSize / 2 - 1.5, innerPaint);

    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(position.dx - 6, position.dy),
      Offset(position.dx + 6, position.dy),
      crosshairPaint,
    );

    canvas.drawLine(
      Offset(position.dx, position.dy - 6),
      Offset(position.dx, position.dy + 6),
      crosshairPaint,
    );

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawLine(
      Offset(position.dx - 7, position.dy),
      Offset(position.dx + 7, position.dy),
      shadowPaint,
    );

    canvas.drawLine(
      Offset(position.dx, position.dy - 7),
      Offset(position.dx, position.dy + 7),
      shadowPaint,
    );
  }

  void _drawOutline(Canvas canvas, Size canvasSize) {
    final scaleX = canvasSize.width / imageSize!.width;
    final scaleY = canvasSize.height / imageSize!.height;
    final scale = math.min(scaleX, scaleY);

    // 创建两个画笔，一个用于主描边，一个用于外描边效果
    final mainStrokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outerStrokePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 内部轮廓使用不同颜色以区分
    final innerStrokePaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 内部轮廓的外描边
    final innerOuterStrokePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final offsetX = (canvasSize.width - imageSize!.width * scale) / 2;
    final offsetY = (canvasSize.height - imageSize!.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // 跟踪已绘制的轮廓数
    int contourCount = 0;

    for (final contour in outline!.contourPoints) {
      if (contour.length < 2) continue;

      final path = Path();
      path.moveTo(contour[0].dx, contour[0].dy);

      for (int i = 1; i < contour.length; i++) {
        path.lineTo(contour[i].dx, contour[i].dy);
      }

      path.close();

      // 第一个轮廓使用蓝色（外轮廓），其余使用红色（内轮廓）
      if (contourCount == 0) {
        // 先绘制外描边（白色）
        canvas.drawPath(path, outerStrokePaint);
        // 再绘制主描边（蓝色）
        canvas.drawPath(path, mainStrokePaint);
      } else {
        // 先绘制外描边（白色）
        canvas.drawPath(path, innerOuterStrokePaint);
        // 再绘制主描边（红色）
        canvas.drawPath(path, innerStrokePaint);
      }

      contourCount++;
    }

    // 打印轮廓数量，帮助调试
    print('绘制了 $contourCount 个轮廓');

    canvas.restore();
  }

  void _drawPanCursor(Canvas canvas, Offset position) {
    // 绘制移动指示器 - 手型光标
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 增加半透明背景圆形，让光标更明显
    canvas.drawCircle(
      position,
      15.0,
      Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // 绘制外圈
    canvas.drawCircle(position, 14.0, paint);

    // 绘制移动指示箭头
    _drawArrow(canvas, position, Offset(position.dx, position.dy - 12), paint);
    _drawArrow(canvas, position, Offset(position.dx, position.dy + 12), paint);
    _drawArrow(canvas, position, Offset(position.dx - 12, position.dy), paint);
    _drawArrow(canvas, position, Offset(position.dx + 12, position.dy), paint);

    // 添加"Pan"标签
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Pan',
        style: TextStyle(
          color: Colors.blue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position.translate(-textPainter.width / 2, 16),
    );
  }
}
