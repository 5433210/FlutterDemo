import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../tools/erase/erase_controller.dart';
import 'character_edit_canvas.dart';

/// 字符编辑面板，包含工具栏和编辑画布
class CharacterEditPanel extends StatefulWidget {
  final ui.Image image;
  final Function(Map<String, dynamic>)? onEditComplete;

  const CharacterEditPanel({
    Key? key,
    required this.image,
    this.onEditComplete,
  }) : super(key: key);

  @override
  State<CharacterEditPanel> createState() => _CharacterEditPanelState();
}

class _CharacterEditPanelState extends State<CharacterEditPanel> {
  final EraseController _eraseController = EraseController();
  final GlobalKey<CharacterEditCanvasState> _canvasKey = GlobalKey();
  double _currentBrushSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 工具栏
        _buildToolbar(),

        // 编辑画布区域
        Expanded(
          child: CharacterEditCanvas(
            key: _canvasKey,
            image: widget.image,
            onEraseStart: _handleEraseStart,
            onEraseUpdate: _handleEraseUpdate,
            onEraseEnd: _handleEraseEnd,
            brushColor:
                _eraseController.brushColor, // 使用EraseController中的brushColor
            brushSize: _currentBrushSize, // 传递当前笔刷大小
          ),
        ),

        // 底部操作区
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 取消按钮
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),

          // 完成按钮
          ElevatedButton(
            onPressed: _finishEditing,
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          // 反转按钮
          IconButton(
            icon: const Icon(Icons.invert_colors),
            onPressed: _toggleInvert,
            tooltip: '反转',
          ),

          // 描边按钮
          IconButton(
            icon: const Icon(Icons.border_style),
            onPressed: _toggleOutline,
            tooltip: '描边',
          ),

          // 画笔大小滑块
          Expanded(
            child: Row(
              children: [
                const Text('笔刷: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: _currentBrushSize,
                    min: 1.0,
                    max: 50.0,
                    onChanged: (value) {
                      setState(() {
                        _currentBrushSize = value;
                        _eraseController.brushSize = value;
                      });
                    },
                    label: '${_currentBrushSize.toInt()}',
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${_currentBrushSize.toInt()}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // 撤销按钮
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _eraseController.canUndo ? _undo : null,
            tooltip: '撤销',
          ),

          // 重做按钮
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _eraseController.canRedo ? _redo : null,
            tooltip: '重做',
          ),
        ],
      ),
    );
  }

  void _finishEditing() {
    // 获取最终的擦除结果
    final result = _eraseController.getFinalResult();

    // 调用回调
    widget.onEditComplete?.call(result);

    // 返回结果
    Navigator.of(context).pop(result);
  }

  void _handleEraseEnd() {
    _eraseController.endErase();
  }

  // 处理擦除开始事件，传递当前笔刷大小
  void _handleEraseStart(Offset position) {
    _eraseController.brushSize = _currentBrushSize; // 确保使用当前设置的笔刷大小
    _eraseController.startErase(position);
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    _eraseController.updateErase(position);
  }

  void _redo() {
    _eraseController.redo();
    setState(() {});
  }

  void _toggleInvert() {
    print('切换反转模式');
    setState(() {
      _eraseController.invertMode = !_eraseController.invertMode;
      print(
          '当前反转模式: ${_eraseController.invertMode}, 画笔颜色: ${_eraseController.brushColor}');
    });
  }

  void _toggleOutline() {
    setState(() {
      _eraseController.outlineMode = !_eraseController.outlineMode;
    });
  }

  void _undo() {
    _eraseController.undo();
    setState(() {});
  }
}
