import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

class CharacterImageProcessor {
  /// 根据框选区域裁剪图片
  /// 返回三种格式: 原图裁剪, 二值化处理后的图片, 缩略图
  Future<Map<String, String>> processCharacterImage({
    required String sourcePath,
    required String outputDir,
    required String charId,
    required Rect region,
    double rotation = 0.0,
    bool inverted = false,
    List<Offset>? erasePoints,
  }) async {
    // 创建输出目录
    final outputPath = path.join(outputDir, charId);
    await Directory(outputPath).create(recursive: true);

    // 读取源图
    final sourceImage = img.decodeImage(await File(sourcePath).readAsBytes());
    if (sourceImage == null) throw Exception('Failed to load source image');

    // 1. 裁剪原图 - 保持原始比例和尺寸
    final croppedOriginal = _cropImage(
      sourceImage,
      region.left.round(),
      region.top.round(),
      region.width.round(),
      region.height.round(),
    );
    if (croppedOriginal == null) throw Exception('Failed to crop image');

    // 旋转图片（如果需要）
    final rotatedOriginal = rotation != 0.0
        ? img.copyRotate(croppedOriginal,
            angle: (rotation * 180 / 3.141592653589793).round())
        : croppedOriginal;

    // 保存原图裁剪
    final originalPath = path.join(outputPath, 'original.png');
    await File(originalPath).writeAsBytes(img.encodePng(rotatedOriginal));

    // 2. 二值化处理
    final binaryImage = await _processBinaryImage(
      rotatedOriginal,
      inverted: inverted,
      targetSize: const Size(300, 300),
      erasePoints: erasePoints,
    );

    // 保存二值化图片
    final binaryPath = path.join(outputPath, 'char.png');
    await File(binaryPath).writeAsBytes(img.encodePng(binaryImage));

    // 3. 生成缩略图
    final thumbnail = img.copyResize(binaryImage, width: 50, height: 50);
    final thumbnailPath = path.join(outputPath, 'thumbnail.jpg');
    await File(thumbnailPath)
        .writeAsBytes(img.encodeJpg(thumbnail, quality: 85));

    return {
      'original': originalPath,
      'binary': binaryPath,
      'thumbnail': thumbnailPath,
    };
  }

