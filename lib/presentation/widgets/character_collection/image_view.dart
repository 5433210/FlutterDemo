import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../../providers/debug/debug_options_provider.dart';
import 'debug_overlay.dart';
import 'regions_painter.dart';
import 'selection_painters.dart';

/// 图像查看组件
class ImageView extends ConsumerStatefulWidget {
  const ImageView({Key? key}) : super(key: key);

  @override
  ConsumerState<ImageView> createState() => _ImageViewState();
}

class _DebugModeToggle extends ConsumerWidget {
  final bool enabled;

  const _DebugModeToggle({
    required this.enabled,
  });

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
  void dispose() {
    _animationController?.dispose();
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
        panEnabled: !_isInSelectionMode,
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
                  painter: RegionsPainter(
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
        if (_isInSelectionMode)
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
        if (_selectionStart != null && _selectionCurrent != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ActiveSelectionPainter(
                  startPoint: _selectionStart!,
                  endPoint: _selectionCurrent!,
                  viewportSize: _transformer!.viewportSize,
                ),
                size: _transformer!.viewportSize,
              ),
            ),
          ),
        if (_transformer != null &&
            _hasCompletedSelection &&
            _lastCompletedSelection != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: CompletedSelectionPainter(
                  rect: _lastCompletedSelection!,
                  transformer: _transformer!,
                  viewportSize: _transformer!.viewportSize,
                ),
                size: _transformer!.viewportSize,
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

  void _handleInteractionEnd(ScaleEndDetails details) {
    if (_isInSelectionMode) return;
    setState(() => _isPanning = false);
    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    if (_isInSelectionMode) return;
    setState(() => _isPanning = true);
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    if (_isInSelectionMode) return;
    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyD &&
        HardwareKeyboard.instance.isAltPressed) {
      ref.read(debugOptionsProvider.notifier).toggleDebugMode();
      return KeyEventResult.handled;
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

      // 转换到图像坐标
      final viewStart = _transformer!.mouseToViewCoordinate(_selectionStart!);
      final viewEnd = _transformer!.mouseToViewCoordinate(_selectionCurrent!);

      // 创建并规范化矩形
      final rect = _transformer!
          .viewRectToImageRect(Rect.fromPoints(viewStart, viewEnd));

      if (rect.width >= 20.0 && rect.height >= 20.0) {
        setState(() {
          _lastCompletedSelection = rect;
          _hasCompletedSelection = true;
        });

        _handleRegionCreated(rect);

        // 重置选择状态但保持选择模式
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
    if (!_isInSelectionMode) return;

    setState(() {
      _selectionStart = details.localPosition;
      _selectionCurrent = details.localPosition;
      _hasCompletedSelection = false;
      _lastCompletedSelection = null;
    });
  }

  void _handleSelectionUpdate(DragUpdateDetails details) {
    if (!_isInSelectionMode || _selectionStart == null) return;

    setState(() {
      _selectionCurrent = details.localPosition;
    });
  }

  void _initializeView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetView(animate: false);
    });
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
