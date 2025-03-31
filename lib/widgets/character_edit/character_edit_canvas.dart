import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../application/services/image/character_image_processor.dart';
import '../../tools/image/image_utils.dart';
import 'layers/erase_layer_stack.dart';

/// 编辑画布组件，管理缩放和平移，整合所有功能
class CharacterEditCanvas extends ConsumerStatefulWidget {
  final ui.Image image;
  final bool showOutline;
  final bool invertMode;
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
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey _stackKey = GlobalKey();
  final List<Offset> _currentErasePoints = [];
  DetectedOutline? _outline;
  bool _isProcessing = false;

  // 获取EraseLayerStack的引用
  final GlobalKey<EraseLayerStackState> _layerStackKey = GlobalKey();

  // 添加Alt键状态跟踪
  bool _isAltKeyPressed = false;

  @override
  Widget build(BuildContext context) {
    // 打印当前Alt键状态以便调试
    print('当前Alt键状态: $_isAltKeyPressed, 擦除笔刷大小: ${widget.brushSize}');

    return Focus(
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: InteractiveViewer(
        transformationController: _transformationController,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(double.infinity),
        minScale: 0.1,
        maxScale: 5.0,
        // 只在Alt键按下时允许平移
        panEnabled: _isAltKeyPressed,
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
            brushSize: widget.brushSize, // 传递笔刷大小
          ),
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(CharacterEditCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 图像改变时重新适配屏幕
    if (widget.image != oldWidget.image) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        fitToScreen();
      });
    }

    // 当轮廓检测设置改变时，更新轮廓
    if (widget.showOutline != oldWidget.showOutline ||
        widget.invertMode != oldWidget.invertMode) {
      _updateOutline();
    }
  }

  /// 将图像适配到屏幕大小，确保坐标系对齐
  void fitToScreen() {
    if (!mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Size viewportSize = renderBox.size;
    final double imageWidth = widget.image.width.toDouble();
    final double imageHeight = widget.image.height.toDouble();

    // 计算缩放比例，使图像适合视口
    final double scaleX = viewportSize.width / imageWidth;
    final double scaleY = viewportSize.height / imageHeight;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // 计算平移，使图像居中
    final double dx = (viewportSize.width - imageWidth * scale) / 2;
    final double dy = (viewportSize.height - imageHeight * scale) / 2;

    // 创建变换矩阵
    final Matrix4 matrix = Matrix4.identity()
      ..translate(dx, dy)
      ..scale(scale, scale);

    // 应用变换
    _transformationController.value = matrix;

    print('适配屏幕: 图像大小(${imageWidth}x$imageHeight), '
        '视口大小(${viewportSize.width}x${viewportSize.height}), '
        '缩放比例($scale), 平移($dx, $dy)');
  }

  @override
  void initState() {
    super.initState();
    // 使用帧回调确保在布局完成后适配屏幕
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fitToScreen();

      // 初始化时检测轮廓
      if (widget.showOutline) {
        _updateOutline();
      }
    });
  }

  // 设置缩放比例
  void setScale(double scale) {
    if (_transformationController.value != Matrix4.identity()) {
      final Matrix4 matrix = Matrix4.copy(_transformationController.value);
      final double currentScale = _getScaleFromMatrix(matrix);
      final double scaleChange = scale / currentScale;

      matrix.scale(scaleChange, scaleChange);
      _transformationController.value = matrix;
    }
  }

  /// 从矩阵中获取当前缩放比例
  double _getScaleFromMatrix(Matrix4 matrix) {
    return matrix.getMaxScaleOnAxis();
  }

  // 处理擦除结束事件
  void _handleEraseEnd() {
    widget.onEraseEnd?.call();

    // 如果显示轮廓，更新轮廓
    if (widget.showOutline) {
      _updateOutline();
    }
  }

  // 处理擦除开始事件
  void _handleEraseStart(Offset position) {
    // 保留历史点，只添加新点
    // 注意：不清空现有数组，这可能是导致问题的原因之一
    _currentErasePoints.add(position);
    widget.onEraseStart?.call(position);

    print('擦除开始 - 当前点数: ${_currentErasePoints.length}');
  }

  // 处理擦除更新事件
  void _handleEraseUpdate(Offset position, Offset delta) {
    _currentErasePoints.add(position);
    widget.onEraseUpdate?.call(position, delta);

    // 更新擦除点回调
    widget.onErasePointsChanged?.call(_currentErasePoints);
  }

  // 处理键盘事件
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // 检测Alt键状态
    if (event.logicalKey == LogicalKeyboardKey.alt) {
      final bool isDown = event is KeyDownEvent;
      setState(() {
        _isAltKeyPressed = isDown;
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 使用CharacterImageProcessor检测并更新轮廓
  Future<void> _updateOutline() async {
    if (_isProcessing || !widget.showOutline) return;

    setState(() => _isProcessing = true);

    try {
      // 使用现有的CharacterImageProcessor进行轮廓检测
      final imageBytes = await ImageUtils.imageToBytes(widget.image);
      if (imageBytes == null)
        throw Exception('Failed to convert image to bytes');

      final imageProcessor = ref.read(characterImageProcessorProvider);

      final options = ProcessingOptions(
        inverted: widget.invertMode,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: true, // 启用轮廓检测
      );

      final fullImageRect = Rect.fromLTWH(
          0, 0, widget.image.width.toDouble(), widget.image.height.toDouble());

      final result = await imageProcessor.previewProcessing(
          imageBytes,
          fullImageRect,
          options,
          _currentErasePoints.isNotEmpty ? _currentErasePoints : null);

      if (mounted) {
        setState(() {
          _outline = result.outline;
          _isProcessing = false;
        });

        // 更新UI层显示轮廓
        _layerStackKey.currentState?.setOutline(_outline);
      }
    } catch (e) {
      print('轮廓检测失败: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
