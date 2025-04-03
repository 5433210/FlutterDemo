import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/character/path_info.dart';
import '../../../utils/debug/debug_flags.dart';
import 'base_layer.dart';

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
    // First draw all completed paths
    if (paths.isNotEmpty) {
      try {
        // Each path with its own color
        for (final pathInfo in paths) {
          // Make sure we're using each path's stored color
          final fillPaint = Paint()
            ..color = pathInfo.brushColor
            ..style = PaintingStyle.fill;

          canvas.drawPath(pathInfo.path, fillPaint);
        }
      } catch (e) {
        print('绘制已完成路径失败: $e');
      }
    }

    // Then draw the current path on top
    if (currentPath != null) {
      try {
        final fillPaint = Paint()
          ..color = currentPath!.brushColor
          ..style = PaintingStyle.fill;

        canvas.drawPath(currentPath!.path, fillPaint);
      } catch (e) {
        print('绘制当前路径失败: $e');
      }
    }
  }
}
