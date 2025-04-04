import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/path_info.dart';
import '../../../presentation/providers/character/erase_providers.dart';
import 'background_layer.dart';
import 'preview_layer.dart';
import 'ui_layer.dart';

/// 擦除图层栈组件，管理所有图层
class EraseLayerStack extends ConsumerStatefulWidget {
  final ui.Image image;
  final TransformationController transformationController;
  final Function(Offset)? onEraseStart;
  final Function(Offset, Offset)? onEraseUpdate;
  final Function()? onEraseEnd;
  final Function(Offset)? onPan;
  final Function(Offset)? onTap;
  final bool altKeyPressed;
  final double brushSize;
  final Color brushColor;
  final bool imageInvertMode;
  final bool showOutline;

  const EraseLayerStack({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onEraseStart,
    this.onEraseUpdate,
    this.onEraseEnd,
    this.onPan,
    this.onTap,
    this.altKeyPressed = false,
    this.brushSize = 10.0,
    this.brushColor = Colors.white,
    this.imageInvertMode = false,
    this.showOutline = false,
  }) : super(key: key);

  @override
  ConsumerState<EraseLayerStack> createState() => EraseLayerStackState();
}

class EraseLayerStackState extends ConsumerState<EraseLayerStack> {
  DetectedOutline? _outline;
  List<PathInfo> _paths = [];
  PathInfo? _currentPath;
  Rect? _dirtyBounds;

  @override
  Widget build(BuildContext context) {
    final renderData = ref.watch(pathRenderDataProvider);
    final eraseState = ref.watch(eraseStateProvider);
    final showContour = eraseState.showContour;

    if (_outline != null) {
      print('EraseLayerStack 轮廓数据存在, 路径数量: ${_outline!.contourPoints.length}');
    } else {
      print('EraseLayerStack 轮廓数据不存在');
    }

    final displayPaths = renderData.completedPaths ?? _paths;
    final displayCurrentPath = renderData.currentPath;
    final displayDirtyRect = renderData.dirtyBounds;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundLayer(
            image: widget.image,
            invertMode: widget.imageInvertMode,
          ),
          PreviewLayer(
            paths: displayPaths,
            currentPath: displayCurrentPath,
            dirtyRect: displayDirtyRect,
          ),
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
            altKeyPressed: widget.altKeyPressed,
            brushSize: widget.brushSize,
            cursorPosition: _getCursorPosition(),
          ),
        ],
      ),
    );
  }

  /// 将当前状态渲染到画布上
  Future<void> renderToCanvas(Canvas canvas, Size size) async {
    // 绘制背景层
    canvas.drawImage(widget.image, Offset.zero, Paint());

    // 绘制预览层
    final renderData = ref.read(pathRenderDataProvider);
    final paths = renderData.completedPaths ?? _paths;

    // 使用与PreviewLayer相同的绘制逻辑
    final paint = Paint()..blendMode = BlendMode.srcOver;
    canvas.saveLayer(null, paint);

    try {
      // 绘制所有已完成的路径
      for (final pathInfo in paths) {
        if (pathInfo.path.getBounds().isEmpty ||
            !pathInfo.path.getBounds().isFinite) {
          continue;
        }

        paint
          ..color = pathInfo.brushColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = pathInfo.brushSize;

        canvas.drawPath(pathInfo.path, paint);
      }

      // 绘制当前路径
      if (renderData.currentPath != null) {
        paint
          ..color = renderData.currentPath!.brushColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = renderData.currentPath!.brushSize;

        canvas.drawPath(renderData.currentPath!.path, paint);
      }
    } finally {
      canvas.restore();
    }
  }

  void setOutline(DetectedOutline? outline) {
    print('EraseLayerStack 收到轮廓设置: ${outline != null}');
    if (outline != null) {
      print('轮廓包含 ${outline.contourPoints.length} 条路径');
      if (outline.contourPoints.isNotEmpty &&
          outline.contourPoints[0].isNotEmpty) {
        double minX = double.infinity, minY = double.infinity;
        double maxX = -double.infinity, maxY = -double.infinity;

        for (var point in outline.contourPoints[0]) {
          minX = math.min(minX, point.dx);
          minY = math.min(minY, point.dy);
          maxX = math.max(maxX, point.dx);
          maxY = math.max(maxY, point.dy);
        }

        print('第一条轮廓边界: ($minX,$minY) - ($maxX,$maxY)');
        print('图像大小: ${widget.image.width}x${widget.image.height}');
      }
    }

    if (mounted) {
      setState(() {
        _outline = outline;
      });
    }
  }

  void updateCurrentPath(PathInfo? path) {
    setState(() {
      _currentPath = path;
    });
  }

  void updateDirtyRect(Rect? rect) {
    setState(() {
      _dirtyBounds = rect;
    });
  }

  void updatePaths(List<PathInfo> paths) {
    setState(() {
      _paths = paths;
    });
  }

  Offset? _getCursorPosition() {
    final state = ref.read(eraseStateProvider);
    if (state.currentPath == null) return null;

    final bounds = state.currentPath!.path.getBounds();
    return bounds.center;
  }

  void _handlePointerDown(Offset position) {
    if (widget.altKeyPressed) return;
    widget.onEraseStart?.call(position);
  }

  void _handlePointerMove(Offset position, Offset delta) {
    if (widget.altKeyPressed) {
      widget.onPan?.call(delta);
      return;
    }
    widget.onEraseUpdate?.call(position, delta);
  }

  void _handlePointerUp(Offset position) {
    widget.onEraseEnd?.call();
  }

  void _handleTap(Offset position) {
    if (widget.altKeyPressed) return;

    widget.onEraseStart?.call(position);
    widget.onEraseEnd?.call();
    widget.onTap?.call(position);
  }
}
