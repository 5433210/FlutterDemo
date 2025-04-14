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
    // Check if we're in pan mode from eraseStateProvider
    final isPanMode = eraseState.isPanMode;

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
            // Pass both altKeyPressed and isPanMode - either one enables pan mode
            altKeyPressed: widget.altKeyPressed || isPanMode,
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

    // 绘制预览层 - Use anti-aliasing instead of blur
    final renderData = ref.read(pathRenderDataProvider);
    final paths = renderData.completedPaths ?? _paths;

    // 使用与PreviewLayer相同的绘制逻辑但更高效
    final paint = Paint()..blendMode = BlendMode.srcOver;
    canvas.saveLayer(null, paint);

    try {
      // 绘制所有已完成的路径
      for (final pathInfo in paths) {
        if (pathInfo.path.getBounds().isEmpty ||
            !pathInfo.path.getBounds().isFinite) {
          continue;
        }

        // Use anti-aliased clean stroke
        final strokePaint = Paint()
          ..color = pathInfo.brushColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = pathInfo.brushSize
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true; // Enable anti-aliasing
        // Remove maskFilter blur

        canvas.drawPath(pathInfo.path, strokePaint);
      }

      // 绘制当前路径
      if (renderData.currentPath != null) {
        final strokePaint = Paint()
          ..color = renderData.currentPath!.brushColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = renderData.currentPath!.brushSize
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true; // Enable anti-aliasing
        // Remove maskFilter blur

        canvas.drawPath(renderData.currentPath!.path, strokePaint);
      }
    } finally {
      canvas.restore();
    }
  }

  void setOutline(DetectedOutline? outline) {
    print('EraseLayerStack 收到轮廓设置: ${outline != null}');
    if (outline != null) {
      print('轮廓包含 ${outline.contourPoints.length} 条路径');

      // Validate the outline data
      bool valid = true;
      for (var contour in outline.contourPoints) {
        if (contour.isEmpty) {
          valid = false;
          break;
        }

        // Check for invalid points
        for (var point in contour) {
          if (!point.dx.isFinite || !point.dy.isFinite) {
            valid = false;
            break;
          }
        }

        if (!valid) break;
      }

      if (!valid) {
        print('轮廓数据包含无效点，进行修复');
        // Try to fix the outline by removing invalid contours
        final fixedContours = outline.contourPoints.where((contour) {
          if (contour.isEmpty) return false;

          bool allValid = true;
          for (var point in contour) {
            if (!point.dx.isFinite || !point.dy.isFinite) {
              allValid = false;
              break;
            }
          }

          return allValid;
        }).toList();

        outline = DetectedOutline(
          boundingRect: outline.boundingRect,
          contourPoints: fixedContours,
        );

        print('修复后轮廓包含 ${outline.contourPoints.length} 条路径');
      }

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
    final isPanMode = ref.read(eraseStateProvider).isPanMode;
    if (widget.altKeyPressed || isPanMode) {
      // Store the initial position for panning
      return;
    }
    widget.onEraseStart?.call(position);
  }

  void _handlePointerMove(Offset position, Offset delta) {
    final isPanMode = ref.read(eraseStateProvider).isPanMode;
    if (widget.altKeyPressed || isPanMode) {
      widget.onPan?.call(delta);
      return;
    }
    widget.onEraseUpdate?.call(position, delta);
  }

  void _handlePointerUp(Offset position) {
    if (widget.altKeyPressed || ref.read(eraseStateProvider).isPanMode) {
      return;
    }
    widget.onEraseEnd?.call();
  }

  void _handleTap(Offset position) {
    final isPanMode = ref.read(eraseStateProvider).isPanMode;
    if (widget.altKeyPressed || isPanMode) return;

    widget.onEraseStart?.call(position);
    widget.onEraseEnd?.call();
    widget.onTap?.call(position);
  }
}
