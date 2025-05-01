import 'package:flutter/material.dart';

/// 绝对定位的控制点处理器
class AbsoluteControlPointHandler extends StatelessWidget {
  final String elementId;
  final double width;
  final double height;
  final double rotation;
  final Function(int, Offset) onControlPointUpdate;

  const AbsoluteControlPointHandler({
    Key? key,
    required this.elementId,
    required this.width,
    required this.height,
    required this.rotation,
    required this.onControlPointUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 控制点的大小
    const controlPointSize = 12.0;
    // 旋转控制点的距离
    const rotationHandleDistance = 40.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 元素边框 - 透明的，只用于显示边界
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.transparent),
          ),
        ),

        // 左上角控制点
        _buildControlPoint(
          0,
          const Offset(-controlPointSize / 2, -controlPointSize / 2),
          SystemMouseCursors.resizeUpLeft,
        ),

        // 上中控制点
        _buildControlPoint(
          1,
          Offset(width / 2 - controlPointSize / 2, -controlPointSize / 2),
          SystemMouseCursors.resizeUpDown,
        ),

        // 右上角控制点
        _buildControlPoint(
          2,
          Offset(width - controlPointSize / 2, -controlPointSize / 2),
          SystemMouseCursors.resizeUpRight,
        ),

        // 右中控制点
        _buildControlPoint(
          3,
          Offset(
              width - controlPointSize / 2, height / 2 - controlPointSize / 2),
          SystemMouseCursors.resizeLeftRight,
        ),

        // 右下角控制点
        _buildControlPoint(
          4,
          Offset(width - controlPointSize / 2, height - controlPointSize / 2),
          SystemMouseCursors.resizeDownRight,
        ),

        // 下中控制点
        _buildControlPoint(
          5,
          Offset(
              width / 2 - controlPointSize / 2, height - controlPointSize / 2),
          SystemMouseCursors.resizeUpDown,
        ),

        // 左下角控制点
        _buildControlPoint(
          6,
          Offset(-controlPointSize / 2, height - controlPointSize / 2),
          SystemMouseCursors.resizeDownLeft,
        ),

        // 左中控制点
        _buildControlPoint(
          7,
          Offset(-controlPointSize / 2, height / 2 - controlPointSize / 2),
          SystemMouseCursors.resizeLeftRight,
        ),

        // 旋转控制点连接线
        Positioned(
          left: width / 2 - 0.5,
          top: -rotationHandleDistance,
          width: 1,
          height: rotationHandleDistance,
          child: Container(color: Colors.blue),
        ),

        // 旋转控制点
        _buildControlPoint(
          8,
          Offset(width / 2 - controlPointSize / 2,
              -rotationHandleDistance - controlPointSize / 2),
          SystemMouseCursors.grab,
          isRotation: true,
        ),
      ],
    );
  }

  /// 构建单个控制点
  Widget _buildControlPoint(
    int index,
    Offset position,
    MouseCursor cursor, {
    bool isRotation = false,
  }) {
    // 控制点的大小
    const controlPointSize = 12.0;
    // 点击区域的大小 - 使用更大的点击区域
    const hitAreaSize = 40.0;

    // 计算点击区域的位置，使其以控制点为中心
    final left = position.dx - (hitAreaSize - controlPointSize) / 2;
    final top = position.dy - (hitAreaSize - controlPointSize) / 2;

    return Positioned(
      left: left,
      top: top,
      width: hitAreaSize,
      height: hitAreaSize,
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              debugPrint(
                  '【控制点】onPanStart: 控制点索引=$index, 位置=${details.localPosition}, 全局位置=${details.globalPosition}');
            },
            onPanUpdate: (details) {
              debugPrint(
                  '【控制点】onPanUpdate: 控制点索引=$index, 偏移量=${details.delta}, 全局位置=${details.globalPosition}');
              onControlPointUpdate(index, details.delta);
            },
            onPanEnd: (details) {
              debugPrint(
                  '【控制点】onPanEnd: 控制点索引=$index, 速度=${details.velocity.pixelsPerSecond}');
            },
            child: Container(
              // 使用半透明红色背景，便于调试
              color: const Color.fromRGBO(255, 0, 0, 0.8),
              child: Center(
                child: Container(
                  width: controlPointSize,
                  height: controlPointSize,
                  decoration: BoxDecoration(
                    color: isRotation ? Colors.blue : Colors.white,
                    shape: isRotation ? BoxShape.circle : BoxShape.rectangle,
                    border: Border.all(
                      color: isRotation ? Colors.white : Colors.blue,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51), // 0.2 opacity
                        spreadRadius: 1,
                        blurRadius: 1,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
