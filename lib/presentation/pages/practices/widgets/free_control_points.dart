import 'dart:math';

import 'package:flutter/material.dart';

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
  }) : super(key: key);

  @override
  State<FreeControlPoints> createState() => _FreeControlPointsState();
}

class _FreeControlPointsState extends State<FreeControlPoints> {
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
  double? _initialRotationAngle;
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox.shrink();
    }

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

    // 测试控制点现在完全独立，不再响应widget属性变化
    // 只在初始化时从widget获取起始状态，后续可以自由调整
  }

  @override
  void initState() {
    super.initState();
    _initializeControlPointPositions();
  }

  /// 构建测试控制点 - 独立移动，不更新元素
  Widget _buildTestControlPoint(int index) {
    final position = _controlPointPositions[index]!;
    const controlPointSize = 16.0;
    const hitAreaSize = 24.0;

    String controlPointName = _getControlPointName(index);
    MouseCursor cursor = _getControlPointCursor(index);
    bool isRotation = index == 8;

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
            onPanStart: (details) {
              debugPrint('🧪 测试控制点 $index ($controlPointName) 开始拖拽');

              if (index == 8) {
                // 旋转控制点 - 初始化旋转状态
                _initializeRotationState();
              }

              // 触发拖拽开始回调
              widget.onControlPointDragStart?.call(index);
            },
            onPanUpdate: (details) {
              // 根据控制点类型应用约束移动
              setState(() {
                _updateControlPointWithConstraints(index, details.delta);
              });

              debugPrint(
                  '🧪 测试控制点 $index 移动到: ${_controlPointPositions[index]}');

              // 触发控制点更新回调
              widget.onControlPointUpdate
                  ?.call(index, _controlPointPositions[index]!);
            },
            onPanEnd: (details) {
              debugPrint('🧪 测试控制点 $index ($controlPointName) 结束拖拽');

              // 触发拖拽结束回调
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

  /// 将屏幕坐标系的delta转换为元素本地坐标系的delta

  /// 构建透明拖拽层 - 用于平移整个控制点组  /// 构建透明拖拽层，用于平移整个控制点组
  /// ✅ 透明拖拽层现在随控制点一起旋转，但平移操作仍使用屏幕坐标系
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

    debugPrint(
        '🧪 拖拽层位置: left=$dragLeft, top=$dragTop, size=${dragWidth}x$dragHeight');
    return Positioned(
      left: dragLeft,
      top: dragTop,
      width: dragWidth,
      height: dragHeight,
      // 移除旋转变换，让拖拽层保持水平不跟随旋转
      child: MouseRegion(
        cursor: SystemMouseCursors.move,
        onEnter: (_) {
          debugPrint('🧪 鼠标进入透明拖拽层');
        },
        onExit: (_) {
          debugPrint('🧪 鼠标离开透明拖拽层');
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent, // 允许事件穿透到下层
          onPanStart: (details) {
            debugPrint('🧪 测试控制点组开始平移');
          },
          onPanUpdate: (details) {
            // 直接传递屏幕坐标系的 delta，不进行任何转换
            debugPrint('🧪 收到手势delta: ${details.delta}');
            setState(() {
              _translateAllControlPoints(details.delta);
            });
          },
          onPanEnd: (details) {
            debugPrint('🧪 测试控制点组结束平移');
          },
          child: Container(
            width: dragWidth,
            height: dragHeight,
            decoration: const BoxDecoration(
              color: Colors.transparent, // 完全透明
              // 移除边框，使其完全不可见
            ),
            // 移除child内容，使其完全透明
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
    debugPrint(
        '🧪 测试控制点已初始化，独立状态: 位置($_currentX, $_currentY), 大小($_currentWidth, $_currentHeight), 旋转${_currentRotation * 180 / pi}°');
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

  /// 根据新矩形更新所有控制点位置

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

    debugPrint(
        '🧪 坐标转换（仅用于resize）: 屏幕$screenDelta → 本地${Offset(localDx, localDy)}');
    return Offset(localDx, localDy);
  }

  /// 平移所有控制点

  /// 平移所有控制点
  void _translateAllControlPoints(Offset delta) {
    // ✅✅ 完全按照屏幕坐标系平移，无任何坐标转换
    // 规则：鼠标向上移动10像素 → 控制点向上移动10像素 (delta.dy = -10)
    //      鼠标向下移动10像素 → 控制点向下移动10像素 (delta.dy = +10)
    //      鼠标向左移动10像素 → 控制点向左移动10像素 (delta.dx = -10)
    //      鼠标向右移动10像素 → 控制点向右移动10像素 (delta.dx = +10)

    debugPrint('🧪 收到屏幕坐标delta: $delta (dx=${delta.dx}, dy=${delta.dy})');

    // 将所有控制点位置直接加上屏幕坐标系的位移量（不转换）
    for (int i = 0; i < _controlPointPositions.length; i++) {
      final currentPos = _controlPointPositions[i];
      if (currentPos != null) {
        final newPos = currentPos + delta;
        _controlPointPositions[i] = newPos;
        debugPrint('🧪 控制点 $i: $currentPos → $newPos');
      }
    }

    // 同时更新独立的位置属性（直接使用屏幕delta，无转换）
    final oldX = _currentX;
    final oldY = _currentY;
    _currentX += delta.dx;
    _currentY += delta.dy;

    // 同时更新旋转中心（直接使用屏幕delta，无转换）
    if (_rotationCenter != null) {
      final oldCenter = _rotationCenter!;
      _rotationCenter = _rotationCenter! + delta;
      debugPrint('🧪 旋转中心: $oldCenter → $_rotationCenter');
    }

    debugPrint('🧪 矩形位置更新: ($oldX, $oldY) → ($_currentX, $_currentY)');
    debugPrint('🧪 平移完成，完全按照屏幕坐标系移动');
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

    debugPrint(
        '🧪 独立矩形已更新: 位置($_currentX, $_currentY), 大小($_currentWidth, $_currentHeight), 旋转${_currentRotation * 180 / pi}°');
  }

  /// 根据新的旋转角度更新所有控制点位置
  void _updateAllControlPointsFromRotation() {
    if (_rotationCenter == null) return;

    final centerX = _rotationCenter!.dx;
    final centerY = _rotationCenter!.dy;

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

    debugPrint('🧪 旋转已更新: ${_currentRotation * 180 / pi}°');
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

    // 计算角度变化量
    final deltaAngle = newAngle - _initialRotationAngle!;
    _currentRotation = widget.rotation * pi / 180 + deltaAngle;

    // 重新计算所有控制点的位置
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
