import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/character/detected_outline.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../providers/character/erase_providers.dart';
import 'background_layer.dart';
import 'preview_layer.dart';
import 'ui_layer.dart';

/// 优化版擦除图层栈组件，减少不必要的重建
class OptimizedEraseLayerStack extends ConsumerStatefulWidget {
  final ui.Image image;
  final TransformationController transformationController;
  final Function(Offset)? onEraseStart;
  final Function(Offset, Offset)? onEraseUpdate;
  final Function()? onEraseEnd;
  final Function(Offset)? onPan;
  final Function(Offset)? onTap;
  final bool altKeyPressed; // Add the Alt key state parameter

  const OptimizedEraseLayerStack({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onEraseStart,
    this.onEraseUpdate,
    this.onEraseEnd,
    this.onPan,
    this.onTap,
    this.altKeyPressed = false, // Default to false
  }) : super(key: key);

  @override
  ConsumerState<OptimizedEraseLayerStack> createState() =>
      OptimizedEraseLayerStackState();
}

class OptimizedEraseLayerStackState
    extends ConsumerState<OptimizedEraseLayerStack> {
  DetectedOutline? _outline;

  @override
  Widget build(BuildContext context) {
    // 使用select只订阅所需的特定状态变化
    final showContour = ref.watch(
      eraseStateProvider.select((s) => s.showContour),
    );
    final imageInvertMode = ref.watch(
      eraseStateProvider.select((s) => s.imageInvertMode),
    ); // Not using isPanMode from provider anymore
    final brushSize = ref.watch(
      eraseStateProvider.select((s) => s.brushSize),
    );

    final renderData = ref.watch(pathRenderDataProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 使用RepaintBoundary隔离背景层重绘
        BackgroundLayer(
          image: widget.image,
          invertMode: imageInvertMode,
        ), // 使用RepaintBoundary隔离预览层重绘
        RepaintBoundary(
          child: PreviewLayer(
            paths: renderData.completedPaths,
            currentPath: renderData.currentPath,
            dirtyRect: renderData.dirtyBounds,
            imageSize: Size(
              widget.image.width.toDouble(),
              widget.image.height.toDouble(),
            ),
          ),
        ), // UI层处理交互事件
        UILayer(
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPan: widget.onPan,
          onTap: _handleTap,
          outline: showContour ? _outline : null,
          imageSize: Size(
            widget.image.width.toDouble(),
            widget.image.height.toDouble(),
          ),
          altKeyPressed: widget
              .altKeyPressed, // Use widget.altKeyPressed instead of isPanMode
          brushSize: brushSize,
          cursorPosition: _getCursorPosition(),
        ),
      ],
    );
  }

  /// 将当前状态渲染到画布上
  Future<void> renderToCanvas(Canvas canvas, Size size) async {
    // 绘制背景层
    canvas.drawImage(widget.image, Offset.zero,
        Paint()); // Apply clipping to image bounds to prevent brush strokes from extending beyond the image
    // Use full image bounds to allow erasing to the edges
    final renderData = ref.read(pathRenderDataProvider);
    final imageWidth = widget.image.width.toDouble();
    final imageHeight = widget.image.height.toDouble();
    final imageRect = Rect.fromLTWH(0, 0, imageWidth, imageHeight);

    canvas.save();
    canvas.clipRect(imageRect);

    // 绘制路径 - 使用平滑抗锯齿效果
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // 绘制所有路径
    for (final path in renderData.completedPaths) {
      paint.color = path.brushColor;
      paint.strokeWidth = path.brushSize;
      canvas.drawPath(path.path, paint);
    }

    // 绘制当前活动路径（如果有）
    if (renderData.currentPath != null) {
      paint.color = renderData.currentPath!.brushColor;
      paint.strokeWidth = renderData.currentPath!.brushSize;
      canvas.drawPath(renderData.currentPath!.path, paint);
    }

    // Restore clipping
    canvas.restore();
  }

  /// 设置轮廓数据
  void setOutline(DetectedOutline? outline) {
    AppLogger.debug('OptimizedEraseLayerStack 收到轮廓设置', data: {
      'hasOutline': outline != null,
      'pointCount': outline?.contourPoints.length ?? 0,
    });

    if (mounted) {
      setState(() {
        _outline = outline;
      });
    }
  }

  /// 获取光标位置
  Offset? _getCursorPosition() {
    final state = ref.read(eraseStateProvider);
    if (state.currentPath == null) return null;

    final bounds = state.currentPath!.path.getBounds();
    return bounds.center;
  }

  // 处理指针按下事件
  void _handlePointerDown(Offset position) {
    // Use widget.altKeyPressed instead of state provider
    if (widget.altKeyPressed) return;
    widget.onEraseStart?.call(position);
  }

  // 处理指针移动事件
  void _handlePointerMove(Offset position, Offset delta) {
    // Use widget.altKeyPressed instead of state provider
    if (widget.altKeyPressed) return;
    widget.onEraseUpdate?.call(position, delta);
  }

  // 处理指针抬起事件
  void _handlePointerUp(Offset position) {
    // Use widget.altKeyPressed instead of state provider
    if (widget.altKeyPressed) return;
    widget.onEraseEnd?.call();
  }

  // 处理点击事件
  void _handleTap(Offset position) {
    widget.onTap?.call(position);
  }
}
