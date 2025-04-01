import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../application/services/image/character_image_processor.dart';
import '../../tools/image/image_utils.dart';
import 'layers/erase_layer_stack.dart';
import 'layers/preview_layer.dart';

/// 编辑画布组件，管理缩放和平移，整合所有功能
class CharacterEditCanvas extends ConsumerStatefulWidget {
  final ui.Image image;
  final bool showOutline;
  final bool invertMode;
  final bool imageInvertMode;
  final Function(Offset)? onEraseStart;
  final Function(Offset, Offset)? onEraseUpdate;
  final Function()? onEraseEnd;
  final Function(List<Offset>)? onErasePointsChanged;
  final double brushSize;
  final Color brushColor;

  const CharacterEditCanvas({
    Key? key,
    required this.image,
    this.showOutline = false,
    this.invertMode = false,
    this.imageInvertMode = false,
    this.onEraseStart,
    this.onEraseUpdate,
    this.onEraseEnd,
    this.onErasePointsChanged,
    this.brushSize = 10.0,
    required this.brushColor,
  }) : super(key: key);

  @override
  ConsumerState<CharacterEditCanvas> createState() =>
      CharacterEditCanvasState();
}

class CharacterEditCanvasState extends ConsumerState<CharacterEditCanvas> {
  static const _altToggleDebounce = Duration(milliseconds: 100); // 防抖间隔
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _stackKey = GlobalKey();
  final Map<String, dynamic> _currentErasePath = {
    'points': <Offset>[],
    'brushSize': 10.0,
  };
  final List<Map<String, dynamic>> _erasePaths = [];
  DetectedOutline? _outline;
  bool _isProcessing = false;
  final GlobalKey<EraseLayerStackState> _layerStackKey = GlobalKey();
  bool _isAltKeyPressed = false;
  final FocusNode _focusNode = FocusNode();
  DateTime _lastAltToggleTime = DateTime.now(); // 添加时间戳记录

  @override
  Widget build(BuildContext context) {
    print('画布状态 - Alt键: $_isAltKeyPressed, 笔刷大小: ${widget.brushSize}, '
        '画笔颜色: ${widget.brushColor}, 图像反转: ${widget.imageInvertMode}, '
        '显示轮廓: ${widget.showOutline}');

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTapDown: (_) => _focusNode.requestFocus(),
        child: InteractiveViewer(
          transformationController: _transformationController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.1,
          maxScale: 5.0,
          panEnabled: false,
          child: SizedBox(
            width: widget.image.width.toDouble(),
            height: widget.image.height.toDouble(),
            key: _stackKey,
            child: EraseLayerStack(
              key: _layerStackKey,
              image: widget.image,
              transformationController: _transformationController,
              onEraseStart: _handleEraseStart,
              onEraseUpdate: _handleEraseUpdate,
              onEraseEnd: _handleEraseEnd,
              altKeyPressed: _isAltKeyPressed,
              onPan: (delta) {
                setState(() {
                  final Matrix4 matrix =
                      _transformationController.value.clone();
                  matrix.translate(delta.dx, delta.dy);
                  _transformationController.value = matrix;
                });
              },
              brushSize: widget.brushSize,
              brushColor: widget.brushColor,
              imageInvertMode: widget.imageInvertMode,
              showOutline: widget.showOutline,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(CharacterEditCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.image != oldWidget.image) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fitToScreen();
      });
    }

    if (widget.showOutline != oldWidget.showOutline ||
        widget.invertMode != oldWidget.invertMode ||
        widget.imageInvertMode != oldWidget.imageInvertMode) {
      print('设置变化 - invertMode: ${widget.invertMode}, '
          'imageInvertMode: ${widget.imageInvertMode}, '
          'showOutline: ${widget.showOutline}');
      _updateOutline();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void fitToScreen() {
    if (!mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size viewportSize = renderBox.size;
    final double imageWidth = widget.image.width.toDouble();
    final double imageHeight = widget.image.height.toDouble();

    final double scaleX = viewportSize.width / imageWidth;
    final double scaleY = viewportSize.height / imageHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double dx = (viewportSize.width - imageWidth * scale) / 2;
    final double dy = (viewportSize.height - imageHeight * scale) / 2;

    final Matrix4 matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);

    _transformationController.value = matrix;
  }

  @override
  void initState() {
    super.initState();
    // 初始化空路径列表
    _currentErasePath['points'] = <Offset>[];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fitToScreen();
      if (widget.showOutline) {
        _updateOutline();
      }

      // 确保擦除层能正常工作
      print('画布初始化完成，图片尺寸: ${widget.image.width}x${widget.image.height}');
    });
  }

