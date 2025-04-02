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
  final Color brushColor;
  final double brushSize;
  final Rect? dirtyRect;

  const PreviewLayer({
    Key? key,
    this.paths = const [],
    this.currentPath,
    this.brushColor = Colors.white,
    this.brushSize = 10.0,
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
    if (kDebugMode) {
      print('绘制预览层 - 路径数量: ${paths.length}, 当前路径: ${currentPath != null}');
    }

    // 创建填充画笔
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 0 // 填充模式不需要描边宽度
      ..isAntiAlias = true;

    // 尝试合并并绘制已完成的路径
    if (paths.isNotEmpty) {
      try {
        // 合并所有已完成的路径
        final pathsList = paths.map((p) => p.path).toList();
        final completePath = PathUtils.mergePaths(pathsList);

        if (!PathUtils.isPathEmpty(completePath)) {
          print('绘制已完成路径');
          canvas.drawPath(completePath, paint..color = brushColor);
        }
      } catch (e) {
        print('合并路径失败，尝试单独绘制: $e');
        // 如果合并失败，逐个绘制每个路径
        for (final pathInfo in paths) {
          try {
            canvas.drawPath(pathInfo.path, paint..color = pathInfo.brushColor);
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
        canvas.drawPath(
          PathUtils.clonePath(currentPath!.path),
          paint..color = currentPath!.brushColor,
        );
      } catch (e) {
        print('绘制当前路径失败: $e');
      }
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
        brushColor != oldDelegate.brushColor ||
        brushSize != oldDelegate.brushSize ||
        dirtyRect != oldDelegate.dirtyRect;

    if (shouldRepaint && kDebugMode) {
      print('重绘预览层');
    }

    return shouldRepaint;
  }
}
