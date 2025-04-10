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

  // Remove the unused path cache since it's not working correctly
  _PreviewPainter({
    required this.paths,
    this.currentPath,
    this.dirtyRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (kDebugMode && DebugFlags.enableEraseDebug) {
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
        debugPrint('绘制当前路径失败: ${e.toString()}');
      }
    }
  }

  /// 简化的高效绘制方法 - 替换原来的复杂方法
  void _drawPath(Canvas canvas, PathInfo pathInfo) {
    final path = pathInfo.path;
    final color = pathInfo.brushColor;
    final brushSize = pathInfo.brushSize;

    // Skip empty or invalid paths
    final bounds = path.getBounds();
    if (bounds.isEmpty || !bounds.isFinite) return;

    // Main outer glow - soft edge
    final softPaint = Paint()
      ..color =
          color.withOpacity(0.7) // Increased opacity for better visibility
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal, 2.0); // Slightly stronger blur

    // Inner stroke - for solid center
    final solidPaint = Paint()
      ..color = color.withOpacity(0.9) // More opaque for the center
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushSize * 0.7 // Smaller width for the solid center
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw the path with both effects
    canvas.drawPath(path, softPaint); // Outer glow
    canvas.drawPath(path, solidPaint); // Inner solid stroke

    // For debugging - draw a dot at each endpoint
    if (kDebugMode && DebugFlags.enableEraseDebug) {
      final pointPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;

      final metrics = path.computeMetrics();
      if (metrics.isNotEmpty) {
        for (final metric in metrics) {
          if (metric.length > 0) {
            final start = metric.getTangentForOffset(0)?.position;
            final end = metric.getTangentForOffset(metric.length)?.position;

            if (start != null) {
              canvas.drawCircle(start, 3, pointPaint);
            }
            if (end != null) {
              canvas.drawCircle(end, 3, pointPaint);
            }
          }
        }
      } else {
        // For paths too small to have metrics
        canvas.drawCircle(bounds.center, 3, pointPaint);
      }
    }
  }
}
