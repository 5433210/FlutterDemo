import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// UI图层
/// 处理用户交互
class UILayer extends StatefulWidget {
  /// 变换控制器
  final TransformationController transformationController;

  /// 是否处于擦除模式
  final bool eraseMode;

  /// 笔刷大小
  final double brushSize;

  /// 手势回调
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  const UILayer({
    Key? key,
    required this.transformationController,
    this.eraseMode = true,
    this.brushSize = 20.0,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  }) : super(key: key);

  @override
  State<UILayer> createState() => _UILayerState();
}

/// 光标绘制器
class _CursorPainter extends CustomPainter {
  final double brushSize;
  final bool showCursor;
  final Offset position;

  const _CursorPainter({
    required this.brushSize,
    required this.position,
    this.showCursor = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!showCursor) return;

    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // 绘制圆形笔刷指示器
    final radius = brushSize / 2;
    canvas.drawCircle(position, radius, paint);

    // 绘制十字线
    const crossSize = 4.0;
    canvas.drawLine(
      position.translate(-radius - crossSize, 0),
      position.translate(-radius + crossSize, 0),
      paint,
    );
    canvas.drawLine(
      position.translate(radius - crossSize, 0),
      position.translate(radius + crossSize, 0),
      paint,
    );
    canvas.drawLine(
      position.translate(0, -radius - crossSize),
      position.translate(0, -radius + crossSize),
      paint,
    );
    canvas.drawLine(
      position.translate(0, radius - crossSize),
      position.translate(0, radius + crossSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CursorPainter oldDelegate) {
    return brushSize != oldDelegate.brushSize ||
        showCursor != oldDelegate.showCursor ||
        position != oldDelegate.position;
  }
}

class _UILayerState extends State<UILayer> {
  bool _isAltPressed = false;
  bool _isPanning = false;
  bool _isTransforming = false;
  Offset _mousePosition = Offset.zero;
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Stack(
        children: [
          // 基础层 - 处理擦除
          if (!_isAltPressed)
            Positioned.fill(
              child: Listener(
                onPointerHover: _updateMousePosition,
                onPointerDown: (event) {
                  if (event.kind == PointerDeviceKind.mouse &&
                      event.buttons == kPrimaryMouseButton) {
                    _isPanning = true;
                    widget.onPanStart?.call(DragStartDetails(
                      globalPosition: event.position,
                      localPosition: event.localPosition,
                    ));
                  }
                },
                onPointerMove: (event) {
                  if (_isPanning) {
                    widget.onPanUpdate?.call(DragUpdateDetails(
                      globalPosition: event.position,
                      localPosition: event.localPosition,
                      delta: event.delta,
                    ));
                  }
                },
                onPointerUp: (event) {
                  if (_isPanning) {
                    _isPanning = false;
                    widget.onPanEnd?.call(DragEndDetails());
                  }
                },
                onPointerCancel: (event) {
                  if (_isPanning) {
                    _isPanning = false;
                    widget.onPanCancel?.call();
                  }
                },
                child: MouseRegion(
                  cursor: widget.eraseMode
                      ? SystemMouseCursors.precise
                      : SystemMouseCursors.basic,
                  child: CustomPaint(
                    painter: _CursorPainter(
                      brushSize: widget.brushSize,
                      showCursor: widget.eraseMode,
                      position: _mousePosition,
                    ),
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
            ),

          // 变换层 - 处理移动和缩放
          if (_isAltPressed)
            Positioned.fill(
              child: MouseRegion(
                cursor: _isTransforming
                    ? SystemMouseCursors.grabbing
                    : SystemMouseCursors.grab,
                child: InteractiveViewer(
                  transformationController: widget.transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(20.0),
                  panEnabled: true,
                  scaleEnabled: true,
                  onInteractionStart: (_) {
                    setState(() {
                      _isTransforming = true;
                    });
                  },
                  onInteractionEnd: (_) {
                    setState(() {
                      _isTransforming = false;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 状态提示
          if (_isAltPressed)
            Positioned(
              left: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.pan_tool_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '移动和缩放模式 (Alt)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  /// 处理键盘事件
  void _handleKeyEvent(RawKeyEvent event) {
    final bool isAltPressed = event.isAltPressed;
    if (_isAltPressed != isAltPressed) {
      setState(() {
        _isAltPressed = isAltPressed;
        if (!isAltPressed) {
          _isTransforming = false;
        }
      });
    }
  }

  /// 更新鼠标位置
  void _updateMousePosition(PointerEvent event) {
    if (mounted && !_isAltPressed) {
      setState(() {
        _mousePosition = event.localPosition;
      });
    }
  }
}
