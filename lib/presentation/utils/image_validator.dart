import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // 导入 Size 类型

/// 图像元数据
class ImageMetadata {
  final int width;
  final int height;
  final int sizeInBytes;
  final String format;

  const ImageMetadata({
    required this.width,
    required this.height,
    required this.sizeInBytes,
    required this.format,
  });
}

/// 图像验证工具类
class ImageValidator {
  /// 验证图像文件是否有效
  static Future<bool> validateImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      return await validateImageBytes(bytes);
    } catch (e) {
      debugPrint('图像文件验证失败: $e');
      return false;
    }
  }

  /// 验证图像字节数据是否有效
  static Future<bool> validateImageBytes(Uint8List bytes) async {
    try {
      if (bytes.isEmpty) {
        return false;
      }

      // 尝试创建图像描述符来验证数据
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      // 检查图像尺寸是否合理
      final image = frame.image;
      if (image.width <= 0 || image.height <= 0) {
        return false;
      }

      // 检查图像尺寸是否过大（防止内存溢出）
      const maxDimension = 8192; // 8K分辨率限制
      if (image.width > maxDimension || image.height > maxDimension) {
        debugPrint('图像尺寸过大: ${image.width}x${image.height}');
        return false;
      }

      image.dispose();
      return true;
    } catch (e) {
      debugPrint('图像数据验证失败: $e');
      return false;
    }
  }

  /// 直接解码图像数据（绕过Flutter限制）
  static img.Image? decodeImage(Uint8List bytes) {
    try {
      return img.decodeImage(bytes);
    } catch (e) {
      debugPrint('image包解码图像失败: $e');
      return null;
    }
  }

  /// 获取图像的真实尺寸（使用 image 包绕过Flutter显示限制）
  static Future<Size?> getRealImageSize(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      
      // 🔧 关键修复：使用 image 包直接解码，避免Flutter的GPU纹理限制
      final image = img.decodeImage(bytes);
      if (image == null) {
        debugPrint('image包无法解码图像: $filePath');
        return null;
      }

      final realSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      debugPrint('通过image包检测到图像真实尺寸: ${realSize.width.toInt()}x${realSize.height.toInt()}');
      return realSize;
    } catch (e) {
      debugPrint('获取图像真实尺寸失败: $e');
      return null;
    }
  }

  /// 获取图像的真实尺寸（旧方法，受Flutter限制）
  @deprecated
  static Future<Size?> getRealImageSizeOld(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final realSize = Size(
        image.width.toDouble(),
        image.height.toDouble(),
      );

      image.dispose();
      codec.dispose();
      
      debugPrint('检测到图像真实尺寸: ${realSize.width.toInt()}x${realSize.height.toInt()}');
      return realSize;
    } catch (e) {
      debugPrint('获取图像真实尺寸失败: $e');
      return null;
    }
  }

  /// 验证并获取图像信息
  static Future<ImageMetadata?> getImageInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      return ImageMetadata(
        width: image.width,
        height: image.height,
        sizeInBytes: bytes.length,
        format: _detectImageFormat(bytes),
      );
    } catch (e) {
      debugPrint('获取图像信息失败: $e');
      return null;
    }
  }

  /// 检测图像格式
  static String _detectImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return 'unknown';

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'PNG';
    }

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'JPEG';
    }

    // GIF: 47 49 46 38
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'GIF';
    }

    // BMP: 42 4D
    if (bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return 'BMP';
    }

    // WebP: 52 49 46 46 (前4字节)
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'WebP';
    }

    return 'unknown';
  }

  /// 尝试修复损坏的图像文件（如果可能）
  static Future<bool> tryRepairImageFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return false;
      }

      final bytes = await file.readAsBytes();

      // 检查文件是否为空或过小
      if (bytes.length < 100) {
        debugPrint('图像文件过小，无法修复');
        return false;
      }

      // 尝试验证原始数据
      if (await validateImageBytes(bytes)) {
        return true; // 文件本身没问题
      }

      // 尝试移除文件末尾的无效数据
      final format = _detectImageFormat(bytes);
      if (format == 'JPEG') {
        return await _tryRepairJpeg(file, bytes);
      } else if (format == 'PNG') {
        return await _tryRepairPng(file, bytes);
      }

      return false;
    } catch (e) {
      debugPrint('修复图像文件失败: $e');
      return false;
    }
  }

  /// 尝试修复JPEG文件
  static Future<bool> _tryRepairJpeg(File file, Uint8List bytes) async {
    try {
      // 查找JPEG结束标记 FF D9
      int endIndex = -1;
      for (int i = bytes.length - 2; i >= 0; i--) {
        if (bytes[i] == 0xFF && bytes[i + 1] == 0xD9) {
          endIndex = i + 2;
          break;
        }
      }

      if (endIndex > 0 && endIndex < bytes.length) {
        final repairedBytes = bytes.sublist(0, endIndex);
        if (await validateImageBytes(repairedBytes)) {
          await file.writeAsBytes(repairedBytes);
          debugPrint('JPEG文件修复成功');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('修复JPEG文件失败: $e');
      return false;
    }
  }

  /// 尝试修复PNG文件
  static Future<bool> _tryRepairPng(File file, Uint8List bytes) async {
    try {
      // PNG文件应该以 IEND 块结束
      // 查找 IEND 块 (49 45 4E 44)
      int endIndex = -1;
      for (int i = bytes.length - 12; i >= 0; i--) {
        if (bytes[i + 4] == 0x49 &&
            bytes[i + 5] == 0x45 &&
            bytes[i + 6] == 0x4E &&
            bytes[i + 7] == 0x44) {
          endIndex = i + 12; // IEND块长度 + 4字节CRC
          break;
        }
      }

      if (endIndex > 0 && endIndex <= bytes.length) {
        final repairedBytes = bytes.sublist(0, endIndex);
        if (await validateImageBytes(repairedBytes)) {
          await file.writeAsBytes(repairedBytes);
          debugPrint('PNG文件修复成功');
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('修复PNG文件失败: $e');
      return false;
    }
  }
}

/// 图像信息类
class ImageInfo {
  final int width;
  final int height;
  final int sizeInBytes;
  final String format;

  const ImageInfo({
    required this.width,
    required this.height,
    required this.sizeInBytes,
    required this.format,
  });

  @override
  String toString() {
    return 'ImageInfo(${width}x$height, ${(sizeInBytes / 1024).toStringAsFixed(1)}KB, $format)';
  }
}
