import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'base_layer.dart';

/// 背景图层，显示原始图像
class BackgroundLayer extends BaseLayer {
  final ui.Image image;
  final bool hasChanged;

  const BackgroundLayer({
    Key? key,
    required this.image,
    this.hasChanged = false,
  }) : super(key: key);

  @override
  bool get isComplexPainting => false; // 静态内容，不复杂

  @override
  bool get willChangePainting => false; // 静态内容，不频繁变化

  @override
  CustomPainter createPainter() => _BackgroundPainter(
        // Changed from _createPainter to createPainter
        image: image,
        hasChanged: hasChanged,
      );
}

class _BackgroundPainter extends CustomPainter {
  final ui.Image image;
  final bool hasChanged;

  ui.Picture? _cachedPicture;
  Size? _cachedSize;

  _BackgroundPainter({
    required this.image,
    required this.hasChanged,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedPicture == null || _cachedSize != size || hasChanged) {
      _renderCache(size);
    }

    // 使用缓存直接绘制
    if (_cachedPicture != null) {
      canvas.drawPicture(_cachedPicture!);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) {
    return image != oldDelegate.image ||
        hasChanged != oldDelegate.hasChanged ||
        _cachedSize == null;
  }

  void _renderCache(Size size) {
    final recorder = ui.PictureRecorder();
    final cacheCanvas = Canvas(recorder);

    // 计算绘制区域，使图像居中且适应画布
    final imageRatio = image.width / image.height;
    final canvasRatio = size.width / size.height;

    double targetWidth, targetHeight;
    if (imageRatio > canvasRatio) {
      // 图像较宽，宽度适应画布
      targetWidth = size.width;
      targetHeight = size.width / imageRatio;
    } else {
      // 图像较高，高度适应画布
      targetHeight = size.height;
      targetWidth = size.height * imageRatio;
    }

    final left = (size.width - targetWidth) / 2;
    final top = (size.height - targetHeight) / 2;

    final rect = Rect.fromLTWH(left, top, targetWidth, targetHeight);

    // 绘制图像
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    cacheCanvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      rect,
      paint,
    );

    _cachedPicture = recorder.endRecording();
    _cachedSize = size;
  }
}