  void updatePaths(List<PathInfo> paths) {
    if (_layerStackKey.currentState != null) {
      print('更新擦除路径 - 路径数: ${paths.length}');

      // 确保在UI线程执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _layerStackKey.currentState!.updatePaths(paths);

        // 如果需要显示轮廓，更新轮廓
        if (widget.showOutline) {
          _updateOutline();
        }
      });
    } else {
      print('错误: 图层栈不可用，无法更新路径');
    }
  }

  void _handleEraseEnd() {
    final points = _currentErasePath['points'] as List<Offset>;

    if (points.isNotEmpty) {
      print('结束擦除 - 添加路径，点数: ${points.length}');

      // 深度复制当前路径
      final pathCopy = Map<String, dynamic>.from(_currentErasePath);
      pathCopy['points'] = List<Offset>.from(points);

      _erasePaths.add(pathCopy);
      _currentErasePath['points'] = <Offset>[];

      print('结束后路径总数: ${_erasePaths.length}');
    }

    widget.onEraseEnd?.call();

    // 如果显示轮廓开关打开，在每次擦除完成后更新轮廓
    if (widget.showOutline) {
      _updateOutline();
    }
  }

  void _handleEraseStart(Offset position) {
    // 如果Alt键被按下，不进行擦除操作
    if (_isAltKeyPressed) return;

    // 仅当不在Alt键模式时才创建擦除路径
    print('开始擦除 - 位置: $position');

    _currentErasePath['points'] = <Offset>[position];
    _currentErasePath['brushSize'] = widget.brushSize;

    widget.onEraseStart?.call(position);

    // 立即通知视图更新
    if (widget.onErasePointsChanged != null) {
      final allPoints = <Offset>[
        ...(_currentErasePath['points'] as List<Offset>),
        ..._erasePaths.expand((path) => path['points'] as List<Offset>),
      ];
      widget.onErasePointsChanged!(allPoints);
    }
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    // 如果Alt键被按下，不进行擦除更新
    if (_isAltKeyPressed) return;

    // 检查是否是实际的擦除操作（有delta）还是单纯的光标移动
    bool isErasing = delta != Offset.zero;

    if (!isErasing) {
      // 如果是单纯的光标移动，只更新光标位置，不执行擦除
      return;
    }

    // 以下是实际擦除操作的逻辑 - 仅在真正拖拽时执行且不在Alt键模式下

    // 如果没有活动的擦除路径，创建一个
    if ((_currentErasePath['points'] as List<Offset>).isEmpty) {
      _handleEraseStart(position);
    }

    // 添加点到当前路径
    (_currentErasePath['points'] as List<Offset>).add(position);

    print('擦除更新 - 添加点到路径: $position, delta: $delta');

    // 调用擦除更新回调
    widget.onEraseUpdate?.call(position, delta);

    // 通知点集合更新
    if (widget.onErasePointsChanged != null) {
      final allPoints = <Offset>[
        ...(_currentErasePath['points'] as List<Offset>),
        ..._erasePaths.expand((path) => path['points'] as List<Offset>),
      ];
      widget.onErasePointsChanged!(allPoints);
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // 处理Alt键事件
    if (event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      final now = DateTime.now();
      final bool isDown = event is KeyDownEvent;

      // 防止快速切换 - 忽略短时间内的反向切换
      if (_isAltKeyPressed != isDown &&
          now.difference(_lastAltToggleTime) > _altToggleDebounce) {
        setState(() {
          _isAltKeyPressed = isDown;
          _lastAltToggleTime = now;

          // 记录状态变化便于调试
          print('Alt键状态变化: $_isAltKeyPressed, 事件类型: ${event.runtimeType}');
        });
      }

      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _updateOutline() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final imageBytes = await ImageUtils.imageToBytes(widget.image);
      if (imageBytes == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final imageProcessor = ref.read(characterImageProcessorProvider);

      final options = ProcessingOptions(
        inverted: widget.invertMode,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: true,
      );

      final fullImageRect = Rect.fromLTWH(
        0,
        0,
        widget.image.width.toDouble(),
        widget.image.height.toDouble(),
      );

      final result = await imageProcessor.previewProcessing(
        imageBytes,
        fullImageRect,
        options,
        _erasePaths.isNotEmpty ? _erasePaths : null,
      );

      if (mounted) {
        setState(() {
          _outline = result.outline;
          _isProcessing = false;
        });

        _layerStackKey.currentState
            ?.setOutline(widget.showOutline ? _outline : null);
      }
    } catch (e) {
      print('轮廓检测失败: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
