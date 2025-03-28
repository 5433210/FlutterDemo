import 'package:flutter/material.dart';

import '../../../utils/coordinate_transformer.dart';

class ActiveSelectionPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;
  final Size viewportSize;

  const ActiveSelectionPainter({
    required this.startPoint,
    required this.endPoint,
    required this.viewportSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // 确保绘制区域不超出视口
      final selectionRect = Rect.fromPoints(startPoint, endPoint)
          .intersect(Offset.zero & viewportSize);

      // 填充
      canvas.drawRect(
        selectionRect,
        Paint()
          ..color = Colors.blue.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );

      // 边框
      canvas.drawRect(
        selectionRect,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // 绘制角点
      const handleSize = 6.0;
      final handlePaint = Paint()..color = Colors.blue;

      final corners = [
        selectionRect.topLeft,
        selectionRect.topRight,
        selectionRect.bottomLeft,
        selectionRect.bottomRight,
      ];

      for (var corner in corners) {
        canvas.drawRect(
          Rect.fromCenter(
            center: corner,
            width: handleSize,
            height: handleSize,
          ),
          handlePaint,
        );
      }
    } catch (e) {}
  }

  @override
  bool shouldRepaint(covariant ActiveSelectionPainter oldDelegate) {
    return startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint ||
        viewportSize != oldDelegate.viewportSize;
  }
}

class CompletedSelectionPainter extends CustomPainter {
  final Rect rect;
  final CoordinateTransformer transformer;
  final Size viewportSize;

  const CompletedSelectionPainter({
    required this.rect,
    required this.transformer,
    required this.viewportSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (viewportSize != size) return; // 防止视口大小不匹配

    try {
      // 从图像坐标转换到视口坐标
      final viewportRect = transformer.imageRectToViewportRect(rect);

      // 绘制选区
      canvas.drawRect(
        viewportRect,
        Paint()
          ..color = Colors.blue.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );

      canvas.drawRect(
        viewportRect,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // 绘制角点手柄
      const handleSize = 6.0;
      final handlePaint = Paint()..color = Colors.blue;

      final corners = [
        viewportRect.topLeft,
        viewportRect.topRight,
        viewportRect.bottomLeft,
        viewportRect.bottomRight,
      ];

      for (var corner in corners) {
        canvas.drawRect(
          Rect.fromCenter(
            center: corner,
            width: handleSize,
            height: handleSize,
          ),
          handlePaint,
        );
      }
    } catch (e) {}
  }

  @override
  bool shouldRepaint(covariant CompletedSelectionPainter oldDelegate) {
    return rect != oldDelegate.rect ||
        transformer != oldDelegate.transformer ||
        viewportSize != oldDelegate.viewportSize;
  }
}
