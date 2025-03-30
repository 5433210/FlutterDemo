import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../controllers/erase_tool_provider.dart';

/// UI交互层
/// 处理用户输入和显示交互元素
class UILayer extends StatefulWidget {
  /// 手势回调
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
  final GestureCancelCallback? onPanCancel;

  /// 图层链接器
  final LayerLink layerLink;

  /// 构造函数
  const UILayer({
    Key? key,
    required this.layerLink,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
    this.onPanCancel,
  }) : super(key: key);

  @override
  State<UILayer> createState() => _UILayerState();
}

class _UILayerState extends State<UILayer> {
  // 当前拖动状态
  bool _isDragging = false;
  Offset? _dragStartPosition;

  @override
  Widget build(BuildContext context) {
    final controller = EraseToolProvider.of(context);

    return CompositedTransformFollower(
      link: widget.layerLink,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 简化为只处理事件的层，不再负责光标显示
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent, // 透明传递行为
              onPointerDown: (event) {
                // 左键或触摸开始拖动
                if (event.buttons == kPrimaryMouseButton ||
                    event.kind == PointerDeviceKind.touch) {
                  _startDrag(event.localPosition);
                }
                print('👇 UILayer: 指针按下 at ${event.localPosition}');
              },
              onPointerMove: (event) {
                if (_isDragging) {
                  _updateDrag(event.localPosition);
                  if (event.delta.distance > 5) {
                    print(
                        '👉 UILayer: 拖动中 at ${event.localPosition} delta=${event.delta.distance}');
                  }
                }
              },
              onPointerUp: (event) {
                if (_isDragging) {
                  _endDrag(event.localPosition);
                }
                print('👆 UILayer: 指针抬起 at ${event.localPosition}');
              },
              onPointerCancel: (event) {
                if (_isDragging) {
                  _cancelDrag();
                }
                print('❌ UILayer: 指针取消');
              },
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // 状态指示器
          if (controller.isErasing)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Points: ${controller.currentPoints.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 取消拖动操作
  void _cancelDrag() {
    if (mounted) {
      setState(() {
        _isDragging = false;
      });

      print('❌ 取消擦除');
      widget.onPanCancel?.call();
      _dragStartPosition = null;
    }
  }

  // 结束拖动操作
  void _endDrag(Offset position) {
    if (mounted) {
      setState(() {
        _isDragging = false;
      });

      // 构造拖动结束细节
      final dragEndDetails = DragEndDetails(
        velocity: Velocity.zero,
        primaryVelocity: 0,
      );

      print('✓ 完成擦除');
      widget.onPanEnd?.call(dragEndDetails);
      _dragStartPosition = null;
    }
  }

  // 开始拖动操作
  void _startDrag(Offset position) {
    if (mounted) {
      setState(() {
        _isDragging = true;
        _dragStartPosition = position;
      });

      // 转换为DragStartDetails并调用回调
      final dragStartDetails = DragStartDetails(
        sourceTimeStamp: Duration.zero,
        globalPosition: position,
        localPosition: position,
      );

      print('🖌️ 开始擦除: $position');
      widget.onPanStart?.call(dragStartDetails);
    }
  }

  // 更新拖动操作
  void _updateDrag(Offset position) {
    if (_isDragging && mounted) {
      // 计算增量
      final delta = _dragStartPosition != null
          ? position - _dragStartPosition!
          : Offset.zero;

      // 构造拖动更新细节 - 对于pan手势，primaryDelta应该为null
      final dragUpdateDetails = DragUpdateDetails(
        sourceTimeStamp: Duration.zero,
        globalPosition: position,
        localPosition: position,
        delta: delta,
        primaryDelta: null, // 修复：对于pan手势，primaryDelta应为null
      );

      // 更新起始位置为当前位置
      _dragStartPosition = position;

      // 调用回调
      widget.onPanUpdate?.call(dragUpdateDetails);
    }
  }
}
