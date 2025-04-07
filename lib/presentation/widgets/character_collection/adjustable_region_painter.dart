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

    // 保存画布状态用于旋转
    canvas.save();

    // 应用旋转变换
    if (currentRotation != 0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(currentRotation);
      canvas.translate(-center.dx, -center.dy);
    }

    // 绘制选区填充
    canvas.drawRect(viewportRect!, fillPaint);

    // 绘制选区边框
    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = isAdjusting ? 2.0 : 1.5;
    canvas.drawRect(viewportRect!, borderPaint);

    // 绘制调整手柄 (draw with rotation applied)
    _drawHandles(canvas, viewportRect!);

    // 绘制旋转控件 (draw with rotation applied)
    _drawRotationControl(canvas, viewportRect!);

    // 恢复画布状态，后续绘制不会受到旋转影响
    canvas.restore();

    // 绘制不随旋转的元素
    // 绘制辅助线
    if (guideLines != null) {
      _drawGuideLines(canvas);
    }
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
    const dashWidth = 5.0;
    const dashSpace = 5.0;
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
}
