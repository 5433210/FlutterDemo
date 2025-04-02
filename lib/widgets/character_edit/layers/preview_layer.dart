import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../utils/debug/debug_flags.dart';
import '../../../utils/path/path_utils.dart';
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
  final Rect? dirtyRect;

  const PreviewLayer({
    Key? key,
    this.paths = const [],
    this.currentPath,
    this.dirtyRect,
  }) : super(key: key);

  @override
  bool get isComplexPainting => false;

  @override
  bool get willChangePainting => true;

  @override
  CustomPainter createPainter() => _PreviewPainter(
        paths: paths,
        currentPath: currentPath,
        dirtyRect: dirtyRect,
      );
}

class _PreviewPainter extends CustomPainter {
  final List<PathInfo> paths;
  final PathInfo? currentPath;

  final Rect? dirtyRect;

  _PreviewPainter({
    required this.paths,
    this.currentPath,
    this.dirtyRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (kDebugMode) {
      print('绘制预览层 - 路径数量: ${paths.length}, 当前路径: ${currentPath != null}');
    }

    // Apply global color blend mode - ensure erased areas display correctly
    final compositeMode = Paint()..blendMode = BlendMode.srcOver;
    canvas.saveLayer(null, compositeMode);

    try {
      // Draw all completed paths
      _drawAllPaths(canvas);
    } finally {
      canvas.restore(); // Ensure canvas state is restored
    }

    // 在调试模式下绘制边界框
    if (kDebugMode && DebugFlags.enableEraseDebug && dirtyRect != null) {
      canvas.drawRect(
        dirtyRect!,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.red
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) {
    final shouldRepaint = paths != oldDelegate.paths ||
        currentPath?.path != oldDelegate.currentPath?.path ||
        dirtyRect != oldDelegate.dirtyRect;

    if (shouldRepaint && kDebugMode) {
      print('重绘预览层');
    }

    return shouldRepaint;
  }

  void _drawAllPaths(Canvas canvas) {
    // 尝试合并并绘制已完成的路径
    if (paths.isNotEmpty) {
      try {
        // 合并所有已完成的路径
        final pathsList = paths.map((p) => p.path).toList();
        final completePath = PathUtils.mergePaths(pathsList);

        if (!PathUtils.isPathEmpty(completePath)) {
          // 使用第一个路径的颜色，因为所有路径应该使用相同的颜色
          if (paths.isNotEmpty) {
            print('绘制已完成路径');
            canvas.drawPath(
              completePath,
              Paint()..color = paths[0].brushColor,
            );
          }
        }
      } catch (e) {
        print('合并路径失败，尝试单独绘制: $e');
        // 如果合并失败，逐个绘制每个路径
        for (final pathInfo in paths) {
          try {
            _drawPath(canvas, pathInfo);
          } catch (e2) {
            print('单独绘制路径失败: $e2');
          }
        }
      }
    }

    // 绘制当前正在擦除的路径
    if (currentPath != null) {
      try {
        print('绘制当前路径');
        // 当前路径不参与合并，单独绘制
        _drawPath(canvas, currentPath!);
      } catch (e) {
        print('绘制当前路径失败: $e');
      }
    }
  }

  // Improved path drawing method that properly handles inverted colors
  void _drawPath(Canvas canvas, PathInfo pathInfo) {
    // Click erase point - use fill style for better visibility
    final fillPaint = Paint()
      ..color = pathInfo.brushColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(pathInfo.path, fillPaint);
  }

  // Helper method to get a contrasting color for stroke
  Color _getContrastingColor(Color color) {
    // If the brush color is light, use dark border and vice versa
    return color.computeLuminance() > 0.5
        ? color.withOpacity(0.7)
        : Colors.white.withOpacity(0.7);
  }
}
