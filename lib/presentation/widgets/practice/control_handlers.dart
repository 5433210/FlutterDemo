import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 控制点处理器
class ControlHandlers {
  /// 构建变换控制点
  static Widget buildTransformControls(double width, double height) {
    const controlPointSize = 8.0;
    const rotationHandleDistance = 35.0; // 增加旋转控制柄距离

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none, // 关键修改：禁用裁剪，允许控制点超出边界
        children: [
          // 四个角落的调整控制点
          // 左上角
          Positioned(
            left: -controlPointSize / 2,
            top: -controlPointSize / 2,
            child: _buildControlPoint(ControlPointPosition.topLeft),
          ),
          // 右上角
          Positioned(
            right: -controlPointSize / 2,
            top: -controlPointSize / 2,
            child: _buildControlPoint(ControlPointPosition.topRight),
          ),
          // 左下角
          Positioned(
            left: -controlPointSize / 2,
            bottom: -controlPointSize / 2,
            child: _buildControlPoint(ControlPointPosition.bottomLeft),
          ),
          // 右下角
          Positioned(
            right: -controlPointSize / 2,
            bottom: -controlPointSize / 2,
            child: _buildControlPoint(ControlPointPosition.bottomRight),
          ),

          // 四条边中间的调整控制点
          // 上边中间
          Positioned(
            left: (width - controlPointSize) / 2,
            top: -controlPointSize / 2,
            child: _buildControlPoint(ControlPointPosition.top),
          ),
          // 右边中间
          Positioned(
            right: -controlPointSize / 2,
            top: (height - controlPointSize) / 2,
            child: _buildControlPoint(ControlPointPosition.right),
          ),
          // 下边中间
          Positioned(
            left: (width - controlPointSize) / 2,
            bottom: -controlPointSize / 2,
            child: _buildControlPoint(ControlPointPosition.bottom),
          ),
          // 左边中间
          Positioned(
            left: -controlPointSize / 2,
            top: (height - controlPointSize) / 2,
            child: _buildControlPoint(ControlPointPosition.left),
          ),

          // 旋转控制柄 - 增强显示效果
          Positioned(
            left: (width - 14) / 2, // 使用旋转手柄的实际宽度
            top: -rotationHandleDistance,
            child: Column(
              children: [
                // 旋转手柄
                _buildRotationHandle(),
                // 连接线
                Container(
                  width: 2, // 增加线宽
                  height: rotationHandleDistance - 14, // 调整高度以匹配旋转手柄大小
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 计算控制点调整后的几何属性
  static Map<String, dynamic> calculateNewGeometry(
    Map<String, dynamic> currentGeometry,
    int controlPointIndex,
    Offset delta,
  ) {
    final x = (currentGeometry['x'] as num).toDouble();
    final y = (currentGeometry['y'] as num).toDouble();
    final width = (currentGeometry['width'] as num).toDouble();
    final height = (currentGeometry['height'] as num).toDouble();

    // 根据不同控制点调整几何属性
    switch (controlPointIndex) {
      case 0: // 左上角 - 调整位置和大小
        return {
          'x': x + delta.dx,
          'y': y + delta.dy,
          'width': width - delta.dx,
          'height': height - delta.dy,
        };
      case 1: // 上中 - 只调整y和高度
        return {
          'y': y + delta.dy,
          'height': height - delta.dy,
        };
      case 2: // 右上角 - 调整y和宽高
        return {
          'y': y + delta.dy,
          'width': width + delta.dx,
          'height': height - delta.dy,
        };
      case 3: // 右中 - 只调整宽度
        return {
          'width': width + delta.dx,
        };
      case 4: // 右下角 - 调整宽高
        return {
          'width': width + delta.dx,
          'height': height + delta.dy,
        };
      case 5: // 下中 - 只调整高度
        return {
          'height': height + delta.dy,
        };
      case 6: // 左下角 - 调整x和宽高
        return {
          'x': x + delta.dx,
          'width': width - delta.dx,
          'height': height + delta.dy,
        };
      case 7: // 左中 - 调整x和宽度
        return {
          'x': x + delta.dx,
          'width': width - delta.dx,
        };
      default:
        return {};
    }
  }

  /// 计算旋转角度
  static double calculateRotation(
    Offset center,
    Offset startPoint,
    Offset currentPoint,
  ) {
    // 计算起始向量
    final startVector = startPoint - center;
    // 计算当前向量
    final currentVector = currentPoint - center;

    // 计算两个向量之间的角度
    final startAngle = math.atan2(startVector.dy, startVector.dx);
    final currentAngle = math.atan2(currentVector.dy, currentVector.dx);

    // 计算角度差（弧度转换为角度）
    return (currentAngle - startAngle) * 180 / math.pi;
  }

  /// 获取控制点类型
  static String getControlPointType(int index) {
    switch (index) {
      case 0:
        return 'top-left';
      case 1:
        return 'top-center';
      case 2:
        return 'top-right';
      case 3:
        return 'right-center';
      case 4:
        return 'bottom-right';
      case 5:
        return 'bottom-center';
      case 6:
        return 'bottom-left';
      case 7:
        return 'left-center';
      case 8:
        return 'rotation';
      default:
        return 'unknown';
    }
  }

  /// 构建控制点
  static Widget _buildControlPoint(ControlPointPosition position) {
    final cursor = _getCursorForPosition(position);
    const controlPointSize = 8.0;
    // 增加点击区域，但保持视觉大小不变
    const hitAreaExpansion = 6.0;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        // 添加事件处理以防止事件冒泡
        onPanStart: (details) {
          // 消耗事件，防止冒泡到父级
          details.sourceTimeStamp; // 访问属性以避免未使用的变量警告
        },
        child: Container(
          width: controlPointSize + hitAreaExpansion,
          height: controlPointSize + hitAreaExpansion,
          color: Colors.transparent, // 扩展区域透明
          padding: const EdgeInsets.all(hitAreaExpansion / 2),
          child: Container(
            width: controlPointSize,
            height: controlPointSize,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blue, width: 1),
              shape: BoxShape.rectangle,
            ),
          ),
        ),
      ),
    );
  }

  /// 构建旋转控制柄
  static Widget _buildRotationHandle() {
    const controlSize = 14.0;
    const hitAreaExpansion = 8.0;

    return MouseRegion(
      cursor: SystemMouseCursors.grabbing,
      child: GestureDetector(
        // 添加事件处理以防止事件冒泡
        onPanStart: (details) {
          // 消耗事件，防止冒泡到父级
          details.sourceTimeStamp; // 访问属性以避免未使用的变量警告
        },
        child: Container(
          width: controlSize + hitAreaExpansion,
          height: controlSize + hitAreaExpansion,
          color: Colors.transparent, // 扩展区域透明
          padding: const EdgeInsets.all(hitAreaExpansion / 2),
          child: Container(
            width: controlSize,
            height: controlSize,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2), // 添加白色边框
              boxShadow: [
                // 添加阴影效果
                BoxShadow(
                  color: Colors.black.withAlpha(76), // 0.3 的不透明度
                  spreadRadius: 1,
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 根据控制点位置获取鼠标指针样式
  static MouseCursor _getCursorForPosition(ControlPointPosition position) {
    switch (position) {
      case ControlPointPosition.topLeft:
        return SystemMouseCursors.resizeUpLeft;
      case ControlPointPosition.bottomRight:
        return SystemMouseCursors.resizeDownRight; // 修正：右下角应该是resizeDownRight
      case ControlPointPosition.topRight:
        return SystemMouseCursors.resizeUpRight;
      case ControlPointPosition.bottomLeft:
        return SystemMouseCursors.resizeDownLeft; // 修正：左下角应该是resizeDownLeft
      case ControlPointPosition.top:
        return SystemMouseCursors.resizeUpDown;
      case ControlPointPosition.bottom:
        return SystemMouseCursors.resizeUpDown;
      case ControlPointPosition.left:
        return SystemMouseCursors.resizeLeftRight;
      case ControlPointPosition.right:
        return SystemMouseCursors.resizeLeftRight;
    }
  }
}

/// 控制点位置枚举
enum ControlPointPosition {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}
