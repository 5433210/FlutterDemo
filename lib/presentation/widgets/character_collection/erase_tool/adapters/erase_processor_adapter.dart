import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/erase_operation.dart';
import '../utils/erase_background_detector.dart';

/// 擦除处理适配器
/// 处理擦除操作并生成擦除后的图像
class EraseProcessorAdapter {
  /// 背景颜色（默认白色）
  Color _backgroundColor = Colors.white;

  /// 是否已初始化
  bool _isInitialized = false;

  /// 处理单个擦除操作
  Future<ui.Image> process(ui.Image image, EraseOperation operation) async {
    // 如果尚未初始化，先检测背景色
    if (!_isInitialized) {
      await _initialize(image);
    }

    // 创建画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 绘制原始图像
    canvas.drawImage(image, Offset.zero, Paint());

    // 设置擦除画笔
    final erasePaint = Paint()
      ..color = _backgroundColor // 使用检测到的背景色
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = operation.brushSize
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.src; // 使用源模式确保完全擦除

    // 创建路径
    if (operation.points.length >= 2) {
      final path = Path();
      path.moveTo(operation.points.first.dx, operation.points.first.dy);

      for (int i = 1; i < operation.points.length; i++) {
        path.lineTo(operation.points[i].dx, operation.points[i].dy);
      }

      // 绘制擦除路径
      canvas.drawPath(path, erasePaint);
    }

    // 单独处理孤立点（只有一个点的情况）
    if (operation.points.length == 1) {
      canvas.drawCircle(
          operation.points.first,
          operation.brushSize / 2,
          Paint()
            ..color = _backgroundColor
            ..style = PaintingStyle.fill);
    }

    // 生成图片
    final picture = recorder.endRecording();
    return picture.toImage(image.width, image.height);
  }

  /// 批量处理擦除操作
  Future<ui.Image> processBatch(
      ui.Image originalImage, List<EraseOperation> operations) async {
    // 如果尚未初始化，先检测背景色
    if (!_isInitialized) {
      await _initialize(originalImage);
    }

    // 没有操作，直接返回原图
    if (operations.isEmpty) return originalImage;

    // 创建画布
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 绘制原始图像
    canvas.drawImage(originalImage, Offset.zero, Paint());

    // 处理每个擦除操作
    for (final operation in operations) {
      // 设置擦除画笔
      final erasePaint = Paint()
        ..color = _backgroundColor // 使用检测到的背景色
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = operation.brushSize
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.src; // 使用源模式确保完全擦除

      // 创建并绘制路径
      if (operation.points.length >= 2) {
        final path = Path();
        path.moveTo(operation.points.first.dx, operation.points.first.dy);

        for (int i = 1; i < operation.points.length; i++) {
          path.lineTo(operation.points[i].dx, operation.points[i].dy);
        }

        canvas.drawPath(path, erasePaint);
      }

      // 处理孤立点
      if (operation.points.length == 1) {
        canvas.drawCircle(
            operation.points.first,
            operation.brushSize / 2,
            Paint()
              ..color = _backgroundColor
              ..style = PaintingStyle.fill);
      }
    }

    // 生成图片
    final picture = recorder.endRecording();
    return picture.toImage(originalImage.width, originalImage.height);
  }

  /// 初始化处理器，检测背景色
  Future<void> _initialize(ui.Image image) async {
    try {
      // 检测背景色
      _backgroundColor =
          await EraseBackgroundDetector.detectBackgroundColor(image);
      print('Detected background color: $_backgroundColor');

      // 检查是否为黑白图像
      final isBlackAndWhite =
          await EraseBackgroundDetector.isBlackAndWhiteImage(image);
      print('Is black and white image: $isBlackAndWhite');

      _isInitialized = true;
    } catch (e) {
      print('Error initializing erase processor: $e');
      // 出错时使用默认白色背景
      _backgroundColor = Colors.white;
      _isInitialized = true;
    }
  }
}
