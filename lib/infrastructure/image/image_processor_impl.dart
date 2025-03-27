import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

import '../../domain/models/character/detected_outline.dart';
import '../../infrastructure/logging/logger.dart';
import './image_processor.dart';

/// 图片处理器实现
class ImageProcessorImpl implements ImageProcessor {
  final String _cachePath;

  ImageProcessorImpl({required String cachePath}) : _cachePath = cachePath;

  @override
  String get tempPath => path.join(_cachePath, 'temp');

  @override
  String get thumbnailCachePath => path.join(_cachePath, 'thumbnails');

  @override
  Future<File> adjustImageColors(
    File input, {
    double brightness = 0.0,
    double contrast = 0.0,
    double saturation = 0.0,
  }) async {
    try {
      final bytes = await input.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Failed to decode image');

      var adjusted = image;

      if (brightness != 0.0) {
        adjusted = img.colorOffset(adjusted,
            red: brightness.round(),
            green: brightness.round(),
            blue: brightness.round());
      }

      if (contrast != 0.0) {
        adjusted = img.contrast(adjusted, contrast: contrast);
      }

      // Note: The image package might not have direct saturation adjustment,
      // this is a simplified example

      final outPath = await _createTempFilePath('adjusted_');
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodePng(adjusted));

      return outFile;
    } catch (e, stack) {
      AppLogger.error(
        '调整图片颜色失败',
        error: e,
        stackTrace: stack,
        data: {
          'input': input.path,
          'brightness': brightness,
          'contrast': contrast,
          'saturation': saturation,
        },
      );
      rethrow;
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
  Future<Uint8List> binarizeImage(
      Uint8List input, double threshold, bool invertColors) async {
    try {
      final image = img.decodeImage(input);
      if (image == null) throw Exception('Failed to decode image');

      final binarized = img.copyRotate(image, angle: 0); // Create a copy
      for (var y = 0; y < binarized.height; y++) {
        for (var x = 0; x < binarized.width; x++) {
          final pixel = binarized.getPixel(x, y);
          final intensity = img.getLuminance(pixel);
          bool isWhite = intensity > threshold;

          // Apply inversion if needed
          if (invertColors) isWhite = !isWhite;

          if (isWhite) {
            binarized.setPixel(x, y, img.ColorRgb8(255, 255, 255));
          } else {
            binarized.setPixel(x, y, img.ColorRgb8(0, 0, 0));
          }
        }
      }

      return Uint8List.fromList(img.encodePng(binarized));
    } catch (e, stack) {
      AppLogger.error(
        '二值化图片失败',
        error: e,
        stackTrace: stack,
        data: {'threshold': threshold, 'invertColors': invertColors},
      );
      rethrow;
    }
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
  Future<Uint8List> denoiseImage(Uint8List input, double strength) async {
    try {
      final image = img.decodeImage(input);
      if (image == null) throw Exception('Failed to decode image');

      // Apply a simple blur as denoising
      // You might want to implement a more advanced denoising algorithm
      final denoised = img.gaussianBlur(image, radius: strength.round());

      return Uint8List.fromList(img.encodePng(denoised));
    } catch (e, stack) {
      AppLogger.error(
        '图像降噪失败',
        error: e,
        stackTrace: stack,
        data: {'strength': strength},
      );
      rethrow;
    }
  }

  @override
  Future<DetectedOutline> detectOutline(Uint8List input) async {
    try {
      final image = img.decodeImage(input);
      if (image == null) throw Exception('Failed to decode image');

      // Simple outline detection implementation
      // In a real application, you'd need a more sophisticated algorithm
      List<List<Offset>> contourPoints = [];
      List<Offset> currentContour = [];

      // This is a placeholder implementation
      // Find edges along the borders of the image as a simple contour
      for (int x = 0; x < image.width; x += 5) {
        currentContour.add(Offset(x.toDouble(), 0));
      }
      for (int y = 0; y < image.height; y += 5) {
        currentContour.add(Offset(image.width.toDouble(), y.toDouble()));
      }
      for (int x = image.width; x > 0; x -= 5) {
        currentContour.add(Offset(x.toDouble(), image.height.toDouble()));
      }
      for (int y = image.height; y > 0; y -= 5) {
        currentContour.add(Offset(0, y.toDouble()));
      }

      contourPoints.add(currentContour);

      return DetectedOutline(
        contourPoints: contourPoints,
        boundingRect: Rect.fromLTWH(
            0, 0, image.width.toDouble(), image.height.toDouble()),
      );
    } catch (e, stack) {
      AppLogger.error(
        '检测轮廓失败',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
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

      // 计算保持宽高比的尺寸
      final aspectRatio = image.width / image.height;
      var targetWidth = maxWidth;
      var targetHeight = maxHeight;

      if (targetWidth / targetHeight > aspectRatio) {
        targetWidth = (targetHeight * aspectRatio).round();
      } else {
        targetHeight = (targetWidth / aspectRatio).round();
      }

      final processed = img.copyResize(
        image,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );

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
}
