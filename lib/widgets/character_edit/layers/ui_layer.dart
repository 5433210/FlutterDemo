import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../utils/debug/debug_flags.dart';
import 'base_layer.dart';

/// UI图层，处理用户交互和显示光标
class UILayer extends BaseLayer {
  // 添加静态计数器用于降低日志频率
  static int _updateCounter = 0;
  final Function(Offset)? onPointerDown;
  final Function(Offset, Offset)? onPointerMove;
  final Function(Offset)? onPointerUp;
  final Function(Offset)? onPan;
  final Function(Offset)? onTap;
  final MouseCursor cursor;
  final DetectedOutline? outline;
  final Size? imageSize;
  final bool altKeyPressed;
  final double brushSize;

  final Offset? cursorPosition;

  const UILayer({
    Key? key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPan,
    this.onTap, // 添加点击回调
    this.cursor = SystemMouseCursors.precise,
    this.outline,
    this.imageSize,
    this.altKeyPressed = false,
    this.brushSize = 10.0,
    this.cursorPosition,
  }) : super(key: key);

  @override
  bool get isComplexPainting => outline != null;

  @override
  bool get willChangePainting => cursorPosition != null;

  @override
  Widget build(BuildContext context) {
    // 记录当前使用的光标，便于调试
    final currentCursor = altKeyPressed ? SystemMouseCursors.move : cursor;

    return MouseRegion(
      cursor: currentCursor,
      onHover: (event) {
        // 只更新光标位置，不触发擦除操作
        if (onPointerMove != null) {
          // 重要: 传递Offset.zero作为delta，表明这只是光标移动而非拖拽
          onPointerMove!(event.localPosition, Offset.zero);
        }
      },
      child: GestureDetector(
        // 添加点击处理
        onTap: () {
          if (cursorPosition != null && onTap != null) {
            print('UI层执行点击回调: $cursorPosition');
            onTap!(cursorPosition!);
          } else {
            print(
                '点击回调未执行: cursorPosition=$cursorPosition, onTap=${onTap != null}');
          }
        },
        // 仅当拖动时处理擦除
        onPanStart: (details) {
          // 只在调试模式下打印
          if (kDebugMode && DebugFlags.enableEraseDebug) {
            print('手势开始: ${details.localPosition}, Alt键: $altKeyPressed');
          }
          if (onPointerDown != null) {
            onPointerDown!(details.localPosition);
          }
        },
        onPanUpdate: (details) {
          // 只打印每15个点的一次，避免大量日志
          if (kDebugMode &&
              DebugFlags.enableEraseDebug &&
              _updateCounter++ % 15 == 0) {
            print(
                '手势更新: ${details.localPosition}, 增量: ${details.delta}, Alt键: $altKeyPressed');
          }
          if (onPointerMove != null) {
            onPointerMove!(details.localPosition, details.delta);
          }
        },
        onPanEnd: (_) {
          // 只在调试模式下打印
          if (kDebugMode && DebugFlags.enableEraseDebug) {
            print('手势结束, Alt键: $altKeyPressed');
          }
          if (cursorPosition != null && onPointerUp != null) {
            onPointerUp!(cursorPosition!);
          }
        },
        // 确保透明部分也能接收事件
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: Colors.transparent,
          child: super.build(context),
        ),
      ),
    );
  }

  @override
  CustomPainter createPainter() => _UIPainter(
        outline: outline,
        imageSize: imageSize,
        brushSize: brushSize,
        cursorPosition: cursorPosition,
        altKeyPressed: altKeyPressed,
      );

  // 辅助方法：仅更新光标位置
  void _updateCursorPosition(Offset position) {
    // 如果有onPointerMove回调，调用它但设置delta为Zero，表示只是光标移动而非擦除
    onPointerMove?.call(position, Offset.zero);
  }
}

class _UIPainter extends CustomPainter {
  final DetectedOutline? outline;
  final Size? imageSize;
  final double brushSize;
  final Offset? cursorPosition;
  final bool altKeyPressed;

