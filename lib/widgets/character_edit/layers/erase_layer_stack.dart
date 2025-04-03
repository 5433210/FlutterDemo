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
    // 通过Provider获取路径渲染数据
    final renderData = ref.watch(pathRenderDataProvider);
    final eraseState = ref.watch(eraseStateProvider);
    final showContour = eraseState.showContour;

    // 确保_outline变量被正确更新
    if (_outline != null) {
      print('EraseLayerStack 轮廓数据存在, 路径数量: ${_outline!.contourPoints.length}');
    } else {
      print('EraseLayerStack 轮廓数据不存在');
    }

    // 确定显示的路径数据（优先使用Provider数据）
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
            outline: showContour ? _outline : null, // 确保这里传递的是正确的轮廓数据
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

  void setOutline(DetectedOutline? outline) {
    print('EraseLayerStack 收到轮廓设置: ${outline != null}');
    if (outline != null) {
      print('轮廓包含 ${outline.contourPoints.length} 条路径');
      if (outline.contourPoints.isNotEmpty &&
          outline.contourPoints[0].isNotEmpty) {
        // 检查第一个轮廓点集的边界，确保位置正确
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
    // 通过Provider获取当前路径
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
      // 在Alt键按下时，调用平移回调
      widget.onPan?.call(delta);
      return;
    }
    // 正常的擦除更新
    widget.onEraseUpdate?.call(position, delta);
  }

  void _handlePointerUp(Offset position) {
    widget.onEraseEnd?.call();
  }

  void _handleTap(Offset position) {
    if (widget.altKeyPressed) return;

    // 处理单击擦除 - 先触发start再触发end
    widget.onEraseStart?.call(position);

    // 确保两个事件之间有足够的分离
    // 这会触发completePath，确保单击擦除路径被保存
    widget.onEraseEnd?.call();

    widget.onTap?.call(position);
  }
}
