import 'dart:math' as math;

import 'package:charasgem/infrastructure/logging/logger.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/detected_outline.dart';
import '../../../presentation/providers/character/erase_providers.dart';

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
    final radius = size;

    // Clean anti-aliased edge instead of radial gradient
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3) // Light fill
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Draw brush area with anti-aliasing
    canvas.drawCircle(position, radius, fillPaint);

    // Draw crisp edge
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = true;

    canvas.drawCircle(position, radius, borderPaint);

    // Draw crosshair for precise positioning
    final crosshairPaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size / 20
      ..isAntiAlias = true;

    final crosshairSize = radius * 0.7; // Slightly smaller crosshair

    canvas.drawLine(
      Offset(position.dx - crosshairSize, position.dy),
      Offset(position.dx + crosshairSize, position.dy),
      crosshairPaint,
    );

    canvas.drawLine(
      Offset(position.dx, position.dy - crosshairSize),
      Offset(position.dx, position.dy + crosshairSize),
      crosshairPaint,
    );

    // Show size indicator for larger brushes
    if (size > 15) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: size.round().toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.8),
              ),
            ],
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

  bool _isDragging = false;

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
              if (widget.onTap != null &&
                  _isWithinImageBounds(details.localPosition)) {
                _updateMousePosition(details.localPosition);
                widget.onTap!(details.localPosition);
              }
            },
            onPanStart: (details) {
              _isDragging = true;
              if (_isWithinImageBounds(details.localPosition)) {
                _updateMousePosition(details.localPosition);

                // 当Alt键没有按下时，调用擦除开始回调
                if (!widget.altKeyPressed && widget.onPointerDown != null) {
                  widget.onPointerDown!(details.localPosition);
                }
              }
            },
            onPanUpdate: (details) {
              // Update cursor position during dragging if within bounds
              if (_isWithinImageBounds(details.localPosition)) {
                _updateMousePosition(details.localPosition);

                // 当Alt键按下时，使用onPan回调进行平移操作
                if (widget.altKeyPressed) {
                  if (widget.onPan != null) {
                    widget.onPan!(details.delta);
                  }
                } else if (widget.onPointerMove != null) {
                  // 否则正常擦除
                  widget.onPointerMove!(details.localPosition, details.delta);
                }
              }
            },
            onPanEnd: (_) {
              _isDragging = false;

              // 当Alt键没有按下时，才调用擦除结束回调
              if (!widget.altKeyPressed && widget.onPointerUp != null) {
                if (_mousePosition != null) {
                  widget.onPointerUp!(_mousePosition!);
                } else if (widget.cursorPosition != null) {
                  widget.onPointerUp!(widget.cursorPosition!);
                }
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
            ),
          ),

          // Show cursor when we have a position and not in alt-key/pan mode
          if (_mousePosition != null && !widget.altKeyPressed)
            CustomPaint(
              painter: BrushCursorPainter(
                position: _mousePosition!,
                size: eraseState.brushSize,
                color: eraseState.brushColor,
              ),
            ),
        ],
      ),
    );
  }

  void _handleMouseHover(PointerHoverEvent event) {
    // Only process hover events if we're not dragging and position is within image bounds
    if (!_isDragging && _isWithinImageBounds(event.localPosition)) {
      _updateMousePosition(event.localPosition);
    }
  }

  // Helper to check if position is within image bounds
  bool _isWithinImageBounds(Offset position) {
    if (widget.imageSize == null) {
      return true; // If no image size is set, allow all positions
    }

    return position.dx >= 0 &&
        position.dx < widget.imageSize!.width &&
        position.dy >= 0 &&
        position.dy < widget.imageSize!.height;
  }

  void _updateMousePosition(Offset position) {
    // Only update if position is within bounds
    if (_isWithinImageBounds(position)) {
      setState(() {
        _mousePosition = position;
      });

      // Also update the provider so other components can access cursor position
      ref.read(cursorPositionProvider.notifier).state = position;
    }
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
    // 移除不再使用的参数
    this.cursorPosition, // 保留但不使用，避免修改调用代码
    this.altKeyPressed = false, // 保留但不使用，避免修改调用代码
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 只绘制轮廓，不再绘制自定义光标
    if (outline != null && imageSize != null) {
      _drawOutline(canvas, size);
    }

    // 移除自定义pan光标绘制，使用系统move光标代替
    // 当按下Alt键时，MouseRegion会自动切换为SystemMouseCursors.move
  }

  @override
  bool shouldRepaint(_UIPainter oldDelegate) =>
      outline != oldDelegate.outline ||
      imageSize != oldDelegate.imageSize ||
      brushSize != oldDelegate.brushSize;

  // _drawArrow方法已移除，不再需要

  void _drawOutline(Canvas canvas, Size size) {
    if (outline == null || imageSize == null) {
      AppLogger.debug('_drawOutline: 无轮廓数据或图像尺寸');
      return;
    }

    // 检查轮廓数据是否有效
    if (outline!.contourPoints.isEmpty) {
      AppLogger.debug('_drawOutline: 轮廓点集为空');
      return;
    }

    // print('开始绘制轮廓, 共 ${outline!.contourPoints.length} 条路径');

    // 计算正确的缩放和偏移以确保轮廓与图像对齐
    final scaleX = size.width / imageSize!.width;
    final scaleY = size.height / imageSize!.height;

    // 使用统一缩放比例避免变形
    final scale = math.min(scaleX, scaleY);

    // 计算居中偏移
    final offsetX = (size.width - imageSize!.width * scale) / 2;
    final offsetY = (size.height - imageSize!.height * scale) / 2;

    // 增强轮廓线条清晰度和可见性
    final mainStrokePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.9) // 提高不透明度
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5 / scale // 加粗轮廓线
      // ..strokeCap = StrokeCap.round
      // ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true; // 确保抗锯齿

    canvas.save();
    // 应用正确的变换
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);

    for (final contour in outline!.contourPoints) {
      if (contour.length < 2) {
        continue;
      }

      // 使用path来绘制复杂轮廓可获得更好的性能和质量
      final path = Path();

      // 确保起点是有效的
      if (!contour[0].dx.isFinite || !contour[0].dy.isFinite) {
        AppLogger.debug('轮廓点无效，跳过该轮廓');
        continue;
      }

      path.moveTo(contour[0].dx, contour[0].dy);

      for (int i = 1; i < contour.length; i++) {
        // 验证点的有效性
        if (!contour[i].dx.isFinite || !contour[i].dy.isFinite) {
          AppLogger.debug('发现无效轮廓点，继续使用前一个有效点');
          continue;
        }
        path.lineTo(contour[i].dx, contour[i].dy);
      }
      path.close();

      // 先绘制外描边再绘制内描边，确保可见性
      // canvas.drawPath(path, outerStrokePaint);
      canvas.drawPath(path, mainStrokePaint);
    }

    canvas.restore();
  }

  // _drawPanCursor方法已移除，使用系统move光标代替
}
