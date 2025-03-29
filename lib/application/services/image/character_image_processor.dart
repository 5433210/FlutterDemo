import 'dart:isolate';
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

final characterImageProcessorProvider =
    Provider<CharacterImageProcessor>((ref) {
  final imageProcessor = ref.watch(imageProcessorProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return CharacterImageProcessor(imageProcessor, cacheManager);
});

class CharacterImageProcessor {
  static const int maxPreviewSize = 800;
  final ImageProcessor _processor;
  final CacheManager _cacheManager;

  CharacterImageProcessor(this._processor, this._cacheManager);

  /// 预览处理 - 同步执行，适用于预览场景
  Future<PreviewResult> previewProcessing(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Offset>? erasePoints,
  ) async {
    final params = ProcessingParams(
      imageData: imageData,
      region: region,
      options: options,
      erasePoints: erasePoints,
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
      var processed = await _processImageForPreview(cropped, params);

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

  /// 完整处理(包含文件生成和缓存)
  Future<ProcessingResult> processCharacterRegion(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Offset>? erasePoints,
  ) async {
    final params = ProcessingParams(
      imageData: imageData,
      region: region,
      options: options,
      erasePoints: erasePoints,
    );

    if (!params.isRegionValid) {
      throw ImageProcessingException('处理区域无效');
    }

    final cacheKey = _generateCacheKey(params);
    try {
      final cachedResult = await _cacheManager.get(cacheKey);
      if (cachedResult != null) {
        try {
          return ProcessingResult.fromArchiveBytes(cachedResult);
        } catch (e) {
          AppLogger.error('缓存数据无效', error: e);
        }
      }

      final result = await _processInIsolate(params);
      await _cacheManager.put(cacheKey, result.toArchiveBytes());
      return result;
    } catch (e) {
      AppLogger.error('图像处理失败', error: e);
      rethrow;
    }
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

  /// 生成缓存键
  String _generateCacheKey(ProcessingParams params) {
    final regionKey =
        'rect_${params.region.left.toInt()}_${params.region.top.toInt()}_'
        '${params.region.width.toInt()}_${params.region.height.toInt()}';

    final optionsKey = 'opt_${params.options.inverted ? 1 : 0}_'
        '${params.options.threshold.toInt()}_'
        '${(params.options.noiseReduction * 10).toInt()}';

    final imageHash = params.imageData.hashCode.toString();
    final eraseKey = params.erasePoints?.isNotEmpty == true
        ? 'erase_${params.erasePoints!.length}'
        : 'noerase';

    return '$imageHash:$regionKey:$optionsKey:$eraseKey';
  }

  /// 预览图像处理
  Future<img.Image> _processImageForPreview(
    img.Image source,
    ProcessingParams params,
  ) async {
    var processed = source;

    if (params.erasePoints?.isNotEmpty == true) {
      processed = _applyErase(processed, params.erasePoints!, 10.0);
    }

    processed = _binarize(processed, params.options);

    if (params.options.noiseReduction > 0.3) {
      processed = _denoise(processed, params.options.noiseReduction);
    }

    return processed;
  }

  /// 在Isolate中处理图像
  Future<ProcessingResult> _processInIsolate(ProcessingParams params) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(
        _isolateProcessImage, [receivePort.sendPort, params.toMap()]);

    try {
      final result = await receivePort.first;
      if (result is Map && result.containsKey('error')) {
        throw ImageProcessingException(result['error']);
      }
      return result as ProcessingResult;
    } finally {
      receivePort.close();
    }
  }

  /// 应用擦除
  static img.Image _applyErase(
    img.Image source,
    List<Offset> points,
    double brushSize,
  ) {
    final result =
        img.copyResize(source, width: source.width, height: source.height);
    final brushRadius = brushSize / 2;
    final white = img.ColorRgb8(255, 255, 255);

    for (final point in points) {
      final x = point.dx.clamp(0, source.width - 1).toInt();
      final y = point.dy.clamp(0, source.height - 1).toInt();

      for (var dy = -brushRadius; dy <= brushRadius; dy++) {
        for (var dx = -brushRadius; dx <= brushRadius; dx++) {
          if (dx * dx + dy * dy <= brushRadius * brushRadius) {
            final px = (x + dx).round();
            final py = (y + dy).round();
            if (px >= 0 && px < result.width && py >= 0 && py < result.height) {
              result.setPixel(px, py, white);
            }
          }
        }
      }
    }

    return result;
  }

  /// 二值化处理
  static img.Image _binarize(img.Image source, ProcessingOptions options) {
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
                : img.ColorRgb8(0, 0, 0));
      }
    }

    return options.inverted ? img.invert(gray) : gray;
  }

  /// 降噪处理
  static img.Image _denoise(img.Image source, double strength) {
    var kernelSize = (strength * 3).toInt().clamp(1, 9);
    if (kernelSize % 2 == 0) kernelSize++;
    return img.gaussianBlur(source, radius: kernelSize ~/ 2);
  }

  /// 检测轮廓
  static DetectedOutline _detectOutline(img.Image image) {
    return DetectedOutline(
      boundingRect: Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      ),
      contourPoints: [
        [
          const Offset(0, 0),
          Offset(image.width.toDouble(), 0),
          Offset(image.width.toDouble(), image.height.toDouble()),
          Offset(0, image.height.toDouble()),
          const Offset(0, 0),
        ]
      ],
    );
  }

  /// 生成SVG轮廓
  static String _generateSvgOutline(DetectedOutline outline) {
    final width = outline.boundingRect.width;
    final height = outline.boundingRect.height;
    final svg = StringBuffer()
      ..write(
          '<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">');

    for (final contour in outline.contourPoints) {
      if (contour.isEmpty) continue;
      svg.write('<path d="M${contour[0].dx},${contour[0].dy} ');
      for (int i = 1; i < contour.length; i++) {
        svg.write('L${contour[i].dx},${contour[i].dy} ');
      }
      svg.write('" stroke="black" fill="none" />');
    }

    svg.write('</svg>');
    return svg.toString();
  }

  /// Isolate处理入口
  static void _isolateProcessImage(List<dynamic> args) async {
    final SendPort sendPort = args[0] as SendPort;
    final params = ProcessingParams.fromMap(args[1] as Map<String, dynamic>);

    try {
      final sourceImage = img.decodeImage(params.imageData);
      if (sourceImage == null) {
        throw ImageProcessingException('图像解码失败');
      }

      final cropped = img.copyCrop(
        sourceImage,
        x: params.region.left.toInt().clamp(0, sourceImage.width - 1),
        y: params.region.top.toInt().clamp(0, sourceImage.height - 1),
        width: params.region.width.toInt().clamp(1, sourceImage.width),
        height: params.region.height.toInt().clamp(1, sourceImage.height),
      );

      var processed = cropped;
      if (params.erasePoints?.isNotEmpty == true) {
        processed = _applyErase(cropped, params.erasePoints!, 10.0);
      }
      processed = _binarize(processed, params.options);
      processed = _denoise(processed, params.options.noiseReduction);

      final outline =
          params.options.showContour ? _detectOutline(processed) : null;
      final processedBytes = Uint8List.fromList(img.encodePng(processed));

      final thumbnail = img.copyResize(
        processed,
        width: (processed.width *
                100 /
                math.max(processed.width, processed.height))
            .toInt(),
        height: (processed.height *
                100 /
                math.max(processed.width, processed.height))
            .toInt(),
        interpolation: img.Interpolation.cubic,
      );
      final thumbnailBytes =
          Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));

      sendPort.send(ProcessingResult(
        originalCrop: processedBytes,
        binaryImage: processedBytes,
        thumbnail: thumbnailBytes,
        svgOutline: outline != null ? _generateSvgOutline(outline) : null,
        boundingBox: outline?.boundingRect ?? params.region,
      ));
    } catch (e) {
      sendPort.send({'error': e.toString()});
    }
  }
}

