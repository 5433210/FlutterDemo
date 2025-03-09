import 'package:flutter/material.dart';

import '../../../domain/models/character/character_entity.dart';

/// 字形预览组件
class CharacterPreview extends StatelessWidget {
  final CharacterEntity character;
  final bool showGrid;
  final double initialScale;
  final void Function(double)? onScaleChanged;

  const CharacterPreview({
    super.key,
    required this.character,
    this.showGrid = false,
    this.initialScale = 1.0,
    this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: InteractiveViewer(
        minScale: 0.1,
        maxScale: 5.0,
        onInteractionUpdate: (details) {
          if (onScaleChanged != null) {
            onScaleChanged!(details.scale);
          }
        },
        child: Stack(
          children: [
            // 字形图片
            const Icon(
              Icons.broken_image,
              size: 48,
              color: Colors.red,
            ),

            // 参考网格
            if (showGrid)
              CustomPaint(
                painter: GridPainter(),
                size: Size.infinite,
              ),
          ],
        ),
      ),
    );
  }
}

/// 网格绘制器
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 0.5;

    const gridSize = 50.0;

    for (var i = 0.0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    for (var i = 0.0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
