import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../application/services/image/character_image_processor.dart';
import '../../tools/image/image_utils.dart';
import '../../utils/debug/debug_flags.dart';
import '../../utils/focus/focus_persistence.dart';
import 'layers/erase_layer_stack.dart';
import 'layers/preview_layer.dart';

/// 编辑画布组件
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

class CharacterEditCanvasState extends ConsumerState<CharacterEditCanvas>
    with FocusPersistenceMixin {
  static const _altToggleDebounce = Duration(milliseconds: 100);
  final TransformationController _transformationController =
      TransformationController();
  final GlobalKey<EraseLayerStackState> _layerStackKey = GlobalKey();

  final Map<String, dynamic> _currentErasePath = {
    'points': <Offset>[],
    'brushSize': 10.0,
  };
  final List<Map<String, dynamic>> _erasePaths = [];

  DetectedOutline? _outline;
  bool _isProcessing = false;
  bool _isAltKeyPressed = false;
  DateTime _lastAltToggleTime = DateTime.now();
  Timer? _outlineUpdateTimer;

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && DebugFlags.enableEraseDebug) {
      print(
          '画布构建 - showOutline: ${widget.showOutline}, isProcessing: $_isProcessing');
    }

    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!focusNode.hasFocus) focusNode.requestFocus();
        },
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
            child: EraseLayerStack(
              key: _layerStackKey,
              image: widget.image,
              transformationController: _transformationController,
              onEraseStart: _handleEraseStart,
              onEraseUpdate: _handleEraseUpdate,
              onEraseEnd: _handleEraseEnd,
              onTap: _handleTap,
              altKeyPressed: _isAltKeyPressed,
              onPan: (delta) {
                setState(() {
                  final matrix = _transformationController.value.clone();
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
      print('画布属性变化:');
      print('- showOutline: ${widget.showOutline}');
      print('- invertMode: ${widget.invertMode}');
      print('- imageInvertMode: ${widget.imageInvertMode}');
      _scheduleOutlineUpdate();
    }
  }

  @override
  void dispose() {
    _outlineUpdateTimer?.cancel();
    focusNode.removeListener(_onFocusChange);
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
    _currentErasePath['points'] = <Offset>[];
    focusNode.addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fitToScreen();
      if (widget.showOutline) {
        _scheduleOutlineUpdate();
      }
    });
  }

  void updatePaths(List<PathInfo> paths) {
    print(
        '更新路径 - showOutline: ${widget.showOutline}, isProcessing: $_isProcessing');
    if (_layerStackKey.currentState != null) {
      _layerStackKey.currentState!.updatePaths(paths);
      // 使用延迟更新来避免过于频繁的轮廓更新
      _scheduleOutlineUpdate();
    }
  }

  void _handleEraseEnd() {
    print('擦除结束 - showOutline: ${widget.showOutline}');
    widget.onEraseEnd?.call();

    final points = _currentErasePath['points'] as List<Offset>;
    if (points.isNotEmpty) {
      final pathCopy = Map<String, dynamic>.from(_currentErasePath);
      pathCopy['points'] = List<Offset>.from(points);
      _erasePaths.add(pathCopy);
      _currentErasePath['points'] = <Offset>[];

      // 强制更新轮廓
      _scheduleOutlineUpdate();
    }
  }

  void _handleEraseStart(Offset position) {
    if (_isAltKeyPressed) return;

    _currentErasePath['points'] = <Offset>[position];
    _currentErasePath['brushSize'] = widget.brushSize;

    widget.onEraseStart?.call(position);

    if (widget.onErasePointsChanged != null) {
      final allPoints = <Offset>[
        ...(_currentErasePath['points'] as List<Offset>),
        ..._erasePaths.expand((path) => path['points'] as List<Offset>),
      ];
      widget.onErasePointsChanged!(allPoints);
    }
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    if (_isAltKeyPressed) return;

    if ((_currentErasePath['points'] as List<Offset>).isEmpty) {
      _handleEraseStart(position);
    }

    final points = _currentErasePath['points'] as List<Offset>;
    if (points.isNotEmpty) {
      final lastPoint = points.last;
      final distance = (position - lastPoint).distance;

      if (distance > widget.brushSize / 2) {
        const interpolationCount = 3;
        for (int i = 1; i <= interpolationCount; i++) {
          final t = i / (interpolationCount + 1);
          final interpolatedPoint = Offset(
            lastPoint.dx + (position.dx - lastPoint.dx) * t,
            lastPoint.dy + (position.dy - lastPoint.dy) * t,
          );
          points.add(interpolatedPoint);
        }
      }
    }

    points.add(position);
    widget.onEraseUpdate?.call(position, delta);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      final now = DateTime.now();
      bool isDown;

      if (event is KeyDownEvent) {
        isDown = true;
      } else if (event is KeyUpEvent) {
        isDown = false;
      } else if (event is KeyRepeatEvent) {
        isDown = _isAltKeyPressed;
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }

      if (_isAltKeyPressed != isDown &&
          now.difference(_lastAltToggleTime) > _altToggleDebounce) {
        setState(() {
          _isAltKeyPressed = isDown;
          _lastAltToggleTime = now;
        });
      }

      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleTap(Offset position) {
    if (_isAltKeyPressed) return;

    _currentErasePath['points'] = <Offset>[position];
    _currentErasePath['brushSize'] = widget.brushSize;

    widget.onEraseStart?.call(position);

    final pathCopy = Map<String, dynamic>.from(_currentErasePath);
    pathCopy['points'] =
        List<Offset>.from(_currentErasePath['points'] as List<Offset>);
    _erasePaths.add(pathCopy);
    _currentErasePath['points'] = <Offset>[];

    widget.onEraseEnd?.call();

    // 强制更新轮廓
    _scheduleOutlineUpdate();

    HapticFeedback.lightImpact();
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus && _isAltKeyPressed) {
      setState(() {
        _isAltKeyPressed = false;
      });
    }
  }

  void _scheduleOutlineUpdate() {
    _outlineUpdateTimer?.cancel();
    _outlineUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted && widget.showOutline) {
        _updateOutline();
      }
    });
  }

  Future<void> _updateOutline() async {
    if (_isProcessing) {
      print('轮廓正在处理中，跳过更新');
      return;
    }

    print(
        '开始更新轮廓 - isProcessing: $_isProcessing, showOutline: ${widget.showOutline}');
    setState(() => _isProcessing = true);

    try {
      final imageBytes = await ImageUtils.imageToBytes(widget.image);
      if (imageBytes == null) {
        throw Exception('无法将图像转换为字节数组');
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
          print('轮廓更新完成，是否有轮廓：${_outline != null}');
          if (_outline != null) {
            print('轮廓信息:');
            print('- 轮廓数量: ${_outline!.contourPoints.length}');
            print('- 边界矩形: ${_outline!.boundingRect}');
          }
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
