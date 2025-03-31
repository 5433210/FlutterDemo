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
  // 添加Alt键状态参数
  final bool altKeyPressed;

  const EraseLayerStack({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onEraseStart,
    this.onEraseUpdate,
    this.onEraseEnd,
    this.altKeyPressed = false,
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
    print('构建擦除图层栈 - 路径数: ${_paths.length}, 当前路径: ${_currentPath != null}');

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景图层
          RepaintBoundary(
            child: BackgroundLayer(image: widget.image),
          ),

          // 预览图层 - 不使用RepaintBoundary，确保能及时更新
          PreviewLayer(
            paths: _paths,
            currentPath: _currentPath,
            dirtyRect: _dirtyRect,
          ),

          // UI图层 - 添加轮廓支持和Alt键状态
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
              altKeyPressed: widget.altKeyPressed, // 传递Alt键状态
              cursor: widget.altKeyPressed
                  ? SystemMouseCursors.move
                  : SystemMouseCursors.precise,
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
    print('处理鼠标按下 - 现有路径数: ${_paths.length}');

    final imagePosition = _transformToImageCoordinates(position);

    // 创建新路径，但不清除现有路径列表
    _currentPath = Path()..moveTo(imagePosition.dx, imagePosition.dy);
    _dirtyRect = Rect.fromPoints(imagePosition, imagePosition).inflate(10);

    widget.onEraseStart?.call(imagePosition);

    // 显式地维持现有路径
    setState(() {
      // 仅更新_currentPath和_dirtyRect，不修改_paths
    });
  }

  void _handlePointerMove(Offset position, Offset delta) {
    if (_currentPath == null) return;

    final imagePosition = _transformToImageCoordinates(position);

    // 更新路径
    _currentPath!.lineTo(imagePosition.dx, imagePosition.dy);

    // 更新脏区域 - 确保包含整个路径区域
    if (_dirtyRect != null) {
      _dirtyRect = _dirtyRect!
          .expandToInclude(Rect.fromCircle(center: imagePosition, radius: 10));
    } else {
      _dirtyRect = Rect.fromCircle(center: imagePosition, radius: 10);
    }

    widget.onEraseUpdate?.call(imagePosition, delta);

    // 强制更新UI以显示所有路径
    setState(() {
      // 空setState，仅触发重绘
    });
  }

  void _handlePointerUp(Offset position) {
    if (_currentPath == null) return;

    // 确保有真实的路径内容
    Rect bounds = _currentPath!.getBounds();
    if (bounds.width > 0 || bounds.height > 0) {
      print('路径完成 - 旧路径数: ${_paths.length}, 添加新路径');

      // 创建一个新的路径列表，保留所有现有路径并添加当前完成的路径
      List<Path> newPaths = List.from(_paths);
      newPaths.add(_currentPath!);

      // 更新状态，清除当前路径和脏区域
      setState(() {
        _paths = newPaths;
        _currentPath = null;
        _dirtyRect = null;
      });
    } else {
      // 空路径，仅清除当前路径
      setState(() {
        _currentPath = null;
        _dirtyRect = null;
      });
    }

    widget.onEraseEnd?.call();
  }

  // 转换视图坐标到图像坐标
  Offset _transformToImageCoordinates(Offset viewportOffset) {
    try {
      // // 获取当前变换矩阵
      // final matrix = widget.transformationController.value.clone();

      // // 获取逆矩阵进行反向转换
      // final invertedMatrix = Matrix4.tryInvert(matrix);
      // if (invertedMatrix == null) {
      //   return viewportOffset; // 无法求逆时返回原始值
      // }

      // // 应用变换获取图像坐标
      // final vector = invertedMatrix
      //     .transform3(Vector3(viewportOffset.dx, viewportOffset.dy, 0));

      final vector = viewportOffset;

      // 添加日志以便调试
      print('坐标转换: 视口($viewportOffset) -> 图像($vector)');

      return vector;
    } catch (e) {
      print('坐标转换错误: $e');
      return viewportOffset;
    }
  }
}
