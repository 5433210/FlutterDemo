import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 路径调试工具类
class PathDebugUtils {
  static bool debugEnabled = true;

  /// 打印路径信息
  static void printPathsInfo(List<Map<String, dynamic>> paths) {
    if (!debugEnabled) return;

    print('==== 路径信息 ====');
    print('路径总数: ${paths.length}');

    for (int i = 0; i < paths.length; i++) {
      final pathData = paths[i];
      final points = pathData['points'] as List<Offset>;
      final brushSize = (pathData['brushSize'] as num).toDouble();

      print('路径 #$i:');
      print('  点数: ${points.length}');
      print('  笔刷大小: $brushSize');

      if (points.isNotEmpty) {
        print('  起点: ${points.first}');
        print('  终点: ${points.last}');

        // 计算路径总长度
        double totalLength = 0;
        for (int j = 1; j < points.length; j++) {
          totalLength += (points[j] - points[j - 1]).distance;
        }
        print('  长度: ${totalLength.toStringAsFixed(1)}');
      }
    }

    print('================');
  }

  /// 图像调试 - 在独立画布上绘制路径用于调试
  static Future<ui.Image> visualizePaths(
      List<Map<String, dynamic>> paths, Size size,
      {Color background = Colors.white}) async {
    if (!debugEnabled) return _createEmptyImage(1, 1);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 绘制背景
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    // 绘制每个路径
    for (final pathData in paths) {
      final points = pathData['points'] as List<Offset>;
      final brushSize = (pathData['brushSize'] as num).toDouble();

      if (points.length < 2) continue;

      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(
          path,
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.stroke
            ..strokeWidth = brushSize
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);

      // 绘制起点和终点标记
      _drawPointMarker(canvas, points.first, Colors.green);
      _drawPointMarker(canvas, points.last, Colors.blue);
    }

    // 转换为图像
    final picture = recorder.endRecording();
    return await picture.toImage(size.width.ceil(), size.height.ceil());
  }

  /// 创建空图像
  static Future<ui.Image> _createEmptyImage(int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final picture = recorder.endRecording();
    return picture.toImage(width, height);
  }

  /// 绘制点标记
  static void _drawPointMarker(Canvas canvas, Offset point, Color color) {
    canvas.drawCircle(point, 3.0, Paint()..color = color);
  }
}
