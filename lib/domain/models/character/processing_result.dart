import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'detected_outline.dart';

/// 预览结果
class ResultForPreview {
  final img.Image processedImage;
  final DetectedOutline? outline;

  ResultForPreview({
    required this.processedImage,
    this.outline,
  });
}

/// 图像处理结果
class ResultForSave {
  // 原始比例图像
  final Uint8List originalCrop; // 原始裁剪图像
  final Uint8List binaryImage; // 二值化图像
  final String? svgOutline; // 轮廓SVG
  final Uint8List? transparentPng; // 去背景透明图像

  // 正方形格式图像
  final Uint8List squareBinary; // 正方形二值化图像
  final String? squareSvgOutline; // 正方形轮廓SVG
  final Uint8List? squareTransparentPng; // 正方形去背景透明图像

  // 缩略图
  final Uint8List thumbnail; // 100x100缩略图

  // 边界信息
  final Rect? boundingBox; // 字符边界框

  /// 创建处理结果
  const ResultForSave({
    required this.originalCrop,
    required this.binaryImage,
    required this.thumbnail,
    this.svgOutline,
    this.transparentPng,
    required this.squareBinary,
    this.squareSvgOutline,
    this.squareTransparentPng,
    this.boundingBox,
  });

  /// 检查处理结果是否包含有效数据
  bool get isValid =>
      originalCrop.isNotEmpty &&
      binaryImage.isNotEmpty &&
      thumbnail.isNotEmpty &&
      squareBinary.isNotEmpty;

  /// 转换为字节数组进行归档存储
  Future<Uint8List> toArchiveBytes() async {
    final archive = <String, dynamic>{
      'originalCrop': base64Encode(originalCrop),
      'binaryImage': base64Encode(binaryImage),
      'thumbnail': base64Encode(thumbnail),
      'squareBinary': base64Encode(squareBinary),
      if (svgOutline != null) 'svgOutline': svgOutline,
      if (transparentPng != null)
        'transparentPng': base64Encode(transparentPng!),
      if (squareSvgOutline != null) 'squareSvgOutline': squareSvgOutline,
      if (squareTransparentPng != null)
        'squareTransparentPng': base64Encode(squareTransparentPng!),
      if (boundingBox != null)
        'boundingBox': {
          'x': boundingBox!.left,
          'y': boundingBox!.top,
          'width': boundingBox!.width,
          'height': boundingBox!.height,
        },
    };

    return Uint8List.fromList(utf8.encode(jsonEncode(archive)));
  }

  /// 从归档字节数组中恢复
  static Future<ResultForSave> fromArchiveBytes(Uint8List bytes) async {
    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      final originalCrop = base64Decode(json['originalCrop'] as String);
      final binaryImage = base64Decode(json['binaryImage'] as String);
      final thumbnail = base64Decode(json['thumbnail'] as String);
      final squareBinary = json.containsKey('squareBinary')
          ? base64Decode(json['squareBinary'] as String)
          : thumbnail; // Fallback for older data

      Rect? boundingBox;
      if (json.containsKey('boundingBox')) {
        final boxData = json['boundingBox'] as Map<String, dynamic>;
        boundingBox = Rect.fromLTWH(
          (boxData['x'] as num).toDouble(),
          (boxData['y'] as num).toDouble(),
          (boxData['width'] as num).toDouble(),
          (boxData['height'] as num).toDouble(),
        );
      }

      return ResultForSave(
        originalCrop: originalCrop,
        binaryImage: binaryImage,
        thumbnail: thumbnail,
        svgOutline: json['svgOutline'] as String?,
        transparentPng: json.containsKey('transparentPng')
            ? base64Decode(json['transparentPng'] as String)
            : null,
        squareBinary: squareBinary,
        squareSvgOutline: json['squareSvgOutline'] as String?,
        squareTransparentPng: json.containsKey('squareTransparentPng')
            ? base64Decode(json['squareTransparentPng'] as String)
            : null,
        boundingBox: boundingBox,
      );
    } catch (e) {
      debugPrint('处理结果反序列化失败: $e');
      rethrow;
    }
  }
}
