import 'package:flutter/material.dart';

import 'base_layer.dart';

/// 预览图层，显示擦除预览效果
class PreviewLayer extends BaseLayer {
  final List<Path> paths;
  final Path? currentPath;
  final Color brushColor;
  final double brushSize;
  final Rect? dirtyRect;

  const PreviewLayer({
    Key? key,
    this.paths = const [],
    this.currentPath,
    this.brushColor = Colors.red,
    this.brushSize = 10.0,
    this.dirtyRect,
  }) : super(key: key);

  @override
  bool get isComplexPainting => false;

  @override
  bool get willChangePainting => true; // 会频繁更新

  @override
  CustomPainter createPainter() => _PreviewPainter(
        // Changed from _createPainter to createPainter
        paths: paths,
        currentPath: currentPath,
        brushColor: brushColor,
        brushSize: brushSize,
        dirtyRect: dirtyRect,
      );
}

class _PreviewPainter extends CustomPainter {
  final List<Path> paths;
  final Path? currentPath;
  final Color brushColor;
  final double brushSize;
  final Rect? dirtyRect;

  _PreviewPainter({
    required this.paths,
    this.currentPath,
    required this.brushColor,
    required this.brushSize,
    this.dirtyRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 如果有脏区域，只重绘该区域
    if (dirtyRect != null) {
      canvas.save();
      canvas.clipRect(dirtyRect!);
    }

    final paint = Paint()
      ..color = brushColor
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // 绘制已完成的路径
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }

    // 绘制当前路径
    if (currentPath != null) {
      canvas.drawPath(currentPath!, paint);
    }

    if (dirtyRect != null) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) {
    return brushColor != oldDelegate.brushColor ||
        brushSize != oldDelegate.brushSize ||
        paths.length != oldDelegate.paths.length ||
        currentPath != oldDelegate.currentPath ||
        dirtyRect != oldDelegate.dirtyRect;
  }
}
