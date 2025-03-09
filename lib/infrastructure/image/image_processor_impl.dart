import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'image_processor.dart';

/// 图片处理器实现
class ImageProcessorImpl implements ImageProcessor {
  const ImageProcessorImpl();

  @override
  Future<Uint8List?> createThumbnail(
    String imagePath, {
    required int width,
    int? height,
  }) async {
    try {
      final bytes = await loadImage(imagePath);
      if (bytes == null) return null;

      // 解码图片
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 计算缩略图尺寸
      final targetHeight = height ?? (width * image.height ~/ image.width);

      // 创建缩略图
      final thumbnail = img.copyResize(
        image,
        width: width,
        height: targetHeight,
        interpolation: img.Interpolation.average,
      );

      // 编码为JPEG格式（较小文件大小）
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List?> cropImage(
    String imagePath, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      final bytes = await loadImage(imagePath);
      if (bytes == null) return null;

      // 解码图片
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 执行裁剪
      final cropped = img.copyCrop(
        image,
        x: x,
        y: y,
        width: width,
        height: height,
      );

      // 编码为PNG格式
      return Uint8List.fromList(img.encodePng(cropped));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> getImageInfo(String imagePath) async {
    try {
      final bytes = await loadImage(imagePath);
      if (bytes == null) return null;

      // 解码图片
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 返回基本信息
      return {
        'width': image.width,
        'height': image.height,
        'format': _getImageFormat(bytes),
        'size': bytes.length,
        'hasAlpha': image.hasAlpha,
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List?> loadImage(String path) async {
    try {
      final file = File(path);
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List?> resizeImage(
    String imagePath, {
    required int width,
    int? height,
  }) async {
    try {
      final bytes = await loadImage(imagePath);
      if (bytes == null) return null;

      // 解码图片
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 计算目标高度（保持宽高比）
      final targetHeight = height ?? (width * image.height ~/ image.width);

      // 执行缩放
      final resized = img.copyResize(
        image,
        width: width,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      // 编码为PNG格式
      return Uint8List.fromList(img.encodePng(resized));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Uint8List?> rotateImage(String imagePath, int angle) async {
    try {
      final bytes = await loadImage(imagePath);
      if (bytes == null) return null;

      // 解码图片
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // 执行旋转
      final rotated = img.copyRotate(image, angle: angle);

      // 编码为PNG格式
      return Uint8List.fromList(img.encodePng(rotated));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> saveImage(Uint8List data, String path) async {
    try {
      final file = File(path);
      await file.writeAsBytes(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取图片格式
  String _getImageFormat(Uint8List bytes) {
    if (bytes.length < 12) return 'unknown';

    // 检查文件头
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return 'jpeg';
    } else if (bytes[0] == 0x89 && bytes[1] == 0x50) {
      return 'png';
    } else if (bytes[0] == 0x47 && bytes[1] == 0x49) {
      return 'gif';
    } else if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'bmp';
    }

    return 'unknown';
  }
}
