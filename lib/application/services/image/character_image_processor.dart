import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../infrastructure/image/image_processor.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../providers/service_providers.dart';
import '../storage/cache_manager.dart';

/// Character Image Processor Provider
final characterImageProcessorProvider =
    Provider<CharacterImageProcessor>((ref) {
  final imageProcessor = ref.watch(imageProcessorProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return CharacterImageProcessor(imageProcessor, cacheManager);
});

/// 字符图像处理器
class CharacterImageProcessor {
  static const int maxPreviewSize = 800;
  final ImageProcessor _processor;
  final CacheManager _cacheManager;

  CharacterImageProcessor(this._processor, this._cacheManager);

  String generateSvgOutline(DetectedOutline outline, bool isInverted) {
    final width = outline.boundingRect.width;
    final height = outline.boundingRect.height;

    if (outline.contourPoints.isEmpty) {
      return '';
    }

    final strokeColor = isInverted ? 'white' : 'black';

    final svg = StringBuffer()
      ..write(
          '<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">');

    for (final contour in outline.contourPoints) {
      if (contour.length < 3) continue;

      svg.write('<path d="');
      svg.write(
          'M${contour[0].dx.toStringAsFixed(1)},${contour[0].dy.toStringAsFixed(1)} ');

      for (int i = 1; i < contour.length - 1; i++) {
        final p0 = contour[i - 1];
        final p1 = contour[i];
        final p2 = contour[i + 1];

        final control =
            Offset(p1.dx + (p2.dx - p0.dx) / 4, p1.dy + (p2.dy - p0.dy) / 4);

        svg.write(
            'Q${control.dx.toStringAsFixed(1)},${control.dy.toStringAsFixed(1)} '
            '${p1.dx.toStringAsFixed(1)},${p1.dy.toStringAsFixed(1)} ');
      }

      svg.write('Z" fill="none" stroke="$strokeColor" '
          'stroke-width="1.0" stroke-linecap="round" '
          'stroke-linejoin="round"/>');
    }

    svg.write('</svg>');
    return svg.toString();
  }

  /// 预览处理
  Future<PreviewResult> previewProcessing(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Map<String, dynamic>>? erasePaths, {
    double rotation = 0.0,
  }) async {
    final params = ProcessingParams(
      imageData: imageData,
      region: region,
      rotation: rotation,
      options: options,
      erasePaths: erasePaths,
    );

    if (!params.isRegionValid) {
      throw ImageProcessingException('预览区域无效');
    }

    try {
      final sourceImage = img.decodeImage(params.imageData);
      if (sourceImage == null) {
        throw ImageProcessingException('图像解码失败');
      }

      final croppedImage =
          _rotateAndCropImage(sourceImage, params.region, params.rotation);

      // 应用对比度和亮度调整
      img.Image finalImage = croppedImage;
      if (params.options.contrast != 1.0 || params.options.brightness != 0.0) {
        final adjustedImage =
            img.Image(width: croppedImage.width, height: croppedImage.height);
        for (var y = 0; y < croppedImage.height; y++) {
          for (var x = 0; x < croppedImage.width; x++) {
            final pixel = croppedImage.getPixel(x, y);
            final r = ((pixel.r - 128) * params.options.contrast +
                    128 +
                    params.options.brightness)
                .clamp(0, 255)
                .round();
            final g = ((pixel.g - 128) * params.options.contrast +
                    128 +
                    params.options.brightness)
                .clamp(0, 255)
                .round();
            final b = ((pixel.b - 128) * params.options.contrast +
                    128 +
                    params.options.brightness)
                .clamp(0, 255)
                .round();
            adjustedImage.setPixelRgba(x, y, r, g, b, pixel.a);
          }
        }
        finalImage = adjustedImage;
      }

      finalImage = _binarize(finalImage, params.options);

      if (params.erasePaths?.isNotEmpty == true) {
        finalImage =
            _applyErase(finalImage, params.erasePaths!, params.options);
      } // 应用其他处理选项

      if (params.options.noiseReduction > 0.3) {
        finalImage = _denoise(finalImage, params.options.noiseReduction);
      }

      final processedBytes = Uint8List.fromList(img.encodeJpg(finalImage));
      final thumbnailBytes = _generateThumbnail(finalImage);
      final outline = options.showContour
          ? _detectOutline(finalImage, options.inverted)
          : null;

      final result = ProcessingResult(
        originalCrop: processedBytes,
        binaryImage: processedBytes,
        thumbnail: thumbnailBytes,
        svgOutline: outline != null
            ? generateSvgOutline(outline, options.inverted)
            : null,
        boundingBox: outline?.boundingRect ?? params.region,
      );

      return PreviewResult(
        processedImage: finalImage,
        outline: outline,
      );
    } catch (e) {
      AppLogger.error('预览处理失败', error: e);
      rethrow;
    }
  }

  /// 完整处理
  Future<ProcessingResult> processCharacterRegion(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Map<String, dynamic>>? erasePaths, {
    double rotation = 0.0,
  }) async {
    final params = ProcessingParams(
      imageData: imageData,
      region: region,
      rotation: rotation,
      options: options,
      erasePaths: erasePaths,
    );

    if (!params.isRegionValid) {
      throw ImageProcessingException('处理区域无效');
    }

    final cacheKey = _generateCacheKey(params);

    try {
      final sourceImage = img.decodeImage(params.imageData);
      if (sourceImage == null) {
        throw ImageProcessingException('图像解码失败');
      }

      final croppedImage =
          _rotateAndCropImage(sourceImage, params.region, params.rotation);

      // 应用对比度和亮度调整
      img.Image finalImage = croppedImage;
      if (params.options.contrast != 1.0 || params.options.brightness != 0.0) {
        final adjustedImage =
            img.Image(width: croppedImage.width, height: croppedImage.height);
        for (var y = 0; y < croppedImage.height; y++) {
          for (var x = 0; x < croppedImage.width; x++) {
            final pixel = croppedImage.getPixel(x, y);
            final r = ((pixel.r - 128) * params.options.contrast +
                    128 +
                    params.options.brightness * 255)
                .clamp(0, 255)
                .round();
            final g = ((pixel.g - 128) * params.options.contrast +
                    128 +
                    params.options.brightness * 255)
                .clamp(0, 255)
                .round();
            final b = ((pixel.b - 128) * params.options.contrast +
                    128 +
                    params.options.brightness * 255)
                .clamp(0, 255)
                .round();
            adjustedImage.setPixelRgba(x, y, r, g, b, pixel.a);
          }
        }
        finalImage = adjustedImage;
      }

      // 应用二值化
      finalImage = _binarize(finalImage, params.options);

      // 应用擦除路径
      if (params.erasePaths?.isNotEmpty == true) {
        finalImage =
            _applyErase(finalImage, params.erasePaths!, params.options);
      }

      // 应用其他处理选项
      if (params.options.noiseReduction > 0.3) {
        finalImage = _denoise(finalImage, params.options.noiseReduction);
      }

      final processedBytes = Uint8List.fromList(img.encodeJpg(finalImage));
      final thumbnailBytes = _generateThumbnail(finalImage);
      final outline = options.showContour
          ? _detectOutline(finalImage, options.inverted)
          : null;

      final result = ProcessingResult(
        originalCrop: processedBytes,
        binaryImage: processedBytes,
        thumbnail: thumbnailBytes,
        svgOutline: outline != null
            ? generateSvgOutline(outline, options.inverted)
            : null,
        boundingBox: outline?.boundingRect ?? params.region,
      );

      await _cacheManager.put(cacheKey, result.toArchiveBytes());
      return result;
    } catch (e) {
      AppLogger.error('图像处理失败', error: e);
      rethrow;
    }
  }

  /// 应用擦除
  img.Image _applyErase(
    img.Image source,
    List<Map<String, dynamic>> erasePaths,
    ProcessingOptions options,
  ) {
    final result =
        img.copyResize(source, width: source.width, height: source.height);

    final imageWidth = source.width;
    final imageHeight = source.height;

    for (final pathData in erasePaths) {
      final points = pathData['points'] as List<dynamic>;
      final brushSize = (pathData['brushSize'] as num?)?.toDouble() ?? 10.0;
      final brushRadius = brushSize / 2;

      // 获取路径的颜色，默认为白色
      final brushColorValue = pathData['brushColor'] as int?;
      final brushColor = brushColorValue != null
          ? img.ColorRgb8((brushColorValue >> 16) & 0xFF,
              (brushColorValue >> 8) & 0xFF, brushColorValue & 0xFF)
          : options.inverted
              ? img.ColorRgb8(0, 0, 0) // 反转时使用黑色
              : img.ColorRgb8(255, 255, 255); // 未反转时使用白色

      for (final point in points) {
        double x, y;
        if (point is Offset) {
          x = point.dx;
          y = point.dy;
        } else if (point is Map) {
          x = (point['dx'] ?? point['x'] as num).toDouble();
          y = (point['dy'] ?? point['y'] as num).toDouble();
        } else {
          continue;
        }

        // Skip points completely outside the image (plus brush radius buffer)
        if (x < -brushRadius ||
            y < -brushRadius ||
            x >= imageWidth + brushRadius ||
            y >= imageHeight + brushRadius) {
          continue;
        }

        // Clamp points to valid coordinates for calculation
        x = x.clamp(0, imageWidth - 1);
        y = y.clamp(0, imageHeight - 1);

        // Apply soft-edge brush with reduced blur radius
        for (var dy = -brushRadius * 1.05; dy <= brushRadius * 1.05; dy++) {
          // Skip entire row if outside Y boundaries
          final py = (y + dy).round();
          if (py < 0 || py >= imageHeight) continue;

          for (var dx = -brushRadius * 1.05; dx <= brushRadius * 1.05; dx++) {
            // Skip pixel if outside X boundaries
            final px = (x + dx).round();
            if (px < 0 || px >= imageWidth) continue;

            // Distance check
            final distSquared = dx * dx + dy * dy;
            if (distSquared > brushRadius * brushRadius * 1.1) continue;

            // Alpha blending calculation - only for pixels in bounds
            double alpha = 1.0;
            if (distSquared > brushRadius * brushRadius * 0.9) {
              final dist = math.sqrt(distSquared);
              alpha = 1.0 - ((dist - brushRadius * 0.95) / (brushRadius * 0.1));
              alpha = alpha.clamp(0.0, 1.0);
            }

            if (alpha > 0.1) {
              final originalPixel = result.getPixel(px, py);
              final blendedR =
                  (brushColor.r * alpha + originalPixel.r * (1 - alpha))
                      .round()
                      .clamp(0, 255);
              final blendedG =
                  (brushColor.g * alpha + originalPixel.g * (1 - alpha))
                      .round()
                      .clamp(0, 255);
              final blendedB =
                  (brushColor.b * alpha + originalPixel.b * (1 - alpha))
                      .round()
                      .clamp(0, 255);

              result.setPixelRgb(px, py, blendedR, blendedG, blendedB);
            }
          }
        }
      }
    }

    return result;
  }

  /// 二值化处理
  img.Image _binarize(img.Image source, ProcessingOptions options) {
    final gray = img.grayscale(source);
    final threshold = options.threshold.toInt().clamp(0, 255);

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

    return options.inverted ? img.invert(gray) : gray;
  }

  /// 计算旋转后的矩形区域
  Rect _calculateRotatedRect(Rect rect, double rotation) {
    if (rotation == 0) return rect;

    final center = Offset(rect.center.dx, rect.center.dy);
    final width = rect.width;
    final height = rect.height;

    // 计算旋转后的四个角点
    final points = [
      _rotatePoint(Offset(rect.left, rect.top), center, rotation),
      _rotatePoint(Offset(rect.right, rect.top), center, rotation),
      _rotatePoint(Offset(rect.right, rect.bottom), center, rotation),
      _rotatePoint(Offset(rect.left, rect.bottom), center, rotation),
    ];

    // 计算新的边界
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final point in points) {
      minX = math.min(minX, point.dx);
      minY = math.min(minY, point.dy);
      maxX = math.max(maxX, point.dx);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTWH(minX, minY, maxX - minX, maxY - minY);
  }

  /// 裁剪并调整大小
  img.Image _cropAndResize(img.Image source, Rect region) {
    final cropped = img.copyCrop(
      source,
      x: region.left.toInt().clamp(0, source.width - 1),
      y: region.top.toInt().clamp(0, source.height - 1),
      width: region.width.toInt().clamp(1, source.width),
      height: region.height.toInt().clamp(1, source.height),
    );

    if (cropped.width > maxPreviewSize || cropped.height > maxPreviewSize) {
      final ratio = maxPreviewSize / math.max(cropped.width, cropped.height);
      return img.copyResize(
        cropped,
        width: (cropped.width * ratio).toInt(),
        height: (cropped.height * ratio).toInt(),
        interpolation: img.Interpolation.cubic,
      );
    }

    return cropped;
  }

  /// 降噪处理
  img.Image _denoise(img.Image source, double strength) {
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

  /// 生成缓存键
  String _generateCacheKey(ProcessingParams params) {
    final regionKey =
        'rect_${params.region.left.toInt()}_${params.region.top.toInt()}_'
        '${params.region.width.toInt()}_${params.region.height.toInt()}';
    final optionsKey = 'opt_${params.options.inverted ? 1 : 0}_'
        '${params.options.threshold.toInt()}_'
        '${(params.options.noiseReduction * 10).toInt()}';
    final eraseKey = params.erasePaths?.isNotEmpty == true
        ? 'erase_${params.erasePaths!.length}'
        : 'noerase';
    return '${params.imageData.hashCode}:$regionKey:$optionsKey:$eraseKey';
  }

  /// 生成缩略图
  Uint8List _generateThumbnail(img.Image source) {
    final thumbnail = img.copyResize(
      source,
      width:
          (source.width * 100 / math.max(source.width, source.height)).toInt(),
      height:
          (source.height * 100 / math.max(source.width, source.height)).toInt(),
      interpolation: img.Interpolation.cubic,
    );
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
  }

  /// 对图像进行基于选区中心的旋转和裁剪处理
  ///
  /// [sourceImage] 源图像
  /// [region] 选区矩形
  /// [rotation] 旋转角度
  /// 返回处理后的图像
  img.Image _rotateAndCropImage(
    img.Image sourceImage,
    Rect region,
    double rotation,
  ) {
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

  Offset _rotatePoint(Offset point, Offset center, double rotation) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final cos = math.cos(rotation);
    final sin = math.sin(rotation);
    return Offset(
      center.dx + dx * cos - dy * sin,
      center.dy + dx * sin + dy * cos,
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

  /// 检测轮廓
  static DetectedOutline _detectOutline(
      img.Image binaryImage, bool isInverted) {
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
    } catch (e, stackTrace) {
      print('轮廓检测异常: $e');
      print('轮廓检测堆栈: $stackTrace');

      // Return an empty outline instead of crashing
      return DetectedOutline(
        boundingRect: Rect.fromLTWH(
            0, 0, binaryImage.width.toDouble(), binaryImage.height.toDouble()),
        contourPoints: [],
      );
    }
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

  /// 查找下一个边界方向
  static List<int>? _findNextBoundaryDirection(int x, int y, int width,
      int height, List<List<int>> allDirections, List<int> currentDir) {
    // 确定当前是哪个边界
    bool isLeftBoundary = x == 0;
    bool isRightBoundary = x == width - 1;
    bool isTopBoundary = y == 0;
    bool isBottomBoundary = y == height - 1;

    // 循环尝试各个方向，找到一个有效的边界点
    int startIdx = allDirections.indexOf(currentDir);
    for (int i = 0; i < allDirections.length; i++) {
      int idx = (startIdx + i) % allDirections.length;
      List<int> dir = allDirections[idx];

      int nx = x + dir[0];
      int ny = y + dir[1];

      // 检查是否仍在边界上且是有效坐标
      if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
        // 确保新点至少有一边在边界上
        if ((isLeftBoundary && nx == 0) ||
            (isRightBoundary && nx == width - 1) ||
            (isTopBoundary && ny == 0) ||
            (isBottomBoundary && ny == height - 1)) {
          return dir;
        }
      }
    }

    return null; // 没找到合适的边界方向
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
      print('检查轮廓点时出错: $e');
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
            continue; // Skip already visited pixels
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
        if (!found || iterations > maxIterations || contour.length > 10000) {
          break; // Prevent infinite loops and excessively long contours
        }
      } while (true);

      return contour;
    } catch (e, stackTrace) {
      print('轮廓跟踪异常: $e');
      print('轮廓跟踪堆栈: $stackTrace');
      return []; // Return empty contour on error
    }
  }
}

/// 图像处理异常
class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException(this.message);
  @override
  String toString() => 'ImageProcessingException: $message';
}

/// 预览结果
class PreviewResult {
  final img.Image processedImage;
  final DetectedOutline? outline;

  PreviewResult({
    required this.processedImage,
    this.outline,
  });
}

/// 图像处理参数
class ProcessingParams {
  final Uint8List imageData;
  final Rect region;
  final double rotation;
  final ProcessingOptions options;
  final List<Map<String, dynamic>>? erasePaths;

  const ProcessingParams({
    required this.imageData,
    required this.region,
    this.rotation = 0.0,
    required this.options,
    this.erasePaths,
  });

  bool get isRegionValid =>
      region.left >= 0 &&
      region.top >= 0 &&
      region.width > 0 &&
      region.height > 0;
}
