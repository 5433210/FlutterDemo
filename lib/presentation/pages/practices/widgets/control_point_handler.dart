import 'package:flutter/material.dart';

/// Class to handle control point interactions for element manipulation
class ControlPointHandler extends StatelessWidget {
  final String elementId;
  final double width;
  final double height;
  final Function(int, Offset) onControlPointUpdate;

  const ControlPointHandler({
    Key? key,
    required this.elementId,
    required this.width,
    required this.height,
    required this.onControlPointUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const controlPointSize = 8.0;
    const rotationHandleDistance = 30.0;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip
            .none, // Allow control points to extend outside element boundaries
        children: [
          // Top-left corner
          _buildControlPoint(
            0,
            const Offset(-controlPointSize / 2, -controlPointSize / 2),
            SystemMouseCursors.resizeUpLeft,
          ),

          // Top-center
          _buildControlPoint(
            1,
            Offset((width - controlPointSize) / 2, -controlPointSize / 2),
            SystemMouseCursors.resizeUpDown,
          ),

          // Top-right corner
          _buildControlPoint(
            2,
            Offset(width - controlPointSize / 2, -controlPointSize / 2),
            SystemMouseCursors.resizeUpRight,
          ),

          // Middle-right
          _buildControlPoint(
            3,
            Offset(
                width - controlPointSize / 2, (height - controlPointSize) / 2),
            SystemMouseCursors.resizeLeftRight,
          ),

          // Bottom-right corner
          _buildControlPoint(
            4,
            Offset(width - controlPointSize / 2, height - controlPointSize / 2),
            SystemMouseCursors.resizeUpLeft,
          ),

          // Bottom-center
          _buildControlPoint(
            5,
            Offset(
                (width - controlPointSize) / 2, height - controlPointSize / 2),
            SystemMouseCursors.resizeUpDown,
          ),

          // Bottom-left corner
          _buildControlPoint(
            6,
            Offset(-controlPointSize / 2, height - controlPointSize / 2),
            SystemMouseCursors.resizeUpRight,
          ),

          // Middle-left
          _buildControlPoint(
            7,
            Offset(-controlPointSize / 2, (height - controlPointSize) / 2),
            SystemMouseCursors.resizeLeftRight,
          ),

          // Rotation handle
          _buildControlPoint(
            8,
            Offset(width / 2 - controlPointSize / 2, -rotationHandleDistance),
            SystemMouseCursors.grab,
            isRotation: true,
          ),

          // Rotation handle connection line
          Positioned(
            left: width / 2,
            top: -rotationHandleDistance + controlPointSize,
            child: Container(
              width: 1,
              height: rotationHandleDistance - controlPointSize,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a single control point
  Widget _buildControlPoint(
    int index,
    Offset position,
    MouseCursor cursor, {
    bool isRotation = false,
  }) {
    const controlPointSize = 8.0;
    final size = isRotation ? 10.0 : controlPointSize;

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior:
              HitTestBehavior.opaque, // Ensure gesture detector captures events
          onPanStart: (details) {
            // 阻止事件冒泡，防止触发父级的拖拽事件
            // 这里不需要做任何事情，但必须提供这个回调以捕获事件
          },
          onPanUpdate: (details) {
            onControlPointUpdate(index, details.delta);
          },
          onPanEnd: (details) {
            // 这里不需要做任何事情，但必须提供这个回调以捕获事件
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isRotation ? Colors.blue : Colors.white,
              shape: isRotation ? BoxShape.circle : BoxShape.rectangle,
              border: Border.all(
                color: isRotation ? Colors.white : Colors.blue,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(51), // 0.2 opacity = 51/255
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
