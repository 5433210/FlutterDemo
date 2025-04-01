import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 路径可视化调试工具 - 帮助诊断路径问题
class PathVisualizer {
  static bool isEnabled = true;

  /// 可视化Path对象并保存到Widget
  static Widget pathToWidget(
    Path path, {
    Size size = const Size(300, 300),
    Color pathColor = Colors.red,
    double strokeWidth = 2.0,
  }) {
    return FutureBuilder<ui.Image>(
      future: visualizePath(path, size,
          pathColor: pathColor, strokeWidth: strokeWidth),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return const SizedBox(
            width: 50,
            height: 50,
            child: Icon(Icons.error),
          );
        }

        return RawImage(
          image: snapshot.data,
          width: size.width,
          height: size.height,
          fit: BoxFit.contain,
        );
      },
    );
  }

  /// 将Path对象可视化为图片
  static Future<ui.Image> visualizePath(
    Path path,
    Size size, {
    Color pathColor = Colors.red,
    double strokeWidth = 2.0,
    Color backgroundColor = Colors.white,
  }) async {
    if (!isEnabled) {
      // 创建1x1的空白图像
      final recorder = ui.PictureRecorder();
      final picture = recorder.endRecording();
      return picture.toImage(1, 1);
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 绘制背景
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = backgroundColor,
    );

    // 绘制网格
    _drawGrid(canvas, size);

    // 绘制路径
    canvas.drawPath(
      path,
      Paint()
        ..color = pathColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 获取路径的边界点
    final bounds = path.getBounds();

    // 绘制边界矩形
    canvas.drawRect(
      bounds,
      Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );

    // 绘制边界信息文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: '边界: (${bounds.left.toInt()},${bounds.top.toInt()}) '
            '${bounds.width.toInt()}x${bounds.height.toInt()}',
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));

    final picture = recorder.endRecording();
    return await picture.toImage(size.width.toInt(), size.height.toInt());
  }

  /// 绘制调试网格
  static void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 0.5;

    // 绘制垂直线
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 绘制水平线
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }
}
