import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/edit_panel_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../common/empty_state.dart';
import 'action_buttons.dart';
import 'character_input.dart';
import 'erase_tool/controllers/erase_tool_controller.dart';
import 'preview_canvas.dart';

class CharacterEditPanel extends ConsumerStatefulWidget {
  const CharacterEditPanel({Key? key}) : super(key: key);

  @override
  ConsumerState<CharacterEditPanel> createState() => _CharacterEditPanelState();
}

class _CharacterEditPanelState extends ConsumerState<CharacterEditPanel> {
  // 添加静态实例计数器方便调试
  static int _panelInstanceCount = 0;
  bool _isErasing = false;
  double _brushSize = 20.0;
  List<Offset> _erasePoints = [];
  EraseToolController? _eraseController;

  bool _isUpdatingController = false;

  // 创建一个key来保持EraseToolWidget的状态
  final _eraseToolKey = GlobalKey();
  final int _panelInstanceId = _panelInstanceCount++;

  @override
  Widget build(BuildContext context) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final editState = ref.watch(editPanelProvider);
    final imageState = ref.watch(workImageProvider);

    // 如果没有选中区域，显示空状态
    if (selectedRegion == null) {
      return const EmptyState(
        icon: Icons.crop_free,
        actionLabel: '未选择字符区域',
        message: '请使用左侧工具栏的框选工具选择一个字符区域，或从下方"作品集字结果"选择一个已保存的字符',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 工具栏
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                // 反色按钮
                Tooltip(
                  message: '反色处理',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedPadding(
                      padding: EdgeInsets.all(editState.isInverted ? 6.0 : 8.0),
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedScale(
                        scale: editState.isInverted ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.invert_colors,
                          color:
                              editState.isInverted ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    onTap: () =>
                        ref.read(editPanelProvider.notifier).toggleInvert(),
                  ),
                ),
                const SizedBox(width: 8),
                // 轮廓按钮
                Tooltip(
                  message: '显示轮廓',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedPadding(
                      padding:
                          EdgeInsets.all(editState.showOutline ? 6.0 : 8.0),
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedScale(
                        scale: editState.showOutline ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.border_clear,
                          color:
                              editState.showOutline ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ),
                    onTap: () =>
                        ref.read(editPanelProvider.notifier).toggleOutline(),
                  ),
                ),
                const SizedBox(width: 8),
                // 擦除按钮
                Tooltip(
                  message: '擦除工具',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _toggleErasing,
                    child: AnimatedPadding(
                      padding: EdgeInsets.all(_isErasing ? 6.0 : 8.0),
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedScale(
                        scale: _isErasing ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.auto_fix_high,
                          color: _isErasing ? Colors.blue : Colors.grey,
                          size: 20,
                        ),
                      ),
                    ), // 使用专用方法控制状态变化
                  ),
                ),

                if (_isErasing) ...[
                  const SizedBox(width: 8),
                  // 擦除笔刷大小滑块
                  Expanded(
                    child: Slider(
                      value: _brushSize,
                      min: 5,
                      max: 50,
                      divisions: 9,
                      label: '${_brushSize.round()}',
                      onChanged: (value) => setState(() => _brushSize = value),
                    ),
                  ),

                  // 撤销按钮
                  IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: _eraseController?.canUndo == true
                        ? () => _safelyOperateController((c) => c.undo())
                        : null,
                    tooltip: '撤销',
                  ),

                  // 重做按钮
                  IconButton(
                    icon: const Icon(Icons.redo),
                    onPressed: _eraseController?.canRedo == true
                        ? () => _safelyOperateController((c) => c.redo())
                        : null,
                    tooltip: '重做',
                  ),

                  // 清除所有按钮
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _safelyOperateController((c) => c.clearAll()),
                    tooltip: '清除所有',
                  ),
                ] else
                  const Spacer(),

                // 区域信息（只读）
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withOpacity(0.7),
                          ) ??
                      const TextStyle(),
                  child: Text(
                    '${selectedRegion.rect.width.toInt()} × ${selectedRegion.rect.height.toInt()} px',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 预览画布 - 使用RepaintBoundary和适当的key避免不必要的重建
          Expanded(
            child: RepaintBoundary(
              child: PreviewCanvas(
                key: ValueKey(_isErasing
                    ? 'erasing_${selectedRegion.id}_${_brushSize.round()}'
                    : 'preview_${selectedRegion.id}_${editState.isInverted}_${editState.showOutline}'),
                regionId: selectedRegion.id,
                pageImageData: imageState.imageData,
                regionRect: selectedRegion.rect,
                isInverted: editState.isInverted,
                showOutline: editState.showOutline,
                zoomLevel: editState.zoomLevel,
                isErasing: _isErasing,
                brushSize: _brushSize,
                onErasePointsChanged: (points) {
                  // 避免频繁更新状态
                  if (points.length != _erasePoints.length) {
                    _erasePoints = points;
                  }
                },
                onEraseControllerReady: (controller) {
                  if (_eraseController != controller &&
                      !_isUpdatingController) {
                    _isUpdatingController = true;
                    // 使用延迟避免在构建过程中setState
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) {
                        setState(() {
                          _eraseController = controller;
                          _isUpdatingController = false;
                        });
                      }
                    });
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 字符输入
          CharacterInput(
            value: selectedRegion.character,
            onChanged: (value) {
              // 只更新字符，不刷新预览
              ref.read(selectedRegionProvider.notifier).updateCharacter(value);
            },
          ),

          const SizedBox(height: 16),

          // 操作按钮
          ActionButtons(
            onSave: () async {
              // 保存时包含擦除点
              final region = selectedRegion.copyWith(
                erasePoints: _erasePoints,
              );
              ref.read(selectedRegionProvider.notifier).setRegion(region);
              await ref
                  .read(characterCollectionProvider.notifier)
                  .saveCurrentRegion();
            },
            onCancel: () {
              ref.read(selectedRegionProvider.notifier).clearRegion();
              setState(() {
                _erasePoints = [];
                _isErasing = false;
              });
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print('⭐ CharacterEditPanel[$_panelInstanceId] disposed');
    _eraseController = null;
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    print('⭐ CharacterEditPanel[$_panelInstanceId] created');
  }

  // 添加一个安全的操作控制器的方法
  void _safelyOperateController(Function(EraseToolController) operation) {
    if (_eraseController != null) {
      try {
        operation(_eraseController!);
      } catch (e) {
        print('Error operating on erase controller: $e');
      }
    }
  }

  // 添加一个处理擦除工具选择的专用方法
  void _toggleErasing() {
    if (_isUpdatingController) return;

    print('🔍 切换擦除模式: ${!_isErasing}');

    // 使用一个延迟机制避免频繁状态更新
    setState(() {
      _isErasing = !_isErasing;
    });

    // 如果启用擦除，预先创建控制器
    if (_isErasing && _eraseController == null) {
      _isUpdatingController = true;

      // 延迟消除切换后的卡顿感
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _isUpdatingController = false;
          });
        }
      });
    }
  }
}
