import 'package:flutter/material.dart';

import 'guideline_types.dart';

/// 简单的参考线绘制器
class GuidelineSimplePainter extends CustomPainter {
  final List<Guideline> guidelines;

  GuidelineSimplePainter(this.guidelines);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final guideline in guidelines) {
      if (guideline.direction == AlignmentDirection.horizontal) {
        canvas.drawLine(
          Offset(0, guideline.position),
          Offset(size.width, guideline.position),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(guideline.position, 0),
          Offset(guideline.position, size.height),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