  _UIPainter({
    this.outline,
    this.imageSize,
    this.brushSize = 10.0,
    this.cursorPosition,
    this.altKeyPressed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (outline != null && imageSize != null) {
      _drawOutline(canvas, size);
    }

    // 根据模式显示不同光标
    if (cursorPosition != null) {
      if (altKeyPressed) {
        // 平移模式 - 绘制带有"Pan"标签的手型光标
        _drawPanCursor(canvas, cursorPosition!);
      } else {
        // 擦除模式 - 绘制带有"Erase"标签的圆形光标
        _drawBrushCursor(canvas, cursorPosition!);
      }
    }
  }

  @override
  bool shouldRepaint(_UIPainter oldDelegate) =>
      outline != oldDelegate.outline ||
      imageSize != oldDelegate.imageSize ||
      brushSize != oldDelegate.brushSize ||
      cursorPosition != oldDelegate.cursorPosition ||
      altKeyPressed != oldDelegate.altKeyPressed;

  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // 绘制主线
    canvas.drawLine(start, end, paint);

    // 计算箭头方向
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    // 计算垂直方向
    final perpX = -unitY;
    final perpY = unitX;

    // 计算箭头的两个端点
    const arrowSize = 4.0;
    final arrowPoint1 = Offset(
      end.dx - unitX * arrowSize + perpX * arrowSize,
      end.dy - unitY * arrowSize + perpY * arrowSize,
    );
    final arrowPoint2 = Offset(
      end.dx - unitX * arrowSize - perpX * arrowSize,
      end.dy - unitY * arrowSize - perpY * arrowSize,
    );

    // 绘制箭头
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.blue);
  }

  void _drawBrushCursor(Canvas canvas, Offset position) {
    // 绘制更准确的擦除光标

    // 1. 外轮廓 - 白色，半透明
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // 2. 内轮廓 - 黑色，半透明
    final innerPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 3. 擦除区域预览 - 非常淡的白色填充，表示将被擦除的区域
    final erasePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // 绘制擦除区域预览
    canvas.drawCircle(position, brushSize / 2, erasePaint);

    // 绘制轮廓
    canvas.drawCircle(position, brushSize / 2, outlinePaint);
    canvas.drawCircle(position, brushSize / 2 - 1.5, innerPaint);

    // 绘制十字准星
    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 水平线
    canvas.drawLine(
      Offset(position.dx - brushSize / 4, position.dy),
      Offset(position.dx + brushSize / 4, position.dy),
      crosshairPaint,
    );

    // 垂直线
    canvas.drawLine(
      Offset(position.dx, position.dy - brushSize / 4),
      Offset(position.dx, position.dy + brushSize / 4),
      crosshairPaint,
    );

    // 添加擦除大小提示
    if (brushSize > 15) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: brushSize.round().toString(),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position.translate(-textPainter.width / 2, -textPainter.height / 2),
      );
    }
  }

  void _drawOutline(Canvas canvas, Size canvasSize) {
    final scaleX = canvasSize.width / imageSize!.width;
    final scaleY = canvasSize.height / imageSize!.height;
    final scale = math.min(scaleX, scaleY);

    // 创建两个画笔，一个用于主描边，一个用于外描边效果
    final mainStrokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final outerStrokePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 内部轮廓使用不同颜色以区分
    final innerStrokePaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 内部轮廓的外描边
    final innerOuterStrokePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final offsetX = (canvasSize.width - imageSize!.width * scale) / 2;
    final offsetY = (canvasSize.height - imageSize!.height * scale) / 2;
    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    // 跟踪已绘制的轮廓数
    int contourCount = 0;
    for (final contour in outline!.contourPoints) {
      if (contour.length < 2) continue;
      final path = Path();
      path.moveTo(contour[0].dx, contour[0].dy);

      for (int i = 1; i < contour.length; i++) {
        path.lineTo(contour[i].dx, contour[i].dy);
      }
      path.close();

      // 第一个轮廓使用蓝色（外轮廓），其余使用红色（内轮廓）
      if (contourCount == 0) {
        // 先绘制外描边（白色）
        canvas.drawPath(path, outerStrokePaint);
        // 再绘制主描边（蓝色）
        canvas.drawPath(path, mainStrokePaint);
      } else {
        // 先绘制外描边（白色）
        canvas.drawPath(path, innerOuterStrokePaint);
        // 再绘制主描边（红色）
        canvas.drawPath(path, innerStrokePaint);
      }

      contourCount++;
    }

    // 打印轮廓数量，帮助调试
    print('绘制了 $contourCount 个轮廓');
    canvas.restore();
  }

  void _drawPanCursor(Canvas canvas, Offset position) {
    // 绘制移动指示器 - 手型光标
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // 增加半透明背景圆形，让光标更明显
    canvas.drawCircle(
      position,
      15.0,
      Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // 绘制外圈指示器
    canvas.drawCircle(position, 14.0, paint);

    // 绘制移动指示箭头
    _drawArrow(canvas, position, Offset(position.dx, position.dy - 12), paint);
    _drawArrow(canvas, position, Offset(position.dx, position.dy + 12), paint);
    _drawArrow(canvas, position, Offset(position.dx - 12, position.dy), paint);
    _drawArrow(canvas, position, Offset(position.dx + 12, position.dy), paint);

    // 添加"Pan"标签
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Pan',
        style: TextStyle(
          color: Colors.blue,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position.translate(-textPainter.width / 2, 16),
    );
  }
}
