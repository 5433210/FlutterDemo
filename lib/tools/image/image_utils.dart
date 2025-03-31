import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 图像处理工具类
class ImageUtils {
  /// 将字节数据转换为UI Image
  static Future<ui.Image> bytesToImage(Uint8List bytes) async {
    final Completer<ui.Image> completer = Completer();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }

  /// 裁剪图像区域
  static Future<ui.Image> cropImage(ui.Image source, Rect rect) async {
    // 确保区域有效
    final safeRect = Rect.fromLTRB(
        math.max(0, rect.left),
        math.max(0, rect.top),
        math.min(source.width.toDouble(), rect.right),
        math.min(source.height.toDouble(), rect.bottom));

    // 使用Canvas和PictureRecorder进行裁剪
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(source, safeRect,
        Rect.fromLTWH(0, 0, safeRect.width, safeRect.height), Paint());

    final picture = recorder.endRecording();
    return await picture.toImage(
        safeRect.width.round(), safeRect.height.round());
  }

  /// 将UI Image转换为字节数据
  static Future<Uint8List?> imageToBytes(ui.Image image,
      {ui.ImageByteFormat format = ui.ImageByteFormat.png}) async {
    final ByteData? byteData = await image.toByteData(format: format);
    if (byteData == null) return null;
    return byteData.buffer.asUint8List();
  }

  /// 在异步操作中处理图像，避免阻塞UI线程
  static Future<ui.Image> processImageAsync(
      ui.Image image, Future<ui.Image> Function(ui.Image) processor) async {
    // 将图像转换为字节
    final bytes = await imageToBytes(image);
    if (bytes == null) throw Exception('Failed to convert image to bytes');

    // 在isolate中处理
    final processedImage = await compute((Uint8List imageBytes) async {
      // 在isolate中转换回图像
      final img = await bytesToImage(imageBytes);
      // 处理图像
      return await processor(img);
    }, bytes);

    return processedImage;
  }
}
