import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../../utils/focus/focus_persistence.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/character_refresh_notifier.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import 'adjustable_region_painter.dart';
import 'image_view_base.dart';
import 'regions_painter.dart';
import 'selection_painters.dart';
import 'selection_toolbar.dart';

/// 桌面端图片预览组件
/// 专门针对鼠标和键盘操作优化的实现
class DesktopImageView extends ImageViewBase {
  const DesktopImageView({super.key});

  @override
  ConsumerState<DesktopImageView> createState() => _DesktopImageViewState();

  // 实现基类的抽象方法
  @override
  void handleScale(ScaleStartDetails details, ScaleUpdateDetails updateDetails,
      ScaleEndDetails endDetails) {
    // 桌面端的缩放实现（主要通过鼠标滚轮）
  }

  @override
  void handlePan(DragStartDetails details, DragUpdateDetails updateDetails,
      DragEndDetails endDetails) {
    // 桌面端的平移实现
  }

  @override
  void handleTap(TapUpDetails details) {
    // 桌面端的点击实现
  }

  @override
  void handleLongPress(LongPressStartDetails details) {
    // 桌面端长按实现（可能不需要）
  }

  @override
  void handleSelectionCreate(Offset start, Offset end) {
    // 桌面端的选区创建实现
  }

  @override
  void handleSelectionAdjust(String regionId, Rect newRect, double rotation) {
    // 桌面端的选区调整实现
  }

  @override
  void handleSelectionSelect(String regionId) {
    // 桌面端的选区选择实现
  }

  @override
  List<CharacterRegion> getCurrentRegions(WidgetRef ref) {
    return ref.watch(characterCollectionProvider).regions;
  }

  @override
  CharacterRegion? hitTestRegion(
      Offset position, List<CharacterRegion> regions) {
    // 桌面端的碰撞检测实现
    return null;
  }

  @override
  Widget buildGestureDetector({
    required Widget child,
    required Tool currentTool,
    required bool isAdjusting,
    required VoidCallback? onTap,
    required VoidCallback? onPanStart,
    required VoidCallback? onPanUpdate,
    required VoidCallback? onPanEnd,
    required VoidCallback? onScaleStart,
    required VoidCallback? onScaleUpdate,
    required VoidCallback? onScaleEnd,
  }) {
    // 桌面端的手势检测器构建
    return child;
  }

  @override
  Widget buildAdjustmentHandles({
    required CharacterRegion region,
    required bool isActive,
    required int? activeHandleIndex,
    required VoidCallback? onHandleDrag,
  }) {
    // 桌面端的调整句柄构建
    return const SizedBox.shrink();
  }
}

