import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 背景检测器，用于确定图像背景色和擦除颜色
class EraseBackgroundDetector {
  /// 检测图像是否为黑白二值图
  /// 如果是二值图，会返回应该使用的背景颜色(白色或黑色)
  static Future<Color> detectBackgroundColor(ui.Image image) async {
    // 获取图像边缘像素样本来确定背景色
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return Colors.white; // 默认使用白色背景

    final bytes = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    // 采样点数量
    const sampleSize = 20;

    // 统计边缘像素颜色
    int whiteCount = 0;
    int blackCount = 0;

    // 采样函数
    void samplePixel(int x, int y) {
      if (x < 0 || x >= width || y < 0 || y >= height) return;

      final pixelIndex = (y * width + x) * 4; // 4 bytes per pixel (RGBA)
      final r = bytes[pixelIndex];
      final g = bytes[pixelIndex + 1];
      final b = bytes[pixelIndex + 2];

      // 判断是亮色还是暗色
      final brightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
      if (brightness > 0.7) {
        whiteCount++;
      } else if (brightness < 0.3) {
        blackCount++;
      }
    }

    // 采样图像边缘
    for (int i = 0; i < sampleSize; i++) {
      // 上边缘
      samplePixel((width * i) ~/ sampleSize, 0);
      // 下边缘
      samplePixel((width * i) ~/ sampleSize, height - 1);
      // 左边缘
      samplePixel(0, (height * i) ~/ sampleSize);
      // 右边缘
      samplePixel(width - 1, (height * i) ~/ sampleSize);
    }

    print('Background detection - white: $whiteCount, black: $blackCount');

    // 判断背景色：如果边缘区域白色像素更多，则判定为白色背景
    if (whiteCount >= blackCount) {
      return Colors.white;
    } else {
      return Colors.black;
    }
  }

  /// 判断图像是否为黑白二值图
  static Future<bool> isBlackAndWhiteImage(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return false;

    final bytes = byteData.buffer.asUint8List();
    final width = image.width;
    final height = image.height;

    // 随机采样点数量
    const sampleCount = 100;
    const threshold = 30; // 灰度阈值

    bool hasGray = false;

    // 随机采样检测是否存在大量灰度值
    for (int i = 0; i < sampleCount; i++) {
      final x = (i * width / sampleCount).toInt();
      final y = (i * height / sampleCount).toInt();

      final pixelIndex = (y * width + x) * 4;
      final r = bytes[pixelIndex];
      final g = bytes[pixelIndex + 1];
      final b = bytes[pixelIndex + 2];

      // 检查是否为明显的灰度（非黑白）
      if ((r > threshold && r < 225) ||
          (g > threshold && g < 225) ||
          (b > threshold && b < 225)) {
        // 检查RGB是否接近一致（灰度特征）
        final maxDiff = max(max((r - g).abs(), (r - b).abs()), (g - b).abs());
        if (maxDiff < 20) {
          hasGray = true;
          break;
        }
      }
    }

    return !hasGray; // 如果没有明显的灰度值，判定为黑白图像
  }
}
