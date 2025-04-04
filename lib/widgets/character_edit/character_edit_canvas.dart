import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/image/character_image_processor.dart';
import '../../domain/models/character/detected_outline.dart';
import '../../domain/models/character/processing_options.dart';
import '../../infrastructure/logging/logger.dart';
import '../../presentation/providers/character/erase_providers.dart';
import '../../utils/coordinate_transformer.dart';
import '../../utils/debug/debug_flags.dart';
import '../../utils/focus/focus_persistence.dart';
import '../../utils/image/image_utils.dart';
import 'layers/erase_layer_stack.dart';

/// 编辑画布组件
class CharacterEditCanvas extends ConsumerStatefulWidget {
  final ui.Image image;
  final bool showOutline;
  final bool invertMode;
  final bool imageInvertMode;
  final Function(Offset)? onEraseStart;
  final Function(Offset, Offset)? onEraseUpdate;
  final Function()? onEraseEnd;
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
  late CoordinateTransformer _transformer;

  final GlobalKey<EraseLayerStackState> _layerStackKey = GlobalKey();

  bool _isProcessing = false;

  bool _isAltKeyPressed = false;
  DateTime _lastAltToggleTime = DateTime.now();

  DetectedOutline? _outline;

  /// 返回当前的坐标转换器
  CoordinateTransformer get transformer => _transformer;
  @override
  Widget build(BuildContext context) {
    if (kDebugMode && DebugFlags.enableEraseDebug) {
      print(
          '画布构建 - showOutline: ${widget.showOutline}, isProcessing: $_isProcessing');
    }

    final eraseState = ref.watch(eraseStateProvider);
    final pathRenderData = ref.watch(pathRenderDataProvider);
    final showContour =
        ref.watch(eraseStateProvider.select((state) => state.showContour));

    ref.listen(eraseStateProvider.select((state) => state.showContour),
        (previous, current) {
      if (current) {
        print('轮廓状态变化，强制更新轮廓显示，当前值: $current');
        _updateOutline();
      }
    });

    ref.listen(pathRenderDataProvider, (previous, current) {
      final showContour = ref.read(eraseStateProvider).showContour;
      if (showContour) {
        final prevPaths = previous?.completedPaths ?? [];
        final currentPaths = current.completedPaths ?? [];
        if (prevPaths.length != currentPaths.length) {
          print('路径变化检测：从 ${prevPaths.length} 到 ${currentPaths.length} 个路径');
          _updateOutline();
        }
      }
    });

    ref.listen(eraseStateProvider.select((state) => state.imageInvertMode),
        (previous, current) {
      if (previous != current && ref.read(eraseStateProvider).showContour) {
        print('图像反转状态变化，强制更新轮廓');
        Future.delayed(const Duration(milliseconds: 100), () {
          _updateOutline();
        });
      }
    });

    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!focusNode.hasFocus) focusNode.requestFocus();
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            _updateTransformer(constraints.biggest);

