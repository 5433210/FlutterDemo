import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'layers/background_layer.dart';
import 'layers/preview_layer.dart';

/// 擦除图层栈
/// 包含背景图层和预览图层
class EraseLayerStack extends StatelessWidget {
  /// 图像数据
  final ui.Image image;

  /// 变换控制器
  final TransformationController transformationController;

  /// 变换回调
  final VoidCallback? onTransformationChanged;

  /// 手势事件回调
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  /// 是否显示背景图像 - 添加此参数控制背景显示
  final bool showBackgroundImage;

  /// 构造函数
  const EraseLayerStack({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onTransformationChanged,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.showBackgroundImage = true, // 默认显示背景
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据设备性能进行渲染优化
    final imageRatio = image.width / image.height;

    return AspectRatio(
      aspectRatio: imageRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 简化布局计算，减少性能开销
          final Size containerSize = constraints.biggest;
          final double containerRatio =
              containerSize.width / containerSize.height;

          // 根据容器尺寸和图像比例计算实际显示尺寸
          final Size displaySize;
          if (imageRatio > containerRatio) {
            displaySize =
                Size(containerSize.width, containerSize.width / imageRatio);
          } else {
            displaySize =
                Size(containerSize.height * imageRatio, containerSize.height);
          }

          return SizedBox.fromSize(
            size: displaySize,
            child: GestureDetector(
              onPanStart: onPanStart,
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              onPanCancel: onPanCancel,
              behavior: HitTestBehavior.opaque, // 强制接收所有手势事件
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景图层 - 根据showBackgroundImage参数决定是否显示
                  if (showBackgroundImage)
                    RepaintBoundary(
                      child: BackgroundLayer(
                        image: image,
                        transformationController: transformationController,
                        onChanged: onTransformationChanged,
                      ),
                    ),

                  // 独立的透明背景层，确保手势区域覆盖整个区域
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.01, // 几乎透明但提供交互区域
                      child: Container(color: Colors.white),
                    ),
                  ),

                  // 预览图层 - 总是显示擦除效果，即使没有背景
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: PreviewLayer(
                        transformationController: transformationController,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
