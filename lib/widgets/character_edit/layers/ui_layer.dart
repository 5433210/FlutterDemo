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
    return MouseRegion(
      cursor: altKeyPressed ? SystemMouseCursors.move : cursor,
      child: Listener(
        onPointerDown: (event) {
          if (altKeyPressed) {
            print('Alt+鼠标按下，准备平移');
            return;
          }
          print('鼠标按下: ${event.localPosition}');
          onPointerDown?.call(event.localPosition);
        },
        onPointerMove: (event) {
          if (altKeyPressed) {
            if (event.buttons == 1) {
              // 鼠标左键按下
              print('Alt+拖拽平移: ${event.delta}');
              onPan?.call(event.delta);
              return;
            }
          } else {
            print('鼠标移动: ${event.localPosition}, 增量: ${event.delta}');
            onPointerMove?.call(
              event.localPosition,
              event.delta,
            );
          }
        },
        onPointerUp: (event) {
          if (altKeyPressed) return;
          onPointerUp?.call(event.localPosition);
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

    if (cursorPosition != null && !altKeyPressed) {
      _drawBrushCursor(canvas, cursorPosition!);
    }
  }

  @override
  bool shouldRepaint(_UIPainter oldDelegate) =>
      outline != oldDelegate.outline ||
      imageSize != oldDelegate.imageSize ||
      brushSize != oldDelegate.brushSize ||
      cursorPosition != oldDelegate.cursorPosition ||
      altKeyPressed != oldDelegate.altKeyPressed;

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
}
