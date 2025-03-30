import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 图像层
/// 负责显示和变换原始图像
class ImageLayer extends StatelessWidget {
  /// 图像数据
  final ui.Image image;

  /// 变换控制器
  final TransformationController transformationController;

  /// 变换变更回调
  final VoidCallback? onTransformationChanged;

  /// 构造函数
  const ImageLayer({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onTransformationChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 获取图像原始尺寸
    final imageSize = Size(
      image.width.toDouble(),
      image.height.toDouble(),
    );

    return InteractiveViewer(
      transformationController: transformationController,
      minScale: 0.1,
      maxScale: 5.0,
      constrained: false, // 允许图像超出边界
      onInteractionUpdate: (_) {
        onTransformationChanged?.call();
      },
      onInteractionEnd: (_) {
        onTransformationChanged?.call();
      },
      child: FittedBox(
        fit: BoxFit.contain, // 使用contain保持纵横比
        child: SizedBox(
          width: imageSize.width,
          height: imageSize.height,
          child: RawImage(
            image: image,
            width: imageSize.width,
            height: imageSize.height,
            fit: BoxFit.fill, // 使用fill因为已经在SizedBox中设置了正确的尺寸
          ),
        ),
      ),
    );
  }
}
