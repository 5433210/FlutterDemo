import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/edit_panel_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../common/empty_state.dart';
import 'action_buttons.dart';
import 'character_input.dart';
import 'edit_toolbar.dart';
import 'preview_canvas.dart';
import 'region_info_bar.dart';
import 'zoom_control_bar.dart';

class CharacterEditPanel extends ConsumerWidget {
  const CharacterEditPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final editState = ref.watch(editPanelProvider);

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
          // 编辑工具栏
          EditToolbar(
            isInverted: editState.isInverted,
            showOutline: editState.showOutline,
            isErasing: editState.isErasing,
            canUndo: true, // 这里应该从擦除管理器获取状态
            canRedo: false, // 这里应该从擦除管理器获取状态
            onInvertToggled: (value) =>
                ref.read(editPanelProvider.notifier).toggleInvert(),
            onOutlineToggled: (value) =>
                ref.read(editPanelProvider.notifier).toggleOutline(),
            onEraseToggled: (value) =>
                ref.read(editPanelProvider.notifier).toggleErase(),
            onUndo: () => {}, // 这里应该调用擦除管理器的撤销方法
            onRedo: () => {}, // 这里应该调用擦除管理器的重做方法
          ),

          const SizedBox(height: 16),

          // 预览画布
          Expanded(
            child: PreviewCanvas(
              regionId: selectedRegion.id,
              isInverted: editState.isInverted,
              showOutline: editState.showOutline,
              zoomLevel: editState.zoomLevel,
              isErasing: editState.isErasing,
              brushSize: editState.brushSize,
              onErasePointsChanged: (points) => ref
                  .read(selectedRegionProvider.notifier)
                  .addErasePoints(points),
            ),
          ),

          const SizedBox(height: 8),

          // 缩放控制栏
          ZoomControlBar(
            zoomLevel: editState.zoomLevel,
            onZoomIn: () =>
                ref.read(editPanelProvider.notifier).incrementZoom(),
            onZoomOut: () =>
                ref.read(editPanelProvider.notifier).decrementZoom(),
            onReset: () => ref.read(editPanelProvider.notifier).resetZoom(),
          ),

          const SizedBox(height: 16),

          // 区域信息栏
          RegionInfoBar(
            rect: selectedRegion.rect,
            rotation: selectedRegion.rotation,
            onSizeChanged: (size) {
              // 更新区域大小
              final center = selectedRegion.rect.center;
              final newRect = Rect.fromCenter(
                center: center,
                width: size.width,
                height: size.height,
              );
              ref.read(selectedRegionProvider.notifier).updateRect(newRect);
            },
            onRotationChanged: (angle) =>
                ref.read(selectedRegionProvider.notifier).updateAngle(angle),
          ),

          const SizedBox(height: 16),

          // 字符输入
          CharacterInput(
            value: selectedRegion.character,
            onChanged: (value) => ref
                .read(selectedRegionProvider.notifier)
                .updateCharacter(value),
          ),

          const SizedBox(height: 16),

          // 操作按钮
          ActionButtons(
            onSave: () => ref
                .read(characterCollectionProvider.notifier)
                .saveCurrentRegion(),
            onCancel: () =>
                ref.read(selectedRegionProvider.notifier).clearRegion(),
          ),
        ],
      ),
    );
  }
}
