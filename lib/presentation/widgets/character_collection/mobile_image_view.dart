import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../domain/models/character/character_region.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/coordinate_transformer.dart';
import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/tool_mode_provider.dart';
import '../../providers/character/work_image_provider.dart';
import 'image_view_base.dart';
import 'regions_painter.dart';

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
  bool _isDraggingRegion = false; // 是否正在拖拽选区
  CharacterRegion? _draggingRegion; // 正在拖拽的选区
  Offset? _dragStartPosition; // 拖拽开始位置
  Rect? _originalDragRect; // 拖拽开始时的原始矩形

  // 手势状态
  int _pointerCount = 0;
  DateTime _gestureStartTime = DateTime.now();
  Matrix4? _initialTransform;

  // 选区相关
  Offset? _selectionStart;
  Offset? _selectionEnd;
  String? _adjustingRegionId;
  CharacterRegion? _originalRegion;
  Rect? _adjustingRect;
  Offset? _dragStartPoint;

  // 调整相关状态
  int? _activeHandleIndex;

  // 控制点点压状态
  bool _isHandlePressed = false;
  String? _pressedRegionId;
  int? _pressedHandleIndex;

  // 控制点拖拽调整状态
  bool _isAdjustingHandle = false;
  String? _adjustingHandleRegionId;
  int? _adjustingHandleIndex;
  CharacterRegion? _originalAdjustingRegion;
  Offset? _adjustingStartPosition;

  // 指针事件追踪
  final Map<int, Offset> _activePointers = {};
  bool _isMultiPointer = false;
  Offset? _singlePointerStart;
  bool _isDragging = false;
  
  // 新增：多指手勢狀態追蹤
  bool _hasBeenMultiPointer = false;  // 記錄本次手勢序列是否曾經是多指
  int _maxPointerCount = 0;  // 記錄本次手勢序列的最大指針數量
  DateTime? _lastPointerDownTime;  // 記錄最後一次指針按下的時間
  
  // 手勢識別常量
  static const Duration _gestureStabilizationDelay = Duration(milliseconds: 50);  // 手勢穩定延遲
  static const double _dragThreshold = 15.0;  // 拖拽閾值，增加防止誤觸發

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

    // 调试输出：检查工具模式
    if (toolMode == Tool.select) {
      print('💆 MobileImageView build - toolMode: $toolMode');
    }

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
    final selectedIds =
        regions.where((r) => r.isSelected).map((r) => r.id).toList();

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          constrained: false,
          transformationController: _transformationController,
          minScale: 0.1,
          maxScale: 10.0,
          panEnabled: toolMode == Tool.pan,
          scaleEnabled: true, // 保持缩放始终启用
          boundaryMargin: const EdgeInsets.all(double.infinity),
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none, // 防止裁剪问题
          onInteractionStart: (details) {
            // 验证变换矩阵的有效性
            final matrix = _transformationController.value;
            if (matrix.determinant().abs() < 1e-10) {
              // 矩阵接近奇异，重置为单位矩阵
              AppLogger.debug('检测到奇异矩阵，重置变换');
              _transformationController.value = Matrix4.identity();
            }
          },
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

              // 选区绘制层 - 智能手势检测
              if (_transformer != null) ...[
                Positioned.fill(
                  child: Builder(
                    builder: (context) {
                      // 调试信息
                      if (regions.isNotEmpty) {
                        print('📐 MobileImageView: 正在绘制 ${regions.length} 个选区');
                      }
                      return GestureDetector(
                        // 优化手势检测：允许多指手势透传给InteractiveViewer
                        behavior: HitTestBehavior.translucent,

                        onTapUp: _onTapUp,
                        // 不再直接使用onPan*，改为使用Listener监听原始事件
                        
                        child: Listener(
                          onPointerDown: _onPointerDown,
                          onPointerMove: _onPointerMove,
                          onPointerUp: _onPointerUp,
                          onPointerCancel: _onPointerCancel,
                          child: CustomPaint(
                            painter: RegionsPainter(
                              regions: regions,
                              transformer: _transformer!,
                              hoveredId: null,
                              adjustingRegionId: _adjustingRegionId,
                              currentTool: toolMode,
                              isAdjusting: _isAdjusting,
                              selectedIds: selectedIds,
                              // 添加创建中选区的支持
                              isSelecting: _isSelecting,
                              selectionStart: _selectionStart,
                              selectionEnd: _selectionEnd,
                              // 添加控制点状态支持
                              pressedRegionId: _pressedRegionId,
                              pressedHandleIndex: _pressedHandleIndex,
                              isHandlePressed: _isHandlePressed,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
        ref
            .read(characterCollectionProvider.notifier)
            .toggleSelection(hitRegion.id);

        // 如果选中了区域，更新右侧编辑面板
        if (!hitRegion.isSelected) {
          // toggleSelection后会变为选中状态
          ref.read(selectedRegionProvider.notifier).setRegion(hitRegion);
        } else {
          // 如果取消选择，清除右侧编辑面板
          ref.read(selectedRegionProvider.notifier).clearRegion();
        }
      } else {
        // 选择模式（采集工具）：处理选区点击
        if (hitRegion.isSelected) {
          // 如果点击的是已选中的区域，进入adjusting状态并准备拖拽
          AppLogger.debug('点击已选中区域，进入adjusting状态', data: {
            'regionId': hitRegion.id,
          });
          
          setState(() {
            _isAdjusting = true;
            _adjustingRegionId = hitRegion.id;
            _originalRegion = hitRegion;
            
            // 同时设置拖拽状态，以便后续的指针事件能够正确处理
            _isDraggingRegion = false; // 暂时不设置，等到真正开始拖拽时再设置
          });
          
          // 更新右侧编辑面板显示选中的区域
          ref.read(selectedRegionProvider.notifier).setRegion(hitRegion);
        } else {
          // 选中单个区域
          ref
              .read(characterCollectionProvider.notifier)
              .selectRegion(hitRegion.id);

          // 更新右侧编辑面板显示选中的区域
          ref.read(selectedRegionProvider.notifier).setRegion(hitRegion);
        }
      }
    } else {
      // 点击空白区域，清除所有选择并退出adjusting状态
      ref.read(characterCollectionProvider.notifier).clearSelections();
      ref.read(selectedRegionProvider.notifier).clearRegion();
      
      setState(() {
        _isAdjusting = false;
        _adjustingRegionId = null;
        _originalRegion = null;
      });
      
      AppLogger.debug('点击空白区域，清除所有选择并退出adjusting状态');
    }
  }

  /// 碰撞检测（简化版本，参考桌面端）
  CharacterRegion? _hitTestRegion(
      Offset position, List<CharacterRegion> regions) {
    if (_transformer == null) return null;

    // 直接使用transformer的方法进行碰撞检测
    for (final region in regions.reversed) {
      final rect = _transformer!.imageRectToViewportRect(region.rect);
      if (rect.contains(position)) {
        AppLogger.debug('碰撞检测成功', data: {
          'regionId': region.id,
          'viewportRect':
              '${rect.left}, ${rect.top}, ${rect.width}x${rect.height}',
          'position': '${position.dx}, ${position.dy}',
        });
        return region;
      }
    }

    return null;
  }

  /// 检测控制点的点击
  /// 返回: {regionId: String?, handleIndex: int?}
  Map<String, dynamic> _hitTestHandle(
      Offset position, List<CharacterRegion> regions) {
    if (_transformer == null) {
      return {'regionId': null, 'handleIndex': null};
    }

    // 只检测已选中的区域的控制点
    for (final region in regions.reversed) {
      if (!region.isSelected) continue;

      final rect = _transformer!.imageRectToViewportRect(region.rect);
      final handleIndex = _getHandleIndexFromPosition(position, rect);

      if (handleIndex != null) {
        AppLogger.debug('控制点碰撞检测成功', data: {
          'regionId': region.id,
          'handleIndex': handleIndex,
          'position': '${position.dx}, ${position.dy}',
        });
        return {'regionId': region.id, 'handleIndex': handleIndex};
      }
    }

    return {'regionId': null, 'handleIndex': null};
  }

  /// 检测控制点位置
  int? _getHandleIndexFromPosition(Offset position, Rect rect) {
    const handleSize = 32.0; // 增大移动端触摸区域

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

    // 检查每个控制点，使用更大的触摸区域
    for (int i = 0; i < handles.length; i++) {
      final handleRect = Rect.fromCenter(
        center: handles[i],
        width: handleSize,
        height: handleSize,
      );

      if (handleRect.contains(position)) {
        AppLogger.debug('控制点命中检测', data: {
          'handleIndex': i,
          'handleCenter': '${handles[i].dx}, ${handles[i].dy}',
          'position': '${position.dx}, ${position.dy}',
          'handleRect': '${handleRect.left}, ${handleRect.top}, ${handleRect.width}x${handleRect.height}',
          'distance': (position - handles[i]).distance,
        });
        return i;
      }
    }

    return null;
  }

  /// 处理平移开始（选区拖拽或创建新选区）
  void _onPanStart(DragStartDetails details) {
    final position = details.localPosition;
    final regions = ref.read(characterCollectionProvider).regions;
    final toolMode = ref.read(toolModeProvider);

    // 简单的调试输出，确保被调用
    print('🔄 _onPanStart 被调用: ${position.dx}, ${position.dy}');
    
    AppLogger.debug('🔄 移动端平移开始', data: {
      'position': '${position.dx}, ${position.dy}',
      'regionsCount': regions.length,
      'toolMode': toolMode.toString(),
      'selectedRegionsCount': regions.where((r) => r.isSelected).length,
      'currentStates': {
        '_isDraggingRegion': _isDraggingRegion,
        '_isSelecting': _isSelecting,
        '_isAdjusting': _isAdjusting,
      }
    });

    // 在框选模式下，优先检测控制点
    if (toolMode == Tool.select) {
      // 增强控制点检测，使用更精确的检测逻辑
      for (final region in regions.reversed) {
        if (!region.isSelected) continue;
        
        final rect = _transformer!.imageRectToViewportRect(region.rect);
        final handleIndex = _getHandleIndexFromPosition(position, rect);
        
        if (handleIndex != null) {
          // 点击了控制点，开始控制点拖拽调整
          setState(() {
            _isHandlePressed = true;
            _pressedRegionId = region.id;
            _pressedHandleIndex = handleIndex;
            // 开始控制点调整
            _isAdjustingHandle = true;
            _adjustingHandleRegionId = region.id;
            _adjustingHandleIndex = handleIndex;
            _originalAdjustingRegion = region;
            _adjustingStartPosition = position;
          });

          AppLogger.debug('🎯 控制点拖拽调整开始', data: {
            'regionId': region.id,
            'handleIndex': handleIndex,
            'startPosition': '${position.dx}, ${position.dy}',
            'originalRect':
                '${region.rect.left}, ${region.rect.top}, ${region.rect.width}x${region.rect.height}',
          });

          return; // 直接返回，不继续处理其他操作
        }
      }
    }

    // 检查是否点击了选中的区域
    final hitRegion = _hitTestRegion(position, regions);

    AppLogger.debug('🔍 碰撞检测结果', data: {
      'hitRegion': hitRegion != null
          ? {
              'id': hitRegion.id,
              'isSelected': hitRegion.isSelected,
              'rect':
                  '${hitRegion.rect.left}, ${hitRegion.rect.top}, ${hitRegion.rect.width}x${hitRegion.rect.height}',
            }
          : null,
    });

    if (hitRegion != null && hitRegion.isSelected) {
      // 开始拖拽选中的区域
      setState(() {
        _isDraggingRegion = true;
        _draggingRegion = hitRegion;
        _dragStartPosition = position;
        _originalDragRect = hitRegion.rect;
      });

      AppLogger.debug('✅ 开始拖拽选区', data: {
        'regionId': hitRegion.id,
        'originalRect':
            '${hitRegion.rect.left}, ${hitRegion.rect.top}, ${hitRegion.rect.width}x${hitRegion.rect.height}',
      });
    } else {
      // 点击空白区域，开始创建新选区
      AppLogger.debug('🆕 准备开始创建新选区', data: {
        'startPosition': '${position.dx}, ${position.dy}',
        'transformer': _transformer != null ? 'available' : 'null',
      });

      // 先清除所有已选中的选区
      ref.read(characterCollectionProvider.notifier).clearSelections();
      ref.read(selectedRegionProvider.notifier).clearRegion();
      AppLogger.debug('清除已选中选区后开始创建新选区');

      _startRegionCreation(position);

      AppLogger.debug('✅ 已调用_startRegionCreation', data: {
        'startPosition': '${position.dx}, ${position.dy}',
        'newStates': {
          '_isSelecting': _isSelecting,
          '_selectionStart': _selectionStart != null
              ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
              : 'null',
          '_selectionEnd': _selectionEnd != null
              ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
              : 'null',
        }
      });
    }
  }

  /// 处理平移更新（选区拖拽或选区创建）
  void _onPanUpdate(DragUpdateDetails details) {
    final currentPosition = details.localPosition;

    AppLogger.debug('🔄 _onPanUpdate 开始', data: {
      'currentPosition': '${currentPosition.dx}, ${currentPosition.dy}',
      'states': {
        '_isDraggingRegion': _isDraggingRegion,
        '_isSelecting': _isSelecting,
        '_isAdjusting': _isAdjusting,
        '_isAdjustingHandle': _isAdjustingHandle,
      }
    });

    if (_isAdjustingHandle) {
      // 控制点拖拽调整选区大小
      _updateHandleAdjustment(currentPosition);
    } else if (_isDraggingRegion) {
      // 拖拽现有选区
      if (_draggingRegion == null ||
          _dragStartPosition == null ||
          _originalDragRect == null) {
        AppLogger.debug('❌ 拖拽选区条件不满足', data: {
          '_draggingRegion': _draggingRegion?.id ?? 'null',
          '_dragStartPosition': _dragStartPosition != null
              ? '${_dragStartPosition!.dx}, ${_dragStartPosition!.dy}'
              : 'null',
          '_originalDragRect': _originalDragRect != null
              ? '${_originalDragRect!.left}, ${_originalDragRect!.top}, ${_originalDragRect!.width}x${_originalDragRect!.height}'
              : 'null',
        });
        return;
      }

      final delta = currentPosition - _dragStartPosition!;

      AppLogger.debug('🔄 移动端平移更新（拖拽选区）', data: {
        'delta': '${delta.dx}, ${delta.dy}',
        'currentPosition': '${currentPosition.dx}, ${currentPosition.dy}',
      });

      // 将delta转换为图像坐标系中的偏移量
      final deltaStart =
          _transformer!.viewportToImageCoordinate(_dragStartPosition!);
      final deltaCurrent =
          _transformer!.viewportToImageCoordinate(currentPosition);
      final imageDelta = Offset(
          deltaCurrent.dx - deltaStart.dx, deltaCurrent.dy - deltaStart.dy);

      // 计算新的图像矩形位置
      final newImageRect = Rect.fromLTWH(
        _originalDragRect!.left + imageDelta.dx,
        _originalDragRect!.top + imageDelta.dy,
        _originalDragRect!.width,
        _originalDragRect!.height,
      );

      // 实时更新选区位置
      final updatedRegion = _draggingRegion!.copyWith(
        rect: newImageRect,
        updateTime: DateTime.now(),
        isModified: true,
      );

      ref
          .read(characterCollectionProvider.notifier)
          .updateRegionDisplay(updatedRegion);
    } else if (_isSelecting) {
      // 创建新选区
      AppLogger.debug('🆕 _onPanUpdate 调用_updateRegionCreation', data: {
        'currentPosition': '${currentPosition.dx}, ${currentPosition.dy}',
        'selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        'selectionEnd_before': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      });

      _updateRegionCreation(currentPosition);

      AppLogger.debug('✅ _onPanUpdate 已调用_updateRegionCreation', data: {
        'currentPosition': '${currentPosition.dx}, ${currentPosition.dy}',
        'selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        'selectionEnd_after': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      });
    } else {
      AppLogger.debug('⚠️ _onPanUpdate 无操作', data: {
        'currentPosition': '${currentPosition.dx}, ${currentPosition.dy}',
        'states': {
          '_isDraggingRegion': _isDraggingRegion,
          '_isSelecting': _isSelecting,
          '_isAdjusting': _isAdjusting,
        }
      });
    }
  }

  /// 处理平移结束（选区拖拽或选区创建）
  void _onPanEnd(DragEndDetails details) {
    AppLogger.debug('🏁 _onPanEnd 开始', data: {
      'states': {
        '_isDraggingRegion': _isDraggingRegion,
        '_isSelecting': _isSelecting,
        '_isAdjusting': _isAdjusting,
        '_isHandlePressed': _isHandlePressed,
        '_isAdjustingHandle': _isAdjustingHandle,
      }
    });

    // 处理控制点调整完成
    if (_isAdjustingHandle) {
      _finishHandleAdjustment();
      return; // 直接返回，不继续处理其他操作
    }

    // 处理控制点释放（仅点压，未拖拽）
    if (_isHandlePressed && !_isAdjustingHandle) {
      setState(() {
        _isHandlePressed = false;
        _pressedRegionId = null;
        _pressedHandleIndex = null;
      });

      AppLogger.debug('🎯 控制点点压结束（仅点压）', data: {
        'previousRegionId': _pressedRegionId,
        'previousHandleIndex': _pressedHandleIndex,
      });

      return; // 直接返回，不继续处理其他操作
    }

    if (_isDraggingRegion) {
      // 完成选区拖拽
      if (_draggingRegion == null) {
        AppLogger.debug('❌ 拖拽结束条件不满足: _draggingRegion = null');
        return;
      }

      // 获取最新的选区数据
      final regions = ref.read(characterCollectionProvider).regions;
      final updatedRegion = regions.firstWhere(
        (r) => r.id == _draggingRegion!.id,
        orElse: () => _draggingRegion!,
      );

      AppLogger.debug('🔄 移动端平移结束（拖拽选区）', data: {
        'regionId': updatedRegion.id,
        'finalRect':
            '${updatedRegion.rect.left}, ${updatedRegion.rect.top}, ${updatedRegion.rect.width}x${updatedRegion.rect.height}',
      });

      // 更新右侧字符编辑面板的选区
      if (updatedRegion.isSelected) {
        ref.read(selectedRegionProvider.notifier).setRegion(updatedRegion);
        AppLogger.debug('更新右侧编辑面板选区', data: {
          'regionId': updatedRegion.id,
          'newRect':
              '${updatedRegion.rect.left}, ${updatedRegion.rect.top}, ${updatedRegion.rect.width}x${updatedRegion.rect.height}',
        });
      }

      // 清理拖拽状态
      setState(() {
        _isDraggingRegion = false;
        _draggingRegion = null;
        _dragStartPosition = null;
        _originalDragRect = null;
      });
    } else if (_isSelecting) {
      // 完成选区创建
      AppLogger.debug('🆕 _onPanEnd 准备调用_finishRegionCreation', data: {
        'selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        'selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
        '_isSelecting': _isSelecting,
      });

      _finishRegionCreation();

      AppLogger.debug('✅ _onPanEnd 已调用_finishRegionCreation', data: {
        'statesAfter': {
          '_isSelecting': _isSelecting,
          '_selectionStart': _selectionStart != null
              ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
              : 'null',
          '_selectionEnd': _selectionEnd != null
              ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
              : 'null',
        }
      });
    } else {
      AppLogger.debug('⚠️ _onPanEnd 无操作', data: {
        'states': {
          '_isDraggingRegion': _isDraggingRegion,
          '_isSelecting': _isSelecting,
          '_isAdjusting': _isAdjusting,
          '_isHandlePressed': _isHandlePressed,
        }
      });
    }
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
    // 注意：现在使用指针事件处理，不再使用这些方法
    // if (toolMode == Tool.select && _pointerCount == 1) {
    //   if (_isAdjusting) {
    //     _updateRegionDrag(details.focalPoint);
    //   } else if (_isSelecting) {
    //     _updateRegionCreation(details.focalPoint);
    //   }
    // }
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

  /// 完成控制点调整
  void _finishHandleAdjustment() {
    if (!_isAdjustingHandle || _adjustingHandleRegionId == null) {
      AppLogger.debug('❌ 控制点调整完成条件不满足');
      return;
    }

    // 获取最新的选区数据
    final regions = ref.read(characterCollectionProvider).regions;
    final updatedRegion =
        regions.where((r) => r.id == _adjustingHandleRegionId!).firstOrNull;

    AppLogger.debug('🎯 控制点调整完成', data: {
      'regionId': _adjustingHandleRegionId!,
      'handleIndex': _adjustingHandleIndex,
      'finalRect': updatedRegion != null
          ? '${updatedRegion.rect.left}, ${updatedRegion.rect.top}, ${updatedRegion.rect.width}x${updatedRegion.rect.height}'
          : 'null',
    });

    // 更新右侧字符编辑面板的选区
    if (updatedRegion != null && updatedRegion.isSelected) {
      ref.read(selectedRegionProvider.notifier).setRegion(updatedRegion);
      AppLogger.debug('更新右侧编辑面板选区', data: {
        'regionId': updatedRegion.id,
        'newRect':
            '${updatedRegion.rect.left}, ${updatedRegion.rect.top}, ${updatedRegion.rect.width}x${updatedRegion.rect.height}',
      });
    }

    // 清理控制点调整状态
    setState(() {
      _isHandlePressed = false;
      _pressedRegionId = null;
      _pressedHandleIndex = null;
      _isAdjustingHandle = false;
      _adjustingHandleRegionId = null;
      _adjustingHandleIndex = null;
      _originalAdjustingRegion = null;
      _adjustingStartPosition = null;
    });
  }

  /// 更新控制點拖拽調整（簡化版 - 直接使用圖像坐標）
  void _updateHandleAdjustment(Offset currentPosition) {
    if (!_isAdjustingHandle ||
        _originalAdjustingRegion == null ||
        _adjustingStartPosition == null ||
        _adjustingHandleIndex == null) {
      AppLogger.debug('❌ 控制點調整條件不滿足');
      return;
    }

    // 在InteractiveViewer中，坐標已經是圖像坐標系，直接計算偏移量
    final imageDelta = currentPosition - _adjustingStartPosition!;

    final originalRect = _originalAdjustingRegion!.rect;
    final handleIndex = _adjustingHandleIndex!;

    // 根據控制點索引計算新的矩形
    Rect newRect =
        _calculateNewRectForHandle(originalRect, imageDelta, handleIndex);

    // 確保矩形有最小尺寸
    const minSize = 10.0;
    if (newRect.width < minSize || newRect.height < minSize) {
      // 如果矩形太小，保持最小尺寸
      if (newRect.width < minSize) {
        if (handleIndex == 0 || handleIndex == 6 || handleIndex == 7) {
          // 左側控制點，調整left
          newRect = Rect.fromLTRB(newRect.right - minSize, newRect.top,
              newRect.right, newRect.bottom);
        } else {
          // 右側控制點，調整right
          newRect = Rect.fromLTRB(newRect.left, newRect.top,
              newRect.left + minSize, newRect.bottom);
        }
      }
      if (newRect.height < minSize) {
        if (handleIndex == 0 || handleIndex == 1 || handleIndex == 2) {
          // 頂部控制點，調整top
          newRect = Rect.fromLTRB(newRect.left, newRect.bottom - minSize,
              newRect.right, newRect.bottom);
        } else {
          // 底部控制點，調整bottom
          newRect = Rect.fromLTRB(
              newRect.left, newRect.top, newRect.right, newRect.top + minSize);
        }
      }
    }

    // 獲取圖像尺寸進行邊界檢查
    final imageState = ref.read(workImageProvider);
    final imageSize = imageState.imageSize;
    
    if (imageSize != null) {
      // 確保選區不會超出圖像邊界
      newRect = Rect.fromLTRB(
        newRect.left.clamp(0.0, imageSize.width),
        newRect.top.clamp(0.0, imageSize.height),
        newRect.right.clamp(0.0, imageSize.width),
        newRect.bottom.clamp(0.0, imageSize.height),
      );
      
      // 重新檢查最小尺寸（邊界裁剪後可能變小）
      if (newRect.width < minSize || newRect.height < minSize) {
        AppLogger.debug('⚠️ 控制點調整後選區太小，取消更新', data: {
          'newRect': '${newRect.left}, ${newRect.top}, ${newRect.width}x${newRect.height}',
          'minSize': minSize,
        });
        return;
      }
    }

    // 實時更新選區
    final updatedRegion = _originalAdjustingRegion!.copyWith(
      rect: newRect,
      updateTime: DateTime.now(),
      isModified: true,
    );

    AppLogger.debug('🎯 控制點調整更新', data: {
      'handleIndex': handleIndex,
      'imageDelta': '${imageDelta.dx}, ${imageDelta.dy}',
      'originalRect':
          '${originalRect.left}, ${originalRect.top}, ${originalRect.width}x${originalRect.height}',
      'newRect':
          '${newRect.left}, ${newRect.top}, ${newRect.width}x${newRect.height}',
    });

    ref
        .read(characterCollectionProvider.notifier)
        .updateRegionDisplay(updatedRegion);
  }

  /// 根据控制点索引和偏移量计算新矩形
  Rect _calculateNewRectForHandle(
      Rect originalRect, Offset delta, int handleIndex) {
    double left = originalRect.left;
    double top = originalRect.top;
    double right = originalRect.right;
    double bottom = originalRect.bottom;

    switch (handleIndex) {
      case 0: // topLeft - 左上角
        left += delta.dx;
        top += delta.dy;
        break;
      case 1: // topCenter - 上边中点
        top += delta.dy;
        break;
      case 2: // topRight - 右上角
        right += delta.dx;
        top += delta.dy;
        break;
      case 3: // centerRight - 右边中点
        right += delta.dx;
        break;
      case 4: // bottomRight - 右下角
        right += delta.dx;
        bottom += delta.dy;
        break;
      case 5: // bottomCenter - 下边中点
        bottom += delta.dy;
        break;
      case 6: // bottomLeft - 左下角
        left += delta.dx;
        bottom += delta.dy;
        break;
      case 7: // centerLeft - 左边中点
        left += delta.dx;
        break;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// 开始创建新选区
  void _startRegionCreation(Offset screenPoint) {
    AppLogger.debug('🚀 _startRegionCreation 开始', data: {
      'screenPoint': '${screenPoint.dx}, ${screenPoint.dy}',
      'currentStates_before': {
        '_isSelecting': _isSelecting,
        '_selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        '_selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      }
    });

    // 边界检查：确保起始点在图像范围内
    final imageState = ref.read(workImageProvider);
    Offset clampedScreenPoint = screenPoint;
    final imageSize = imageState.imageSize;
    
    if (imageSize != null) {
      clampedScreenPoint = Offset(
        screenPoint.dx.clamp(0.0, imageSize.width),
        screenPoint.dy.clamp(0.0, imageSize.height),
      );
      
      if (clampedScreenPoint != screenPoint) {
        AppLogger.debug('🛡️ 选区创建起始点被裁剪', data: {
          'original': '${screenPoint.dx}, ${screenPoint.dy}',
          'clamped': '${clampedScreenPoint.dx}, ${clampedScreenPoint.dy}',
          'imageSize': '${imageSize.width}x${imageSize.height}',
        });
      }
    }

    setState(() {
      _isSelecting = true;
      _selectionStart = clampedScreenPoint;
      _selectionEnd = clampedScreenPoint;
    });

    AppLogger.debug('✅ _startRegionCreation setState完成', data: {
      'originalPoint': '${screenPoint.dx}, ${screenPoint.dy}',
      'clampedPoint': '${clampedScreenPoint.dx}, ${clampedScreenPoint.dy}',
      'newStates_after': {
        '_isSelecting': _isSelecting,
        '_selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        '_selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      }
    });
  }

  /// 更新新选区创建
  void _updateRegionCreation(Offset screenPoint) {
    AppLogger.debug('🔄 _updateRegionCreation 开始', data: {
      'screenPoint': '${screenPoint.dx}, ${screenPoint.dy}',
      'currentStates_before': {
        '_isSelecting': _isSelecting,
        '_selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        '_selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      }
    });

    if (!_isSelecting) {
      AppLogger.debug('❌ _updateRegionCreation 条件不满足: _isSelecting = false');
      return;
    }

    // 边界检查：确保屏幕点在图像范围内
    final imageState = ref.read(workImageProvider);
    Offset clampedScreenPoint = screenPoint;
    final imageSize = imageState.imageSize;
    
    if (imageSize != null) {
      clampedScreenPoint = Offset(
        screenPoint.dx.clamp(0.0, imageSize.width),
        screenPoint.dy.clamp(0.0, imageSize.height),
      );
      
      if (clampedScreenPoint != screenPoint) {
        AppLogger.debug('🛡️ 选区创建位置被裁剪', data: {
          'original': '${screenPoint.dx}, ${screenPoint.dy}',
          'clamped': '${clampedScreenPoint.dx}, ${clampedScreenPoint.dy}',
          'imageSize': '${imageSize.width}x${imageSize.height}',
        });
      }
    }

    setState(() {
      _selectionEnd = clampedScreenPoint;
    });

    AppLogger.debug('✅ _updateRegionCreation setState完成', data: {
      'originalPoint': '${screenPoint.dx}, ${screenPoint.dy}',
      'clampedPoint': '${clampedScreenPoint.dx}, ${clampedScreenPoint.dy}',
      'newStates_after': {
        '_isSelecting': _isSelecting,
        '_selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        '_selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      }
    });
  }

  /// 完成新选区创建
  void _finishRegionCreation() {
    AppLogger.debug('🏁 _finishRegionCreation 开始', data: {
      'currentStates': {
        '_isSelecting': _isSelecting,
        '_selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        '_selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      }
    });

    if (!_isSelecting || _selectionStart == null || _selectionEnd == null) {
      AppLogger.debug('❌ _finishRegionCreation 条件不满足', data: {
        '_isSelecting': _isSelecting,
        '_selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        '_selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      });
      return;
    }

    final startImage = _selectionStart!;
    final endImage = _selectionEnd!;

    AppLogger.debug('🔄 坐標處理（直接使用圖像坐標）', data: {
      'selectionStart': '${_selectionStart!.dx}, ${_selectionStart!.dy}',
      'selectionEnd': '${_selectionEnd!.dx}, ${_selectionEnd!.dy}',
      'note': '在InteractiveViewer中，觸摸坐標已經是圖像坐標系',
    });

    // 獲取圖像尺寸進行邊界檢查
    final imageState = ref.read(workImageProvider);
    final imageSize = imageState.imageSize;
    
    if (imageSize == null) {
      AppLogger.debug('❌ 圖像尺寸未知，無法創建選區');
      _cleanupSelection();
      return;
    }
    
    // 對坐標進行邊界裁剪
    final clampedStart = Offset(
      startImage.dx.clamp(0.0, imageSize.width),
      startImage.dy.clamp(0.0, imageSize.height),
    );
    final clampedEnd = Offset(
      endImage.dx.clamp(0.0, imageSize.width),
      endImage.dy.clamp(0.0, imageSize.height),
    );
    
    final rect = Rect.fromPoints(clampedStart, clampedEnd);

    AppLogger.debug('🔄 創建的矩形信息 (邊界裁剪後)', data: {
      'originalStart': '${startImage.dx}, ${startImage.dy}',
      'originalEnd': '${endImage.dx}, ${endImage.dy}',
      'clampedStart': '${clampedStart.dx}, ${clampedStart.dy}',
      'clampedEnd': '${clampedEnd.dx}, ${clampedEnd.dy}',
      'imageSize': '${imageSize.width}x${imageSize.height}',
      'rect': '${rect.left}, ${rect.top}, ${rect.width}x${rect.height}',
      'width': rect.width,
      'height': rect.height,
      'minSizeCheck': rect.width > 10 && rect.height > 10,
    });

    if (rect.width > 10 && rect.height > 10) {
      // 最小尺寸要求
      AppLogger.debug('✅ 開始創建新選區', data: {
        'rect': rect.toString(),
      });

      final newRegion =
          ref.read(characterCollectionProvider.notifier).createRegion(rect);

      if (newRegion != null) {
        AppLogger.debug('🎉 新選區創建成功', data: {
          'regionId': newRegion.id,
          'rect': rect.toString(),
        });
      } else {
        AppLogger.debug('❌ 新選區創建失敗', data: {
          'rect': rect.toString(),
        });
      }
    } else {
      AppLogger.debug('❌ 選區尺寸太小，未創建', data: {
        'rect': '${rect.left}, ${rect.top}, ${rect.width}x${rect.height}',
        'minSizeRequired': '10x10',
      });
    }

    _cleanupSelection();

    AppLogger.debug('✅ _finishRegionCreation 清理完成', data: {
      'statesAfter': {
        '_isSelecting': _isSelecting,
        '_selectionStart': _selectionStart != null
            ? '${_selectionStart!.dx}, ${_selectionStart!.dy}'
            : 'null',
        '_selectionEnd': _selectionEnd != null
            ? '${_selectionEnd!.dx}, ${_selectionEnd!.dy}'
            : 'null',
      }
    });
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
    // 验证变换矩阵的有效性
    final matrix = _transformationController.value;
    if (matrix.determinant().abs() < 1e-10) {
      // 矩阵接近奇异，重置为单位矩阵
      AppLogger.debug('变换监听器检测到奇异矩阵，重置变换');
      _transformationController.value = Matrix4.identity();
      return;
    }

    // 如果正在调整选区，更新其视口位置
    if (_isAdjusting && _originalRegion != null && _transformer != null) {
      try {
        final newRect =
            _transformer!.imageRectToViewportRect(_originalRegion!.rect);
        setState(() {
          _adjustingRect = newRect;
        });
      } catch (e) {
        // 如果坐标转换失败，重置变换矩阵
        AppLogger.error('坐标转换失败，重置变换矩阵', error: e);
        _transformationController.value = Matrix4.identity();
      }
    }
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

  /// 處理指針按下事件
  void _onPointerDown(PointerDownEvent event) {
    final toolMode = ref.read(toolModeProvider);
    // 只在采集工具模式下处理拖拽操作
    if (toolMode != Tool.select) return;

    _activePointers[event.pointer] = event.localPosition;
    _isMultiPointer = _activePointers.length > 1;
    _maxPointerCount = math.max(_maxPointerCount, _activePointers.length);

    // 如果變成多指操作，記錄狀態並立即停止任何單指操作
    if (_isMultiPointer) {
      _hasBeenMultiPointer = true;
      
      // 立即停止任何正在進行的單指操作
      if (_isDragging) {
        AppLogger.debug('🛑 多指檢測，停止單指操作', data: {
          'wasSelecting': _isSelecting,
          'wasDraggingRegion': _isDraggingRegion,
          'wasAdjustingHandle': _isAdjustingHandle,
        });
        
        _cancelCurrentGesture();
      }
      
      print('💆 多指檢測: ${event.pointer}, 數量: ${_activePointers.length}, 最大: $_maxPointerCount');
      return; // 多指操作交給InteractiveViewer處理
    }

    print('💆 指針按下: ${event.pointer}, 數量: ${_activePointers.length}, 曾經多指: $_hasBeenMultiPointer');

    // 只有在真正的單指操作且從未變成多指時才處理
    if (!_hasBeenMultiPointer && !_isMultiPointer) {
      // 檢查時間穩定性：如果上次指針操作太近，可能是快速多指操作的一部分
      final now = DateTime.now();
      if (_lastPointerDownTime != null) {
        final timeSinceLastDown = now.difference(_lastPointerDownTime!);
        if (timeSinceLastDown < _gestureStabilizationDelay) {
          // 太快的連續指針操作，可能是多指手勢的一部分，暫時忽略
          AppLogger.debug('⏱️ 快速連續指針操作，忽略', data: {
            'timeSinceLastDown': timeSinceLastDown.inMilliseconds,
          });
          return;
        }
      }
      
      // 記錄本次指針按下時間
      _lastPointerDownTime = now;
      
      // 單指操作，開始選區創建或控制點操作
      _singlePointerStart = event.localPosition;
      _isDragging = false;
      
      // 邊界檢查：確保指針位置在圖像範圍內
      final imageState = ref.read(workImageProvider);
      final imageSize = imageState.imageSize;
      if (imageSize != null) {
        final clampedPosition = Offset(
          event.localPosition.dx.clamp(0.0, imageSize.width),
          event.localPosition.dy.clamp(0.0, imageSize.height),
        );
        _singlePointerStart = clampedPosition;
      }
      
      // 檢查是否點擊了控制點
      final regions = ref.read(characterCollectionProvider).regions;
      bool hitHandle = false;
      
      print('💆 檢查控制點碰撞: 選中區域數量: ${regions.where((r) => r.isSelected).length}');
      
      for (final region in regions.reversed) {
        if (!region.isSelected) continue;
        
        final rect = _transformer!.imageRectToViewportRect(region.rect);
        final handleIndex = _getHandleIndexFromPosition(_singlePointerStart!, rect);
        
        if (handleIndex != null) {
          // 點擊了控制點
          print('💆 控制點碰撞成功: region: ${region.id}, handle: $handleIndex');
          setState(() {
            _isHandlePressed = true;
            _pressedRegionId = region.id;
            _pressedHandleIndex = handleIndex;
            _isAdjustingHandle = true;
            _adjustingHandleRegionId = region.id;
            _adjustingHandleIndex = handleIndex;
            _originalAdjustingRegion = region;
            _adjustingStartPosition = _singlePointerStart!;
          });
          hitHandle = true;
          break;
        }
      }
      
      if (!hitHandle) {
        // 沒有點擊控制點，可能是選區操作
        final hitRegion = _hitTestRegion(_singlePointerStart!, regions);
        print('💆 選區碰撞檢查: ${hitRegion?.id}, selected: ${hitRegion?.isSelected}, adjusting: $_isAdjusting');
        
        if (hitRegion != null && hitRegion.isSelected) {
          // 點擊了已選中的選區，開始拖拽
          print('💆 選區拖拽準備: ${hitRegion.id}');
          setState(() {
            _isDraggingRegion = true;
            _draggingRegion = hitRegion;
            _dragStartPosition = _singlePointerStart!;
            _originalDragRect = hitRegion.rect;
            
            // 如果还没有进入adjusting状态，现在进入
            if (!_isAdjusting) {
              _isAdjusting = true;
              _adjustingRegionId = hitRegion.id;
              _originalRegion = hitRegion;
            }
          });
        } else if (hitRegion != null && !hitRegion.isSelected) {
          // 点击了未选中的选区，先选中它
          print('💆 選中未選中的選區: ${hitRegion.id}');
          ref.read(characterCollectionProvider.notifier).selectRegion(hitRegion.id);
          ref.read(selectedRegionProvider.notifier).setRegion(hitRegion);
        } else {
          print('💆 準備創建新選區');
        }
      }
    }
  }

  /// 取消當前手勢操作
  void _cancelCurrentGesture() {
    setState(() {
      // 清除選區創建狀態
      if (_isSelecting) {
        _isSelecting = false;
        _selectionStart = null;
        _selectionEnd = null;
      }
      
      // 清除選區拖拽狀態
      if (_isDraggingRegion) {
        _isDraggingRegion = false;
        _draggingRegion = null;
        _dragStartPosition = null;
        _originalDragRect = null;
      }
      
      // 清除控制點調整狀態
      if (_isAdjustingHandle) {
        _isAdjustingHandle = false;
        _adjustingHandleRegionId = null;
        _adjustingHandleIndex = null;
        _originalAdjustingRegion = null;
        _adjustingStartPosition = null;
        _isHandlePressed = false;
        _pressedRegionId = null;
        _pressedHandleIndex = null;
      }
      
      // 重置拖拽狀態
      _isDragging = false;
      _singlePointerStart = null;
    });
    
    AppLogger.debug('✅ 手勢操作已取消');
  }

  /// 處理指針移動事件
  void _onPointerMove(PointerMoveEvent event) {
    final toolMode = ref.read(toolModeProvider);
    // 只在采集工具模式下处理拖拽操作
    if (toolMode != Tool.select) return;

    print('💆 指針移動: ${event.pointer}, 位置: ${event.localPosition.dx.toStringAsFixed(1)}, ${event.localPosition.dy.toStringAsFixed(1)}');

    if (_activePointers.containsKey(event.pointer)) {
      // 邊界檢查：確保移動位置在圖像範圍內
      final imageState = ref.read(workImageProvider);
      Offset clampedPosition = event.localPosition;
      final imageSize = imageState.imageSize;
      
      if (imageSize != null) {
        clampedPosition = Offset(
          event.localPosition.dx.clamp(0.0, imageSize.width),
          event.localPosition.dy.clamp(0.0, imageSize.height),
        );
      }
      
      _activePointers[event.pointer] = clampedPosition;
      
      // 檢查是否變成了多指操作
      final wasMultiPointer = _isMultiPointer;
      _isMultiPointer = _activePointers.length > 1;
      _maxPointerCount = math.max(_maxPointerCount, _activePointers.length);
      
      if (!wasMultiPointer && _isMultiPointer) {
        // 從單指變成多指，立即停止單指操作
        _hasBeenMultiPointer = true;
        if (_isDragging) {
          AppLogger.debug('🛑 移動中檢測到多指，停止單指操作', data: {
            'pointerCount': _activePointers.length,
            'wasSelecting': _isSelecting,
          });
          _cancelCurrentGesture();
        }
        print('💆 移動中多指檢測: 數量: ${_activePointers.length}');
        return;
      }
    }

    // 多指手勢不處理，讓InteractiveViewer處理
    if (_isMultiPointer || _hasBeenMultiPointer) {
      print('💆 忽略多指移動: isMulti: $_isMultiPointer, hadBeenMulti: $_hasBeenMultiPointer');
      return;
    }

    print('💆 單指移動處理: start: $_singlePointerStart, hasBeenMulti: $_hasBeenMultiPointer, isMulti: $_isMultiPointer');

    // 單指手勢處理 - 只有在從未變成多指且當前確實是單指時才處理
    if (_singlePointerStart != null && !_hasBeenMultiPointer && !_isMultiPointer) {
      // 使用裁剪後的位置計算距離
      final imageState = ref.read(workImageProvider);
      Offset clampedPosition = event.localPosition;
      final imageSize = imageState.imageSize;
      
      if (imageSize != null) {
        clampedPosition = Offset(
          event.localPosition.dx.clamp(0.0, imageSize.width),
          event.localPosition.dy.clamp(0.0, imageSize.height),
        );
      }
      
      final distance = (clampedPosition - _singlePointerStart!).distance;
      print('💆 移動距離: ${distance.toStringAsFixed(1)}, 閾值: $_dragThreshold, isDragging: $_isDragging');
      
      if (!_isDragging && distance > _dragThreshold) {
        // 開始拖拽
        _isDragging = true;
        print('💆 開始拖拽操作');
        
        if (_isAdjustingHandle) {
          // 控制點調整
          print('🎯 開始控制點調整');
        } else if (_isDraggingRegion) {
          // 選區拖拽
          print('📊 開始選區拖拽');
        } else {
          // 創建新選區
          ref.read(characterCollectionProvider.notifier).clearSelections();
          ref.read(selectedRegionProvider.notifier).clearRegion();
          _startRegionCreation(_singlePointerStart!);
          print('🆕 開始創建選區');
        }
      }
      
      if (_isDragging) {
        print('💆 執行拖拽更新: adjustingHandle: $_isAdjustingHandle, draggingRegion: $_isDraggingRegion, selecting: $_isSelecting');
        if (_isAdjustingHandle) {
          _updateHandleAdjustment(clampedPosition);
        } else if (_isDraggingRegion) {
          _updateRegionDrag(clampedPosition);
        } else if (_isSelecting) {
          _updateRegionCreation(clampedPosition);
        }
      }
    }
  }

  /// 處理指針釋放事件
  void _onPointerUp(PointerUpEvent event) {
    final toolMode = ref.read(toolModeProvider);
    if (toolMode != Tool.select) return;

    _activePointers.remove(event.pointer);
    _isMultiPointer = _activePointers.length > 1;

    print('💆 指針釋放: ${event.pointer}, 數量: ${_activePointers.length}, 曾經多指: $_hasBeenMultiPointer');

    // 如果所有指針都釋放了，重置手勢狀態
    if (_activePointers.isEmpty) {
      AppLogger.debug('🔄 所有指針釋放，重置手勢狀態', data: {
        'hadBeenMultiPointer': _hasBeenMultiPointer,
        'maxPointerCount': _maxPointerCount,
        'wasSelecting': _isSelecting,
        'wasDragging': _isDragging,
      });
      
      // 只有在純單指操作時才完成手勢
      if (!_hasBeenMultiPointer && _isDragging) {
        if (_isAdjustingHandle) {
          _finishHandleAdjustment();
        } else if (_isDraggingRegion) {
          _finishRegionDrag();
        } else if (_isSelecting) {
          _finishRegionCreation();
        }
      } else if (_hasBeenMultiPointer) {
        // 曾經是多指操作，直接取消所有手勢
        _cancelCurrentGesture();
        AppLogger.debug('📱 多指操作結束，已取消所有手勢');
      }
      
      // 重置所有手勢追蹤狀態
      _resetGestureState();
    }
  }

  /// 重置手勢狀態
  void _resetGestureState() {
    setState(() {
      _singlePointerStart = null;
      _isDragging = false;
      _isHandlePressed = false;
      _pressedRegionId = null;
      _pressedHandleIndex = null;
      
      // 重置多指追蹤狀態
      _hasBeenMultiPointer = false;
      _maxPointerCount = 0;
      _lastPointerDownTime = null;
    });
    
    AppLogger.debug('🔄 手勢狀態已重置');
  }

  /// 處理指針取消事件
  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _isMultiPointer = _activePointers.length > 1;
    
    AppLogger.debug('💆 指針取消: ${event.pointer}, 數量: ${_activePointers.length}');
    
    // 如果所有指針都釋放了，重置狀態
    if (_activePointers.isEmpty) {
      // 指針取消時，直接取消所有手勢操作
      _cancelCurrentGesture();
      _resetGestureState();
      AppLogger.debug('🚫 指針取消，已重置所有狀態');
    }
  }

  /// 更新選區拖拽（簡化版 - 直接使用圖像坐標）
  void _updateRegionDrag(Offset currentPosition) {
    if (!_isDraggingRegion || 
        _draggingRegion == null || 
        _dragStartPosition == null || 
        _originalDragRect == null) {
      return;
    }

    // 在InteractiveViewer中，坐標已經是圖像坐標系，直接計算偏移量
    final imageDelta = currentPosition - _dragStartPosition!;

    final newImageRect = Rect.fromLTWH(
      _originalDragRect!.left + imageDelta.dx,
      _originalDragRect!.top + imageDelta.dy,
      _originalDragRect!.width,
      _originalDragRect!.height,
    );

    // 獲取圖像尺寸進行邊界檢查
    final imageState = ref.read(workImageProvider);
    final imageSize = imageState.imageSize;
    if (imageSize == null) {
      return;
    }
    
    // 確保選區不會超出圖像邊界
    final clampedRect = Rect.fromLTWH(
      newImageRect.left.clamp(0.0, imageSize.width - 10.0),
      newImageRect.top.clamp(0.0, imageSize.height - 10.0),
      newImageRect.width.clamp(10.0, imageSize.width),
      newImageRect.height.clamp(10.0, imageSize.height),
    );
    
    // 確保選區完全在圖像邊界內
    final finalRect = Rect.fromLTWH(
      clampedRect.left.clamp(0.0, imageSize.width - clampedRect.width),
      clampedRect.top.clamp(0.0, imageSize.height - clampedRect.height),
      clampedRect.width,
      clampedRect.height,
    );

    AppLogger.debug('選區拖拽邊界檢查', data: {
      'originalRect': '${newImageRect.left}, ${newImageRect.top}, ${newImageRect.width}x${newImageRect.height}',
      'imageSize': '${imageSize.width}x${imageSize.height}',
      'finalRect': '${finalRect.left}, ${finalRect.top}, ${finalRect.width}x${finalRect.height}',
      'imageDelta': '${imageDelta.dx}, ${imageDelta.dy}',
    });

    final updatedRegion = _draggingRegion!.copyWith(
      rect: finalRect,
      updateTime: DateTime.now(),
      isModified: true,
    );

    ref.read(characterCollectionProvider.notifier).updateRegionDisplay(updatedRegion);
  }

  /// 完成选区拖拽（简化版）
  void _finishRegionDrag() {
    if (!_isDraggingRegion || _draggingRegion == null) {
      return;
    }

    final regions = ref.read(characterCollectionProvider).regions;
    final updatedRegion = regions.firstWhere(
      (r) => r.id == _draggingRegion!.id,
      orElse: () => _draggingRegion!,
    );

    if (updatedRegion.isSelected) {
      ref.read(selectedRegionProvider.notifier).setRegion(updatedRegion);
    }

    setState(() {
      _isDraggingRegion = false;
      _draggingRegion = null;
      _dragStartPosition = null;
      _originalDragRect = null;
    });
  }
}
