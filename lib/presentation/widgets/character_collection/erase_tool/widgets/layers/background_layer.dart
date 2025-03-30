import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 背景图层
/// 显示原始图像
class BackgroundLayer extends StatelessWidget {
  /// 图像数据
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
    // 使用ValueListenableBuilder优化重建范围
    return ValueListenableBuilder<Matrix4>(
      valueListenable: transformationController,
      builder: (context, matrix, _) {
        return InteractiveViewer(
          transformationController: transformationController,
          onInteractionUpdate: (_) => onChanged?.call(),
          onInteractionEnd: (_) => onChanged?.call(),
          child: CustomPaint(
            painter: _BackgroundPainter(
              image: image,
            ),
            size: Size(
              image.width.toDouble(),
              image.height.toDouble(),
            ),
          ),
        );
      },
    );
  }
}

/// 背景图层绘制器
class _BackgroundPainter extends CustomPainter {
  /// 图像数据
  final ui.Image image;

  /// 缓存的画笔
  late final Paint _paint;

  /// 构造函数
  _BackgroundPainter({
    required this.image,
  }) {
    // 初始化画笔，减少重建开销
    _paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    // 绘制图像
    canvas.drawImage(image, Offset.zero, _paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) {
    return image != oldDelegate.image;
  }
}
