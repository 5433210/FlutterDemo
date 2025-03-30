import 'package:flutter/material.dart';

import '../controllers/erase_tool_provider.dart';

/// 专用光标覆盖层
/// 确保光标始终在最上层且跟随鼠标移动
class CursorOverlay extends StatefulWidget {
  /// 容器Key
  final GlobalKey containerKey;

  /// 构造函数
  const CursorOverlay({
    Key? key,
    required this.containerKey,
  }) : super(key: key);

  @override
  State<CursorOverlay> createState() => _CursorOverlayState();
}

class _CursorOverlayState extends State<CursorOverlay> {
  Offset _cursorPosition = Offset.zero;
  bool _isPointerDown = false;
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    // 获取控制器
    final controller = EraseToolProvider.of(context);
    final brushSize = controller.brushSize;
    final isErasing = controller.isErasing || _isPointerDown;

    // 如果鼠标不在区域内则不显示
    if (!_isVisible && !_isPointerDown) {
      return const SizedBox.shrink();
    }

    // 透明覆盖层 + 光标
    return Stack(
      children: [
        // 透明的事件接收层
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              setState(() {
                _isPointerDown = true;
                _cursorPosition = event.localPosition;
              });
            },
            onPointerMove: (event) {
              setState(() {
                _cursorPosition = event.localPosition;
              });
            },
            onPointerUp: (event) {
              setState(() {
                _isPointerDown = false;
              });
            },
            onPointerCancel: (event) {
              setState(() {
                _isPointerDown = false;
              });
            },
            child: MouseRegion(
              onEnter: (_) => setState(() => _isVisible = true),
              onExit: (_) => setState(() => _isVisible = false),
              onHover: (event) =>
                  setState(() => _cursorPosition = event.localPosition),
              opaque: false,
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        // 光标显示
        if (_cursorPosition != Offset.zero)
          Positioned(
            left: _cursorPosition.dx - brushSize / 2,
            top: _cursorPosition.dy - brushSize / 2,
            child: Container(
              width: brushSize,
              height: brushSize,
              decoration: BoxDecoration(
                color: isErasing
                    ? Colors.red.withOpacity(0.3)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isErasing ? Colors.red : Colors.blue,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
