import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
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
    final gray = img.grayscale(source);

    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y);
        final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
        gray.setPixel(
          x,
          y,
          luminance > threshold
              ? img.ColorRgb8(255, 255, 255)
              : img.ColorRgb8(0, 0, 0),
        );
      }
    }

    return invertColors ? img.invert(gray) : gray;
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

      final allContours = <List<Offset>>[];

      // Find and trace the outer contour
      var startPoint = _findFirstContourPoint(paddedImage, isInverted);
      if (startPoint != null) {
        final outerContour =
            _traceContour(paddedImage, visited, startPoint, isInverted);
        if (outerContour.length >= 4) {
          allContours.add(outerContour);
        }
      }

      // Limit inner contour detection to safely inside the image boundaries
      // Note: Changed from y < height - 1 to x < width - 1 in the inner loop condition
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
            final innerContour =
                _traceContour(paddedImage, visited, innerStart, isInverted);

            if (innerContour.length >= 4) {
              allContours.add(innerContour);
            }
          }
        }
      }

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
  img.Image rotateAndCropImage(
      img.Image sourceImage, Rect region, double rotation) {
    final center =
        Offset(region.left + region.width / 2, region.top + region.height / 2);

    if (rotation == 0) {
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

    // 创建变换矩阵
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);

    // 使用仿射变换进行旋转裁剪
    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        // 将目标坐标映射回源图像坐标
        final srcX = cos * (x - region.width / 2) -
            sin * (y - region.height / 2) +
            center.dx;
        final srcY = sin * (x - region.width / 2) +
            cos * (y - region.height / 2) +
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

  static List<Offset> _traceContour(img.Image image, List<List<bool>> visited,
      Offset start, bool isInverted) {
    try {
      final contour = <Offset>[];
      var x = start.dx.toInt();
      var y = start.dy.toInt();
      final startX = x;
      final startY = y;

      // Safety check - ensure starting point is valid
      if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
        return contour; // Return empty contour for invalid starting point
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
      // print('开始跟踪轮廓: 起点 ($x,$y), 最大迭代次数: $maxIterations');

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
            continue; // Skip invalid coordinates
          }

          // Check if this is the starting point and we've completed a loop
          if (visited[ny][nx]) {
            if (nx == startX && ny == startY && contour.length > 3) {
              contour.add(start); // Close the loop
              return contour;
            }
            // Skip already visited pixels, but log for debugging
            if (iterations % 100 == 0) {
              // Only log occasionally to avoid spam
              // print('轮廓跟踪中: 点 ($nx,$ny) 已被访问过，尝试其他方向');
            }
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

        // Log diagnostic information if no next point is found
        if (!found) {
          if (contour.length > 4) break;
        }

        // Check for exceeding iteration limit or contour size limit
        if (iterations > maxIterations) {
          break;
        }

        if (contour.length > 100000) {
          break;
        }
      } while (true);

      // If we exited the loop without returning, log the final contour state
      if (contour.isNotEmpty) {
        if (contour.length > 4) {}
      } else {}

      return contour;
    } catch (e) {
      return []; // Return empty contour on error
    }
  }
}
