import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// 轮廓分析工具 - 用于调试轮廓检测算法
class ContourAnalyzer {
  /// 分析轮廓并生成调试图像
  static Uint8List analyzeContour(List<List<Offset>> contours, Size imageSize,
      {String? title, Map<int, String>? endpointReasons}) {
    if (kDebugMode) {
      print('开始分析轮廓...');
      print('图像尺寸: ${imageSize.width} x ${imageSize.height}');
      print('轮廓数量: ${contours.length}');
    }

    // 创建图像
    final image = img.Image(
        width: imageSize.width.toInt(), height: imageSize.height.toInt());

    // 填充白色背景
    img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));

    // 绘制轮廓
    for (int i = 0; i < contours.length; i++) {
      final contour = contours[i];

      // 选择不同的颜色
      final hue = (i * 45) % 360;
      final color = _hsvToRgb(hue.toDouble(), 1.0, 1.0);

      // 记录这条轮廓的信息
      if (kDebugMode) {
        print('轮廓 #$i: ${contour.length} 个点');

        if (contour.isNotEmpty) {
          print('  起点: (${contour.first.dx}, ${contour.first.dy})');
          print('  终点: (${contour.last.dx}, ${contour.last.dy})');

          // 显示终点原因（如果提供）
          final reason = endpointReasons?[i];
          if (reason != null) {
            print('  终点原因: $reason');
          }
        }
      }

      // 绘制轮廓线
      if (contour.length > 1) {
        for (int j = 1; j < contour.length; j++) {
          final p1 = contour[j - 1];
          final p2 = contour[j];
          _drawLine(image, p1.dx, p1.dy, p2.dx, p2.dy, color);
        }

        // 标记起点和终点
        _drawStartPoint(
            image, contour.first.dx.toInt(), contour.first.dy.toInt());
        _drawEndPoint(image, contour.last.dx.toInt(), contour.last.dy.toInt());

        // 绘制轮廓编号
        _drawNumber(image, i, contour.first.dx.toInt() + 5,
            contour.first.dy.toInt() + 5, img.ColorRgba8(0, 0, 0, 255));

        // 添加终点原因标签（如果提供）
        final reason = endpointReasons?[i];
        if (reason != null) {
          _drawText(
              image,
              '原因: ${reason.substring(0, math.min(reason.length, 20))}',
              contour.last.dx.toInt() + 5,
              contour.last.dy.toInt() + 5,
              img.ColorRgba8(255, 0, 0, 255));
        }
      }
    }

    // 如果有标题，绘制在图像顶部
    if (title != null) {
      _drawText(image, title, 10, 10, img.ColorRgba8(0, 0, 0, 255));
    }

    // 将图像编码为PNG
    return Uint8List.fromList(img.encodePng(image));
  }

  // 绘制字符
  static void _drawChar(
      img.Image image, String char, int x, int y, img.Color color) {
    // 这里只是一个简单的实现，可以扩展为更完整的字符集
    final String pattern = {
          'A': '01100100110011111001100110',
          'B': '11110100101111010010111100',
          'C': '01110100010001000100011100',
          'D': '11110100101001010010111100',
          'E': '11111000011110100001111100',
          'F': '11111000011110100001000000',
          '0': '01100100110011001100101100',
          '1': '00100011000010000100011100',
          '2': '01100100100001000100011110',
          '3': '01100100100001001001001100',
          '4': '10001000110001111000010000',
          '5': '11110100001110000011111000',
          '6': '01110100001111010001001110',
          '7': '11110000100010001000100000',
          '8': '01100100100110010010011000',
          '9': '01100100100111000010011000',
          ':': '00000010000000001000000000',
          ' ': '00000000000000000000000000',
          '-': '00000000001110000000000000',
          '_': '00000000000000000000111110',
        }[char.toUpperCase()] ??
        '00100010001000000001000000'; // 默认为'i'

    int index = 0;
    for (int row = 0; row < 5; row++) {
      for (int col = 0; col < 5; col++) {
        if (pattern[index] == '1') {
          final px = x + col;
          final py = y + row;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
        index++;
      }
    }
  }

  // 绘制终点标记（红色X）
  static void _drawEndPoint(img.Image image, int x, int y) {
    const size = 3;
    final color = img.ColorRgba8(255, 0, 0, 255); // 红色

    // 绘制X
    for (int i = -size; i <= size; i++) {
      final px1 = x + i;
      final py1 = y + i;
      final px2 = x + i;
      final py2 = y - i;

      if (px1 >= 0 && px1 < image.width && py1 >= 0 && py1 < image.height) {
        image.setPixel(px1, py1, color);
      }

      if (px2 >= 0 && px2 < image.width && py2 >= 0 && py2 < image.height) {
        image.setPixel(px2, py2, color);
      }
    }
  }

  // 绘制线条
  static void _drawLine(img.Image image, double x1, double y1, double x2,
      double y2, img.Color color) {
    // 使用Bresenham算法绘制线段
    int x1Int = x1.round(), y1Int = y1.round();
    int x2Int = x2.round(), y2Int = y2.round();

    int dx = (x2Int - x1Int).abs();
    int dy = (y2Int - y1Int).abs();
    int sx = x1Int < x2Int ? 1 : -1;
    int sy = y1Int < y2Int ? 1 : -1;
    int err = dx - dy;

    while (true) {
      // 检查边界并设置像素
      if (x1Int >= 0 &&
          x1Int < image.width &&
          y1Int >= 0 &&
          y1Int < image.height) {
        image.setPixel(x1Int, y1Int, color);
      }

      if (x1Int == x2Int && y1Int == y2Int) break;

      int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x1Int += sx;
      }

      if (e2 < dx) {
        err += dx;
        y1Int += sy;
      }
    }
  }

  // 绘制标记点
  static void _drawMarker(img.Image image, int x, int y, img.Color color) {
    const radius = 2;
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if (dx * dx + dy * dy <= radius * radius) {
          final px = x + dx;
          final py = y + dy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
      }
    }
  }

  // 在图像上绘制数字
  static void _drawNumber(
      img.Image image, int number, int x, int y, img.Color color) {
    _drawText(image, number.toString(), x, y, color);
  }

  // 绘制起点标记（绿色圆圈）
  static void _drawStartPoint(img.Image image, int x, int y) {
    const radius = 3;
    final color = img.ColorRgba8(0, 255, 0, 255); // 绿色

    // 绘制圆圈
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        if ((dx * dx + dy * dy <= radius * radius) &&
            (dx * dx + dy * dy > (radius - 1) * (radius - 1))) {
          final px = x + dx;
          final py = y + dy;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, color);
          }
        }
      }
    }
  }

  // 绘制文本
  static void _drawText(
      img.Image image, String text, int x, int y, img.Color color) {
    const charWidth = 6; // 每个字符的宽度
    int offsetX = 0;

    for (int i = 0; i < text.length; i++) {
      _drawChar(image, text[i], x + offsetX, y, color);
      offsetX += charWidth;
    }
  }

  // HSV转RGB
  static img.Color _hsvToRgb(double h, double s, double v) {
    h = h % 360;
    double c = v * s;
    double x = c * (1 - (((h / 60) % 2) - 1).abs());
    double m = v - c;

    double r, g, b;
    if (h < 60) {
      r = c;
      g = x;
      b = 0;
    } else if (h < 120) {
      r = x;
      g = c;
      b = 0;
    } else if (h < 180) {
      r = 0;
      g = c;
      b = x;
    } else if (h < 240) {
      r = 0;
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      g = 0;
      b = c;
    } else {
      r = c;
      g = 0;
      b = x;
    }

    int red = ((r + m) * 255).round();
    int green = ((g + m) * 255).round();
    int blue = ((b + m) * 255).round();

    return img.ColorRgba8(red, green, blue, 255);
  }
}
