import 'dart:math' as math;
import 'dart:ui';

import 'package:demo/infrastructure/logging/logging.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SelectionOverlay;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../../providers/debug/debug_options_provider.dart';
import 'debug_overlay.dart';
import 'debug_toolbar.dart';

/// 图像查看组件
class ImageView extends ConsumerStatefulWidget {
  const ImageView({Key? key}) : super(key: key);

  @override
  ConsumerState<ImageView> createState() => _ImageViewState();
}

class _ActiveSelectionPainter extends CustomPainter {
  final Offset startPoint;
  final Offset endPoint;

  const _ActiveSelectionPainter({
    required this.startPoint,
    required this.endPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      final selectionRect = Rect.fromPoints(startPoint, endPoint);

      canvas.drawRect(
        selectionRect,
        Paint()
          ..color = Colors.blue.withOpacity(0.1)
          ..style = PaintingStyle.fill,
      );

      canvas.drawRect(
        selectionRect,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      const handleSize = 6.0;
      final handlePaint = Paint()..color = Colors.blue;

      final corners = [
        selectionRect.topLeft,
        selectionRect.topRight,
        selectionRect.bottomLeft,
        selectionRect.bottomRight,
      ];

      for (var corner in corners) {
        canvas.drawRect(
          Rect.fromCenter(
            center: corner,
            width: handleSize,
            height: handleSize,
          ),
          handlePaint,
        );
      }
    } catch (e) {}
  }

  @override
  bool shouldRepaint(covariant _ActiveSelectionPainter oldDelegate) {
    return startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint;
  }
}

class _CompletedSelectionPainter extends CustomPainter {
  final Rect rect;
  final CoordinateTransformer transformer;

