import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../../utils/platform/platform_detector.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/character_refresh_notifier.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import 'adjustable_region_painter.dart';
import 'image_view_base.dart';
import 'regions_painter.dart';
import 'selection_painters.dart';

/// 移动端图片预览组件
/// 专门针对触摸设备优化的手势操作实现
class MobileImageView extends ImageViewBase {
  const MobileImageView({super.key});

  @override
  ConsumerState<MobileImageView> createState() => _MobileImageViewState();

  // 实现基类的抽象方法
  @override
  void handleScale(ScaleStartDetails details, ScaleUpdateDetails updateDetails,
      ScaleEndDetails endDetails) {
    // 移动端的缩放实现
  }

  @override
  void handlePan(DragStartDetails details, DragUpdateDetails updateDetails,
      DragEndDetails endDetails) {
    // 移动端的平移实现
  }

  @override
  void handleTap(TapUpDetails details) {
    // 移动端的点击实现
  }

  @override
  void handleLongPress(LongPressStartDetails details) {
    // 移动端的长按实现
  }

  @override
  void handleSelectionCreate(Offset start, Offset end) {
    // 移动端的选区创建实现
  }

  @override
  void handleSelectionAdjust(String regionId, Rect newRect, double rotation) {
    // 移动端的选区调整实现
  }

  @override
  void handleSelectionSelect(String regionId) {
    // 移动端的选区选择实现
  }

  @override
  List<CharacterRegion> getCurrentRegions(WidgetRef ref) {
    return ref.watch(characterCollectionProvider).regions;
  }

  @override
  CharacterRegion? hitTestRegion(
      Offset position, List<CharacterRegion> regions) {
    // 移动端的碰撞检测实现
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
    // 移动端的手势检测器构建
    return child;
  }

  @override
  Widget buildAdjustmentHandles({
    required CharacterRegion region,
    required bool isActive,
    required int? activeHandleIndex,
    required VoidCallback? onHandleDrag,
  }) {
    // 移动端的调整句柄构建
    return const SizedBox.shrink();
  }
}

