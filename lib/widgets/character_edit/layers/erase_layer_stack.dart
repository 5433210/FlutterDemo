import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../utils/debug/debug_flags.dart';
import 'background_layer.dart';
import 'events/event_dispatcher.dart';
import 'preview_layer.dart';
import 'ui_layer.dart';

// 添加编辑模式枚举，便于跟踪当前状态
enum EditMode {
  erase,
  pan,
}

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

  // 添加对上次模式的记忆
  EditMode _lastMode = EditMode.erase;

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

    // 检测Alt键状态变化
    if (widget.altKeyPressed != oldWidget.altKeyPressed) {
      print('Alt键状态更新: ${widget.altKeyPressed}, 当前光标: $_currentCursorPosition');
      DebugFlags.trackAltKeyState('EraseLayerStack', widget.altKeyPressed);

      // 如果模式变化，立即刷新UI
      setState(() {
        if (widget.altKeyPressed) {
          _lastMode = EditMode.pan; // 设置为平移模式
        } else {
          _lastMode = EditMode.erase; // 设置为擦除模式
        }
      });

      // 当平移模式结束时，确保任何进行中的擦除操作被结束
      if (!widget.altKeyPressed &&
          oldWidget.altKeyPressed &&
          _currentPath != null) {
        print('从平移模式返回擦除模式，结束当前擦除操作');
        _finishCurrentPath();
        widget.onEraseEnd?.call();
      }
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
    print(
        'EraseLayerStack更新路径 - 当前: ${_paths.length}, 新路径: ${newPaths.length}');

    // 确保在setState中更新状态
    setState(() {
      // 替换路径列表
      _paths = List<PathInfo>.from(newPaths);
      _currentPath = null; // 清空当前路径
      _dirtyRect = null; // 重置脏区域，强制完全重绘

      print('更新路径列表完成 - 当前路径数: ${_paths.length}');
    });

    // 添加调试日志检查路径内容
    if (_paths.isNotEmpty) {
      try {
        for (int i = 0; i < _paths.length; i++) {
          final bounds = _paths[i].path.getBounds();
          // print('路径 #$i - 边界: $bounds, 笔刷: ${_paths[i].brushSize}');
        }
      } catch (e) {
        print('路径调试异常: $e');
      }
    }
  }

  // 抽取路径完成逻辑为单独方法
  void _finishCurrentPath() {
    if (_currentPath == null) return;

    // 检查路径是否有效（至少有两个点）
    Rect bounds = _currentPath!.path.getBounds();
    if (bounds.width > 0 || bounds.height > 0) {
      print('路径完成 - 旧路径数: ${_paths.length}, 添加新路径');
      _paths = [..._paths, _currentPath!];
    }

    // 清空当前路径和脏区域
    _currentPath = null;
    _dirtyRect = null;
  }

  void _handlePointerDown(Offset position) {
    // 更新光标位置
    _currentCursorPosition = position;

    // 检查Alt键并处理平移模式 - 如果按下Alt键，不执行擦除操作
    if (widget.altKeyPressed) {
      setState(() {}); // 仅更新光标
      return; // 重要：当按下Alt键时，直接返回，不创建擦除路径
    }

    // 检查边界
    if (!_isPointInImageBounds(position)) {
      print('鼠标超出边界，忽略操作');
      setState(() {});
      return;
    }

    print('开始创建新路径 - 位置: $position');

    // 创建新路径 - 使用直接指定构造函数参数的方式
    final path = Path();
    path.moveTo(position.dx, position.dy);

    _currentPath = PathInfo(
      path: path,
      brushSize: widget.brushSize,
      brushColor: widget.brushColor,
    );

    print('新路径创建完成 - ID: ${_currentPath.hashCode}');

    // 创建大一点的脏矩形区域确保完全覆盖笔触
    _dirtyRect = Rect.fromCircle(
      center: position,
      radius: widget.brushSize + 10, // 使用更大的半径
    );

    // 调用外部回调
    widget.onEraseStart?.call(position);

    // 强制更新UI
    setState(() {});
  }

  void _handlePointerMove(Offset position, Offset delta) {
    // 始终更新光标位置
    _currentCursorPosition = position;

    // Alt键处理 - 优先级最高，如果按下Alt键，则执行平移而非擦除
    if (widget.altKeyPressed) {
      // 确保模式被正确设置为平移
      if (_lastMode != EditMode.pan) {
        _lastMode = EditMode.pan;
        print('切换到平移模式');
      }

      if (widget.onPan != null && delta != Offset.zero) {
        DebugFlags.logPan(position, delta);
        widget.onPan!(delta);
      }

      // 即使在平移模式下也更新UI，确保光标跟随
      setState(() {});
      return; // 重要：当按下Alt键时，直接返回，不执行任何擦除操作
    } else {
      // 从平移切换回擦除模式时，可能需要特殊处理
      if (_lastMode == EditMode.pan) {
        print('从平移模式返回擦除模式');
        _lastMode = EditMode.erase;
      }
    }

    // 检查是否为实际擦除操作还是仅光标移动
    bool isErasing = delta != Offset.zero;
    if (!isErasing) {
      // 如果delta为零，只更新光标位置，不执行擦除
      setState(() {});
      return;
    }

    // 以下是实际擦除操作的逻辑 - 仅在拖拽时执行

    // 如果没有当前路径，创建一个新路径
    if (_currentPath == null) {
      print('拖拽开始，创建新擦除路径');
      _handlePointerDown(position);
      return;
    }

    // 边界检查
    if (!_isPointInImageBounds(position)) {
      print('鼠标移出边界，仅更新光标');
      setState(() {});
      return;
    }

    print('添加擦除点: $position (delta: $delta)');

    // 将点添加到当前路径
    _currentPath!.path.lineTo(position.dx, position.dy);

    // 更新脏区域
    if (_dirtyRect != null) {
      _dirtyRect = _dirtyRect!.expandToInclude(
        Rect.fromCircle(center: position, radius: widget.brushSize + 5),
      );
    }

    // 调用外部回调
    widget.onEraseUpdate?.call(position, delta);

    // 强制更新UI以重绘
    setState(() {});
  }

  void _handlePointerUp(Offset position) {
    // 如果Alt键被按下，仅清除光标位置，不执行擦除完成操作
    if (widget.altKeyPressed) {
      setState(() {
        _currentCursorPosition = null;
      });
      return; // 重要：确保Alt+拖拽不会生成擦除路径
    }

    // 清除光标位置
    _currentCursorPosition = null;

    // 如果无当前路径，无需处理
    if (_currentPath == null) {
      setState(() {});
      return;
    }

    // 检查路径是否有效（至少有两个点）
    Rect bounds = _currentPath!.path.getBounds();
    if (bounds.width > 0 || bounds.height > 0) {
      print('路径完成 - 旧路径数: ${_paths.length}, 添加新路径');

      // 创建新路径列表并添加当前路径
      setState(() {
        _paths = [..._paths, _currentPath!];
        _currentPath = null;
        _dirtyRect = null;
      });

      print('添加新路径后 - 路径总数: ${_paths.length}');
    } else {
      // 清空无效路径
      setState(() {
        _currentPath = null;
        _dirtyRect = null;
      });
    }

    // 调用擦除完成回调
    widget.onEraseEnd?.call();
  }

  bool _isPointInImageBounds(Offset point) {
    return _imageBounds.contains(point);
  }

  // 辅助方法: 获取路径上的点数量
  int _pathPointCount(Path path) {
    try {
      // 尝试获取路径的边界以确认路径有内容
      final bounds = path.getBounds();
      return bounds.isEmpty ? 0 : 1; // 无法直接获取点数，但可判断是否为空
    } catch (e) {
      return 0;
    }
  }
}
