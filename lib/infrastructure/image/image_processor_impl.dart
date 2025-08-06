import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:xml/xml.dart';

import '../../domain/models/character/detected_outline.dart';
import '../../infrastructure/logging/logger.dart';
import './image_processor.dart';
import './image_transform_coordinator.dart';

/// 图片处理器实现
class ImageProcessorImpl implements ImageProcessor {
  final String _cachePath;

  ImageProcessorImpl({required String cachePath}) : _cachePath = cachePath;

  @override
  String get tempPath => path.join(_cachePath, 'temp');

  @override
  String get thumbnailCachePath => path.join(_cachePath, 'thumbnails');

  @override
  img.Image applyColorTransform(
      img.Image sourceImage, Color color, double opacity, bool invert) {
    try {
      // 创建新图像
      final resultImage = img.Image(
        width: sourceImage.width,
        height: sourceImage.height,
      );

      // 应用颜色、不透明度和反转
      for (int y = 0; y < sourceImage.height; y++) {
        for (int x = 0; x < sourceImage.width; x++) {
          final pixel = sourceImage.getPixel(x, y);
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;
          final a = pixel.a;

          if (a > 0) {
            // 计算亮度（简化版）
            final brightness = (r + g + b) / 3;

            // 应用反转
            int newR, newG, newB, newA;

            if (invert) {
              // 反转颜色
              if (brightness < 128) {
                // 原来是深色（如黑色），变为浅色（使用指定颜色）
                newR = color.r.toInt();
                newG = color.g.toInt();
                newB = color.b.toInt();
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
                newR = color.r.toInt();
                newG = color.g.toInt();
                newB = color.b.toInt();
                newA = (a * opacity).round();
              } else {
                // 浅色部分保持原样或变透明（取决于图像类型）
                newR = newG = newB = 255;
                newA = (a * opacity).round();
              }
            }

            resultImage.setPixel(x, y, img.ColorRgba8(newR, newG, newB, newA));
          }
        }
      }

      return resultImage;
    } catch (e, stack) {
      AppLogger.error(
        '应用颜色变换失败',
        error: e,
        stackTrace: stack,
        data: {
          'color': color.toString(),
          'opacity': opacity,
          'invert': invert,
        },
      );
      // 返回原图像作为降级处理
      return sourceImage;
    }
  }

  @override
  Future<Uint8List> applyEraseMask(
      Uint8List input, List<List<Offset>> maskPoints, double brushSize) async {
    try {
      final image = img.decodeImage(input);
      if (image == null) throw Exception('Failed to decode image');

      // Create a mask image with the same dimensions as the original image
      final mask = img.Image(width: image.width, height: image.height);

      // Draw the mask using the provided points and brush size
      for (final path in maskPoints) {
        for (final point in path) {
          // Draw a circle at each point with the given brush size
          final x = point.dx.round();
          final y = point.dy.round();
          final radius = brushSize.round();

          for (var dy = -radius; dy <= radius; dy++) {
            for (var dx = -radius; dx <= radius; dx++) {
              if (dx * dx + dy * dy <= radius * radius) {
                final px = x + dx;
                final py = y + dy;
                if (px >= 0 && px < mask.width && py >= 0 && py < mask.height) {
                  mask.setPixel(px, py, img.ColorRgba8(255, 255, 255, 255));
                }
              }
            }
          }
        }
      }

      // Apply the mask to the image
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final maskPixel = mask.getPixel(x, y);
          if (maskPixel.a > 127) {
            image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
          }
        }
      }

