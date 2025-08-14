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

  // 🔧 内部变换矩阵管理 - 避免依赖容易重置的TransformationController
  Matrix4 _internalMatrix = Matrix4.identity();
  bool _isMatrixInitialized = false;

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

  // 平移模式点击检测相关
  bool _isInteracting = false;
  Offset? _interactionStartPosition;
  DateTime? _interactionStartTime;

  // 🔧 添加防抖机制，避免频繁的矩阵恢复操作
  DateTime? _lastRestoreAttempt;

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

          return Consumer(
            builder: (context, ref, child) {
              // 🔧 使用PostFrameCallback避免在每次build时都检查矩阵
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _restoreMatrixIfNeeded();
              });

              return _buildImageContent(
                imageState: imageState,
                viewportSize: viewportSize,
                toolMode: toolMode,
              );
            },
          );
        },
      ),
    );
  }

  /// 构建图片内容
  Widget _buildImageContent({
    required WorkImageState imageState,
    required Size viewportSize,
    required Tool toolMode,
  }) {
    // 在平移模式下，我们需要在InteractiveViewer外面包装一个GestureDetector
    // 来处理点击事件，避免与InteractiveViewer的平移行为冲突
    Widget interactiveContent = InteractiveViewer(
      key: const ValueKey('mobile_interactive_viewer'), // 🔑 添加key防止重建时重置matrix
      transformationController: _transformationController,
      constrained: false,
      minScale: 0.1,
      maxScale: 10.0,
      // 启用基本的平移和缩放功能
      panEnabled: toolMode == Tool.pan, // 只在平移模式下启用平移
      scaleEnabled: true,
      // 使用合理的边界设置，确保变换矩阵正常更新
      boundaryMargin: const EdgeInsets.all(double.infinity),
      // 允许超出边界但不无限制
      // clipBehavior: Clip.none,
      alignment: Alignment.topLeft,
      // 添加InteractiveViewer回调以确保矩阵正确更新
      onInteractionStart: _handleInteractionStart,
      onInteractionUpdate: _handleInteractionUpdate,
      onInteractionEnd: _handleInteractionEnd,
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

          // 选区绘制层 - 使用独立的Consumer避免影响InteractiveViewer
          Consumer(
            builder: (context, ref, child) {
              final currentRegions =
                  ref.watch(characterCollectionProvider).regions;

              if (_transformer == null || currentRegions.isEmpty) {
                return const SizedBox.shrink();
              }

              return Positioned.fill(
                child: CustomPaint(
                  painter: RegionsPainter(
                    regions: currentRegions,
                    transformer: _transformer!,
                    hoveredId: null, // 移动端不需要hover状态
                    adjustingRegionId: _adjustingRegionId,
                    currentTool: toolMode,
                    isAdjusting: _isAdjusting,
                    selectedIds: currentRegions
                        .where((r) => r.isSelected)
                        .map((r) => r.id)
                        .toList(),
                  ),
                ),
              );
            },
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
                  activeHandleIndex: _activeHandleIndex,
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

          // 手势检测层 - 只在选择模式下激活
          if (toolMode == Tool.select)
            Positioned.fill(
              child: GestureDetector(
                onTapUp: _handleTapUp,
                onLongPressStart: _handleLongPressStart,
                onScaleStart: _handleScaleStart,
                onScaleUpdate: _handleScaleUpdate,
                onScaleEnd: _handleScaleEnd,
                behavior: HitTestBehavior.translucent,
                child: Container(), // 透明容器接收手势
              ),
            ),
        ],
      ),
    );

    // 在平移模式下，使用外层的GestureDetector来处理点击
    if (toolMode == Tool.pan) {
      return GestureDetector(
        onTapUp: (details) {
          // 直接处理点击，不依赖InteractiveViewer的回调
          _handlePanModeClick(details.localPosition);
        },
        behavior: HitTestBehavior.deferToChild,
        child: interactiveContent,
      );
    }

    return interactiveContent;
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

  /// 处理点击（基础点击手势）
  void _handleTapUp(TapUpDetails details) {
    final toolMode = ref.read(toolModeProvider);

    AppLogger.debug('移动端点击', data: {
      'toolMode': toolMode.toString(),
      'position': '${details.globalPosition.dx}, ${details.globalPosition.dy}',
    });

    final imagePoint = _screenToImagePoint(details.globalPosition);
    if (imagePoint != null) {
      final regions = ref.read(characterCollectionProvider).regions;

      if (toolMode == Tool.select) {
        // 选择模式：选中或取消选中字符区域
        final hitRegion = _findRegionAtPoint(imagePoint, regions);
        if (hitRegion != null) {
          _toggleRegionSelection(hitRegion);
        } else {
          // 点击空白区域，取消所有选择
          _clearAllSelections();
        }
      } else if (toolMode == Tool.pan) {
        // 平移模式：点击选中字符区域
        final hitRegion = _findRegionAtPoint(imagePoint, regions);
        if (hitRegion != null) {
          _selectSingleRegion(hitRegion);
        } else {
          _clearAllSelections();
        }
      }
    }
  }

  /// 处理平移模式的点击事件（支持多选和反选）
  void _handlePanModeClick(Offset localPosition) {
    AppLogger.debug('平移模式点击检测', data: {
      'localPosition': '${localPosition.dx}, ${localPosition.dy}',
    });

    // 使用localPosition并应用InteractiveViewer的变换矩阵来转换为图像坐标
    final imagePoint = _localToImagePoint(localPosition);
    AppLogger.debug('坐标转换结果', data: {
      'localPosition': '${localPosition.dx}, ${localPosition.dy}',
      'imagePoint':
          imagePoint != null ? '${imagePoint.dx}, ${imagePoint.dy}' : 'null',
      'hasTransformer': _transformer != null,
    });

    if (imagePoint == null) {
      AppLogger.warning('坐标转换失败，无法处理点击');
      return;
    }

    final regions = ref.read(characterCollectionProvider).regions;
    AppLogger.debug('当前区域数量', data: {
      'totalRegions': regions.length,
      'regionsList': regions
          .map((r) => '${r.id}: ${r.rect} (selected: ${r.isSelected})')
          .toList(),
    });

    final hitRegion = _findRegionAtPoint(imagePoint, regions);
    AppLogger.debug('碰撞检测结果', data: {
      'hitRegion': hitRegion?.id,
      'hitRegionSelected': hitRegion?.isSelected,
    });

    if (hitRegion != null) {
      // 检查是否已选中该区域
      if (hitRegion.isSelected) {
        // 已选中，执行反选
        ref
            .read(characterCollectionProvider.notifier)
            .toggleSelection(hitRegion.id);
        AppLogger.debug('平移模式反选区域', data: {
          'regionId': hitRegion.id,
        });
      } else {
        // 未选中，执行多选（不清除其他选择）
        ref
            .read(characterCollectionProvider.notifier)
            .addToSelection(hitRegion.id);
        AppLogger.debug('平移模式多选区域', data: {
          'regionId': hitRegion.id,
        });
      }
    } else {
      // 点击空白区域，取消所有选择
      _clearAllSelections();
      AppLogger.debug('平移模式取消所有选择');
    }
  }

  /// 处理InteractiveViewer的交互开始（用于平移模式的点击检测）
  void _handleInteractionStart(ScaleStartDetails details) {
    // 只处理单指点击，多指留给InteractiveViewer处理缩放
    if (details.pointerCount == 1) {
      _interactionStartPosition = details.focalPoint;
      _interactionStartTime = DateTime.now();
      _isInteracting = true;

      AppLogger.debug('平移模式交互开始', data: {
        'position': '${details.focalPoint.dx}, ${details.focalPoint.dy}',
        'pointerCount': details.pointerCount,
      });
    } else {
      // 多指操作，清除点击检测
      _interactionStartPosition = null;
      _interactionStartTime = null;
      _isInteracting = false;

      AppLogger.debug('平移模式多指交互开始', data: {
        'pointerCount': details.pointerCount,
      });
    }
  }

  /// 处理InteractiveViewer的交互结束（用于平移模式的点击检测）
  void _handleInteractionEnd(ScaleEndDetails details) {
    AppLogger.debug('平移模式交互结束', data: {
      'velocity': details.velocity.toString(),
      'isInteracting': _isInteracting,
      'hasStartPosition': _interactionStartPosition != null,
    });

    // 检查是否是单指点击
    if (_isInteracting &&
        _interactionStartPosition != null &&
        _interactionStartTime != null) {
      final duration = DateTime.now().difference(_interactionStartTime!);
      final velocity = details.velocity.pixelsPerSecond.distance;

      AppLogger.debug('平移模式点击检测参数', data: {
        'duration': duration.inMilliseconds,
        'velocity': velocity,
        'startPosition':
            '${_interactionStartPosition!.dx}, ${_interactionStartPosition!.dy}',
      });

      // 更宽松的点击检测条件：时间不超过300ms且速度不超过50px/s
      if (duration.inMilliseconds < 300 && velocity < 50) {
        AppLogger.debug('检测到点击，触发选择逻辑');
        _handlePanModeClick(_interactionStartPosition!);
      } else {
        AppLogger.debug('检测到拖拽，忽略点击逻辑', data: {
          'reason': duration.inMilliseconds >= 300
              ? 'duration_too_long'
              : 'velocity_too_high',
        });
      }
    }

    // 重置交互状态
    _isInteracting = false;
    _interactionStartPosition = null;
    _interactionStartTime = null;
  }

  /// 处理InteractiveViewer的交互更新（用于记录矩阵变化）
  void _handleInteractionUpdate(ScaleUpdateDetails details) {
    // 记录矩阵更新，特别是缩放操作
    if (details.scale != 1.0 ||
        details.horizontalScale != 1.0 ||
        details.verticalScale != 1.0) {
      AppLogger.debug('InteractiveViewer缩放更新', data: {
        'scale': details.scale.toStringAsFixed(3),
        'horizontalScale': details.horizontalScale.toStringAsFixed(3),
        'verticalScale': details.verticalScale.toStringAsFixed(3),
        'matrix': _transformationController.value.toString(),
      });
    }
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

  /// 将本地坐标（相对于InteractiveViewer的坐标）转换为图像坐标
  Offset? _localToImagePoint(Offset localPosition) {
    if (_transformer == null) {
      AppLogger.warning('坐标转换失败：transformer为null');
      return null;
    }

    try {
      // 🔧 使用内部保存的变换矩阵，避免依赖可能被重置的TransformationController
      final matrix = _internalMatrix;

      // 计算逆矩阵来反向变换坐标
      final invertedMatrix = Matrix4.identity();
      final determinant = matrix.copyInverse(invertedMatrix);

      if (determinant == 0) {
        AppLogger.warning('内部矩阵逆变换失败：determinant = 0');
        return null;
      }

      // 应用逆变换将视口坐标转换为图像坐标
      final transformed = invertedMatrix.transform3(Vector3(
        localPosition.dx,
        localPosition.dy,
        0.0,
      ));

      final imagePoint = Offset(transformed.x, transformed.y);

      AppLogger.debug('本地坐标到图像坐标转换（使用内部矩阵）', data: {
        'localPosition': '${localPosition.dx}, ${localPosition.dy}',
        'imagePoint': '${imagePoint.dx}, ${imagePoint.dy}',
        'internalMatrix': matrix.toString(),
        'isInternalMatrixIdentity': matrix.isIdentity(),
      });

      return imagePoint;
    } catch (e) {
      AppLogger.error('坐标转换失败', error: e, data: {
        'localPosition': '${localPosition.dx}, ${localPosition.dy}',
      });
      return null;
    }
  }

  /// 屏幕坐标转换为图片坐标
  Offset? _screenToImagePoint(Offset screenPoint) {
    if (_transformer == null) {
      AppLogger.warning('坐标转换失败：transformer为null');
      return null;
    }

    try {
      // 获取变换参数
      final currentScale = _transformer!.currentScale;
      final baseScale = _transformer!.baseScale;
      final currentOffset = _transformer!.currentOffset;
      final imageSize = _transformer!.imageSize;
      final viewportSize = _transformer!.viewportSize;

      // 🔧 使用内部保存的变换矩阵，避免依赖可能被重置的TransformationController
      final matrix = _internalMatrix;
      final invertedMatrix = Matrix4.identity();
      final determinant = matrix.copyInverse(invertedMatrix);

      Offset imagePoint;

      if (determinant != 0) {
        final transformed = invertedMatrix.transform3(Vector3(
          screenPoint.dx,
          screenPoint.dy,
          0.0,
        ));

        // 得到考虑用户缩放/平移后的坐标
        final userTransformedPoint = Offset(transformed.x, transformed.y);

        // 计算图像在视口中的居中偏移
        final scaledImageWidth = imageSize.width * baseScale;
        final scaledImageHeight = imageSize.height * baseScale;
        final centerOffsetX = (viewportSize.width - scaledImageWidth) / 2;
        final centerOffsetY = (viewportSize.height - scaledImageHeight) / 2;

        // 减去居中偏移，然后除以基础缩放得到图像坐标
        imagePoint = Offset(
          (userTransformedPoint.dx - centerOffsetX) / baseScale,
          (userTransformedPoint.dy - centerOffsetY) / baseScale,
        );

        AppLogger.debug('坐标转换详情（使用内部矩阵）', data: {
          'screenPoint': '${screenPoint.dx}, ${screenPoint.dy}',
          'userTransformed':
              '${userTransformedPoint.dx}, ${userTransformedPoint.dy}',
          'imageSize': '${imageSize.width}x${imageSize.height}',
          'viewportSize': '${viewportSize.width}x${viewportSize.height}',
          'scaledImageSize':
              '${scaledImageWidth.toStringAsFixed(1)}x${scaledImageHeight.toStringAsFixed(1)}',
          'centerOffset':
              '${centerOffsetX.toStringAsFixed(1)}, ${centerOffsetY.toStringAsFixed(1)}',
          'finalImagePoint': '${imagePoint.dx}, ${imagePoint.dy}',
          'currentScale': currentScale.toStringAsFixed(3),
          'baseScale': baseScale.toStringAsFixed(3),
          'currentOffset': '${currentOffset.dx}, ${currentOffset.dy}',
          'internalMatrix': matrix.toString(),
          'isInternalMatrixIdentity': matrix.isIdentity(),
        });
      } else {
        AppLogger.warning('内部矩阵逆变换失败：determinant = 0');
        return null;
      }

      return imagePoint;
    } catch (e) {
      AppLogger.error('坐标转换失败', error: e, data: {
        'screenPoint': '${screenPoint.dx}, ${screenPoint.dy}',
      });
      return null;
    }
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

  /// 🔧 检查并恢复内部矩阵到TransformationController
  void _restoreMatrixIfNeeded() {
    final now = DateTime.now();

    // 🔧 防抖：避免频繁执行，最多每100ms检查一次
    if (_lastRestoreAttempt != null &&
        now.difference(_lastRestoreAttempt!).inMilliseconds < 100) {
      return;
    }
    _lastRestoreAttempt = now;

    final currentMatrix = _transformationController.value;

    // 如果TransformationController的矩阵被重置为identity，但我们有保存的非identity矩阵
    if (currentMatrix.isIdentity() &&
        _isMatrixInitialized &&
        !_internalMatrix.isIdentity()) {
      AppLogger.debug('检测到TransformationController被重置，恢复内部矩阵', data: {
        'currentMatrix': currentMatrix.toString(),
        'internalMatrix': _internalMatrix.toString(),
      });

      // 恢复矩阵
      _transformationController.value = _internalMatrix.clone();
    }
  }

  /// 变换矩阵变化监听
  void _onTransformationChanged() {
    final matrix = _transformationController.value;

    // 🔧 保存变换矩阵到内部变量，避免依赖容易重置的TransformationController
    if (!matrix.isIdentity() || !_isMatrixInitialized) {
      _internalMatrix = matrix.clone();
      _isMatrixInitialized = true;

      AppLogger.debug('保存内部变换矩阵', data: {
        'matrix': matrix.toString(),
        'isIdentity': matrix.isIdentity(),
        'scaleX': matrix.entry(0, 0),
        'scaleY': matrix.entry(1, 1),
        'translateX': matrix.entry(0, 3),
        'translateY': matrix.entry(1, 3),
      });
    }

    if (_isAdjusting && _originalRegion != null && _transformer != null) {
      // 更新调整中的选区位置
      final newRect =
          _transformer!.imageRectToViewportRect(_originalRegion!.rect);
      setState(() {
        _adjustingRect = newRect;
      });
    }
  }

  /// 🔧 手动更新内部矩阵（用于特殊情况）
  void _updateInternalMatrix(Matrix4 newMatrix) {
    _internalMatrix = newMatrix.clone();
    _isMatrixInitialized = true;

    AppLogger.debug('手动更新内部矩阵', data: {
      'newMatrix': newMatrix.toString(),
      'isIdentity': newMatrix.isIdentity(),
    });
  }

  /// 🔧 获取当前有效的变换矩阵（优先使用内部矩阵）
  Matrix4 _getCurrentMatrix() {
    return _isMatrixInitialized
        ? _internalMatrix
        : _transformationController.value;
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
