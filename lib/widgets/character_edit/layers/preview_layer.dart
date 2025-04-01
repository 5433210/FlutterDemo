import 'package:flutter/material.dart';

import 'base_layer.dart';

/// 路径信息类，包含路径和笔刷信息
class PathInfo {
  final Path path;
  final double brushSize;
  final Color brushColor;

  PathInfo({
    required this.path,
    required this.brushSize,
    required this.brushColor,
  });
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
    print('绘制预览层 - 路径数: ${paths.length}, 当前路径: ${currentPath != null}, '
        '路径状态: ${_getPathsStatus()}, 画笔大小: $brushSize');

    // 应用全局颜色混合模式 - 确保白色擦除效果正确显示
    final compositeMode = Paint()..blendMode = BlendMode.srcOver;
    canvas.saveLayer(null, compositeMode);

    try {
      // 绘制所有已完成的路径
      _drawAllPaths(canvas);
    } finally {
      canvas.restore(); // 确保恢复画布状态
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) {
    final result = paths != oldDelegate.paths ||
        currentPath?.path != oldDelegate.currentPath?.path ||
        brushColor != oldDelegate.brushColor ||
        brushSize != oldDelegate.brushSize ||
        dirtyRect != oldDelegate.dirtyRect;

    if (result) {
      print(
          '需要重绘预览层 - 原因: ${paths != oldDelegate.paths ? '路径列表变化' : ''}${currentPath?.path != oldDelegate.currentPath?.path ? '当前路径变化' : ''}${dirtyRect != oldDelegate.dirtyRect ? '脏区域变化' : ''}');
    }

    return result;
  }

  // 抽取路径绘制为单独方法以简化代码
  void _drawAllPaths(Canvas canvas) {
    // 绘制已完成的路径
    int pathCount = 0;
    for (final pathInfo in paths) {
      try {
        // 简化绘制逻辑，避免过多检查导致的性能问题
        _drawPath(canvas, pathInfo);
        pathCount++;
      } catch (e) {
        print('绘制路径出错: $e');
      }
    }
    print('  已绘制完成路径数: $pathCount');

    // 绘制当前活动路径
    if (currentPath != null) {
      try {
        _drawPath(canvas, currentPath!);
        print('  已绘制当前路径');
      } catch (e) {
        print('  绘制当前路径失败: $e');
      }
    }
  }

  // 简化的路径绘制方法
  void _drawPath(Canvas canvas, PathInfo pathInfo) {
    final paint = Paint()
      ..color = pathInfo.brushColor
      ..strokeWidth = pathInfo.brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    // 直接绘制路径，简化逻辑避免过多判断
    canvas.drawPath(pathInfo.path, paint);
  }

  // 辅助方法：获取路径状态描述
  String _getPathsStatus() {
    StringBuffer status = StringBuffer();

    // 检查常规路径
    if (paths.isNotEmpty) {
      int validCount = 0;
      int emptyCount = 0;

      for (var path in paths) {
        try {
          final bounds = path.path.getBounds();
          if (!bounds.isEmpty) {
            validCount++;
          } else {
            emptyCount++;
          }
        } catch (e) {
          emptyCount++;
        }
      }

      status.write('有效路径:$validCount,空路径:$emptyCount');
    } else {
      status.write('无路径');
    }

    // 检查当前路径
    if (currentPath != null) {
      try {
        final bounds = currentPath!.path.getBounds();
        status.write(',当前路径:${bounds.isEmpty ? "空" : "有效"}');
      } catch (e) {
        status.write(',当前路径异常');
      }
    }

    return status.toString();
  }
}
