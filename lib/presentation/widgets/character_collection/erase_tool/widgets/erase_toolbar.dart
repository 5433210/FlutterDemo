import 'package:flutter/material.dart';

import '../controllers/erase_tool_controller.dart';
import '../models/erase_mode.dart';
import 'brush_size_slider.dart';

/// 擦除工具栏
/// 提供撤销/重做、笔刷大小调节等控制
class EraseToolbar extends StatelessWidget {
  /// 控制器
  final EraseToolController controller;

  /// 操作回调
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onClearAll;
  final ValueChanged<double>? onBrushSizeChanged;

  /// 构造函数
  const EraseToolbar({
    Key? key,
    required this.controller,
    this.onUndo,
    this.onRedo,
    this.onClearAll,
    this.onBrushSizeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 撤销按钮
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: controller.canUndo ? onUndo : null,
            tooltip: '撤销',
          ),

          // 重做按钮
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: controller.canRedo ? onRedo : null,
            tooltip: '重做',
          ),

          const SizedBox(width: 16),

          // 笔刷大小调节
          Expanded(
            child: BrushSizeSlider(
              value: controller.brushSize,
              min: 3.0,
              max: 30.0,
              onChanged: onBrushSizeChanged,
            ),
          ),

          const SizedBox(width: 16),

          // 清除所有按钮
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onClearAll,
            tooltip: '清除所有',
          ),

          // 模式选择
          PopupMenuButton<EraseMode>(
            icon: const Icon(Icons.more_vert),
            tooltip: '擦除模式',
            onSelected: (EraseMode mode) {
              controller.setMode(mode);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<EraseMode>>[
              const PopupMenuItem<EraseMode>(
                value: EraseMode.normal,
                child: Text('普通模式'),
              ),
              const PopupMenuItem<EraseMode>(
                value: EraseMode.precise,
                child: Text('精确模式'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
