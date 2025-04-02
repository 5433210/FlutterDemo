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
  bool _canUndo = false;
  bool _canRedo = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: CharacterEditCanvas(
            key: _canvasKey,
            image: widget.image,
            onEraseStart: _handleEraseStart,
            onEraseUpdate: _handleEraseUpdate,
            onEraseEnd: _handleEraseEnd,
            brushColor: _eraseController.brushColor,
            brushSize: _currentBrushSize,
            invertMode: _eraseController.invertMode,
            imageInvertMode: _eraseController.imageInvertMode,
            showOutline: _eraseController.outlineMode,
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  @override
  void dispose() {
    _eraseController.removeListener(_handleEraseControllerChange);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _eraseController.addListener(_handleEraseControllerChange);
    _updateUndoRedoState();
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
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
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.brush),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(
                    Icons.invert_colors,
                    size: 14,
                    color: _eraseController.invertMode ? Colors.blue : null,
                  ),
                ),
              ],
            ),
            onPressed: _toggleInvert,
            tooltip: '笔刷反转',
          ),
          IconButton(
            icon: Icon(
              Icons.invert_colors,
              color: _eraseController.imageInvertMode ? Colors.blue : null,
            ),
            onPressed: _toggleImageInvert,
            tooltip: '图像反转',
          ),
          IconButton(
            icon: Icon(
              Icons.border_style,
              color: _eraseController.outlineMode ? Colors.blue : null,
            ),
            onPressed: _toggleOutline,
            tooltip: '描边',
          ),
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
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _canUndo ? _undo : null,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _canRedo ? _redo : null,
            tooltip: '重做',
          ),
        ],
      ),
    );
  }

  void _finishEditing() {
    final result = _eraseController.getFinalResult();
    widget.onEditComplete?.call(result);
    Navigator.of(context).pop(result);
  }

  void _handleEraseControllerChange() {
    setState(() {
      _updateUndoRedoState();
      if (_canvasKey.currentState != null) {
        final paths = _eraseController.getPaths();
        print('准备更新画布路径 - 路径数量: ${paths.length}');
        _canvasKey.currentState!.updatePaths(paths);
      }
    });
  }

  void _handleEraseEnd() {
    print('结束擦除 - 描边模式: ${_eraseController.outlineMode}');
    _eraseController.endErase();

    // 确保在每次擦除结束后都强制更新轮廓
    if (_eraseController.outlineMode && _canvasKey.currentState != null) {
      print('强制更新画布和轮廓');
      final paths = _eraseController.getPaths();
      _canvasKey.currentState!.updatePaths(paths);
    }
  }

  void _handleEraseStart(Offset position) {
    _eraseController.brushSize = _currentBrushSize;
    _eraseController.startErase(position);
  }

  void _handleEraseUpdate(Offset position, Offset delta) {
    _eraseController.updateErase(position);
  }

  void _redo() {
    if (_canRedo) {
      _eraseController.redo();
      final paths = _eraseController.getPaths();
      if (_canvasKey.currentState != null) {
        _canvasKey.currentState!.updatePaths(paths);
      }
    }
  }

  void _toggleImageInvert() {
    setState(() {
      _eraseController.imageInvertMode = !_eraseController.imageInvertMode;
    });
  }

  void _toggleInvert() {
    setState(() {
      _eraseController.invertMode = !_eraseController.invertMode;
    });
  }

  void _toggleOutline() {
    setState(() {
      print('切换描边模式');
      _eraseController.outlineMode = !_eraseController.outlineMode;
      if (_canvasKey.currentState != null) {
        final paths = _eraseController.getPaths();
        print('更新画布路径 - 路径数量: ${paths.length}');
        _canvasKey.currentState!.updatePaths(paths);
      }
    });
  }

  void _undo() {
    if (_canUndo) {
      _eraseController.undo();
      final paths = _eraseController.getPaths();
      if (_canvasKey.currentState != null) {
        _canvasKey.currentState!.updatePaths(paths);
      }
    }
  }

  void _updateUndoRedoState() {
    setState(() {
      _canUndo = _eraseController.canUndo;
      _canRedo = _eraseController.canRedo;
    });
  }
}
