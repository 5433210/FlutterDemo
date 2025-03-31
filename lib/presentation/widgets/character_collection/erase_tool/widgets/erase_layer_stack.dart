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

  /// 笔刷大小
  final double brushSize;

  /// 变换回调
  final VoidCallback? onTransformationChanged;

  /// 手势事件回调
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  /// 是否显示背景图像
  final bool showBackgroundImage;

  /// 构造函数
  const EraseLayerStack({
    Key? key,
    required this.image,
    required this.transformationController,
    this.brushSize = 20.0,
    this.onTransformationChanged,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.showBackgroundImage = true,
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
                      onPanStart!(DragStartDetails(
                        globalPosition: event.position,
                        localPosition: event.localPosition,
                      ));
                    }
                  },
                  onPointerMove: (event) {
                    if (onPanUpdate != null) {
                      onPanUpdate!(DragUpdateDetails(
                        globalPosition: event.position,
                        localPosition: event.localPosition,
                        delta: event.delta,
                      ));
                    }
                  },
                  onPointerUp: (event) {
                    if (onPanEnd != null) {
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
                      // 背景图层
                      if (showBackgroundImage)
                        RepaintBoundary(
                          child: BackgroundLayer(
                            image: image,
                            transformationController: transformationController,
                          ),
                        ),

                      // 预览图层
                      RepaintBoundary(
                        child: PreviewLayer(
                          transformationController: transformationController,
                          brushSize: brushSize,
                          scale: transformationController.value
                              .getMaxScaleOnAxis(),
                        ),
                      ),

                      // 调试网格
                      if (showDebugGrid) _buildDebugGrid(),
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

  /// 构建调试网格
  Widget _buildDebugGrid() {
    return IgnorePointer(
      child: CustomPaint(
        painter: _DebugGridPainter(),
      ),
    );
  }

  /// 计算最佳显示尺寸
  Size _calculateDisplaySize({
    required Size containerSize,
    required double imageRatio,
    required double containerRatio,
  }) {
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

    // 绘制尺寸标签
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
