import 'package:flutter/material.dart';

/// 控制点绘制器
class ControlPointPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    const controlPointSize = 10.0;
    const rotationHandleDistance = 40.0;

    // 绘制控制点
    _drawControlPoint(canvas, const Offset(0, 0), controlPointSize); // 左上
    _drawControlPoint(canvas, Offset(width / 2, 0), controlPointSize); // 上中
    _drawControlPoint(canvas, Offset(width, 0), controlPointSize); // 右上
    _drawControlPoint(
        canvas, Offset(width, height / 2), controlPointSize); // 右中
    _drawControlPoint(canvas, Offset(width, height), controlPointSize); // 右下
    _drawControlPoint(
        canvas, Offset(width / 2, height), controlPointSize); // 下中
    _drawControlPoint(canvas, Offset(0, height), controlPointSize); // 左下
    _drawControlPoint(canvas, Offset(0, height / 2), controlPointSize); // 左中

    // 绘制旋转控制点
    _drawRotationPoint(
        canvas, Offset(width / 2, -rotationHandleDistance), 12.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  /// 绘制普通控制点
  void _drawControlPoint(Canvas canvas, Offset position, double size) {
    final rect = Rect.fromCenter(
      center: position,
      width: size,
      height: size,
    );

    // 绘制白色填充
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // 绘制蓝色边框
    final strokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, strokePaint);
  }

  /// 绘制旋转控制点
  void _drawRotationPoint(Canvas canvas, Offset position, double size) {
    // 绘制蓝色填充圆形
    final fillPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, size / 2, fillPaint);

    // 绘制白色边框
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(position, size / 2, strokePaint);
  }
}

/// 自定义控制点处理器
class CustomControlPointHandler extends StatelessWidget {
  final String elementId;
  final double width;
  final double height;
  final Function(int, Offset) onControlPointUpdate;

  const CustomControlPointHandler({
    Key? key,
    required this.elementId,
    required this.width,
    required this.height,
    required this.onControlPointUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // 允许子元素超出边界
      children: [
        // 绘制控制点
        SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            size: Size(width, height),
            painter: ControlPointPainter(),
          ),
        ),

        // 顶部左侧控制点
        _buildControlPointDetector(0, Offset.zero),

        // 顶部中间控制点
        _buildControlPointDetector(1, Offset(width / 2, 0)),

        // 顶部右侧控制点
        _buildControlPointDetector(2, Offset(width, 0)),

        // 中间右侧控制点
        _buildControlPointDetector(3, Offset(width, height / 2)),

        // 底部右侧控制点
        _buildControlPointDetector(4, Offset(width, height)),

        // 底部中间控制点
        _buildControlPointDetector(5, Offset(width / 2, height)),

        // 底部左侧控制点
        _buildControlPointDetector(6, Offset(0, height)),

        // 中间左侧控制点
        _buildControlPointDetector(7, Offset(0, height / 2)),

        // 旋转控制点
        _buildControlPointDetector(8, Offset(width / 2, -40), isRotation: true),

        // 旋转控制点连接线
        Positioned(
          left: width / 2 - 0.5, // 居中对齐
          top: -40,
          child: Container(
            width: 1,
            height: 40,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  /// 构建控制点检测器
  Widget _buildControlPointDetector(int index, Offset position,
      {bool isRotation = false}) {
    // 控制点的点击区域大小 - 使用更大的点击区域
    const hitAreaSize = 60.0;

    // 计算点击区域的位置，使其以控制点为中心
    final left = position.dx - hitAreaSize / 2;
    final top = position.dy - hitAreaSize / 2;

    // 根据控制点索引确定鼠标光标类型
    MouseCursor cursor;
    switch (index) {
      case 0: // 左上
        cursor = SystemMouseCursors.resizeUpLeft;
        break;
      case 1: // 上中
        cursor = SystemMouseCursors.resizeUpDown;
        break;
      case 2: // 右上
        cursor = SystemMouseCursors.resizeUpRight;
        break;
      case 3: // 右中
        cursor = SystemMouseCursors.resizeLeftRight;
        break;
      case 4: // 右下
        cursor = SystemMouseCursors.resizeDownRight;
        break;
      case 5: // 下中
        cursor = SystemMouseCursors.resizeUpDown;
        break;
      case 6: // 左下
        cursor = SystemMouseCursors.resizeDownLeft;
        break;
      case 7: // 左中
        cursor = SystemMouseCursors.resizeLeftRight;
        break;
      case 8: // 旋转
        cursor = SystemMouseCursors.grab;
        break;
      default:
        cursor = SystemMouseCursors.basic;
    }

    return Positioned(
      left: left,
      top: top,
      width: hitAreaSize,
      height: hitAreaSize,
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
            // 调试用的半透明背景，使用更明显的颜色
            color: const Color.fromRGBO(255, 0, 0, 0.5),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.red, width: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
