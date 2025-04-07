import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/character/character_collection_provider.dart';
import '../../providers/character/edit_panel_provider.dart';
import '../../providers/character/selected_region_provider.dart';
import '../../providers/character/work_image_provider.dart';
import '../common/empty_state.dart';
import 'character_input.dart';
import 'erase_tool/controllers/erase_tool_provider.dart';
import 'erase_tool/models/erase_mode.dart';
import 'erase_tool/utils/image_converter.dart';
import 'erase_tool/widgets/erase_tool_widget.dart';
import '../../../infrastructure/logging/logger.dart';

class CharacterEditPanel extends ConsumerStatefulWidget {
  const CharacterEditPanel({Key? key}) : super(key: key);

  @override
  ConsumerState<CharacterEditPanel> createState() => _CharacterEditPanelState();
}

class _CharacterEditPanelState extends ConsumerState<CharacterEditPanel> {
  final _transformationController = TransformationController();
  final _isEditingController = ValueNotifier<bool>(false);
  ui.Image? _originalImage;
  ui.Image? _editedImage;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final editState = ref.watch(editPanelProvider);
    final imageState = ref.watch(workImageProvider);

    if (selectedRegion == null) {
      return const EmptyState(
        icon: Icons.crop_free,
        actionLabel: '未选择字符区域',
        message: '请使用左侧工具栏的框选工具选择一个字符区域，或从下方"作品集字结果"选择一个已保存的字符',
      );
    }

    if (_originalImage == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.invert_colors,
                    color: editState.isInverted ? Colors.blue : Colors.grey,
                  ),
                  tooltip: '反色处理',
                  onPressed: () =>
                      ref.read(editPanelProvider.notifier).toggleInvert(),
                ),
                const Expanded(
                  child: Text(
                    '使用鼠标进行擦除，按住Alt键可以移动和缩放图像',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: EraseToolWidget(
                  image: _originalImage!,
                  transformationController: _transformationController,
                  initialBrushSize: 20.0,
                  initialMode: EraseMode.normal,
                  onEraseComplete: _handleEditComplete,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          CharacterInput(
            key: ValueKey('char_input_${selectedRegion.id}'),
            value: selectedRegion.character,
            onChanged: (value) {
              AppLogger.debug('CharacterInput onChanged',
                  data: {'value': value, 'regionId': selectedRegion.id});
              ref
                  .read(characterCollectionProvider.notifier)
                  .updateSelectedRegion(
                      selectedRegion.copyWith(character: value));
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(selectedRegionProvider.notifier).clearRegion();
                  _editedImage?.dispose();
                  _editedImage = null;
                  _isEditingController.value = false;
                },
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final currentRegionIdFromProvider =
                      ref.read(characterCollectionProvider).currentId;
                  if (currentRegionIdFromProvider == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('错误：没有选中的区域可供保存')),
                    );
                    return;
                  }
                  try {
                    await ref
                        .read(characterCollectionProvider.notifier)
                        .saveCurrentRegion();
                  } finally {
                    _editedImage?.dispose();
                    _editedImage = null;
                    _isEditingController.value = false;
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _isEditingController.dispose();
    _originalImage?.dispose();
    _editedImage?.dispose();
    super.dispose();
  }

  void _handleEditComplete(ui.Image image) {
    setState(() {
      _editedImage?.dispose();
      _editedImage = image;
      _isEditingController.value = false;
    });
  }
}
