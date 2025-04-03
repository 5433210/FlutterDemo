import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../presentation/providers/character/erase_providers.dart';
import '../../../utils/debug/debug_flags.dart';

class BrushCursorPainter extends CustomPainter {
  final Offset position;
  final double size;
  final Color color;

  BrushCursorPainter({
    required this.position,
    required this.size,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(position, size / 2, paint);
  }

  @override
  bool shouldRepaint(BrushCursorPainter oldDelegate) {
    return position != oldDelegate.position ||
        size != oldDelegate.size ||
        color != oldDelegate.color;
  }
}

/// UI图层，处理用户交互和显示光标
class UILayer extends ConsumerStatefulWidget {
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
    this.onTap,
    this.cursor = SystemMouseCursors.precise,
    this.outline,
    this.imageSize,
    this.altKeyPressed = false,
    this.brushSize = 10.0,
    this.cursorPosition,
  }) : super(key: key);

  @override
  ConsumerState<UILayer> createState() => _UILayerState();
}

class _UILayerState extends ConsumerState<UILayer> {
  Offset? _mousePosition;
  int _updateCounter = 0;

  @override
  Widget build(BuildContext context) {
    final eraseState = ref.watch(eraseStateProvider);
    final currentCursor =
        widget.altKeyPressed ? SystemMouseCursors.move : widget.cursor;

    return MouseRegion(
      cursor: currentCursor,
      onHover: _handleMouseHover,
      child: Stack(
        children: [
          // 将CustomPaint移到Stack顶层，确保它能绘制轮廓
          CustomPaint(
            painter: _UIPainter(
              outline: widget.outline,
              imageSize: widget.imageSize,
              brushSize: widget.brushSize,
              cursorPosition: _mousePosition ?? widget.cursorPosition,
              altKeyPressed: widget.altKeyPressed,
            ),
            size: Size.infinite,
          ),

          GestureDetector(
            onTapUp: (details) {
              if (widget.onTap != null) {
                print('UI层执行点击回调: ${details.localPosition}');
                widget.onTap!(details.localPosition);
              }
            },
            onPanStart: (details) {
              if (kDebugMode && DebugFlags.enableEraseDebug) {
                print(
                    '手势开始: ${details.localPosition}, Alt键: ${widget.altKeyPressed}');
              }
              if (widget.onPointerDown != null) {
                widget.onPointerDown!(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              if (kDebugMode &&
                  DebugFlags.enableEraseDebug &&
                  _updateCounter++ % 15 == 0) {
                print(
                    '手势更新: ${details.localPosition}, 增量: ${details.delta}, Alt键: ${widget.altKeyPressed}');
              }
              if (widget.onPointerMove != null) {
                widget.onPointerMove!(details.localPosition, details.delta);
              }
            },
            onPanEnd: (_) {
              if (kDebugMode && DebugFlags.enableEraseDebug) {
                print('手势结束, Alt键: ${widget.altKeyPressed}');
              }
              if (widget.cursorPosition != null && widget.onPointerUp != null) {
                widget.onPointerUp!(widget.cursorPosition!);
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // 鼠标光标绘制
          if (_mousePosition != null && !widget.altKeyPressed)
            CustomPaint(
              painter: BrushCursorPainter(
                position: _mousePosition!,
                size: eraseState.brushSize,
                color: eraseState.brushColor.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }

  void _handleMouseHover(PointerHoverEvent event) {
    setState(() {
      _mousePosition = event.localPosition;
    });

    ref.read(cursorPositionProvider.notifier).state = event.localPosition;
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
    // Only print in extreme debug mode
    if (kDebugMode && DebugFlags.enableEraseDebug && false) {
      print(
          'UILayer绘制 - outline: ${outline != null}, imageSize: ${imageSize != null}');
    }

    if (outline != null && imageSize != null) {
      _drawOutline(canvas, size);
    }

    if (cursorPosition != null) {
      if (altKeyPressed) {
        _drawPanCursor(canvas, cursorPosition!);
      } else {
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
    canvas.drawLine(start, end, paint);

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    final unitX = dx / length;
    final unitY = dy / length;

    final perpX = -unitY;
    final perpY = unitX;

    const arrowSize = 4.0;
    final arrowPoint1 = Offset(
      end.dx - unitX * arrowSize + perpX * arrowSize,
      end.dy - unitY * arrowSize + perpY * arrowSize,
    );
    final arrowPoint2 = Offset(
      end.dx - unitX * arrowSize - perpX * arrowSize,
      end.dy - unitY * arrowSize - perpY * arrowSize,
    );

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.blue);
  }

  void _drawBrushCursor(Canvas canvas, Offset position) {
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final innerPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final erasePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, brushSize / 2, erasePaint);
    canvas.drawCircle(position, brushSize / 2, outlinePaint);
    canvas.drawCircle(position, brushSize / 2 - 1.5, innerPaint);

    final crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(position.dx - brushSize / 4, position.dy),
      Offset(position.dx + brushSize / 4, position.dy),
      crosshairPaint,
    );

    canvas.drawLine(
      Offset(position.dx, position.dy - brushSize / 4),
      Offset(position.dx, position.dy + brushSize / 4),
      crosshairPaint,
    );

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

  void _drawOutline(Canvas canvas, Size size) {
    if (outline == null || imageSize == null) {
      if (kDebugMode && DebugFlags.enableEraseDebug) {
        print('_drawOutline: 无轮廓数据或图像尺寸');
      }
      return;
    }

    // Reduce log verbosity
    if (kDebugMode && DebugFlags.enableEraseDebug) {
      print('开始绘制轮廓');
    }

    if (outline!.contourPoints.isEmpty) {
      print('_drawOutline: 轮廓点集为空');
      return;
    }

    print('开始绘制轮廓, 共 ${outline!.contourPoints.length} 条路径');

    // 计算正确的缩放和偏移以确保轮廓与图像对齐
    final scaleX = size.width / imageSize!.width;
    final scaleY = size.height / imageSize!.height;

    // 使用统一缩放比例避免变形
    final scale = math.min(scaleX, scaleY);

    // 计算居中偏移
    final offsetX = (size.width - imageSize!.width * scale) / 2;
    final offsetY = (size.height - imageSize!.height * scale) / 2;

    final mainStrokePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 / scale // 根据缩放比例调整线宽
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outerStrokePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 / scale // 根据缩放比例调整线宽
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    // 应用正确的变换
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    int contourCount = 0;
    for (final contour in outline!.contourPoints) {
      if (contour.length < 2) {
        continue;
      }

      final path = Path();
      path.moveTo(contour[0].dx, contour[0].dy);

      for (int i = 1; i < contour.length; i++) {
        path.lineTo(contour[i].dx, contour[i].dy);
      }
      path.close();

      // 先绘制外描边再绘制内描边，确保可见性
      canvas.drawPath(path, outerStrokePaint);
      canvas.drawPath(path, mainStrokePaint);

      contourCount++;
    }

    print('成功绘制了 $contourCount 个轮廓');

    // 调试显示边界框
    if (kDebugMode && DebugFlags.enableEraseDebug) {
      final bounds = outline!.boundingRect;
      canvas.drawRect(
        bounds,
        Paint()
          ..color = Colors.yellow.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0 / scale,
      );
    }

    canvas.restore();
  }

  void _drawPanCursor(Canvas canvas, Offset position) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      position,
      15.0,
      Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(position, 14.0, paint);

    _drawArrow(canvas, position, Offset(position.dx, position.dy - 12), paint);
    _drawArrow(canvas, position, Offset(position.dx, position.dy + 12), paint);
    _drawArrow(canvas, position, Offset(position.dx - 12, position.dy), paint);
    _drawArrow(canvas, position, Offset(position.dx + 12, position.dy), paint);

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
