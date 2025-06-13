import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../widgets/practice/guideline_alignment/guideline_manager.dart';
import '../../../widgets/practice/guideline_alignment/guideline_types.dart';
import 'custom_cursors.dart';

/// 测试版本的控制点 - 独立移动，支持旋转操作
class FreeControlPoints extends StatefulWidget {
  final String elementId;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final double initialScale;

  // 添加回调函数，使其能够与控制器集成
  final Function(int, Offset)? onControlPointUpdate;
  final Function(int)? onControlPointDragStart;
  final Function(int)? onControlPointDragEnd;
  // 🔧 新增：传递最终状态的回调
  final Function(int, Map<String, double>)? onControlPointDragEndWithState;
  // 🔧 新增：参考线对齐回调
  final Function(List<Guideline>)? onGuidelinesUpdated;
  final AlignmentMode? alignmentMode;
  final VoidCallback? updateGuidelineManagerElements;
  const FreeControlPoints({
    Key? key,
    required this.elementId,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    this.initialScale = 1.0,
    this.onControlPointUpdate,
    this.onControlPointDragStart,
    this.onControlPointDragEnd,
    this.onControlPointDragEndWithState,
    this.onGuidelinesUpdated,
    this.alignmentMode,
    this.updateGuidelineManagerElements,
  }) : super(key: key);

  @override
  State<FreeControlPoints> createState() => _FreeControlPointsState();
}

class _FreeControlPointsState extends State<FreeControlPoints> {
  // 🚀 性能优化：防止频繁日志输出的缓存
  static String? _lastUpdateLog;
  static DateTime? _lastUpdateTime;

  static const Duration _guidelineThrottleDuration = Duration(milliseconds: 16);
  static const _snapThreshold = 5.0; // 吸附阈值：5像素内才会吸附
  static const _highlightThreshold = 10.0; // 高亮阈值：10像素内显示高亮
  // 独立的控制点位置状态，不依赖元素位置
  final Map<int, Offset> _controlPointPositions = {};
  bool _isInitialized = false;
  // 独立的矩形属性 - 初始化后不再依赖widget属性
  double _currentX = 0.0;
  double _currentY = 0.0;
  double _currentWidth = 0.0;
  double _currentHeight = 0.0;
  double _currentRotation = 0.0;
  // 旋转相关状态
  Offset? _rotationCenter;
  double? _initialRotationAngle; // 🔧 新增：参考线对齐相关状态

