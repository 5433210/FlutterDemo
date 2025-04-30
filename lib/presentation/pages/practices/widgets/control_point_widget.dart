import 'package:flutter/material.dart';

/// A widget that represents a control point for resizing or rotating elements
class ControlPointWidget extends StatelessWidget {
  final String elementId;
  final int controlPointIndex;
  final Offset position;
  final Size size;
  final bool isRotation;
  final Function(DragStartDetails)? onPanStart;
  final Function(DragUpdateDetails)? onPanUpdate;
  final Function(DragEndDetails)? onPanEnd;

  const ControlPointWidget({
    Key? key,
    required this.elementId,
    required this.controlPointIndex,
    required this.position,
    required this.size,
    this.isRotation = false,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据控制点类型选择光标
    MouseCursor cursor;
    if (isRotation) {
      cursor = SystemMouseCursors.grab;
    } else {
      switch (controlPointIndex) {
        case 0: // 左上角
        case 4: // 右下角
          cursor = SystemMouseCursors.resizeUpLeft;
          break;
        case 2: // 右上角
        case 6: // 左下角
          cursor = SystemMouseCursors.resizeUpRight;
          break;
        case 1: // 上中
        case 5: // 下中
          cursor = SystemMouseCursors.resizeUpDown;
          break;
        case 3: // 右中
        case 7: // 左中
          cursor = SystemMouseCursors.resizeLeftRight;
          break;
        default:
          cursor = SystemMouseCursors.basic;
      }
    }

    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: isRotation
            ? Colors.blue // 旋转控制点使用蓝色
            : Colors.white, // 其他控制点使用白色
        border: Border.all(
          color: isRotation ? Colors.white : Colors.blue,
          width: isRotation ? 1 : 1,
        ),
        shape: isRotation ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: isRotation
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque, // 确保手势检测器完全捕获所有事件
          // 添加点击事件处理，阻止事件冒泡
          onTap: () {
            debugPrint('Control point $controlPointIndex tapped at $position');
          },
          onPanStart: (details) {
            if (onPanStart != null) {
              onPanStart!(details);
            }
          },
          onPanUpdate: (details) {
            if (onPanUpdate != null) {
              onPanUpdate!(details);
            }
          },
          onPanEnd: (details) {
            if (onPanEnd != null) {
              onPanEnd!(details);
            }
          },
        ),
      ),
    );
  }
}

/// A widget that builds a collection of control points around an element for resizing and rotation
class ElementControlPoints extends StatelessWidget {
  final String elementId;
  final double width;
  final double height;
  final Function(String, int, DragStartDetails)? onControlPointDragStart;
  final Function(String, int, DragUpdateDetails)? onControlPointDragUpdate;
  final Function(String, int, DragEndDetails)? onControlPointDragEnd;

  const ElementControlPoints({
    Key? key,
    required this.elementId,
    required this.width,
    required this.height,
    this.onControlPointDragStart,
    this.onControlPointDragUpdate,
    this.onControlPointDragEnd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const controlPointSize = 8.0;
    const rotationHandleDistance = 35.0;

    return Stack(
      clipBehavior: Clip.none, // 关键修改：禁用裁剪，允许控制点超出边界
      children: [
        // 不再添加边框，但仍需要一个容器来确保布局正确
        Container(
          width: width,
          height: height,
          color: Colors.transparent, // 透明容器，仅用于布局
        ),

        // 左上角
        Positioned(
          left: -controlPointSize / 2,
          top: -controlPointSize / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 0,
            position:
                const Offset(-controlPointSize / 2, -controlPointSize / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 0, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 0, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 0, details),
          ),
        ),

        // 上中
        Positioned(
          left: (width - controlPointSize) / 2,
          top: -controlPointSize / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 1,
            position:
                Offset((width - controlPointSize) / 2, -controlPointSize / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 1, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 1, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 1, details),
          ),
        ),

        // 右上角
        Positioned(
          right: -controlPointSize / 2,
          top: -controlPointSize / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 2,
            position:
                Offset(width - controlPointSize / 2, -controlPointSize / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 2, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 2, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 2, details),
          ),
        ),

        // 右中
        Positioned(
          right: -controlPointSize / 2,
          top: (height - controlPointSize) / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 3,
            position: Offset(
                width - controlPointSize / 2, (height - controlPointSize) / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 3, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 3, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 3, details),
          ),
        ),

        // 右下角
        Positioned(
          right: -controlPointSize / 2,
          bottom: -controlPointSize / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 4,
            position: Offset(
                width - controlPointSize / 2, height - controlPointSize / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 4, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 4, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 4, details),
          ),
        ),

        // 下中
        Positioned(
          left: (width - controlPointSize) / 2,
          bottom: -controlPointSize / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 5,
            position: Offset(
                (width - controlPointSize) / 2, height - controlPointSize / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 5, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 5, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 5, details),
          ),
        ),

        // 左下角
        Positioned(
          left: -controlPointSize / 2,
          bottom: -controlPointSize / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 6,
            position:
                Offset(-controlPointSize / 2, height - controlPointSize / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 6, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 6, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 6, details),
          ),
        ),

        // 左中
        Positioned(
          left: -controlPointSize / 2,
          top: (height - controlPointSize) / 2,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 7,
            position:
                Offset(-controlPointSize / 2, (height - controlPointSize) / 2),
            size: const Size(controlPointSize, controlPointSize),
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 7, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 7, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 7, details),
          ),
        ),

        // 旋转控制柄
        Positioned(
          left: width / 2 - 7,
          top: -7,
          child: ControlPointWidget(
            elementId: elementId,
            controlPointIndex: 8,
            position: Offset(width / 2 - 7, -7),
            size: const Size(14, 14),
            isRotation: true,
            onPanStart: (details) =>
                onControlPointDragStart?.call(elementId, 8, details),
            onPanUpdate: (details) =>
                onControlPointDragUpdate?.call(elementId, 8, details),
            onPanEnd: (details) =>
                onControlPointDragEnd?.call(elementId, 8, details),
          ),
        ),
      ],
    );
  }
}