/// 自定义图像处理异常
class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException(this.message);
  @override
  String toString() => 'ImageProcessingException: $message';
}

/// 预览处理结果
class PreviewResult {
  final img.Image processedImage;
  final DetectedOutline? outline;

  PreviewResult({
    required this.processedImage,
    this.outline,
  });
}

/// 处理参数
class ProcessingParams {
  final Uint8List imageData;
  final Rect region;
  final ProcessingOptions options;
  final List<Offset>? erasePoints;

  ProcessingParams({
    required this.imageData,
    required this.region,
    required this.options,
    this.erasePoints,
  });

  bool get isRegionValid => region.width > 0 && region.height > 0;

  Map<String, dynamic> toMap() => {
        'imageData': imageData,
        'region': {
          'x': region.left,
          'y': region.top,
          'width': region.width,
          'height': region.height,
        },
        'options': {
          'inverted': options.inverted,
          'threshold': options.threshold,
          'noiseReduction': options.noiseReduction,
          'showContour': options.showContour,
        },
        'erasePoints': erasePoints?.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      };

  static ProcessingParams fromMap(Map<String, dynamic> map) {
    final regionData = map['region'] as Map<String, dynamic>;
    final optionsData = map['options'] as Map<String, dynamic>;

    return ProcessingParams(
      imageData: map['imageData'] as Uint8List,
      region: Rect.fromLTWH(
        regionData['x'] as double,
        regionData['y'] as double,
        regionData['width'] as double,
        regionData['height'] as double,
      ),
      options: ProcessingOptions(
        inverted: optionsData['inverted'] as bool,
        threshold: optionsData['threshold'] as double,
        noiseReduction: optionsData['noiseReduction'] as double,
        showContour: optionsData['showContour'] as bool,
      ),
      erasePoints: (map['erasePoints'] as List<dynamic>?)
          ?.map(
            (p) => Offset(
                (p as Map<String, dynamic>)['x'] as double, p['y'] as double),
          )
          .toList(),
    );
  }
}