  List<Guideline> _activeGuidelines = [];
  // 🔧 新增：节流相关状态，避免过于频繁的参考线计算
  DateTime? _lastGuidelineUpdate;

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      EditPageLogger.canvasDebug('🔥 FreeControlPoints未初始化，跳过构建', data: {
        'elementId': widget.elementId,
      });
      return const SizedBox.shrink();
    }

    EditPageLogger.canvasDebug('🔥 FreeControlPoints构建中', data: {
      'elementId': widget.elementId,
      'controlPointCount': _controlPointPositions.length,
      'currentPosition': '($_currentX, $_currentY)',
      'currentSize': '($_currentWidth x $_currentHeight)',
    });

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.loose,
      children: [
        // 绘制元素边框（用于参考）
        CustomPaint(
          painter: _TestElementBorderPainter(
            x: _currentX,
            y: _currentY,
            width: _currentWidth,
            height: _currentHeight,
            rotation: _currentRotation * 180 / pi, // 使用当前旋转角度
            color: Colors.green.withOpacity(0.5), // 使用绿色表示这是测试版本
          ),
          size: Size.infinite,
        ),

        // 透明拖拽层 - 用于平移整个控制点组
        _buildTransparentDragLayer(),

        // 渲染所有控制点
        for (int i = 0; i < _controlPointPositions.length; i++)
          _buildTestControlPoint(i),
      ],
    );
  }

  @override
  void didUpdateWidget(FreeControlPoints oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🚀 性能优化：限制日志输出频率，避免日志洪水
    if (_isInitialized) {
      final now = DateTime.now();
      final updateKey =
          '${widget.elementId}_${widget.x}_${widget.y}_${widget.width}_${widget.height}_${widget.rotation}';

      // 只有在值真正变化或超过500ms时才输出日志
      if (_lastUpdateLog != updateKey ||
          _lastUpdateTime == null ||
          now.difference(_lastUpdateTime!).inMilliseconds > 500) {
        final hasPositionChange =
            oldWidget.x != widget.x || oldWidget.y != widget.y;
        final hasSizeChange = oldWidget.width != widget.width ||
            oldWidget.height != widget.height;
        final hasRotationChange = oldWidget.rotation != widget.rotation;

        // 只有在有实际变化时才输出DEBUG日志
        if (hasPositionChange || hasSizeChange || hasRotationChange) {
          EditPageLogger.editPageDebug('🔧 FreeControlPoints属性更新检测', data: {
            'elementId': widget.elementId,
            'position_changed': {
              'old_x': oldWidget.x,
              'new_x': widget.x,
              'old_y': oldWidget.y,
              'new_y': widget.y,
              'x_changed': hasPositionChange,
              'y_changed': hasPositionChange,
            },
            'size_changed': {
              'old_width': oldWidget.width,
              'new_width': widget.width,
              'old_height': oldWidget.height,
              'new_height': widget.height,
              'width_changed': hasSizeChange,
              'height_changed': hasSizeChange,
            },
            'rotation_changed': {
              'old_rotation': oldWidget.rotation,
              'new_rotation': widget.rotation,
              'rotation_changed': hasRotationChange,
            },
            'operation': 'free_control_points_update_analysis',
          });
        } else {
          // 无变化时使用INFO级别，减少DEBUG噪音
          EditPageLogger.editPageInfo('🔧 控制点更新（无变化）', data: {
            'elementId': widget.elementId,
            'optimization': 'skip_unchanged_update',
          });
        }

        _lastUpdateLog = updateKey;
        _lastUpdateTime = now;
      }
    }

    // 🔧 修复：控制点应该跟随元素位置变化，但只在不是自己触发的变化时
    // 检查是否是外部元素拖拽导致的位置变化（而不是控制点自己的resize/rotate操作）
    if (_isInitialized &&
        (widget.x != oldWidget.x || widget.y != oldWidget.y) &&
        (widget.width == oldWidget.width &&
            widget.height == oldWidget.height &&
            widget.rotation == oldWidget.rotation)) {
      // 这是一个纯粹的位置变化（平移），不是尺寸或旋转变化
      // 更新控制点位置以跟随元素移动
      final deltaX = widget.x - oldWidget.x;
      final deltaY = widget.y - oldWidget.y;

      EditPageLogger.editPageDebug('🔧 FreeControlPoints跟随元素平移', data: {
        'delta': '($deltaX, $deltaY)',
        'from': '(${oldWidget.x}, ${oldWidget.y})',
        'to': '(${widget.x}, ${widget.y})',
        'operation': 'free_control_points_follow_translation',
      });

      setState(() {
        _syncWithElementPosition(
            widget.x, widget.y, widget.width, widget.height, widget.rotation);
      });
    }
    // 🔧 修复：旋转撤销时需要更新控制点
    else if (_isInitialized && widget.rotation != oldWidget.rotation) {
      EditPageLogger.editPageDebug('🔧 FreeControlPoints检测到旋转变化', data: {
        'oldRotation': oldWidget.rotation,
        'newRotation': widget.rotation,
        'operation': 'free_control_points_rotation_change',
      });

      setState(() {
        _syncWithElementPosition(
            widget.x, widget.y, widget.width, widget.height, widget.rotation);
      });
    }
    // 如果是尺寸或旋转变化，保持控制点的独立状态，不响应widget变化
    else if (_isInitialized) {
      EditPageLogger.editPageDebug('🔧 FreeControlPoints保持独立状态', data: {
        'reason': '忽略外部尺寸变化或未初始化',
        'isInitialized': _isInitialized,
        'operation': 'free_control_points_ignore_change',
      });
    }
  }

  /// 获取当前计算出的元素属性（用于Commit阶段）
  Map<String, double> getCurrentElementProperties() {
    final result = {
      'x': _currentX,
      'y': _currentY,
      'width': _currentWidth,
      'height': _currentHeight,
      'rotation': _currentRotation * 180 / pi, // 转换为度数
    };

    EditPageLogger.canvasDebug('FreeControlPoints最终状态', data: {
      'currentState': result,
      'deltaFromInitial': {
        'x': _currentX - widget.x,
        'y': _currentY - widget.y,
        'width': _currentWidth - widget.width,
        'height': _currentHeight - widget.height,
        'rotation': _currentRotation * 180 / pi - widget.rotation,
      }
    });

    return result;
  }

  @override
  void initState() {
    super.initState();
    _initializeControlPointPositions();
  }

  /// 🔧 新增：对齐到最近的参考线（仅在鼠标释放时调用，只在距离很近时才对齐）
  Map<String, double> _alignToClosestGuidelines(
      Map<String, double> currentProperties) {
    EditPageLogger.editPageDebug('🔍 [DEBUG] _alignToClosestGuidelines 被调用',
        data: {
          'alignmentMode': widget.alignmentMode?.toString() ?? 'null',
          'elementId': widget.elementId,
          'position': '(${currentProperties['x']}, ${currentProperties['y']})',
        });

    // 🔹 修改：禁用拖拽结束时的参考线对齐，只返回原始属性
    // 清除所有参考线
    if (_activeGuidelines.isNotEmpty) {
      _activeGuidelines = <Guideline>[];
      widget.onGuidelinesUpdated?.call([]);
    }

    // 直接返回未修改的属性
    return currentProperties;
  }

  /// 构建测试控制点 - 独立移动，不更新元素
  Widget _buildTestControlPoint(int index) {
    final position = _controlPointPositions[index]!;
    const controlPointSize = 16.0;
    const hitAreaSize = 24.0;

    String controlPointName = _getControlPointName(index);
    MouseCursor cursor = _getControlPointCursor(index);
    bool isRotation = index == 8;

    // EditPageLogger.canvasDebug('🔥 构建控制点', data: {
    //   'index': index,
    //   'controlPointName': controlPointName,
    //   'position': '${position.dx.toStringAsFixed(1)}, ${position.dy.toStringAsFixed(1)}',
    //   'isRotation': isRotation,
    // });

    return Positioned(
      left: position.dx - hitAreaSize / 2,
      top: position.dy - hitAreaSize / 2,
      width: hitAreaSize,
      height: hitAreaSize,
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          cursor: cursor,
          opaque: true,
          hitTestBehavior: HitTestBehavior.opaque,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              EditPageLogger.canvasDebug('🔥 控制点手势检测 - TapDown', data: {
                'index': index,
                'localPosition': '${details.localPosition}',
                'globalPosition': '${details.globalPosition}',
              });
            },
            onPanStart: (details) {
              EditPageLogger.canvasDebug('🔥 FreeControlPoints拖拽开始', data: {
                'index': index,
                'controlPointName': controlPointName,
                'localPosition': '${details.localPosition}',
                'globalPosition': '${details.globalPosition}',
              });

              if (index == 8) {
                // 旋转控制点 - 初始化旋转状态
                _initializeRotationState();
              } // 触发拖拽开始回调
              widget.onControlPointDragStart?.call(index);

              // 🔹 设置GuidelineManager的拖拽状态为true
              GuidelineManager.instance.isDragging = true;

              // 🔹 初始化动态参考线显示
              _initializeDynamicGuidelines();
            },
            onPanUpdate: (details) {
              setState(() {
                // 先更新控制点位置
                _updateControlPointWithConstraints(index, details.delta);
              });

              // 在setState完成后立即刷新参考线
              _refreshGuidelinesImmediately();
            },
            onPanEnd: (details) {
              EditPageLogger.canvasDebug('控制点结束拖拽', data: {
                'index': index,
                'controlPointName': controlPointName,
              }); // 🔧 新增：拖拽结束时强制清除所有参考线
              _clearGuidelines();

              // 🔹 设置GuidelineManager的拖拽状态为false
              GuidelineManager.instance.isDragging = false;

              // 🔧 新增：在鼠标释放时进行参考线对齐
              var finalProperties = getCurrentElementProperties();
              finalProperties = _alignToClosestGuidelines(finalProperties);

              // 🔧 如果对齐后位置有变化，需要更新控制点位置
              if (finalProperties['x'] != _currentX ||
                  finalProperties['y'] != _currentY) {
                setState(() {
                  _currentX = finalProperties['x']!;
                  _currentY = finalProperties['y']!;
                  _recalculateControlPointPositions();
                });
              }

              // 🔧 修复时序：先传递最终计算的状态（已对齐），再触发Commit阶段
              widget.onControlPointDragEndWithState
                  ?.call(index, finalProperties);

              // 然后触发拖拽结束回调（触发Commit阶段）
              widget.onControlPointDragEnd?.call(index);
            },
            child: Center(
              child: Container(
                width: controlPointSize,
                height: controlPointSize,
                decoration: BoxDecoration(
                  color:
                      isRotation ? Colors.orange : Colors.red, // 使用不同颜色表示测试版本
                  shape: isRotation ? BoxShape.circle : BoxShape.rectangle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(100),
                      spreadRadius: 1.0,
                      blurRadius: 2.0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建透明拖拽层 - 用于平移整个控制点组
  /// 🔧 新架构：以控制点为主导，让DragPreviewLayer跟随控制点状态
  Widget _buildTransparentDragLayer() {
    // 使用当前独立的矩形尺寸，不受旋转影响
    const padding = 5.0;
    final dragWidth = _currentWidth + padding * 2;
    final dragHeight = _currentHeight + padding * 2;

    // 计算旋转中心位置
    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    // 计算拖拽层的左上角位置（相对于旋转中心）
    final dragLeft = centerX - dragWidth / 2;
    final dragTop = centerY - dragHeight / 2;

    return Positioned(
      left: dragLeft,
      top: dragTop,
      width: dragWidth,
      height: dragHeight,
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) {
            EditPageLogger.canvasDebug('控制点主导：开始平移操作'); // 清除之前的参考线
            _clearGuidelines();

            // 🔹 设置GuidelineManager的拖拽状态为true
            GuidelineManager.instance.isDragging = true;

            // 🔹 初始化动态参考线显示
            _initializeDynamicGuidelines();

            // 🔧 关键：通知Canvas开始拖拽，以控制点为主导
            widget.onControlPointDragStart?.call(-1); // -1表示平移操作
          },
          onPanUpdate: (details) {
            setState(() {
              _translateAllControlPoints(details.delta);
            });

            // 在setState完成后强制立即刷新参考线，确保每次移动都更新
            _refreshGuidelinesImmediately();
          },
          onPanEnd: (details) {
            EditPageLogger.canvasDebug('控制点主导：平移结束'); // 🔹 新增：拖拽结束时强制清除所有参考线
            _clearGuidelines();

            // 🔹 设置GuidelineManager的拖拽状态为false
            GuidelineManager.instance.isDragging = false;

            // 🔧 新增：在鼠标释放时进行参考线对齐
            var finalProperties = getCurrentElementProperties();
            finalProperties = _alignToClosestGuidelines(finalProperties);

            // 🔧 如果对齐后位置有变化，需要更新控制点位置
            if (finalProperties['x'] != _currentX ||
                finalProperties['y'] != _currentY) {
              setState(() {
                _currentX = finalProperties['x']!;
                _currentY = finalProperties['y']!;
                _recalculateControlPointPositions();
              });
            }

            // 🔧 传递最终状态（已对齐）
            widget.onControlPointDragEndWithState?.call(-1, finalProperties);

            // 触发Commit阶段
            widget.onControlPointDragEnd?.call(-1);
          },
          child: Container(
            width: dragWidth,
            height: dragHeight,
            decoration: BoxDecoration(
              color: Colors.transparent,
              // 添加调试边框（在debug模式下可见）
              border: kDebugMode
                  ? Border.all(color: Colors.red.withOpacity(0.3), width: 1)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Rect? _calculateCurrentRectFromControlPoints() {
    // 简化：使用左上角和右下角控制点计算
    final topLeft = _controlPointPositions[0];
    final bottomRight = _controlPointPositions[4];

    if (topLeft == null || bottomRight == null) return null;

    return Rect.fromLTRB(
      topLeft.dx + 8,
      topLeft.dy + 8,
      bottomRight.dx - 8,
      bottomRight.dy - 8,
    );
  }

  /// 🔧 新增：清除参考线
  void _clearGuidelines() {
    if (_activeGuidelines.isNotEmpty) {
      setState(() {
        _activeGuidelines =
            <Guideline>[]; // Create new empty list instead of clearing
      });
      widget.onGuidelinesUpdated?.call([]);
    }
  }

  /// 🔧 新增：在拖拽过程中生成参考线用于显示，但不强制对齐
  void _generateDragGuidelines(Map<String, double> currentProperties) {
    // 只在参考线对齐模式下生成参考线
    if (widget.alignmentMode != AlignmentMode.guideline) {
      return;
    }

    try {
      // 确保GuidelineManager已启用
      if (!GuidelineManager.instance.enabled) {
        return;
      }

      // 获取当前元素位置和大小
      final currentPos =
          Offset(currentProperties['x']!, currentProperties['y']!);
      final currentSize =
          Size(currentProperties['width']!, currentProperties['height']!);
      final rotation = currentProperties['rotation']!;

      // 🔹 使用新的动态参考线生成方法
      final dynamicGuidelines =
          GuidelineManager.instance.generateDynamicGuidelines(
        elementId: widget.elementId,
        position: currentPos,
        size: currentSize,
        rotation: rotation,
      ); // 🔧 优化：立即更新本地状态并通知外部，确保参考线能够实时跟随移动
      _activeGuidelines = dynamicGuidelines;

      // 🔧 关键修复：无论是否有参考线都要通知外部，确保清除和显示都能及时生效
      if (widget.onGuidelinesUpdated != null) {
        widget.onGuidelinesUpdated!(dynamicGuidelines);
      }

      EditPageLogger.editPageDebug('动态参考线实时更新', data: {
        'elementId': widget.elementId,
        'guidelinesCount': dynamicGuidelines.length,
        'position': '${currentPos.dx}, ${currentPos.dy}',
        'size': '${currentSize.width} x ${currentSize.height}',
        'mode': 'real_time_dynamic_guidelines',
        'isEmpty': dynamicGuidelines.isEmpty,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      EditPageLogger.editPageDebug('动态参考线生成失败', data: {
        'error': e.toString(),
        'elementId': widget.elementId,
      });
    }
  }

  MouseCursor _getControlPointCursor(int index) {
    switch (index) {
      case 0:
        return CustomCursors.resizeTopLeft;
      case 1:
        return CustomCursors.resizeTop;
      case 2:
        return CustomCursors.resizeTopRight;
      case 3:
        return CustomCursors.resizeRight;
      case 4:
        return CustomCursors.resizeBottomRight;
      case 5:
        return CustomCursors.resizeBottom;
      case 6:
        return CustomCursors.resizeBottomLeft;
      case 7:
        return CustomCursors.resizeLeft;
      case 8:
        return CustomCursors.rotate;
      default:
        return SystemMouseCursors.basic;
    }
  }

  String _getControlPointName(int index) {
    switch (index) {
      case 0:
        return '左上角';
      case 1:
        return '上中';
      case 2:
        return '右上角';
      case 3:
        return '右中';
      case 4:
        return '右下角';
      case 5:
        return '下中';
      case 6:
        return '左下角';
      case 7:
        return '左中';
      case 8:
        return '旋转';
      default:
        return '未知';
    }
  }

  /// 比较两个参考线列表是否相等
  bool _guidelinesEqual(List<Guideline> a, List<Guideline> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].position != b[i].position || a[i].type != b[i].type) {
        return false;
      }
    }
    return true;
  }

  /// 初始化控制点位置 - 基于元素的初始位置和大小
  void _initializeControlPointPositions() {
    // 从widget获取初始状态，后续独立管理
    _currentX = widget.x;
    _currentY = widget.y;
    _currentWidth = widget.width;
    _currentHeight = widget.height;
    _currentRotation = widget.rotation * pi / 180;

    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    // 初始化旋转中心
    _rotationCenter = Offset(centerX, centerY);

    const offset = 8.0; // 控制点偏移量

    final unrotatedPositions = [
      // 索引0: 左上角
      Offset(_currentX - offset, _currentY - offset),
      // 索引1: 上中
      Offset(_currentX + _currentWidth / 2, _currentY - offset),
      // 索引2: 右上角
      Offset(_currentX + _currentWidth + offset, _currentY - offset),
      // 索引3: 右中
      Offset(
          _currentX + _currentWidth + offset, _currentY + _currentHeight / 2),
      // 索引4: 右下角
      Offset(_currentX + _currentWidth + offset,
          _currentY + _currentHeight + offset),
      // 索引5: 下中
      Offset(
          _currentX + _currentWidth / 2, _currentY + _currentHeight + offset),
      // 索引6: 左下角
      Offset(_currentX - offset, _currentY + _currentHeight + offset),
      // 索引7: 左中
      Offset(_currentX - offset, _currentY + _currentHeight / 2),
      // 索引8: 旋转控制点
      Offset(centerX, _currentY - 40),
    ];

    // 应用旋转并保存位置
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }

    _isInitialized = true;

    EditPageLogger.canvasDebug('控制点初始化完成', data: {
      'position': '($_currentX, $_currentY)',
      'size': '($_currentWidth, $_currentHeight)',
      'rotation': '${_currentRotation * 180 / pi}°',
    });
  }

  /// 🔹 新增：初始化动态参考线显示
  void _initializeDynamicGuidelines() {
    // 确保清空之前的任何参考线
    _clearGuidelines();

    // 只在参考线对齐模式下处理
    if (widget.alignmentMode != AlignmentMode.guideline) {
      return;
    }

    // 设置GuidelineManager为拖拽状态
    GuidelineManager.instance.isDragging = true;

    // 强制立即刷新参考线，确保初始状态正确
    _refreshGuidelinesImmediately();

    EditPageLogger.editPageDebug('初始化动态参考线', data: {
      'elementId': widget.elementId,
      'guidelinesCount': _activeGuidelines.length,
      'operation': 'init_dynamic_guidelines',
    });
  }

  /// 初始化旋转状态
  void _initializeRotationState() {
    // 计算矩形中心作为旋转中心
    final currentRect = _calculateCurrentRectFromControlPoints();
    if (currentRect != null) {
      _rotationCenter = currentRect.center;

      // 计算初始角度
      final rotationPoint = _controlPointPositions[8]!;
      _initialRotationAngle = atan2(
        rotationPoint.dy - _rotationCenter!.dy,
        rotationPoint.dx - _rotationCenter!.dx,
      );
    }
  }

  /// 🔧 控制点主导架构：将控制点状态实时推送给Canvas和DragPreviewLayer
  void _pushStateToCanvasAndPreview() {
    EditPageLogger.editPageDebug('🔍 [DEBUG] _pushStateToCanvasAndPreview 被调用',
        data: {
          'elementId': widget.elementId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

    // 构建当前元素的完整状态
    final currentState = getCurrentElementProperties();

    EditPageLogger.editPageDebug('🔍 [DEBUG] 当前元素状态', data: {
      'elementId': widget.elementId,
      'x': currentState['x'],
      'y': currentState['y'],
      'width': currentState['width'],
      'height': currentState['height'],
      'renderTime': DateTime.now().millisecondsSinceEpoch,
    });

    // 🔹 修改：先清除旧参考线，确保实时视觉反馈
    // 强制每帧清除并重新生成参考线
    _activeGuidelines = [];
    widget.onGuidelinesUpdated?.call([]);

    // 🔹 直接生成新参考线，不考虑之前的状态
    _generateDragGuidelines(currentState);

    // 🔧 关键：将当前状态推送给Canvas和DragPreviewLayer
    if (widget.onControlPointDragEndWithState != null) {
      EditPageLogger.editPageDebug(
          '🔍 [DEBUG] 调用 onControlPointDragEndWithState 回调');

      // 注意：使用特殊的controlPointIndex (-2) 表示这是Live阶段的更新
      widget.onControlPointDragEndWithState!(-2, currentState);

      EditPageLogger.editPageDebug(
          '🔍 [DEBUG] onControlPointDragEndWithState 回调完成');
    } else {
      EditPageLogger.editPageDebug(
          '🔍 [DEBUG] onControlPointDragEndWithState 回调为 null');
    }

    // 🔹 新增：立即手动触发UI更新，确保参考线立即可见
    if (_activeGuidelines.isNotEmpty) {
      EditPageLogger.editPageDebug('🔍 强制刷新参考线UI', data: {
        'guidelinesCount': _activeGuidelines.length,
        'atTime': DateTime.now().millisecondsSinceEpoch,
      });

      // 强制刷新UI以显示最新参考线
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.onGuidelinesUpdated != null &&
            _activeGuidelines.isNotEmpty) {
          widget.onGuidelinesUpdated!(List<Guideline>.from(_activeGuidelines));
        }
      });
    }
  }

  /// 重新计算控制点位置
  void _recalculateControlPointPositions() {
    const offset = 8.0; // 控制点偏移量

    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    final unrotatedPositions = [
      // 索引0: 左上角
      Offset(_currentX - offset, _currentY - offset),
      // 索引1: 上中
      Offset(_currentX + _currentWidth / 2, _currentY - offset),
      // 索引2: 右上角
      Offset(_currentX + _currentWidth + offset, _currentY - offset),
      // 索引3: 右中
      Offset(
          _currentX + _currentWidth + offset, _currentY + _currentHeight / 2),
      // 索引4: 右下角
      Offset(_currentX + _currentWidth + offset,
          _currentY + _currentHeight + offset),
      // 索引5: 下中
      Offset(
          _currentX + _currentWidth / 2, _currentY + _currentHeight + offset),
      // 索引6: 左下角
      Offset(_currentX - offset, _currentY + _currentHeight + offset),
      // 索引7: 左中
      Offset(_currentX - offset, _currentY + _currentHeight / 2),
      // 索引8: 旋转控制点
      Offset(centerX, _currentY - 40),
    ];

    // 应用旋转并保存位置
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }
  }

  // 添加一个强制刷新参考线的方法
  void _refreshGuidelinesImmediately() {
    // 获取最新状态
    final currentState = getCurrentElementProperties();

    // 清除现有参考线
    _activeGuidelines = [];

    // 强制生成新参考线
    try {
      if (widget.alignmentMode == AlignmentMode.guideline &&
          GuidelineManager.instance.enabled) {
        // 直接从元素属性重新生成参考线
        final currentPos = Offset(currentState['x']!, currentState['y']!);
        final currentSize =
            Size(currentState['width']!, currentState['height']!);
        final rotation = currentState['rotation']!;

        EditPageLogger.editPageDebug('🔧 FreeControlPoints开始刷新动态参考线', data: {
          'elementId11': widget.elementId,
          'currentPos': '${currentPos.dx}, ${currentPos.dy}',
          'currentSize': '${currentSize.width} x ${currentSize.height}',
          'rotation': rotation,
          'isDragging': GuidelineManager.instance.isDragging,
        });

        // 使用动态参考线生成方法
        final dynamicGuidelines =
            GuidelineManager.instance.generateDynamicGuidelines(
          elementId: widget.elementId,
          position: currentPos,
          size: currentSize,
          rotation: rotation,
        );

        // 处理生成的参考线
        if (dynamicGuidelines.isNotEmpty) {
          // 直接使用生成的参考线
          _activeGuidelines = dynamicGuidelines;

          // 强制通知外部更新参考线
          if (widget.onGuidelinesUpdated != null) {
            widget.onGuidelinesUpdated!(dynamicGuidelines);

            EditPageLogger
                .editPageDebug('🔧 FreeControlPoints成功刷新动态参考线UI', data: {
              'guidelinesCount': dynamicGuidelines.length,
              'elementId': widget.elementId,
              'isDynamicOnly': true,
              'elementPosition': '(${currentPos.dx}, ${currentPos.dy})',
              'guidelinePositions': dynamicGuidelines
                  .map((g) => '${g.type.name}:${g.position.toStringAsFixed(1)}')
                  .toList(),
            });
          }
        } else {
          // 没有找到对齐点，清除参考线
          if (_activeGuidelines.isNotEmpty) {
            _activeGuidelines = [];
            widget.onGuidelinesUpdated?.call([]);
          }
        }
      }
    } catch (e) {
      EditPageLogger.editPageDebug('强制刷新参考线失败', data: {
        'error': e.toString(),
        'elementId': widget.elementId,
      });
    }

    // 推送元素状态更新到预览层（但CanvasControlPointHandlers不会覆盖参考线）
    if (widget.onControlPointDragEndWithState != null) {
      widget.onControlPointDragEndWithState!(-2, currentState);
    }
  }

  /// 旋转一个点
  Offset _rotatePoint(
      double px, double py, double cx, double cy, double angle) {
    final s = sin(angle);
    final c = cos(angle);

    final translatedX = px - cx;
    final translatedY = py - cy;

    final rotatedX = translatedX * c - translatedY * s;
    final rotatedY = translatedX * s + translatedY * c;

    return Offset(rotatedX + cx, rotatedY + cy);
  }

  /// 同步控制点位置到元素位置 - 用于跟随外部元素移动
  void _syncWithElementPosition(
      double x, double y, double width, double height, double rotation) {
    // 更新内部状态
    _currentX = x;
    _currentY = y;
    _currentWidth = width;
    _currentHeight = height;
    _currentRotation = rotation * pi / 180;

    final centerX = _currentX + _currentWidth / 2;
    final centerY = _currentY + _currentHeight / 2;

    // 更新旋转中心
    _rotationCenter = Offset(centerX, centerY);

    // 重新计算所有控制点位置
    _recalculateControlPointPositions();
  }

  /// 将屏幕坐标系的delta转换为元素本地坐标系的delta
  /// ⚠️ 注意：此方法仅用于调整大小操作（resize），不用于平移操作（translate）
  /// 平移操作应始终使用屏幕坐标系，确保鼠标移动方向与元素移动方向一致
  Offset _transformDeltaToLocalCoordinates(Offset screenDelta) {
    if (_currentRotation == 0.0) {
      return screenDelta; // 没有旋转时直接返回
    }

    // 计算旋转矩阵的逆变换
    // 如果元素旋转了角度θ，那么要将屏幕坐标转换到本地坐标，需要旋转-θ
    final cosAngle = cos(-_currentRotation);
    final sinAngle = sin(-_currentRotation);

    final localDx = screenDelta.dx * cosAngle - screenDelta.dy * sinAngle;
    final localDy = screenDelta.dx * sinAngle + screenDelta.dy * cosAngle;

    return Offset(localDx, localDy);
  }

  /// 平移所有控制点
  void _translateAllControlPoints(Offset delta) {
    // ✅✅ 完全按照屏幕坐标系平移，无任何坐标转换
    // 规则：鼠标向上移动10像素 → 控制点向上移动10像素 (delta.dy = -10)
    //      鼠标向下移动10像素 → 控制点向下移动10像素 (delta.dy = +10)
    //      鼠标向左移动10像素 → 控制点向左移动10像素 (delta.dx = -10)
    //      鼠标向右移动10像素 → 控制点向右移动10像素 (delta.dx = +10)

    // 将所有控制点位置直接加上屏幕坐标系的位移量（不转换）
    for (int i = 0; i < _controlPointPositions.length; i++) {
      final currentPos = _controlPointPositions[i];
      if (currentPos != null) {
        final newPos = currentPos + delta;
        _controlPointPositions[i] = newPos;
      }
    }

    // 同时更新独立的位置属性（直接使用屏幕delta，无转换）
    _currentX += delta.dx;
    _currentY += delta.dy;

    // 同时更新旋转中心（直接使用屏幕delta，无转换）
    if (_rotationCenter != null) {
      _rotationCenter = _rotationCenter! + delta;
    }
  }

  void _updateAllControlPointsFromRect(Rect rect) {
    const offset = 8.0;
    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    // 更新独立的矩形属性
    _currentX = rect.left;
    _currentY = rect.top;
    _currentWidth = rect.width;
    _currentHeight = rect.height;

    // 🔧 修复：需要考虑旋转角度！
    // 不能直接基于矩形设置控制点，要先计算未旋转的位置，然后应用旋转

    // 计算未旋转的控制点位置
    final unrotatedPositions = [
      // 索引0: 左上角
      Offset(rect.left - offset, rect.top - offset),
      // 索引1: 上中
      Offset(centerX, rect.top - offset),
      // 索引2: 右上角
      Offset(rect.right + offset, rect.top - offset),
      // 索引3: 右中
      Offset(rect.right + offset, centerY),
      // 索引4: 右下角
      Offset(rect.right + offset, rect.bottom + offset),
      // 索引5: 下中
      Offset(centerX, rect.bottom + offset),
      // 索引6: 左下角
      Offset(rect.left - offset, rect.bottom + offset),
      // 索引7: 左中
      Offset(rect.left - offset, centerY),
      // 索引8: 旋转控制点
      Offset(centerX, rect.top - 40),
    ];

    // 应用当前旋转角度到所有控制点
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }
  }

  /// 根据新的旋转角度更新所有控制点位置
  void _updateAllControlPointsFromRotation() {
    if (_rotationCenter == null) return;

    final centerX = _rotationCenter!.dx;
    final centerY = _rotationCenter!.dy;

    // 🔧 修复：更新位置坐标，确保_currentX和_currentY是左上角位置
    _currentX = centerX - _currentWidth / 2;
    _currentY = centerY - _currentHeight / 2;

    // 使用当前独立的矩形尺寸
    const offset = 8.0;

    // 原始控制点位置（未旋转）
    final unrotatedPositions = [
      // 索引0: 左上角
      Offset(centerX - _currentWidth / 2 - offset,
          centerY - _currentHeight / 2 - offset),
      // 索引1: 上中
      Offset(centerX, centerY - _currentHeight / 2 - offset),
      // 索引2: 右上角
      Offset(centerX + _currentWidth / 2 + offset,
          centerY - _currentHeight / 2 - offset),
      // 索引3: 右中
      Offset(centerX + _currentWidth / 2 + offset, centerY),
      // 索引4: 右下角
      Offset(centerX + _currentWidth / 2 + offset,
          centerY + _currentHeight / 2 + offset),
      // 索引5: 下中
      Offset(centerX, centerY + _currentHeight / 2 + offset),
      // 索引6: 左下角
      Offset(centerX - _currentWidth / 2 - offset,
          centerY + _currentHeight / 2 + offset),
      // 索引7: 左中
      Offset(centerX - _currentWidth / 2 - offset, centerY),
      // 索引8: 旋转控制点
      Offset(centerX, centerY - _currentHeight / 2 - 40),
    ];

    // 应用当前旋转角度并保存位置
    for (int i = 0; i < unrotatedPositions.length; i++) {
      final rotated = _rotatePoint(
        unrotatedPositions[i].dx,
        unrotatedPositions[i].dy,
        centerX,
        centerY,
        _currentRotation,
      );
      _controlPointPositions[i] = rotated;
    }
  }

  /// 根据约束更新控制点位置 - 保持矩形边框关系
  void _updateControlPointWithConstraints(int index, Offset delta) {
    if (index == 8) {
      // 旋转控制点 - 计算旋转角度并更新所有控制点
      _updateRotation(delta);
      return;
    }

    // ⚠️ 重要：调整大小操作需要考虑旋转角度！
    // 用户拖拽右边控制点时，应该增加元素的"宽度"（本地坐标系），
    // 而不是屏幕坐标系的X方向。所以需要坐标转换。
    final localDelta = _transformDeltaToLocalCoordinates(delta);

    // 获取当前矩形的虚拟边界（从其他控制点推算）
    final currentRect = _calculateCurrentRectFromControlPoints();
    if (currentRect == null) return;

    // 根据控制点类型应用约束移动
    switch (index) {
      case 0: // 左上角
        _updateCornerPoint(index, localDelta, currentRect, true, true);
        break;
      case 1: // 上中
        _updateEdgePoint(index, localDelta, currentRect, true, false);
        break;
      case 2: // 右上角
        _updateCornerPoint(index, localDelta, currentRect, false, true);
        break;
      case 3: // 右中
        _updateEdgePoint(index, localDelta, currentRect, false, true);
        break;
      case 4: // 右下角
        _updateCornerPoint(index, localDelta, currentRect, false, false);
        break;
      case 5: // 下中
        _updateEdgePoint(index, localDelta, currentRect, true, false);
        break;
      case 6: // 左下角
        _updateCornerPoint(index, localDelta, currentRect, true, false);
        break;
      case 7: // 左中
        _updateEdgePoint(index, localDelta, currentRect, false, true);
        break;
    }
  }

  /// 更新角点（可以同时改变宽度和高度）
  void _updateCornerPoint(
      int index, Offset localDelta, Rect rect, bool isLeft, bool isTop) {
    // 在本地坐标系中直接更新尺寸
    double deltaWidth = 0.0;
    double deltaHeight = 0.0;
    double deltaX = 0.0;
    double deltaY = 0.0;

    // 根据角点位置计算尺寸变化
    if (isLeft) {
      // 左侧角点：宽度减少，x位置增加
      deltaWidth = -localDelta.dx;
      deltaX = localDelta.dx;
    } else {
      // 右侧角点：宽度增加
      deltaWidth = localDelta.dx;
    }

    if (isTop) {
      // 上方角点：高度减少，y位置增加
      deltaHeight = -localDelta.dy;
      deltaY = localDelta.dy;
    } else {
      // 下方角点：高度增加
      deltaHeight = localDelta.dy;
    }

    // 应用尺寸变化，确保最小尺寸
    const minSize = 20.0;
    final newWidth =
        (_currentWidth + deltaWidth).clamp(minSize, double.infinity);
    final newHeight =
        (_currentHeight + deltaHeight).clamp(minSize, double.infinity);

    // 如果尺寸被限制，调整位置变化
    if (newWidth != _currentWidth + deltaWidth) {
      deltaX = isLeft ? (_currentWidth - newWidth) : 0.0;
    }
    if (newHeight != _currentHeight + deltaHeight) {
      deltaY = isTop ? (_currentHeight - newHeight) : 0.0;
    }

    // 更新独立的矩形属性
    _currentWidth = newWidth;
    _currentHeight = newHeight;
    _currentX += deltaX;
    _currentY += deltaY;

    // 重新计算所有控制点位置
    _updateAllControlPointsFromRect(
        Rect.fromLTWH(_currentX, _currentY, _currentWidth, _currentHeight));
  }

  /// 更新边点（只能改变一个方向的尺寸）
  void _updateEdgePoint(int index, Offset localDelta, Rect rect,
      bool isHorizontal, bool isVertical) {
    double deltaWidth = 0.0;
    double deltaHeight = 0.0;
    double deltaX = 0.0;
    double deltaY = 0.0;

    if (isHorizontal && (index == 1 || index == 5)) {
      // 上中或下中 - 只改变高度
      if (index == 1) {
        // 上中：高度减少，y位置增加
        deltaHeight = -localDelta.dy;
        deltaY = localDelta.dy;
      } else {
        // 下中：高度增加
        deltaHeight = localDelta.dy;
      }
    } else if (isVertical && (index == 3 || index == 7)) {
      // 右中或左中 - 只改变宽度
      if (index == 7) {
        // 左中：宽度减少，x位置增加
        deltaWidth = -localDelta.dx;
        deltaX = localDelta.dx;
      } else {
        // 右中：宽度增加
        deltaWidth = localDelta.dx;
      }
    }

    // 应用尺寸变化，确保最小尺寸
    const minSize = 20.0;
    final newWidth = deltaWidth != 0.0
        ? (_currentWidth + deltaWidth).clamp(minSize, double.infinity)
        : _currentWidth;
    final newHeight = deltaHeight != 0.0
        ? (_currentHeight + deltaHeight).clamp(minSize, double.infinity)
        : _currentHeight;

    // 如果尺寸被限制，调整位置变化
    if (deltaWidth != 0.0 && newWidth != _currentWidth + deltaWidth) {
      deltaX = index == 7 ? (_currentWidth - newWidth) : 0.0;
    }
    if (deltaHeight != 0.0 && newHeight != _currentHeight + deltaHeight) {
      deltaY = index == 1 ? (_currentHeight - newHeight) : 0.0;
    }

    // 更新独立的矩形属性
    _currentWidth = newWidth;
    _currentHeight = newHeight;
    _currentX += deltaX;
    _currentY += deltaY;

    // 重新计算所有控制点位置
    _updateAllControlPointsFromRect(
        Rect.fromLTWH(_currentX, _currentY, _currentWidth, _currentHeight));
  }

  /// 🔹 重置参考线颜色并传递到外部更新
  void _updateGuidelineColors() {
    // 定义固定的灰色
    const guidelineColor = Color(0xFFA0A0A0);

    if (_activeGuidelines.isNotEmpty) {
      // 重设参考线颜色
      final updatedGuidelines = _activeGuidelines.map((guideline) {
        return guideline.copyWith(
          color: guidelineColor, // 强制使用灰色
          isHighlighted: false, // 禁用高亮
          lineWeight: 1.5, // 使用统一线宽
        );
      }).toList();

      _activeGuidelines = updatedGuidelines;

      // 通知外部更新参考线
      if (widget.onGuidelinesUpdated != null) {
        EditPageLogger.editPageDebug('强制更新参考线颜色为灰色', data: {
          'guidelineCount': _activeGuidelines.length,
          'color': 'gray (0xFFA0A0A0)',
        });
        widget.onGuidelinesUpdated!(_activeGuidelines);
      }
    }
  }

  /// 更新旋转
  void _updateRotation(Offset delta) {
    if (_rotationCenter == null || _initialRotationAngle == null) return;

    // 获取旋转控制点的新位置
    final currentRotationPoint = _controlPointPositions[8]! + delta;

    // 计算新的角度
    final newAngle = atan2(
      currentRotationPoint.dy - _rotationCenter!.dy,
      currentRotationPoint.dx - _rotationCenter!.dx,
    );

    // 🔧 修复：使用当前累积的旋转角度，而不是重新从widget.rotation开始
    final deltaAngle = newAngle - _initialRotationAngle!;
    _currentRotation += deltaAngle;

    // 🔧 修复：更新初始角度，避免累积误差
    _initialRotationAngle = newAngle; // 重新计算所有控制点的位置
    _updateAllControlPointsFromRotation();
  }
}

/// 测试用的元素边框绘制器
class _TestElementBorderPainter extends CustomPainter {
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;
  final Color color;

  _TestElementBorderPainter({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerX = x + width / 2;
    final centerY = y + height / 2;
    final angle = rotation * pi / 180;

    // 计算四个角点
    final corners = [
      Offset(x, y),
      Offset(x + width, y),
      Offset(x + width, y + height),
      Offset(x, y + height),
    ];

    // 应用旋转
    final rotatedCorners = corners.map((corner) {
      return _rotatePoint(corner.dx, corner.dy, centerX, centerY, angle);
    }).toList();

    // 绘制边框
    final path = Path();
    path.moveTo(rotatedCorners[0].dx, rotatedCorners[0].dy);
    for (int i = 1; i < rotatedCorners.length; i++) {
      path.lineTo(rotatedCorners[i].dx, rotatedCorners[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);

    // 绘制标签
    final textPainter = TextPainter(
      text: TextSpan(
        text: '测试模式',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(
            centerX - textPainter.width / 2, centerY - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TestElementBorderPainter oldDelegate) {
    return x != oldDelegate.x ||
        y != oldDelegate.y ||
        width != oldDelegate.width ||
        height != oldDelegate.height ||
        rotation != oldDelegate.rotation ||
        color != oldDelegate.color;
  }

  Offset _rotatePoint(
      double px, double py, double cx, double cy, double angle) {
    final s = sin(angle);
    final c = cos(angle);

    final translatedX = px - cx;
    final translatedY = py - cy;

    final rotatedX = translatedX * c - translatedY * s;
    final rotatedY = translatedX * s + translatedY * c;

    return Offset(rotatedX + cx, rotatedY + cy);
  }
}
