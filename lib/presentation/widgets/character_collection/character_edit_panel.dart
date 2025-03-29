import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/edit_panel_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../common/empty_state.dart';
import 'action_buttons.dart';
import 'character_input.dart';
import 'preview_canvas.dart';

class CharacterEditPanel extends ConsumerStatefulWidget {
  const CharacterEditPanel({Key? key}) : super(key: key);

  @override
  ConsumerState<CharacterEditPanel> createState() => _CharacterEditPanelState();
}

class _CharacterEditPanelState extends ConsumerState<CharacterEditPanel> {
  bool _isErasing = false;
  double _brushSize = 20.0;
  List<Offset> _erasePoints = [];

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
                    ),
                    onTap: () => setState(() => _isErasing = !_isErasing),
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

          // 预览画布
          Expanded(
            child: PreviewCanvas(
              key: ValueKey('preview_${selectedRegion.id}'),
              regionId: selectedRegion.id,
              pageImageData: imageState.imageData,
              regionRect: selectedRegion.rect,
              isInverted: editState.isInverted,
              showOutline: editState.showOutline,
              zoomLevel: editState.zoomLevel,
              isErasing: _isErasing,
              brushSize: _brushSize,
              onErasePointsChanged: (points) {
                _erasePoints = points;
              },
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
}
