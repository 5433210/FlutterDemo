import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/models/character/detected_outline.dart';
import 'background_layer.dart';
import 'events/event_dispatcher.dart';
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
  final EventDispatcher _eventDispatcher = EventDispatcher();
  List<PathInfo> _paths = [];
  PathInfo? _currentPath;
  Rect? _dirtyRect;
  Offset? _currentCursorPosition;
  late Rect _imageBounds;
  DetectedOutline? _outline;

  @override
  Widget build(BuildContext context) {
    print('构建擦除图层栈 - 路径数: ${_paths.length}, 当前路径: ${_currentPath != null}');

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: BackgroundLayer(
              image: widget.image,
              invertMode: widget.imageInvertMode,
            ),
          ),
          PreviewLayer(
            paths: _paths,
            currentPath: _currentPath,
            dirtyRect: _dirtyRect,
            brushSize: widget.brushSize,
            brushColor: widget.brushColor,
          ),
          RepaintBoundary(
            child: UILayer(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              onPan: widget.onPan,
              outline: widget.showOutline ? _outline : null,
              imageSize: Size(
                widget.image.width.toDouble(),
                widget.image.height.toDouble(),
              ),
              altKeyPressed: widget.altKeyPressed,
              brushSize: widget.brushSize,
              cursorPosition: _currentCursorPosition,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(EraseLayerStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      _imageBounds = Rect.fromLTWH(
          0, 0, widget.image.width.toDouble(), widget.image.height.toDouble());
    }
  }

  @override
  void initState() {
    super.initState();
    _imageBounds = Rect.fromLTWH(
        0, 0, widget.image.width.toDouble(), widget.image.height.toDouble());
  }

  void setOutline(DetectedOutline? outline) {
    setState(() {
      _outline = outline;
    });
  }

  void updatePaths(List<PathInfo> newPaths) {
    setState(() {
      print(
          'EraseLayerStack更新路径 - 当前: ${_paths.length}, 新路径: ${newPaths.length}');
      _paths = newPaths;
      _currentPath = null;
      _dirtyRect = null;
      print('更新路径列表 - 当前路径数: ${_paths.length}');
    });
  }

  void _handlePointerDown(Offset position) {
    if (widget.altKeyPressed) return;

    if (!_isPointInImageBounds(position)) {
      print('鼠标按下位置超出图像边界，忽略此操作');
      return;
    }

    _currentCursorPosition = position;

    final path = Path()..moveTo(position.dx, position.dy);
    _currentPath = PathInfo(
        path: path, brushSize: widget.brushSize, brushColor: widget.brushColor);

    _dirtyRect = Rect.fromPoints(position, position).inflate(widget.brushSize);

    widget.onEraseStart?.call(position);

    setState(() {});
  }

  void _handlePointerMove(Offset position, Offset delta) {
    _currentCursorPosition = position;

    if (widget.altKeyPressed || _currentPath == null) {
      setState(() {}); // 仅更新光标位置
      return;
    }

    if (!_isPointInImageBounds(position)) {
      print('鼠标移动位置超出图像边界，忽略此点');
      return;
    }

    _currentPath!.path.lineTo(position.dx, position.dy);

    if (_dirtyRect != null) {
      _dirtyRect = _dirtyRect!.expandToInclude(
          Rect.fromCircle(center: position, radius: widget.brushSize));
    } else {
      _dirtyRect = Rect.fromCircle(center: position, radius: widget.brushSize);
    }

    widget.onEraseUpdate?.call(position, delta);

    setState(() {});
  }

  void _handlePointerUp(Offset position) {
    _currentCursorPosition = null;

    if (widget.altKeyPressed || _currentPath == null) {
      setState(() {}); // 清除光标位置
      return;
    }

    Rect bounds = _currentPath!.path.getBounds();
    if (bounds.width > 0 || bounds.height > 0) {
      print('路径完成 - 旧路径数: ${_paths.length}, 添加新路径');
      List<PathInfo> newPaths = List.from(_paths);
      newPaths.add(_currentPath!);
      print('添加新路径 - 更新前: ${_paths.length}, 更新后: ${newPaths.length}');

      setState(() {
        _paths = newPaths;
        _currentPath = null;
        _dirtyRect = null;
      });
    } else {
      setState(() {
        _currentPath = null;
        _dirtyRect = null;
      });
    }

    widget.onEraseEnd?.call();
  }

  bool _isPointInImageBounds(Offset point) {
    return _imageBounds.contains(point);
  }
}