  const _CompletedSelectionPainter({
    required this.rect,
    required this.transformer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    try {
      // 添加调试输出
      AppLogger.debug(
          '【绘制调试】原始图像矩形: ${rect.left},${rect.top},${rect.width}x${rect.height}');

      // 从图像坐标转换到视口坐标
      final viewportRect = transformer.imageRectToViewportRect(rect);

      AppLogger.debug(
          '【绘制调试】转换后视口矩形: ${viewportRect.left},${viewportRect.top},${viewportRect.width}x${viewportRect.height}');

      // 先绘制填充（在边框下方）
      canvas.drawRect(
        viewportRect,
        Paint()
          ..color = Colors.blue.withOpacity(0.15)
          ..style = PaintingStyle.fill,
      );

      // 再绘制边框（在填充上方）
      canvas.drawRect(
        viewportRect,
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // 绘制角点手柄
      const handleSize = 8.0;
      final handlePaint = Paint()..color = Colors.blue;

      final corners = [
        viewportRect.topLeft,
        viewportRect.topRight,
        viewportRect.bottomLeft,
        viewportRect.bottomRight,
      ];

      for (var corner in corners) {
        canvas.drawRect(
          Rect.fromCenter(
            center: corner,
            width: handleSize,
            height: handleSize,
          ),
          handlePaint,
        );
      }

      // 绘制坐标信息用于调试
      final textPainter = TextPainter(
        text: TextSpan(
          text:
              'IMG(${rect.left.toInt()},${rect.top.toInt()}) → VP(${viewportRect.left.toInt()},${viewportRect.top.toInt()})',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 10,
            backgroundColor: Colors.white70,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, viewportRect.topLeft.translate(0, -15));
    } catch (e) {
      AppLogger.error('【绘制调试】绘制完成选框失败', error: e);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletedSelectionPainter oldDelegate) {
    return rect != oldDelegate.rect || transformer != oldDelegate.transformer;
  }
}

class _DebugModeToggle extends ConsumerWidget {
  final bool enabled;

  const _DebugModeToggle({
    Key? key,
    required this.enabled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      onPressed: () =>
          ref.read(debugOptionsProvider.notifier).toggleDebugMode(),
      tooltip: 'Alt+D',
      backgroundColor: enabled ? Colors.blue : Colors.black87,
      child: Icon(
        enabled ? Icons.bug_report : Icons.bug_report_outlined,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _ImageViewState extends ConsumerState<ImageView>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final FocusNode _focusNode = FocusNode();
  CoordinateTransformer? _transformer;
  late final AnimationController _debugPanelController;
  late final Animation<double> _debugPanelAnimation;
  AnimationController? _animationController;
  bool _isFirstLoad = true;

  bool _isInSelectionMode = false;
  bool _isPanning = false;
  bool _isAltPressed = false;
  bool _isZoomed = false;

  Offset? _selectionStart;
  Offset? _selectionCurrent;

  Rect? _lastCompletedSelection;
  bool _hasCompletedSelection = false;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);
    final regions = ref.watch(characterCollectionProvider).regions;
    final selectedIds = ref.watch(characterCollectionProvider).selectedIds;
    final debugOptions = ref.watch(debugOptionsProvider);

    _isInSelectionMode = toolMode == Tool.select;

    if (!imageState.hasValidImage) {
      return const SizedBox.shrink();
    }

    final imageSize = Size(imageState.imageWidth, imageState.imageHeight);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize =
              Size(constraints.maxWidth, constraints.maxHeight);

          _transformer = CoordinateTransformer(
            transformationController: _transformationController,
            imageSize: imageSize,
            viewportSize: viewportSize,
            enableLogging: debugOptions.enableLogging,
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              _buildImageLayer(imageState, regions, selectedIds),
              if (_transformer != null && debugOptions.enabled)
                _buildDebugLayer(
                    debugOptions, regions, selectedIds, viewportSize),
              if (_isInSelectionMode) _buildSelectionToolLayer(),
              _buildUILayer(debugOptions),
            ],
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(ImageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 确保在布局变化时重新计算基础缩放
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_transformer != null) {
        _transformer!.recalculateBaseScale();
        AppLogger.debug('视窗大小改变，重新计算基础缩放比', data: {
          'baseScale': _transformer!.baseScale.toStringAsFixed(3),
          'currentScale': _transformer!.currentScale.toStringAsFixed(3),
          'actualScale': _transformer!.actualScale.toStringAsFixed(3),
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController?.dispose();
    HardwareKeyboard.instance.removeHandler(_handleKeyboardEvent);
    _transformationController.dispose();
    _focusNode.dispose();
    _debugPanelController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _debugPanelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _debugPanelAnimation = CurvedAnimation(
      parent: _debugPanelController,
      curve: Curves.easeInOut,
    );

    HardwareKeyboard.instance.addHandler(_handleKeyboardEvent);
    _initializeView();
  }

  void _animateMatrix(Matrix4 targetMatrix) {
    _animationController?.dispose();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    final animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    _animationController!.forward();
  }

  Widget _buildDebugControls(DebugOptions debugOptions) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _debugPanelAnimation,
          builder: (context, child) => Positioned(
            top: 8,
            right: debugOptions.enabled ? 8 : -280,
            child: AnimatedOpacity(
              opacity: _debugPanelAnimation.value,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !debugOptions.enabled,
                child: child!,
              ),
            ),
          ),
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: const SizedBox(
                  width: 280,
                  child: DebugToolbar(),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: debugOptions.enabled ? 296 : 8,
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: _DebugModeToggle(enabled: debugOptions.enabled),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDebugLayer(
    DebugOptions debugOptions,
    List<CharacterRegion> regions,
    Set<String> selectedIds,
    Size viewportSize,
  ) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: DebugOverlay(
            transformer: _transformer!,
            showGrid: debugOptions.showGrid,
            showCoordinates: debugOptions.showCoordinates,
            showDetails: debugOptions.showDetails,
            showImageInfo: debugOptions.showImageInfo,
            showRegionCenter: debugOptions.showRegionCenter,
            gridSize: debugOptions.gridSize,
            textScale: debugOptions.textScale,
            opacity: debugOptions.opacity,
            regions: regions,
            selectedIds: selectedIds,
          ),
          size: viewportSize,
        ),
      ),
    );
  }

  Widget _buildImageLayer(
    WorkImageState imageState,
    List<CharacterRegion> regions,
    Set<String> selectedIds,
  ) {
    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.1,
        maxScale: 10.0,
        panEnabled: !_isInSelectionMode || _isAltPressed,
        onInteractionStart: _handleInteractionStart,
        onInteractionUpdate: _handleInteractionUpdate,
        onInteractionEnd: _handleInteractionEnd,
        child: Stack(
          children: [
            Image.memory(
              imageState.imageData!,
              fit: BoxFit.contain,
              alignment: Alignment.topLeft,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: frame != null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('无法加载图片', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
            if (_transformer != null && regions.isNotEmpty)
              Positioned.fill(
                child: CustomPaint(
                  painter: _RegionsPainter(
                    regions: regions,
                    selectedIds: selectedIds,
                    transformer: _transformer!,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionToolLayer() {
    if (_transformer == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_isAltPressed)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _handleSelectionStart,
              onPanUpdate: _handleSelectionUpdate,
              onPanEnd: _handleSelectionEnd,
              behavior: HitTestBehavior.translucent,
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        if (_selectionStart != null &&
            _selectionCurrent != null &&
            !_isAltPressed)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ActiveSelectionPainter(
                  startPoint: _selectionStart!,
                  endPoint: _selectionCurrent!,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        if (_transformer != null &&
            _hasCompletedSelection &&
            _lastCompletedSelection != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _CompletedSelectionPainter(
                  rect: _lastCompletedSelection!,
                  transformer: _transformer!,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedOpacity(
              opacity: _isAltPressed ? 0.6 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isAltPressed ? '平移模式' : '按住Alt暂时切换至平移模式',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUILayer(DebugOptions debugOptions) {
    return Stack(
      children: [
        if (_isZoomed)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              onPressed: () => _resetView(animate: true),
              tooltip: '重置缩放',
              child: const Icon(Icons.zoom_out_map),
            ),
          ),
        _buildDebugControls(debugOptions),
      ],
    );
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    if (_isInSelectionMode && !_isAltPressed) return;

    setState(() => _isPanning = false);

    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    if (_isInSelectionMode && !_isAltPressed) return;

    setState(() => _isPanning = true);
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    if (_isInSelectionMode && !_isAltPressed) return;

    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  bool _handleKeyboardEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      setState(() {
        _isAltPressed = HardwareKeyboard.instance.isAltPressed;
      });
    }
    return false;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isAltPressed = HardwareKeyboard.instance.isAltPressed;

    if (isAltPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyD:
          ref.read(debugOptionsProvider.notifier).toggleDebugMode();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyG:
          ref.read(debugOptionsProvider.notifier).toggleGrid();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyC:
          ref.read(debugOptionsProvider.notifier).toggleCoordinates();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyI:
          ref.read(debugOptionsProvider.notifier).toggleImageInfo();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyL:
          ref.read(debugOptionsProvider.notifier).toggleLogging();
          return KeyEventResult.handled;

        default:
          return KeyEventResult.ignored;
      }
    }

    return KeyEventResult.ignored;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    if (HardwareKeyboard.instance.isControlPressed) {
      final delta = event.scrollDelta.dy;
      final currentScale = _transformer?.currentScale ?? 1.0;
      final baseScale = _transformer?.baseScale ?? 1.0;

      var targetScale = (currentScale - delta * 0.001).clamp(0.1, 10.0);

      if (targetScale < baseScale * 0.2) {
        targetScale = baseScale * 0.2;
      }

      final matrix = Matrix4.identity()..scale(targetScale, targetScale);

      if (delta.abs() > 0) {
        setState(() {
          _transformationController.value = matrix;
          _isZoomed = targetScale > 1.05;
        });
      }
    }
  }

  void _handleRegionCreated(Rect rect) {
    ref.read(characterCollectionProvider.notifier).createRegion(rect);
  }

  void _handleSelectionEnd(DragEndDetails details) {
    if (!_isInSelectionMode ||
        _isAltPressed ||
        _selectionStart == null ||
        _selectionCurrent == null) {
      setState(() {
        _selectionStart = null;
        _selectionCurrent = null;
      });
      return;
    }

    try {
      final dragDistance = (_selectionCurrent! - _selectionStart!).distance;
      if (dragDistance < 5) {
        setState(() {
          _selectionStart = null;
          _selectionCurrent = null;
        });
        return;
      }

      // 调试日志记录原始鼠标坐标 (相对于组件左上角的坐标系)
      AppLogger.debug(
          '【框选调试】鼠标坐标起点: ${_selectionStart!.dx},${_selectionStart!.dy}');
      AppLogger.debug(
          '【框选调试】鼠标坐标终点: ${_selectionCurrent!.dx},${_selectionCurrent!.dy}');
      AppLogger.debug('【框选调试】变换矩阵: ${_transformationController.value}');
      AppLogger.debug(
          '【框选调试】图像大小: ${_transformer!.imageSize.width}x${_transformer!.imageSize.height}');
      AppLogger.debug(
          '【框选调试】视图大小: ${_transformer!.viewportSize.width}x${_transformer!.viewportSize.height}');

      AppLogger.debug('【框选调试】当前缩放比例: ${_transformer!.currentScale}');
      AppLogger.debug('【框选调试】基础缩放比例: ${_transformer!.baseScale}');
      AppLogger.debug('【框选调试】实际缩放比例: ${_transformer!.actualScale}');

      // 转换到图像坐标 - 使用鼠标原始坐标，让坐标变换器内部处理转换
      final viewStart = _transformer!.mouseToViewCoordinate(_selectionStart!);
      final viewEnd = _transformer!.mouseToViewCoordinate(_selectionCurrent!);

      AppLogger.debug('【框选调试】转换后坐标起点: ${viewStart.dx},${viewStart.dy}');
      AppLogger.debug('【框选调试】转换后坐标终点: ${viewEnd.dx},${viewEnd.dy}');

      // 创建并规范化矩形
      final rect = _transformer!
          .viewRectToImageRect(Rect.fromPoints(viewStart, viewEnd));

      AppLogger.debug(
          '【框选调试】最终矩形: ${rect.left},${rect.top},${rect.right},${rect.bottom} (${rect.width}x${rect.height})');

      if (rect.width >= 20.0 && rect.height >= 20.0) {
        setState(() {
          _lastCompletedSelection = rect;
          _hasCompletedSelection = true;
          _selectionStart = null;
          _selectionCurrent = null;
        });

        _handleRegionCreated(rect);
      } else {
        setState(() {
          _selectionStart = null;
          _selectionCurrent = null;
        });
      }
    } catch (e) {
      AppLogger.error('【框选调试】发生错误', error: e);
      setState(() {
        _selectionStart = null;
        _selectionCurrent = null;
      });
    }
  }

  void _handleSelectionStart(DragStartDetails details) {
    if (!_isInSelectionMode || _isAltPressed) return;

    setState(() {
      _selectionStart = details.localPosition;
      _selectionCurrent = details.localPosition;
      _hasCompletedSelection = false;
      _lastCompletedSelection = null;
    });
  }

  void _handleSelectionUpdate(DragUpdateDetails details) {
    if (!_isInSelectionMode || _isAltPressed || _selectionStart == null) return;

    setState(() {
      _selectionCurrent = details.localPosition;
    });
  }

  void _initializeView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetView(animate: false);
    });
  }

  Rect _normalizeRect(Rect rect) {
    if (_transformer == null) return rect;

    final left = math.min(rect.left, rect.right);
    final top = math.min(rect.top, rect.bottom);
    final right = math.max(rect.left, rect.right);
    final bottom = math.max(rect.top, rect.bottom);

    final imageSize = _transformer!.imageSize;

    return Rect.fromLTRB(
      math.max(0.0, math.min(left, imageSize.width)),
      math.max(0.0, math.min(top, imageSize.height)),
      math.max(0.0, math.min(right, imageSize.width)),
      math.max(0.0, math.min(bottom, imageSize.height)),
    );
  }

  void _resetView({bool animate = true}) {
    if (_transformer == null) return;

    final viewportSize = _transformer!.viewportSize;
    final imageSize = _transformer!.imageSize;

    final viewportRatio = viewportSize.width / viewportSize.height;
    final imageRatio = imageSize.width / imageSize.height;

    double scale;
    if (viewportRatio < imageRatio) {
      scale = viewportSize.width / imageSize.width * 0.98;
    } else {
      scale = viewportSize.height / imageSize.height * 0.98;
    }

    final matrix = Matrix4.identity()..scale(scale, scale);

    if (animate && !_isFirstLoad) {
      _animateMatrix(matrix);
    } else {
      _transformationController.value = matrix;
      _isFirstLoad = false;
    }

    setState(() {
      _isZoomed = false;
    });
  }
}

class _RegionsPainter extends CustomPainter {
  final List<CharacterRegion> regions;
  final Set<String> selectedIds;
  final CoordinateTransformer transformer;

  const _RegionsPainter({
    required this.regions,
    required this.selectedIds,
    required this.transformer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final region in regions) {
      try {
        final viewportRect = transformer.imageRectToViewportRect(region.rect);
        final isSelected = selectedIds.contains(region.id);

        canvas.drawRect(
          viewportRect,
          Paint()
            ..color = isSelected ? Colors.blue : Colors.green
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 2.0 : 1.5,
        );

        if (isSelected) {
          _drawHandle(canvas, viewportRect.topLeft, Colors.blue);
          _drawHandle(canvas, viewportRect.topRight, Colors.blue);
          _drawHandle(canvas, viewportRect.bottomLeft, Colors.blue);
          _drawHandle(canvas, viewportRect.bottomRight, Colors.blue);
        }
      } catch (e) {}
    }
  }

  @override
  bool shouldRepaint(_RegionsPainter oldDelegate) {
    return regions != oldDelegate.regions ||
        selectedIds != oldDelegate.selectedIds ||
        transformer != oldDelegate.transformer;
  }

  void _drawHandle(Canvas canvas, Offset position, Color color) {
    canvas.drawCircle(
      position,
      6.0,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      position,
      6.0,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }
}
