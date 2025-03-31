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
  // 添加Alt键状态
  final bool altKeyPressed;
  // 添加笔刷大小参数
  final double brushSize;
  // 添加当前鼠标位置跟踪
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
              // 使用原始delta进行平移，不再反转方向
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
          color: Colors.transparent, // 确保能接收整个区域的事件
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
    // 从PreviewCanvas的OutlinePainter迁移：显示轮廓
    if (outline != null && imageSize != null) {
      _drawOutline(canvas, size);
    }

    // 绘制笔刷光标
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

  // 绘制笔刷光标 - 显示笔刷大小
  void _drawBrushCursor(Canvas canvas, Offset position) {
    // 外圈 - 白色半透明
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 内圈 - 黑色半透明
    final innerPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制表示笔刷大小的圆圈
    canvas.drawCircle(position, brushSize / 2, outlinePaint);
    canvas.drawCircle(position, brushSize / 2 - 1.5, innerPaint);

    // 绘制十字准星
    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 横线
    canvas.drawLine(
      Offset(position.dx - 6, position.dy),
      Offset(position.dx + 6, position.dy),
      crosshairPaint,
    );

    // 竖线
    canvas.drawLine(
      Offset(position.dx, position.dy - 6),
      Offset(position.dx, position.dy + 6),
      crosshairPaint,
    );

    // 为十字准星添加黑色描边以增强对比度
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // 绘制十字准星黑色描边
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

    final strokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter;

    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final offsetX = (canvasSize.width - imageSize!.width * scale) / 2;
    final offsetY = (canvasSize.height - imageSize!.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    for (final contour in outline!.contourPoints) {
      if (contour.length < 2) continue;

      final path = Path();
      path.moveTo(contour[0].dx, contour[0].dy);

      for (int i = 1; i < contour.length; i++) {
        path.lineTo(contour[i].dx, contour[i].dy);
      }

      path.close();

      // 先用填充色绘制轮廓内部
      canvas.drawPath(path, fillPaint);
      // 再用描边色绘制轮廓线
      canvas.drawPath(path, strokePaint);
    }

    canvas.restore();
  }
}
