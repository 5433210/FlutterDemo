import 'package:flutter/material.dart';

import '../../../domain/models/character_region.dart';

class RegionPainter extends CustomPainter {
  static const double handleSize = 8.0;
  final CharacterRegion? region;
  final Offset? selectionStart;
  final Offset? selectionEnd;
  final bool isSelecting;
  final bool isSelected;

  RegionPainter({
    this.region,
    this.selectionStart,
    this.selectionEnd,
    this.isSelecting = false,
    this.isSelected = false,
  });

  // 判断点击是否在控制点上
  int? getHandleAtPoint(Offset point, Rect rect) {
    final handles = <Offset>[
      rect.topLeft,
      Offset(rect.left + rect.width / 2, rect.top),
      rect.topRight,
      Offset(rect.right, rect.top + rect.height / 2),
      rect.bottomRight,
      Offset(rect.left + rect.width / 2, rect.bottom),
      rect.bottomLeft,
      Offset(rect.left, rect.top + rect.height / 2),
    ];

    for (int i = 0; i < handles.length; i++) {
      final handleRect = Rect.fromCenter(
        center: handles[i],
        width: handleSize,
        height: handleSize,
      );
      if (handleRect.contains(point)) {
        return i;
      }
    }
    return null;
  }

  // 判断点击是否在旋转控制点上
  bool isRotationHandle(Offset point, Rect rect) {
    final center = Offset(rect.right, rect.top - 20);
    final handleRect = Rect.fromCircle(center: center, radius: handleSize / 2);
    return handleRect.contains(point);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制选择框
    if (isSelecting && selectionStart != null && selectionEnd != null) {
      paint.color = Colors.blue.withOpacity(0.8);
      final rect = Rect.fromPoints(selectionStart!, selectionEnd!);
      canvas.drawRect(rect, paint);
    }

    // 绘制已有区域
    if (region != null) {
      // 保存当前画布状态
      canvas.save();

      // 如果有旋转，先移动到中心点再旋转
      if (region!.rotation != 0.0) {
        final center = region!.rect.center;
        canvas.translate(center.dx, center.dy);
        canvas.rotate(region!.rotation);
        canvas.translate(-center.dx, -center.dy);
      }

      // 绘制区域边框
      paint.color = region!.isSaved
          ? Colors.green
          : (isSelected ? Colors.blue : Colors.blue.withOpacity(0.8));
      canvas.drawRect(region!.rect, paint);

      // 如果被选中，绘制控制点
      if (isSelected) {
        paint
          ..style = PaintingStyle.fill
          ..color = Colors.white;
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.blue;

        // 绘制8个调整大小的控制点
        _drawResizeHandles(canvas, region!.rect, paint, strokePaint);

        // 绘制旋转控制点
        _drawRotationHandle(canvas, region!.rect, paint);
      }

      // 恢复画布状态
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RegionPainter oldDelegate) {
    return region != oldDelegate.region ||
        selectionStart != oldDelegate.selectionStart ||
        selectionEnd != oldDelegate.selectionEnd ||
        isSelecting != oldDelegate.isSelecting ||
        isSelected != oldDelegate.isSelected;
  }

  void _drawResizeHandles(
      Canvas canvas, Rect rect, Paint fillPaint, Paint strokePaint) {
    final handles = <Offset>[
      rect.topLeft,
      Offset(rect.left + rect.width / 2, rect.top),
      rect.topRight,
      Offset(rect.right, rect.top + rect.height / 2),
      rect.bottomRight,
      Offset(rect.left + rect.width / 2, rect.bottom),
      rect.bottomLeft,
      Offset(rect.left, rect.top + rect.height / 2),
    ];

    for (final point in handles) {
      final handleRect = Rect.fromCenter(
        center: point,
        width: handleSize,
        height: handleSize,
      );
      canvas.drawRect(handleRect, fillPaint);
      canvas.drawRect(handleRect, strokePaint);
    }
  }

  void _drawRotationHandle(Canvas canvas, Rect rect, Paint paint) {
    final center = Offset(rect.right, rect.top - 20);
    paint.color = Colors.blue;
    canvas.drawCircle(center, handleSize / 2, paint);
  }
}
