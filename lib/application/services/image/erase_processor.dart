import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// 擦除处理器
/// 负责处理图像擦除的底层逻辑
class EraseProcessor {
  /// 从PNG图像字节数据中创建图像
  Future<ui.Image> createImageFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  /// 对图像应用擦除操作
  /// [sourceImage] 源图像
  /// [points] 擦除点
  /// [brushSize] 笔刷大小
  /// 返回擦除后的图像
  Future<EraseResult> eraseImage({
    required ui.Image sourceImage,
    required List<Offset> points,
    required double brushSize,
  }) async {
    if (points.isEmpty) {
      return EraseResult(
        processedImage: sourceImage,
        success: true,
      );
    }

    try {
      // 创建图片记录器
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 绘制原始图像
      canvas.drawImage(sourceImage, Offset.zero, Paint());

      // 设置擦除画笔
      final paint = Paint()
        ..color = const Color(0x00000000) // 透明色
        ..strokeWidth = brushSize
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.clear; // 使用清除混合模式实现擦除效果

      // 创建路径并绘制
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);

      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(path, paint);

      // 完成绘制并获取图像
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        sourceImage.width,
        sourceImage.height,
      );

      return EraseResult(
        processedImage: image,
        success: true,
      );
    } catch (e) {
      return EraseResult(
        processedImage: sourceImage,
        success: false,
        errorMessage: 'Error processing erase operation: $e',
      );
    }
  }

  /// 将图像转换为字节数据
  Future<Uint8List> imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  /// 异步处理擦除操作
  /// 这个方法可以在隔离区(Isolate)中运行以避免阻塞UI线程
  static Future<Uint8List> processEraseInIsolate(
      Map<String, dynamic> params) async {
    final processor = EraseProcessor();

    // 从参数中获取图像和擦除信息
    final sourceImageBytes = params['sourceImageBytes'] as Uint8List;
    final points = (params['points'] as List)
        .map((e) => Offset((e as Map)['dx'] as double, e['dy'] as double))
        .toList();
    final brushSize = params['brushSize'] as double;

    // 创建图像
    final sourceImage = await processor.createImageFromBytes(sourceImageBytes);

    // 处理擦除
    final result = await processor.eraseImage(
      sourceImage: sourceImage,
      points: points,
      brushSize: brushSize,
    );

    // 转换回字节数据
    return await processor.imageToBytes(result.processedImage);
  }
}

/// 擦除处理结果
class EraseResult {
  /// 处理后的图像
  final ui.Image processedImage;

  /// 处理是否成功
  final bool success;

  /// 错误信息，如果处理失败
  final String? errorMessage;

  EraseResult({
    required this.processedImage,
    this.success = true,
    this.errorMessage,
  });
}
