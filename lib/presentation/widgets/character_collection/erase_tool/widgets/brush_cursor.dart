import 'package:flutter/material.dart';

/// 笔刷光标
/// 跟随鼠标位置显示笔刷大小指示器
class BrushCursor extends StatefulWidget {
  /// 笔刷大小
  final double brushSize;

  /// 是否正在擦除
  final bool isErasing;

  /// 构造函数
  const BrushCursor({
    Key? key,
    required this.brushSize,
    required this.isErasing,
  }) : super(key: key);

  @override
  State<BrushCursor> createState() => _BrushCursorState();
}

class _BrushCursorState extends State<BrushCursor> {
  Offset _cursorPosition = Offset.zero;
  bool _isPointerInside = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (event) {
        setState(() {
          _cursorPosition = event.localPosition;
          _isPointerInside = true;
          print('笔刷光标: 悬停在 $_cursorPosition');
        });
      },
      onPointerDown: (event) {
        setState(() {
          _cursorPosition = event.localPosition;
          _isPointerInside = true;
          print('🎯 笔刷光标位置更新 [按下]');
          print('➡️ 原始位置: ${event.position}');
          print('📱 设备像素比: ${MediaQuery.of(context).devicePixelRatio}');
          print('✨ 本地位置: $_cursorPosition');
        });
      },
      onPointerMove: (event) {
        // 减少日志频率，只记录显著移动
        if (event.delta.distance > 5) {
          setState(() {
            _cursorPosition = event.localPosition;
            _isPointerInside = true;
            print('🎯 笔刷光标位置更新 [移动]');
            print('↔️ 移动距离: ${event.delta.distance}');
            print('✨ 本地位置: $_cursorPosition');
          });
        }
      },
      onPointerUp: (event) {
        setState(() {
          _isPointerInside = false;
          print('笔刷光标: 抬起 - 重置指针状态');
        });
      },
      child: Stack(
        children: [
          if (_isPointerInside)
            Positioned(
              left: _cursorPosition.dx - widget.brushSize / 2,
              top: _cursorPosition.dy - widget.brushSize / 2,
              child: Container(
                width: widget.brushSize,
                height: widget.brushSize,
                decoration: BoxDecoration(
                  color: widget.isErasing
                      ? Colors.red.withOpacity(0.3)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isErasing ? Colors.red : Colors.blue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
