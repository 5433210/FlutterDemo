import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';

class RegionPainter extends CustomPainter {
  static const double handleSize = 8.0;
  static const double rotationHandleOffset = 24.0;
  static const double labelFontSize = 12.0;

  static const Color savedColor = Colors.green;
  static const Color unsavedColor = Colors.blue;
  static const Color selectedColor = Colors.blue;

  final CharacterRegion? region;
  final bool isSelected;
  final bool isSelecting;
  final Offset? selectionStart;
  final Offset? selectionEnd;

  RegionPainter({
    this.region,
    this.isSelected = false,
    this.isSelecting = false,
    this.selectionStart,
    this.selectionEnd,
  });

  Color get _fillColor => _regionColor.withOpacity(0.2);

  Color get _regionColor {
    if (isSelecting) return selectedColor;
    if (region == null) return unsavedColor;
    if (isSelected) return selectedColor;
    return region!.isSaved ? savedColor : unsavedColor;
  }

  int? getHandleAtPoint(Offset point, Rect rect) {
    final points = [
      rect.topLeft,
      Offset(rect.center.dx, rect.top),
      rect.topRight,
      Offset(rect.right, rect.center.dy),
      rect.bottomRight,
      Offset(rect.center.dx, rect.bottom),
      rect.bottomLeft,
      Offset(rect.left, rect.center.dy),
    ];

    for (int i = 0; i < points.length; i++) {
      if ((point - points[i]).distance <= handleSize) {
        return i;
      }
    }
    return null;
  }

  bool isRotationHandle(Offset point, Rect rect) {
    final center = Offset(rect.center.dx, rect.top - rotationHandleOffset);
    return (point - center).distance <= handleSize;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (isSelecting && selectionStart != null && selectionEnd != null) {
      _drawSelectionBox(canvas, selectionStart!, selectionEnd!);
    }

    if (region != null) {
      _drawRegion(canvas, region!);
    }
  }

  @override
  bool shouldRepaint(RegionPainter oldDelegate) {
    return oldDelegate.region != region ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isSelecting != isSelecting ||
        oldDelegate.selectionStart != selectionStart ||
        oldDelegate.selectionEnd != selectionEnd;
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final points = [
      rect.topLeft,
      Offset(rect.center.dx, rect.top),
      rect.topRight,
      Offset(rect.right, rect.center.dy),
      rect.bottomRight,
      Offset(rect.center.dx, rect.bottom),
      rect.bottomLeft,
      Offset(rect.left, rect.center.dy),
    ];

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = _regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final point in points) {
      canvas.drawRect(
        Rect.fromCenter(
          center: point,
          width: handleSize,
          height: handleSize,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: point,
          width: handleSize,
          height: handleSize,
        ),
        borderPaint,
      );
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String label) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: labelFontSize,
          backgroundColor: Colors.black54,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        rect.left,
        rect.top - textPainter.height - 4,
      ),
    );
  }

  void _drawRegion(Canvas canvas, CharacterRegion region) {
    final rect = region.rect;
    final paint = Paint()
      ..color = _fillColor
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(region.rotation);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    canvas.drawRect(rect, paint);

    paint
      ..color = _regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2 : 1;
    canvas.drawRect(rect, paint);

    if (isSelected) {
      _drawHandles(canvas, rect);
      _drawRotationHandle(canvas, rect);
    }

    if (region.label != null) {
      _drawLabel(canvas, rect, region.label!);
    }

    canvas.restore();
  }

  void _drawRotationHandle(Canvas canvas, Rect rect) {
    final center = Offset(rect.center.dx, rect.top - rotationHandleOffset);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = _regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, handleSize / 2, paint);
    canvas.drawCircle(center, handleSize / 2, borderPaint);
    canvas.drawLine(
      Offset(rect.center.dx, rect.top),
      center,
      borderPaint,
    );
  }

  void _drawSelectionBox(Canvas canvas, Offset start, Offset end) {
    final rect = Rect.fromPoints(start, end);
    final paint = Paint()
      ..color = _fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    paint
      ..color = _regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(rect, paint);
  }
}
