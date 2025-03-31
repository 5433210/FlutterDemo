import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 交互层
/// 处理用户输入和显示光标
class UILayer extends StatefulWidget {
  /// 变换控制器
  final TransformationController transformationController;

  /// 是否启用擦除模式
  final bool eraseMode;

  /// 笔刷大小
  final double brushSize;

  /// 手势回调
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureDragCancelCallback? onPanCancel;

  /// 变换回调
  final VoidCallback? onTransformationChanged;

  const UILayer({
    Key? key,
    required this.transformationController,
    this.eraseMode = false,
    this.brushSize = 20.0,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
    this.onTransformationChanged,
  }) : super(key: key);

  @override
  State<UILayer> createState() => _UILayerState();
}

class _UILayerState extends State<UILayer> {
  // 鼠标位置
  Offset? _mousePosition;

  // 是否按下Alt键
  bool _isAltPressed = false;

  // 记录上一次的焦点位置
  Offset? _lastFocalPoint;
  Offset? _lastGlobalPoint;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.eraseMode
          ? SystemMouseCursors.precise
          : SystemMouseCursors.basic,
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      child: GestureDetector(
        onScaleStart: (details) {
          _lastFocalPoint = details.localFocalPoint;
          _lastGlobalPoint = details.focalPoint;
          if (_isAltPressed) {
            // 平移模式
            widget.transformationController.value = Matrix4.identity()
              ..translate(
                  details.localFocalPoint.dx, details.localFocalPoint.dy);
          } else if (widget.eraseMode && !_isAltPressed) {
            widget.onPanStart?.call(
              DragStartDetails(
                globalPosition: details.focalPoint,
                localPosition: details.localFocalPoint,
              ),
            );
          }
        },
        onScaleUpdate: (details) {
          if (_isAltPressed) {
            // 平移
            final delta = details.localFocalPoint -
                (_lastFocalPoint ?? details.localFocalPoint);
            _lastFocalPoint = details.localFocalPoint;
            _lastGlobalPoint = details.focalPoint;

            final Matrix4 matrix = Matrix4.identity();
            matrix.translate(delta.dx, delta.dy);
            widget.transformationController.value = matrix;
            widget.onTransformationChanged?.call();
          } else if (details.scale != 1.0) {
            // 缩放
            final scale =
                widget.transformationController.value.getMaxScaleOnAxis();
            final newScale = scale * details.scale;
            if (newScale >= 0.5 && newScale <= 5.0) {
              final Matrix4 matrix = Matrix4.identity();
              matrix.scale(newScale);
              widget.transformationController.value = matrix;
              widget.onTransformationChanged?.call();
            }
          } else if (widget.eraseMode && !_isAltPressed) {
            // 擦除
            final delta = details.localFocalPoint -
                (_lastFocalPoint ?? details.localFocalPoint);
            _lastFocalPoint = details.localFocalPoint;
            _lastGlobalPoint = details.focalPoint;

            widget.onPanUpdate?.call(
              DragUpdateDetails(
                globalPosition: details.focalPoint,
                localPosition: details.localFocalPoint,
                delta: delta,
              ),
            );
          }
        },
        onScaleEnd: (details) {
          _lastFocalPoint = null;
          _lastGlobalPoint = null;
          if (widget.eraseMode && !_isAltPressed) {
            widget.onPanEnd?.call(
              DragEndDetails(
                velocity: details.velocity,
              ),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 透明层接收事件
            Container(
              color: Colors.transparent,
            ),
            // 光标层
            _buildCursor(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 添加键盘监听
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  // 构建光标
  Widget _buildCursor() {
    if (!widget.eraseMode || _mousePosition == null) {
      return const SizedBox.shrink();
    }

    final scale = widget.transformationController.value.getMaxScaleOnAxis();
    final adjustedBrushSize = widget.brushSize * scale;

    return Positioned(
      left: _mousePosition!.dx - adjustedBrushSize / 2,
      top: _mousePosition!.dy - adjustedBrushSize / 2,
      child: IgnorePointer(
        child: Container(
          width: adjustedBrushSize,
          height: adjustedBrushSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 1.5,
            ),
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }

  // 处理键盘事件
  void _handleKeyEvent(RawKeyEvent event) {
    final bool isAltPressed = event.isAltPressed;
    if (isAltPressed != _isAltPressed) {
      setState(() {
        _isAltPressed = isAltPressed;
      });
    }
  }
}