      return Uint8List.fromList(img.encodePng(image));
    } catch (e, stack) {
      AppLogger.error(
        '应用擦除蒙版失败',
        error: e,
        stackTrace: stack,
        data: {'brushSize': brushSize},
      );
      rethrow;
    }
  }

  @override
  img.Image binarizeImage(
      img.Image source, double threshold, bool invertColors) {
    print('🎯 开始二值化处理');
    print('  - 输入图像: ${source.width}x${source.height}');
    print('  - 阈值: $threshold');
    print('  - 反转颜色: $invertColors');

    final gray = img.grayscale(source);
    print('  - 灰度化完成');

    // 🔍 调试：采样原始图像的像素值
    final originalSamples = <int>[];
    final processedSamples = <int>[];

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);

        // 采样部分像素用于调试
        if (originalSamples.length < 10 && (x + y) % (gray.width ~/ 5) == 0) {
          originalSamples.add(luminance.toInt());
        }

        final newColor = luminance > threshold
            ? img.ColorRgb8(255, 255, 255)
            : img.ColorRgb8(0, 0, 0);

        gray.setPixel(x, y, newColor);

        // 采样处理后的像素
        if (processedSamples.length < 10 && (x + y) % (gray.width ~/ 5) == 0) {
          processedSamples.add(newColor.r.toInt());
        }
      }
    }

    print('  - 原始亮度采样: ${originalSamples.join(', ')}');
    print('  - 处理后采样: ${processedSamples.join(', ')}');

    final result = invertColors ? img.invert(gray) : gray;
    print('  - 二值化处理完成，反转: $invertColors');

    return result;
  }

  @override
  Future<void> cleanupTempFiles() async {
    try {
      final dir = Directory(tempPath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    } catch (e, stack) {
      AppLogger.error(
        '清理临时文件失败',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  @override
  Future<File> createPlaceholder(int width, int height) async {
    try {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(200, 200, 200));

      final outPath = await _createTempFilePath('placeholder_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(image));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '创建占位图失败',
        error: e,
        stackTrace: stack,
        data: {'width': width, 'height': height},
      );
      rethrow;
    }
  }

  @override
  Future<String> createSvgOutline(DetectedOutline outline) async {
    try {
      // Calculate bounds and create path data simultaneously
      double minX = double.infinity, minY = double.infinity;
      double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
      String pathData = '';

      if (outline.contourPoints.isNotEmpty &&
          outline.contourPoints.first.isNotEmpty) {
        final firstPoint = outline.contourPoints.first.first;

        // Initialize bounds with the first point
        minX = maxX = firstPoint.dx;
        minY = maxY = firstPoint.dy;

        // Start the path
        pathData = 'M ${firstPoint.dx},${firstPoint.dy}';

        // Process all points in a single pass
        for (final path in outline.contourPoints) {
          for (int i = (path == outline.contourPoints.first) ? 1 : 0;
              i < path.length;
              i++) {
            final point = path[i];

            // Update bounds
            minX = minX < point.dx ? minX : point.dx;
            minY = minY < point.dy ? minY : point.dy;
            maxX = maxX > point.dx ? maxX : point.dx;
            maxY = maxY > point.dy ? maxY : point.dy;

            // Add to path
            pathData += ' L ${point.dx},${point.dy}';
          }
        }

        // Close the path
        pathData += ' Z';
      }

      final width = maxX - minX;
      final height = maxY - minY;

      final svgContent = '''
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">
  <path d="$pathData" fill="none" stroke="black" stroke-width="1"/>
</svg>
''';

      return svgContent;
    } catch (e, stack) {
      AppLogger.error(
        '创建SVG轮廓失败',
        error: e,
        stackTrace: stack,
        data: {'outline': outline.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<File> createTempFile(String prefix) async {
    final filePath = await _createTempFilePath(prefix);
    return File(filePath);
  }

  @override
  Future<Uint8List> createThumbnail(Uint8List input, int size) async {
    try {
      final image = img.decodeImage(input);
      if (image == null) throw Exception('Failed to decode image');

      // Make a square thumbnail
      int thumbWidth, thumbHeight;
      if (image.width > image.height) {
        thumbHeight = size;
        thumbWidth = (size * (image.width / image.height)).round();
      } else {
        thumbWidth = size;
        thumbHeight = (size * (image.height / image.width)).round();
      }

      final thumbnail = img.copyResize(
        image,
        width: thumbWidth,
        height: thumbHeight,
        interpolation: img.Interpolation.average,
      );

      // Create the thumbnail directory if it doesn't exist
      final dir = Directory(thumbnailCachePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      return Uint8List.fromList(img.encodePng(thumbnail));
    } catch (e, stack) {
      AppLogger.error(
        '创建缩略图失败',
        error: e,
        stackTrace: stack,
        data: {'size': size},
      );
      rethrow;
    }
  }

  @override
  Future<Uint8List> cropImage(Uint8List input, Rect rect) async {
    try {
      final image = img.decodeImage(input);
      if (image == null) throw Exception('Failed to decode image');

      final cropped = img.copyCrop(
        image,
        x: rect.left.toInt(),
        y: rect.top.toInt(),
        width: rect.width.toInt(),
        height: rect.height.toInt(),
      );

      return Uint8List.fromList(img.encodePng(cropped));
    } catch (e, stack) {
      AppLogger.error(
        '裁剪图片失败',
        error: e,
        stackTrace: stack,
        data: {
          'rect': '${rect.left},${rect.top},${rect.width},${rect.height}',
        },
      );
      rethrow;
    }
  }

  @override
  img.Image denoiseImage(img.Image source, double strength) {
    if (strength == 0) return source;
    final radius = (strength * 5).clamp(1.0, 3.0);
    final blurred = img.gaussianBlur(source, radius: radius.toInt());

    for (int y = 0; y < blurred.height; y++) {
      for (int x = 0; x < blurred.width; x++) {
        final pixel = blurred.getPixel(x, y);
        final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
        blurred.setPixel(
          x,
          y,
          luminance > 128
              ? img.ColorRgb8(255, 255, 255)
              : img.ColorRgb8(0, 0, 0),
        );
      }
    }

    return blurred;
  }

  /// 检测轮廓
  @override
  DetectedOutline detectOutline(img.Image binaryImage, bool isInverted) {
    try {
      final paddedImage = _addBorderToImage(binaryImage, isInverted);

      final width = paddedImage.width;
      final height = paddedImage.height;
      final visited = List.generate(
          height, (y) => List.generate(width, (x) => false, growable: false),
          growable: false);

      final allContourSegments = <_ContourSegment>[];

      // Find and trace the outer contour
      var startPoint = _findFirstContourPoint(paddedImage, isInverted);
      if (startPoint != null) {
        final outerSegment =
            _traceContourSegment(paddedImage, visited, startPoint, isInverted);
        if (outerSegment.points.length >= 4) {
          allContourSegments.add(outerSegment);
        }
      }

      // Limit inner contour detection to safely inside the image boundaries
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          // Skip already visited pixels or foreground pixels
          if (y >= visited.length ||
              x >= visited[y].length ||
              visited[y][x] ||
              _isForegroundPixel(paddedImage.getPixel(x, y), isInverted)) {
            continue;
          }

          if (_isInnerContourPoint(paddedImage, x, y, isInverted)) {
            final innerStart = Offset(x.toDouble(), y.toDouble());
            final innerSegment = _traceContourSegment(
                paddedImage, visited, innerStart, isInverted);

            if (innerSegment.points.length >= 4) {
              allContourSegments.add(innerSegment);
            }
          }
        }
      } // 处理轮廓线段（包括闭合和开放线段）
      final allContours = _connectOpenContours(allContourSegments);

      const borderWidth = 1;
      final adjustedContours = allContours.map((contour) {
        return contour
            .map((point) =>
                Offset(point.dx - borderWidth, point.dy - borderWidth))
            .toList();
      }).toList();

      return DetectedOutline(
        boundingRect: Rect.fromLTWH(
            0, 0, binaryImage.width.toDouble(), binaryImage.height.toDouble()),
        contourPoints: adjustedContours,
      );
    } catch (e) {
      // Return an empty outline instead of crashing
      return DetectedOutline(
        boundingRect: Rect.fromLTWH(
            0, 0, binaryImage.width.toDouble(), binaryImage.height.toDouble()),
        contourPoints: [],
      );
    }
  }

  bool isInnerContourPoint(img.Image image, int x, int y, bool isInverted) {
    if (_isForegroundPixel(image.getPixel(x, y), isInverted)) {
      return false;
    }

    final neighbors = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1],
      [-1, -1],
      [-1, 1],
      [1, -1],
      [1, 1],
    ];

    for (final dir in neighbors) {
      final nx = x + dir[0];
      final ny = y + dir[1];

      if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
        continue;
      }

      if (_isForegroundPixel(image.getPixel(nx, ny), isInverted)) {
        return true;
      }
    }

    return false;
  }

  @override
  Future<File> optimizeImage(File input) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      final optimized = img.copyResize(
        image,
        width: image.width,
        height: image.height,
        interpolation: img.Interpolation.linear,
      );

      final outPath = await _createTempFilePath('optimized_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(optimized, quality: 85));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '优化图片失败',
        error: e,
        stackTrace: stack,
        data: {'input': input.path},
      );
      rethrow;
    }
  }

  @override
  Future<Uint8List> processCharacterImage(Uint8List sourceImage, String format,
      Map<String, dynamic> transform) async {
    try {
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
    } catch (e, stack) {
      AppLogger.error(
        '处理集字图像失败',
        error: e,
        stackTrace: stack,
        data: {'format': format, 'transform': transform.toString()},
      );
      rethrow;
    }
  }

  @override
  Future<File> processImage(
    File input, {
    required int maxWidth,
    required int maxHeight,
    required int quality,
  }) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // 检查是否需要缩放
      final needsResize = image.width > maxWidth || image.height > maxHeight;

      img.Image processed;

      if (needsResize) {
        // 只有当图片超过最大尺寸时才缩放
        final aspectRatio = image.width / image.height;
        var targetWidth = maxWidth;
        var targetHeight = maxHeight;

        if (targetWidth / targetHeight > aspectRatio) {
          targetWidth = (targetHeight * aspectRatio).round();
        } else {
          targetHeight = (targetWidth / aspectRatio).round();
        }

        processed = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );
      } else {
        // 保持原始尺寸，只进行质量压缩
        processed = image;
      }

      final outPath = await _createTempFilePath('processed_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(processed, quality: quality));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '处理图片失败',
        error: e,
        stackTrace: stack,
        data: {
          'input': input.path,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
          'quality': quality,
        },
      );
      rethrow;
    }
  }

  @override
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
        final transformList = <String>[];
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
      return _svgToPng(modifiedSvgString);
    } catch (e, stack) {
      AppLogger.error(
        '处理SVG轮廓失败',
        error: e,
        stackTrace: stack,
        data: {
          'color': color.toString(),
          'opacity': opacity,
          'scale': scale,
          'rotation': rotation,
          'invert': invert,
        },
      );
      rethrow;
    }
  }

  @override
  Future<File> resizeImage(
    File input, {
    required int width,
    required int height,
  }) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      // 计算保持宽高比的尺寸
      final aspectRatio = image.width / image.height;
      var targetWidth = width;
      var targetHeight = height;

      if (targetWidth / targetHeight > aspectRatio) {
        targetWidth = (targetHeight * aspectRatio).round();
      } else {
        targetHeight = (targetWidth / aspectRatio).round();
      }

      final resized = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

      final outPath = await _createTempFilePath('resized_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(resized));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '调整图片大小失败',
        error: e,
        stackTrace: stack,
        data: {
          'input': input.path,
          'width': width,
          'height': height,
        },
      );
      rethrow;
    }
  }

  @override
  img.Image rotateAndCropImage(
      img.Image sourceImage, Rect region, double rotation,
      {bool? flipHorizontal, bool? flipVertical}) {
    final center =
        Offset(region.left + region.width / 2, region.top + region.height / 2);

    // 检查是否只需要翻转而不需要旋转
    if (rotation == 0 && (flipHorizontal == true || flipVertical == true)) {
      // 裁剪图像
      var result = img.copyCrop(
        sourceImage,
        x: region.left.round(),
        y: region.top.round(),
        width: region.width.round(),
        height: region.height.round(),
      );

      // 应用翻转
      if (flipHorizontal == true) {
        result = img.flip(result, direction: img.FlipDirection.horizontal);
      }
      if (flipVertical == true) {
        result = img.flip(result, direction: img.FlipDirection.vertical);
      }

      return result;
    }

    // 如果没有任何变换，直接裁剪
    if (rotation == 0 && flipHorizontal != true && flipVertical != true) {
      return img.copyCrop(
        sourceImage,
        x: region.left.round(),
        y: region.top.round(),
        width: region.width.round(),
        height: region.height.round(),
      );
    }

    // 创建目标图像
    final result =
        img.Image(width: region.width.round(), height: region.height.round());

    // 创建变换矩阵 - 转换旋转角度为弧度
    final radians = rotation; // * math.pi / 180.0;
    final cos = math.cos(radians);
    final sin = math.sin(radians);

    // 使用仿射变换进行旋转和翻转裁剪
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        // 应用翻转 - 计算翻转后的坐标
        double xFlipped = x.toDouble();
        double yFlipped = y.toDouble();

        if (flipHorizontal == true) {
          xFlipped = result.width - 1 - x.toDouble();
        }
        if (flipVertical == true) {
          yFlipped = result.height - 1 - y.toDouble();
        }

        // 将目标坐标映射回源图像坐标 - 应用旋转变换
        final srcX = cos * (xFlipped - region.width / 2) -
            sin * (yFlipped - region.height / 2) +
            center.dx;
        final srcY = sin * (xFlipped - region.width / 2) +
            cos * (yFlipped - region.height / 2) +
            center.dy;

        // 双线性插值获取像素值
        if (srcX >= 0 &&
            srcX < sourceImage.width - 1 &&
            srcY >= 0 &&
            srcY < sourceImage.height - 1) {
          // 获取周围四个像素点
          final x0 = srcX.floor();
          final y0 = srcY.floor();
          final x1 = x0 + 1;
          final y1 = y0 + 1;

          // 计算插值权重
          final wx = srcX - x0;
          final wy = srcY - y0;

          // 获取四个角的像素值
          final p00 = sourceImage.getPixel(x0, y0);
          final p01 = sourceImage.getPixel(x0, y1);
          final p10 = sourceImage.getPixel(x1, y0);
          final p11 = sourceImage.getPixel(x1, y1);

          // 进行双线性插值
          final r = ((1 - wx) * (1 - wy) * p00.r +
                  wx * (1 - wy) * p10.r +
                  (1 - wx) * wy * p01.r +
                  wx * wy * p11.r)
              .round();
          final g = ((1 - wx) * (1 - wy) * p00.g +
                  wx * (1 - wy) * p10.g +
                  (1 - wx) * wy * p01.g +
                  wx * wy * p11.g)
              .round();
          final b = ((1 - wx) * (1 - wy) * p00.b +
                  wx * (1 - wy) * p10.b +
                  (1 - wx) * wy * p01.b +
                  wx * wy * p11.b)
              .round();
          final a = ((1 - wx) * (1 - wy) * p00.a +
                  wx * (1 - wy) * p10.a +
                  (1 - wx) * wy * p01.a +
                  wx * wy * p11.a)
              .round();

          result.setPixelRgba(x, y, r, g, b, a);
        }
      }
    }

    return result;
  }

  @override
  img.Image flipThenCropImage(
      img.Image sourceImage, Rect region, double rotation,
      {bool? flipHorizontal, bool? flipVertical}) {
    // 调试日志
    AppLogger.info('flipThenCropImage called', data: {
      'sourceImageSize': '${sourceImage.width}x${sourceImage.height}',
      'region': '${region.left},${region.top},${region.width}x${region.height}',
      'flipHorizontal': flipHorizontal,
      'flipVertical': flipVertical,
      'rotation': rotation,
    });

    // 🔧 实现用户建议的动态边界逻辑
    // 关键理解：当前传入的region参数是相对于原始图像坐标系的
    // 我们需要正确处理这个坐标系统

    // 如果没有任何变换，直接裁剪
    if (rotation == 0 && flipHorizontal != true && flipVertical != true) {
      AppLogger.info('No transforms applied, direct crop');
      return img.copyCrop(
        sourceImage,
        x: region.left.round(),
        y: region.top.round(),
        width: region.width.round(),
        height: region.height.round(),
      );
    }

    // 🔧 步骤1: 创建变换协调器
    final coordinator = ImageTransformCoordinator(
      originalImageSize:
          Size(sourceImage.width.toDouble(), sourceImage.height.toDouble()),
      rotation: rotation,
      flipHorizontal: flipHorizontal ?? false,
      flipVertical: flipVertical ?? false,
    );

    AppLogger.info('Transform coordinator created',
        data: coordinator.getDebugInfo());

    // 🔧 步骤2: 将原始坐标系的裁剪区域转换为动态边界坐标系
    final dynamicCropParams = coordinator.originalToDynamicCropParams(
      cropX: region.left,
      cropY: region.top,
      cropWidth: region.width,
      cropHeight: region.height,
    );

    final dynamicCropRect = Rect.fromLTWH(
      dynamicCropParams['cropX']!,
      dynamicCropParams['cropY']!,
      dynamicCropParams['cropWidth']!,
      dynamicCropParams['cropHeight']!,
    );

    AppLogger.info('Coordinate conversion completed', data: {
      'originalRegion':
          '${region.left},${region.top},${region.width}x${region.height}',
      'dynamicCropRect':
          '${dynamicCropRect.left},${dynamicCropRect.top},${dynamicCropRect.width}x${dynamicCropRect.height}',
    });

    // 🔧 步骤3: 验证并调整动态边界中的裁剪区域
    final clampedDynamicRect =
        coordinator.clampDynamicCropRect(dynamicCropRect);

    AppLogger.info('Dynamic crop rect clamped', data: {
      'beforeClamp':
          '${dynamicCropRect.left},${dynamicCropRect.top},${dynamicCropRect.width}x${dynamicCropRect.height}',
      'afterClamp':
          '${clampedDynamicRect.left},${clampedDynamicRect.top},${clampedDynamicRect.width}x${clampedDynamicRect.height}',
    });

    // 🔧 步骤4: 创建结果图像
    final result = img.Image(
        width: clampedDynamicRect.width.round(),
        height: clampedDynamicRect.height.round());

    AppLogger.info('Created result image', data: {
      'resultSize': '${result.width}x${result.height}',
    });

    // 🔧 步骤5: 对结果图像的每个像素进行映射
    final bounds = coordinator.bounds;

    for (int resultY = 0; resultY < result.height; resultY++) {
      for (int resultX = 0; resultX < result.width; resultX++) {
        // 5a. 计算该像素在动态边界中的坐标
        final dynamicX = clampedDynamicRect.left + resultX;
        final dynamicY = clampedDynamicRect.top + resultY;

        // 5b. 将动态边界坐标映射到原始图像坐标
        final originalPixel =
            bounds.mapDynamicToImagePixel(Offset(dynamicX, dynamicY));

        // 5c. 检查原始图像坐标是否有效并采样
        if (originalPixel.dx >= 0 &&
            originalPixel.dx < sourceImage.width - 1 &&
            originalPixel.dy >= 0 &&
            originalPixel.dy < sourceImage.height - 1) {
          // 双线性插值获取像素值
          final x0 = originalPixel.dx.floor();
          final y0 = originalPixel.dy.floor();
          final x1 = x0 + 1;
          final y1 = y0 + 1;

          final wx = originalPixel.dx - x0;
          final wy = originalPixel.dy - y0;

          final p00 = sourceImage.getPixel(x0, y0);
          final p01 = sourceImage.getPixel(x0, y1);
          final p10 = sourceImage.getPixel(x1, y0);
          final p11 = sourceImage.getPixel(x1, y1);

          final r = ((1 - wx) * (1 - wy) * p00.r +
                  wx * (1 - wy) * p10.r +
                  (1 - wx) * wy * p01.r +
                  wx * wy * p11.r)
              .round();
          final g = ((1 - wx) * (1 - wy) * p00.g +
                  wx * (1 - wy) * p10.g +
                  (1 - wx) * wy * p01.g +
                  wx * wy * p11.g)
              .round();
          final b = ((1 - wx) * (1 - wy) * p00.b +
                  wx * (1 - wy) * p10.b +
                  (1 - wx) * wy * p01.b +
                  wx * wy * p11.b)
              .round();
          final a = ((1 - wx) * (1 - wy) * p00.a +
                  wx * (1 - wy) * p10.a +
                  (1 - wx) * wy * p01.a +
                  wx * wy * p11.a)
              .round();

          result.setPixelRgba(resultX, resultY, r, g, b, a);
        }
        // 如果原始坐标超出范围，像素保持默认（透明）
      }
    }

    AppLogger.info('Dynamic bounds mapping completed', data: {
      'appliedRotation': rotation,
      'appliedFlipH': flipHorizontal,
      'appliedFlipV': flipVertical,
      'resultSize': '${result.width}x${result.height}',
      'mappingMethod': 'coordinatedDynamicBounds',
      'coordinatorInfo': coordinator.toString(),
    });

    return result;
  }

  @override
  Future<File> rotateImage(File input, int degrees) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      final rotated = img.copyRotate(image, angle: degrees);

      final outPath = await _createTempFilePath('rotated_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(rotated));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '旋转图片失败',
        error: e,
        stackTrace: stack,
        data: {
          'input': input.path,
          'degrees': degrees,
        },
      );
      rethrow;
    }
  }

  /// 验证图像数据是否可解码
  @override
  Future<bool> validateImageData(Uint8List data) async {
    if (data.isEmpty) return false;
    try {
      // 尝试解码图像以验证数据有效性
      final codec = await ui.instantiateImageCodec(data);
      await codec.getNextFrame();

      return true;
    } catch (e) {
      AppLogger.warning('图像数据验证失败',
          tag: 'ImageProcessor', error: e, data: {'dataLength': data.length});
      return false;
    }
  }

  // 在SVG中应用颜色和反转
  void _applySvgColor(XmlElement element, Color color, bool invert) {
    // 移除fill和stroke属性
    element.removeAttribute('fill');
    element.removeAttribute('stroke');

    // 颜色字符串
    final colorStr =
        '#${(color.a.toInt() << 24 | color.r.toInt() << 16 | color.g.toInt() << 8 | color.b.toInt()).toRadixString(16).substring(2)}';

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

  /// 创建临时文件路径
  Future<String> _createTempFilePath(String prefix) async {
    final dir = Directory(tempPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path.join(
      tempPath,
      '$prefix${DateTime.now().millisecondsSinceEpoch}.tmp',
    );
  }

  // 解析颜色
  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        String hexColor = colorStr.substring(1);

        // 处理不同长度的十六进制颜色
        if (hexColor.length == 3) {
          // 将 #RGB 转换为 #RRGGBB
          hexColor = hexColor.split('').map((c) => '$c$c').join('');
        }

        if (hexColor.length == 6) {
          // 添加完全不透明的alpha通道
          hexColor = 'FF$hexColor';
        } else if (hexColor.length == 8) {
          // 已经包含alpha通道
        } else {
          return Colors.black;
        }

        return Color(int.parse(hexColor, radix: 16));
      }
      return Colors.black;
    } catch (e) {
      AppLogger.error('解析颜色失败: $colorStr', error: e);
      return Colors.black;
    }
  }

  // 处理PNG图片
  Future<Uint8List> _processPngImage(Uint8List sourceImage, Color color,
      double opacity, double scale, double rotation, bool invert) async {
    try {
      // 解码图像
      final image = img.decodeImage(sourceImage);
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
    } catch (e, stack) {
      AppLogger.error(
        '处理PNG图像失败',
        error: e,
        stackTrace: stack,
        data: {
          'color': color.toString(),
          'opacity': opacity,
          'scale': scale,
          'rotation': rotation,
          'invert': invert,
        },
      );
      rethrow;
    }
  }

  // 将SVG转换为PNG
  Future<Uint8List> _svgToPng(String svgString) async {
    try {
      // 解析SVG文档
      final document = XmlDocument.parse(svgString);
      final svgElement = document.rootElement;

      // 获取SVG的宽度和高度
      final widthAttr = svgElement.getAttribute('width');
      final heightAttr = svgElement.getAttribute('height');

      // 解析宽度和高度，默认为100
      final width = widthAttr != null ? double.tryParse(widthAttr) ?? 100 : 100;
      final height =
          heightAttr != null ? double.tryParse(heightAttr) ?? 100 : 100;

      // 创建一个PNG图像
      final image = img.Image(width: width.toInt(), height: height.toInt());

      // 填充白色背景
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // 获取路径元素
      final pathElements = svgElement.findAllElements('path');

      // 如果有路径元素，尝试绘制简单的轮廓
      if (pathElements.isNotEmpty) {
        for (final pathElement in pathElements) {
          final dAttr = pathElement.getAttribute('d');
          if (dAttr != null) {
            // 解析路径数据
            final pathData = dAttr.split(' ');

            // 简单的路径解析和绘制
            int? lastX, lastY;

            for (int i = 0; i < pathData.length; i++) {
              final cmd = pathData[i];

              if (cmd == 'M' && i + 2 < pathData.length) {
                // 移动到点
                final coords = pathData[i + 1].split(',');
                if (coords.length == 2) {
                  lastX = double.tryParse(coords[0])?.toInt();
                  lastY = double.tryParse(coords[1])?.toInt();
                  i += 1;
                }
              } else if (cmd == 'L' && i + 2 < pathData.length) {
                // 画线到点
                final coords = pathData[i + 1].split(',');
                if (coords.length == 2 && lastX != null && lastY != null) {
                  final x = double.tryParse(coords[0])?.toInt();
                  final y = double.tryParse(coords[1])?.toInt();

                  if (x != null && y != null) {
                    // 绘制线段
                    img.drawLine(
                      image,
                      x1: lastX,
                      y1: lastY,
                      x2: x,
                      y2: y,
                      color: img.ColorRgb8(0, 0, 0),
                      thickness: 1,
                    );

                    lastX = x;
                    lastY = y;
                  }
                  i += 1;
                }
              }
            }
          }
        }
      } else {
        // 如果没有路径元素，绘制一个简单的占位图形
        final centerX = width ~/ 2;
        final centerY = height ~/ 2;
        final radius = math.min(width, height) ~/ 4;

        // 绘制一个圆形
        img.drawCircle(
          image,
          x: centerX,
          y: centerY,
          radius: radius,
          color: img.ColorRgb8(0, 0, 0),
        );
      }

      // 编码为PNG
      return Uint8List.fromList(img.encodePng(image));
    } catch (e, stack) {
      AppLogger.error(
        '将SVG转换为PNG失败',
        error: e,
        stackTrace: stack,
      );

      // 创建一个简单的占位图像
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(240, 240, 240));

      // 绘制一个简单的图形表示错误
      img.drawRect(
        image,
        x1: 20,
        y1: 20,
        x2: 80,
        y2: 80,
        color: img.ColorRgb8(200, 200, 200),
        thickness: 2,
      );

      // 绘制一个X
      img.drawLine(
        image,
        x1: 30,
        y1: 30,
        x2: 70,
        y2: 70,
        color: img.ColorRgb8(150, 150, 150),
        thickness: 2,
      );
      img.drawLine(
        image,
        x1: 70,
        y1: 30,
        x2: 30,
        y2: 70,
        color: img.ColorRgb8(150, 150, 150),
        thickness: 2,
      );

      return Uint8List.fromList(img.encodePng(image));
    }
  }

  static img.Image _addBorderToImage(img.Image source, bool isInverted) {
    const borderWidth = 1;
    final width = source.width + borderWidth * 2;
    final height = source.height + borderWidth * 2;
    final result = img.Image(width: width, height: height);

    isInverted
        ? img.fill(result, color: img.ColorRgb8(0, 0, 0))
        : img.fill(result, color: img.ColorRgb8(255, 255, 255));

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        result.setPixel(
            x + borderWidth, y + borderWidth, source.getPixel(x, y));
      }
    }
    return result;
  }

  /// 计算两点之间的距离
  static double _calculateDistance(Offset point1, Offset point2) {
    return math.sqrt(math.pow(point1.dx - point2.dx, 2) +
        math.pow(point1.dy - point2.dy, 2));
  }

  /// 处理轮廓线段（允许端点多次参与连接）
  static List<List<Offset>> _connectOpenContours(
      List<_ContourSegment> segments) {
    final allContours = <List<Offset>>[];

    // 直接添加已闭合的线段
    final openSegments = <_ContourSegment>[];
    for (final segment in segments) {
      if (segment.isClosed && segment.points.length >= 2) {
        allContours.add(segment.points);
      } else if (!segment.isClosed && segment.points.length >= 2) {
        openSegments.add(segment);
      }
    }

    if (openSegments.isEmpty) {
      return allContours;
    }

    // 创建工作副本，允许动态修改
    final workingSegments = <_ContourSegment>[];
    for (final segment in openSegments) {
      workingSegments.add(_ContourSegment(
        points: List<Offset>.from(segment.points),
        isClosed: segment.isClosed,
      ));
    }

    // 迭代连接过程
    bool hasConnections = true;
    while (hasConnections && workingSegments.isNotEmpty) {
      hasConnections = false;

      // 收集所有可能的连接
      final connections = <_ConnectionInfo>[];

      for (int i = 0; i < workingSegments.length; i++) {
        final segment1 = workingSegments[i];
        if (segment1.isClosed) continue;

        final start1 = segment1.startPoint;
        final end1 = segment1.endPoint;

        // 自身闭合连接
        final selfDistance = _calculateDistance(start1, end1);
        connections.add(_ConnectionInfo(
          segmentIndex1: i,
          isStart1: true,
          segmentIndex2: i,
          isStart2: false,
          distance: selfDistance,
        ));

        // 与其他线段的连接
        for (int j = i + 1; j < workingSegments.length; j++) {
          final segment2 = workingSegments[j];
          if (segment2.isClosed) continue;

          final start2 = segment2.startPoint;
          final end2 = segment2.endPoint;

          // 四种连接方式
          connections.add(_ConnectionInfo(
            segmentIndex1: i,
            isStart1: true,
            segmentIndex2: j,
            isStart2: true,
            distance: _calculateDistance(start1, start2),
          ));

          connections.add(_ConnectionInfo(
            segmentIndex1: i,
            isStart1: true,
            segmentIndex2: j,
            isStart2: false,
            distance: _calculateDistance(start1, end2),
          ));

          connections.add(_ConnectionInfo(
            segmentIndex1: i,
            isStart1: false,
            segmentIndex2: j,
            isStart2: true,
            distance: _calculateDistance(end1, start2),
          ));

          connections.add(_ConnectionInfo(
            segmentIndex1: i,
            isStart1: false,
            segmentIndex2: j,
            isStart2: false,
            distance: _calculateDistance(end1, end2),
          ));
        }
      }

      if (connections.isEmpty) break;

      // 按距离排序，选择最近的连接
      connections.sort((a, b) => a.distance.compareTo(b.distance));
      final bestConnection = connections.first;

      final segment1 = workingSegments[bestConnection.segmentIndex1];

      if (bestConnection.segmentIndex1 == bestConnection.segmentIndex2) {
        // 自身闭合
        final closedPoints = List<Offset>.from(segment1.points);
        if (bestConnection.distance > 0) {
          closedPoints.add(segment1.startPoint);
        }
        allContours.add(closedPoints);
        workingSegments.removeAt(bestConnection.segmentIndex1);
        hasConnections = true;
      } else {
        // 连接两个不同线段
        final segment2 = workingSegments[bestConnection.segmentIndex2];
        final connectedPoints = <Offset>[];

        // 根据连接方式组合点
        if (bestConnection.isStart1 && bestConnection.isStart2) {
          // 起点连起点：反转segment1 + segment2
          connectedPoints.addAll(segment1.points.reversed);
          connectedPoints.addAll(segment2.points);
        } else if (bestConnection.isStart1 && !bestConnection.isStart2) {
          // 起点连终点：反转segment1 + 反转segment2
          connectedPoints.addAll(segment1.points.reversed);
          connectedPoints.addAll(segment2.points.reversed);
        } else if (!bestConnection.isStart1 && bestConnection.isStart2) {
          // 终点连起点：segment1 + segment2
          connectedPoints.addAll(segment1.points);
          connectedPoints.addAll(segment2.points);
        } else {
          // 终点连终点：segment1 + 反转segment2
          connectedPoints.addAll(segment1.points);
          connectedPoints.addAll(segment2.points.reversed);
        }

        // 创建新的合并线段
        final mergedSegment = _ContourSegment(
          points: connectedPoints,
          isClosed: false,
        );

        // 移除原线段并添加合并后的线段
        final removeIndex1 = bestConnection.segmentIndex1;
        final removeIndex2 = bestConnection.segmentIndex2;

        if (removeIndex1 > removeIndex2) {
          workingSegments.removeAt(removeIndex1);
          workingSegments.removeAt(removeIndex2);
        } else {
          workingSegments.removeAt(removeIndex2);
          workingSegments.removeAt(removeIndex1);
        }

        workingSegments.add(mergedSegment);
        hasConnections = true;
      }
    }

    // 添加剩余的未连接线段
    for (final segment in workingSegments) {
      if (segment.points.length >= 2) {
        allContours.add(segment.points);
      }
    }

    return allContours;
  }

  static Offset? _findFirstContourPoint(img.Image image, bool isInverted) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (_isForegroundPixel(image.getPixel(x, y), isInverted) &&
            _isContourPoint(image, x, y, isInverted)) {
          return Offset(x.toDouble(), y.toDouble());
        }
      }
    }
    return null;
  }

  static bool _isContourPoint(img.Image image, int x, int y, bool isInverted) {
    try {
      // Ensure coordinates are within image bounds
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
        return false;
      }

      if (!_isForegroundPixel(image.getPixel(x, y), isInverted)) {
        return false;
      }

      // Point on the image border is always a contour point
      if (x == 0 || x == image.width - 1 || y == 0 || y == image.height - 1) {
        return true;
      }

      // Check if any neighbor is background
      final neighbors = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ];

      for (final dir in neighbors) {
        final nx = x + dir[0];
        final ny = y + dir[1];

        // Skip invalid neighbors
        if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
          continue;
        }

        // If any neighbor is background, this is a contour point
        if (!_isForegroundPixel(image.getPixel(nx, ny), isInverted)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false; // Safety fallback
    }
  }

  static bool _isForegroundPixel(img.Pixel pixel, bool isInverted) {
    final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
    return isInverted ? luminance >= 128 : luminance < 128;
  }

  static bool _isInnerContourPoint(
      img.Image image, int x, int y, bool isInverted) {
    try {
      // Ensure coordinates are within image bounds
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
        return false;
      }

      // Point must be background
      if (_isForegroundPixel(image.getPixel(x, y), isInverted)) {
        return false;
      }

      // Check if any neighbor is foreground (inner contour detection)
      final neighbors = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1]
      ];

      for (final dir in neighbors) {
        final nx = x + dir[0];
        final ny = y + dir[1];

        // Skip invalid neighbors
        if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
          continue;
        }

        // If any neighbor is foreground, this is an inner contour point
        if (_isForegroundPixel(image.getPixel(nx, ny), isInverted)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false; // Safety fallback
    }
  }

  /// 跟踪轮廓线段（不强制闭合）
  static _ContourSegment _traceContourSegment(img.Image image,
      List<List<bool>> visited, Offset start, bool isInverted) {
    try {
      final contour = <Offset>[];
      var x = start.dx.toInt();
      var y = start.dy.toInt();
      final startX = x;
      final startY = y;

      // Safety check - ensure starting point is valid
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
        return _ContourSegment(points: [], isClosed: false);
      }

      const directions = [
        [1, 0],
        [1, 1],
        [0, 1],
        [-1, 1],
        [-1, 0],
        [-1, -1],
        [0, -1],
        [1, -1],
      ];

      // Limit iterations to prevent infinite loops
      int maxIterations = image.width * image.height;
      int iterations = 0;

      do {
        contour.add(Offset(x.toDouble(), y.toDouble()));

        // Mark as visited only if coordinates are valid
        if (y >= 0 && y < visited.length && x >= 0 && x < visited[y].length) {
          visited[y][x] = true;
        }

        var found = false;
        for (final dir in directions) {
          final nx = x + dir[0];
          final ny = y + dir[1];

          // Safe boundary check for next point
          if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
            continue;
          }

          // Valid point check for visited array
          if (ny < 0 ||
              ny >= visited.length ||
              nx < 0 ||
              nx >= visited[ny].length) {
            continue;
          }

          // Check if this is the starting point and we've completed a loop
          if (nx == startX && ny == startY && contour.length > 3) {
            contour.add(start); // Close the loop
            return _ContourSegment(points: contour, isClosed: true);
          }

          // Skip already visited pixels
          if (visited[ny][nx]) {
            continue;
          }

          // Only consider points that are part of a contour
          if (_isContourPoint(image, nx, ny, isInverted)) {
            x = nx;
            y = ny;
            found = true;
            break;
          }
        }

        iterations++;

        // Break if no next point found or limits exceeded
        if (!found || iterations > maxIterations || contour.length > 100000) {
          break;
        }
      } while (true);

      // Return the segment as non-closed if we didn't complete the loop
      return _ContourSegment(points: contour, isClosed: false);
    } catch (e) {
      return _ContourSegment(points: [], isClosed: false);
    }
  }

  /// 计算两点之间的距离

  // ...existing helper methods...
}

/// 连接信息
class _ConnectionInfo {
  final int segmentIndex1;
  final bool isStart1; // true表示起点，false表示终点
  final int segmentIndex2;
  final bool isStart2;
  final double distance;

  _ConnectionInfo({
    required this.segmentIndex1,
    required this.isStart1,
    required this.segmentIndex2,
    required this.isStart2,
    required this.distance,
  });
}

/// 轮廓线段，用于区分闭合和非闭合线段
class _ContourSegment {
  final List<Offset> points;
  final bool isClosed;

  _ContourSegment({required this.points, required this.isClosed});

  Offset get endPoint => points.last;
  double get length => points.length.toDouble();
  Offset get startPoint => points.first;
}
