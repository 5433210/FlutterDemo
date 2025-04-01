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

  @override
  Widget build(BuildContext context) {
    print('画布状态 - Alt键: $_isAltKeyPressed, 笔刷大小: ${widget.brushSize}, '
        '画笔颜色: ${widget.brushColor}, 图像反转: ${widget.imageInvertMode}, '
        '显示轮廓: ${widget.showOutline}');

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        // 处理Alt键事件
        if (event.logicalKey == LogicalKeyboardKey.alt ||
            event.logicalKey == LogicalKeyboardKey.altLeft ||
            event.logicalKey == LogicalKeyboardKey.altRight) {
          final bool isDown = event is KeyDownEvent;
          if (_isAltKeyPressed != isDown) {
            setState(() {
              _isAltKeyPressed = isDown;
            });
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fitToScreen();
      if (widget.showOutline) {
        _updateOutline();
      }
    });
  }

  void updatePaths(List<PathInfo> paths) {
    if (_layerStackKey.currentState != null) {
      _layerStackKey.currentState!.updatePaths(paths);
      if (widget.showOutline) {
        _updateOutline(); // 路径更新后，如果需要显示轮廓就更新轮廓
      }
    }
  }

  void _handleEraseEnd() {
    if ((_currentErasePath['points'] as List<Offset>).isNotEmpty) {
      _erasePaths.add(Map<String, dynamic>.from(_currentErasePath));
      _currentErasePath['points'] = <Offset>[];
    }

    widget.onEraseEnd?.call();

    if (widget.showOutline) {
      _updateOutline();
    }
  }

  void _handleEraseStart(Offset position) {
    _currentErasePath['points'] = <Offset>[position];
    _currentErasePath['brushSize'] = widget.brushSize;
    widget.onEraseStart?.call(position);
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    (_currentErasePath['points'] as List<Offset>).add(position);
    widget.onEraseUpdate?.call(position, delta);

    widget.onErasePointsChanged?.call(
      (_currentErasePath['points'] as List<Offset>)
        ..addAll(_erasePaths.expand((path) => path['points'] as List<Offset>)),
    );
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
