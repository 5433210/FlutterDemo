import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 背景图层
/// 负责显示原始图像内容
class BackgroundLayer extends StatelessWidget {
  /// 原始图像
  final ui.Image image;

  /// 变换控制器
  final TransformationController transformationController;

  /// 变换回调
  final VoidCallback? onChanged;

  /// 构造函数
  const BackgroundLayer({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BackgroundPainter(
          image: image,
          transform: transformationController.value,
        ),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

/// 背景绘制器
class _BackgroundPainter extends CustomPainter {
  final ui.Image image;
  final Matrix4 transform;

  const _BackgroundPainter({
    required this.image,
    required this.transform,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算缩放比例以适应画布
    final imageAspectRatio = image.width / image.height;
    final canvasAspectRatio = size.width / size.height;

    double scale;
    double dx = 0;
    double dy = 0;

    if (imageAspectRatio > canvasAspectRatio) {
      // 图像更宽，以宽度为准
      scale = size.width / image.width;
      dy = (size.height - image.height * scale) / 2;
    } else {
      // 图像更高，以高度为准
      scale = size.height / image.height;
      dx = (size.width - image.width * scale) / 2;
    }

    // 应用变换
    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    // 绘制图像
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImage(image, Offset.zero, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return image != oldDelegate.image || transform != oldDelegate.transform;
  }
}
