import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../infrastructure/cache/interfaces/i_cache.dart';
import '../../../infrastructure/image/image_processor.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/providers/cache_providers.dart';
import '../../providers/service_providers.dart';

/// Character Image Processor Provider
final characterImageProcessorProvider =
    Provider<CharacterImageProcessor>((ref) {
  final imageProcessor = ref.watch(imageProcessorProvider);
  final binaryCache = ref.watch(tieredImageCacheProvider);
  return CharacterImageProcessor(imageProcessor, binaryCache);
});

/// 字符图像处理器
class CharacterImageProcessor {
  static const int maxPreviewSize = 800;
  final ImageProcessor _processor;
  final ICache<String, Uint8List> _binaryCache;

  CharacterImageProcessor(this._processor, this._binaryCache);

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
  Future<ResultForPreview> processForPreview(
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

      // 二值化处理
      finalImage = _binarize(finalImage, params.options);

      // 应用擦除路径
      if (params.erasePaths?.isNotEmpty == true) {
        finalImage =
            _applyErase(finalImage, params.erasePaths!, params.options);
      }

      // 应用降噪
      // if (params.options.noiseReduction > 0.3) {
      finalImage = _denoise(finalImage, params.options.noiseReduction);
      // }

      // 进行轮廓检测
      final outline = options.showContour
          ? _detectOutline(finalImage, options.inverted)
          : null;

      return ResultForPreview(
        processedImage: finalImage,
        outline: outline,
      );
    } catch (e) {
      AppLogger.error('预览处理失败', error: e);
      rethrow;
    }
  }

  /// 完整处理
  Future<ResultForSave> processForSave(
    Uint8List imageData,
    Rect region,
    ProcessingOptions options,
    List<Map<String, dynamic>>? erasePaths,
    double rotation,
  ) async {
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

      // 旋转裁剪获取原始比例图像
      final croppedImage =
          _rotateAndCropImage(sourceImage, params.region, params.rotation);

      // 保存原始裁剪图像（PNG格式）
      final originalCropBytes = Uint8List.fromList(img.encodePng(croppedImage));

      // 应用对比度和亮度调整
      img.Image finalImage =
          croppedImage.clone(); // Create a copy for binary processing
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

      // 二值化处理 - 创建带透明背景的二值图像
      img.Image binaryImage = _binarize(finalImage, params.options);

      // 应用擦除路径
      if (params.erasePaths?.isNotEmpty == true) {
        binaryImage =
            _applyErase(binaryImage, params.erasePaths!, params.options);
      }

      // 应用降噪
      // if (params.options.noiseReduction > 0.3) {
      binaryImage = _denoise(binaryImage, params.options.noiseReduction);
      // }

      // 获取处理后的二值化图像数据 (确保为透明背景)
      final binaryBytes =
          _createTransparentBinary(binaryImage, options.inverted);

      // 进行轮廓检测
      final outline = _detectOutline(binaryImage, options.inverted);

      // 生成去背景透明图像 (使用二值图像作为参考改进背景去除)
      Uint8List transparentPng = _createBetterTransparentPng(
          croppedImage, binaryImage, outline, options.inverted);

      // 生成正方形版本的图像 - 使用修正后的计算逻辑
      Uint8List squareBinary;
      String? squareSvgOutline;
      Uint8List? squareTransparentPng;

      if (outline.contourPoints.isNotEmpty) {
        // 使用改进的方法创建正方形图像 - 确保保持正方形且图像居中
        final squareResults = _createProperSquareImages(
            originalImage: croppedImage,
            binaryImage: binaryImage,
            outline: outline,
            options: params.options);

        squareBinary = squareResults.binary;
        squareSvgOutline = squareResults.svg;
        squareTransparentPng = squareResults.transparent;

        AppLogger.debug('正方形图像创建结果', data: {
          'hasBinary': squareBinary.isNotEmpty,
          'hasSvg': squareSvgOutline != null,
          'hasTransparentPng': squareTransparentPng != null,
          'binarySize': squareBinary.length,
          'transparentSize': squareTransparentPng?.length,
        });
      } else {
        // 如果没有轮廓，创建居中的方形二值化图像
        squareBinary = _createProperSquareBinaryWithoutContour(
            binaryImage, options.inverted);
        squareSvgOutline = null;
        squareTransparentPng =
            _createProperSquareTransparentWithoutContour(croppedImage);
      }

      // 生成保持宽高比的缩略图 (100x100)
      final thumbnailBytes = _generateProperThumbnail(squareBinary.isNotEmpty
          ? img.decodeImage(squareBinary)!
          : binaryImage);

      // 创建处理结果，确保每个字段都有正确格式的图像
      final result = ResultForSave(
        originalCrop: originalCropBytes, // 原始裁剪图像 (PNG)
        binaryImage: binaryBytes, // 二值化图像 (PNG)
        thumbnail: thumbnailBytes, // 缩略图 (JPG)
        svgOutline: generateSvgOutline(outline, options.inverted),
        transparentPng: transparentPng,
        squareBinary: squareBinary,
        squareSvgOutline: squareSvgOutline,
        squareTransparentPng: squareTransparentPng,
        boundingBox: outline.boundingRect,
      );

      await _binaryCache.put(cacheKey, await result.toArchiveBytes());
      return result;
    } catch (e) {
      AppLogger.error('图像处理失败', error: e);
      rethrow;
    }
  }

  /// 应用擦除 - 使用反锯齿边缘替代模糊
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

      // 确保最小有效半径，解决小笔刷被忽略的问题
      // 对于小于2.0的笔刷，使用1.0作为最小有效半径
      final effectiveRadius = math.max(brushSize / 2, 1.0); // 获取路径的颜色，默认为白色
      // 支持 int 类型和 String 类型的 brushColor
      final brushColorRaw = pathData['brushColor'];
      int? brushColorValue;

      if (brushColorRaw is int) {
        brushColorValue = brushColorRaw;
      } else if (brushColorRaw is String) {
        // 如果是字符串，尝试解析为整数
        try {
          // 移除可能的前缀和后缀，如 "Color(0xff000000)" -> "0xff000000"
          String colorStr = brushColorRaw;
          if (colorStr.startsWith('Color(') && colorStr.endsWith(')')) {
            colorStr = colorStr.substring(6, colorStr.length - 1);
          }
          brushColorValue = int.tryParse(colorStr);
        } catch (e) {
          brushColorValue = null;
        }
      }

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

        // Skip points completely outside the image
        if (x < -effectiveRadius ||
            y < -effectiveRadius ||
            x >= imageWidth + effectiveRadius ||
            y >= imageHeight + effectiveRadius) {
          continue;
        }

        // Clamp points to valid coordinates for calculation
        x = x.clamp(0, imageWidth - 1);
        y = y.clamp(0, imageHeight - 1);

        // 计算影响范围的整数边界，确保小笔刷至少影响一个完整像素
        final int minX = math.max(0, (x - effectiveRadius).floor());
        final int maxX = math.min(imageWidth - 1, (x + effectiveRadius).ceil());
        final int minY = math.max(0, (y - effectiveRadius).floor());
        final int maxY =
            math.min(imageHeight - 1, (y + effectiveRadius).ceil());

        // 使用整数坐标遍历，避免取整问题
        for (int py = minY; py <= maxY; py++) {
          for (int px = minX; px <= maxX; px++) {
            // 计算像素中心到笔刷中心的距离
            final dx = px - x;
            final dy = py - y;
            final distSquared = dx * dx + dy * dy;

            // 使用有效半径进行距离检查
            final radiusSquared = effectiveRadius * effectiveRadius;
            if (distSquared > radiusSquared) continue;

            // 计算抗锯齿效果的alpha值
            double alpha = 1.0;
            final dist = math.sqrt(distSquared);

            // 在边缘应用抗锯齿效果
            if (dist > effectiveRadius - 1.0 && dist <= effectiveRadius) {
              alpha = effectiveRadius - dist; // 线性渐变
              alpha = alpha.clamp(0.0, 1.0);
            }

            // 应用颜色混合
            if (alpha > 0) {
              final originalPixel = result.getPixel(px, py);

              // 简单的alpha混合，不使用额外的模糊
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
    return _processor.binarizeImage(
        source, options.threshold, options.inverted);
  }

  /// 改进的透明图像生成 - 使用二值图像辅助背景去除
  Uint8List _createBetterTransparentPng(img.Image source, img.Image binaryImage,
      DetectedOutline outline, bool isInverted) {
    try {
      // 创建一个新的带透明通道的图像
      final result = img.Image(
        width: source.width,
        height: source.height,
        numChannels: 4, // 4通道 - RGBA
      );

      // 先填充透明背景
      img.fill(result, color: img.ColorRgba8(0, 0, 0, 0));

      // 根据掩码和二值图像共同判断应用源图像像素
      for (int y = 0; y < source.height; y++) {
        for (int x = 0; x < source.width; x++) {
          final binaryPixel = binaryImage.getPixel(x, y);
          final luminance =
              img.getLuminanceRgb(binaryPixel.r, binaryPixel.g, binaryPixel.b);
          final isForeground = isInverted ? luminance > 128 : luminance < 128;

          if (isInverted) {
            // 反转模式下：非前景区域应显示原图，前景区域应该透明
            if (!isForeground && binaryPixel.a > 128) {
              //排除透明区域
              final sourcePixel = source.getPixel(x, y);
              result.setPixelRgba(
                  x, y, sourcePixel.r, sourcePixel.g, sourcePixel.b, 255);
            }
            // 前景区域保持透明
          } else {
            // 正常模式下：前景区域显示原图，非前景区域应该透明
            if (isForeground && binaryPixel.a > 128) {
              //排除透明区域
              final sourcePixel = source.getPixel(x, y);
              result.setPixelRgba(
                  x, y, sourcePixel.r, sourcePixel.g, sourcePixel.b, 255);
            }
            // 非前景区域保持透明
          }
        }
      }

      // 编码为PNG并返回
      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      AppLogger.error('创建透明PNG失败', error: e);
      return Uint8List(0);
    }
  }

  /// 改进版：没有轮廓时创建方形二值化图像
  Uint8List _createProperSquareBinaryWithoutContour(
      img.Image source, bool isInverted) {
    try {
      // 原图的长和宽
      final sourceWidth = source.width;
      final sourceHeight = source.height;

      // 确定正方形边长（取长和宽的较大值）
      final squareSize = math.max(sourceWidth, sourceHeight);

      // 创建一个空白的正方形图像，确保有透明通道
      final square = img.Image(
        width: squareSize,
        height: squareSize,
        numChannels: 4, // 4通道支持透明度
      );

      // 填充完全透明背景
      img.fill(square, color: img.ColorRgba8(0, 0, 0, 0));

      // 计算居中偏移量
      final offsetX = (squareSize - sourceWidth) ~/ 2;
      final offsetY = (squareSize - sourceHeight) ~/ 2;

      // 将原图复制到正方形图像中央，将背景像素设为透明
      for (int y = 0; y < sourceHeight; y++) {
        for (int x = 0; x < sourceWidth; x++) {
          final pixel = source.getPixel(x, y);
          final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);

          // 确定像素是背景还是前景
          final isBackground = isInverted
              ? luminance < 128 // 反转模式下
              : luminance > 128; // 正常模式下

          if (!isBackground) {
            // 只保留前景像素
            final color = isInverted
                ? img.ColorRgba8(255, 255, 255, 255) // 反转模式下，前景为白色
                : img.ColorRgba8(0, 0, 0, 255); // 正常模式下，前景为黑色

            // 确保坐标有效
            if (x + offsetX >= 0 &&
                x + offsetX < squareSize &&
                y + offsetY >= 0 &&
                y + offsetY < squareSize) {
              square.setPixel(x + offsetX, y + offsetY, color);
            }
          }
          // 背景像素默认为透明，不需要设置
        }
      }

      // 确保返回PNG格式
      return Uint8List.fromList(img.encodePng(square));
    } catch (e) {
      AppLogger.error('创建正方形二值化图像失败', error: e);
      // 创建空白透明PNG作为回退
      final fallbackImage =
          img.Image(width: source.width, height: source.height, numChannels: 4);
      img.fill(fallbackImage, color: img.ColorRgba8(0, 0, 0, 0));
      return Uint8List.fromList(img.encodePng(fallbackImage));
    }
  }

  /// 改进版：创建正方形格式的图像
  _SquareImageResults _createProperSquareImages({
    required img.Image originalImage,
    required img.Image binaryImage,
    required DetectedOutline outline,
    required ProcessingOptions options,
  }) {
    try {
      // 计算包含所有轮廓的最小矩形
      double minX = double.infinity, minY = double.infinity;
      double maxX = -double.infinity, maxY = -double.infinity;

      if (outline.contourPoints.isEmpty) {
        throw Exception('没有轮廓点');
      }

      // 找出所有轮廓的边界
      for (final contour in outline.contourPoints) {
        for (final point in contour) {
          if (!point.dx.isFinite || !point.dy.isFinite) continue;
          minX = math.min(minX, point.dx);
          minY = math.min(minY, point.dy);
          maxX = math.max(maxX, point.dx);
          maxY = math.max(maxY, point.dy);
        }
      }

      if (minX > maxX ||
          minY > maxY ||
          !minX.isFinite ||
          !minY.isFinite ||
          !maxX.isFinite ||
          !maxY.isFinite) {
        throw Exception('无法计算有效的轮廓边界');
      }

      // 确保坐标在图像范围内
      minX = minX.clamp(0, originalImage.width - 1);
      minY = minY.clamp(0, originalImage.height - 1);
      maxX = maxX.clamp(0, originalImage.width - 1);
      maxY = maxY.clamp(0, originalImage.height - 1);

      // 计算内容区域的实际大小
      final contentWidth = maxX - minX + 1;
      final contentHeight = maxY - minY + 1;

      // 使用较大的边作为正方形尺寸，确保完全包含内容
      final squareSize = math.max(contentWidth, contentHeight).ceil();

      // 创建正方形图像 - 确保有透明通道
      final squareOriginal =
          img.Image(width: squareSize, height: squareSize, numChannels: 4);
      final squareBinary =
          img.Image(width: squareSize, height: squareSize, numChannels: 4);

      // 初始化为透明背景
      img.fill(squareOriginal, color: img.ColorRgba8(0, 0, 0, 0));
      img.fill(squareBinary, color: img.ColorRgba8(0, 0, 0, 0));

      // 计算缩放比例，使用较小的缩放比例来避免放大失真
      final scaleX = squareSize / contentWidth;
      final scaleY = squareSize / contentHeight;
      final scale = math.min(scaleX, scaleY); // 使用较小的缩放比例保持原始大小

      // 计算缩放后的尺寸
      final scaledWidth = (contentWidth * scale).round();
      final scaledHeight = (contentHeight * scale).round();

      // 计算居中偏移量
      final centerOffsetX = (squareSize - scaledWidth) ~/ 2;
      final centerOffsetY = (squareSize - scaledHeight) ~/ 2;

      // 复制和缩放内容
      for (int y = 0; y < scaledHeight; y++) {
        for (int x = 0; x < scaledWidth; x++) {
          // 计算源坐标时立即取整
          final srcX = (minX + x / scale).round();
          final srcY = (minY + y / scale).round();

          // 计算目标坐标时确保是整数
          final destX = (x + centerOffsetX).toInt();
          final destY = (y + centerOffsetY).toInt();

          if (srcX >= 0 &&
              srcX < originalImage.width &&
              srcY >= 0 &&
              srcY < originalImage.height &&
              destX >= 0 &&
              destX < squareSize &&
              destY >= 0 &&
              destY < squareSize) {
            final srcPixel = originalImage.getPixel(srcX, srcY);
            final binaryPixel = binaryImage.getPixel(srcX, srcY);
            // 只复制非透明像素
            if (srcPixel.a > 0) {
              squareOriginal.setPixelRgba(
                  destX, destY, srcPixel.r, srcPixel.g, srcPixel.b, srcPixel.a);
            }
            // 同样，只复制非透明像素
            if (binaryPixel.a > 0) {
              squareBinary.setPixelRgba(destX, destY, binaryPixel.r,
                  binaryPixel.g, binaryPixel.b, binaryPixel.a);
            }
          }
        }
      }

      // 调整轮廓点集
      // 调整轮廓点到新的坐标系统
      final adjustedContours = outline.contourPoints.map((contour) {
        return contour.map((point) {
          final adjustedX = ((point.dx - minX) * scale + centerOffsetX)
              .clamp(0.0, squareSize.toDouble());
          final adjustedY = ((point.dy - minY) * scale + centerOffsetY)
              .clamp(0.0, squareSize.toDouble());
          return Offset(adjustedX, adjustedY);
        }).toList();
      }).toList();

      // 创建新轮廓对象
      final squareOutline = DetectedOutline(
        boundingRect:
            Rect.fromLTWH(0, 0, squareSize.toDouble(), squareSize.toDouble()),
        contourPoints: adjustedContours,
      );

      // 生成SVG轮廓
      final svgOutline = generateSvgOutline(squareOutline, options.inverted);

      // 生成透明PNG - 确保使用改进的方法处理反转模式下的透明区域
      final transparentPng = _createBetterTransparentPng(
          squareOriginal, squareBinary, squareOutline, options.inverted);

      // 确保二值图像有透明背景
      final transparentBinary =
          _createTransparentBinary(squareBinary, options.inverted);

      return _SquareImageResults(
        binary: transparentBinary,
        svg: svgOutline,
        transparent: transparentPng,
      );
    } catch (e, stack) {
      AppLogger.error('创建正方形图像失败', error: e, stackTrace: stack);

      try {
        final squareSize = math.max(originalImage.width, originalImage.height);
        final square =
            img.Image(width: squareSize, height: squareSize, numChannels: 4);
        img.fill(square, color: img.ColorRgba8(0, 0, 0, 0));

        final fallbackPng = Uint8List.fromList(img.encodePng(square));
        return _SquareImageResults(
          binary: fallbackPng,
          svg: null,
          transparent: fallbackPng,
        );
      } catch (fallbackError) {
        AppLogger.error('创建应急图像失败', error: fallbackError);
        final minimalImage = img.Image(width: 1, height: 1, numChannels: 4);
        img.fill(minimalImage, color: img.ColorRgba8(0, 0, 0, 0));
        final minimalPng = Uint8List.fromList(img.encodePng(minimalImage));

        return _SquareImageResults(
          binary: minimalPng,
          svg: null,
          transparent: minimalPng,
        );
      }
    }
  }

  /// 创建透明背景的方形图像 (当没有轮廓时)
  Uint8List _createProperSquareTransparentWithoutContour(img.Image source) {
    try {
      // 获取尺寸
      final sourceWidth = source.width;
      final sourceHeight = source.height;

      // 计算正方形尺寸
      final squareSize = math.max(sourceWidth, sourceHeight);

      // 创建带透明通道的正方形图像
      final square = img.Image(
        width: squareSize,
        height: squareSize,
        numChannels: 4, // RGBA
      );

      // 填充透明背景 - 确保整个图像初始化为透明
      img.fill(square, color: img.ColorRgba8(0, 0, 0, 0));

      // 计算偏移量以居中原图
      final offsetX = (squareSize - sourceWidth) ~/ 2;
      final offsetY = (squareSize - sourceHeight) ~/ 2;

      // 复制原图到正方形画布上，只复制非透明像素
      for (int y = 0; y < sourceHeight; y++) {
        final srcY = y;
        final dstY = y + offsetY;
        if (dstY < 0 || dstY >= squareSize) continue;

        for (int x = 0; x < sourceWidth; x++) {
          final srcX = x;
          final dstX = x + offsetX;
          if (dstX < 0 || dstX >= squareSize) continue;

          final pixel = source.getPixel(srcX, srcY);
          // 只复制非透明像素，确保扩展部分保持透明
          if (pixel.a > 0) {
            square.setPixelRgba(dstX, dstY, pixel.r, pixel.g, pixel.b, pixel.a);
          }
        }
      }

      return Uint8List.fromList(img.encodePng(square));
    } catch (e) {
      AppLogger.error('创建透明背景正方形图像失败', error: e);
      // 创建一个完全透明的图像作为后备
      final fallback = img.Image(
        width: source.width,
        height: source.height,
        numChannels: 4,
      );
      img.fill(fallback, color: img.ColorRgba8(0, 0, 0, 0));
      return Uint8List.fromList(img.encodePng(fallback));
    }
  }

  /// 生成透明背景二值化图像 - 改进版，处理不同的反转模式
  Uint8List _createTransparentBinary(img.Image binaryImage, bool isInverted) {
    try {
      // 创建一个新的带透明通道的图像
      final result = img.Image(
        width: binaryImage.width,
        height: binaryImage.height,
        numChannels: 4, // 4通道 - RGBA
      );

      // 初始化为完全透明
      img.fill(result, color: img.ColorRgba8(0, 0, 0, 0));

      // 遍历图像的每个像素
      for (int y = 0; y < binaryImage.height; y++) {
        for (int x = 0; x < binaryImage.width; x++) {
          final pixel = binaryImage.getPixel(x, y);

          // 使用Alpha通道判断是否为透明像素
          if (pixel.a < 128) {
            continue; // 保持透明
          }

          final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);

          if (isInverted) {
            // 反转模式：亮色(白色)应该是透明的，暗色(黑色)应该是黑色
            if (luminance <= 128) {
              // 暗色像素设为黑色
              result.setPixelRgba(x, y, 0, 0, 0, 255);
            }
            // 亮色像素保持透明，不需要处理
          } else {
            // 正常模式：暗色为前景(黑色)，亮色为背景(透明)
            if (luminance < 128) {
              // 暗色像素设为黑色
              result.setPixelRgba(x, y, 0, 0, 0, 255);
            }
            // 亮色像素保持透明，不需要处理
          }
        }
      }

      // 编码为PNG
      return Uint8List.fromList(img.encodePng(result));
    } catch (e) {
      AppLogger.error('创建透明背景二值化图像失败', error: e);
      // 创建一个空白透明图像作为后备
      final fallback = img.Image(
        width: binaryImage.width,
        height: binaryImage.height,
        numChannels: 4,
      );
      img.fill(fallback, color: img.ColorRgba8(0, 0, 0, 0));
      return Uint8List.fromList(img.encodePng(fallback));
    }
  }

  /// 降噪处理
  img.Image _denoise(img.Image source, double strength) {
    return _processor.denoiseImage(source, strength);
  }

  DetectedOutline _detectOutline(img.Image binaryImage, bool isInverted) {
    return _processor.detectOutline(binaryImage, isInverted);
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

  /// 生成保持比例的缩略图 (100x100像素，居中)
  Uint8List _generateProperThumbnail(img.Image source) {
    try {
      // 创建纯白或全黑背景的100x100画布
      final thumbnail = img.Image(width: 100, height: 100);
      img.fill(thumbnail, color: img.ColorRgb8(255, 255, 255));

      // 获取非透明区域的边界
      int minX = source.width, minY = source.height;
      int maxX = 0, maxY = 0;
      bool hasContent = false;

      for (int y = 0; y < source.height; y++) {
        for (int x = 0; x < source.width; x++) {
          final pixel = source.getPixel(x, y);
          if (pixel.a > 128) {
            // 非透明像素
            minX = math.min(minX, x);
            minY = math.min(minY, y);
            maxX = math.max(maxX, x);
            maxY = math.max(maxY, y);
            hasContent = true;
          }
        }
      }

      if (!hasContent) {
        // 如果没有内容，绘制边框
        img.drawRect(thumbnail,
            x1: 10,
            y1: 10,
            x2: 90,
            y2: 90,
            color: img.ColorRgb8(0, 0, 0),
            thickness: 2);
        return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 95));
      }

      // 计算内容区域的尺寸
      final contentWidth = maxX - minX + 1;
      final contentHeight = maxY - minY + 1;

      // 计算合适的缩放比例，保持原始比例
      final scaleX = 80.0 / contentWidth; // 使用80像素留出边距
      final scaleY = 80.0 / contentHeight;
      final scaleRatio = math.min(scaleX, scaleY); // 使用较小的比例避免失真

      // 计算缩放后的尺寸
      final scaledWidth = (contentWidth * scaleRatio).round();
      final scaledHeight = (contentHeight * scaleRatio).round();

      // 创建临时图像来存储内容
      final contentImage = img.Image(
        width: contentWidth,
        height: contentHeight,
        numChannels: 4,
      );

      // 复制内容区域
      for (int y = 0; y < contentHeight; y++) {
        for (int x = 0; x < contentWidth; x++) {
          final srcPixel = source.getPixel(x + minX, y + minY);
          if (srcPixel.a > 128) {
            // 检查原始像素亮度并保持颜色
            final luminance =
                img.getLuminanceRgb(srcPixel.r, srcPixel.g, srcPixel.b);
            if (luminance < 128) {
              contentImage.setPixelRgba(x, y, 0, 0, 0, 255);
            } else {
              contentImage.setPixelRgba(x, y, 255, 255, 255, 255);
            }
          }
        }
      }

      // 缩放内容
      final scaledContent = img.copyResize(
        contentImage,
        width: scaledWidth,
        height: scaledHeight,
        interpolation: img.Interpolation.cubic,
      );

      // 计算居中偏移，确保在100x100范围内居中
      final centerX = (100 - scaledWidth) ~/ 2;
      final centerY = (100 - scaledHeight) ~/ 2;

      // 将缩放后的内容复制到缩略图中心
      for (int y = 0; y < scaledHeight; y++) {
        for (int x = 0; x < scaledWidth; x++) {
          final pixel = scaledContent.getPixel(x, y);
          if (pixel.a > 128) {
            final destX = x + centerX;
            final destY = y + centerY;
            if (destX >= 0 && destX < 100 && destY >= 0 && destY < 100) {
              thumbnail.setPixelRgba(
                  destX, destY, pixel.r, pixel.g, pixel.b, 255);
            }
          }
        }
      }

      // 编码为JPEG，使用高质量设置
      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 95));
    } catch (e) {
      AppLogger.error('生成缩略图失败', error: e);
      // 返回带框的空白缩略图
      final fallback = img.Image(width: 100, height: 100);
      img.fill(fallback, color: img.ColorRgb8(255, 255, 255));
      img.drawRect(fallback,
          x1: 10,
          y1: 10,
          x2: 90,
          y2: 90,
          color: img.ColorRgb8(0, 0, 0),
          thickness: 2);
      return Uint8List.fromList(img.encodeJpg(fallback, quality: 95));
    }
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
    // This method will be moved to ImageProcessorImpl class
    // Replace with a call to the processor's method
    return _processor.rotateAndCropImage(sourceImage, region, rotation);
  }
}

/// 图像处理异常
class ImageProcessingException implements Exception {
  final String message;
  ImageProcessingException(this.message);
  @override
  String toString() => 'ImageProcessingException: $message';
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

/// 正方形图像生成结果
class _SquareImageResults {
  final Uint8List binary;
  final String? svg;
  final Uint8List? transparent;

  _SquareImageResults({
    required this.binary,
    this.svg,
    this.transparent,
  });
}
