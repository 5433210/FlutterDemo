import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/character_collection_provider.dart';
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
  int _pointerCount = 0;
  DateTime _gestureStartTime = DateTime.now();
  Matrix4? _initialTransform;
  final double _rotation = 0.0;

  // 选区相关
  Offset? _selectionStart;
  Offset? _selectionEnd;
  String? _adjustingRegionId;
  CharacterRegion? _originalRegion;
  Rect? _adjustingRect;
  Offset? _dragStartPoint;

  // 调整相关状态
  int? _activeHandleIndex;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    AppLogger.debug('移动端图片预览组件初始化');
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _focusNode.dispose();
    AppLogger.debug('移动端图片预览组件销毁');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(workImageProvider);
    final toolMode = ref.watch(toolModeProvider);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = constraints.biggest;

          if (imageState.imageData == null) {
            return const Center(
              child: Text('请先选择图片'),
            );
          }

          // 获取图片尺寸
          final imageSize = imageState.imageSize;

          // 更新坐标变换器
          _updateTransformer(
            imageSize: imageSize,
            viewportSize: viewportSize,
          );

          // 直接返回内容，不使用Consumer包装整个内容
          return _buildImageContent(
            imageState: imageState,
            viewportSize: viewportSize,
            toolMode: toolMode,
          );
        },
      ),
    );
  }

  /// 构建图片内容（参考桌面版的成功实现）
  Widget _buildImageContent({
    required WorkImageState imageState,
    required Size viewportSize,
    required Tool toolMode,
  }) {
    final regions = ref.watch(characterCollectionProvider).regions;
    final selectedIds = regions.where((r) => r.isSelected).map((r) => r.id).toList();
    
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          constrained: false,
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 10.0,
          panEnabled: toolMode == Tool.pan,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          alignment: Alignment.topLeft,
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
              
              // 选区绘制层 - 使用GestureDetector直接在CustomPaint上
              if (_transformer != null && regions.isNotEmpty)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _onTapUp,
                    child: CustomPaint(
                      painter: RegionsPainter(
                        regions: regions,
                        transformer: _transformer!,
                        hoveredId: null,
                        adjustingRegionId: _adjustingRegionId,
                        currentTool: toolMode,
                        isAdjusting: _isAdjusting,
                        selectedIds: selectedIds,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 处理点击事件（简化版本，参考桌面端）
  void _onTapUp(TapUpDetails details) {
    final toolMode = ref.read(toolModeProvider);
    final regions = ref.read(characterCollectionProvider).regions;
    final position = details.localPosition;
    
    AppLogger.debug('🖱️ 移动端点击事件', data: {
      'position': '${position.dx}, ${position.dy}',
      'toolMode': toolMode.toString(),
      'regionsCount': regions.length,
    });

    // 使用简化的碰撞检测
    final hitRegion = _hitTestRegion(position, regions);
    
    if (hitRegion != null) {
      AppLogger.debug('点击到区域', data: {
        'regionId': hitRegion.id,
        'isSelected': hitRegion.isSelected,
      });
      
      if (toolMode == Tool.pan) {
        // 平移模式：切换选择状态
        ref.read(characterCollectionProvider.notifier).toggleSelection(hitRegion.id);
      } else {
        // 选择模式：选中单个区域
        ref.read(characterCollectionProvider.notifier).selectRegion(hitRegion.id);
      }
    } else {
      // 点击空白区域，清除所有选择
      ref.read(characterCollectionProvider.notifier).clearSelections();
      AppLogger.debug('点击空白区域，清除所有选择');
    }
  }

  /// 碰撞检测（简化版本，参考桌面端）
  CharacterRegion? _hitTestRegion(Offset position, List<CharacterRegion> regions) {
    if (_transformer == null) return null;
    
    // 直接使用transformer的方法进行碰撞检测
    for (final region in regions.reversed) {
      final rect = _transformer!.imageRectToViewportRect(region.rect);
      if (rect.contains(position)) {
        AppLogger.debug('碰撞检测成功', data: {
          'regionId': region.id,
          'viewportRect': '${rect.left}, ${rect.top}, ${rect.width}x${rect.height}',
          'position': '${position.dx}, ${position.dy}',
        });
        return region;
      }
    }
    
    return null;
  }

  /// 处理缩放手势开始
  void _handleScaleStart(ScaleStartDetails details) {
    final toolMode = ref.read(toolModeProvider);

    _pointerCount = details.pointerCount;
    _gestureStartTime = DateTime.now();

    AppLogger.debug('移动端Scale开始', data: {
      'toolMode': toolMode.toString(),
      'pointerCount': details.pointerCount,
      'focalPoint': '${details.focalPoint.dx}, ${details.focalPoint.dy}',
    });

    // 只在选择模式的单指操作时处理自定义逻辑
    // 双指操作留给InteractiveViewer处理
    if (toolMode == Tool.select && _pointerCount == 1) {
      // 记录当前变换状态
      _initialTransform = _transformationController.value.clone();

      AppLogger.debug('初始变换状态', data: {
        'initialScale': _initialTransform!.getMaxScaleOnAxis(),
        'translation':
            '${_initialTransform!.getTranslation().x}, ${_initialTransform!.getTranslation().y}',
      });

      // 选择模式单指：可能是拖拽选区或创建新选区
      final imagePoint = _screenToImagePoint(details.focalPoint);
      if (imagePoint != null) {
        final regions = ref.read(characterCollectionProvider).regions;
        final hitRegion = _findRegionAtPoint(imagePoint, regions);
        if (hitRegion != null) {
          // 开始拖拽选区
          _startRegionDrag(hitRegion, imagePoint);
        } else {
          // 开始创建新选区
          _startRegionCreation(details.focalPoint);
        }
      }
    }
  }

  /// 处理缩放手势更新
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    final toolMode = ref.read(toolModeProvider);

    if (_transformer == null) return;

    AppLogger.debug('移动端Scale更新', data: {
      'toolMode': toolMode.toString(),
      'pointerCount': _pointerCount,
      'scale': details.scale,
      'focalPoint': '${details.focalPoint.dx}, ${details.focalPoint.dy}',
      'isAdjusting': _isAdjusting,
      'isSelecting': _isSelecting,
    });

    // 只处理选择模式下的单指操作
    // 双指操作留给InteractiveViewer处理
    if (toolMode == Tool.select && _pointerCount == 1) {
      if (_isAdjusting) {
        // 拖拽选区
        _updateRegionDrag(details.focalPoint);
      } else if (_isSelecting) {
        // 创建新选区
        _updateRegionCreation(details.focalPoint);
      }
    }
  }

  /// 处理缩放手势结束
  void _handleScaleEnd(ScaleEndDetails details) {
    final toolMode = ref.read(toolModeProvider);

    AppLogger.debug('移动端Scale结束', data: {
      'toolMode': toolMode.toString(),
      'pointerCount': _pointerCount,
      'isSelecting': _isSelecting,
      'isAdjusting': _isAdjusting,
      'velocity': details.velocity.toString(),
      'gestureDuration':
          DateTime.now().difference(_gestureStartTime).inMilliseconds,
    });

    if (_isSelecting) {
      _finishRegionCreation();
    } else if (_isAdjusting) {
      _finishRegionDrag();
    }

    // 重置状态
    _pointerCount = 0;
    _gestureStartTime = DateTime.now();
  }



  /// 处理长按开始
  void _handleLongPressStart(LongPressStartDetails details) {
    final toolMode = ref.read(toolModeProvider);

    AppLogger.debug('移动端长按开始', data: {
      'toolMode': toolMode.toString(),
      'position': '${details.globalPosition.dx}, ${details.globalPosition.dy}',
    });

    final imagePoint = _screenToImagePoint(details.globalPosition);
    if (imagePoint != null) {
      final regions = ref.read(characterCollectionProvider).regions;
      final hitRegion = _findRegionAtPoint(imagePoint, regions);
      if (hitRegion != null) {
        // 长按进入调整模式
        _startRegionAdjustment(hitRegion);
      }
    }
  }

  /// 屏幕坐标转换为图像坐标（用于手势处理）
  Offset? _screenToImagePoint(Offset screenPoint) {
    if (_transformer == null) return null;
    
    // 使用transformer的简化方法
    return _transformer!.viewportToImageCoordinate(screenPoint);
  }


  /// 在指定位置查找字符区域
  CharacterRegion? _findRegionAtPoint(
      Offset imagePoint, List<CharacterRegion> regions) {
    for (final region in regions.reversed) {
      if (region.rect.contains(imagePoint)) {
        return region;
      }
    }
    return null;
  }

  /// 开始选区拖拽
  void _startRegionDrag(CharacterRegion region, Offset imagePoint) {
    // 首先检查是否点击了控制点
    if (_transformer != null) {
      final screenRect = _transformer!.imageRectToViewportRect(region.rect);

      // 将图像坐标转换为视口坐标（屏幕坐标）
      final matrix = _transformationController.value;
      final vector =
          matrix.transform3(Vector3(imagePoint.dx, imagePoint.dy, 0));
      final viewportPoint = Offset(vector.x, vector.y);

      // 检测控制点
      final handleIndex =
          _getHandleIndexFromPosition(viewportPoint, screenRect);

      setState(() {
        _isAdjusting = true;
        _adjustingRegionId = region.id;
        _originalRegion = region;
        _adjustingRect = region.rect;
        _dragStartPoint = imagePoint;
        _activeHandleIndex = handleIndex;
      });

      AppLogger.debug('开始拖拽选区', data: {
        'regionId': region.id,
        'startPoint': '${imagePoint.dx}, ${imagePoint.dy}',
        'handleIndex': handleIndex,
        'screenPoint': '${viewportPoint.dx}, ${viewportPoint.dy}',
      });
    } else {
      // 没有transformer的情况下，只能拖拽整个选区
      setState(() {
        _isAdjusting = true;
        _adjustingRegionId = region.id;
        _originalRegion = region;
        _adjustingRect = region.rect;
        _dragStartPoint = imagePoint;
        _activeHandleIndex = 8; // 拖拽整个选区
      });

      AppLogger.debug('开始拖拽选区（无transformer）', data: {
        'regionId': region.id,
        'startPoint': '${imagePoint.dx}, ${imagePoint.dy}',
      });
    }
  }

  /// 开始创建新选区
  void _startRegionCreation(Offset screenPoint) {
    setState(() {
      _isSelecting = true;
      _selectionStart = screenPoint;
      _selectionEnd = screenPoint;
    });

    AppLogger.debug('开始创建新选区', data: {
      'startPoint': '${screenPoint.dx}, ${screenPoint.dy}',
    });
  }

  /// 平移图片
  /// 更新选区拖拽
  void _updateRegionDrag(Offset screenPoint) {
    if (!_isAdjusting || _dragStartPoint == null || _originalRegion == null) {
      return;
    }

    final currentImagePoint = _screenToImagePoint(screenPoint);
    if (currentImagePoint == null) {
      return;
    }

    // 如果有活动的控制点，使用控制点调整逻辑
    if (_activeHandleIndex != null) {
      _adjustSelectedRegion(currentImagePoint);
    } else {
      // 普通拖拽逻辑
      final delta = currentImagePoint - _dragStartPoint!;
      final newRect = _originalRegion!.rect.translate(delta.dx, delta.dy);

      setState(() {
        _adjustingRect = newRect;
      });
    }
  }

  /// 更新新选区创建
  void _updateRegionCreation(Offset screenPoint) {
    if (!_isSelecting) return;

    setState(() {
      _selectionEnd = screenPoint;
    });
  }

  /// 完成选区拖拽
  void _finishRegionDrag() {
    if (!_isAdjusting || _adjustingRegionId == null || _adjustingRect == null) {
      return;
    }

    // 更新选区位置
    final updatedRegion = _originalRegion!.copyWith(rect: _adjustingRect!);
    ref
        .read(characterCollectionProvider.notifier)
        .updateRegionDisplay(updatedRegion);

    _cleanupAdjustment();
    AppLogger.debug('完成选区拖拽', data: {
      'regionId': _adjustingRegionId,
    });
  }

  /// 完成新选区创建
  void _finishRegionCreation() {
    if (!_isSelecting || _selectionStart == null || _selectionEnd == null) {
      return;
    }

    final startImage = _screenToImagePoint(_selectionStart!);
    final endImage = _screenToImagePoint(_selectionEnd!);

    if (startImage != null && endImage != null) {
      final rect = Rect.fromPoints(startImage, endImage);
      if (rect.width > 10 && rect.height > 10) {
        // 最小尺寸要求
        final newRegion =
            ref.read(characterCollectionProvider.notifier).createRegion(rect);
        if (newRegion != null) {
          AppLogger.debug('创建新选区', data: {
            'regionId': newRegion.id,
            'rect': rect.toString(),
          });
        }
      }
    }

    _cleanupSelection();
  }

  /// 切换选区选择状态
  void _toggleRegionSelection(CharacterRegion region) {
    ref.read(characterCollectionProvider.notifier).toggleSelection(region.id);
  }

  /// 选择单个选区
  void _selectSingleRegion(CharacterRegion region) {
    ref.read(characterCollectionProvider.notifier).selectRegion(region.id);
  }

  /// 清除所有选择
  void _clearAllSelections() {
    ref.read(characterCollectionProvider.notifier).selectRegion(null);
  }

  /// 开始选区调整
  void _startRegionAdjustment(CharacterRegion region) {
    setState(() {
      _isAdjusting = true;
      _adjustingRegionId = region.id;
      _originalRegion = region;
      _adjustingRect = region.rect;
    });

    AppLogger.debug('开始选区调整', data: {
      'regionId': region.id,
    });
  }

  /// 清理调整状态
  void _cleanupAdjustment() {
    setState(() {
      _isAdjusting = false;
      _adjustingRegionId = null;
      _originalRegion = null;
      _adjustingRect = null;
      _dragStartPoint = null;
      _activeHandleIndex = null;
    });
  }

  /// 清理选择状态
  void _cleanupSelection() {
    setState(() {
      _isSelecting = false;
      _selectionStart = null;
      _selectionEnd = null;
    });
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

  /// 变换矩阵变化监听（简化版本）
  void _onTransformationChanged() {
    // 如果正在调整选区，更新其视口位置
    if (_isAdjusting && _originalRegion != null && _transformer != null) {
      final newRect =
          _transformer!.imageRectToViewportRect(_originalRegion!.rect);
      setState(() {
        _adjustingRect = newRect;
      });
    }
  }

  /// 检测控制点位置
  int? _getHandleIndexFromPosition(Offset position, Rect rect) {
    const handleSize = 24.0; // 移动端使用更大的触摸区域

    // 旋转控制点（在顶部中心上方）
    final rotationPoint = Offset(rect.topCenter.dx, rect.topCenter.dy - 40);
    if ((position - rotationPoint).distance < handleSize) {
      return -1; // 旋转句柄
    }

    // 8个调整控制点
    final handles = [
      rect.topLeft, // 0
      rect.topCenter, // 1
      rect.topRight, // 2
      rect.centerRight, // 3
      rect.bottomRight, // 4
      rect.bottomCenter, // 5
      rect.bottomLeft, // 6
      rect.centerLeft, // 7
    ];

    // 检查每个控制点
    for (int i = 0; i < handles.length; i++) {
      final handleRect = Rect.fromCenter(
        center: handles[i],
        width: handleSize,
        height: handleSize,
      );

      if (handleRect.contains(position)) {
        return i;
      }
    }

    // 检查是否在选区内部（用于拖拽整个选区）
    if (rect.contains(position)) {
      return 8; // 拖拽整个选区
    }

    return null;
  }

  /// 调整选中区域的大小或位置
  void _adjustSelectedRegion(Offset currentPoint) {
    if (_adjustingRegionId == null ||
        _dragStartPoint == null ||
        _activeHandleIndex == null) {
      return;
    }

    final region = ref
        .read(characterCollectionProvider)
        .regions
        .where((r) => r.id == _adjustingRegionId)
        .firstOrNull;

    if (region == null) return;

    if (_activeHandleIndex == -1) {
      // 旋转控制
      final center = region.rect.center;
      final angle = _calculateAngle(center, currentPoint);
      final startAngle = _calculateAngle(center, _dragStartPoint!);
      final deltaAngle = angle - startAngle;

      final updatedRegion =
          region.copyWith(rotation: region.rotation + deltaAngle);
      ref
          .read(characterCollectionProvider.notifier)
          .updateSelectedRegion(updatedRegion);
    } else if (_activeHandleIndex == 8) {
      // 拖拽整个选区
      final delta = currentPoint - _dragStartPoint!;
      final newRect = Rect.fromLTWH(
        region.rect.left + delta.dx,
        region.rect.top + delta.dy,
        region.rect.width,
        region.rect.height,
      );

      final updatedRegion = region.copyWith(rect: newRect);
      ref
          .read(characterCollectionProvider.notifier)
          .updateSelectedRegion(updatedRegion);
    } else {
      // 调整大小
      final newRect =
          _adjustRect(region.rect, currentPoint, _activeHandleIndex!);

      final updatedRegion = region.copyWith(rect: newRect);
      ref
          .read(characterCollectionProvider.notifier)
          .updateSelectedRegion(updatedRegion);
    }
  }

  /// 计算角度
  double _calculateAngle(Offset center, Offset point) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return math.atan2(dy, dx);
  }

  /// 调整矩形大小
  Rect _adjustRect(Rect rect, Offset newPosition, int handleIndex) {
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
