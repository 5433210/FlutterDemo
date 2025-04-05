import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../utils/coordinate_transformer.dart';

class AdjustableRegionPainter extends CustomPainter {
  final CharacterRegion region;
  final CoordinateTransformer transformer;
  final bool isAdjusting;
  final double handleSize;
  final List<Offset>? guideLines;

  const AdjustableRegionPainter({
    required this.region,
    required this.transformer,
    this.isAdjusting = false,
    this.handleSize = 8.0,
    this.guideLines,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final viewportRect = transformer.imageRectToViewportRect(region.rect);

      // 绘制选区
      _drawRegion(canvas, viewportRect);

      // 如果正在调整，绘制控制点和参考线
      if (isAdjusting) {
        _drawHandles(canvas, viewportRect);
        if (guideLines != null) {
          _drawGuideLines(canvas, guideLines!, size);
        }
      }
    } catch (e) {
      // 忽略绘制错误
    }
  }

  @override
  bool shouldRepaint(covariant AdjustableRegionPainter oldDelegate) {
    return region != oldDelegate.region ||
        transformer != oldDelegate.transformer ||
        isAdjusting != oldDelegate.isAdjusting ||
        handleSize != oldDelegate.handleSize ||
        guideLines != oldDelegate.guideLines;
  }

  void _drawGuideLines(Canvas canvas, List<Offset> guides, Size size) {
    final guidePaint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // 绘制虚线参考线
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    final shader = ui.Gradient.linear(
      const Offset(0, 0),
      const Offset(dashWidth + dashSpace, 0),
      [Colors.blue.withOpacity(0.5), Colors.transparent],
      [0, 0.5, 1],
      TileMode.repeated,
    );
    guidePaint.shader = shader;

    for (var point in guides) {
      // 绘制水平参考线
      canvas.drawLine(
        Offset(0, point.dy),
        Offset(size.width, point.dy),
        guidePaint,
      );

      // 绘制垂直参考线
      canvas.drawLine(
        Offset(point.dx, 0),
        Offset(point.dx, size.height),
        guidePaint,
      );
    }
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final handlePaint = Paint()..color = Colors.white;
    final handleBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 所有控制点位置
    final handles = [
      rect.topLeft,
      rect.topCenter,
      rect.topRight,
      rect.centerRight,
      rect.bottomRight,
      rect.bottomCenter,
      rect.bottomLeft,
      rect.centerLeft,
    ];

    // 绘制所有控制点
    for (var handle in handles) {
      final handleRect = Rect.fromCenter(
        center: handle,
        width: handleSize,
        height: handleSize,
      );

      // 绘制白色填充
      canvas.drawRect(handleRect, handlePaint);
      // 绘制蓝色边框
      canvas.drawRect(handleRect, handleBorderPaint);
    }

    // 绘制旋转控制点
    _drawRotationHandle(canvas, rect);
  }

  void _drawRegion(Canvas canvas, Rect rect) {
    // 绘制填充
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue.withOpacity(0.1)
        ..style = PaintingStyle.fill,
    );

    // 绘制边框
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawRotationHandle(Canvas canvas, Rect rect) {
    final center = rect.topCenter;
    final rotationPoint = center.translate(0, -30);

    // 绘制连接线
    canvas.drawLine(
      center,
      rotationPoint,
      Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.5,
    );

    // 绘制旋转控制点
    canvas.drawCircle(
      rotationPoint,
      handleSize / 2,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      rotationPoint,
      handleSize / 2,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
