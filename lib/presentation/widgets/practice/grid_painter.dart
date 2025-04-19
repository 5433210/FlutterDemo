import 'package:flutter/material.dart';

/// 网格绘制器
class GridPainter extends CustomPainter {
  final double gridSize;
  final Color gridColor;
  final double strokeWidth;

  GridPainter({
    this.gridSize = 20.0,
    this.gridColor = const Color(0x20000000),
    this.strokeWidth = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // 绘制横线
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 绘制竖线
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
