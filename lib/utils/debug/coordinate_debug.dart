import 'package:flutter/material.dart';

/// 坐标系统调试工具类
class CoordinateDebug {
  // 启用或禁用日志
  static bool enabled = true;

  // 在画布上显示调试坐标
  static void drawDebugPoint(Canvas canvas, Offset position,
      {Color color = Colors.red}) {
    if (!enabled) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // 绘制一个小圆点标记位置
    canvas.drawCircle(position, 5.0, paint);

    // 绘制坐标文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: '(${position.dx.toInt()},${position.dy.toInt()})',
        style: const TextStyle(color: Colors.black, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position + const Offset(10, -10));
  }

  // 记录点击事件
  static void logPointerEvent(String action, Offset position, [Offset? delta]) {
    if (!enabled) return;

    String message = '[$action] 位置: $position';
    if (delta != null) {
      message += ', 增量: $delta';
    }
    print(message);
  }

  // 日志坐标转换
  static void logTransform(String tag, Offset from, Offset to) {
    if (!enabled) return;

    print(
        '[$tag] 坐标转换: $from -> $to (差异: ${(to - from).distance.toStringAsFixed(2)})');
  }
}
