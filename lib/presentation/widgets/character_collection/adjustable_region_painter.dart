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

    // 绘制调整状态的选区填充和边框
    final fillPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    // 保存画布状态用于旋转
    canvas.save();

    // 应用旋转变换
    if (currentRotation != 0) {
      canvas.translate(center.dx, center.dy);
      canvas.rotate(currentRotation);
      canvas.translate(-center.dx, -center.dy);
    }

    // 绘制调整状态的选区填充
    canvas.drawRect(viewportRect!, fillPaint);

    // 绘制调整状态的选区边框
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
    // 🚀 优化：先检查最可能变化的UI状态属性
    if (oldDelegate.isActive != isActive ||
        oldDelegate.isAdjusting != isAdjusting ||
        oldDelegate.activeHandleIndex != activeHandleIndex) {
      return true;
    }
    
    // 检查变换相关的变化  
    if (oldDelegate.currentRotation != currentRotation ||
        oldDelegate.viewportRect != viewportRect) {
      return true;
    }
    
    // 检查引导线变化
    if (!_listsEqual(oldDelegate.guideLines, guideLines)) {
      return true;
    }
    
    // 最后检查区域变化（最复杂的比较）
    return oldDelegate.region != region;
  }

  // 🚀 优化：添加空安全的列表比较方法
  bool _listsEqual<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _drawGuideLines(Canvas canvas) {
    if (guideLines == null || guideLines!.length < 2) return;

    final guidePaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var i = 0; i < guideLines!.length - 1; i += 2) {
      canvas.drawLine(guideLines![i], guideLines![i + 1], guidePaint);
    }
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    // 使用与字帖编辑页相同的角落标记式风格
    final markPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // 绘制包围元素区域的细线框
    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, borderPaint);

    // 控制点标记的长度
    const double markLength = 12.0;
    const double inset = 8.0; // 控制点内偏移量

    // 计算所有8个控制点位置（在元素内部）
    final controlPoints = [
      Offset(rect.left + inset, rect.top + inset), // 左上角
      Offset(rect.center.dx, rect.top + inset), // 上中
      Offset(rect.right - inset, rect.top + inset), // 右上角
      Offset(rect.right - inset, rect.center.dy), // 右中
      Offset(rect.right - inset, rect.bottom - inset), // 右下角
      Offset(rect.center.dx, rect.bottom - inset), // 下中
      Offset(rect.left + inset, rect.bottom - inset), // 左下角
      Offset(rect.left + inset, rect.center.dy), // 左中
    ];

    // 为每个控制点位置绘制L形或T形标记
    for (int i = 0; i < controlPoints.length; i++) {
      final isActive = i == activeHandleIndex;
      final currentPaint = isActive 
          ? (Paint()
              ..color = Colors.blue.shade800
              ..strokeWidth = 3.0
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.square)
          : markPaint;
      
      _drawControlPointMark(canvas, currentPaint, controlPoints[i], i, markLength);
    }
  }

  void _drawControlPointMark(Canvas canvas, Paint paint, Offset controlPoint, 
      int index, double markLength) {
    
    // 根据控制点位置确定L形或T形标记的方向
    switch (index) {
      case 0: // 左上角 - L形开口向右下
        canvas.drawLine(controlPoint, controlPoint.translate(markLength, 0), paint);
        canvas.drawLine(controlPoint, controlPoint.translate(0, markLength), paint);
        break;
      case 1: // 上中 - T形向下
        canvas.drawLine(controlPoint.translate(-markLength/2, 0), controlPoint.translate(markLength/2, 0), paint);
        canvas.drawLine(controlPoint, controlPoint.translate(0, markLength), paint);
        break;
      case 2: // 右上角 - L形开口向左下
        canvas.drawLine(controlPoint, controlPoint.translate(-markLength, 0), paint);
        canvas.drawLine(controlPoint, controlPoint.translate(0, markLength), paint);
        break;
      case 3: // 右中 - T形向左
        canvas.drawLine(controlPoint, controlPoint.translate(-markLength, 0), paint);
        canvas.drawLine(controlPoint.translate(0, -markLength/2), controlPoint.translate(0, markLength/2), paint);
        break;
      case 4: // 右下角 - L形开口向左上
        canvas.drawLine(controlPoint, controlPoint.translate(-markLength, 0), paint);
        canvas.drawLine(controlPoint, controlPoint.translate(0, -markLength), paint);
        break;
      case 5: // 下中 - T形向上
        canvas.drawLine(controlPoint.translate(-markLength/2, 0), controlPoint.translate(markLength/2, 0), paint);
        canvas.drawLine(controlPoint, controlPoint.translate(0, -markLength), paint);
        break;
      case 6: // 左下角 - L形开口向右上
        canvas.drawLine(controlPoint, controlPoint.translate(markLength, 0), paint);
        canvas.drawLine(controlPoint, controlPoint.translate(0, -markLength), paint);
        break;
      case 7: // 左中 - T形向右
        canvas.drawLine(controlPoint, controlPoint.translate(markLength, 0), paint);
        canvas.drawLine(controlPoint.translate(0, -markLength/2), controlPoint.translate(0, markLength/2), paint);
        break;
    }
  }

  void _drawRotationControl(Canvas canvas, Rect rect) {
    final rotationPoint = rect.topCenter.translate(0, -30);
    final center = rect.center;

    // 🔧 优化连接线样式，更精致
    final linePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // 绘制优化的虚线
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final path = Path();
    var distance = 0.0;
    final totalDistance = (rotationPoint - center).distance;
    final direction = (rotationPoint - center) / totalDistance;

    while (distance < totalDistance) {
      path.moveTo(
        center.dx + direction.dx * distance,
        center.dy + direction.dy * distance,
      );
      final segmentEnd = (distance + dashWidth).clamp(0.0, totalDistance);
      path.lineTo(
        center.dx + direction.dx * segmentEnd,
        center.dy + direction.dy * segmentEnd,
      );
      distance = segmentEnd + dashSpace;
    }

    canvas.drawPath(path, linePaint);

    // 🔧 优化旋转控制点样式，更精致
    final controlPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final controlBorderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // 绘制带阴影效果的圆形控制点
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    
    // 绘制阴影
    canvas.drawCircle(rotationPoint.translate(1, 1), 8.5, shadowPaint);
    
    // 绘制控制点主体
    canvas.drawCircle(rotationPoint, 8.0, controlPaint);
    canvas.drawCircle(rotationPoint, 8.0, controlBorderPaint);

    // 🔧 优化旋转箭头样式
    final arrowPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final arrowPath = Path()
      ..moveTo(rotationPoint.dx - 4, rotationPoint.dy)
      ..lineTo(rotationPoint.dx + 4, rotationPoint.dy)
      ..moveTo(rotationPoint.dx + 2.5, rotationPoint.dy - 2.5)
      ..lineTo(rotationPoint.dx + 4, rotationPoint.dy)
      ..lineTo(rotationPoint.dx + 2.5, rotationPoint.dy + 2.5);

    canvas.drawPath(arrowPath, arrowPaint);
  }
}