class _DesktopImageViewState extends ConsumerState<DesktopImageView>
    with TickerProviderStateMixin, FocusPersistenceMixin {
  final TransformationController _transformationController =
      TransformationController();
  final FocusNode _focusNode = FocusNode();
  CoordinateTransformer? _transformer;

  AnimationController? _animationController;
  Timer? _transformationDebouncer;
  Timer? _hoverDebouncer;
  bool _isFirstLoad = true;

  bool _isInSelectionMode = false;

  bool _isPanning = false;
  bool _isAltKeyPressed = false;
  bool _isRightMousePressed = false;
  late final ValueNotifier<bool> _altKeyNotifier = ValueNotifier<bool>(false);
  Timer? _altKeyDebouncer;
  Ticker? _ticker;

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
  double _currentRotation = 0.0;
  bool _mounted = true;

  // 选区调整相关字段
  bool _isRotating = false;
  Offset? _rotationCenter;
  double _rotationStartAngle = 0.0;

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);
    final characterCollection = ref.watch(characterCollectionProvider);
    final regions = characterCollection.regions;
    final selectedIds =
        regions.where((r) => r.isSelected).map((r) => r.id).toList();

    // 处理工具模式变化
    final lastToolMode = _isInSelectionMode ? Tool.select : Tool.pan;
    _isInSelectionMode = toolMode == Tool.select;
    _isPanning = toolMode == Tool.pan;

    // 模式变化时重置状态
    if (lastToolMode != toolMode) {
      AppLogger.debug('桌面端工具模式变化，重置状态', data: {
        'from': lastToolMode.toString(),
        'to': toolMode.toString(),
      });
      Future(() => _resetSelectionState());
    }

    if (!imageState.hasValidImage) {
      return const SizedBox.shrink();
    }

    final imageSize = Size(imageState.imageWidth, imageState.imageHeight);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize =
              Size(constraints.maxWidth, constraints.maxHeight);

          _updateTransformer(
            imageSize: imageSize,
            viewportSize: viewportSize,
          );

          // 首次加载设置
          if (_isFirstLoad &&
              imageState.hasValidImage &&
              imageSize.width > 0 &&
              imageSize.height > 0 &&
              _transformer != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_mounted || _transformer == null) return;

              final effectiveViewportSize = _transformer!.viewportSize;
              _setInitialScale(
                  imageSize: imageSize, viewportSize: effectiveViewportSize);

              setState(() {
                _isFirstLoad = false;
              });
            });
          }

          return Material(
            color: Colors.transparent,
            child: Listener(
              onPointerDown: _handlePointerDown,
              onPointerUp: _handlePointerUp,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImageLayer(
                    imageState,
                    regions,
                    viewportSize,
                    selectedIds,
                  ),
                  _buildSelectionToolLayer(),
                  _buildUILayer(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mounted = false;
    _transformationDebouncer?.cancel();
    _hoverDebouncer?.cancel();
    _altKeyDebouncer?.cancel();
    _ticker?.dispose();
    _animationController?.dispose();
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _altKeyNotifier.dispose();
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyboardEvent);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _transformationController.addListener(_onTransformationChanged);
    _focusNode.addListener(_onFocusChange);
    _altKeyNotifier.addListener(_onAltKeyChange);
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyboardEvent);
    _ticker = createTicker(_onTick);
    _initializeView();

    // 监听Provider状态变化
    _setupProviderListeners();
  }

  /// 设置Provider监听器
  void _setupProviderListeners() {
    // 监听外部区域删除
    ref.listenManual(characterCollectionProvider, (previous, next) {
      if (_isAdjusting && _adjustingRegionId != null) {
        final regionExists =
            next.regions.any((r) => r.id == _adjustingRegionId);
        if (!regionExists) {
          AppLogger.debug('调整的区域被外部删除，重置调整状态');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_mounted) {
              _resetAdjustmentState();
            }
          });
        }
      }

      // 同步Provider的调整状态
      if (previous?.isAdjusting != next.isAdjusting) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_mounted) return;

          if (next.isAdjusting && !_isAdjusting) {
            final regionToAdjust = next.selectedRegion;
            if (regionToAdjust != null) {
              _activateAdjustmentMode(regionToAdjust);
            }
          } else if (!next.isAdjusting && _isAdjusting) {
            _resetAdjustmentState();
          }
        });
      }
    });

    // 监听刷新事件
    ref.listenManual(characterRefreshNotifierProvider, (previous, current) {
      if (previous != current) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mounted) {
            setState(() {});
          }
        });
      }
    });

    // 监听图像状态变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final imageState = ref.read(workImageProvider);
      if (imageState.hasValidImage) {
        _tryLoadCharacterData();
      }
    });
  }

  /// 尝试加载字符数据
  Future<void> _tryLoadCharacterData() async {
    if (!_mounted) return;

    final imageState = ref.read(workImageProvider);

    try {
      if (!imageState.hasValidImage ||
          imageState.workId.isEmpty ||
          imageState.currentPageId.isEmpty) {
        return;
      }

      await ref.read(characterCollectionProvider.notifier).loadWorkData(
            imageState.workId,
            pageId: imageState.currentPageId,
          );

      AppLogger.debug('桌面端字符数据加载完成');
    } catch (e, stack) {
      AppLogger.error('加载字符数据失败', error: e, stackTrace: stack);
    }
  }

  /// 初始化视图
  void _initializeView() {
    if (!_mounted) return;

    _transformationController.value = Matrix4.identity();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isFirstLoad = true;
        _isPanning = false;
      });
    });
  }

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    bool isAlt = false;

    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      isAlt = true;
    } else if (HardwareKeyboard.instance.isAltPressed) {
      isAlt = true;
    }

    if (isAlt) {
      if (event.runtimeType.toString() == 'KeyRepeatEvent') {
        return;
      }

      final bool isPressed = event.runtimeType.toString() == 'KeyDownEvent';

      if (_isAltKeyPressed != isPressed) {
        setState(() {
          _isAltKeyPressed = isPressed;
          _altKeyNotifier.value = isPressed;
        });
      }
    }
  }

  /// 硬件键盘事件处理
  bool _handleHardwareKeyboardEvent(KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.altLeft ||
        event.logicalKey == LogicalKeyboardKey.altRight) {
      if (event.runtimeType.toString() == 'KeyRepeatEvent') {
        return false;
      }

      final bool isPressed = event.runtimeType.toString() == 'KeyDownEvent';

      if (_isAltKeyPressed != isPressed) {
        setState(() {
          _isAltKeyPressed = isPressed;
          _altKeyNotifier.value = isPressed;
        });
      }
    }

    return false;
  }

  /// 构建图像层
  Widget _buildImageLayer(
    WorkImageState imageState,
    List<CharacterRegion> regions,
    Size viewportSize,
    List<String> selectedIds,
  ) {
    final toolMode = ref.watch(toolModeProvider);
    final isPanMode = toolMode == Tool.pan;
    final isSelectMode = toolMode == Tool.select;
    final characterCollection = ref.watch(characterCollectionProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          constrained: false,
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 10.0,
          // 在桌面端，缩放功能（鼠标滚轮）应该在所有模式下都可用
          scaleEnabled: true,
          // 平移功能只在特定条件下启用：平移模式、Alt键、右键
          panEnabled:
              isPanMode || _altKeyNotifier.value || _isRightMousePressed,
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
              ),

              // 区域绘制层 - 仅在非调整模式下响应交互
              if (_transformer != null && regions.isNotEmpty && !_isAdjusting)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: _onTapUp,
                      child: CustomPaint(
                        painter: RegionsPainter(
                          regions: regions,
                          transformer: _transformer!,
                          hoveredId: _hoveredRegionId,
                          adjustingRegionId: _adjustingRegionId,
                          currentTool: toolMode,
                          isAdjusting: characterCollection.isAdjusting,
                          selectedIds: selectedIds,
                        ),
                      ),
                    ),
                  ),
                ),

              // 调整层 - 仅在调整模式下显示
              if (_isAdjusting &&
                  _adjustingRegionId != null &&
                  _originalRegion != null)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _altKeyNotifier,
                      builder: (context, isAltPressed, child) {
                        return MouseRegion(
                          cursor: _getCursor(),
                          onHover: (event) {
                            if (isAltPressed || _isRightMousePressed) return;
                            _hoverDebouncer?.cancel();
                            _hoverDebouncer =
                                Timer(const Duration(milliseconds: 8), () {
                              if (!_mounted) return;
                              final handleIndex = _getHandleIndexFromPosition(
                                  event.localPosition);
                              setState(() {
                                _activeHandleIndex = handleIndex;
                              });
                            });
                          },
                          onExit: (_) {
                            _hoverDebouncer?.cancel();
                            if (_mounted) {
                              setState(() {
                                _activeHandleIndex = null;
                              });
                            }
                          },
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: _onTapUp,
                            onPanStart: _handleAdjustmentPanStart,
                            onPanUpdate: _handleAdjustmentPanUpdate,
                            onPanEnd: _handleAdjustmentPanEnd,
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
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 框选层 - 仅在框选模式下且非调整状态下响应
              if (isSelectMode && !_isAdjusting)
                Positioned.fill(
                  child: RepaintBoundary(
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _altKeyNotifier,
                      builder: (context, isAltPressed, child) {
                        return MouseRegion(
                          cursor: SystemMouseCursors.precise,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: _onTapUp,
                            onPanStart: _handleSelectionStart,
                            onPanUpdate: _handleSelectionUpdate,
                            onPanEnd: _handleSelectionEnd,
                            child: CustomPaint(
                              painter: ActiveSelectionPainter(
                                startPoint: _selectionStart ?? Offset.zero,
                                endPoint: _selectionCurrent ?? Offset.zero,
                                viewportSize:
                                    _transformer?.viewportSize ?? Size.zero,
                                isActive: _selectionStart != null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
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

  Widget _buildUILayer() {
    return Stack(
      children: [
        // 选区工具栏
        if (_hasCompletedSelection && _lastCompletedSelection != null)
          Positioned(
            left: _lastCompletedSelection!.left,
            top: _lastCompletedSelection!.top - 40,
            child: SelectionToolbar(
              onConfirm: _confirmSelection,
              onCancel: _cancelSelection,
              onDelete: () {},
            ),
          ),

        // 尺寸指示器
        if (_isAdjusting && _adjustingRect != null)
          Positioned(
            left: _calculateIndicatorPosition().dx,
            top: _calculateIndicatorPosition().dy,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: _activeHandleIndex != null ? 1.0 : 0.7,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: _activeHandleIndex != null
                        ? Colors.blue
                        : Colors.blue.withAlpha(179),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.straighten,
                            size: 14, color: Colors.blue),
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
                            const Icon(Icons.rotate_right,
                                size: 14, color: Colors.blue),
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

  // 其他方法的实现（基本与原始m3_image_view.dart相同，但针对桌面端优化）
  void _activateAdjustmentMode(CharacterRegion region) {
    if (_transformer == null) return;

    try {
      setState(() {
        _isAdjusting = true;
        _adjustingRegionId = region.id;
        _originalRegion = region;
        _adjustingRect = _transformer!.imageRectToViewportRect(region.rect);
        _currentRotation = region.rotation;
        _selectionStart = null;
        _selectionCurrent = null;
        _hasCompletedSelection = false;
      });

      AppLogger.debug('桌面端选区进入调整模式', data: {
        'regionId': region.id,
        'rect': '${_adjustingRect!.width}x${_adjustingRect!.height}',
      });
    } catch (e) {
      AppLogger.error('激活调整模式失败', error: e);
      _resetAdjustmentState();
    }
  }

  MouseCursor _getCursor() {
    final toolMode = ref.read(toolModeProvider);
    // 移除Alt键和右键的光标变化，避免误导用户
    // if (_isAltKeyPressed || _isRightMousePressed) {
    //   return SystemMouseCursors.move;
    // }

    if (_isAdjusting) {
      if (_activeHandleIndex != null) {
        switch (_activeHandleIndex) {
          case -1:
            return SystemMouseCursors.grab;
          case 0:
          case 4:
            return SystemMouseCursors.resizeUpLeftDownRight;
          case 2:
          case 6:
            return SystemMouseCursors.resizeUpRightDownLeft;
          case 1:
          case 5:
            return SystemMouseCursors.resizeUpDown;
          case 3:
          case 7:
            return SystemMouseCursors.resizeLeftRight;
          case 8:
            return SystemMouseCursors.move;
          default:
            return SystemMouseCursors.precise;
        }
      }
    }

    if (toolMode == Tool.pan) {
      return _isPanning ? SystemMouseCursors.grabbing : SystemMouseCursors.grab;
    } else {
      return SystemMouseCursors.precise;
    }
  }

  Offset _calculateIndicatorPosition() {
    // 计算指示器位置
    return Offset.zero;
  }

  void _resetAdjustmentState() {
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _activeHandleIndex = null;
      _guideLines = null;
      _originalRegion = null;
      _adjustingRect = null;
      _currentRotation = 0.0;
    });
  }

  void _resetSelectionState() {
    if (_isAdjusting) {
      setState(() {
        _isAdjusting = false;
        _adjustingRegionId = null;
        _activeHandleIndex = null;
        _guideLines = null;
        _originalRegion = null;
        _adjustingRect = null;
        _currentRotation = 0.0;
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

  void _confirmSelection() {
    if (_lastCompletedSelection == null) return;

    final imageRect =
        _transformer!.viewportRectToImageRect(_lastCompletedSelection!);

    Future(() {
      if (_mounted) {
        ref.read(characterCollectionProvider.notifier).createRegion(imageRect);
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.regionUpdated);
      }
    });

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

  // 添加其他必要的方法实现
  void _onAltKeyChange() {
    _altKeyDebouncer?.cancel();
    _altKeyDebouncer = Timer(const Duration(milliseconds: 16), () {
      if (mounted) {
        _startTickerIfNeeded();
      }
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      AppLogger.debug('DesktopImageView获得焦点');
      final isAltActuallyPressed = HardwareKeyboard.instance.isAltPressed;
      if (_isAltKeyPressed != isAltActuallyPressed) {
        setState(() {
          _isAltKeyPressed = isAltActuallyPressed;
          _altKeyNotifier.value = isAltActuallyPressed;
        });
      }
    } else {
      if (_isAltKeyPressed) {
        setState(() {
          _isAltKeyPressed = false;
          _altKeyNotifier.value = false;
        });
      }
    }
  }

  void _onTick(Duration elapsed) {
    if (!_mounted) {
      _ticker?.stop();
      return;
    }

    if (!_isAdjusting && !_isInSelectionMode) {
      _ticker?.stop();
    }
  }

  void _startTickerIfNeeded() {
    if (_ticker != null &&
        !_ticker!.isActive &&
        (_isAdjusting || _isInSelectionMode)) {
      _ticker!.start();
    }
  }

  void _onTransformationChanged() {
    if (!_isAdjusting || _originalRegion == null || _transformer == null) {
      return;
    }

    _transformationDebouncer?.cancel();
    _transformationDebouncer = Timer(const Duration(milliseconds: 16), () {
      if (!_mounted) return;

      final newRect =
          _transformer!.imageRectToViewportRect(_originalRegion!.rect);

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
      }
    });
  }

  List<Offset> _calculateGuideLines(Rect rect) {
    final guides = <Offset>[];

    if (_transformer == null) return guides;

    guides.add(Offset(rect.center.dx, 0));
    guides.add(Offset(rect.center.dx, _transformer!.viewportSize.height));
    guides.add(Offset(0, rect.center.dy));
    guides.add(Offset(_transformer!.viewportSize.width, rect.center.dy));

    return guides;
  }

  void _setInitialScale({
    required Size imageSize,
    required Size viewportSize,
  }) {
    if (_animationController != null && _animationController!.isAnimating) {
      return;
    }

    try {
      final double widthScale = viewportSize.width / imageSize.width;
      final double heightScale = viewportSize.height / imageSize.height;
      final scale = math.min(widthScale, heightScale);

      final double offsetX = (viewportSize.width - imageSize.width * scale) / 2;
      final double offsetY =
          (viewportSize.height - imageSize.height * scale) / 2;

      final targetMatrix = Matrix4.identity()
        ..translate(offsetX, offsetY)
        ..scale(scale, scale, 1.0);

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
    } catch (e) {
      AppLogger.error('设置初始缩放失败', error: e);
    }
  }

  void _updateTransformer({
    required Size imageSize,
    required Size viewportSize,
  }) {
    final needsUpdate = _transformer == null ||
        _transformer!.imageSize != imageSize ||
        _transformer!.viewportSize != viewportSize;

    if (needsUpdate) {
      _transformer = CoordinateTransformer(
        transformationController: _transformationController,
        imageSize: imageSize,
        viewportSize: viewportSize,
      );
    }
  }

  void _handleInteractionStart(ScaleStartDetails details) {
    final toolMode = ref.read(toolModeProvider);
    final isPanMode = toolMode == Tool.pan;

    if (isPanMode) {
      setState(() {
        _isPanning = true;
      });
    }
  }

  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    final toolMode = ref.read(toolModeProvider);
    final isPanMode = toolMode == Tool.pan;

    if (isPanMode && _isPanning) {
      // 桌面端的InteractiveViewer会自动处理平移和缩放
    }
  }

  void _handleInteractionEnd(ScaleEndDetails details) {
    _transformationDebouncer?.cancel();
    setState(() {
      _isPanning = false;
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.buttons == 2) {
      setState(() {
        _isRightMousePressed = true;
      });
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (!event.down && _isRightMousePressed) {
      setState(() {
        _isRightMousePressed = false;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    final toolMode = ref.read(toolModeProvider);
    final regions = ref.read(characterCollectionProvider).regions;
    final position = details.localPosition;

    // 桌面端的点击检测（使用较小的容差）
    final hitRegion = _hitTestRegion(position, regions);

    if (hitRegion != null) {
      if (toolMode == Tool.select) {
        _handleRegionSelect(hitRegion);
      } else {
        ref
            .read(characterCollectionProvider.notifier)
            .toggleSelection(hitRegion.id);
      }
    } else {
      if (_isAdjusting) {
        _exitAdjustmentMode();
      } else {
        ref.read(characterCollectionProvider.notifier).clearSelections();
      }
    }
  }

  CharacterRegion? _hitTestRegion(
      Offset position, List<CharacterRegion> regions) {
    if (_transformer == null) return null;

    // 桌面端使用较小的点击区域
    for (final region in regions.reversed) {
      final rect = _transformer!.imageRectToViewportRect(region.rect);
      if (rect.contains(position)) {
        return region;
      }
    }

    return null;
  }

  void _handleRegionSelect(CharacterRegion region) {
    ref.read(characterCollectionProvider.notifier).handleRegionClick(region.id);
  }

  void _exitAdjustmentMode() {
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _originalRegion = null;
      _adjustingRect = null;
      _currentRotation = 0.0;
    });

    ref.read(characterCollectionProvider.notifier).finishCurrentAdjustment();
  }

  void _handlePanStart(DragStartDetails details) {
    // 桌面端平移开始处理 - 主要依赖InteractiveViewer
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // 桌面端平移更新处理 - 主要依赖InteractiveViewer
  }

  void _handlePanEnd(DragEndDetails details) {
    // 桌面端平移结束处理 - 主要依赖InteractiveViewer
  }

  void _handleSelectionStart(DragStartDetails details) {
    final toolMode = ref.read(toolModeProvider);

    // 只有在框选模式下才处理框选开始事件
    if (toolMode != Tool.select) return;

    // Alt键或右键按下时，交给InteractiveViewer处理平移
    if (_isAltKeyPressed || _isRightMousePressed) {
      return;
    }

    // 如果正在调整，退出调整模式
    if (_isAdjusting) {
      _exitAdjustmentMode();
      return;
    }

    // 检查是否点击了现有选区
    final regions = ref.read(characterCollectionProvider).regions;
    final hitRegion = _hitTestRegion(details.localPosition, regions);

    if (hitRegion != null) {
      // 点击了现有选区，不开始新的框选
      return;
    }

    // 开始新的框选
    setState(() {
      _selectionStart = details.localPosition;
      _selectionCurrent = details.localPosition;
      _hasCompletedSelection = false;
      _lastCompletedSelection = null;
    });

    AppLogger.debug('桌面端开始框选', data: {
      'position': '${details.localPosition.dx}, ${details.localPosition.dy}',
    });
  }

  void _handleSelectionUpdate(DragUpdateDetails details) {
    final toolMode = ref.read(toolModeProvider);

    // 只有在框选模式下才处理框选更新事件
    if (toolMode != Tool.select) return;

    // Alt键或右键按下时，交给InteractiveViewer处理平移
    if (_isAltKeyPressed || _isRightMousePressed) {
      return;
    }

    // 只有在有框选起点时才更新
    if (_selectionStart == null) return;

    setState(() {
      _selectionCurrent = details.localPosition;
    });
  }

  void _handleSelectionEnd(DragEndDetails details) {
    final toolMode = ref.read(toolModeProvider);

    // 只有在框选模式下才处理框选结束事件
    if (toolMode != Tool.select) return;

    // Alt键或右键按下时，交给InteractiveViewer处理平移
    if (_isAltKeyPressed || _isRightMousePressed) {
      return;
    }

    if (_selectionStart == null || _selectionCurrent == null) {
      _resetSelectionState();
      return;
    }

    try {
      final dragDistance = (_selectionCurrent! - _selectionStart!).distance;

      // 检查是否满足最小拖拽距离
      if (dragDistance < 10) {
        AppLogger.debug('拖拽距离太小，取消框选', data: {
          'distance': dragDistance.toStringAsFixed(1),
        });
        _resetSelectionState();
        return;
      }

      // 创建选区
      final viewportRect =
          Rect.fromPoints(_selectionStart!, _selectionCurrent!);
      final imageRect = _transformer!.viewportRectToImageRect(viewportRect);

      // 检查选区大小是否有效
      if (imageRect.width >= 20.0 && imageRect.height >= 20.0) {
        AppLogger.debug('桌面端创建选区', data: {
          'viewportRect': viewportRect.toString(),
          'imageRect': imageRect.toString(),
        });

        ref.read(characterCollectionProvider.notifier).createRegion(imageRect);
        ref
            .read(characterRefreshNotifierProvider.notifier)
            .notifyEvent(RefreshEventType.regionUpdated);
      } else {
        AppLogger.debug('选区尺寸太小，取消创建', data: {
          'width': imageRect.width.toStringAsFixed(1),
          'height': imageRect.height.toStringAsFixed(1),
        });
      }

      _resetSelectionState();
    } catch (e) {
      AppLogger.error('桌面端框选结束错误', error: e);
      _resetSelectionState();
    }
  }

  void _handleAdjustmentPanStart(DragStartDetails details) {
    // Alt键或右键按下时，允许平移图片而不是调整选区
    if (_isAltKeyPressed || _isRightMousePressed) {
      return;
    }

    if (!_isAdjusting || _adjustingRect == null) {
      return;
    }

    final handleIndex = _getHandleIndexFromPosition(details.localPosition);

    AppLogger.debug('桌面端调整开始', data: {
      'localPosition':
          '${details.localPosition.dx},${details.localPosition.dy}',
      'handleIndex': handleIndex,
      'isAltKeyPressed': _isAltKeyPressed,
      'isRightMousePressed': _isRightMousePressed,
    });

    if (handleIndex != null) {
      setState(() {
        _activeHandleIndex = handleIndex;
        _isRotating = (handleIndex == -1);
        if (_isRotating) {
          _rotationCenter = _adjustingRect!.center;
          _rotationStartAngle = _calculateAngle(
            _rotationCenter!,
            details.localPosition,
          );
        }
      });
    }
  }

  void _handleAdjustmentPanUpdate(DragUpdateDetails details) {
    // Alt键或右键按下时，允许平移图片而不是调整选区
    if (_isAltKeyPressed || _isRightMousePressed) {
      return;
    }

    if (!_isAdjusting || _activeHandleIndex == null || _adjustingRect == null) {
      return;
    }

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

      // 在调整过程中实时更新原始区域
      if (_originalRegion != null && _adjustingRect != null) {
        final Rect finalImageRect =
            _transformer!.viewportRectToImageRect(_adjustingRect!);
        final updatedRegion = _originalRegion!.copyWith(
          rect: finalImageRect,
          rotation: _currentRotation,
          updateTime: DateTime.now(),
          isModified: true,
        );
        _originalRegion = updatedRegion;
      }
    });
  }

  void _handleAdjustmentPanEnd(DragEndDetails details) {
    if (!_isAdjusting || _originalRegion == null || _adjustingRect == null) {
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
      isModified: true,
    );

    // 立即更新provider状态
    ref
        .read(characterCollectionProvider.notifier)
        .updateSelectedRegion(updatedRegion);
    ref
        .read(characterRefreshNotifierProvider.notifier)
        .notifyEvent(RefreshEventType.regionUpdated);

    // 重置UI状态，但保持调整模式
    setState(() {
      _activeHandleIndex = null;
      _guideLines = null;
      _isRotating = false;
      _rotationCenter = null;
    });

    AppLogger.debug('桌面端选区调整完成', data: {
      'regionId': updatedRegion.id,
      'newRect':
          '${updatedRegion.rect.left.toStringAsFixed(1)}, ${updatedRegion.rect.top.toStringAsFixed(1)}, ${updatedRegion.rect.width.toStringAsFixed(1)}, ${updatedRegion.rect.height.toStringAsFixed(1)}',
      'newRotation': updatedRegion.rotation.toStringAsFixed(2)
    });
  }

  // 添加缺失的辅助方法

  /// 获取句柄索引
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

    // 🔧 更新控制点位置以匹配新的角落标记式样式
    // 控制点现在向内偏移8px，与绘制逻辑保持一致
    const double inset = 8.0;
    final rect = _adjustingRect!;
    
    final handles = [
      Offset(rect.left + inset, rect.top + inset),       // 左上角
      Offset(rect.center.dx, rect.top + inset),          // 上中
      Offset(rect.right - inset, rect.top + inset),      // 右上角
      Offset(rect.right - inset, rect.center.dy),        // 右中
      Offset(rect.right - inset, rect.bottom - inset),   // 右下角
      Offset(rect.center.dx, rect.bottom - inset),       // 下中
      Offset(rect.left + inset, rect.bottom - inset),    // 左下角
      Offset(rect.left + inset, rect.center.dy),         // 左中
    ];

    // Transform these handle positions if we have rotation
    final transformedHandles = _currentRotation != 0
        ? handles.map((p) => transformPoint(p, false)).toList()
        : handles;

    // Check each handle with transformed positions
    // 🔧 使用更大的点击区域以提高用户体验
    for (int i = 0; i < transformedHandles.length; i++) {
      final handleRect = Rect.fromCenter(
        center: transformedHandles[i],
        width: 20.0, // 增大点击区域
        height: 20.0,
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

  /// 计算角度
  double _calculateAngle(Offset center, Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return math.atan2(dy, dx);
  }

  /// 检查点是否在旋转的矩形内
  bool _isPointInRotatedRect(Offset point, Rect rect, double rotation) {
    if (rotation == 0) {
      return rect.contains(point);
    }

    final center = rect.center;
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;

    // Inverse rotation to transform point to rect's local space
    final cos = math.cos(-rotation);
    final sin = math.sin(-rotation);

    final localX = dx * cos - dy * sin + center.dx;
    final localY = dx * sin + dy * cos + center.dy;

    return rect.contains(Offset(localX, localY));
  }

  /// 调整矩形大小
  Rect _adjustRect(Rect rect, Offset newPosition, int handleIndex) {
    // Implementation based on handle index
    switch (handleIndex) {
      case 0: // Top-left
        return Rect.fromLTRB(
            newPosition.dx, newPosition.dy, rect.right, rect.bottom);
      case 1: // Top-center
        return Rect.fromLTRB(
            rect.left, newPosition.dy, rect.right, rect.bottom);
      case 2: // Top-right
        return Rect.fromLTRB(
            rect.left, newPosition.dy, newPosition.dx, rect.bottom);
      case 3: // Center-right
        return Rect.fromLTRB(rect.left, rect.top, newPosition.dx, rect.bottom);
      case 4: // Bottom-right
        return Rect.fromLTRB(
            rect.left, rect.top, newPosition.dx, newPosition.dy);
      case 5: // Bottom-center
        return Rect.fromLTRB(rect.left, rect.top, rect.right, newPosition.dy);
      case 6: // Bottom-left
        return Rect.fromLTRB(
            newPosition.dx, rect.top, rect.right, newPosition.dy);
      case 7: // Center-left
        return Rect.fromLTRB(newPosition.dx, rect.top, rect.right, rect.bottom);
      default:
        return rect;
    }
  }
}
