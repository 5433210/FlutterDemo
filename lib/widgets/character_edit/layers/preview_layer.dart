import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/character/path_info.dart';
import '../../../infrastructure/logging/logger.dart';
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

  // Add a cache for rendered paths to avoid redundant work
  final Map<int, ui.Image> _pathCache = {};

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

      // Draw current path if exists
      if (currentPath != null) {
        _drawCurrentPath(canvas);
      }
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

  /// 绘制所有已完成的路径
  void _drawAllPaths(Canvas canvas) {
    if (paths.isNotEmpty) {
      for (final pathInfo in paths) {
        if (pathInfo.path.getBounds().isEmpty ||
            !pathInfo.path.getBounds().isFinite) {
          AppLogger.debug('跳过无效路径');
          continue;
        }

        try {
          _drawEfficientSoftEdgePath(canvas, pathInfo);
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
        // Current path should always be rendered freshly (not cached)
        // since it's actively changing
        _drawEfficientSoftEdgePath(canvas, currentPath!, useCache: false);
      } catch (e) {
        debugPrint('绘制当前路径失败: ${e.toString()}');
      }
    }
  }

  /// 高效绘制带软边缘效果的路径
  ///
  /// Uses an optimized approach with fewer draw operations and optional caching
  void _drawEfficientSoftEdgePath(Canvas canvas, PathInfo pathInfo,
      {bool useCache = true}) {
    final path = pathInfo.path;
    final color = pathInfo.brushColor;
    final brushSize = pathInfo.brushSize;

    // Skip empty or invalid paths
    final bounds = path.getBounds();
    if (bounds.isEmpty || !bounds.isFinite) return;

    // Check if this path is already cached (for completed paths only)
    final pathHash = useCache ? path.hashCode : -1;
    if (useCache && _pathCache.containsKey(pathHash)) {
      // Draw from cache if available
      final cachedImage = _pathCache[pathHash]!;
      canvas.drawImage(cachedImage, Offset.zero, Paint());
      return;
    }

    // For short straight line paths or single points, use simplified approach
    if (_isSimplePath(path)) {
      _drawSimplifiedPath(canvas, pathInfo);
      return;
    }

    // For complex paths, use a more efficient approach with minimal blur
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal,
          1.0); // Reduced blur to just 1.0 to match processing

    // Draw the path with minimal blur
    canvas.drawPath(path, paint);

    // Optional: draw solid center for a more accurate representation
    if (brushSize > 5.0) {
      // Only for larger brushes
      final centerPaint = Paint()
        ..color = color.withOpacity(0.7) // More opaque center
        ..style = PaintingStyle.stroke
        ..strokeWidth = brushSize * 0.85 // Larger solid center
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, centerPaint);
    }
  }

  /// Draws a simplified path for short segments
  void _drawSimplifiedPath(Canvas canvas, PathInfo pathInfo) {
    final bounds = pathInfo.path.getBounds();
    final center = bounds.center;
    final color = pathInfo.brushColor;
    final radius = pathInfo.brushSize / 2;

    // Create a more defined gradient with less blur for short paths
    final gradient = ui.Gradient.radial(center, radius * 1.05, [
      color.withOpacity(0.9),
      color.withOpacity(0.7),
      color.withOpacity(0.0),
    ], [
      0.0,
      0.9, // Sharper transition
      1.0
    ]);

    final paint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        center, radius * 1.05, paint); // Only slightly larger than radius
  }

  /// Determines if a path is simple enough for simplified rendering
  bool _isSimplePath(Path path) {
    try {
      final metrics = path.computeMetrics();
      if (metrics.isEmpty) return true;

      final metric = metrics.first;
      // A path is considered simple if it's very short
      return metric.length < 10;
    } catch (e) {
      return true; // Handle as simple if we can't compute metrics
    }
  }
}
