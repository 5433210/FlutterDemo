import 'dart:math' as math;

import 'package:charasgem/infrastructure/logging/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/character/detected_outline.dart';
import '../../../providers/character/erase_providers.dart';

class BrushCursorPainter extends CustomPainter {
  final Offset position;
  final double size;
  final Color color;
  final bool isMobile; // 新增：移动端标识

  BrushCursorPainter({
    required this.position,
    required this.size,
    required this.color,
    this.isMobile = false, // 默认为桌面端
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final radius = size;

    // 移动端优化：更加明显的颜色和线条
    final double fillAlpha = isMobile ? 0.4 : 0.3; // 移动端更不透明
    final double borderWidth = isMobile ? 2.0 : 1.0; // 移动端更粗的边框

    // 移动端增强对比度：添加白色背景光环
    if (isMobile) {
      final haloRadius = radius + 3.0;
      final haloPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..isAntiAlias = true;
      canvas.drawCircle(position, haloRadius, haloPaint);
    }

    // 笔刷区域填充
    final fillPaint = Paint()
      ..color = color.withValues(alpha: fillAlpha)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.drawCircle(position, radius, fillPaint);

    // 笔刷边框
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..isAntiAlias = true;

    canvas.drawCircle(position, radius, borderPaint);

    // 移动端优化的十字线：更粗更明显
    final crosshairColor =
        isMobile ? Colors.red : Colors.red.withValues(alpha: 0.7);
    final crosshairStrokeWidth =
        isMobile ? math.max(2.0, size / 15) : size / 20;

    final crosshairPaint = Paint()
      ..color = crosshairColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = crosshairStrokeWidth
      ..isAntiAlias = true;

    final crosshairSize = radius * (isMobile ? 0.8 : 0.7); // 移动端稍大一些

    // 移动端增强十字线：添加白色背景描边
    if (isMobile) {
      final backgroundPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = crosshairStrokeWidth + 2.0
        ..isAntiAlias = true;

      // 白色背景线
      canvas.drawLine(
        Offset(position.dx - crosshairSize, position.dy),
        Offset(position.dx + crosshairSize, position.dy),
        backgroundPaint,
      );
      canvas.drawLine(
        Offset(position.dx, position.dy - crosshairSize),
        Offset(position.dx, position.dy + crosshairSize),
        backgroundPaint,
      );
    }

    // 主十字线
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

    // 移动端优化的尺寸指示器：更大更清晰
    final sizeThreshold = isMobile ? 10 : 15; // 移动端更容易显示尺寸
    if (size > sizeThreshold) {
      final fontSize = isMobile ? 13.0 : 11.0; // 移动端更大字体
      final textPainter = TextPainter(
        text: TextSpan(
          text: size.round().toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: isMobile ? 3 : 2, // 移动端更强的阴影
                color: Colors.black.withValues(alpha: 0.9), // 更深的阴影
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // 移动端增强：添加文本背景圆圈
      if (isMobile) {
        final textBgRadius =
            math.max(textPainter.width, textPainter.height) / 2 + 4;
        final textBgPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
        canvas.drawCircle(position, textBgRadius, textBgPaint);
      }

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

  // 移动端检测 - 使用多种方法综合判断
  bool get _isMobile {
    // 优先使用平台判断
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }

    // 对于Web平台，可以通过其他方式判断
    if (kIsWeb) {
      // 在Web上，可以通过屏幕尺寸和用户代理来判断
      final size = MediaQuery.of(context).size;
      return size.width < 768; // 平板一般768px以上
    }

    return false;
  }

  // 多指手势支持 - 移动端专用
  final Map<int, Offset> _activePointers = {};
  bool _isMultiPointer = false;
  Offset? _singlePointerStart;

  // 多指手势状态追踪
  bool _hasBeenMultiPointer = false; // 记录本次手势序列是否曾经是多指
  int _maxPointerCount = 0; // 记录本次手势序列的最大指针数量

  // 手势识别常量
  static const double _dragThreshold = 15.0; // 拖拽阈值

  @override
  Widget build(BuildContext context) {
    final eraseState = ref.watch(eraseStateProvider);
    final currentCursor =
        widget.altKeyPressed ? SystemMouseCursors.move : widget.cursor;

    // AppLogger.debug('🔧 [UILayer] build方法调用', data: {
    //   'screenWidth': screenSize.width.toStringAsFixed(1),
    //   'screenHeight': screenSize.height.toStringAsFixed(1),
    //   'isMobile': _isMobile,
    //   'defaultTargetPlatform': defaultTargetPlatform.toString(),
    //   'themeplatform': Theme.of(context).platform.toString(),
    //   'kIsWeb': kIsWeb,
    // });

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

          // 根据平台选择不同的手势处理方式
          _isMobile
              ? _buildMobileGestureHandler()
              : _buildDesktopGestureHandler(),

          // Show cursor when we have a position and not in alt-key/pan mode
          if (_mousePosition != null && !widget.altKeyPressed)
            CustomPaint(
              painter: BrushCursorPainter(
                position: _mousePosition!,
                size: eraseState.brushSize,
                color: eraseState.brushColor,
                isMobile: _isMobile, // 添加移动端标识
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

  /// 桌面端手势处理器
  Widget _buildDesktopGestureHandler() {
    return GestureDetector(
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
    );
  }

  /// 移动端手势处理器 - 支持多点触控
  Widget _buildMobileGestureHandler() {
    AppLogger.debug('📱 [UILayer] 构建移动端手势处理器');

    return Listener(
      onPointerDown: (event) {
        AppLogger.debug('📱 [UILayer] Listener onPointerDown', data: {
          'pointer': event.pointer,
          'position':
              '${event.localPosition.dx.toStringAsFixed(1)},${event.localPosition.dy.toStringAsFixed(1)}',
        });
        _handleMobilePointerDown(event);
      },
      onPointerMove: (event) {
        AppLogger.debug('📱 [UILayer] Listener onPointerMove', data: {
          'pointer': event.pointer,
          'position':
              '${event.localPosition.dx.toStringAsFixed(1)},${event.localPosition.dy.toStringAsFixed(1)}',
        });
        _handleMobilePointerMove(event);
      },
      onPointerUp: (event) {
        AppLogger.debug('📱 [UILayer] Listener onPointerUp', data: {
          'pointer': event.pointer,
          'position':
              '${event.localPosition.dx.toStringAsFixed(1)},${event.localPosition.dy.toStringAsFixed(1)}',
        });
        _handleMobilePointerUp(event);
      },
      onPointerCancel: _handleMobilePointerCancel,
      behavior: HitTestBehavior.translucent,
      child: GestureDetector(
        onTapUp: (details) {
          if (widget.onTap != null &&
              _isWithinImageBounds(details.localPosition)) {
            _updateMousePosition(details.localPosition);
            widget.onTap!(details.localPosition);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(color: Colors.transparent),
      ),
    );
  }

  /// 移动端指针按下事件 - 多指手势检测
  void _handleMobilePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    _isMultiPointer = _activePointers.length > 1;
    _maxPointerCount = math.max(_maxPointerCount, _activePointers.length);

    AppLogger.debug(
      '🖱️ [UILayer] 移动端指针按下',
      data: {
        'pointer': event.pointer,
        'position':
            '${event.localPosition.dx.toStringAsFixed(1)},${event.localPosition.dy.toStringAsFixed(1)}',
        'pointersCount': _activePointers.length,
        'isMultiPointer': _isMultiPointer,
        'hasBeenMultiPointer': _hasBeenMultiPointer,
        'activePointers': _activePointers.keys.toList(),
      },
    );

    // 如果变成多指操作，记录状态并立即停止任何单指操作
    if (_isMultiPointer) {
      _hasBeenMultiPointer = true;

      // 立即停止任何正在进行的单指操作
      if (_isDragging) {
        AppLogger.debug('🛑 [UILayer] 多指检测，停止单指操作',
            data: {'wasDragging': _isDragging});
        _cancelCurrentGesture();
      }

      AppLogger.debug(
        '💆 [UILayer] 多指检测 - 交给InteractiveViewer处理',
        data: {
          'pointer': event.pointer,
          'count': _activePointers.length,
          'maxCount': _maxPointerCount,
        },
      );
      return; // 多指操作交给InteractiveViewer处理
    }

    // 只有在真正的单指操作且从未变成多指时才处理
    if (!_hasBeenMultiPointer && !_isMultiPointer) {
      AppLogger.debug('✅ [UILayer] 确认单指操作，开始擦除', data: {
        'position':
            '${event.localPosition.dx.toStringAsFixed(1)},${event.localPosition.dy.toStringAsFixed(1)}',
        'hasBeenMultiPointer': _hasBeenMultiPointer,
        'isMultiPointer': _isMultiPointer,
      });

      // 单指操作，开始擦除操作
      _singlePointerStart = event.localPosition;
      _isDragging = false;
      _updateMousePosition(event.localPosition);

      // 立即开始擦除操作
      if (widget.onPointerDown != null) {
        AppLogger.debug('🎯 [UILayer] 调用擦除开始回调');
        widget.onPointerDown!(event.localPosition);
      }
    } else {
      AppLogger.debug('🚫 [UILayer] 跳过单指处理', data: {
        'hasBeenMultiPointer': _hasBeenMultiPointer,
        'isMultiPointer': _isMultiPointer,
      });
    }
  }

  /// 移动端指针移动事件 - 多指手势检测
  void _handleMobilePointerMove(PointerMoveEvent event) {
    if (_activePointers.containsKey(event.pointer)) {
      _activePointers[event.pointer] = event.localPosition;

      // 检查是否变成了多指操作
      final wasMultiPointer = _isMultiPointer;
      _isMultiPointer = _activePointers.length > 1;
      _maxPointerCount = math.max(_maxPointerCount, _activePointers.length);

      if (!wasMultiPointer && _isMultiPointer) {
        // 从单指变成多指，立即停止单指操作
        _hasBeenMultiPointer = true;
        AppLogger.debug(
          '🛑 [UILayer] 移动中检测到多指，停止单指操作',
          data: {
            'pointer': event.pointer,
            'pointerCount': _activePointers.length,
            'wasDragging': _isDragging,
            'activePointers': _activePointers.keys.toList(),
          },
        );
        if (_isDragging) {
          _cancelCurrentGesture();
        }
        return;
      }
    }

    // 多指手势不处理，让InteractiveViewer处理
    if (_isMultiPointer || _hasBeenMultiPointer) {
      AppLogger.debug('⏭️ [UILayer] 跳过多指移动事件', data: {
        'isMultiPointer': _isMultiPointer,
        'hasBeenMultiPointer': _hasBeenMultiPointer,
        'activePointers': _activePointers.length,
      });
      return;
    }

    // 单指手势处理
    if (_singlePointerStart != null &&
        !_hasBeenMultiPointer &&
        !_isMultiPointer) {
      _updateMousePosition(event.localPosition);

      final distance = (event.localPosition - _singlePointerStart!).distance;

      if (!_isDragging && distance > _dragThreshold) {
        // 开始拖拽
        _isDragging = true;
        AppLogger.debug('🏃 [UILayer] 开始拖拽擦除', data: {
          'distance': distance.toStringAsFixed(1),
          'threshold': _dragThreshold,
        });
      }

      if (_isDragging && widget.onPointerMove != null) {
        AppLogger.debug('🎯 [UILayer] 单指擦除移动', data: {
          'position':
              '${event.localPosition.dx.toStringAsFixed(1)},${event.localPosition.dy.toStringAsFixed(1)}',
          'delta':
              '${event.delta.dx.toStringAsFixed(1)},${event.delta.dy.toStringAsFixed(1)}',
        });
        widget.onPointerMove!(event.localPosition, event.delta);
      }
    }
  }

  /// 移动端指针释放事件 - 多指手势检测
  void _handleMobilePointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    _isMultiPointer = _activePointers.length > 1;

    AppLogger.debug(
      '🖱️ [UILayer] 移动端指针释放',
      data: {
        'pointer': event.pointer,
        'beforeCount': _activePointers.length,
        'afterCount': _activePointers.length - 1,
        'isDragging': _isDragging,
        'hasBeenMultiPointer': _hasBeenMultiPointer,
        'remainingPointers':
            _activePointers.keys.where((k) => k != event.pointer).toList(),
      },
    );

    // 如果所有指针都释放了
    if (_activePointers.isEmpty) {
      AppLogger.debug(
        '🔄 所有指针释放，重置手势状态',
        data: {
          'hadBeenMultiPointer': _hasBeenMultiPointer,
          'maxPointerCount': _maxPointerCount,
          'wasDragging': _isDragging,
        },
      );

      // 只有在纯单指操作时才完成擦除手势
      if (!_hasBeenMultiPointer && _isDragging) {
        // 调用擦除结束回调
        if (widget.onPointerUp != null) {
          if (_mousePosition != null) {
            widget.onPointerUp!(_mousePosition!);
          } else if (widget.cursorPosition != null) {
            widget.onPointerUp!(widget.cursorPosition!);
          }
        }
      } else if (_hasBeenMultiPointer) {
        // 曾经是多指操作，直接取消所有手势
        AppLogger.debug('📱 多指操作结束，已取消所有手势');
      }

      // 重置所有手势追踪状态
      _resetGestureState();
    }
  }

  /// 移动端指针取消事件 - 多指手势检测
  void _handleMobilePointerCancel(PointerCancelEvent event) {
    _activePointers.remove(event.pointer);
    _isMultiPointer = _activePointers.length > 1;

    AppLogger.debug(
        '💆 移动端指针取消: ${event.pointer}, 数量: ${_activePointers.length}');

    // 如果所有指针都释放了，重置状态
    if (_activePointers.isEmpty) {
      // 指针取消时，直接取消所有手势操作
      _cancelCurrentGesture();
      _resetGestureState();
      AppLogger.debug('🚫 移动端指针取消，已重置所有状态');
    }
  }

  /// 取消当前手势操作
  void _cancelCurrentGesture() {
    // 清除拖拽状态
    _isDragging = false;
    _singlePointerStart = null;

    AppLogger.debug('✅ 手势操作已取消');
  }

  /// 重置手势状态
  void _resetGestureState() {
    _singlePointerStart = null;
    _isDragging = false;

    // 重置多指追踪状态
    _hasBeenMultiPointer = false;
    _maxPointerCount = 0;

    AppLogger.debug('🔄 手势状态已重置');
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
