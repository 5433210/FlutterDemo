import 'package:flutter/material.dart';

import '../../../domain/models/character/path_info.dart';
import '../../../infrastructure/logging/logger.dart';
import 'base_layer.dart';

/// 预览图层，显示擦除预览效果
class PreviewLayer extends BaseLayer {
  final List<PathInfo> paths;
  final PathInfo? currentPath;
  final Rect? dirtyRect;
  final Size? imageSize;

  const PreviewLayer({
    Key? key,
    this.paths = const [],
    this.currentPath,
    this.dirtyRect,
    this.imageSize,
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
        imageSize: imageSize,
      );
}

class _PreviewPainter extends CustomPainter {
  final List<PathInfo> paths;
  final PathInfo? currentPath;
  final Rect? dirtyRect;
  final Size? imageSize;

  // Remove the unused path cache since it's not working correctly
  _PreviewPainter({
    required this.paths,
    this.currentPath,
    this.dirtyRect,
    this.imageSize,
  });
  @override
  void paint(Canvas canvas, Size size) {
    // Use the full image bounds as clipping area to allow erasing to the edges
    if (imageSize != null) {
      final imageRect =
          Rect.fromLTWH(0, 0, imageSize!.width, imageSize!.height);
      canvas.save();
      canvas.clipRect(imageRect);
    }

    // Apply global color blend mode - ensure erased areas display correctly
    final compositeMode = Paint()..blendMode = BlendMode.srcOver;
    canvas.saveLayer(null, compositeMode);

    try {
      // Draw all completed paths
      _drawAllPaths(canvas);

      // Draw current path if exists
      if (currentPath != null) {
        _drawCurrentPath(canvas);
      }
    } finally {
      canvas.restore(); // Restore the blend mode layer

      // Restore the clipping if it was applied
      if (imageSize != null) {
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) {
    final shouldRepaint = paths != oldDelegate.paths ||
        currentPath?.path != oldDelegate.currentPath?.path ||
        dirtyRect != oldDelegate.dirtyRect ||
        imageSize != oldDelegate.imageSize;

    return shouldRepaint;
  }

  /// 绘制所有已完成的路径
  void _drawAllPaths(Canvas canvas) {
    if (paths.isNotEmpty) {
      AppLogger.debug('绘制已完成路径', data: {'pathCount': paths.length});

      for (final pathInfo in paths) {
        if (pathInfo.path.getBounds().isEmpty ||
            !pathInfo.path.getBounds().isFinite) {
          AppLogger.debug('跳过无效路径');
          continue;
        }

        try {
          _drawPath(canvas, pathInfo);
        } catch (e) {
          AppLogger.error('绘制路径失败', error: e);
        }
      }
    }
  }

  /// 绘制当前活动路径
  void _drawCurrentPath(Canvas canvas) {
    if (currentPath != null) {
      try {
        _drawPath(canvas, currentPath!);
      } catch (e) {
        AppLogger.error('绘制当前路径失败', error: e);
      }
    }
  }

  /// 简化的高效绘制方法 - 移除模糊效果，改用反锯齿
  void _drawPath(Canvas canvas, PathInfo pathInfo) {
    final path = pathInfo.path;
    final color = pathInfo.brushColor;
    final brushSize = pathInfo.brushSize;

    // Skip empty or invalid paths
    final bounds = path.getBounds();
    if (bounds.isEmpty || !bounds.isFinite) return;

    // Clean stroke with anti-aliasing
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true; // Enable anti-aliasing
    // Remove maskFilter blur

    // Draw the path with anti-aliasing
    canvas.drawPath(path, strokePaint);
  }
}
