import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../domain/models/character/detected_outline.dart';

/// 图片处理器接口
abstract class ImageProcessor {
  /// 临时文件目录
  String get tempPath;

  /// 缩略图缓存目录
  String get thumbnailCachePath;

  /// 应用颜色变换
  ///
  /// 对图像应用颜色变换
  /// [sourceImage] 源图像
  /// [color] 目标颜色
  /// [opacity] 不透明度
  /// [invert] 是否反转颜色
  img.Image applyColorTransform(
      img.Image sourceImage, Color color, double opacity, bool invert);

  /// 应用擦除区域
  Future<Uint8List> applyEraseMask(
      Uint8List image, List<List<Offset>> erasePaths, double brushSize);

  /// 二值化图像
  img.Image binarizeImage(img.Image source, double threshold, bool inverted);

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
  img.Image denoiseImage(img.Image source, double strength);

  /// 检测轮廓
  DetectedOutline detectOutline(img.Image binaryImage, bool isInverted);

  /// 优化图片
  ///
  /// 优化图片质量和大小
  Future<File> optimizeImage(File input);

  /// 处理集字图像
  ///
  /// 根据变换参数处理集字图像
  /// [sourceImage] 源图像数据
  /// [format] 图像格式（png-binary, png-transparent, svg-outline）
  /// [transform] 变换参数
  Future<Uint8List> processCharacterImage(
      Uint8List sourceImage, String format, Map<String, dynamic> transform);

  /// 处理图片
  ///
  /// 按指定尺寸和质量处理图片
  Future<File> processImage(
    File input, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
    double rotation = 0.0, // 旋转角度（度）
  });

  /// 处理SVG轮廓
  ///
  /// 处理SVG轮廓图像
  /// [svgContent] SVG内容
  /// [color] 目标颜色
  /// [opacity] 不透明度
  /// [scale] 缩放比例
  /// [rotation] 旋转角度
  /// [invert] 是否反转颜色
  Future<Uint8List> processSvgOutline(String svgContent, Color color,
      double opacity, double scale, double rotation, bool invert);

  /// 调整图片大小
  ///
  /// 按指定尺寸调整图片，保持宽高比
  Future<File> resizeImage(
    File input, {
    required int width,
    required int height,
  });

  /// 对图像进行基于选区中心的旋转和裁剪处理
  ///
  /// [sourceImage] 源图像
  /// [region] 选区矩形
  /// [rotation] 旋转角度
  /// [flipHorizontal] 是否水平翻转
  /// [flipVertical] 是否垂直翻转
  /// 返回处理后的图像
  img.Image rotateAndCropImage(
      img.Image sourceImage, Rect region, double rotation,
      {bool? flipHorizontal, bool? flipVertical});

  /// 对图像进行翻转后再裁剪和旋转处理
  /// 
  /// 与rotateAndCropImage不同，此方法先对原图像应用翻转变换，
  /// 然后调整裁剪区域坐标，最后进行裁剪和旋转
  ///
  /// [sourceImage] 源图像
  /// [region] 选区矩形（基于原图像坐标系）
  /// [rotation] 旋转角度
  /// [flipHorizontal] 是否水平翻转
  /// [flipVertical] 是否垂直翻转
  /// 返回处理后的图像
  img.Image flipThenCropImage(
      img.Image sourceImage, Rect region, double rotation,
      {bool? flipHorizontal, bool? flipVertical});

  /// 旋转图片
  ///
  /// [degrees] 旋转角度(90, 180, 270)
  Future<File> rotateImage(File input, int degrees);

  /// 验证图像数据是否可解码
  Future<bool> validateImageData(Uint8List data);
}