  /// 自适应阈值二值化
  Uint8List _adaptiveThreshold(img.Image source,
      {int windowSize = 11, int t = 15}) {
    final width = source.width;
    final height = source.height;
    final result = Uint8List(width * height);
    final integralImg = List.filled(width * height, 0);

    // 计算积分图
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pos = y * width + x;
        final pixel = source.getPixel(x, y).r.toInt();
        integralImg[pos] = pixel +
            (x > 0 ? integralImg[pos - 1] : 0) +
            (y > 0 ? integralImg[pos - width] : 0) -
            (x > 0 && y > 0 ? integralImg[pos - width - 1] : 0);
      }
    }

    // 应用自适应阈值
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pos = y * width + x;
        final pixel = source.getPixel(x, y).r.toInt();

        // 计算局部窗口的边界
        final x1 = x - windowSize ~/ 2;
        final y1 = y - windowSize ~/ 2;
        final x2 = x + windowSize ~/ 2;
        final y2 = y + windowSize ~/ 2;

        // 确保窗口在图像范围内并转换为整数
        final rx1 = x1 < 0
            ? 0
            : x1 >= width
                ? width - 1
                : x1;
        final ry1 = y1 < 0
            ? 0
            : y1 >= height
                ? height - 1
                : y1;
        final rx2 = x2 < 0
            ? 0
            : x2 >= width
                ? width - 1
                : x2;
        final ry2 = y2 < 0
            ? 0
            : y2 >= height
                ? height - 1
                : y2;

        // 计算窗口内的平均值
        final areaWidth = (rx2 - rx1);
        final areaHeight = (ry2 - ry1);
        final area = areaWidth * areaHeight;

        if (area > 0) {
          final sum = integralImg[ry2 * width + rx2] -
              (rx1 > 0 ? integralImg[ry2 * width + rx1 - 1] : 0) -
              (ry1 > 0 ? integralImg[ry1 * width + rx2] : 0) +
              (rx1 > 0 && ry1 > 0 ? integralImg[ry1 * width + rx1 - 1] : 0);
          final average = sum ~/ area;
          result[pos] = pixel < (average - t) ? 0 : 255;
        } else {
          result[pos] = pixel < t ? 0 : 255;
        }
      }
    }

    return result;
  }

  /// 裁剪图片
  img.Image? _cropImage(img.Image source, int x, int y, int width, int height) {
    return img.copyCrop(
      source,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }

  /// 画线（用于擦除）
  void _drawLine(
    img.Image image,
    int x1,
    int y1,
    int x2,
    int y2,
    int color, {
    int thickness = 1,
  }) {
    final dx = (x2 - x1).abs();
    final dy = (y2 - y1).abs();
    final sx = x1 < x2 ? 1 : -1;
    final sy = y1 < y2 ? 1 : -1;
    var err = dx - dy;

    while (true) {
      // 绘制粗线
      for (int i = -thickness ~/ 2; i <= thickness ~/ 2; i++) {
        for (int j = -thickness ~/ 2; j <= thickness ~/ 2; j++) {
          final px = x1 + i;
          final py = y1 + j;
          if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
            image.setPixel(px, py, img.ColorInt8.rgb(color, color, color));
          }
        }
      }

      if (x1 == x2 && y1 == y2) break;
      final e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x1 += sx;
      }
      if (e2 < dx) {
        err += dx;
        y1 += sy;
      }
    }
  }

  /// 二值化处理并调整尺寸
  Future<img.Image> _processBinaryImage(
    img.Image source, {
    bool inverted = false,
    Size targetSize = const Size(300, 300),
    List<Offset>? erasePoints,
  }) async {
    // 转换为灰度图
    final grayscale = img.grayscale(source);

    // 应用擦除点
    if (erasePoints != null && erasePoints.isNotEmpty) {
      for (int i = 0; i < erasePoints.length - 1; i++) {
        _drawLine(
          grayscale,
          erasePoints[i].dx.round(),
          erasePoints[i].dy.round(),
          erasePoints[i + 1].dx.round(),
          erasePoints[i + 1].dy.round(),
          255, // 白色
          thickness: 10,
        );
      }
    }

    // 应用自适应阈值进行二值化
    final binary = _adaptiveThreshold(grayscale);

    // 如果需要反转颜色
    if (inverted) {
      for (int i = 0; i < binary.length; i++) {
        binary[i] = binary[i] == 0 ? 255 : 0;
      }
    }

    // 调整大小，保持宽高比
    final aspectRatio = source.width / source.height;
    int newWidth, newHeight;
    if (aspectRatio > 1) {
      newWidth = targetSize.width.round();
      newHeight = (targetSize.width / aspectRatio).round();
    } else {
      newHeight = targetSize.height.round();
      newWidth = (targetSize.height * aspectRatio).round();
    }

    // 创建目标尺寸的空白图像
    final resized = img.Image(
      width: targetSize.width.round(),
      height: targetSize.height.round(),
      format: img.Format.uint8,
    );

    // 将二值化图像调整到新尺寸并居中放置
    final scaled = img.copyResize(
      img.Image.fromBytes(
        width: source.width,
        height: source.height,
        bytes: binary.buffer,
        format: img.Format.uint8,
      ),
      width: newWidth,
      height: newHeight,
    );

    // 计算居中位置
    final x = ((targetSize.width - newWidth) / 2).round();
    final y = ((targetSize.height - newHeight) / 2).round();

    // 将调整后的图像复制到目标图像的中心
    img.compositeImage(resized, scaled, dstX: x, dstY: y);

    return resized;
  }
}
