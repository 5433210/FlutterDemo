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
      // 创建可重用的Paint对象以提高性能
      final paint = Paint();

      try {
        _drawPathsWithPaint(canvas, paint);
      } catch (e) {
        debugPrint('绘制路径失败: ${e.toString()}');
      }
    }
  }

  /// 绘制当前活动路径
  void _drawCurrentPath(Canvas canvas) {
    if (currentPath != null) {
      try {
        final paint = Paint()
          ..color = currentPath!.brushColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentPath!.brushSize;

        canvas.drawPath(currentPath!.path, paint);
      } catch (e) {
        debugPrint('绘制当前路径失败: ${e.toString()}');
      }
    }
  }

  /// 使用给定的Paint对象绘制所有路径
  ///
  /// 将绘制逻辑分离出来以提高代码可读性和可维护性
  void _drawPathsWithPaint(Canvas canvas, Paint paint) {
    for (final pathInfo in paths) {
      if (pathInfo.path.getBounds().isEmpty ||
          !pathInfo.path.getBounds().isFinite) {
        debugPrint('跳过无效路径');
        continue;
      }

      try {
        paint
          ..color = pathInfo.brushColor
          ..style = PaintingStyle.stroke // 使用描边样式来应用线条粗细
          ..strokeWidth = pathInfo.brushSize;

        canvas.drawPath(pathInfo.path, paint);
      } catch (e) {
        debugPrint('绘制单个路径失败: ${e.toString()}');
        // 继续绘制其他路径
      }
    }
  }
}
