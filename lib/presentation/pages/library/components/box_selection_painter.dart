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
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 绘制边框
    final strokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRect(rect, strokePaint);

    // 绘制角落标记，增强视觉反馈
    final cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 边角尺寸
    const cornerSize = 6.0;

    // 左上角
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(
        rect.topLeft, rect.topLeft.translate(0, cornerSize), cornerPaint);

    // 右上角
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(
        rect.topRight, rect.topRight.translate(0, cornerSize), cornerPaint);

    // 左下角
    canvas.drawLine(
        rect.bottomLeft, rect.bottomLeft.translate(cornerSize, 0), cornerPaint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft.translate(0, -cornerSize),
        cornerPaint);

    // 右下角
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(-cornerSize, 0), cornerPaint);
    canvas.drawLine(rect.bottomRight,
        rect.bottomRight.translate(0, -cornerSize), cornerPaint);
  }

  @override
  bool shouldRepaint(BoxSelectionPainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }
}
