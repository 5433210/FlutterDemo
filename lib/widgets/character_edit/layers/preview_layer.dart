import 'package:flutter/material.dart';

import 'base_layer.dart';

/// 路径信息类，包含路径和笔刷大小
class PathInfo {
  final Path path;
  final double brushSize;

  PathInfo({required this.path, required this.brushSize});
}

/// 预览图层，显示擦除预览效果
class PreviewLayer extends BaseLayer {
  final List<PathInfo> paths;
  final PathInfo? currentPath;
  final Color brushColor;
  final double brushSize;
  final Rect? dirtyRect;

  const PreviewLayer({
    Key? key,
    this.paths = const [],
    this.currentPath,
    // 默认颜色为白色，代表擦除
    this.brushColor = Colors.white,
    this.brushSize = 10.0,
    this.dirtyRect,
  }) : super(key: key);

  @override
  bool get isComplexPainting => false;

  @override
  bool get willChangePainting => true; // 会频繁更新

  @override
  CustomPainter createPainter() => _PreviewPainter(
        paths: paths,
        currentPath: currentPath,
        brushColor: brushColor,
        brushSize: brushSize,
        dirtyRect: dirtyRect,
      );
}

class _PreviewPainter extends CustomPainter {
  final List<PathInfo> paths;
  final PathInfo? currentPath;
  final Color brushColor;
  final double brushSize; // 默认笔刷大小
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
    // 设置基础画笔
    final basePaint = Paint()
      ..color = brushColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // 打印调试信息
    print('绘制预览层 - 现有路径数: ${paths.length}, 当前路径: ${currentPath != null}');

    // 绘制所有已完成的路径，每个路径使用自己的笔刷大小
    for (final pathInfo in paths) {
      final paint = Paint()
        ..color = brushColor
        ..strokeWidth = pathInfo.brushSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(pathInfo.path, paint);
    }

    // 绘制当前路径
    if (currentPath != null) {
      final paint = Paint()
        ..color = brushColor
        ..strokeWidth = currentPath!.brushSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawPath(currentPath!.path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) {
    // 简化重绘逻辑，确保路径变化时重绘
    if (paths.length != oldDelegate.paths.length) return true;
    if ((currentPath == null) != (oldDelegate.currentPath == null)) return true;
    if (brushColor != oldDelegate.brushColor) return true;
    if (brushSize != oldDelegate.brushSize) return true;

    // 如果有当前路径，总是重绘（因为路径在变化）
    if (currentPath != null) return true;

    return false;
  }
}
