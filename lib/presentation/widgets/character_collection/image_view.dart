import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SelectionOverlay;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../../providers/debug/debug_options_provider.dart';
import 'debug_overlay.dart';
import 'debug_toolbar.dart';
import 'selection_overlay.dart';

/// 图像查看组件
class ImageView extends ConsumerStatefulWidget {
  const ImageView({Key? key}) : super(key: key);

  @override
  ConsumerState<ImageView> createState() => _ImageViewState();
}

/// 调试模式开关按钮
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
  bool _isInSelectionMode = false;
  bool _isPanning = false;
  bool _isAltPressed = false;
  bool _isZoomed = false;

  // 添加一个字段来跟踪正在进行的动画
  AnimationController? _animationController;

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
      child: Listener(
        onPointerSignal: _handlePointerSignal,
        onPointerDown: (event) {
          if (debugOptions.enableLogging) {
            AppLogger.debug('指针按下', data: {
              'position': '${event.position.dx},${event.position.dy}',
              'toolMode': toolMode.toString(),
              'isPanning': _isPanning,
              'isAltPressed': _isAltPressed,
            });
          }
        },
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
                ColoredBox(
                  color: Colors.black.withOpacity(0.05),
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.1,
                    maxScale: 10.0,
                    panEnabled: true,
                    onInteractionStart: _handleInteractionStart,
                    onInteractionUpdate: (details) {
                      if (_isInSelectionMode && !_isAltPressed) return;

                      final scale = _transformer?.currentScale ?? 1.0;
                      setState(() {
                        _isZoomed = scale > 1.05;
                      });

                      if (debugOptions.enableLogging) {
                        AppLogger.debug('交互更新', data: {
                          'scale': details.scale.toStringAsFixed(2),
                          'isZoomed': _isZoomed,
                        });
                      }
                    },
                    onInteractionEnd: _handleInteractionEnd,
                    child: Center(
                      child: Image.memory(
                        imageState.imageData!,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        frameBuilder:
                            (context, child, frame, wasSynchronouslyLoaded) {
                          if (wasSynchronouslyLoaded) return child;

                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: frame != null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 64, color: Colors.red),
                              SizedBox(height: 16),
                              Text('无法加载图片',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_transformer != null && !_isPanning)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_isInSelectionMode,
                      child: SelectionOverlay(
                        regions: regions,
                        selectedIds: selectedIds,
                        toolMode: toolMode,
                        transformationController: _transformationController,
                        imageSize: imageSize,
                        viewportSize: viewportSize,
                        onRegionCreated: _handleRegionCreated,
                        onRegionSelected: _handleRegionSelected,
                        onRegionUpdated: _handleRegionUpdated,
                      ),
                    ),
                  ),
                if (_transformer != null && debugOptions.enabled)
                  Positioned.fill(
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
                  ),
                _buildDebugControls(debugOptions),
                if (_isInSelectionMode)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _isAltPressed ? 0.6 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 确保释放所有控制器
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

  void _handleInteractionEnd(ScaleEndDetails details) {
    if (_isInSelectionMode && !_isAltPressed) return;

    setState(() => _isPanning = false);

    final displayRect = _transformer?.displayRect;
    final viewportSize = _transformer?.viewportSize;

    if (displayRect != null && viewportSize != null) {
      final visibleArea = displayRect.overlaps(
          Rect.fromLTWH(0, 0, viewportSize.width, viewportSize.height));

      final scale = _transformer!.currentScale;
      if (!visibleArea || scale < _transformer!.baseScale * 0.2) {
        return;
      }
    }

    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });

    if (ref.read(debugOptionsProvider).enableLogging) {
      final offset = _transformer?.currentOffset ?? Offset.zero;
      AppLogger.debug('交互结束', data: {
        'scale': scale.toStringAsFixed(2),
        'offset': '${offset.dx.toInt()},${offset.dy.toInt()}',
        'isZoomed': _isZoomed,
      });
    }
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    if (_isInSelectionMode && !_isAltPressed) return;

    setState(() => _isPanning = true);

    final toolMode = ref.read(toolModeProvider);
    AppLogger.debug('开始交互', data: {
      'mode': toolMode.toString(),
      'pointerCount': details.pointerCount,
      'isAltPressed': _isAltPressed,
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

    if (_isInSelectionMode && !_isAltPressed) return;

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

      AppLogger.debug('滚轮缩放', data: {
        'delta': delta,
        'currentScale': currentScale.toStringAsFixed(2),
        'targetScale': targetScale.toStringAsFixed(2),
        'isZoomed': _isZoomed,
      });
    }
  }

  void _handleRegionCreated(Rect rect) {
    AppLogger.debug('创建新区域', data: {
      'rect':
          '${rect.left.toInt()},${rect.top.toInt()},${rect.width.toInt()},${rect.height.toInt()}'
    });

    ref.read(characterCollectionProvider.notifier).createRegion(rect);
  }

  void _handleRegionSelected(String id) {
    AppLogger.debug('选择区域', data: {'id': id});
    ref.read(characterCollectionProvider.notifier).selectRegion(id);
  }

  void _handleRegionUpdated(String id, Rect rect) {
    AppLogger.debug('更新区域', data: {
      'id': id,
      'rect':
          '${rect.left.toInt()},${rect.top.toInt()},${rect.width.toInt()},${rect.height.toInt()}'
    });
    ref.read(selectedRegionProvider.notifier).updateRect(rect);
  }

  void _initializeView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //_resetView(animate: false);
    });
  }
}
