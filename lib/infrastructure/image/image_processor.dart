import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../domain/models/character/detected_outline.dart';

/// 图片处理器接口
abstract class ImageProcessor {
  /// 临时文件目录
  String get tempPath;

  /// 缩略图缓存目录
  String get thumbnailCachePath;

  /// 应用擦除区域
  Future<Uint8List> applyEraseMask(
      Uint8List image, List<List<Offset>> erasePaths, double brushSize);

  /// 二值化图像
  Future<Uint8List> binarizeImage(
      Uint8List image, double threshold, bool inverted);

  /// 清理临时文件
  Future<void> cleanupTempFiles();

  /// 创建占位图
  ///
  /// 创建指定尺寸的占位图
  Future<File> createPlaceholder(int width, int height);

  /// 创建SVG轮廓
  Future<String> createSvgOutline(DetectedOutline outline);

  /// 创建临时文件
  Future<File> createTempFile(String prefix);

  /// 生成缩略图
  Future<Uint8List> createThumbnail(Uint8List image, int maxSize);

  /// 裁剪图像
  Future<Uint8List> cropImage(Uint8List sourceImage, Rect region);

  /// 降噪处理
  Future<Uint8List> denoiseImage(Uint8List binaryImage, double noiseReduction);

  /// 检测轮廓
  Future<DetectedOutline> detectOutline(Uint8List binaryImage);

  /// 优化图片
  ///
  /// 优化图片质量和大小
  Future<File> optimizeImage(File input);

  /// 处理图片
  ///
  /// 按指定尺寸和质量处理图片
  Future<File> processImage(
    File input, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  });

  /// 调整图片大小
  ///
  /// 按指定尺寸调整图片，保持宽高比
  Future<File> resizeImage(
    File input, {
    required int width,
    required int height,
  });

  /// 旋转图片
  ///
  /// [degrees] 旋转角度(90, 180, 270)
  Future<File> rotateImage(File input, int degrees);
}
