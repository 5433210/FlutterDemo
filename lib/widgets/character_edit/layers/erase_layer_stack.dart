import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../utils/path/path_utils.dart';
import 'background_layer.dart';
import 'preview_layer.dart';
import 'ui_layer.dart';

/// 擦除图层栈组件，管理所有图层
class EraseLayerStack extends StatefulWidget {
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
  State<EraseLayerStack> createState() => EraseLayerStackState();
}

class EraseLayerStackState extends State<EraseLayerStack> {
  final List<PathInfo> _paths = [];
  Path _currentPath = Path();
  Rect? _dirtyRect;
  Offset? _lastPoint;
  Offset? _cursorPosition;
  bool _isDragging = false;
  DetectedOutline? _outline;

  late Rect _imageBounds;

  @override
  Widget build(BuildContext context) {
    PathInfo? currentPathInfo;
    if (!PathUtils.isPathEmpty(_currentPath)) {
      currentPathInfo = PathInfo(
        path: Path()..addPath(_currentPath, Offset.zero),
        brushSize: widget.brushSize,
        brushColor: widget.brushColor,
      );
    }

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackgroundLayer(
            image: widget.image,
            invertMode: widget.imageInvertMode,
          ),
          PreviewLayer(
            paths: _paths,
            currentPath: currentPathInfo,
            dirtyRect: _dirtyRect,
            brushSize: widget.brushSize,
            brushColor: widget.brushColor,
          ),
          UILayer(
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerUp,
            onPan: widget.onPan,
            onTap: _handleTap,
            outline: widget.showOutline ? _outline : null,
            imageSize: Size(
              widget.image.width.toDouble(),
              widget.image.height.toDouble(),
            ),
            altKeyPressed: widget.altKeyPressed,
            brushSize: widget.brushSize,
            cursorPosition: _cursorPosition,
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _imageBounds = Rect.fromLTWH(
      0,
      0,
      widget.image.width.toDouble(),
      widget.image.height.toDouble(),
    );
  }

  void setOutline(DetectedOutline? outline) {
    setState(() {
      _outline = outline;
    });
  }

  void updatePaths(List<PathInfo> newPaths) {
    print('更新路径列表 - 数量: ${newPaths.length}');
    setState(() {
      _paths.clear();
      _paths.addAll(newPaths);
      _currentPath = Path();
      _dirtyRect = null;
    });
  }

  void _handlePointerDown(Offset position) {
    if (widget.altKeyPressed) return;

    setState(() {
      print('开始擦除 - position: $position');
      _isDragging = true;
      _lastPoint = position;
      _cursorPosition = position;

      _currentPath = PathUtils.createSolidCircle(
        position,
        widget.brushSize / 2,
      );

      _dirtyRect = Rect.fromCircle(
        center: position,
        radius: widget.brushSize + 5,
      );
    });

    widget.onEraseStart?.call(position);
  }

  void _handlePointerMove(Offset position, Offset delta) {
    _cursorPosition = position;

    if (widget.altKeyPressed) {
      widget.onPan?.call(delta);
      setState(() {});
      return;
    }

    if (!_isDragging || _lastPoint == null) return;

    final gapPath = PathUtils.createSolidGap(
      _lastPoint!,
      position,
      widget.brushSize,
    );

    setState(() {
      _currentPath = Path.combine(
        PathOperation.union,
        _currentPath,
        gapPath,
      );

      _dirtyRect = _dirtyRect?.expandToInclude(
        Rect.fromCircle(center: position, radius: widget.brushSize + 5),
      );

      _lastPoint = position;
    });

    widget.onEraseUpdate?.call(position, delta);
  }

  void _handlePointerUp(Offset position) {
    if (!_isDragging) return;

    _isDragging = false;
    _cursorPosition = null;

    if (_lastPoint != null) {
      _handlePointerMove(position, Offset.zero);
    }

    setState(() {
      if (!PathUtils.isPathEmpty(_currentPath)) {
        print('完成擦除路径');
        _paths.add(PathInfo(
          path: _currentPath,
          brushSize: widget.brushSize,
          brushColor: widget.brushColor,
        ));
      }
      _currentPath = Path();
      _dirtyRect = null;
    });

    widget.onEraseEnd?.call();
  }

  void _handleTap(Offset position) {
    if (widget.altKeyPressed) return;

    setState(() {
      print('处理单击 - position: $position');
      final circlePath = PathUtils.createSolidCircle(
        position,
        widget.brushSize / 2,
      );

      _paths.add(PathInfo(
        path: circlePath,
        brushSize: widget.brushSize,
        brushColor: widget.brushColor,
      ));
    });

    widget.onEraseStart?.call(position);
    widget.onEraseEnd?.call();
    widget.onTap?.call(position);
  }
}
