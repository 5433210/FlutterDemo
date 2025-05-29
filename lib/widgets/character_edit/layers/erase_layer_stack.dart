import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/path_info.dart';
import '../../../infrastructure/logging/logger.dart';
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
  ui.Image? _processedImage;

  // 以下变量虽然在当前实现中不直接用于渲染，但被updateXXX方法使用
  // 保留它们是为了保持API兼容性，避免破坏现有代码
  // ignore: unused_field
  PathInfo? _currentPath;
  // ignore: unused_field
  Rect? _dirtyBounds;
  // ignore: unused_field
  List<PathInfo> _paths = [];

  @override
  Widget build(BuildContext context) {
    final renderData = ref.watch(pathRenderDataProvider);
    final eraseState = ref.watch(eraseStateProvider);
    final showContour = eraseState.showContour;
    // Check if we're in pan mode from eraseStateProvider
    final isPanMode = eraseState.isPanMode;
    _processedImage = widget.image;

    // 不再需要监听forceRefreshProvider

    // 使用AppLogger替代print
    if (_outline != null) {
      AppLogger.debug('EraseLayerStack 轮廓数据状态', data: {
        'exists': true,
        'pathCount': _outline!.contourPoints.length,
      });
    } else {
      AppLogger.debug('EraseLayerStack 轮廓数据不存在');
    }

    // 修复空值检查
    final displayPaths = renderData.completedPaths;
    final displayCurrentPath = renderData.currentPath;
    final displayDirtyRect = renderData.dirtyBounds;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundLayer(
            image: _processedImage!,
            invertMode: widget.imageInvertMode,
          ),
          PreviewLayer(
            paths: displayPaths,
            currentPath: displayCurrentPath,
            dirtyRect: displayDirtyRect,
            imageSize: Size(
              widget.image.width.toDouble(),
              widget.image.height.toDouble(),
            ),
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

  /// 强制刷新整个图层栈
  void forceRefresh() {
    if (mounted) {
      setState(() {
        // 强制重建整个图层栈
      });
    }
  }

  /// 将当前状态渲染到画布上
  Future<void> renderToCanvas(Canvas canvas, Size size) async {
    // 绘制背景层
    canvas.drawImage(_processedImage!, Offset.zero, Paint());

    // Calculate maximum brush size for enhanced clipping
    final pathData = ref.read(pathRenderDataProvider);
    final allPaths = pathData.completedPaths;
    double maxBrushSize = 1.0;

    // Find maximum brush size from all paths
    for (final pathInfo in allPaths) {
      if (pathInfo.brushSize > maxBrushSize) {
        maxBrushSize = pathInfo.brushSize;
      }
    }

    // Check current path for maximum brush size
    if (pathData.currentPath != null &&
        pathData.currentPath!.brushSize > maxBrushSize) {
      maxBrushSize = pathData.currentPath!.brushSize;
    } // Apply clipping to image bounds to prevent brush strokes from extending beyond the image
    // Use full image bounds to allow erasing to the edges
    final imageRect = Rect.fromLTWH(
        0, 0, widget.image.width.toDouble(), widget.image.height.toDouble());

    canvas.save();
    canvas.clipRect(imageRect);

    // 绘制预览层 - Use anti-aliasing instead of blur
    final renderData = ref.read(pathRenderDataProvider);
    final paths = renderData.completedPaths;

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
      canvas.restore(); // Restore the blend mode layer
    }

    // Restore clipping
    canvas.restore();
  }

  void setOutline(DetectedOutline? outline) {
    AppLogger.debug('EraseLayerStack 收到轮廓设置', data: {
      'hasOutline': outline != null,
    });

    if (outline != null) {
      AppLogger.debug('轮廓数据', data: {
        'pathCount': outline.contourPoints.length,
      });

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
        AppLogger.debug('轮廓数据包含无效点，进行修复');
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

        AppLogger.debug('轮廓修复结果', data: {
          'fixedPathCount': outline.contourPoints.length,
        });
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

        AppLogger.debug('轮廓边界信息', data: {
          'bounds': '($minX,$minY) - ($maxX,$maxY)',
          'imageSize': '${widget.image.width}x${widget.image.height}',
        });
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

  void updateImage(ui.Image processedImage) {
    if (mounted) {
      setState(() {
        _processedImage = processedImage;
      });
    }
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

    // 直接调用onTap回调，让父组件处理点击擦除
    // 不再调用onEraseStart和onEraseEnd，避免重复创建路径
    widget.onTap?.call(position);
  }
}
