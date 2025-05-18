import 'package:flutter/material.dart';

/// 用于绘制框选矩形的自定义画笔
class BoxSelectionPainter extends CustomPainter {
  final Offset start;
  final Offset end;

  BoxSelectionPainter({
    required this.start,
    required this.end,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 创建选择框的矩形
    final rect = Rect.fromPoints(start, end);

    // 绘制半透明填充
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 绘制边框
    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, strokePaint);
  }

  @override
  bool shouldRepaint(BoxSelectionPainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}
