import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';

class RegionPainter extends CustomPainter {
  static const double handleSize = 8.0;
  static const double rotationHandleOffset = 20.0;
  final CharacterRegion? region;
  final bool isSelected;
  final Offset? selectionStart;

  final Offset? selectionEnd;
  final bool isSelecting;

  const RegionPainter({
    this.region,
    this.isSelected = false,
    this.selectionStart,
    this.selectionEnd,
    this.isSelecting = false,
  });

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

    for (var i = 0; i < handles.length; i++) {
      if (_isPointNearHandle(point, handles[i])) {
        return i;
      }
    }
    return null;
  }

  bool isRotationHandle(Offset point, Rect rect) {
    final center = Offset(
      rect.left + rect.width / 2,
      rect.top - rotationHandleOffset,
    );
    return _isPointNearHandle(point, center);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (isSelecting && selectionStart != null && selectionEnd != null) {
      _drawSelectionRect(canvas, selectionStart!, selectionEnd!);
    }

    if (region != null) {
      _drawRegion(canvas, region!);
    }
  }

  @override
  bool shouldRepaint(RegionPainter oldDelegate) {
    return region != oldDelegate.region ||
        isSelected != oldDelegate.isSelected ||
        selectionStart != oldDelegate.selectionStart ||
        selectionEnd != oldDelegate.selectionEnd ||
        isSelecting != oldDelegate.isSelecting;
  }

  void _drawHandle(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, handleSize, paint);

    paint.color = Colors.blue;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.5;

    canvas.drawCircle(position, handleSize, paint);
  }

  void _drawRegion(Canvas canvas, CharacterRegion region) {
    final paint = Paint()
      ..color = isSelected
          ? Colors.blue.withOpacity(0.3)
          : Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final rect = region.rect;
    canvas.drawRect(rect, paint);

    paint
      ..color = isSelected ? Colors.blue : Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(rect, paint);

    if (isSelected) {
      _drawResizeHandles(canvas, rect);
      _drawRotationHandle(canvas, rect);
    }
  }

  void _drawResizeHandles(Canvas canvas, Rect rect) {
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

    for (final handle in handles) {
      _drawHandle(canvas, handle);
    }
  }

  void _drawRotationHandle(Canvas canvas, Rect rect) {
    final center = Offset(
      rect.left + rect.width / 2,
      rect.top - rotationHandleOffset,
    );

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw connecting line
    canvas.drawLine(
      Offset(rect.left + rect.width / 2, rect.top),
      center,
      paint,
    );

    // Draw rotation handle
    _drawHandle(canvas, center);
  }

  void _drawSelectionRect(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);

    paint
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(rect, paint);
  }

  bool _isPointNearHandle(Offset point, Offset handle) {
    return (point - handle).distance <= handleSize;
  }
}