            return InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.1,
              maxScale: 5.0,
              panEnabled: _isAltKeyPressed,
              onInteractionUpdate: (details) {
                _updateTransformer(constraints.biggest);
              },
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
                  altKeyPressed: _isAltKeyPressed,
                  brushSize: widget.brushSize,
                  brushColor: widget.brushColor,
                  imageInvertMode: widget.imageInvertMode,
                  showOutline: widget.showOutline,
                  onPan: (delta) {
                    if (_isAltKeyPressed) {
                      final matrix = _transformationController.value.clone();
                      matrix.translate(delta.dx, delta.dy);
                      _transformationController.value = matrix;
                    }
                  },
                  onTap: _handleTap,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(CharacterEditCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    // transformer的更新已经移到LayoutBuilder中处理
  }

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    _transformationController.dispose();
    super.dispose();
  }

  /// 获取处理后的图像
  Future<ui.Image?> getProcessedImage() async {
    if (_layerStackKey.currentState == null) return null;

    try {
      // 创建一个带有当前大小的图片记录器
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = Size(
        widget.image.width.toDouble(),
        widget.image.height.toDouble(),
      );

      // 调用EraseLayerStack的渲染方法
      await _layerStackKey.currentState!.renderToCanvas(canvas, size);

      // 创建最终图像
      final picture = recorder.endRecording();
      final processedImage = await picture.toImage(
        widget.image.width,
        widget.image.height,
      );

      return processedImage;
    } catch (e) {
      print('获取处理后图像失败: $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);

    // 初始化坐标转换器
    _transformer = CoordinateTransformer(
      transformationController: _transformationController,
      imageSize: Size(
        widget.image.width.toDouble(),
        widget.image.height.toDouble(),
      ),
      viewportSize: const Size(800, 600), // 初始默认值，将在LayoutBuilder中更新
      enableLogging: false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitToScreen();
      if (widget.showOutline) {
        _updateOutline();
      }

      // 让布局完成后再进行transformer的更新
      if (mounted && context.size != null) {
        _updateTransformer(context.size!);
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    // 热重载时更新transformer
    if (mounted && context.size != null) {
      _updateTransformer(context.size!);
    }
  }

  Future<void> _exportContourDebugImage() async {
    if (!kDebugMode) return;

    setState(() => _isProcessing = true);

    try {
      final imageBytes = await ImageUtils.imageToBytes(widget.image);
      if (imageBytes == null) {
        throw Exception('无法将图像转换为字节数组');
      }

      final imageProcessor = ref.read(characterImageProcessorProvider);
      final eraseState = ref.read(eraseStateProvider);

      final options = ProcessingOptions(
        inverted: eraseState.imageInvertMode,
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

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'contour_debug_$timestamp.png';

      print('轮廓调试图已生成，文件名: $filename');
      print('轮廓图显示了每条轮廓的起点(绿色)和终点(红色)，以及终止原因');
    } catch (e) {
      print('导出轮廓调试图失败: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  List<Offset> _extractPointsFromPath(Path path) {
    List<Offset> points = [];
    try {
      for (final metric in path.computeMetrics()) {
        if (metric.length == 0) {
          final pathBounds = path.getBounds();
          points.add(pathBounds.center);
          continue;
        }

        final stepLength = math.max(1.0, metric.length / 100);

        for (double distance = 0;
            distance <= metric.length;
            distance += stepLength) {
          final tangent = metric.getTangentForOffset(distance);
          if (tangent != null) {
            points.add(tangent.position);
          }
        }

        if (metric.length > 0) {
          final lastTangent = metric.getTangentForOffset(metric.length);
          if (lastTangent != null) {
            points.add(lastTangent.position);
          }
        }
      }

      if (points.isEmpty) {
        print('警告：从路径中未提取到点，尝试使用路径边界');
        final bounds = path.getBounds();
        points.add(bounds.center);
      }
    } catch (e) {
      print('提取路径点出错: $e');
      try {
        final bounds = path.getBounds();
        points.add(bounds.center);
        print('提取失败，使用路径中心点代替');
      } catch (e2) {
        print('无法获取路径边界: $e2');
      }
    }
    return points;
  }

  void _fitToScreen() {
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

  void _handleEraseEnd() {
    widget.onEraseEnd?.call();
    if (!_isAltKeyPressed) {
      ref.read(eraseStateProvider.notifier).completePath();
    }
  }

  void _handleEraseStart(Offset position) {
    widget.onEraseStart?.call(position);
    if (!_isAltKeyPressed) {
      ref.read(eraseStateProvider.notifier).startPath(position);
    }
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    widget.onEraseUpdate?.call(position, delta);
    if (!_isAltKeyPressed) {
      ref.read(eraseStateProvider.notifier).updatePath(position);
    }
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

    if (kDebugMode &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyD) {
      print('按下D键，导出轮廓调试图');
      _exportContourDebugImage();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _handleTap(Offset position) {
    if (_isAltKeyPressed) return;

    ref.read(eraseStateProvider.notifier).startPath(position);
    ref.read(eraseStateProvider.notifier).completePath();

    widget.onEraseStart?.call(position);
    widget.onEraseEnd?.call();
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus && _isAltKeyPressed) {
      setState(() {
        _isAltKeyPressed = false;
      });
    }
  }

  Future<void> _updateOutline() async {
    if (_isProcessing) {
      print('轮廓正在处理中，跳过更新');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final imageBytes = await ImageUtils.imageToBytes(widget.image);
      if (imageBytes == null) {
        throw Exception('无法将图像转换为字节数组');
      }

      final imageProcessor = ref.read(characterImageProcessorProvider);
      final pathRenderData = ref.read(pathRenderDataProvider);
      final eraseState = ref.read(eraseStateProvider);

      final options = ProcessingOptions(
        inverted: eraseState.imageInvertMode,
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

      if (kDebugMode) {
        print(
            '轮廓处理选项: inverted=${options.inverted}, showContour=${options.showContour}');
      }

      List<Map<String, dynamic>> erasePaths = [];
      if (pathRenderData.completedPaths.isNotEmpty) {
        erasePaths = pathRenderData.completedPaths.map((p) {
          final points = _extractPointsFromPath(p.path);
          return {
            'brushSize': p.brushSize,
            'brushColor': p.brushColor.value,
            'points': points,
            'pathId': p.hashCode.toString(),
          };
        }).toList();
      }

      print('开始处理轮廓，传递 ${erasePaths.length} 个路径...');
      final result = await imageProcessor.previewProcessing(
        imageBytes,
        fullImageRect,
        options,
        erasePaths,
      );
      print('轮廓处理完成');

      if (mounted) {
        setState(() {
          _outline = result.outline;
          _isProcessing = false;
        });

        if (_layerStackKey.currentState != null) {
          final showContour = ref.read(eraseStateProvider).showContour;
          print('传递轮廓数据到 EraseLayerStack, 显示=$showContour');
          _layerStackKey.currentState!
              .setOutline(showContour ? _outline : null);
        }
      }
    } catch (e) {
      print('轮廓检测失败: $e');
      if (kDebugMode) {
        print('错误堆栈: ${StackTrace.current}');
      }
      setState(() => _isProcessing = false);
    }
  }

  /// 更新坐标转换器
  /// [viewportSize] 视口尺寸
  void _updateTransformer(Size viewportSize) {
    if (!mounted) {
      AppLogger.warning('无法更新坐标转换器：组件未挂载');
      return;
    }

    try {
      final imageSize = Size(
        widget.image.width.toDouble(),
        widget.image.height.toDouble(),
      );

      _transformer = CoordinateTransformer(
        transformationController: _transformationController,
        imageSize: imageSize,
        viewportSize: viewportSize,
        enableLogging: kDebugMode,
      );

      if (kDebugMode) {
        AppLogger.debug('坐标转换器更新完成', data: {
          'imageSize': '${imageSize.width}x${imageSize.height}',
          'viewportSize': '${viewportSize.width}x${viewportSize.height}',
          'scale': _transformer.currentScale.toStringAsFixed(3),
        });
      }
    } catch (e, stack) {
      AppLogger.error('更新坐标转换器失败', error: e, stackTrace: stack, data: {
        'imageSize': '${widget.image.width}x${widget.image.height}',
        'viewportSize': '${viewportSize.width}x${viewportSize.height}',
      });
    }
  }
}
