import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../utils/coordinate_transformer.dart';

/// 可调整区域绘制器
class AdjustableRegionPainter extends CustomPainter {
  final CharacterRegion region;
  final CoordinateTransformer transformer;
  final bool isActive;
  final bool isAdjusting;
  final int? activeHandleIndex;
  final double currentRotation;
  final List<Offset>? guideLines;
  final Rect? viewportRect;

  AdjustableRegionPainter({
    required this.region,
    required this.transformer,
    this.isActive = false,
    this.isAdjusting = false,
    this.activeHandleIndex,
    this.currentRotation = 0.0,
    this.guideLines,
    this.viewportRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || viewportRect == null) return;

    final center = viewportRect!.center;

    // 绘制选区填充
    final fillPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // 根据旋转角度绘制区域
    if (currentRotation != 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(currentRotation);
      canvas.translate(-center.dx, -center.dy);

      canvas.drawRect(viewportRect!, fillPaint);

      canvas.restore();
    } else {
      canvas.drawRect(viewportRect!, fillPaint);
    }

    // 绘制选区边框
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAdjusting ? 2.0 : 1.5;

    // 如果区域有旋转，绘制旋转后的边框
    if (currentRotation != 0) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(currentRotation);
      canvas.translate(-center.dx, -center.dy);
      canvas.drawRect(viewportRect!, borderPaint);
      canvas.restore();
    } else {
      canvas.drawRect(viewportRect!, borderPaint);
    }

    // 绘制调整手柄
    _drawHandles(canvas, viewportRect!);

    // 绘制旋转控件
    _drawRotationControl(canvas, viewportRect!);

    // 绘制辅助线
    if (guideLines != null) {
      _drawGuideLines(canvas);
    }

    // 绘制尺寸指示器
    _drawSizeIndicator(canvas, viewportRect!);

    // 绘制角度指示器（旋转时）
    if (currentRotation != 0) {
      _drawAngleIndicator(canvas, viewportRect!);
    }
  }

  void _drawHandles(Canvas canvas, Rect rect) {
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

    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final activeHandlePaint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;

    for (var i = 0; i < handles.length; i++) {
      final isActive = i == activeHandleIndex;
      final handleRect = Rect.fromCenter(
        center: handles[i],
        width: isActive ? 12.0 : 10.0,
        height: isActive ? 12.0 : 10.0,
      );

      canvas.drawRect(handleRect, isActive ? activeHandlePaint : handlePaint);
      canvas.drawRect(handleRect, handleBorderPaint);
    }
  }

  void _drawRotationControl(Canvas canvas, Rect rect) {
    final rotationPoint = rect.topCenter.translate(0, -30);
    final center = rect.center;

    // 绘制连接线
    final linePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // 绘制虚线
    final dashWidth = 5.0;
    final dashSpace = 5.0;
    final path = Path();
    var distance = 0.0;
    final totalDistance = (rotationPoint - center).distance;
    final direction = (rotationPoint - center) / totalDistance;

    while (distance < totalDistance) {
      path.moveTo(
        center.dx + direction.dx * distance,
        center.dy + direction.dy * distance,
      );
      path.lineTo(
        center.dx + direction.dx * (distance + dashWidth),
        center.dy + direction.dy * (distance + dashWidth),
      );
      distance += dashWidth + dashSpace;
    }

    canvas.drawPath(path, linePaint);

    // 绘制旋转控制点
    final controlPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final controlBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final controlRect = Rect.fromCenter(
      center: rotationPoint,
      width: 16.0,
      height: 16.0,
    );

    canvas.drawCircle(rotationPoint, 8.0, controlPaint);
    canvas.drawCircle(rotationPoint, 8.0, controlBorderPaint);

    // 绘制旋转箭头
    final arrowPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final arrowPath = Path()
      ..moveTo(rotationPoint.dx - 4, rotationPoint.dy)
      ..lineTo(rotationPoint.dx + 4, rotationPoint.dy)
      ..moveTo(rotationPoint.dx + 2, rotationPoint.dy - 2)
      ..lineTo(rotationPoint.dx + 4, rotationPoint.dy)
      ..lineTo(rotationPoint.dx + 2, rotationPoint.dy + 2);

    canvas.drawPath(arrowPath, arrowPaint);
  }

  void _drawGuideLines(Canvas canvas) {
    if (guideLines == null || guideLines!.length < 2) return;

    final guidePaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < guideLines!.length - 1; i += 2) {
      canvas.drawLine(guideLines![i], guideLines![i + 1], guidePaint);
    }
  }

  // 绘制尺寸指示器
  void _drawSizeIndicator(Canvas canvas, Rect rect) {
    final text = '${rect.width.round()}×${rect.height.round()}';
    final textStyle = TextStyle(
      color: Colors.blue,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final position = Offset(rect.right + 5, rect.top);

    // 绘制背景
    final bgRect = Rect.fromLTWH(position.dx - 2, position.dy - 2,
        textPainter.width + 6, textPainter.height + 4);

    canvas.drawRect(
      bgRect,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      bgRect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(canvas, position);
  }

  // 绘制角度指示器
  void _drawAngleIndicator(Canvas canvas, Rect rect) {
    final angle = (currentRotation * 180 / 3.14159).round();
    final text = '$angle°';
    final textStyle = TextStyle(
      color: Colors.blue,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final position = Offset(rect.right + 5, rect.top + 25);

    // 绘制背景
    final bgRect = Rect.fromLTWH(position.dx - 2, position.dy - 2,
        textPainter.width + 6, textPainter.height + 4);

    canvas.drawRect(
      bgRect,
      Paint()
        ..color = Colors.white.withOpacity(0.9)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRect(
      bgRect,
      Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(AdjustableRegionPainter oldDelegate) {
    return region != oldDelegate.region ||
        isActive != oldDelegate.isActive ||
        isAdjusting != oldDelegate.isAdjusting ||
        activeHandleIndex != oldDelegate.activeHandleIndex ||
        currentRotation != oldDelegate.currentRotation ||
        guideLines != oldDelegate.guideLines ||
        viewportRect != oldDelegate.viewportRect;
  }
}
