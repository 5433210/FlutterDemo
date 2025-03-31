import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/character/detected_outline.dart';
import 'base_layer.dart';

/// UI图层，处理用户交互和显示光标
class UILayer extends BaseLayer {
  final Function(Offset)? onPointerDown;
  final Function(Offset, Offset)? onPointerMove;
  final Function(Offset)? onPointerUp;
  final MouseCursor cursor;
  final DetectedOutline? outline;
  final Size? imageSize;
  // 添加Alt键状态
  final bool altKeyPressed;

  const UILayer({
    Key? key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.cursor = SystemMouseCursors.precise,
    this.outline,
    this.imageSize,
    this.altKeyPressed = false,
  }) : super(key: key);

  @override
  bool get isComplexPainting => outline != null;

  @override
  bool get willChangePainting => false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: altKeyPressed ? SystemMouseCursors.move : cursor,
      child: Listener(
        // 在Alt键按下时不处理擦除事件
        onPointerDown: (event) {
          if (altKeyPressed) return; // Alt键按下时不处理擦除
          print('鼠标按下: ${event.localPosition}');
          onPointerDown?.call(event.localPosition);
        },
        onPointerMove: (event) {
          if (altKeyPressed) return; // Alt键按下时不处理擦除
          print('鼠标移动: ${event.localPosition}, 增量: ${event.delta}');
          onPointerMove?.call(
            event.localPosition,
            event.delta,
          );
        },
        onPointerUp: (event) {
          if (altKeyPressed) return; // Alt键按下时不处理擦除
          print('鼠标释放: ${event.localPosition}');
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
      );
}

class _UIPainter extends CustomPainter {
  final DetectedOutline? outline;
  final Size? imageSize;

  _UIPainter({
    this.outline,
    this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // UI层通常不绘制内容，它主要处理交互

    // 从PreviewCanvas的OutlinePainter迁移：显示轮廓
    if (outline != null && imageSize != null) {
      _drawOutline(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_UIPainter oldDelegate) =>
      outline != oldDelegate.outline || imageSize != oldDelegate.imageSize;

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
