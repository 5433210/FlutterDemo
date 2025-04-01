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

  /// 预览处理
  Future<PreviewResult> previewProcessing(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Map<String, dynamic>>? erasePaths,
  ) async {
    final params = ProcessingParams(
      imageData: imageData,
      region: region,
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

      final cropped = _cropAndResize(sourceImage, params.region);
      var processed = _binarize(cropped, params.options);

      if (params.erasePaths?.isNotEmpty == true) {
        processed = _applyErase(processed, params.erasePaths!);
      }

      if (params.options.noiseReduction > 0.3) {
        processed = _denoise(processed, params.options.noiseReduction);
      }

      DetectedOutline? outline;
      if (options.showContour) {
        outline = _detectOutline(processed);
      }

      return PreviewResult(
        processedImage: processed,
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
    List<Map<String, dynamic>>? erasePaths,
  ) async {
    final params = ProcessingParams(
      imageData: imageData,
      region: region,
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

      final cropped = _cropAndResize(sourceImage, params.region);
      var processed = _binarize(cropped, params.options);

      if (params.erasePaths?.isNotEmpty == true) {
        processed = _applyErase(processed, params.erasePaths!);
      }

      if (params.options.noiseReduction > 0.3) {
        processed = _denoise(processed, params.options.noiseReduction);
      }

      final processedBytes = Uint8List.fromList(img.encodePng(processed));
      final thumbnailBytes = _generateThumbnail(processed);
      final outline = options.showContour ? _detectOutline(processed) : null;

      final result = ProcessingResult(
        originalCrop: processedBytes,
        binaryImage: processedBytes,
        thumbnail: thumbnailBytes,
        svgOutline: outline != null ? _generateSvgOutline(outline) : null,
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
  ) {
    final result =
        img.copyResize(source, width: source.width, height: source.height);
    final white = img.ColorRgb8(255, 255, 255);

    for (final pathData in erasePaths) {
      final points = pathData['points'] as List<dynamic>;
      final brushSize = (pathData['brushSize'] as num?)?.toDouble() ?? 10.0;
      final brushRadius = brushSize / 2;

      for (final point in points) {
        final x =
            (point['x'] as num).toDouble().clamp(0, source.width - 1).toInt();
        final y =
            (point['y'] as num).toDouble().clamp(0, source.height - 1).toInt();

        for (var dy = -brushRadius; dy <= brushRadius; dy++) {
          for (var dx = -brushRadius; dx <= brushRadius; dx++) {
            if (dx * dx + dy * dy <= brushRadius * brushRadius) {
              final px = (x + dx).round();
              final py = (y + dy).round();
              if (px >= 0 &&
                  px < result.width &&
                  py >= 0 &&
                  py < result.height) {
                result.setPixel(px, py, white);
              }
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

    // 重新二值化以保持边缘清晰
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

  // 添加边框辅助方法 - 给图像周围添加白色边框
  static img.Image _addBorderToImage(img.Image source) {
    const borderWidth = 1; // 边框宽度（像素）
    final width = source.width + borderWidth * 2;
    final height = source.height + borderWidth * 2;
    final result = img.Image(width: width, height: height);

    // 填充白色背景（边框）
    img.fill(result, color: img.ColorRgb8(255, 255, 255));

    // 复制原图到中心位置
    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        result.setPixel(
            x + borderWidth, y + borderWidth, source.getPixel(x, y));
      }
    }

    return result;
  }

  /// 检测轮廓
  static DetectedOutline _detectOutline(img.Image binaryImage) {
    // 为图像添加边框以处理边界轮廓
    final paddedImage = _addBorderToImage(binaryImage);

    final width = paddedImage.width;
    final height = paddedImage.height;
    final visited = List.generate(
        height, (y) => List.generate(width, (x) => false, growable: false),
        growable: false);

    // 存储所有检测到的轮廓
    final allContours = <List<Offset>>[];

    // 1. 首先找到外轮廓
    var startPoint = _findFirstContourPoint(paddedImage);
    if (startPoint != null) {
      final outerContour = _traceContour(paddedImage, visited, startPoint);
      if (outerContour.length >= 4) {
        allContours.add(_smoothContour(outerContour));
      }
    }

    // 2. 寻找内部轮廓（字符内部的孔洞）
    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        // 跳过已访问的点和黑色点
        if (visited[y][x] || _isBlackPixel(paddedImage.getPixel(x, y))) {
          continue;
        }

        // 查找内部空白区域的边界点
        if (_isInnerContourPoint(paddedImage, x, y)) {
          final innerStart = Offset(x.toDouble(), y.toDouble());
          final innerContour = _traceContour(paddedImage, visited, innerStart);

          // 只添加有效的内部轮廓（长度足够且形成封闭区域）
          if (innerContour.length >= 4) {
            allContours.add(_smoothContour(innerContour));
          }
        }
      }
    }

    // 完成后调整所有轮廓点坐标（减去边框宽度）
    const borderWidth = 1; // 边框宽度为1像素
    final adjustedContours = allContours.map((contour) {
      return contour
          .map(
              (point) => Offset(point.dx - borderWidth, point.dy - borderWidth))
          .toList();
    }).toList();

    return DetectedOutline(
      boundingRect: Rect.fromLTWH(
          0, 0, binaryImage.width.toDouble(), binaryImage.height.toDouble()),
      contourPoints: adjustedContours,
    );
  }

  /// 查找第一个轮廓点
  static Offset? _findFirstContourPoint(img.Image image) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        if (_isBlackPixel(image.getPixel(x, y)) &&
            _isContourPoint(image, x, y)) {
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

  /// 生成SVG轮廓
  static String _generateSvgOutline(DetectedOutline outline) {
    final width = outline.boundingRect.width;
    final height = outline.boundingRect.height;

    if (outline.contourPoints.isEmpty) {
      return '';
    }

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

      svg.write('Z" fill="none" stroke="black" '
          'stroke-width="1.0" stroke-linecap="round" '
          'stroke-linejoin="round"/>');
    }

    svg.write('</svg>');
    return svg.toString();
  }

  /// 检查像素是否为黑色（前景）
  static bool _isBlackPixel(img.Pixel pixel) {
    return img.getLuminanceRgb(pixel.r, pixel.g, pixel.b) < 128;
  }

  /// 判断是否是轮廓点
  static bool _isContourPoint(img.Image image, int x, int y) {
    if (!_isBlackPixel(image.getPixel(x, y))) {
      return false;
    }

    if (x == 0 || x == image.width - 1 || y == 0 || y == image.height - 1) {
      return true;
    }

    final neighbors = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ];

    for (final dir in neighbors) {
      final nx = x + dir[0];
      final ny = y + dir[1];

      if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
        continue;
      }

      if (!_isBlackPixel(image.getPixel(nx, ny))) {
        return true;
      }
    }

    return false;
  }

  /// 判断是否是内部轮廓点（白色点周围有黑色点）
  static bool _isInnerContourPoint(img.Image image, int x, int y) {
    if (_isBlackPixel(image.getPixel(x, y))) {
      return false; // 黑色点不是内部轮廓点
    }

    final neighbors = [
      [-1, 0], [1, 0], [0, -1], [0, 1], // 上下左右
      [-1, -1], [-1, 1], [1, -1], [1, 1], // 对角线
    ];

    for (final dir in neighbors) {
      final nx = x + dir[0];
      final ny = y + dir[1];

      if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
        continue;
      }

      if (_isBlackPixel(image.getPixel(nx, ny))) {
        return true; // 周围有黑色点，是内部轮廓点
      }
    }

    return false;
  }

  /// 平滑轮廓
  static List<Offset> _smoothContour(List<Offset> points) {
    if (points.length < 4) return points;

    final smoothed = <Offset>[];
    const windowSize = 2;

    final extendedPoints = [
      ...points.sublist(points.length - windowSize),
      ...points,
      ...points.sublist(0, windowSize)
    ];

    for (int i = windowSize; i < extendedPoints.length - windowSize; i++) {
      var sumX = 0.0;
      var sumY = 0.0;
      var totalWeight = 0.0;

      for (int j = -windowSize; j <= windowSize; j++) {
        final weight = 1.0 / (j.abs() + 1);
        final point = extendedPoints[i + j];
        sumX += point.dx * weight;
        sumY += point.dy * weight;
        totalWeight += weight;
      }

      smoothed.add(Offset(sumX / totalWeight, sumY / totalWeight));
    }

    return smoothed;
  }

  /// 追踪轮廓
  static List<Offset> _traceContour(
      img.Image image, List<List<bool>> visited, Offset start) {
    final contour = <Offset>[];
    var x = start.dx.toInt();
    var y = start.dy.toInt();
    final startX = x;
    final startY = y;

    const directions = [
      [1, 0], // 右
      [1, 1], // 右下
      [0, 1], // 下
      [-1, 1], // 左下
      [-1, 0], // 左
      [-1, -1], // 左上
      [0, -1], // 上
      [1, -1], // 右上
    ];

    do {
      contour.add(Offset(x.toDouble(), y.toDouble()));
      visited[y][x] = true;

      var found = false;
      for (final dir in directions) {
        final nx = x + dir[0];
        final ny = y + dir[1];

        // 边界处理：当触及边界时，特殊处理
        if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
          // 如果当前点是边界点，标记为已找到，继续沿着边界移动
          if (x == 0 ||
              x == image.width - 1 ||
              y == 0 ||
              y == image.height - 1) {
            // 尝试移动到下一个边界点 - 沿着边界移动
            final nextBoundaryDir = _findNextBoundaryDirection(
                x, y, image.width, image.height, directions, dir);
            if (nextBoundaryDir != null) {
              x += nextBoundaryDir[0];
              y += nextBoundaryDir[1];
              found = true;
              break;
            }
          }
          continue;
        }

        if (visited[ny][nx]) {
          if (nx == startX && ny == startY && contour.length > 3) {
            contour.add(start);
            return contour;
          }
          continue;
        }

        if (_isBlackPixel(image.getPixel(nx, ny)) &&
            _isContourPoint(image, nx, ny)) {
          x = nx;
          y = ny;
          found = true;
          break;
        }
      }

      if (!found || contour.length > 400000) {
        break;
      }
    } while (true);

    return contour;
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
  final ProcessingOptions options;
  final List<Map<String, dynamic>>? erasePaths;

  ProcessingParams({
    required this.imageData,
    required this.region,
    required this.options,
    this.erasePaths,
  });

  bool get isRegionValid => region.width > 0 && region.height > 0;
}
