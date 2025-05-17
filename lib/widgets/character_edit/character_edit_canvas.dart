import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/migration/erase_data_migration.dart';
import '../../application/services/image/character_image_processor.dart';
import '../../domain/models/character/character_region.dart';
import '../../domain/models/character/detected_outline.dart';
import '../../domain/models/character/processing_options.dart';
import '../../infrastructure/logging/logger.dart';
import '../../presentation/providers/character/erase_providers.dart';
import '../../utils/coordinate_transformer.dart';
import '../../utils/focus/focus_persistence.dart';
import '../../utils/image/image_utils.dart';
import 'layers/optimized_erase_layer_stack.dart';

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
  final double? rotation;
  final CharacterRegion? region;

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
    this.rotation,
    this.region,
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

  final GlobalKey<OptimizedEraseLayerStackState> _layerStackKey = GlobalKey();

  bool _isProcessing = false;

  // 跟踪Alt键当前状态的变量
  bool _isAltKeyPressed = false;

  // 为Alt键状态添加一个ValueNotifier，保证状态变化能够可靠地传递到UI
  late final ValueNotifier<bool> _altKeyNotifier = ValueNotifier<bool>(false);

  // 用于延迟更新轮廓的计时器，防止频繁刷新
  Timer? _updateOutlineDebounceTimer;

  DateTime _lastAltToggleTime = DateTime.now();

  DetectedOutline? _outline;

  // Add getter for the current outline to allow access from outside
  DetectedOutline? get outline => _outline;

  /// 返回当前的坐标转换器
  CoordinateTransformer get transformer => _transformer;

  @override
  Widget build(BuildContext context) {
    // if (kDebugMode && DebugFlags.enableEraseDebug) {
    print(
        '画布构建 - showOutline: ${widget.showOutline}, isProcessing: $_isProcessing');
    // }

    // Pan mode is always enabled by default through Alt key

    // Improved outline toggling behavior
    ref.listen(eraseStateProvider.select((state) => state.showContour),
        (previous, current) {
      if (previous != current) {
        print('轮廓状态变化，从 $previous 到 $current, 强制更新轮廓显示');
        // Force update outline regardless of toggle direction to ensure proper state
        _updateOutline();

        // Set the outline in layer stack with appropriate visibility
        if (_layerStackKey.currentState != null) {
          final outline = current ? _outline : null;
          _layerStackKey.currentState!.setOutline(outline);
        }
      }
    });

    ref.listen(pathRenderDataProvider, (previous, current) {
      final showContour = ref.read(eraseStateProvider).showContour;
      if (showContour) {
        final prevPaths = previous?.completedPaths ?? [];
        final currentPaths = current.completedPaths;

        // 检测路径变化
        AppLogger.debug('路径变化检测', data: {
          'from': prevPaths.length,
          'to': currentPaths.length,
        });

        // 当路径数量变化时更新轮廓
        // 这确保了撤销操作后视觉效果会立即更新
        if (prevPaths.length != currentPaths.length) {
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

    // Listen for forceImageUpdate flag changes to update the image processing
    ref.listen(eraseStateProvider.select((state) => state.forceImageUpdate),
        (_, current) {
      // Use null-safe approach to check if forceImageUpdate is true
      if (current ?? false) {
        ref.read(eraseStateProvider.notifier).resetForceImageUpdate();
        AppLogger.debug('检测到强制更新图像标志，更新处理图像');
        _updateOutline(); // Uses internal debouncing mechanism
      }
    });

    // 监听Alt键状态
    _altKeyNotifier.addListener(() {
      setState(() {
        // 当ValueNotifier更新时，强制刷新UI
      });
    });

    return RawKeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        // 直接拦截原始键盘事件，确保Alt键状态稳定
        final isAltKey = event.logicalKey == LogicalKeyboardKey.alt ||
            event.logicalKey == LogicalKeyboardKey.altLeft ||
            event.logicalKey == LogicalKeyboardKey.altRight;

        if (isAltKey) {
          if (event is RawKeyDownEvent) {
            _setAltKeyPressed(true);
          } else if (event is RawKeyUpEvent) {
            _setAltKeyPressed(false);
          }
        }
      },
      // 回到精确光标，通常显示为箭头
      child: Focus(
        focusNode: FocusNode(), // 使用额外的FocusNode来捕获事件
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
                maxScale: 10.0,
                // Always enable panning, but only when Alt is pressed will it actually pan
                panEnabled: _altKeyNotifier.value,
                onInteractionUpdate: (details) {
                  _updateTransformer(constraints.biggest);
                },
                child: SizedBox(
                  width: widget.image.width.toDouble(),
                  height: widget.image.height.toDouble(),
                  child: OptimizedEraseLayerStack(
                    key: _layerStackKey,
                    image: widget.image,
                    transformationController: _transformationController,
                    onEraseStart: _handleEraseStart,
                    onEraseUpdate: _handleEraseUpdate,
                    onEraseEnd: _handleEraseEnd,
                    onPan: (delta) {
                      if (_altKeyNotifier.value) {
                        _transformationController.value
                            .translate(delta.dx, delta.dy);
                      }
                    },
                    onTap: _handleTap,
                    altKeyPressed:
                        _altKeyNotifier.value, // Pass the Alt key state
                  ),
                ),
              );
            },
          ),
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
    // 移除所有键盘事件处理器
    HardwareKeyboard.instance.removeHandler(_handleRawKeyEvent);
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyboardEvent);

    // 清理ValueNotifier
    _altKeyNotifier.dispose();

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

    // 设置增强的键盘监听系统，用于可靠地处理Alt键
    _setupKeyboardListener();

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

      // Load saved erase paths with migration support
      if (widget.region != null) {
        final eraseData = EraseDataMigration.migrateEraseData(widget.region!);

        AppLogger.debug('擦除路径加载诊断', data: {
          'hasRegion': widget.region != null,
          'hasEraseData': widget.region?.eraseData != null,
          'eraseDataCount': widget.region?.eraseData?.length ?? 0,
          'hasErasePoints': widget.region?.erasePoints != null,
          'erasePointsCount': widget.region?.erasePoints?.length ?? 0,
          'migratedDataCount': eraseData?.length ?? 0,
        });

        if (eraseData != null && eraseData.isNotEmpty) {
          AppLogger.debug('准备加载擦除路径数据', data: {
            'pathCount': eraseData.length,
          });

          ref
              .read(eraseStateProvider.notifier)
              .initializeWithSavedPaths(eraseData);

          // Check if paths were successfully loaded
          final pathRenderData = ref.read(pathRenderDataProvider);
          AppLogger.debug('擦除路径加载结果', data: {
            'completedPathCount': pathRenderData.completedPaths.length,
          });
        } else {
          AppLogger.debug('没有有效的擦除路径数据可加载');
        }
      }

      // Initialize outline immediately if contour showing is enabled
      if (widget.showOutline || ref.read(eraseStateProvider).showContour) {
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

      // ...existing code...
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
    if (!_isAltKeyPressed) {
      widget.onEraseEnd?.call();
      ref.read(eraseStateProvider.notifier).completePath();
    }
  }

  void _handleEraseStart(Offset position) {
    // Only initiate erasing if the position is within image bounds
    if (!_isAltKeyPressed && _isPointWithinImageBounds(position)) {
      widget.onEraseStart?.call(position);
      ref.read(eraseStateProvider.notifier).startPath(position);
    }
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    if (!_isAltKeyPressed) {
      // Check if the position is within image bounds
      if (_isPointWithinImageBounds(position)) {
        widget.onEraseUpdate?.call(position, delta);
        ref.read(eraseStateProvider.notifier).updatePath(position);
      }
    }
  }

  // 键盘事件全局处理器
  bool _handleKeyboardEvent(KeyEvent event) {
    // 使用统一的处理逻辑
    return _processAltKeyEvent(event);
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

  // 直接处理原始键盘事件，专门用于处理Alt键
  bool _handleRawKeyEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      final now = DateTime.now();
      final bool isDown = event is KeyDownEvent;

      // 防止事件重复触发
      if (_isAltKeyPressed != isDown &&
          now.difference(_lastAltToggleTime) > _altToggleDebounce) {
        setState(() {
          _isAltKeyPressed = isDown;
          _lastAltToggleTime = now;
        });

        AppLogger.debug('Alt键状态变化', data: {
          'isDown': isDown,
          'eventType': event.runtimeType.toString()
        });
      }

      return true; // 已处理事件
    }

    return false; // 让其他处理程序处理此事件
  }

  void _handleTap(Offset position) {
    if (_isAltKeyPressed) {
      // Alt键按下时不处理点击事件，允许平移
      return;
    }

    // Only handle taps within image bounds
    if (_isPointWithinImageBounds(position)) {
      // 使用专门的点击擦除方法，避免重复创建路径
      ref.read(eraseStateProvider.notifier).clickErase(position);

      // 不调用任何回调，避免创建多余的路径
      // 点击擦除只需要一个路径，clickErase方法已经处理了路径的创建和完成
    }
  }

  // New helper method to check if a point is within the image boundaries
  bool _isPointWithinImageBounds(Offset point) {
    return point.dx >= 0 &&
        point.dx < widget.image.width.toDouble() &&
        point.dy >= 0 &&
        point.dy < widget.image.height.toDouble();
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus && _isAltKeyPressed) {
      setState(() {
        _isAltKeyPressed = false;
      });
    }
  }

  // 每帧检查，确保Alt状态与硬件状态同步
  void _onFrameCallback() {
    if (!mounted) return;

    // 检查是否需要执行额外同步
    if (_isAltKeyPressed) {
      final bool isAltActuallyPressed = HardwareKeyboard.instance.isAltPressed;
      if (!isAltActuallyPressed) {
        _setAltKeyPressed(false);
        AppLogger.debug('帧回调检测到Alt键已释放', data: {
          'time': DateTime.now().toIso8601String(),
        });
      }
    }

    // 继续在下一帧检查
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFrameCallback());
  }

  // 统一处理Alt键事件的方法
  bool _processAltKeyEvent(KeyEvent event) {
    // 检查是否是Alt相关的键
    final bool isAltKey = event.logicalKey == LogicalKeyboardKey.alt ||
        event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight;

    if (isAltKey) {
      final bool isKeyDown = event is KeyDownEvent;
      final bool isKeyUp = event is KeyUpEvent;

      if (isKeyDown || isKeyUp) {
        _setAltKeyPressed(isKeyDown);

        // 记录更详细的日志便于调试
        AppLogger.debug('Alt键事件处理', data: {
          'event': event.runtimeType.toString(),
          'isDown': isKeyDown,
          'source': 'processAltKeyEvent',
        });

        return true; // 已处理此事件
      }
    }

    return false; // 让其他处理器处理此事件
  }

  // 统一设置Alt键状态的方法，确保各种监听器间状态一致
  void _setAltKeyPressed(bool isPressed) {
    final now = DateTime.now();

    // 防抖动：确保Alt键状态变化不会太频繁
    if (_isAltKeyPressed != isPressed ||
        now.difference(_lastAltToggleTime) >
            const Duration(milliseconds: 500)) {
      // 更新状态和时间戳
      _isAltKeyPressed = isPressed;
      _lastAltToggleTime = now;

      // 通过ValueNotifier通知UI更新
      if (_altKeyNotifier.value != isPressed) {
        _altKeyNotifier.value = isPressed;
      }

      // 强制请求焦点以确保继续接收键盘事件
      if (isPressed && !focusNode.hasFocus) {
        focusNode.requestFocus();
      }

      // 记录日志以便调试
      AppLogger.debug('Alt键状态已更新', data: {
        'isPressed': isPressed,
        'timestamp': now.millisecondsSinceEpoch,
      });

      // 确保UI更新
      if (mounted) {
        setState(() {});
      }

      // 在Alt键释放后强制执行一次额外检查，以确保状态正确
      if (!isPressed) {
        // 延迟50ms后再检查一次，捕获可能的不同步状态
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _altKeyNotifier.value != isPressed) {
            _altKeyNotifier.value = isPressed;
            AppLogger.debug('Alt键状态释放后强制同步', data: {
              'isPressed': isPressed,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            });
            setState(() {});
          }
        });
      }
    }
  }

  // 监听键盘状态变化，用于Alt键释放检测
  void _setupKeyboardListener() {
    // 添加全局键盘状态监听器
    HardwareKeyboard.instance.addHandler(_handleRawKeyEvent);

    // 特别添加对Alt键的监听
    // 这个监听器会在窗口失焦或系统级别的事件发生时也能捕获Alt键释放
    ServicesBinding.instance.keyboard.addHandler(_handleKeyboardEvent);

    // 另外在应用程序空闲时检查Alt键状态
    // 这能捕获因为切换窗口等导致的未被捕获的键盘释放事件
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startKeyboardStateChecking();
    });
  }

  // 定时检查Alt键的实际状态，防止状态不同步
  void _startKeyboardStateChecking() {
    // 创建多个定时检查，以不同频率进行状态同步

    // 1. 更快速的检查 - 每50ms检查一次，主要用于立即捕获按键释放
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 检查Alt键的实际状态
      final bool isAltActuallyPressed = HardwareKeyboard.instance.isAltPressed;

      // 更积极地纠正状态不一致
      if (_isAltKeyPressed != isAltActuallyPressed) {
        _setAltKeyPressed(isAltActuallyPressed);
        AppLogger.debug('快速检测器发现Alt键状态不一致', data: {
          'UIState': _isAltKeyPressed,
          'actualState': isAltActuallyPressed,
          'time': DateTime.now().toIso8601String(),
        });
      }
    });

    // 2. 鼠标移动时的强制状态检查
    // 当用户移动鼠标时，特别是在Alt释放后可能没有捕获到事件时
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // 当有用户交互时，添加一次性检查
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _isAltKeyPressed) {
            final bool isAltActuallyPressed =
                HardwareKeyboard.instance.isAltPressed;
            if (!isAltActuallyPressed) {
              _setAltKeyPressed(false);
              AppLogger.debug('延迟检测到Alt键状态修正', data: {
                'time': DateTime.now().toIso8601String(),
              });
            }
          }
        });
      }

      // 继续下一帧检查
      WidgetsBinding.instance.addPostFrameCallback((_) => _onFrameCallback());
    });
  }

  // Add a timeout helper function to prevent hanging during outline processing
  Future<T> _timeoutFuture<T>(Future<T> future, Duration timeout) {
    return future.timeout(timeout, onTimeout: () {
      throw Exception('轮廓处理超时');
    });
  }

  Future<void> _updateOutline() async {
    // If another update is already in progress, cancel this one
    if (_isProcessing) {
      AppLogger.debug('轮廓正在处理中，跳过更新');
      return;
    }

    // Cancel any previously scheduled debounced updates
    _updateOutlineDebounceTimer?.cancel();

    // Start a debounce timer to avoid too frequent updates
    _updateOutlineDebounceTimer =
        Timer(const Duration(milliseconds: 50), () async {
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
          threshold: eraseState.processingOptions.threshold,
          noiseReduction: eraseState.processingOptions.noiseReduction,
          showContour: true,
        );

        final fullImageRect = Rect.fromLTWH(
          0,
          0,
          widget.image.width.toDouble(),
          widget.image.height.toDouble(),
        );

        AppLogger.debug('轮廓处理选项', data: {
          'inverted': options.inverted,
          'threshold': options.threshold,
          'noiseReduction': options.noiseReduction,
          'showContour': options.showContour,
          'imageSize': '${widget.image.width}x${widget.image.height}'
        });

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

        // Use a timeout to prevent hanging if outline detection takes too long
        final result = await _timeoutFuture(
            imageProcessor.processForPreview(
              imageBytes,
              fullImageRect,
              options,
              erasePaths,
              rotation: 0.0, // 图像内容已经旋转过，不需要再次旋转
            ),
            const Duration(seconds: 5));

        print('轮廓处理完成');

        if (mounted) {
          setState(() {
            _outline = result.outline;
            _isProcessing = false;
          });

          if (_layerStackKey.currentState != null) {
            final showContour = ref.read(eraseStateProvider).showContour;
            print(
                '传递轮廓数据到 EraseLayerStack, 显示=$showContour, 轮廓数据是否存在=${_outline != null}');

            // Only set outline if showing contours is enabled AND outline has valid data
            if (showContour &&
                _outline != null &&
                _outline!.contourPoints.isNotEmpty) {
              print('轮廓包含 ${_outline!.contourPoints.length} 个轮廓路径');
              _layerStackKey.currentState!.setOutline(_outline);
            } else {
              // Clear outline when toggled off or outline is invalid
              _layerStackKey.currentState!.setOutline(null);
            }

            // // Convert img.Image to ui.Image before updating
            // final imageBytes = img.encodePng(result.processedImage);
            // ui.decodeImageFromList(imageBytes, (uiImage) {
            //   if (mounted && _layerStackKey.currentState != null) {
            //     _layerStackKey.currentState!.updateImage(uiImage);
            //   }
            // });
          }
        }
      } catch (e, stack) {
        print('轮廓检测失败: $e');
        AppLogger.error('轮廓检测失败', error: e, stackTrace: stack);
        if (kDebugMode) {
          print('错误堆栈: $stack');
        }

        // Make sure to reset state on error
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    });
  }

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
    } catch (e, stack) {
      AppLogger.error('更新坐标转换器失败', error: e, stackTrace: stack, data: {
        'imageSize': '${widget.image.width}x${widget.image.height}',
        'viewportSize': '${viewportSize.width}x${viewportSize.height}',
      });
    }
  }
}