class _MobileImageViewState extends ConsumerState<MobileImageView>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  final FocusNode _focusNode = FocusNode();
  CoordinateTransformer? _transformer;

  // 移动端特定的状态
  bool _isSelecting = false;
  bool _isAdjusting = false;

  // 手势状态
  Offset? _lastPanPosition;
  double _rotation = 0.0;

  // 选区相关
  Offset? _selectionStart;
  Offset? _selectionEnd;
  String? _adjustingRegionId;
  CharacterRegion? _originalRegion;
  Rect? _adjustingRect;

  // 触摸交互阈值
  late Map<String, double> _thresholds;

  // 调整相关状态
  int? _activeHandleIndex;
  bool _isRotating = false;
  final double _currentRotation = 0.0;

  @override
  void initState() {
    super.initState();
    _thresholds = PlatformDetector.getInteractionThresholds();
    _transformationController.addListener(_onTransformationChanged);
    AppLogger.debug('移动端图片预览组件初始化');
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);
    final characterCollection = ref.watch(characterCollectionProvider);
    final regions = characterCollection.regions;

    if (!imageState.hasValidImage) {
      return const SizedBox.shrink();
    }

    final imageSize = Size(imageState.imageWidth, imageState.imageHeight);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

        _updateTransformer(
          imageSize: imageSize,
          viewportSize: viewportSize,
        );

        return _buildMobileGestureDetector(
          child: _buildImageContent(
            imageState: imageState,
            regions: regions,
            viewportSize: viewportSize,
            toolMode: toolMode,
          ),
        );
      },
    );
  }

  /// 构建移动端专用的手势检测器
  Widget _buildMobileGestureDetector({required Widget child}) {
    final toolMode = ref.watch(toolModeProvider);

    return GestureDetector(
      // 基础点击手势
      onTapUp: _handleTapUp,

      // 长按手势 - 用于进入调整模式
      onLongPressStart: _handleLongPressStart,

      // 只在框选模式下使用Scale手势进行框选
      // 在平移模式下，让InteractiveViewer处理所有手势
      onScaleStart: toolMode == Tool.select ? _handleScaleStart : null,
      onScaleUpdate: toolMode == Tool.select ? _handleScaleUpdate : null,
      onScaleEnd: toolMode == Tool.select ? _handleScaleEnd : null,

      child: child,
    );
  }

  /// 构建图片内容
  Widget _buildImageContent({
    required WorkImageState imageState,
    required List<CharacterRegion> regions,
    required Size viewportSize,
    required Tool toolMode,
  }) {
    return InteractiveViewer(
      transformationController: _transformationController,
      constrained: false,
      minScale: 0.1,
      maxScale: 10.0,
      // 始终启用默认手势，在框选模式下通过自定义手势覆盖单指操作
      panEnabled: true,
      scaleEnabled: true,
      child: Stack(
        children: [
          // 图片层
          Image.memory(
            imageState.imageData!,
            fit: BoxFit.contain,
            alignment: Alignment.topLeft,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
          ),

          // 选区绘制层
          if (_transformer != null && regions.isNotEmpty)
            Positioned.fill(
              child: CustomPaint(
                painter: RegionsPainter(
                  regions: regions,
                  transformer: _transformer!,
                  hoveredId: null, // 移动端不需要hover状态
                  adjustingRegionId: _adjustingRegionId,
                  currentTool: toolMode,
                  isAdjusting: _isAdjusting,
                  selectedIds: regions
                      .where((r) => r.isSelected)
                      .map((r) => r.id)
                      .toList(),
                ),
              ),
            ),

          // 调整控制层
          if (_isAdjusting && _originalRegion != null)
            Positioned.fill(
              child: CustomPaint(
                painter: AdjustableRegionPainter(
                  region: _originalRegion!,
                  transformer: _transformer!,
                  isActive: true,
                  isAdjusting: true,
                  activeHandleIndex: null,
                  currentRotation: _rotation,
                  guideLines: null,
                  viewportRect: _adjustingRect,
                ),
              ),
            ),

          // 选区创建层
          if (_isSelecting && _selectionStart != null && _selectionEnd != null)
            Positioned.fill(
              child: CustomPaint(
                painter: ActiveSelectionPainter(
                  startPoint: _selectionStart!,
                  endPoint: _selectionEnd!,
                  viewportSize: viewportSize,
                  isActive: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 处理点击事件
  void _handleTapUp(TapUpDetails details) {
    final toolMode = ref.read(toolModeProvider);
    final position = details.localPosition;

    AppLogger.debug('移动端点击事件', data: {
      'position': '${position.dx}, ${position.dy}',
      'toolMode': toolMode.toString(),
    });

    try {
      final regions = ref.read(characterCollectionProvider).regions;
      final hitRegion = _hitTestRegion(position, regions);

      if (hitRegion != null) {
        AppLogger.debug('点击了选区', data: {
          'regionId': hitRegion.id,
          'isSelected': hitRegion.isSelected,
        });

        // 切换选区的选中状态
        ref
            .read(characterCollectionProvider.notifier)
            .toggleSelection(hitRegion.id);

        AppLogger.debug('选区选择状态已切换', data: {
          'regionId': hitRegion.id,
          'newState': !hitRegion.isSelected,
        });
      } else {
        AppLogger.debug('点击了空白区域');

        // 如果是框选模式，清除所有选择
        if (toolMode == Tool.select) {
          final selectedRegions = regions.where((r) => r.isSelected).toList();
          if (selectedRegions.isNotEmpty) {
            AppLogger.debug('清除所有选区选择', data: {
              'selectedCount': selectedRegions.length,
            });
            for (final region in selectedRegions) {
              ref
                  .read(characterCollectionProvider.notifier)
                  .toggleSelection(region.id);
            }
          }
        }
      }
    } catch (e, stack) {
      AppLogger.error('移动端点击处理错误', error: e, stackTrace: stack);
    }
  }

  /// 处理长按事件（移动端特有）
  void _handleLongPressStart(LongPressStartDetails details) {
    final regions = ref.read(characterCollectionProvider).regions;
    final position = details.localPosition;

    AppLogger.debug('移动端长按事件', data: {
      'position': '${position.dx}, ${position.dy}',
    });

    // 长按可以用于快速切换工具模式或显示上下文菜单
    final hitRegion = _hitTestRegion(position, regions);

    if (hitRegion != null) {
      // 长按选区进入调整模式
      _enterAdjustmentMode(hitRegion);
    }
  }

  /// 处理缩放开始（简化版本，专注于框选模式）
  void _handleScaleStart(ScaleStartDetails details) {
    final toolMode = ref.read(toolModeProvider);

    // 只在框选模式下处理
    if (toolMode != Tool.select) return;

    _lastPanPosition = details.focalPoint;

    AppLogger.debug('移动端框选模式Scale开始', data: {
      'pointerCount': details.pointerCount,
      'focalPoint': '${details.focalPoint.dx}, ${details.focalPoint.dy}',
    });

    // 单指操作 - 处理框选和调整
    if (details.pointerCount == 1) {
      final position = details.focalPoint;
      final regions = ref.read(characterCollectionProvider).regions;
      final hitRegion = _hitTestRegion(position, regions);

      if (hitRegion != null && hitRegion.isSelected) {
        // 点击了已选中的选区，进入调整模式
        _enterAdjustmentMode(hitRegion);
      } else if (hitRegion != null) {
        // 点击了未选中的选区，先选中它
        ref
            .read(characterCollectionProvider.notifier)
            .toggleSelection(hitRegion.id);
      } else {
        // 点击了空白区域，开始框选
        _startSelection(position);
      }
    }
    // 双指操作让InteractiveViewer处理缩放和平移
  }

  /// 处理缩放更新（简化版本，专注于框选模式）
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final toolMode = ref.read(toolModeProvider);

    // 只在框选模式下处理
    if (toolMode != Tool.select) return;

    final position = details.focalPoint;

    // 双指操作：让InteractiveViewer自动处理缩放和平移
    if (details.pointerCount > 1) {
      // 不做任何处理，让InteractiveViewer处理
      return;
    }

    // 单指操作：处理框选或调整
    if (details.pointerCount == 1) {
      if (_isSelecting) {
        // 框选模式：更新选区
        _updateSelection(position);
      } else if (_isAdjusting && _lastPanPosition != null) {
        // 调整模式：调整选区
        _handleAdjustmentUpdate(position);
      }
    }

    _lastPanPosition = position;
  }

  /// 处理缩放结束（简化版本，专注于框选模式）
  void _handleScaleEnd(ScaleEndDetails details) {
    final toolMode = ref.read(toolModeProvider);

    // 只在框选模式下处理
    if (toolMode != Tool.select) return;

    AppLogger.debug('移动端框选模式Scale结束', data: {
      'pointerCount': details.pointerCount,
      'isSelecting': _isSelecting,
      'isAdjusting': _isAdjusting,
    });

    // 完成相应的操作
    if (_isSelecting) {
      _finishSelection();
    } else if (_isAdjusting) {
      _handleAdjustmentEnd();
    }

    // 重置状态
    _lastPanPosition = null;
  }

  /// 辅助方法：处理调整开始
  void _handleAdjustmentStart(Offset position) {
    _handleAdjustmentPanStart(position);
  }

  /// 辅助方法：处理调整更新
  void _handleAdjustmentUpdate(Offset position) {
    _handleAdjustmentPanUpdate(position);
  }

  /// 辅助方法：处理调整结束
  void _handleAdjustmentEnd() {
    _handleAdjustmentPanEnd();
  }

  /// 开始选区创建
  void _startSelection(Offset position) {
    _isSelecting = true;
    _selectionStart = position;
    _selectionEnd = position;

    setState(() {});
  }

  /// 更新选区
  void _updateSelection(Offset position) {
    _selectionEnd = position;
    setState(() {});
  }

  /// 完成选区创建
  void _finishSelection() {
    if (_selectionStart == null ||
        _selectionEnd == null ||
        _transformer == null) {
      _cancelSelection();
      return;
    }

    final startPoint = _selectionStart!;
    final endPoint = _selectionEnd!;
    final distance = (endPoint - startPoint).distance;

    // 检查是否满足最小选区大小
    if (distance < _thresholds['minSelectionSize']!) {
      _cancelSelection();
      return;
    }

    // 创建选区
    final viewportRect = Rect.fromPoints(startPoint, endPoint);
    final imageRect = _transformer!.viewportRectToImageRect(viewportRect);

    ref.read(characterCollectionProvider.notifier).createRegion(imageRect);

    _cancelSelection();

    AppLogger.debug('移动端选区创建完成', data: {
      'viewportRect': viewportRect.toString(),
      'imageRect': imageRect.toString(),
    });
  }

  /// 取消选区创建
  void _cancelSelection() {
    _isSelecting = false;
    _selectionStart = null;
    _selectionEnd = null;
    setState(() {});
  }

  /// 进入选区调整模式
  void _enterAdjustmentMode(CharacterRegion region) {
    if (_transformer == null) return;

    setState(() {
      _isAdjusting = true;
      _adjustingRegionId = region.id;
      _originalRegion = region;
      _adjustingRect = _transformer!.imageRectToViewportRect(region.rect);
      _rotation = region.rotation;
    });

    AppLogger.debug('移动端进入调整模式', data: {
      'regionId': region.id,
      'rect': region.rect.toString(),
    });
  }

  /// 退出选区调整模式
  void _exitAdjustmentMode() {
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _originalRegion = null;
      _adjustingRect = null;
      _rotation = 0.0;
    });

    ref.read(characterCollectionProvider.notifier).finishCurrentAdjustment();

    AppLogger.debug('移动端退出调整模式');
  }

  /// 处理选区选择
  void _handleRegionSelect(CharacterRegion region) {
    ref.read(characterCollectionProvider.notifier).handleRegionClick(region.id);
  }

  /// 处理调整模式下的平移开始
  void _handleAdjustmentPanStart(Offset position) {
    if (!_isAdjusting || _adjustingRect == null || _transformer == null) return;

    // 检查是否点击了控制手柄或选区内部
    final handleIndex = _getHandleIndexFromPosition(position);

    if (handleIndex != null) {
      setState(() {
        _activeHandleIndex = handleIndex;
        if (handleIndex == -1) {
          // 旋转控制点（移动端暂时禁用）
          _isRotating = false;
        } else if (handleIndex >= 0 && handleIndex < 8) {
          // 大小调整控制点
          _isRotating = false;
        } else if (handleIndex == 8) {
          // 移动整个选区
          _isRotating = false;
        }
      });

      AppLogger.debug('移动端选区调整开始', data: {
        'position': '${position.dx}, ${position.dy}',
        'handleIndex': handleIndex,
        'isRotating': _isRotating,
      });
    }
  }

  /// 处理调整模式下的平移更新
  void _handleAdjustmentPanUpdate(Offset position) {
    if (!_isAdjusting || _adjustingRect == null || _activeHandleIndex == null)
      return;

    setState(() {
      if (_activeHandleIndex! >= 0 && _activeHandleIndex! < 8) {
        // 大小调整
        _adjustingRect = _adjustRect(
          _adjustingRect!,
          position,
          _activeHandleIndex!,
        );
      } else if (_activeHandleIndex == 8) {
        // 移动选区
        final delta = position - _lastPanPosition!;
        _adjustingRect = _adjustingRect!.translate(delta.dx, delta.dy);
      }

      // 更新原始区域数据
      if (_transformer != null && _originalRegion != null) {
        final imageRect =
            _transformer!.viewportRectToImageRect(_adjustingRect!);
        _originalRegion = _originalRegion!.copyWith(
          rect: imageRect,
          rotation: _currentRotation,
          updateTime: DateTime.now(),
          isModified: true,
        );
      }
    });

    _lastPanPosition = position;
  }

  /// 处理调整模式下的平移结束
  void _handleAdjustmentPanEnd() {
    if (!_isAdjusting || _originalRegion == null || _adjustingRect == null)
      return;

    // 提交选区更改
    final finalImageRect =
        _transformer!.viewportRectToImageRect(_adjustingRect!);
    final updatedRegion = _originalRegion!.copyWith(
      rect: finalImageRect,
      rotation: _currentRotation,
      updateTime: DateTime.now(),
      isModified: true,
    );

    // 更新Provider状态
    ref
        .read(characterCollectionProvider.notifier)
        .updateSelectedRegion(updatedRegion);
    ref
        .read(characterRefreshNotifierProvider.notifier)
        .notifyEvent(RefreshEventType.regionUpdated);

    // 重置调整状态
    setState(() {
      _activeHandleIndex = null;
      _isRotating = false;
    });

    AppLogger.debug('移动端选区调整完成', data: {
      'regionId': updatedRegion.id,
      'newRect': finalImageRect.toString(),
      'newRotation': updatedRegion.rotation.toStringAsFixed(2),
    });
  }

  /// 调整选区大小
  Rect _adjustRect(Rect rect, Offset position, int handleIndex) {
    // 移动端简化的选区调整实现
    // 为了避免复杂的变换计算，暂时不支持旋转调整

    Rect newRect;
    const minSize = 40.0; // 移动端使用更大的最小尺寸

    switch (handleIndex) {
      case 0: // 左上角
        newRect = Rect.fromPoints(position, rect.bottomRight);
        break;
      case 1: // 上边中点
        newRect =
            Rect.fromLTRB(rect.left, position.dy, rect.right, rect.bottom);
        break;
      case 2: // 右上角
        newRect = Rect.fromPoints(rect.bottomLeft, position);
        break;
      case 3: // 右边中点
        newRect = Rect.fromLTRB(rect.left, rect.top, position.dx, rect.bottom);
        break;
      case 4: // 右下角
        newRect = Rect.fromPoints(rect.topLeft, position);
        break;
      case 5: // 下边中点
        newRect = Rect.fromLTRB(rect.left, rect.top, rect.right, position.dy);
        break;
      case 6: // 左下角
        newRect = Rect.fromPoints(position, rect.topRight);
        break;
      case 7: // 左边中点
        newRect = Rect.fromLTRB(position.dx, rect.top, rect.right, rect.bottom);
        break;
      case 8: // 移动整个选区
        if (_lastPanPosition != null) {
          final delta = position - _lastPanPosition!;
          newRect = rect.translate(delta.dx, delta.dy);
        } else {
          newRect = rect;
        }
        break;
      default:
        return rect;
    }

    // 确保最小尺寸
    if (newRect.width < minSize) {
      final center = newRect.center;
      newRect = Rect.fromCenter(
          center: center, width: minSize, height: newRect.height);
    }
    if (newRect.height < minSize) {
      final center = newRect.center;
      newRect = Rect.fromCenter(
          center: center, width: newRect.width, height: minSize);
    }

    return newRect;
  }

  /// 获取手柄索引（移动端优化版本）
  int? _getHandleIndexFromPosition(Offset position) {
    if (_adjustingRect == null) return null;

    const touchRadius = 24.0; // 移动端使用更大的触摸区域

    // 检查是否点击了控制手柄
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
        width: touchRadius,
        height: touchRadius,
      );

      if (handleRect.contains(position)) {
        return i;
      }
    }

    // 检查是否点击了选区内部（移动选区）
    final expandedRect = _adjustingRect!.inflate(-touchRadius / 2);
    if (expandedRect.contains(position)) {
      return 8;
    }

    return null;
  }

  /// 碰撞检测
  CharacterRegion? _hitTestRegion(
      Offset position, List<CharacterRegion> regions) {
    if (_transformer == null) return null;

    // 为移动端增加更大的点击区域
    const touchRadius = 12.0;

    for (final region in regions.reversed) {
      final rect = _transformer!.imageRectToViewportRect(region.rect);
      final expandedRect = rect.inflate(touchRadius);

      if (expandedRect.contains(position)) {
        return region;
      }
    }

    return null;
  }

  /// 更新坐标变换器
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

  /// 变换矩阵变化监听
  void _onTransformationChanged() {
    if (_isAdjusting && _originalRegion != null && _transformer != null) {
      // 更新调整中的选区位置
      final newRect =
          _transformer!.imageRectToViewportRect(_originalRegion!.rect);
      setState(() {
        _adjustingRect = newRect;
      });
    }
  }
}
