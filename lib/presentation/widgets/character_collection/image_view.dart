import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/character_refresh_notifier.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../../providers/debug/debug_options_provider.dart';
import 'adjustable_region_painter.dart';
import 'debug_overlay.dart';
import 'delete_confirmation_dialog.dart';
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
  Timer? _transformationDebouncer;
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
    // No need to access selectedIds and modifiedIds directly as they're now part of region properties
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

          // 首次加载且图像和transformer都准备好时设置初始缩放
          if (_isFirstLoad &&
              imageState.hasValidImage &&
              imageSize.width > 0 &&
              imageSize.height > 0 &&
              _transformer != null) {
            // 确保在布局完成后执行
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_mounted || _transformer == null) return;

              final effectiveViewportSize = _transformer!.viewportSize;
              _setInitialScale(
                  imageSize: imageSize, viewportSize: effectiveViewportSize);

              setState(() {
                _isFirstLoad = false;
                _isZoomed = false;
              });

              AppLogger.debug('首次加载完成，已设置初始缩放', data: {
                'imageSize': '${imageSize.width}x${imageSize.height}',
                'viewportSize':
                    '${effectiveViewportSize.width}x${effectiveViewportSize.height}',
                'scale': _transformer!.currentScale
              });
            });
          }

          return Material(
            // 添加Material widget以支持elevation效果
            color: Colors.transparent,
            child: Listener(
              onPointerHover: _handleMouseMove,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageLayer(
                    imageState,
                    regions,
                    viewportSize,
                  ),
                  if (_transformer != null && debugOptions.enabled)
                    _buildDebugLayer(
                      debugOptions,
                      regions,
                      viewportSize,
                    ),
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
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if there's a selected region and activate adjustment mode if needed
    final characterCollection = ref.read(characterCollectionProvider);
    final selectedRegions =
        characterCollection.regions.where((r) => r.isSelected);

    if (selectedRegions.length == 1 &&
        !_isAdjusting &&
        ref.read(toolModeProvider) == Tool.select) {
      final selectedRegion = selectedRegions.first;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _activateAdjustmentMode(selectedRegion);
      });
    }
  }

  @override
  void didUpdateWidget(ImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 不在这里触发数据加载，改为观察图像状态变化
  }

  @override
  void dispose() {
    _mounted = false;
    _transformationDebouncer?.cancel();
    _animationController?.dispose();
    _transformationController.removeListener(_onTransformationChanged);
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

    // 添加变换矩阵变化监听
    _transformationController.addListener(_onTransformationChanged);

    _initializeView();

    // Listen for external region deletions affecting the adjusted region
    ref.listenManual(characterCollectionProvider, (previous, next) {
      // Check if we were adjusting a region
      if (_isAdjusting && _adjustingRegionId != null) {
        // Check if the adjusted region ID no longer exists in the new list
        final regionExists =
            next.regions.any((r) => r.id == _adjustingRegionId);
        if (!regionExists) {
          AppLogger.debug(
              'Adjusted region removed externally, resetting adjustment state.',
              data: {'removedRegionId': _adjustingRegionId});
          // Use WidgetsBinding to ensure state reset happens after build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mounted) {
              // Check if still mounted
              _resetAdjustmentState();
            }
          });
        }
      }

      // 监听Provider的isAdjusting状态变化以同步本地状态
      if (previous?.isAdjusting != next.isAdjusting) {
        AppLogger.debug('Provider isAdjusting state changed', data: {
          'previous': previous?.isAdjusting,
          'next': next.isAdjusting,
          'local_isAdjusting': _isAdjusting,
          'currentRegionId': next.currentId,
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_mounted) return;

          if (next.isAdjusting && !_isAdjusting) {
            // Provider进入调整模式，本地需要同步
            final regionToAdjust = next.selectedRegion;
            if (regionToAdjust != null) {
              AppLogger.debug('Activating adjustment mode from provider state');
              _activateAdjustmentMode(regionToAdjust);
            } else {
              AppLogger.warning(
                  'Provider isAdjusting is true, but no selected region found');
            }
          } else if (!next.isAdjusting && _isAdjusting) {
            // Provider退出调整模式，本地需要同步（只重置UI）
            AppLogger.debug(
                'Resetting local adjustment state from provider state');
            _resetAdjustmentState(); // 重置本地状态
          }
        });
      }
    });

    // Listen for refresh events
    ref.listenManual(characterRefreshNotifierProvider, (previous, current) {
      if (previous != current) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            // This could be optimized to handle specific refresh event types
            setState(() {
              // Force rebuild to reflect updated state
            });
          }
        });
      }
    });

    // 监听图像状态变化来触发选区数据加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final imageState = ref.read(workImageProvider);
      _lastImageId = '${imageState.workId}-${imageState.currentPageId}';
      if (imageState.hasValidImage) {
        _tryLoadCharacterData();
      }
    });
  }

  void _activateAdjustmentMode(CharacterRegion region) {
    if (_transformer == null) return;

    try {
      setState(() {
        _isAdjusting = true;
        _adjustingRegionId = region.id;
        _originalRegion = region;
        // 将图像坐标系中的矩形转换为视口坐标系
        _adjustingRect = _transformer!.imageRectToViewportRect(region.rect);
        _currentRotation = region.rotation;
        _selectionStart = null;
        _selectionCurrent = null;
        _hasCompletedSelection = false;
      });

      // 记录激活状态
      AppLogger.debug('选区进入调整模式', data: {
        'regionId': region.id,
        'isAdjusting': _isAdjusting,
        'rect': '${_adjustingRect!.width}x${_adjustingRect!.height}',
        'position': '${_adjustingRect!.left},${_adjustingRect!.top}',
        'rotation': _currentRotation,
        'scale': _transformer!.currentScale.toStringAsFixed(2)
      });
    } catch (e) {
      AppLogger.error('激活调整模式失败',
          error: e,
          data: {'regionId': region.id, 'rect': region.rect.toString()});
      _resetAdjustmentState();
    }
  }

  Rect _adjustRect(Rect rect, Offset position, int handleIndex) {
    final center = rect.center;

    // Transform the position to account for rotation
    Offset transformedPosition = position;
    if (_currentRotation != 0) {
      // Convert screen position to object space (un-rotate it)
      final dx = position.dx - center.dx;
      final dy = position.dy - center.dy;

      final cos = math.cos(-_currentRotation);
      final sin = math.sin(-_currentRotation);

      final rotatedX = dx * cos - dy * sin + center.dx;
      final rotatedY = dx * sin + dy * cos + center.dy;

      transformedPosition = Offset(rotatedX, rotatedY);
    }

    // Use the transformed position for standard rectangle adjustments
    Rect newRect;

    switch (handleIndex) {
      case 0: // 左上角
        newRect = Rect.fromPoints(transformedPosition, rect.bottomRight);
        break;
      case 1: // 上边中点
        newRect = Rect.fromLTRB(
            rect.left, transformedPosition.dy, rect.right, rect.bottom);
        break;
      case 2: // 右上角
        newRect = Rect.fromPoints(rect.bottomLeft, transformedPosition);
        break;
      case 3: // 右边中点
        newRect = Rect.fromLTRB(
            rect.left, rect.top, transformedPosition.dx, rect.bottom);
        break;
      case 4: // 右下角
        newRect = Rect.fromPoints(rect.topLeft, transformedPosition);
        break;
      case 5: // 下边中点
        newRect = Rect.fromLTRB(
            rect.left, rect.top, rect.right, transformedPosition.dy);
        break;
      case 6: // 左下角
        newRect = Rect.fromPoints(transformedPosition, rect.topRight);
        break;
      case 7: // 左边中点
        newRect = Rect.fromLTRB(
            transformedPosition.dx, rect.top, rect.right, rect.bottom);
        break;
      case 8: // 移动整个选区
        // For movement, use the original (non-transformed) position delta
        final dx = position.dx - center.dx;
        final dy = position.dy - center.dy;

        // If rotated, calculate the rotated delta
        if (_currentRotation != 0) {
          final cos = math.cos(-_currentRotation);
          final sin = math.sin(-_currentRotation);

          final rotatedDx = dx * cos - dy * sin;
          final rotatedDy = dx * sin + dy * cos;

          // Apply the rotated delta
          newRect = rect.translate(rotatedDx, rotatedDy);
        } else {
          newRect = rect.translate(dx, dy);
        }
        break;
      default:
        return rect;
    }

    // Ensure minimum size
    const minSize = 20.0;
    if (newRect.width < minSize || newRect.height < minSize) {
      // Keep at least minimum size but respect aspect ratio if possible
      if (newRect.width < minSize) {
        final aspectRatio = rect.height / rect.width;
        const newWidth = minSize;
        final newHeight = newWidth * aspectRatio;

        // Create rect with minimum width while preserving position
        newRect = Rect.fromLTWH(
            newRect.left, newRect.top, newWidth, math.max(newHeight, minSize));
      }

      if (newRect.height < minSize) {
        final aspectRatio = rect.width / rect.height;
        const newHeight = minSize;
        final newWidth = newHeight * aspectRatio;

        // Create rect with minimum height while preserving position
        newRect = Rect.fromLTWH(
            newRect.left, newRect.top, math.max(newWidth, minSize), newHeight);
      }
    }

    return newRect;
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
            // selectedIds is no longer needed, regions have isSelected property
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
    Size viewportSize,
  ) {
    final toolMode = ref.watch(toolModeProvider);
    final isPanMode = toolMode == Tool.pan;
    final isSelectMode = toolMode == Tool.select;
    final isMultiSelectMode = toolMode == Tool.multiSelect;
    final characterCollection = ref.watch(characterCollectionProvider);

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
          _hoveredHandleIndex = null;
        });
      },
      child: GestureDetector(
        onTapUp: _onTapUp,
        onDoubleTap: () {
          // 双击不再需要确认调整
        },
        // Always allow selection start, handle adjustment cancellation inside
        onPanStart: isPanMode ? _handlePanStart : _handleSelectionStart,
        onPanUpdate: isPanMode ? _handlePanUpdate : _handleSelectionUpdate,
        onPanEnd: isPanMode ? _handlePanEnd : _handleSelectionEnd,
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
                alignment: Alignment.topLeft,
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

              // 绘制所有区域
              if (_transformer != null && regions.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: _isAdjusting,
                    child: CustomPaint(
                      painter: RegionsPainter(
                        regions: regions,
                        transformer: _transformer!,
                        hoveredId: _hoveredRegionId,
                        adjustingRegionId: _adjustingRegionId,
                        currentTool: toolMode,
                        isAdjusting: characterCollection.isAdjusting,
                      ),
                    ),
                  ),
                ),

              // **Adjustment Layer GestureDetector**
              if (_isAdjusting && _adjustingRegionId != null)
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
                      painter: AdjustableRegionPainter(
                        region: _originalRegion!,
                        transformer: _transformer!,
                        isActive: true,
                        isAdjusting: true,
                        activeHandleIndex: _activeHandleIndex,
                        currentRotation: _currentRotation,
                        guideLines: _guideLines,
                        viewportRect: _adjustingRect,
                      ),
                      size: viewportSize,
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

        // 尺寸指示器 - 只在调整模式下显示
        if (_isAdjusting && _adjustingRect != null)
          Positioned(
            left: _calculateIndicatorPosition().dx,
            top: _calculateIndicatorPosition().dy,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _hoveredHandleIndex != null || _activeHandleIndex != null
                  ? 1.0
                  : 0.7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: _hoveredHandleIndex != null ||
                            _activeHandleIndex != null
                        ? Colors.blue
                        : Colors.blue.withOpacity(0.7),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.straighten,
                          size: 14,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_adjustingRect!.width.round()}×${_adjustingRect!.height.round()}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_currentRotation != 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.rotate_right,
                              size: 14,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(_currentRotation * 180 / math.pi).round()}°',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  double _calculateAngle(Offset center, Offset point) {
    // ...existing code...
    return (point - center).direction;
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

  /// 计算指示器的理想位置
  Offset _calculateIndicatorPosition() {
    if (_adjustingRect == null) return Offset.zero;

    const padding = 8.0;
    final viewportSize = _transformer?.viewportSize ?? Size.zero;

    // 默认位置在选区右侧
    var x = _adjustingRect!.right + padding;
    var y = _adjustingRect!.top;

    // 如果右侧空间不足，将指示器放在左侧
    if (x + 120 > viewportSize.width) {
      // 120是估算的指示器宽度
      x = _adjustingRect!.left - padding - 120;
    }

    // 如果顶部空间不足，将指示器向下移动
    if (y < padding) {
      y = padding;
    }

    // 如果底部空间不足，将指示器向上移动
    if (y + 50 > viewportSize.height) {
      // 50是估算的指示器最大高度
      y = viewportSize.height - 50;
    }

    // 当选区旋转时，确保指示器不会被选区遮挡
    if (_currentRotation != 0) {
      final rotationDegrees = (_currentRotation * 180 / math.pi) % 360;
      if (rotationDegrees > 45 && rotationDegrees < 135) {
        y = math.max(y, _adjustingRect!.bottom + padding);
      } else if (rotationDegrees > 225 && rotationDegrees < 315) {
        y = math.min(y, _adjustingRect!.top - 50 - padding);
      }
    }

    return Offset(x, y);
  }

  // 取消选区调整
  void _cancelAdjustment() {
    AppLogger.debug('取消选区调整 (_cancelAdjustment called)', data: {
      'imageViewHasAdjustingRegion': _adjustingRegionId != null,
    });

    // 更新Provider状态
    ref.read(characterCollectionProvider.notifier).finishCurrentAdjustment();

    // 完全重置本地调整状态
    _resetAdjustmentState();
  }

  void _cancelSelection() {
    setState(() {
      _hasCompletedSelection = false;
      _lastCompletedSelection = null;
    });
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

        // Notify refresh
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.regionUpdated);
      }
    });

    // 重置状态
    setState(() {
      _hasCompletedSelection = false;
      _lastCompletedSelection = null;
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

  int? _getHandleIndexFromPosition(Offset position) {
    if (_adjustingRect == null) return null;

    final center = _adjustingRect!.center;

    // Function to transform a point from screen to object space
    Offset transformPoint(Offset point, bool inverse) {
      if (_currentRotation == 0) return point;

      final dx = point.dx - center.dx;
      final dy = point.dy - center.dy;

      // Use inverse rotation for screen to object conversion, forward rotation for object to screen
      final angle = inverse ? -_currentRotation : _currentRotation;
      final cos = math.cos(angle);
      final sin = math.sin(angle);

      final rotatedX = dx * cos - dy * sin + center.dx;
      final rotatedY = dx * sin + dy * cos + center.dy;

      return Offset(rotatedX, rotatedY);
    }

    // Handle rotation control first
    // Transform the rotation point from object space to screen space
    final rotationPoint = transformPoint(
        Offset(_adjustingRect!.topCenter.dx, _adjustingRect!.topCenter.dy - 30),
        false // Transform from object to screen space
        );

    // Check if clicked on rotation handle
    if ((position - rotationPoint).distance < 12) {
      return -1; // Rotation handle
    }

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

    // Transform these handle positions if we have rotation
    final transformedHandles = _currentRotation != 0
        ? handles.map((p) => transformPoint(p, false)).toList()
        : handles;

    // Check each handle with transformed positions
    for (int i = 0; i < transformedHandles.length; i++) {
      final handleRect = Rect.fromCenter(
        center: transformedHandles[i],
        width: 12.0,
        height: 12.0,
      );

      if (handleRect.contains(position)) {
        return i;
      }
    }

    // If clicked inside the rect (considering rotation)
    if (_isPointInRotatedRect(position, _adjustingRect!, _currentRotation)) {
      return 8; // Move entire selection
    }

    return null;
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

    // 立即更新provider状态，确保UI和状态同步
    final Rect finalImageRect =
        _transformer!.viewportRectToImageRect(finalViewportRect);

    final updatedRegion = originalRegion.copyWith(
      rect: finalImageRect,
      rotation: finalRotation,
      updateTime: DateTime.now(),
      isModified: true, // Mark as modified
    );

    // 立即更新provider状态
    ref
        .read(characterCollectionProvider.notifier)
        .updateSelectedRegion(updatedRegion);

    // Notify refresh
    ref
        .read(characterRefreshNotifierProvider.notifier)
        .notifyEvent(RefreshEventType.regionUpdated);

    // 重置UI状态，但保持调整模式
    setState(() {
      _activeHandleIndex = null;
      _guideLines = null;
      _isRotating = false;
      _rotationCenter = null;
      _hoveredHandleIndex = null;
      // 不重置_isAdjusting和_adjustingRect，保持调整状态
    });

    AppLogger.debug('选区调整完成', data: {
      'regionId': updatedRegion.id,
      'newRect':
          '${updatedRegion.rect.left.toStringAsFixed(1)}, ${updatedRegion.rect.top.toStringAsFixed(1)}, ${updatedRegion.rect.width.toStringAsFixed(1)}, ${updatedRegion.rect.height.toStringAsFixed(1)}',
      'newRotation': updatedRegion.rotation.toStringAsFixed(2)
    });
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
        // Handle rotation
        final currentAngle =
            _calculateAngle(_rotationCenter!, details.localPosition);
        final angleDiff = currentAngle - _rotationStartAngle;
        _currentRotation =
            (_originalRegion!.rotation + angleDiff) % (2 * math.pi);
        if (_currentRotation < 0) _currentRotation += (2 * math.pi);
      } else if (_activeHandleIndex! >= 0 && _activeHandleIndex! < 8) {
        // Handle resizing with proper coordinate transformation
        _adjustingRect = _adjustRect(
          _adjustingRect!,
          details.localPosition,
          _activeHandleIndex!,
        );
        _guideLines = _calculateGuideLines(_adjustingRect!);
      } else if (_activeHandleIndex == 8) {
        // Handle movement - simpler approach that preserves rotation
        _adjustingRect =
            _adjustingRect!.translate(details.delta.dx, details.delta.dy);
        _guideLines = _calculateGuideLines(_adjustingRect!);
      }
    });
  }

  void _handleBlankAreaTap() {
    AppLogger.debug('空白区域点击处理 (_handleBlankAreaTap called)');
    // 实现点击空白区域退出调整模式的逻辑
    _cancelAdjustment();
    _cancelSelection();
  }

  /// 处理图片加载完成事件
  /// 更新图像数据并触发选区加载
  Future<void> _handleImageLoaded(WorkImageState imageState) async {
    if (!_mounted) return;

    final currentImageId = '${imageState.workId}-${imageState.currentPageId}';

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
      // await _tryLoadCharacterData();

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
    // 结束平移和清理定时器
    _transformationDebouncer?.cancel();
    setState(() {
      _isPanning = false;
      _lastPanPosition = null;
    });

    final scale = _transformer?.currentScale ?? 1.0;
    setState(() {
      _isZoomed = scale > 1.05;
    });
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

    // 添加防抖以避免频繁更新状态
    _transformationDebouncer?.cancel();
    _transformationDebouncer = Timer(const Duration(milliseconds: 16), () {
      if (!_mounted) return;
      final scale = _transformer?.currentScale ?? 1.0;
      setState(() {
        _isZoomed = scale > 1.05;
      });
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
            // 显示确认对话框
            _requestDeleteRegion(_adjustingRegionId!);
            return KeyEventResult.handled;
          }
          break;
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
      _requestDeleteSelectedRegions();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
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

  void _handlePanEnd(DragEndDetails details) {
    if (ref.read(toolModeProvider) != Tool.pan) return;

    setState(() {
      _isPanning = false;
      _lastPanPosition = null;
    });
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

  Future<void> _handleRegionCreated(Rect rect) async {
    try {
      AppLogger.debug('框选完成，创建新选区', data: {
        'rect': '${rect.left},${rect.top},${rect.width}x${rect.height}',
      });

      // 1. 创建选区 (Notifier 会设置 isAdjusting = true)
      final notifier = ref.read(characterCollectionProvider.notifier);
      notifier.createRegion(rect);

      // 2. 清理临时的选区状态
      setState(() {
        _lastCompletedSelection = null;
        _hasCompletedSelection = false;
        _selectionStart = null;
        _selectionCurrent = null;
      });

      // Notify refresh
      ref
          .read(characterRefreshNotifierProvider.notifier)
          .notifyEvent(RefreshEventType.regionUpdated);
    } catch (e, stack) {
      AppLogger.error('创建选区失败', error: e, stackTrace: stack);
      // 清理选区状态以防万一
      _resetSelectionState();
    }
  }

  void _handleRegionTap(String id) {
    // 使用CharacterCollectionNotifier的扩展方法处理区域点击
    ref.read(characterCollectionProvider.notifier).handleRegionClick(id);
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
    // If starting a new selection while adjusting, cancel the current adjustment first.
    if (_isAdjusting) {
      _cancelAdjustment();
    }

    if (!_isInSelectionMode) return;

    // 检查是否当前有区域处于调整状态
    final collectionState = ref.read(characterCollectionProvider);
    if (collectionState.isAdjusting) {
      // 使用Provider API退出调整模式
      ref.read(characterCollectionProvider.notifier).setAdjusting(false);
    }

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

  // 检测点击位置是否在选区内
  CharacterRegion? _hitTestRegion(
      Offset position, List<CharacterRegion> regions) {
    if (_transformer == null) return null;

    // 从后向前检测，使最上层的选区优先响应
    for (final region in regions.reversed) {
      final rect = _transformer!.imageRectToViewportRect(region.rect);
      if (_isPointInRotatedRect(position, rect, region.rotation)) {
        return region;
      }
    }
    return null;
  }

  void _initializeView() {
    if (!_mounted) return;

    // 重置变换控制器
    _transformationController.value = Matrix4.identity();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 重置所有状态
      setState(() {
        _isFirstLoad = true;
        _isZoomed = false;
        _isPanning = false;
        _lastImageId = null;

        // 清理transformer相关状态
        if (_transformer != null) {
          _transformer = null;
        }
      });

      // 检查当前图像状态
      final imageState = ref.read(workImageProvider);
      AppLogger.debug('视图初始化', data: {
        'hasValidImage': imageState.hasValidImage,
        'imageSize': imageState.hasValidImage
            ? '${imageState.imageWidth}x${imageState.imageHeight}'
            : 'none'
      });
    });
  }

  // Helper to determine if a point is inside a rotated rectangle
  bool _isPointInRotatedRect(Offset point, Rect rect, double rotation) {
    if (rotation == 0) return rect.contains(point);

    final center = rect.center;

    // Translate to origin
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    // Rotate back (apply inverse rotation)
    final cos = math.cos(-rotation);
    final sin = math.sin(-rotation);

    final rotatedX = dx * cos - dy * sin + center.dx;
    final rotatedY = dx * sin + dy * cos + center.dy;

    // Check if rotated point is in original rect
    return rect.contains(Offset(rotatedX, rotatedY));
  }

  // 处理画布点击
  void _onTapUp(TapUpDetails details) {
    final characterCollection = ref.read(characterCollectionProvider);
    final regions = characterCollection.regions; // 获取区域列表
    final hitRegion = _hitTestRegion(details.localPosition, regions);

    AppLogger.debug('画布点击 (_onTapDown)', data: {
      'position':
          '${details.localPosition.dx.toStringAsFixed(1)},${details.localPosition.dy.toStringAsFixed(1)}',
      'hitRegionId': hitRegion?.id ?? 'null',
      'isAdjusting': characterCollection.isAdjusting,
      'hasTool': _isInSelectionMode ? 'true' : 'false',
      'toolMode': _isInSelectionMode ? Tool.select.toString() : 'null',
    });

    if (characterCollection.isAdjusting && hitRegion == null) {
      // 如果正在调整区域且点击空白，则取消调整
      AppLogger.debug('点击空白处且isAdjusting为true，调用_handleBlankAreaTap()');
      _handleBlankAreaTap();
      return;
    }
    if (characterCollection.currentTool == Tool.pan && hitRegion == null) {
      // 如果点击空白处且当前处于Pan模式，清除选择状态
      ref.read(characterCollectionProvider.notifier).selectRegion(null);
      return;
    }
    if (hitRegion != null) {
      // 如果点击了区域，处理区域点击事件
      _handleRegionTap(hitRegion.id);
      return;
    }
  }

  /// 处理变换矩阵变化事件
  void _onTransformationChanged() {
    if (!_isAdjusting || _originalRegion == null || _transformer == null)
      return;

    // 使用防抖处理频繁的变换更新
    _transformationDebouncer?.cancel();
    _transformationDebouncer = Timer(const Duration(milliseconds: 16), () {
      if (!_mounted) return;

      // 计算新的视口矩形
      final newRect =
          _transformer!.imageRectToViewportRect(_originalRegion!.rect);

      // 只在位置或大小有显著变化时更新
      if (_adjustingRect == null ||
          (newRect.left - _adjustingRect!.left).abs() > 0.1 ||
          (newRect.top - _adjustingRect!.top).abs() > 0.1 ||
          (newRect.width - _adjustingRect!.width).abs() > 0.1 ||
          (newRect.height - _adjustingRect!.height).abs() > 0.1) {
        setState(() {
          _adjustingRect = newRect;
          if (_guideLines != null) {
            _guideLines = _calculateGuideLines(newRect);
          }
        });

        AppLogger.debug('变换更新选区', data: {
          'scale': _transformer!.currentScale.toStringAsFixed(2),
          'rect':
              '${newRect.width.toStringAsFixed(1)}x${newRect.height.toStringAsFixed(1)}',
          'position':
              '${newRect.left.toStringAsFixed(1)},${newRect.top.toStringAsFixed(1)}'
        });
      }
    });
  }

  // 请求删除单个区域（显示确认对话框）
  Future<void> _requestDeleteRegion(String id) async {
    final regions = ref.read(characterCollectionProvider).regions;
    final region = regions.firstWhere((r) => r.id == id,
        orElse: () => throw Exception('找不到区域'));

    // 只有保存标志为true的区域才需要确认
    bool confirmed = true;
    if (region.characterId != null) {
      // 显示确认对话框
      confirmed = await DeleteConfirmationDialog.show(context);
    }

    if (confirmed) {
      // 用户确认删除，执行删除操作
      if (_mounted) {
        await ref.read(characterCollectionProvider.notifier).deleteRegion(id);

        // Notify refresh
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.characterDeleted);

        // 确保重置调整状态
        _resetAdjustmentState();
      }
    }
  }

  // 请求删除选中的区域（显示确认对话框）
  Future<void> _requestDeleteSelectedRegions() async {
    final collection = ref.read(characterCollectionProvider);
    final selectedRegions =
        collection.regions.where((r) => r.isSelected).toList();
    final selectedIds = selectedRegions.map((r) => r.id).toList();

    if (selectedIds.isEmpty) return;

    // 检查是否有已保存的区域
    final savedRegions =
        selectedRegions.where((r) => r.characterId != null).toList();

    bool confirmed = true;
    if (savedRegions.isNotEmpty) {
      // 只有当选中的区域中有已保存的区域时才显示确认对话框
      confirmed = await DeleteConfirmationDialog.show(
        context,
        count: savedRegions.length,
        isBatch: savedRegions.length > 1,
      );
    }

    if (confirmed) {
      // 用户确认删除，执行删除操作
      if (_mounted) {
        await ref
            .read(characterCollectionProvider.notifier)
            .deleteBatchRegions(selectedIds);

        // Notify refresh
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.characterDeleted);

        // 确保重置调整状态
        _resetAdjustmentState();
      }
    }
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

  /// 设置图像初始缩放以适应视口
  void _setInitialScale({
    required Size imageSize,
    required Size viewportSize,
  }) {
    // 避免重复调用动画设置
    if (_animationController != null && _animationController!.isAnimating) {
      AppLogger.debug('动画已在进行中，跳过缩放设置');
      return;
    }

    try {
      // 计算基础缩放比例：宽度/高度适配模式，取较小值以确保完整显示
      final double widthScale = viewportSize.width / imageSize.width;
      final double heightScale = viewportSize.height / imageSize.height;
      final scale = math.min(widthScale, heightScale);

      // 计算居中偏移
      final double offsetX = (viewportSize.width - imageSize.width * scale) / 2;
      final double offsetY =
          (viewportSize.height - imageSize.height * scale) / 2;

      // 构建变换矩阵
      final targetMatrix = Matrix4.identity()
        ..translate(offsetX, offsetY)
        ..scale(scale, scale, 1.0);

      // 使用动画平滑过渡
      if (_animationController != null) {
        _animationController!.dispose();
      }

      _animationController = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );

      final animation = Matrix4Tween(
        begin: _transformationController.value,
        end: targetMatrix,
      ).animate(CurvedAnimation(
        parent: _animationController!,
        curve: Curves.easeOutCubic,
      ));

      animation.addListener(() {
        if (_mounted) {
          _transformationController.value = animation.value;
        }
      });

      animation.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController?.dispose();
          _animationController = null;
        }
      });

      _animationController!.forward();

      AppLogger.debug('设置初始缩放', data: {
        'scale': scale.toStringAsFixed(3),
        'imageSize': '${imageSize.width}x${imageSize.height}',
        'viewportSize': '${viewportSize.width}x${viewportSize.height}',
        'offset': '${offsetX.toStringAsFixed(1)},${offsetY.toStringAsFixed(1)}'
      });
    } catch (e) {
      AppLogger.error('设置初始缩放失败', error: e);
    }
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

      // 只记录错误日志，不清理状态
      // loadWorkData内部会处理自己的错误状态
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
        _transformer = CoordinateTransformer(
          transformationController: _transformationController,
          imageSize: imageSize,
          viewportSize: viewportSize,
          enableLogging: enableLogging,
        );

        AppLogger.debug('CoordinateTransformer已更新', data: {
          'imageSize': '${imageSize.width}x${imageSize.height}',
          'viewportSize': '${viewportSize.width}x${viewportSize.height}',
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
