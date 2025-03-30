import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
          final Size containerSize = constraints.biggest;
          final double containerRatio =
              containerSize.width / containerSize.height;

          // 根据容器尺寸和图像比例计算图像实际显示尺寸
          final Size displaySize = _calculateDisplaySize(
            containerSize: containerSize,
            imageRatio: imageRatio,
            containerRatio: containerRatio,
          );

          // 添加坐标系调试网格用于校准
          bool showDebugGrid = kDebugMode && false; // 开发时可设为true以显示网格

          return Center(
            child: SizedBox.fromSize(
              size: displaySize,
              child: MouseRegion(
                cursor: SystemMouseCursors.precise, // 使用精确光标
                onHover: (event) {
                  if (kDebugMode && showDebugGrid) {
                    print('🖱️ 鼠标悬停: ${event.localPosition}');
                  }
                },
                child: Listener(
                  // 使用Listener代替GestureDetector以获取原始指针事件
                  onPointerDown: (event) {
                    if (onPanStart != null) {
                      final localPosition = event.localPosition;
                      if (kDebugMode) {
                        print('👆 指针按下: $localPosition');
                      }
                      onPanStart!(DragStartDetails(
                        globalPosition: event.position,
                        localPosition: localPosition,
                      ));
                    }
                  },
                  onPointerMove: (event) {
                    if (onPanUpdate != null) {
                      final localPosition = event.localPosition;
                      onPanUpdate!(DragUpdateDetails(
                        globalPosition: event.position,
                        localPosition: localPosition,
                        delta: event.delta,
                      ));
                    }
                  },
                  onPointerUp: (event) {
                    if (onPanEnd != null) {
                      if (kDebugMode) {
                        print('👆 指针抬起: ${event.localPosition}');
                      }
                      onPanEnd!(DragEndDetails());
                    }
                  },
                  onPointerCancel: (event) {
                    if (onPanCancel != null) {
                      onPanCancel!();
                    }
                  },
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

                      // 预览图层 - 总是显示擦除效果
                      RepaintBoundary(
                        child: PreviewLayer(
                          transformationController: transformationController,
                        ),
                      ),

                      // 交互辅助层 - 提供半透明覆盖使得手势捕获更容易
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                      ),

                      // 调试网格用于校准
                      if (showDebugGrid) _buildDebugLayer(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 构建调试辅助层
  Widget _buildDebugLayer() {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _DebugGridPainter(),
          isComplex: false,
        ),
      ),
    );
  }

  /// 计算最佳显示尺寸
  Size _calculateDisplaySize({
    required Size containerSize,
    required double imageRatio,
    required double containerRatio,
  }) {
    // 基于宽高比和容器尺寸计算显示大小
    if (imageRatio > containerRatio) {
      // 图像更宽，使用容器宽度
      return Size(containerSize.width, containerSize.width / imageRatio);
    } else {
      // 图像更高，使用容器高度
      return Size(containerSize.height * imageRatio, containerSize.height);
    }
  }
}

/// 调试网格绘制器
class _DebugGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 绘制参考网格
    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // 水平线
    for (double y = 0; y <= size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 垂直线
    for (double x = 0; x <= size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // 绘制中心十字线
    final centerPaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), centerPaint);

    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), centerPaint);

    // 绘制坐标标签
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 显示尺寸
    textPainter.text = TextSpan(
      text:
          '${size.width.toStringAsFixed(0)} x ${size.height.toStringAsFixed(0)}',
      style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 10),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(5, 5));
  }

  @override
  bool shouldRepaint(_DebugGridPainter oldDelegate) => false;
}
