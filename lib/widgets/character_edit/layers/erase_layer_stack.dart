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
  // 添加笔刷大小参数
  final double brushSize;
  // 添加画笔颜色参数
  final Color brushColor;

  const EraseLayerStack({
    Key? key,
    required this.image,
    required this.transformationController,
    this.onEraseStart,
    this.onEraseUpdate,
    this.onEraseEnd,
    this.altKeyPressed = false,
    this.brushSize = 10.0,
    this.brushColor = Colors.white,
  }) : super(key: key);

  @override
  State<EraseLayerStack> createState() => EraseLayerStackState();
}

class EraseLayerStackState extends State<EraseLayerStack> {
  final EventDispatcher _eventDispatcher = EventDispatcher();
  // 修改为PathInfo列表
  List<PathInfo> _paths = [];
  // 修改为PathInfo
  PathInfo? _currentPath;
  Rect? _dirtyRect;
  // 添加当前鼠标位置跟踪
  Offset? _currentCursorPosition;
  // 添加图像边界矩形
  late Rect _imageBounds;

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
            child: BackgroundLayer(
              image: widget.image,
              invertMode: widget.brushColor == Colors.black, // 根据画笔颜色判断反转模式
            ),
          ),

          // 预览图层 - 不使用RepaintBoundary，确保能及时更新
          PreviewLayer(
            paths: _paths,
            currentPath: _currentPath,
            dirtyRect: _dirtyRect,
            brushSize: widget.brushSize, // 传递笔刷大小作为默认值
            brushColor: widget.brushColor, // 传递画笔颜色
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
              brushSize: widget.brushSize, // 传递笔刷大小
              cursorPosition: _currentCursorPosition, // 传递光标位置
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

  @override
  void didUpdateWidget(EraseLayerStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image) {
      // 图像改变时更新边界
      _imageBounds = Rect.fromLTWH(
          0, 0, widget.image.width.toDouble(), widget.image.height.toDouble());
    }
  }

  @override
  void initState() {
    super.initState();
    // 初始化图像边界
    _imageBounds = Rect.fromLTWH(
        0, 0, widget.image.width.toDouble(), widget.image.height.toDouble());
  }

  // 添加设置轮廓方法
  void setOutline(DetectedOutline? outline) {
    setState(() {
      _outline = outline;
    });
  }

  void _handlePointerDown(Offset position) {
    print('处理鼠标按下 - 现有路径数: ${_paths.length}');

    final imagePosition = (position);

    // 检查点是否在图像边界内
    if (!_isPointInImageBounds(imagePosition)) {
      print('鼠标按下位置超出图像边界，忽略此操作');
      return;
    }

    // 更新光标位置
    _currentCursorPosition = imagePosition;

    // 创建新路径，使用当前笔刷大小
    final path = Path()..moveTo(imagePosition.dx, imagePosition.dy);
    _currentPath = PathInfo(path: path, brushSize: widget.brushSize);

    _dirtyRect =
        Rect.fromPoints(imagePosition, imagePosition).inflate(widget.brushSize);

    widget.onEraseStart?.call(imagePosition);

    // 显式地维持现有路径
    setState(() {
      // 仅更新_currentPath和_dirtyRect，不修改_paths
    });
  }

  void _handlePointerMove(Offset position, Offset delta) {
    if (_currentPath == null) return;

    final imagePosition = (position);

    // 检查点是否在图像边界内
    if (!_isPointInImageBounds(imagePosition)) {
      print('鼠标移动位置超出图像边界，忽略此点');
      return;
    }

    // 更新光标位置
    _currentCursorPosition = imagePosition;

    // 更新路径
    (_currentPath!.path).lineTo(imagePosition.dx, imagePosition.dy);

    // 更新脏区域 - 确保包含整个路径区域
    if (_dirtyRect != null) {
      _dirtyRect = _dirtyRect!.expandToInclude(
          Rect.fromCircle(center: imagePosition, radius: widget.brushSize));
    } else {
      _dirtyRect =
          Rect.fromCircle(center: imagePosition, radius: widget.brushSize);
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
    Rect bounds = _currentPath!.path.getBounds();
    if (bounds.width > 0 || bounds.height > 0) {
      print('路径完成 - 旧路径数: ${_paths.length}, 添加新路径');

      // 创建一个新的路径列表，保留所有现有路径并添加当前完成的路径
      List<PathInfo> newPaths = List.from(_paths);
      newPaths.add(_currentPath!);

      // 更新状态，清除当前路径和脏区域
      setState(() {
        _paths = newPaths;
        _currentPath = null;
        _dirtyRect = null;
        _currentCursorPosition = null; // 清除光标位置
      });
    } else {
      // 空路径，仅清除当前路径
      setState(() {
        _currentPath = null;
        _dirtyRect = null;
        _currentCursorPosition = null; // 清除光标位置
      });
    }

    widget.onEraseEnd?.call();
  }

  // 检查点是否在图像边界内
  bool _isPointInImageBounds(Offset point) {
    return _imageBounds.contains(point);
  }
}
