import 'package:flutter/material.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../utils/coordinate_transformer.dart';

class RegionsPainter extends CustomPainter {
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final CoordinateTransformer transformer;

  const RegionsPainter({
    required this.regions,
    required this.selectedIds,
    required this.transformer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      try {
        final viewportRect = transformer.imageRectToViewportRect(region.rect);
        final isSelected = selectedIds.contains(region.id);

        canvas.drawRect(
          viewportRect,
          Paint()
            ..color = isSelected ? Colors.blue : Colors.green
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 2.0 : 1.5,
        );

        if (isSelected) {
          _drawHandle(canvas, viewportRect.topLeft, Colors.blue);
          _drawHandle(canvas, viewportRect.topRight, Colors.blue);
          _drawHandle(canvas, viewportRect.bottomLeft, Colors.blue);
          _drawHandle(canvas, viewportRect.bottomRight, Colors.blue);
        }
      } catch (e) {}
    }
  }

  @override
  bool shouldRepaint(RegionsPainter oldDelegate) {
    return regions != oldDelegate.regions ||
        selectedIds != oldDelegate.selectedIds ||
        transformer != oldDelegate.transformer;
  }

  void _drawHandle(Canvas canvas, Offset position, Color color) {
    canvas.drawCircle(
      position,
      6.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      position,
      6.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }
}
