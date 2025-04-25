import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:xml/xml.dart';

import './image_processor.dart';

/// 扩展 ImageProcessor 接口，添加处理集字图像所需的方法
extension CharacterImageProcessorExtension on ImageProcessor {
  /// 应用颜色变换
  ///
  /// 对图像应用颜色变换
  /// [sourceImage] 源图像
  /// [color] 目标颜色
  /// [opacity] 不透明度
  /// [invert] 是否反转颜色
  img.Image applyColorTransform(
      img.Image sourceImage, Color color, double opacity, bool invert) {
    // 创建新图像
    final resultImage = img.Image(
      width: sourceImage.width,
      height: sourceImage.height,
    );

    // 应用颜色、不透明度和反转
    for (int y = 0; y < sourceImage.height; y++) {
      for (int x = 0; x < sourceImage.width; x++) {
        final pixel = sourceImage.getPixel(x, y);
        final r = pixel.getChannel(img.Channel.red);
        final g = pixel.getChannel(img.Channel.green);
        final b = pixel.getChannel(img.Channel.blue);
        final a = pixel.getChannel(img.Channel.alpha);

        if (a > 0) {
          // 计算亮度（简化版）
          final brightness = (r + g + b) / 3;

          // 应用反转
          int newR, newG, newB, newA;

          if (invert) {
            // 反转颜色
            if (brightness < 128) {
              // 原来是深色（如黑色），变为浅色（使用指定颜色）
              newR = color.red;
              newG = color.green;
              newB = color.blue;
              newA = (a * opacity).round();
            } else {
              // 原来是浅色（如白色），变为透明
              newR = newG = newB = 0;
              newA = 0;
            }
          } else {
            // 不反转，但应用颜色
            if (brightness < 128) {
              // 深色部分应用指定颜色
              newR = color.red;
              newG = color.green;
              newB = color.blue;
              newA = (a * opacity).round();
            } else {
              // 浅色部分保持原样或变透明（取决于图像类型）
              newR = newG = newB = 255;
              newA = (a * opacity).round();
            }
          }

          final newPixel = img.ColorRgba8(newR, newG, newB, newA);
          resultImage.setPixel(x, y, newPixel);
        }
      }
    }

    return resultImage;
  }

  /// 处理集字图像
  ///
  /// 根据变换参数处理集字图像
  /// [sourceImage] 源图像数据
  /// [format] 图像格式（png-binary, png-transparent, svg-outline）
  /// [transform] 变换参数
  Future<Uint8List> processCharacterImage(Uint8List sourceImage, String format,
      Map<String, dynamic> transform) async {
    // 解析变换参数
    final scale = transform['scale'] as double? ?? 1.0;
    final rotation = transform['rotation'] as double? ?? 0.0;
    final colorStr = transform['color'] as String? ?? '#000000';
    final opacity = transform['opacity'] as double? ?? 1.0;
    final invert = transform['invert'] as bool? ?? false;

    // 解析颜色
    final color = _parseColor(colorStr);

    // 根据不同格式选择不同的处理方法
    if (format == 'png-binary' || format == 'png-transparent') {
      return _processPngImage(
          sourceImage, color, opacity, scale, rotation, invert);
    } else if (format == 'svg-outline') {
      final svgString = utf8.decode(sourceImage);
      return processSvgOutline(
          svgString, color, opacity, scale, rotation, invert);
    } else {
      throw Exception('Unsupported image format: $format');
    }
  }

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
      double opacity, double scale, double rotation, bool invert) async {
    try {
      // 创建一个XML解析器
      final document = XmlDocument.parse(svgContent);

      // 获取SVG根元素
      final svgElement = document.rootElement;

      // 应用颜色和反转
      _applySvgColor(svgElement, color, invert);

      // 应用不透明度
      if (opacity < 1.0) {
        svgElement.setAttribute('opacity', opacity.toString());
      }

      // 应用缩放和旋转
      if (scale != 1.0 || rotation != 0.0) {
        final transformList = [];
        if (scale != 1.0) {
          transformList.add('scale($scale)');
        }
        if (rotation != 0.0) {
          transformList.add('rotate($rotation)');
        }

        final existingTransform = svgElement.getAttribute('transform') ?? '';
        final newTransform = existingTransform.isEmpty
            ? transformList.join(' ')
            : '$existingTransform ${transformList.join(' ')}';

        svgElement.setAttribute('transform', newTransform);
      }

      // 将修改后的SVG转换回字符串
      final modifiedSvgString = document.toXmlString();

      // 将SVG转换为PNG
      // 注意：这里需要实际实现SVG到PNG的转换
      // 由于Flutter中直接将SVG转换为PNG比较复杂，这里使用一个简化的实现
      // 在实际应用中，可能需要使用flutter_svg或其他库来实现

      // 创建一个简单的PNG图像作为替代
      const width = 100;
      const height = 100;
      final image = img.Image(width: width, height: height);

      // 填充背景色（透明）
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        }
      }

      // 绘制一个简单的形状来模拟SVG
      // 在实际应用中，这里应该使用SVG渲染引擎
      const centerX = width ~/ 2;
      const centerY = height ~/ 2;
      final radius = (width ~/ 3) * scale;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final dx = x - centerX;
          final dy = y - centerY;
          final distance = math.sqrt(dx * dx + dy * dy);

          if (distance < radius && distance > radius - 2) {
            image.setPixel(
                x,
                y,
                img.ColorRgba8(color.red, color.green, color.blue,
                    (255 * opacity).round()));
          }
        }
      }

      // 编码为PNG
      return Uint8List.fromList(img.encodePng(image));
    } catch (e) {
      throw Exception('Failed to process SVG outline: $e');
    }
  }

  // 在SVG中应用颜色和反转
  void _applySvgColor(XmlElement element, Color color, bool invert) {
    // 移除fill和stroke属性
    element.removeAttribute('fill');
    element.removeAttribute('stroke');

    // 颜色字符串
    final colorStr = '#${color.value.toRadixString(16).substring(2)}';

    // 添加新的颜色
    if (invert) {
      // 反转颜色：轮廓填充为背景色，背景为透明
      element.setAttribute('fill', 'none');
      element.setAttribute('stroke', colorStr);
      element.setAttribute('stroke-width', '1');
    } else {
      // 正常颜色：轮廓填充为指定颜色
      element.setAttribute('fill', colorStr);
      element.setAttribute('stroke', 'none');
    }

    // 递归处理子元素
    for (final child in element.childElements) {
      _applySvgColor(child, color, invert);
    }
  }

  // 解析颜色
  Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      final value = int.parse(colorStr.substring(1), radix: 16);
      return Color(value + 0xFF000000);
    }
    return Colors.black;
  }

  // 处理PNG图片
  Future<Uint8List> _processPngImage(Uint8List sourceImage, Color color,
      double opacity, double scale, double rotation, bool invert) async {
    // 解码图像
    final img.Image? image = img.decodeImage(sourceImage);
    if (image == null) {
      throw Exception('Failed to decode PNG image');
    }

    // 应用缩放
    final scaledImage = img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
    );

    // 应用旋转
    final rotatedImage = rotation != 0.0
        ? img.copyRotate(scaledImage, angle: rotation)
        : scaledImage;

    // 应用颜色变换
    final resultImage =
        applyColorTransform(rotatedImage, color, opacity, invert);

    // 编码为PNG
    return Uint8List.fromList(img.encodePng(resultImage));
  }
}
