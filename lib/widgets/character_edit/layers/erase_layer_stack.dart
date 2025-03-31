import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

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

  const EraseLayerStack({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onEraseStart,
    this.onEraseUpdate,
    this.onEraseEnd,
  }) : super(key: key);

  @override
  State<EraseLayerStack> createState() => EraseLayerStackState();
}

class EraseLayerStackState extends State<EraseLayerStack> {
  final EventDispatcher _eventDispatcher = EventDispatcher();
  List<Path> _paths = [];
  Path? _currentPath;
  Rect? _dirtyRect;

  // 添加轮廓支持
  DetectedOutline? _outline;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图层
          RepaintBoundary(
            child: BackgroundLayer(image: widget.image),
          ),

          // 预览图层
          RepaintBoundary(
            child: PreviewLayer(
              paths: _paths,
              currentPath: _currentPath,
              dirtyRect: _dirtyRect,
            ),
          ),

          // UI图层 - 添加轮廓支持
          RepaintBoundary(
            child: UILayer(
              onPointerDown: _handlePointerDown,
              onPointerMove: _handlePointerMove,
              onPointerUp: _handlePointerUp,
              outline: _outline,
              imageSize: Size(
                widget.image.width.toDouble(),
                widget.image.height.toDouble(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 清除所有路径
  void clearPaths() {
    setState(() {
      _paths = [];
      _currentPath = null;
      _dirtyRect = null;
    });
  }

  // 添加设置轮廓方法
  void setOutline(DetectedOutline? outline) {
    setState(() {
      _outline = outline;
    });
  }

  void _handlePointerDown(Offset position) {
    final imagePosition = _transformToImageCoordinates(position);

    // 创建新路径
    _currentPath = Path()..moveTo(imagePosition.dx, imagePosition.dy);
    _dirtyRect = Rect.fromPoints(imagePosition, imagePosition).inflate(10);

    widget.onEraseStart?.call(imagePosition);
    setState(() {});
  }

  void _handlePointerMove(Offset position, Offset delta) {
    if (_currentPath == null) return;

    final imagePosition = _transformToImageCoordinates(position);

    // 更新路径
    _currentPath!.lineTo(imagePosition.dx, imagePosition.dy);

    // 更新脏区域
    if (_dirtyRect != null) {
      _dirtyRect = _dirtyRect!
          .expandToInclude(Rect.fromCircle(center: imagePosition, radius: 10));
    } else {
      _dirtyRect = Rect.fromCircle(center: imagePosition, radius: 10);
    }

    widget.onEraseUpdate?.call(imagePosition, delta);
    setState(() {});
  }

  void _handlePointerUp(Offset position) {
    if (_currentPath != null) {
      // 完成当前路径
      _paths = List.from(_paths)..add(_currentPath!);
      _currentPath = null;
      _dirtyRect = null;

      widget.onEraseEnd?.call();
      setState(() {});
    }
  }

  // 转换视图坐标到图像坐标
  Offset _transformToImageCoordinates(Offset viewportOffset) {
    final matrix = widget.transformationController.value.clone();
    final vector = Matrix4.inverted(matrix)
        .transform3(Vector3(viewportOffset.dx, viewportOffset.dy, 0));
    return Offset(vector.x, vector.y);
  }
}
