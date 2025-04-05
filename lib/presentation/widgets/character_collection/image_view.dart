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
  bool _isRotating = false;
  double _rotationStartAngle = 0.0;
  double _currentRotation = 0.0;
  Offset? _rotationCenter;

  bool _mounted = true;

  Offset? _lastPanPosition;

  // 悬停的控制点索引
  int? _hoveredHandleIndex;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);
    final characterCollection = ref.watch(characterCollectionProvider);
    final regions = characterCollection.regions;
    final selectedIds = characterCollection.selectedIds;
    final debugOptions = ref.watch(debugOptionsProvider);

    // 处理工具模式变化
    final lastToolMode = _isInSelectionMode
        ? Tool.select
        : (_isPanning ? Tool.pan : Tool.multiSelect);
    _isInSelectionMode = toolMode == Tool.select;
    _isPanning = toolMode == Tool.pan;

    // 模式变化时重置状态
    if (lastToolMode != toolMode) {
      AppLogger.debug('工具模式变化，重置状态', data: {
        'from': lastToolMode.toString(),
        'to': toolMode.toString(),
      });
      // 使用Future延迟执行，避免在build过程中修改provider状态
      Future(() => _resetSelectionState());
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
            child: Listener(
              onPointerHover: _handleMouseMove,
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
    final toolMode = ref.watch(toolModeProvider);
    final isPanMode = toolMode == Tool.pan;
    final isSelectMode = toolMode == Tool.select;
    final isMultiSelectMode = toolMode == Tool.multiSelect;

    return MouseRegion(
      cursor: _getCursor(),
      onHover: (event) {
        // 更新悬停状态
        if (_isAdjusting && _adjustingRect != null) {
          final handleIndex = _getHandleIndexFromPosition(event.localPosition);
          setState(() {
            _hoveredHandleIndex = handleIndex;
          });
        } else {
          final hitRegion = _hitTestRegion(event.localPosition, regions);
          setState(() {
            _hoveredRegionId = hitRegion?.id;
          });
        }
      },
      onExit: (_) {
        setState(() {
          _hoveredRegionId = null;
          _hoveredHandleIndex = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          // 只在非调整模式下处理区域点击
          if (!_isAdjusting) {
            final hitRegion = _hitTestRegion(details.localPosition, regions);
            if (hitRegion != null) {
              _handleRegionTap(hitRegion.id);
            }
          }
        },
        onDoubleTap: () {
          // 双击不再需要确认调整
        },
        onPanStart: _isAdjusting
            ? null
            : (isPanMode
                ? _handlePanStart
                : isSelectMode
                    ? _handleSelectionStart
                    : null),
        onPanUpdate: _isAdjusting
            ? null
            : (isPanMode
                ? _handlePanUpdate
                : isSelectMode
                    ? _handleSelectionUpdate
                    : null),
        onPanEnd: _isAdjusting
            ? null
            : (isPanMode
                ? _handlePanEnd
                : isSelectMode
                    ? _handleSelectionEnd
                    : null),
        child: Listener(
          onPointerSignal: _handlePointerSignal,
          child: Stack(
            fit: StackFit.expand,
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 10.0,
                scaleEnabled: true,
                panEnabled: isPanMode && !_isAdjusting,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                onInteractionStart: _handleInteractionStart,
                onInteractionUpdate: _handleInteractionUpdate,
                onInteractionEnd: _handleInteractionEnd,
                child: Stack(
                  fit: StackFit.expand,
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

              // 绘制所有区域
              if (_transformer != null && regions.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _isAdjusting,
                    child: CustomPaint(
                      painter: RegionsPainter(
                        regions: regions,
                        selectedIds: selectedIds,
                        transformer: _transformer!,
                        hoveredId: _hoveredRegionId,
                      ),
                    ),
                  ),
                ),

              // **Adjustment Layer GestureDetector**
              if (_isAdjusting &&
                  _adjustingRegionId != null &&
                  _originalRegion != null)
                Positioned.fill(
                  child: GestureDetector(
                    behavior:
                        HitTestBehavior.opaque, // Capture hits within bounds
                    onPanStart:
                        _handleAdjustmentPanStart, // Use dedicated handler
                    onPanUpdate:
                        _handleAdjustmentPanUpdate, // Use dedicated handler
                    onPanEnd: _handleAdjustmentPanEnd, // Use dedicated handler
                    child: CustomPaint(
                      // Painter should ignore pointer events itself
                      painter: AdjustableRegionPainter(
                        region:
                            _originalRegion!, // Should be original image coords
                        transformer: _transformer!,
                        isActive: true,
                        isAdjusting: true,
                        activeHandleIndex: _activeHandleIndex,
                        currentRotation: _currentRotation,
                        guideLines: _guideLines,
                        // Pass the viewport rect for painting controls
                        viewportRect: _adjustingRect,
                      ),
                      size: _transformer!.viewportSize,
                    ),
                  ),
                ),

              // 添加框选层
              if (isSelectMode && !_isAdjusting)
                Positioned.fill(
                  child: GestureDetector(
                    onPanStart: _handleSelectionStart,
                    onPanUpdate: _handleSelectionUpdate,
                    onPanEnd: _handleSelectionEnd,
                    child: CustomPaint(
                      painter: ActiveSelectionPainter(
                        startPoint: _selectionStart ?? Offset.zero,
                        endPoint: _selectionCurrent ?? Offset.zero,
                        viewportSize: _transformer?.viewportSize ?? Size.zero,
                        isActive: _selectionStart != null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // 处理拖拽工具的拖拽操作
  void _handlePanStart(DragStartDetails details) {
    if (ref.read(toolModeProvider) != Tool.pan) return;

    setState(() {
      _isPanning = true;
      _lastPanPosition = details.localPosition;
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isPanning || ref.read(toolModeProvider) != Tool.pan) return;

    if (_lastPanPosition != null) {
      final delta = details.localPosition - _lastPanPosition!;
      final matrix = _transformationController.value.clone();
      matrix.translate(delta.dx, delta.dy);
      _transformationController.value = matrix;
      _lastPanPosition = details.localPosition;
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (ref.read(toolModeProvider) != Tool.pan) return;

    setState(() {
      _isPanning = false;
      _lastPanPosition = null;
    });
  }

  /// 获取更新的光标样式
  MouseCursor _getCursor() {
    final toolMode = ref.read(toolModeProvider);

    if (_isAdjusting) {
      if (_activeHandleIndex != null) {
        // 根据不同控制点返回不同光标
        switch (_activeHandleIndex) {
          case -1: // 旋转控制点
            return SystemMouseCursors.alias; // 用于旋转的光标
          case 0: // 左上角
          case 4: // 右下角
            return SystemMouseCursors.resizeUpLeftDownRight;
          case 2: // 右上角
          case 6: // 左下角
            return SystemMouseCursors.resizeUpRightDownLeft;
          case 1: // 上边中点
          case 5: // 下边中点
            return SystemMouseCursors.resizeUpDown;
          case 3: // 右边中点
          case 7: // 左边中点
            return SystemMouseCursors.resizeLeftRight;
          case 8: // 移动整个选区
            return SystemMouseCursors.move;
          default:
            return SystemMouseCursors.basic;
        }
      }

      // 检查当前悬停位置是否在某个控制点上
      if (_hoveredHandleIndex != null) {
        switch (_hoveredHandleIndex) {
          case -1: // 旋转控制点
            return SystemMouseCursors.alias; // 用于旋转的光标
          case 0: // 左上角
          case 4: // 右下角
            return SystemMouseCursors.resizeUpLeftDownRight;
          case 2: // 右上角
          case 6: // 左下角
            return SystemMouseCursors.resizeUpRightDownLeft;
          case 1: // 上边中点
          case 5: // 下边中点
            return SystemMouseCursors.resizeUpDown;
          case 3: // 右边中点
          case 7: // 左边中点
            return SystemMouseCursors.resizeLeftRight;
          case 8: // 移动整个选区
            return SystemMouseCursors.move;
          default:
            return SystemMouseCursors.basic;
        }
      }
    }

    switch (toolMode) {
      case Tool.pan:
        return _isPanning
            ? SystemMouseCursors.grabbing
            : SystemMouseCursors.grab;
      case Tool.select:
        return SystemMouseCursors.precise;
      case Tool.multiSelect:
        return SystemMouseCursors.click;
      default:
        return SystemMouseCursors.basic;
    }
  }

  // 处理鼠标移动，更新悬停状态
  void _handleMouseMove(PointerHoverEvent event) {
    if (_isAdjusting && _adjustingRect != null) {
      final handleIndex = _getHandleIndexFromPosition(event.localPosition);
      setState(() {
        _hoveredHandleIndex = handleIndex;
      });
    }
  }

  Widget _buildSelectionToolLayer() {
    if (!_isInSelectionMode || _selectionStart == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _selectionCurrent = details.localPosition;
        });
      },
      onPanEnd: (details) {
        if (_selectionStart != null && _selectionCurrent != null) {
          _handleSelectionEnd(details);
        }
      },
      child: CustomPaint(
        painter: ActiveSelectionPainter(
          startPoint: _selectionStart!,
          endPoint: _selectionCurrent ?? _selectionStart!,
          viewportSize: _transformer!.viewportSize,
        ),
      ),
    );
  }

  Widget _buildUILayer(DebugOptions debugOptions) {
    return Stack(
      children: [
        // 调试模式切换按钮
        if (debugOptions.enabled)
          Positioned(
            right: 16,
            bottom: 16,
            child: _DebugModeToggle(enabled: debugOptions.enabled),
          ),

        // 选区工具栏
        if (_hasCompletedSelection && _lastCompletedSelection != null)
          Positioned(
            left: _lastCompletedSelection!.left,
            top: _lastCompletedSelection!.top - 40,
            child: SelectionToolbar(
              onConfirm: () {
                _confirmSelection();
              },
              onCancel: () {
                _cancelSelection();
              },
              onDelete: () {
                // 删除选区的逻辑
              },
            ),
          ),

        // 尺寸指示器
        if (_isAdjusting && _adjustingRect != null)
          Positioned(
            left: _adjustingRect!.right + 8,
            top: _adjustingRect!.top,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Text(
                '${_adjustingRect!.width.round()}×${_adjustingRect!.height.round()}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // 角度指示器
        if (_isRotating && _adjustingRect != null)
          Positioned(
            left: _adjustingRect!.right + 8,
            top: _adjustingRect!.top + 30,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Text(
                '${(_currentRotation * 180 / 3.14159).round()}°',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // 计算对齐参考线
  List<Offset> _calculateGuideLines(Rect rect) {
    final guides = <Offset>[];

    // 添加水平中心线
    guides.add(Offset(rect.center.dx, 0));
    guides.add(Offset(rect.center.dx, _transformer!.viewportSize.height));

    // 添加垂直中心线
    guides.add(Offset(0, rect.center.dy));
    guides.add(Offset(_transformer!.viewportSize.width, rect.center.dy));

    // 添加水平对齐线（接近水平时）
    if (rect.height < 20) {
      guides.add(Offset(0, rect.top));
      guides.add(Offset(_transformer!.viewportSize.width, rect.top));
    }

    // 添加垂直对齐线（接近垂直时）
    if (rect.width < 20) {
      guides.add(Offset(rect.left, 0));
      guides.add(Offset(rect.left, _transformer!.viewportSize.height));
    }

    return guides;
  }

  // 取消选区调整
  void _cancelAdjustment() {
    AppLogger.debug('取消选区调整', data: {
      'originalRegionId': _originalRegion?.id,
      'wasAdjusting': _isAdjusting,
      'hadAdjustingRect': _adjustingRect != null,
    });

    // 使用Future延迟更新provider状态
    if (_originalRegion != null) {
      Future(() {
        if (_mounted) {
          ref
              .read(characterCollectionProvider.notifier)
              .updateSelectedRegion(_originalRegion!);
        }
      });
    }

    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _activeHandleIndex = null;
      _guideLines = null;
      _originalRegion = null;
      _adjustingRect = null;
      _isRotating = false;
      _currentRotation = 0.0;
      _rotationCenter = null;
    });
  }

  void _confirmAdjustment() {
    if (!_isAdjusting ||
        _adjustingRegionId == null ||
        _adjustingRect == null ||
        _originalRegion == null) {
      return;
    }

    final imageRect = _transformer!.viewportRectToImageRect(_adjustingRect!);

    // 使用Future延迟更新provider状态
    Future(() {
      if (_mounted) {
        // 创建更新后的区域
        final updatedRegion = _originalRegion!.copyWith(
          rect: imageRect,
          rotation: _currentRotation,
          updateTime: DateTime.now(),
        );

        // 更新区域
        ref
            .read(characterCollectionProvider.notifier)
            .updateSelectedRegion(updatedRegion);
      }
    });

    // 重置状态
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _activeHandleIndex = null;
      _guideLines = null;
      _originalRegion = null;
      _adjustingRect = null;
      _isRotating = false;
      _currentRotation = 0.0;
      _rotationCenter = null;
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

  void _handleInteractionStart(ScaleStartDetails details) {
    final toolMode = ref.read(toolModeProvider);
    final isPanMode = toolMode == Tool.pan;

    // 如果是拖拽工具模式，启用平移
    if (isPanMode) {
      setState(() {
        _isPanning = true;
        _lastPanPosition = details.localFocalPoint;
      });
    }
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    final toolMode = ref.read(toolModeProvider);
    final isPanMode = toolMode == Tool.pan;

    // 如果是拖拽工具模式且正在平移，处理平移逻辑
    if (isPanMode && _isPanning && _lastPanPosition != null) {
      final delta = details.localFocalPoint - _lastPanPosition!;
      final matrix = _transformationController.value.clone();
      matrix.translate(delta.dx, delta.dy);
      _transformationController.value = matrix;
      _lastPanPosition = details.localFocalPoint;
    }

    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    // 结束平移
    setState(() {
      _isPanning = false;
      _lastPanPosition = null;
    });

    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Debug模式切换 (Alt+D)
    if (event.logicalKey == LogicalKeyboardKey.keyD &&
        HardwareKeyboard.instance.isAltPressed) {
      ref.read(debugOptionsProvider.notifier).toggleDebugMode();
      return KeyEventResult.handled;
    }

    // ESC键退出调整模式
    if (event.logicalKey == LogicalKeyboardKey.escape && _isAdjusting) {
      // 退出调整模式
      _cancelAdjustment();
      return KeyEventResult.handled;
    }

    // 工具切换快捷键
    if (!HardwareKeyboard.instance.isControlPressed &&
        !HardwareKeyboard.instance.isAltPressed) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.keyV:
          ref.read(toolModeProvider.notifier).setMode(Tool.pan);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyR:
          ref.read(toolModeProvider.notifier).setMode(Tool.select);
          return KeyEventResult.handled;
        case LogicalKeyboardKey.keyM:
          ref.read(toolModeProvider.notifier).setMode(Tool.multiSelect);
          return KeyEventResult.handled;
      }
    }

    // 选区操作快捷键
    if (_adjustingRegionId != null) {
      // 微调 (Shift 时移动距离更大)
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
        case LogicalKeyboardKey.delete:
        case LogicalKeyboardKey.backspace:
          if (_adjustingRegionId != null) {
            ref
                .read(characterCollectionProvider.notifier)
                .deleteRegion(_adjustingRegionId!);
            _cancelAdjustment();
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

    // 删除已选中区域 (Delete/Backspace)
    if (!_isAdjusting &&
        (event.logicalKey == LogicalKeyboardKey.delete ||
            event.logicalKey == LogicalKeyboardKey.backspace)) {
      final selectedIds = ref.read(characterCollectionProvider).selectedIds;
      if (selectedIds.isNotEmpty) {
        ref
            .read(characterCollectionProvider.notifier)
            .deleteBatchRegions(selectedIds.toList());
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
    final notifier = ref.read(characterCollectionProvider.notifier);
    final state = ref.read(characterCollectionProvider);
    final region = state.regions.firstWhere((r) => r.id == id);

    switch (toolMode) {
      case Tool.select:
        // 选择模式：单选并启用调整功能
        notifier.selectRegion(id);
        setState(() {
          _isAdjusting = true;
          _adjustingRegionId = id;
          _originalRegion = region;
          // 将图像坐标系中的矩形转换为视口坐标系
          _adjustingRect = _transformer!.imageRectToViewportRect(region.rect);
          _currentRotation = region.rotation;
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
        break;

      case Tool.multiSelect:
        // 多选模式：切换选择状态
        notifier.toggleSelection(id);
        AppLogger.debug('多选模式切换选区', data: {
          'regionId': id,
          'selectedIds': state.selectedIds.toString(),
        });
        break;

      case Tool.pan:
        // 拖拽模式：仅选中不调整
        notifier.selectRegion(id);
        break;

      default:
        notifier.selectRegion(id);
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
      // 避免在build过程中修改provider状态
      if (_originalRegion != null) {
        Future(() {
          if (_mounted) {
            ref
                .read(characterCollectionProvider.notifier)
                .updateSelectedRegion(_originalRegion!);
          }
        });
      }

      setState(() {
        _isAdjusting = false;
        _adjustingRegionId = null;
        _activeHandleIndex = null;
        _guideLines = null;
        _originalRegion = null;
        _adjustingRect = null;
        _isRotating = false;
        _currentRotation = 0.0;
        _rotationCenter = null;
      });
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

    // 不再实时更新预览，而只在onPanEnd时更新右侧预览区
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

  void _handleAdjustmentPanStart(DragStartDetails details) {
    if (!_isAdjusting || _adjustingRect == null) return; // Safety check

    final handleIndex = _getHandleIndexFromPosition(details.localPosition);

    AppLogger.debug('_handleAdjustmentPanStart', data: {
      'localPosition':
          '${details.localPosition.dx},${details.localPosition.dy}',
      'handleIndex': handleIndex,
    });

    if (handleIndex != null) {
      setState(() {
        _activeHandleIndex = handleIndex;
        _isRotating = (handleIndex == -1);
        if (_isRotating) {
          _rotationCenter = _adjustingRect!.center;
          _rotationStartAngle = _calculateAngle(
            _rotationCenter!,
            details.localPosition, // Use local position directly
          );
        }
      });
    }
  }

  void _handleAdjustmentPanUpdate(DragUpdateDetails details) {
    if (!_isAdjusting || _activeHandleIndex == null || _adjustingRect == null)
      return;

    setState(() {
      if (_isRotating) {
        // 处理旋转 (using viewport coordinates)
        final currentAngle =
            _calculateAngle(_rotationCenter!, details.localPosition);
        final angleDiff = currentAngle - _rotationStartAngle;
        _currentRotation = (_originalRegion!.rotation + angleDiff);
        // Normalize angle to 0 - 2*PI
        _currentRotation = _currentRotation % (2 * 3.14159);
        if (_currentRotation < 0) _currentRotation += (2 * 3.14159);

        AppLogger.debug('Rotating',
            data: {'currentRotation': _currentRotation});
      } else if (_activeHandleIndex! >= 0 && _activeHandleIndex! < 8) {
        // 处理调整大小 (using viewport coordinates)
        _adjustingRect = _adjustRect(
          _adjustingRect!,
          details.localPosition, // Use local position directly
          _activeHandleIndex!,
        );
        _guideLines = _calculateGuideLines(_adjustingRect!);
        AppLogger.debug('Resizing',
            data: {'newRect': _adjustingRect.toString()});
      } else if (_activeHandleIndex == 8) {
        // 处理整体移动 (using viewport coordinates)
        _adjustingRect =
            _adjustingRect!.translate(details.delta.dx, details.delta.dy);
        _guideLines =
            _calculateGuideLines(_adjustingRect!); // Update guides on move
        AppLogger.debug('Moving', data: {'newRect': _adjustingRect.toString()});
      }
    });
  }

  void _handleAdjustmentPanEnd(DragEndDetails details) {
    if (!_isAdjusting || _originalRegion == null || _adjustingRect == null) {
      // Ensure state is reset even if something went wrong
      _resetAdjustmentState();
      return;
    }

    final Rect finalViewportRect = _adjustingRect!;
    final double finalRotation = _currentRotation;
    final CharacterRegion originalRegion = _originalRegion!;

    // Reset UI state *immediately* so controls disappear
    _resetAdjustmentState();

    AppLogger.debug('_handleAdjustmentPanEnd - Processing Update', data: {
      'finalRect_viewport': finalViewportRect.toString(),
      'finalRotation': finalRotation
    });

    // Perform coordinate conversion *after* resetting UI state
    final Rect finalImageRect =
        _transformer!.viewportRectToImageRect(finalViewportRect);

    // Use Future.microtask to ensure provider update happens ASAP after current event loop
    Future.microtask(() {
      if (_mounted) {
        final updatedRegion = originalRegion.copyWith(
          rect: finalImageRect,
          rotation: finalRotation,
          updateTime: DateTime.now(),
        );

        AppLogger.debug('Updating Provider State', data: {
          'regionId': updatedRegion.id,
          'newRect':
              '${updatedRegion.rect.left.toStringAsFixed(1)}, ${updatedRegion.rect.top.toStringAsFixed(1)}, ${updatedRegion.rect.width.toStringAsFixed(1)}, ${updatedRegion.rect.height.toStringAsFixed(1)}',
          'newRotation': updatedRegion.rotation.toStringAsFixed(2)
        });

        try {
          ref
              .read(characterCollectionProvider.notifier)
              .updateSelectedRegion(updatedRegion);
          AppLogger.debug('Provider State Update - SUCCESS');
        } catch (e, stack) {
          AppLogger.error('Provider State Update - FAILED',
              error: e,
              stackTrace: stack,
              data: {'regionId': updatedRegion.id});
        }
      } else {
        AppLogger.debug('Provider State Update - SKIPPED (unmounted)');
      }
    });
  }

  // Helper to reset adjustment-specific state
  void _resetAdjustmentState() {
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _activeHandleIndex = null;
      _guideLines = null;
      _originalRegion = null;
      _adjustingRect = null;
      _isRotating = false;
      _currentRotation = 0.0;
      _rotationCenter = null;
      _hoveredHandleIndex = null; // Important reset
    });
  }

  double _calculateAngle(Offset center, Offset point) {
    return (point - center).direction;
  }

  void _confirmSelection() {
    if (_lastCompletedSelection == null) return;

    final imageRect =
        _transformer!.viewportRectToImageRect(_lastCompletedSelection!);

    // 使用Future延迟更新provider
    Future(() {
      if (_mounted) {
        // 添加区域
        ref.read(characterCollectionProvider.notifier).createRegion(imageRect);
      }
    });

    // 重置状态
    setState(() {
      _hasCompletedSelection = false;
      _lastCompletedSelection = null;
    });
  }

  void _cancelSelection() {
    setState(() {
      _hasCompletedSelection = false;
      _lastCompletedSelection = null;
    });
  }

  int? _getHandleIndexFromPosition(Offset position) {
    if (_adjustingRect == null) return null;

    // 计算旋转控制点的位置
    final rotationPoint = _adjustingRect!.topCenter.translate(0, -30);

    // 检查是否点击了旋转控制点
    if ((position - rotationPoint).distance < 12) {
      return -1; // 旋转控制点
    }

    // 检查是否点击了调整手柄
    final handles = [
      _adjustingRect!.topLeft,
      _adjustingRect!.topCenter,
      _adjustingRect!.topRight,
      _adjustingRect!.centerRight,
      _adjustingRect!.bottomRight,
      _adjustingRect!.bottomCenter,
      _adjustingRect!.bottomLeft,
      _adjustingRect!.centerLeft,
    ];

    for (int i = 0; i < handles.length; i++) {
      final handleRect = Rect.fromCenter(
        center: handles[i],
        width: 12.0,
        height: 12.0,
      );
      if (handleRect.contains(position)) {
        return i;
      }
    }

    // 如果点击了选区内部，返回移动整个选区的索引
    if (_adjustingRect!.contains(position)) {
      return 8; // 移动整个选区
    }

    return null;
  }

  Rect _adjustRect(Rect rect, Offset position, int handleIndex) {
    switch (handleIndex) {
      case 0: // 左上角
        return Rect.fromPoints(position, rect.bottomRight);
      case 1: // 上边中点
        return Rect.fromLTRB(rect.left, position.dy, rect.right, rect.bottom);
      case 2: // 右上角
        return Rect.fromPoints(rect.bottomLeft, position);
      case 3: // 右边中点
        return Rect.fromLTRB(rect.left, rect.top, position.dx, rect.bottom);
      case 4: // 右下角
        return Rect.fromPoints(rect.topLeft, position);
      case 5: // 下边中点
        return Rect.fromLTRB(rect.left, rect.top, rect.right, position.dy);
      case 6: // 左下角
        return Rect.fromPoints(position, rect.topRight);
      case 7: // 左边中点
        return Rect.fromLTRB(position.dx, rect.top, rect.right, rect.bottom);
      case 8: // 移动整个选区
        final dx = position.dx - rect.center.dx;
        final dy = position.dy - rect.center.dy;
        return rect.translate(dx, dy);
      default:
        return rect;
    }
  }
}
