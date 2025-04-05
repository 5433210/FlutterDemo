import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_options.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../../providers/debug/debug_options_provider.dart';
import 'adjustable_region_painter.dart';
import 'debug_overlay.dart';
import 'regions_painter.dart';
import 'selection_painters.dart';
import 'selection_toolbar.dart';

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
  String? _lastImageId;

  bool _isFirstLoad = true;

  bool _isInSelectionMode = false;
  bool _isPanning = false;
  bool _isZoomed = false;

  // 选区相关
  Offset? _selectionStart;
  Offset? _selectionCurrent;
  Rect? _lastCompletedSelection;
  bool _hasCompletedSelection = false;

  // 调整相关
  bool _isAdjusting = false;
  String? _adjustingRegionId;
  int? _activeHandleIndex;
  List<Offset>? _guideLines;
  CharacterRegion? _originalRegion;
  Rect? _adjustingRect;
  String? _hoveredRegionId;

  bool _mounted = true;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);
    final characterCollection = ref.watch(characterCollectionProvider);
    final regions = characterCollection.regions;
    final selectedIds = characterCollection.selectedIds;
    final debugOptions = ref.watch(debugOptionsProvider);

    // 工具模式变化时重置状态
    final wasInSelectionMode = _isInSelectionMode;
    _isInSelectionMode = toolMode == Tool.select;

    if (wasInSelectionMode && !_isInSelectionMode) {
      AppLogger.debug('退出选择模式，重置选区状态');
      _resetSelectionState();
    }

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

          // 检查是否需要更新transformer
          _updateTransformer(
            imageSize: imageSize,
            viewportSize: viewportSize,
            enableLogging: debugOptions.enableLogging,
          );

          return Material(
            // 添加Material widget以支持elevation效果
            color: Colors.transparent,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImageLayer(imageState, regions, selectedIds),
                if (_transformer != null && debugOptions.enabled)
                  _buildDebugLayer(
                      debugOptions, regions, selectedIds, viewportSize),
                _buildSelectionToolLayer(),
                _buildUILayer(debugOptions),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 不在这里触发数据加载，改为观察图像状态变化
  }

  @override
  void dispose() {
    _mounted = false;
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

    // 监听图像状态变化来触发选区数据加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final imageState = ref.read(workImageProvider);
      _lastImageId = '${imageState.workId}-${imageState.currentPageId}';
      if (imageState.hasValidImage) {
        _tryLoadCharacterData();
      }
    });
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

  /// 构建错误显示
  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    AppLogger.error('图片加载失败', error: error, stackTrace: stackTrace);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            '无法加载图片: ${error.toString()}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建图像帧
  Widget _buildImageFrame(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (frame != null && !wasSynchronouslyLoaded) {
      // 只在异步加载完成时触发一次
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_mounted) return;
        final imageState = ref.read(workImageProvider);
        final currentImageId =
            '${imageState.workId}-${imageState.currentPageId}';
        if (_lastImageId != currentImageId) {
          _handleImageLoaded(imageState);
        }
      });

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: child,
      );
    }

    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(height: 16),
          Text('正在加载图片...', style: TextStyle(color: Colors.grey)),
        ],
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
      child: Stack(
        children: [
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1,
            maxScale: 10.0,
            scaleEnabled: true,
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
                  frameBuilder: _buildImageFrame,
                  errorBuilder: _buildErrorWidget,
                ),
              ],
            ),
          ),
          if (_transformer != null && regions.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: RegionsPainter(
                  regions: regions,
                  selectedIds: selectedIds,
                  transformer: _transformer!,
                  hoveredId: _hoveredRegionId,
                ),
              ),
            ),
          // 添加点击和悬停检测层
          Positioned.fill(
            child: _buildRegionInteractionLayer(regions),
          ),
        ],
      ),
    );
  }

  // 处理选区点击
  // 构建选区交互层
  Widget _buildRegionInteractionLayer(List<CharacterRegion> regions) {
    return MouseRegion(
      onHover: (event) {
        final hitRegion = _hitTestRegion(event.localPosition, regions);
        setState(() {
          _hoveredRegionId = hitRegion?.id;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredRegionId = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          final hitRegion = _hitTestRegion(details.localPosition, regions);
          if (hitRegion != null) {
            _handleRegionTap(hitRegion.id);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildSelectionToolLayer() {
    if (_transformer == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        // 选区创建层
        if (_isInSelectionMode && !_isAdjusting)
          Positioned.fill(
            child: GestureDetector(
              onPanStart: _handleSelectionStart,
              onPanUpdate: _handleSelectionUpdate,
              onPanEnd: _handleSelectionEnd,
              onTapDown: (details) {
                final hitIndex = _hitTestHandle(details.localPosition);
                if (hitIndex != null) {
                  setState(() {
                    _activeHandleIndex = hitIndex;
                  });
                }
              },
              behavior: HitTestBehavior.translucent,
              child: MouseRegion(
                cursor: _activeHandleIndex != null
                    ? SystemMouseCursors.move
                    : SystemMouseCursors.precise,
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

        // 活动选框层
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

        // 移除已完成选区层的显示，因为选区会立即创建到regions中

        // 调整选区层
        if (_isAdjusting &&
            _adjustingRegionId != null &&
            _adjustingRect != null)
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                if (_activeHandleIndex != null) {
                  _handleHandleDrag(details, _activeHandleIndex!);
                }
              },
              onPanEnd: (_) {
                setState(() {
                  _activeHandleIndex = null;
                });
              },
              behavior: HitTestBehavior.translucent,
              child: CustomPaint(
                painter: AdjustableRegionPainter(
                  region: CharacterRegion.create(
                    pageId: '',
                    rect: _adjustingRect!,
                    options: const ProcessingOptions(),
                  ),
                  transformer: _transformer!,
                  isAdjusting: true,
                  guideLines: _guideLines,
                ),
                size: _transformer!.viewportSize,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUILayer(DebugOptions debugOptions) {
    // 记录选区调整状态
    // AppLogger.debug('构建UI层', data: {
    //   'isAdjusting': _isAdjusting,
    //   'adjustingRegionId': _adjustingRegionId,
    //   'hasAdjustingRect': _adjustingRect != null,
    // });

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (_isAdjusting)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectionToolbar(
                    onConfirm: () {
                      AppLogger.debug('确认选区调整');
                      _finishAdjusting();
                    },
                    onCancel: () {
                      AppLogger.debug('取消选区调整');
                      _cancelAdjusting();
                    },
                    onDelete: () {
                      if (_adjustingRegionId != null) {
                        AppLogger.debug('删除选区', data: {
                          'regionId': _adjustingRegionId,
                        });
                        ref
                            .read(characterCollectionProvider.notifier)
                            .deleteRegion(_adjustingRegionId!);
                        _cancelAdjusting();
                      }
                    },
                  ),
                ),
              ),
            ),
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
      ),
    );
  }

  // 计算对齐参考线
  List<Offset> _calculateGuideLines(Rect rect) {
    final guides = <Offset>[];
    final regions = ref.read(characterCollectionProvider).regions;

    for (final other in regions) {
      if (other.id == _adjustingRegionId) continue;

      // 水平对齐
      if ((rect.top - other.rect.top).abs() < 5) {
        guides.add(Offset(0, other.rect.top));
      }
      if ((rect.bottom - other.rect.bottom).abs() < 5) {
        guides.add(Offset(0, other.rect.bottom));
      }

      // 垂直对齐
      if ((rect.left - other.rect.left).abs() < 5) {
        guides.add(Offset(other.rect.left, 0));
      }
      if ((rect.right - other.rect.right).abs() < 5) {
        guides.add(Offset(other.rect.right, 0));
      }
    }

    return guides;
  }

  // 取消选区调整
  void _cancelAdjusting() {
    AppLogger.debug('取消选区调整', data: {
      'originalRegionId': _originalRegion?.id,
      'wasAdjusting': _isAdjusting,
      'hadAdjustingRect': _adjustingRect != null,
    });

    if (_originalRegion != null) {
      ref
          .read(characterCollectionProvider.notifier)
          .updateSelectedRegion(_originalRegion!);
    }
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _activeHandleIndex = null;
      _guideLines = null;
      _originalRegion = null;
      _adjustingRect = null;
    });
  }

  // 完成选区调整
  Future<void> _finishAdjusting() async {
    if (_adjustingRect != null && _adjustingRegionId != null) {
      final notifier = ref.read(characterCollectionProvider.notifier);
      final region = _originalRegion?.copyWith(rect: _adjustingRect!);
      if (region != null) {
        await notifier.saveCurrentRegion();
      }
    }
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _activeHandleIndex = null;
      _guideLines = null;
      _originalRegion = null;
      _adjustingRect = null;
    });
  }

  /// 获取更新transformer的原因，用于调试
  String _getUpdateReason(
    Size imageSize,
    Size viewportSize,
    CoordinateTransformer? oldTransformer,
  ) {
    if (oldTransformer == null) return 'initial';
    if (oldTransformer.imageSize != imageSize) return 'image_size_changed';
    if (oldTransformer.viewportSize != viewportSize)
      return 'viewport_size_changed';
    return 'unknown';
  }

  // 处理控制点拖动
  void _handleHandleDrag(DragUpdateDetails details, int handleIndex) {
    if (_adjustingRect == null) return;

    final delta = details.delta;
    final matrix = _transformationController.value.clone();
    matrix.invert();
    final scale = matrix.getMaxScaleOnAxis();
    final scaledDelta = Offset(delta.dx / scale, delta.dy / scale);

    Rect newRect = _adjustingRect!;
    switch (handleIndex) {
      case 0: // 左上
        newRect = Rect.fromPoints(
          _adjustingRect!.topLeft.translate(scaledDelta.dx, scaledDelta.dy),
          _adjustingRect!.bottomRight,
        );
        break;
      case 1: // 上中
        newRect = Rect.fromLTRB(
          _adjustingRect!.left,
          _adjustingRect!.top + scaledDelta.dy,
          _adjustingRect!.right,
          _adjustingRect!.bottom,
        );
        break;
      case 2: // 右上
        newRect = Rect.fromPoints(
          _adjustingRect!.bottomLeft,
          Offset(_adjustingRect!.right + scaledDelta.dx,
              _adjustingRect!.top + scaledDelta.dy),
        );
        break;
      case 3: // 右中
        newRect = Rect.fromLTRB(
          _adjustingRect!.left,
          _adjustingRect!.top,
          _adjustingRect!.right + scaledDelta.dx,
          _adjustingRect!.bottom,
        );
        break;
      case 4: // 右下
        newRect = Rect.fromPoints(
          _adjustingRect!.topLeft,
          _adjustingRect!.bottomRight.translate(scaledDelta.dx, scaledDelta.dy),
        );
        break;
      case 5: // 下中
        newRect = Rect.fromLTRB(
          _adjustingRect!.left,
          _adjustingRect!.top,
          _adjustingRect!.right,
          _adjustingRect!.bottom + scaledDelta.dy,
        );
        break;
      case 6: // 左下
        newRect = Rect.fromPoints(
          Offset(_adjustingRect!.left + scaledDelta.dx,
              _adjustingRect!.bottom + scaledDelta.dy),
          _adjustingRect!.topRight,
        );
        break;
      case 7: // 左中
        newRect = Rect.fromLTRB(
          _adjustingRect!.left + scaledDelta.dx,
          _adjustingRect!.top,
          _adjustingRect!.right,
          _adjustingRect!.bottom,
        );
        break;
    }

    _updateAdjustingRegion(newRect);
  }

  /// 处理图片加载完成事件
  /// 更新图像数据并触发选区加载
  Future<void> _handleImageLoaded(WorkImageState imageState) async {
    if (!_mounted) return;

    final currentImageId = '${imageState.workId}-${imageState.currentPageId}';
    final provider = ref.read(characterCollectionProvider);
    final notifier = ref.read(characterCollectionProvider.notifier);

    try {
      AppLogger.debug('处理图片加载完成', data: {
        'workId': imageState.workId,
        'pageId': imageState.currentPageId,
        'imageSize': '${imageState.imageWidth}x${imageState.imageHeight}',
      });

      // 避免重复处理
      if (_lastImageId == currentImageId) {
        AppLogger.debug('跳过重复的图片处理', data: {
          'imageId': currentImageId,
        });
        return;
      }

      // 1. 设置图像数据并加载选区数据
      notifier.setCurrentPageImage(imageState.imageData!);
      await _tryLoadCharacterData();

      // 2. 更新状态标记
      _lastImageId = currentImageId;

      // 3. 重置视图状态
      if (_mounted) {
        setState(() {
          _isFirstLoad = false;
          _isZoomed = false;
          _isPanning = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('处理图片加载失败', error: e, stackTrace: stack, data: {
        'workId': imageState.workId,
        'pageId': imageState.currentPageId,
        'imageId': currentImageId,
      });

      // 清理错误状态
      if (_mounted) {
        notifier.clearState();
        setState(() {
          _isFirstLoad = true;
          _isZoomed = false;
          _isPanning = false;
        });
      }
    }
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

    // Debug模式切换
    if (event.logicalKey == LogicalKeyboardKey.keyD &&
        HardwareKeyboard.instance.isAltPressed) {
      ref.read(debugOptionsProvider.notifier).toggleDebugMode();
      return KeyEventResult.handled;
    }

    // 选区相关快捷键
    if (_adjustingRegionId != null) {
      // 微调
      final delta = HardwareKeyboard.instance.isShiftPressed ? 10.0 : 1.0;
      Rect? newRect;

      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          newRect = _adjustingRect?.translate(-delta, 0);
          break;
        case LogicalKeyboardKey.arrowRight:
          newRect = _adjustingRect?.translate(delta, 0);
          break;
        case LogicalKeyboardKey.arrowUp:
          newRect = _adjustingRect?.translate(0, -delta);
          break;
        case LogicalKeyboardKey.arrowDown:
          newRect = _adjustingRect?.translate(0, delta);
          break;
        case LogicalKeyboardKey.escape:
          _cancelAdjusting();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.enter:
          _finishAdjusting();
          return KeyEventResult.handled;
        case LogicalKeyboardKey.delete:
        case LogicalKeyboardKey.backspace:
          if (_adjustingRegionId != null) {
            ref
                .read(characterCollectionProvider.notifier)
                .deleteRegion(_adjustingRegionId!);
            _cancelAdjusting();
          }
          return KeyEventResult.handled;
        default:
          break;
      }

      if (newRect != null) {
        _updateAdjustingRegion(newRect);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    try {
      // 获取鼠标相对于视口的位置
      final box = context.findRenderObject() as RenderBox;
      final localPosition = box.globalToLocal(event.position);
      final delta = event.scrollDelta.dy;

      // 计算目标缩放比例
      final currentScale = _transformer?.currentScale ?? 1.0;
      final baseScale = _transformer?.baseScale ?? 1.0;
      var targetScale = (currentScale - delta * 0.001).clamp(0.1, 10.0);

      if (targetScale < baseScale * 0.2) {
        targetScale = baseScale * 0.2;
      }

      final scaleChange = targetScale / currentScale;

      if (delta.abs() > 0) {
        setState(() {
          // 获取当前变换矩阵并应用缩放
          final matrix = Matrix4.copy(_transformationController.value);

          // 移动原点到鼠标位置
          matrix.translate(localPosition.dx, localPosition.dy);
          matrix.scale(scaleChange, scaleChange);
          matrix.translate(-localPosition.dx, -localPosition.dy);

          _transformationController.value = matrix;
          _isZoomed = targetScale > 1.05;
        });

        AppLogger.debug('缩放变换', data: {
          'scale': targetScale,
          'mousePosition': '${localPosition.dx},${localPosition.dy}'
        });
      }
    } catch (e) {
      AppLogger.error('滚轮缩放失败', error: e);
    }
  }

  void _handleRegionCreated(Rect rect) {
    try {
      AppLogger.debug('框选完成，创建新选区', data: {
        'rect': '${rect.left},${rect.top},${rect.width}x${rect.height}',
      });

      // 创建选区
      final notifier = ref.read(characterCollectionProvider.notifier);
      notifier.createRegion(rect);

      // 清理所有临时选区状态
      setState(() {
        _lastCompletedSelection = null;
        _hasCompletedSelection = false;
      });
    } catch (e) {
      AppLogger.error('创建选区失败', error: e);
    }
  }

  void _handleRegionTap(String id) {
    final toolMode = ref.read(toolModeProvider);

    // 在任何工具模式下都允许选择，但只在select模式下允许调整
    final notifier = ref.read(characterCollectionProvider.notifier);
    final region = notifier.state.regions.firstWhere((r) => r.id == id);

    // 先选中区域
    notifier.selectRegion(id);

    // 在选择模式下启用调整功能
    if (toolMode == Tool.select) {
      setState(() {
        _isAdjusting = true;
        _adjustingRegionId = id;
        _originalRegion = region;
        _adjustingRect = region.rect;
        _selectionStart = null;
        _selectionCurrent = null;
        _hasCompletedSelection = false;
      });

      AppLogger.debug('选区进入调整模式', data: {
        'regionId': id,
        'isAdjusting': _isAdjusting,
        'rect':
            '${_adjustingRect!.left},${_adjustingRect!.top},${_adjustingRect!.width}x${_adjustingRect!.height}',
      });
    }
  }

  void _handleSelectionEnd(DragEndDetails details) {
    if (!_isInSelectionMode ||
        _selectionStart == null ||
        _selectionCurrent == null) {
      _resetSelectionState();
      return;
    }

    try {
      final dragDistance = (_selectionCurrent! - _selectionStart!).distance;
      if (dragDistance < 5) {
        _resetSelectionState();
        return;
      }

      // 直接使用鼠标位置创建视口中的矩形
      final viewportRect =
          Rect.fromPoints(_selectionStart!, _selectionCurrent!);

      // 将视口矩形转换为图像坐标系中的矩形
      final rect = _transformer!.viewportRectToImageRect(viewportRect);

      AppLogger.debug('框选矩形', data: {
        'viewport':
            '${viewportRect.left},${viewportRect.top},${viewportRect.width}x${viewportRect.height}',
        'image': '${rect.left},${rect.top},${rect.width}x${rect.height}'
      });

      if (rect.width >= 20.0 && rect.height >= 20.0) {
        _handleRegionCreated(rect);
      }

      // 完全重置选区状态
      _resetSelectionState();
    } catch (e) {
      AppLogger.error('【框选调试】发生错误', error: e);
      _resetSelectionState();
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

  // 检测点击是否在控制点上
  int? _hitTestHandle(Offset position) {
    if (_adjustingRect == null || _transformer == null) return null;

    final viewportRect = _transformer!.imageRectToViewportRect(_adjustingRect!);
    final handles = [
      viewportRect.topLeft,
      viewportRect.topCenter,
      viewportRect.topRight,
      viewportRect.centerRight,
      viewportRect.bottomRight,
      viewportRect.bottomCenter,
      viewportRect.bottomLeft,
      viewportRect.centerLeft,
    ];

    for (var i = 0; i < handles.length; i++) {
      final handleRect = Rect.fromCenter(
        center: handles[i],
        width: 16,
        height: 16,
      );
      if (handleRect.contains(position)) {
        return i;
      }
    }
    return null;
  }

  // 检测点击位置是否在选区内
  CharacterRegion? _hitTestRegion(
      Offset position, List<CharacterRegion> regions) {
    if (_transformer == null) return null;

    // 从后向前检测，使最上层的选区优先响应
    for (final region in regions.reversed) {
      final rect = _transformer!.imageRectToViewportRect(region.rect);
      if (rect.contains(position)) {
        return region;
      }
    }
    return null;
  }

  void _initializeView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetView(animate: false);
    });
  }

  /// 重置所有选区相关状态
  void _resetSelectionState() {
    if (_isAdjusting) {
      _cancelAdjusting();
    }
    setState(() {
      _selectionStart = null;
      _selectionCurrent = null;
      _lastCompletedSelection = null;
      _hasCompletedSelection = false;
      _activeHandleIndex = null;
      _hoveredRegionId = null;
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

  Future<void> _tryLoadCharacterData() async {
    if (!_mounted) return;

    final imageState = ref.read(workImageProvider);
    final currentImageId = '${imageState.workId}-${imageState.currentPageId}';

    try {
      // 状态检查和记录
      AppLogger.debug('准备加载选区数据', data: {
        'currentImageId': currentImageId,
        'lastImageId': _lastImageId,
        'hasValidImage': imageState.hasValidImage,
        'workId': imageState.workId,
        'pageId': imageState.currentPageId,
      });

      // 验证条件
      if (!imageState.hasValidImage ||
          imageState.workId.isEmpty ||
          imageState.currentPageId.isEmpty) {
        AppLogger.debug('加载条件不满足，跳过选区数据加载');
        return;
      }

      // 避免重复加载
      if (currentImageId == _lastImageId) {
        AppLogger.debug('检测到重复加载请求，跳过', data: {'imageId': currentImageId});
        return;
      }

      // 清理当前状态
      ref.read(characterCollectionProvider.notifier).clearSelectedRegions();

      // 加载新数据
      AppLogger.debug('开始加载新选区数据', data: {
        'workId': imageState.workId,
        'pageId': imageState.currentPageId,
      });

      await ref.read(characterCollectionProvider.notifier).loadWorkData(
            imageState.workId,
            pageId: imageState.currentPageId,
          );

      // 更新标记并记录
      if (_mounted) {
        _lastImageId = currentImageId;
        AppLogger.debug('选区数据加载完成', data: {
          'imageId': currentImageId,
          'regionsCount': ref.read(characterCollectionProvider).regions.length,
        });
      }
    } catch (e, stack) {
      AppLogger.error(
        '加载选区数据失败',
        error: e,
        stackTrace: stack,
        data: {'imageId': currentImageId},
      );

      // 清理错误状态
      if (_mounted) {
        ref.read(characterCollectionProvider.notifier).clearState();
      }
    }
  }

  // 更新调整中的选区
  void _updateAdjustingRegion(Rect newRect) {
    if (_adjustingRegionId == null || _originalRegion == null) return;

    // 检查最小尺寸
    if (newRect.width < 20 || newRect.height < 20) return;

    setState(() {
      _adjustingRect = newRect;
      _guideLines = _calculateGuideLines(newRect);
    });

    // 更新预览
    final updatedRegion = _originalRegion!.copyWith(rect: newRect);
    ref
        .read(characterCollectionProvider.notifier)
        .updateSelectedRegion(updatedRegion);
  }

  /// 更新或创建CoordinateTransformer
  /// 只在必要时创建新的实例以优化性能
  void _updateTransformer({
    required Size imageSize,
    required Size viewportSize,
    required bool enableLogging,
  }) {
    try {
      final needsUpdate = _transformer == null ||
          _transformer!.imageSize != imageSize ||
          _transformer!.viewportSize != viewportSize;

      if (needsUpdate) {
        final oldScale = _transformer?.currentScale;
        final oldTransformer = _transformer;

        _transformer = CoordinateTransformer(
          transformationController: _transformationController,
          imageSize: imageSize,
          viewportSize: viewportSize,
          enableLogging: enableLogging,
        );

        AppLogger.debug('更新CoordinateTransformer', data: {
          'imageSize': '${imageSize.width}x${imageSize.height}',
          'viewportSize': '${viewportSize.width}x${viewportSize.height}',
          'previousScale': oldScale?.toStringAsFixed(3) ?? 'null',
          'currentScale': _transformer!.currentScale.toStringAsFixed(3),
          'reason': _getUpdateReason(imageSize, viewportSize, oldTransformer),
        });
      }
    } catch (e, stack) {
      AppLogger.error('更新CoordinateTransformer失败',
          error: e,
          stackTrace: stack,
          data: {
            'imageSize': '${imageSize.width}x${imageSize.height}',
            'viewportSize': '${viewportSize.width}x${viewportSize.height}',
          });
    }
  }
}
