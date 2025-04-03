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
    List<Map<String, dynamic>>? erasePaths,
  ) async {
    try {
      final pathsToProcess = erasePaths ?? [];
      print(
          'ImageProcessor: 处理 ${pathsToProcess.length} 个擦除路径, 图像反转=${options.inverted}');

      // 添加调试信息: 检查传入的路径颜色
      if (pathsToProcess.isNotEmpty) {
        int blackPaths = 0;
        int whitePaths = 0;
        for (final path in pathsToProcess) {
          final brushColor = path['brushColor'] as int?;
          if (brushColor == Colors.black.value)
            blackPaths++;
          else
            whitePaths++;
        }
        print('擦除路径颜色统计: 黑色=$blackPaths, 白色=$whitePaths');
      }

      final params = ProcessingParams(
        imageData: imageData,
        region: region,
        options: options,
        erasePaths: pathsToProcess,
      );

      if (!params.isRegionValid) {
        throw ImageProcessingException('预览区域无效');
      }

      final sourceImage = img.decodeImage(params.imageData);
      if (sourceImage == null) {
        throw ImageProcessingException('图像解码失败');
      }

      final cropped = _cropAndResize(sourceImage, params.region);
      var processed = _binarize(cropped, options);

      // 记录二值化后图像的统计数据
      _logImageStats(processed, '二值化后');

      if (params.erasePaths?.isNotEmpty == true) {
        // 对于每种颜色的路径，分别应用擦除效果
        processed = _applyEraseWithMixedColors(
            processed, params.erasePaths!, params.options);
        _logImageStats(processed, '所有擦除后');
      }

      if (params.options.noiseReduction > 0.3) {
        processed = _denoise(processed, params.options.noiseReduction);
      }

      DetectedOutline? outline;
      if (options.showContour) {
        print('开始检测轮廓...');
        outline = _detectOutline(processed, options.inverted);
        print('轮廓检测完成，获取 ${outline.contourPoints.length} 条轮廓');
      }

      return PreviewResult(
        processedImage: processed,
        outline: outline,
      );
    } catch (e, stack) {
      AppLogger.error('预览处理失败', error: e, stackTrace: stack);
      print('处理失败详细信息: $e\n$stack');
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
        processed = _applyErase(processed, params.erasePaths!, params.options);
      }

      if (params.options.noiseReduction > 0.3) {
        processed = _denoise(processed, params.options.noiseReduction);
      }

      final processedBytes = Uint8List.fromList(img.encodePng(processed));
      final thumbnailBytes = _generateThumbnail(processed);
      final outline = options.showContour
          ? _detectOutline(processed, options.inverted)
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

    for (final pathData in erasePaths) {
      final points = pathData['points'] as List<dynamic>;
      final brushSize = (pathData['brushSize'] as num?)?.toDouble() ?? 10.0;
      final brushRadius = brushSize / 2;

      // 获取路径的颜色
      final brushColorValue = pathData['brushColor'] as int?;

      // 修正: 确保颜色逻辑与图像反转状态一致
      img.Color brushColor;
      if (brushColorValue != null) {
        // 使用传入的颜色值
        brushColor = img.ColorRgb8((brushColorValue >> 16) & 0xFF,
            (brushColorValue >> 8) & 0xFF, brushColorValue & 0xFF);
        print(
            '使用路径指定的颜色: ${brushColorValue == Colors.black.value ? "黑色" : "白色"}');
      } else {
        // 默认颜色逻辑
        brushColor = options.inverted
            ? img.ColorRgb8(0, 0, 0)
            : img.ColorRgb8(255, 255, 255);
        print('使用默认颜色: ${options.inverted ? "黑色" : "白色"}');
      }

      for (final point in points) {
        double x, y;
        if (point is Offset) {
          x = point.dx;
          y = point.dy;
        } else if (point is Map) {
          x = (point['x'] as num).toDouble();
          y = (point['y'] as num).toDouble();
        } else {
          continue;
        }

        x = x.clamp(0, source.width - 1);
        y = y.clamp(0, source.height - 1);

        for (var dy = -brushRadius; dy <= brushRadius; dy++) {
          for (var dx = -brushRadius; dx <= brushRadius; dx++) {
            if (dx * dx + dy * dy <= brushRadius * brushRadius) {
              final px = (x + dx).round();
              final py = (y + dy).round();
              if (px >= 0 &&
                  px < result.width &&
                  py >= 0 &&
                  py < result.height) {
                result.setPixel(px, py, brushColor); // 使用路径的颜色
              }
            }
          }
        }
      }
    }

    return result;
  }

  /// 应用可能包含不同颜色的擦除路径
  img.Image _applyEraseWithMixedColors(
    img.Image source,
    List<Map<String, dynamic>> erasePaths,
    ProcessingOptions options,
  ) {
    // 创建源图像的精确副本，确保像素对齐
    final result =
        img.copyResize(source, width: source.width, height: source.height);

    // 为调试添加日志
    print(
        '应用擦除效果 - 图像尺寸: ${source.width}x${source.height}, 路径数量: ${erasePaths.length}');

    // 收集黑色和白色路径
    final blackPaths = erasePaths
        .where((path) => (path['brushColor'] as int?) == Colors.black.value)
        .toList();
    final whitePaths = erasePaths
        .where((path) => (path['brushColor'] as int?) != Colors.black.value)
        .toList();

    print('应用擦除: 黑色路径=${blackPaths.length}, 白色路径=${whitePaths.length}');

    // 确保路径应用的像素精确对齐
    _applyPathsWithExactPixelAlignment(
        result, whitePaths, Colors.white.value, options);
    _applyPathsWithExactPixelAlignment(
        result, blackPaths, Colors.black.value, options);

    return result;
  }

  /// 使用精确像素对齐的方式应用路径
  void _applyPathsWithExactPixelAlignment(
    img.Image image,
    List<Map<String, dynamic>> paths,
    int brushColorValue,
    ProcessingOptions options,
  ) {
    if (paths.isEmpty) return;

    final brushColor = brushColorValue == Colors.black.value
        ? img.ColorRgb8(0, 0, 0)
        : img.ColorRgb8(255, 255, 255);

    // 跟踪修改的像素数
    int modifiedPixels = 0;

    for (final pathData in paths) {
      final points = pathData['points'] as List<dynamic>;
      if (points.isEmpty) continue;

      // 确保笔刷大小是整数，避免小数造成的不精确
      final brushSize =
          (pathData['brushSize'] as num?)?.toDouble().roundToDouble() ?? 10.0;
      final brushRadius = (brushSize / 2).floor().toDouble();

      for (final point in points) {
        double x, y;
        if (point is Offset) {
          x = point.dx;
          y = point.dy;
        } else if (point is Map) {
          x = (point['x'] as num).toDouble();
          y = (point['y'] as num).toDouble();
        } else {
          continue;
        }

        // 确保x和y是整数值，避免小数位置
        final centerX = x.round();
        final centerY = y.round();

        // 计算边界框以避免边界检查开销
        final left = math.max(0, centerX - brushRadius.ceil());
        final top = math.max(0, centerY - brushRadius.ceil());
        final right = math.min(image.width - 1, centerX + brushRadius.ceil());
        final bottom = math.min(image.height - 1, centerY + brushRadius.ceil());

        // 批量修改像素，避免重复边界检查
        for (int py = top; py <= bottom; py++) {
          for (int px = left; px <= right; px++) {
            // 检查点是否在圆内
            final dx = px - centerX;
            final dy = py - centerY;
            if (dx * dx + dy * dy <= brushRadius * brushRadius) {
              image.setPixel(px, py, brushColor);
              modifiedPixels++;
            }
          }
        }
      }
    }

    print(
        '应用${brushColorValue == Colors.black.value ? "黑色" : "白色"}路径 - 修改了 $modifiedPixels 个像素');
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

  // 新增: 统计图像黑白像素
  void _logImageStats(img.Image image, String stage) {
    int blackPixels = 0;
    int whitePixels = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
        if (luminance < 128)
          blackPixels++;
        else
          whitePixels++;
      }
    }

    print('$stage - 图像统计: 黑色像素=$blackPixels, 白色像素=$whitePixels');
  }

  // 处理图像边框
  static img.Image _addBorderToImage(img.Image source, bool isInverted) {
    const borderWidth = 1;
    final width = source.width + borderWidth * 2;
    final height = source.height + borderWidth * 2;
    final result = img.Image(width: width, height: height);

    // 根据反转模式选择背景色
    // 在正常模式下使用白色背景，在反转模式下使用黑色背景
    // 这确保边框始终被视为背景而不是前景
    final borderColor = isInverted
        ? img.ColorRgb8(0, 0, 0) // 反转模式使用黑色边框
        : img.ColorRgb8(255, 255, 255); // 正常模式使用白色边框

    img.fill(result, color: borderColor);

    for (int y = 0; y < source.height; y++) {
      for (int x = 0; x < source.width; x++) {
        result.setPixel(
            x + borderWidth, y + borderWidth, source.getPixel(x, y));
      }
    }

    return result;
  }

  /// 检测轮廓 - 简化为单一方法，处理所有情况
  static DetectedOutline _detectOutline(
      img.Image binaryImage, bool isInverted) {
    try {
      // 创建图像的副本，确保不影响原始图像
      final processImage = img.copyResize(binaryImage,
          width: binaryImage.width, height: binaryImage.height);

      // 添加边框 - 确保边框颜色正确匹配反转状态
      final paddedImage = _addBorderToImage(processImage, isInverted);

      // 记录图像尺寸
      print(
          '轮廓检测 - 原始图像: ${binaryImage.width}x${binaryImage.height}, 填充图像: ${paddedImage.width}x${paddedImage.height}');

      final width = paddedImage.width;
      final height = paddedImage.height;
      final visited = List.generate(
          height, (y) => List.generate(width, (x) => false, growable: false),
          growable: false);

      final allContours = <List<Offset>>[];

      // 首先找到外部轮廓
      var startPoint = _findFirstContourPoint(paddedImage, isInverted);
      if (startPoint != null) {
        // 使用更精确的轮廓跟踪算法
        final outerContour = _traceContourPrecisely(
            paddedImage, visited, startPoint, isInverted);
        if (outerContour.length >= 4) {
          allContours.add(outerContour);
          print('找到外部轮廓 - ${outerContour.length} 个点');
        }
      }

      // 寻找内部轮廓
      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          // 跳过已访问点和前景点
          if (visited[y][x] ||
              _isForegroundPixel(paddedImage.getPixel(x, y), isInverted)) {
            continue;
          }
          if (_isInnerContourPoint(paddedImage, x, y, isInverted)) {
            final innerStart = Offset(x.toDouble(), y.toDouble());
            final innerContour = _traceContourPrecisely(
                paddedImage, visited, innerStart, isInverted);
            if (innerContour.length >= 4) {
              allContours.add(innerContour);
            }
          }
        }
      }

      const borderWidth = 1;
      final adjustedContours = allContours.map((contour) {
        // 修正：确保边框偏移量正确应用到每个轮廓点
        return contour
            .map((point) =>
                Offset(point.dx - borderWidth, point.dy - borderWidth))
            .toList();
      }).toList();

      print('轮廓检测完成，找到 ${adjustedContours.length} 条轮廓');

      // 验证第一条轮廓的位置（调试用）
      if (adjustedContours.isNotEmpty && adjustedContours[0].isNotEmpty) {
        final firstContour = adjustedContours[0];
        double minX = double.infinity, minY = double.infinity;
        double maxX = -double.infinity, maxY = -double.infinity;

        for (var point in firstContour) {
          minX = math.min(minX, point.dx);
          minY = math.min(minY, point.dy);
          maxX = math.max(maxX, point.dx);
          maxY = math.max(maxY, point.dy);
        }
        print('第一条轮廓边界: ($minX,$minY) - ($maxX,$maxY)');
      }

      return DetectedOutline(
        boundingRect: Rect.fromLTWH(
            0, 0, binaryImage.width.toDouble(), binaryImage.height.toDouble()),
        contourPoints: adjustedContours,
      );
    } catch (e, stack) {
      print('轮廓检测错误: $e\n$stack');
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
        if (_isContourPoint(image, x, y, isInverted)) {
          return Offset(x.toDouble(), y.toDouble());
        }
      }
    }
    return null;
  }

  static bool _isContourPoint(img.Image image, int x, int y, bool isInverted) {
    if (!_isForegroundPixel(image.getPixel(x, y), isInverted)) {
      return false;
    }
    if (x == 0 || x == image.width - 1 || y == 0 || y == image.height - 1) {
      return true;
    }
    final neighbors = [
      [0, -1],
      [0, 1],
      [-1, 0],
      [1, 0],
    ];
    for (final dir in neighbors) {
      final nx = x + dir[0];
      final ny = y + dir[1];
      if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
        continue;
      }
      if (!_isForegroundPixel(image.getPixel(nx, ny), isInverted)) {
        return true;
      }
    }
    return false;
  }

  static bool _isContourPointPrecise(
      img.Image image, int x, int y, bool isInverted) {
    // 确保当前像素是前景
    if (!_isForegroundPixel(image.getPixel(x, y), isInverted)) {
      return false;
    }

    // 如果是边界像素，必定是轮廓点
    if (x == 0 || x == image.width - 1 || y == 0 || y == image.height - 1) {
      return true;
    }

    // 检查4连通邻域 - 只需要一个相邻像素是背景，就认为这是轮廓点
    const neighbors4 = [
      [0, -1], // 上
      [1, 0], // 右
      [0, 1], // 下
      [-1, 0], // 左
    ];

    for (final dir in neighbors4) {
      final nx = x + dir[0];
      final ny = y + dir[1];
      if (nx >= 0 &&
          nx < image.width &&
          ny >= 0 &&
          ny < image.height &&
          !_isForegroundPixel(image.getPixel(nx, ny), isInverted)) {
        return true; // 找到一个背景像素邻居
      }
    }

    return false; // 所有4连通邻居都是前景，不是轮廓点
  }

  static bool _isForegroundPixel(img.Pixel pixel, bool isInverted) {
    final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
    return isInverted
        ? luminance > 127 // In inverted mode, bright pixels are foreground
        : luminance < 127; // In normal mode, dark pixels are foreground
  }

  static bool _isInnerContourPoint(
      img.Image image, int x, int y, bool isInverted) {
    if (_isForegroundPixel(image.getPixel(x, y), isInverted)) {
      return false;
    }
    final neighbors = [
      [0, -1],
      [0, 1],
      [-1, 0],
      [1, 0],
      [1, -1],
      [1, 1],
      [-1, -1],
      [-1, 1],
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

  static List<Offset> _traceContourPrecisely(img.Image image,
      List<List<bool>> visited, Offset start, bool isInverted) {
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

    int currentDirIndex = 0; // 从右方向开始
    int stepCount = 0;

    do {
      // 避免无限循环
      if (stepCount++ > 100000) {
        print('轮廓跟踪步数超过限制，强制结束');
        break;
      }

      // 添加当前点到轮廓并标记为已访问
      contour.add(Offset(x.toDouble(), y.toDouble()));
      visited[y][x] = true;

      // 寻找下一个轮廓点
      bool foundNextPoint = false;

      // 尝试从当前方向开始，顺时针旋转寻找下一个点
      for (int i = 0; i < directions.length; i++) {
        // 计算要检查的方向索引
        int checkDirIndex = (currentDirIndex + i) % directions.length;
        final dir = directions[checkDirIndex];

        final nx = x + dir[0];
        final ny = y + dir[1];

        // 检查边界
        if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
          continue;
        }

        // 如果回到起点且轮廓足够长，则完成
        if (nx == startX && ny == startY && contour.length > 3) {
          return contour;
        }

        // 如果这个点是轮廓点且未访问过，则采用它
        if (!visited[ny][nx] &&
            _isContourPointPrecise(image, nx, ny, isInverted)) {
          x = nx;
          y = ny;
          currentDirIndex = checkDirIndex; // 更新当前方向
          foundNextPoint = true;
          break;
        }
      }

      // 如果找不到下一个轮廓点，退出循环
      if (!foundNextPoint) {
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
