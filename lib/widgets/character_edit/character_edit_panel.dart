import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/character/processing_options.dart';
import '../../presentation/providers/character/erase_providers.dart';
import 'character_edit_canvas.dart';

/// 字符编辑面板组件
class CharacterEditPanel extends ConsumerStatefulWidget {
  final ui.Image image;
  final Function(Map<String, dynamic>) onEditComplete;

  const CharacterEditPanel({
    Key? key,
    required this.image,
    required this.onEditComplete,
  }) : super(key: key);

  @override
  ConsumerState<CharacterEditPanel> createState() => _CharacterEditPanelState();
}

class _CharacterEditPanelState extends ConsumerState<CharacterEditPanel> {
  final GlobalKey<CharacterEditCanvasState> _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    // 监听状态变化
    final eraseState = ref.watch(eraseStateProvider);
    final pathRenderData = ref.watch(pathRenderDataProvider);

    // 在状态变化时打印调试信息
    if (kDebugMode) {
      print('编辑面板构建 - 轮廓显示: ${eraseState.showContour}');
    }

    return Column(
      children: [
        Expanded(
          child: CharacterEditCanvas(
            key: _canvasKey,
            image: widget.image,
            showOutline: eraseState.showContour, // 传递轮廓显示状态
            invertMode: eraseState.isReversed,
            imageInvertMode: eraseState.imageInvertMode,
            brushSize: eraseState.brushSize,
            brushColor: eraseState.brushColor,
            onEraseStart: _handleEraseStart,
            onEraseUpdate: _handleEraseUpdate,
            onEraseEnd: _handleEraseEnd,
          ),
        ),
        _buildToolbar(),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    // 确保初始状态正确
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eraseStateProvider.notifier).clear();
    });
  }

  Widget _buildToolbar() {
    final eraseState = ref.watch(eraseStateProvider);
    final brushColor = eraseState.brushColor;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // 撤销按钮
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: eraseState.canUndo
                    ? () => ref.read(eraseStateProvider.notifier).undo()
                    : null,
              ),
              // 重做按钮
              IconButton(
                icon: const Icon(Icons.redo),
                onPressed: eraseState.canRedo
                    ? () => ref.read(eraseStateProvider.notifier).redo()
                    : null,
              ),
              // 橡皮擦大小滑块
              Expanded(
                child: Slider(
                  value: eraseState.brushSize,
                  min: 1.0,
                  max: 50.0,
                  onChanged: (value) {
                    ref.read(eraseStateProvider.notifier).setBrushSize(value);
                  },
                ),
              ),
              // 颜色反转按钮
              IconButton(
                icon: const Icon(Icons.invert_colors),
                onPressed: () {
                  ref.read(eraseStateProvider.notifier).toggleReverse();
                },
                color: eraseState.isReversed
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              // 图像反转按钮
              IconButton(
                icon: const Icon(Icons.flip),
                onPressed: () {
                  ref.read(eraseStateProvider.notifier).toggleImageInvert();
                },
                color: eraseState.imageInvertMode
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              // 轮廓显示按钮
              IconButton(
                icon: const Icon(Icons.border_all),
                onPressed: () {
                  ref.read(eraseStateProvider.notifier).toggleContour();
                },
                color: eraseState.showContour
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              // 平移模式按钮
              IconButton(
                icon: const Icon(Icons.pan_tool),
                onPressed: () {
                  ref.read(eraseStateProvider.notifier).togglePanMode();
                },
                color: eraseState.isPanMode
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              // 确认按钮
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _handleComplete,
              ),
            ],
          ),
          // Add a status bar in debug mode
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('笔刷颜色: ', style: TextStyle(fontSize: 12)),
                  Container(
                    width: 12,
                    height: 12,
                    color: brushColor,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  Text('${brushColor == Colors.black ? "黑色" : "白色"} | ',
                      style: const TextStyle(fontSize: 12)),
                  Text('反转模式: ${eraseState.isReversed ? "开" : "关"} | ',
                      style: const TextStyle(fontSize: 12)),
                  Text('图像反转: ${eraseState.imageInvertMode ? "开" : "关"}',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _handleComplete() {
    // 获取路径数据和处理选项
    final pathRenderData = ref.read(pathRenderDataProvider);
    final eraseState = ref.read(eraseStateProvider);

    final result = {
      'paths': pathRenderData.completedPaths ?? [],
      'processingOptions': ProcessingOptions(
        inverted: eraseState.isReversed,
        threshold: 128.0,
        noiseReduction: 0.5,
        showContour: eraseState.showContour,
      ),
    };

    widget.onEditComplete(result);
  }

  // 处理擦除结束事件
  void _handleEraseEnd() {
    if (!ref.read(eraseStateProvider).isPanMode) {
      ref.read(eraseStateProvider.notifier).completePath();
    }
  }

  // 处理擦除开始事件
  void _handleEraseStart(Offset position) {
    if (!ref.read(eraseStateProvider).isPanMode) {
      ref.read(eraseStateProvider.notifier).startPath(position);
    }
  }

  // 处理擦除更新事件
  void _handleEraseUpdate(Offset position, Offset delta) {
    if (!ref.read(eraseStateProvider).isPanMode) {
      ref.read(eraseStateProvider.notifier).updatePath(position);
    }
  }
}
