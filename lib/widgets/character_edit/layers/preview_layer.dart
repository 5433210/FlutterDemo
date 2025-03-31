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
    // 修改默认颜色为白色，代表擦除
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
    // 设置画笔
    final paint = Paint()
      ..color = brushColor
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      // 修改为填充模式，确保完全覆盖原内容
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true; // 确保抗锯齿

    // 打印调试信息
    print('绘制预览层 - 现有路径数: ${paths.length}, 当前路径: ${currentPath != null}');

    // 不要使用save/restore，可能导致状态问题
    // 仅在需要裁剪区域时使用

    // 绘制所有已完成的路径
    for (final path in paths) {
      canvas.drawPath(path, paint);
    }

    // 绘制当前路径
    if (currentPath != null) {
      canvas.drawPath(currentPath!, paint);
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
