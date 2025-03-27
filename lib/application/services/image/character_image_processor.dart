import 'dart:isolate';
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
  final ImageProcessor _processor;
  final CacheManager _cacheManager;

  CharacterImageProcessor(this._processor, this._cacheManager);

  /// 完整的字符区域处理流程
  Future<ProcessingResult> processCharacterRegion(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Offset>? erasePoints,
  ) async {
    // 生成处理参数的缓存键
    final cacheKey = _generateCacheKey(imageData, region, options, erasePoints);

    // 检查缓存
    AppLogger.debug('检查缓存', data: {'cacheKey': cacheKey});
    final cachedResult = await _cacheManager.get(cacheKey);
    if (cachedResult != null) {
      AppLogger.debug('找到缓存的处理结果', data: {'dataLength': cachedResult.length});
      try {
        // 从缓存数据反序列化结果
        return _deserializeProcessingResult(cachedResult);
      } catch (e) {
        print('从缓存反序列化处理结果失败: $e');
        // 缓存数据有问题则继续处理
      }
    }

    AppLogger.debug('未找到缓存，开始处理图像...');
    // 创建处理参数
    final processingParams = {
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

    late ProcessingResult result;
    try {
      result = await _processInIsolate(processingParams);

      AppLogger.debug('图像处理完成',
          data: {'resultSize': '${result.binaryImage.length}bytes'});
      AppLogger.debug('缓存处理结果');
      await _cacheManager.put(cacheKey, result.toArchiveBytes());
    } catch (e) {
      AppLogger.error('图像处理失败', error: e);
      rethrow;
    }

    return result;
  }

  /// 从缓存数据反序列化处理结果
  ProcessingResult _deserializeProcessingResult(dynamic cachedData) {
    try {
      final bytes = cachedData as Uint8List;
      return ProcessingResult.fromArchiveBytes(bytes);
    } catch (e) {
      print('从缓存反序列化处理结果失败: $e');
      rethrow;
    }
  }

  /// 生成缓存键
  String _generateCacheKey(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Offset>? erasePoints,
  ) {
    // 区域坐标处理为整数，减少不必要的差异
    final regionKey =
        'rect_${region.left.toInt()}_${region.top.toInt()}_${region.width.toInt()}_${region.height.toInt()}';

    // 处理选项键
    final optionsKey =
        'opt_${options.inverted ? 1 : 0}_${options.threshold.toInt()}_${(options.noiseReduction * 10).toInt()}';

    // 使用图像数据的哈希作为唯一标识
    final imageHashCode = imageData.hashCode.toString();

    // 擦除点处理（如果有）
    final eraseKey = erasePoints != null && erasePoints.isNotEmpty
        ? 'erase_${erasePoints.length}'
        : 'noerase';

    return '$imageHashCode:$regionKey:$optionsKey:$eraseKey';
  }

  /// 在Isolate中处理图像
  Future<ProcessingResult> _processInIsolate(
      Map<String, dynamic> params) async {
    final receivePort = ReceivePort();
    await Isolate.spawn(_isolateProcessImage, [receivePort.sendPort, params]);

    final result = await receivePort.first as Map<String, dynamic>;
    receivePort.close();

    if (result.containsKey('error')) {
      throw Exception(result['error']);
    }

    return ProcessingResult(
      originalCrop: result['originalCrop'] as Uint8List,
      binaryImage: result['binaryImage'] as Uint8List,
      thumbnail: result['thumbnail'] as Uint8List,
      svgOutline: result['svgOutline'] as String?,
      boundingBox: Rect.fromLTWH(
        result['boundingBox']['x'] as double,
        result['boundingBox']['y'] as double,
        result['boundingBox']['width'] as double,
        result['boundingBox']['height'] as double,
      ),
    );
  }

  static Uint8List _applyErase(
      Uint8List image, List<Offset> erasePoints, double brushSize) {
    // 解码图像
    final decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      throw Exception('无法解码图像用于擦除');
    }

    // 创建副本进行修改
    final resultImage = img.copyResize(decodedImage,
        width: decodedImage.width, height: decodedImage.height);

    // 应用擦除点，用白色填充
    final brushRadius = brushSize / 2;
    final white = img.ColorRgba8(255, 255, 255, 255);

    for (final point in erasePoints) {
      // 将画布坐标转换为图像坐标
      final imgX = point.dx.clamp(0, decodedImage.width - 1).toInt();
      final imgY = point.dy.clamp(0, decodedImage.height - 1).toInt();

      // 绘制圆形擦除区域
      for (int y = -brushRadius.toInt(); y <= brushRadius.toInt(); y++) {
        for (int x = -brushRadius.toInt(); x <= brushRadius.toInt(); x++) {
          // 判断是否在圆内
          if (x * x + y * y <= brushRadius * brushRadius) {
            final px = imgX + x;
            final py = imgY + y;

            // 检查像素是否在图像范围内
            if (px >= 0 &&
                px < resultImage.width &&
                py >= 0 &&
                py < resultImage.height) {
              resultImage.setPixel(px, py, white);
            }
          }
        }
      }
    }

    // 编码为PNG
    return Uint8List.fromList(img.encodePng(resultImage));
  }

  static Uint8List _binarizeImage(
      Uint8List image, double threshold, bool inverted) {
    // 解码图像
    final decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      throw Exception('无法解码图像用于二值化');
    }

    // 转为灰度图
    final grayscale = img.grayscale(decodedImage);

    // 应用阈值，进行二值化
    // 将阈值限制在0-255范围内
    final thresholdValue = threshold.toInt().clamp(0, 255);

    // 创建一个二值化图像
    final binary = img.Image(
      width: grayscale.width,
      height: grayscale.height,
      numChannels: grayscale.numChannels,
    );

    // 逐像素应用阈值
    for (int y = 0; y < grayscale.height; y++) {
      for (int x = 0; x < grayscale.width; x++) {
        // 获取灰度值
        final pixel = grayscale.getPixel(x, y);
        final luminance = img.getLuminanceRgb(
          pixel.r,
          pixel.g,
          pixel.b,
        );

        // 应用阈值
        if (luminance > thresholdValue) {
          binary.setPixel(x, y, img.ColorRgb8(255, 255, 255)); // 白色
        } else {
          binary.setPixel(x, y, img.ColorRgb8(0, 0, 0)); // 黑色
        }
      }
    }

    // 如果需要反转颜色
    final resultImage = inverted ? img.invert(binary) : binary;

    // 编码为PNG
    return Uint8List.fromList(img.encodePng(resultImage));
  }

  static Uint8List _createThumbnail(Uint8List image, int maxSize) {
    // 解码图像
    final decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      throw Exception('无法解码图像用于生成缩略图');
    }

    // 计算缩放比例
    double ratio = 1.0;
    if (decodedImage.width > decodedImage.height) {
      ratio = maxSize / decodedImage.width;
    } else {
      ratio = maxSize / decodedImage.height;
    }

    final targetWidth = (decodedImage.width * ratio).toInt();
    final targetHeight = (decodedImage.height * ratio).toInt();

    // 调整图像大小
    final thumbnail = img.copyResize(
      decodedImage,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );

    // 编码为JPEG（缩略图使用JPEG以减小体积）
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
  }

  static Future<Uint8List> _cropImage(
      Uint8List sourceImage, Rect region) async {
    // 解码图像
    final image = img.decodeImage(sourceImage);
    if (image == null) {
      throw Exception('无法解码源图像');
    }

    // 进行裁剪
    final cropX = region.left.toInt().clamp(0, image.width - 1);
    final cropY = region.top.toInt().clamp(0, image.height - 1);
    final cropWidth = region.width.toInt().clamp(1, image.width - cropX);
    final cropHeight = region.height.toInt().clamp(1, image.height - cropY);

    final croppedImage = img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // 编码为PNG
    return Uint8List.fromList(img.encodePng(croppedImage));
  }

  static Uint8List _denoiseImage(Uint8List binaryImage, double noiseReduction) {
    // 解码图像
    final decodedImage = img.decodeImage(binaryImage);
    if (decodedImage == null) {
      throw Exception('无法解码图像用于降噪');
    }

    if (noiseReduction <= 0) {
      return binaryImage;
    }

    // 应用中值滤波降噪
    var kernelSize = (noiseReduction * 3).toInt().clamp(1, 9);
    if (kernelSize % 2 == 0) kernelSize++; // 确保为奇数

    // 使用现代化的图像滤波API
    final command = img.Command()
      ..image(decodedImage)
      ..gaussianBlur(radius: kernelSize ~/ 2);
    final Object denoisedObj = command.getImage();
    final img.Image imageToEncode =
        denoisedObj is img.Image ? denoisedObj : decodedImage;

    // 编码为PNG
    return Uint8List.fromList(img.encodePng(imageToEncode));
  }

  static DetectedOutline _detectOutline(Uint8List binaryImage) {
    // 解码图像
    final decodedImage = img.decodeImage(binaryImage);
    if (decodedImage == null) {
      throw Exception('无法解码图像用于轮廓检测');
    }

    // 此处应实现轮廓检测算法
    // 目前返回一个简单的边界，实际使用需要更复杂的算法

    // 默认轮廓为整个图像的边界
    final boundingRect = Rect.fromLTWH(
        0, 0, decodedImage.width.toDouble(), decodedImage.height.toDouble());

    // 简化的轮廓点，实际需要提取真实轮廓
    final contourPoints = [
      [
        const Offset(0, 0),
        Offset(decodedImage.width.toDouble(), 0),
        Offset(decodedImage.width.toDouble(), decodedImage.height.toDouble()),
        Offset(0, decodedImage.height.toDouble()),
        const Offset(0, 0),
      ]
    ];

    return DetectedOutline(
      boundingRect: boundingRect,
      contourPoints: contourPoints,
    );
  }

  static String _generateSvgOutline(DetectedOutline outline) {
    // 生成SVG路径字符串
    final width = outline.boundingRect.width;
    final height = outline.boundingRect.height;

    StringBuffer svg = StringBuffer();
    svg.write(
        '<svg viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">');

    // 为每个轮廓生成路径
    for (final contour in outline.contourPoints) {
      if (contour.isEmpty) continue;

      svg.write('<path d="');

      // 移动到第一个点
      svg.write('M${contour[0].dx},${contour[0].dy} ');

      // 连接后续点
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
    final Map<String, dynamic> params = args[1] as Map<String, dynamic>;

    try {
      // 解析参数
      AppLogger.debug('开始在Isolate中处理图像');
      final imageData = params['imageData'] as Uint8List;
      final regionData = params['region'] as Map<String, dynamic>;
      final optionsData = params['options'] as Map<String, dynamic>;
      final erasePointsData = params['erasePoints'] as List<dynamic>?;

      final region = Rect.fromLTWH(
        regionData['x'] as double,
        regionData['y'] as double,
        regionData['width'] as double,
        regionData['height'] as double,
      );

      final options = ProcessingOptions(
        inverted: optionsData['inverted'] as bool,
        threshold: optionsData['threshold'] as double,
        noiseReduction: optionsData['noiseReduction'] as double,
        showContour: optionsData['showContour'] as bool,
      );

      final erasePoints = erasePointsData
          ?.map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList();

      // 执行处理步骤

      // 1. 裁剪区域
      final croppedImage = await _cropImage(imageData, region);
      AppLogger.debug('图像裁剪完成', data: {
        'cropWidth': region.width,
        'cropHeight': region.height,
        'cropLength': croppedImage.length
      });

      // 2. 应用擦除（如果有）
      final erasedImage = erasePoints != null && erasePoints.isNotEmpty
          ? _applyErase(croppedImage, erasePoints, 10.0) // 10.0是笔刷大小
          : croppedImage;

      // 3. 二值化处理
      final binaryImage = _binarizeImage(
        erasedImage,
        options.threshold,
        options.inverted,
      );
      AppLogger.debug('图像二值化完成', data: {
        'threshold': options.threshold,
        'inverted': options.inverted,
        'binaryLength': binaryImage.length
      });

      // 4. 降噪处理
      final denoisedImage = _denoiseImage(
        binaryImage,
        options.noiseReduction,
      );

      // 5. 检测轮廓
      final outline = _detectOutline(denoisedImage);

      // 6. 生成SVG轮廓（如果需要）
      final svgOutline =
          options.showContour ? _generateSvgOutline(outline) : null;

      // 7. 生成缩略图
      final thumbnail = _createThumbnail(denoisedImage, 100);

      // 发送处理结果
      sendPort.send({
        'originalCrop': croppedImage,
        'binaryImage': denoisedImage,
        'thumbnail': thumbnail,
        'svgOutline': svgOutline,
        'boundingBox': {
          'x': outline.boundingRect.left,
          'y': outline.boundingRect.top,
          'width': outline.boundingRect.width,
          'height': outline.boundingRect.height,
        },
      });
    } catch (e) {
      AppLogger.error('Isolate中的图像处理失败', error: e);
      // 发送错误信息
      sendPort.send({'error': e.toString()});
    }
  }
}
