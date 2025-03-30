import 'package:flutter/material.dart';

import '../controllers/erase_gesture_mixin.dart';
import '../controllers/erase_tool_controller_impl.dart';
import '../controllers/erase_tool_provider.dart';
import '../widgets/erase_toolbar.dart';

/// 擦除工具使用示例
class EraseToolExample extends StatefulWidget {
  const EraseToolExample({super.key});

  @override
  State<EraseToolExample> createState() => _EraseToolExampleState();
}

class _EraseToolExampleState extends State<EraseToolExample>
    with EraseGestureMixin {
  late final EraseToolControllerImpl _controller;

  @override
  EraseToolControllerImpl get controller => _controller;

  @override
  Widget build(BuildContext context) {
    return EraseToolProvider(
      controller: _controller,
      child: Column(
        children: [
          // 添加顶部工具栏
          EraseToolbar(
            controller: _controller,
            onUndo: handleUndo,
            onRedo: handleRedo,
            onClearAll: handleClearAll,
            onBrushSizeChanged: handleBrushSizeChanged,
          ),
          Expanded(
            child: GestureDetector(
              onPanStart: handlePanStart,
              onPanUpdate: handlePanUpdate,
              onPanEnd: handlePanEnd,
              onPanCancel: handlePanCancel,
              child: Container(
                color: Colors.grey[200],
                // 这里会添加实际的擦除界面
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = EraseToolProvider.createController(
      initialBrushSize: 10.0,
    );
  }
}
