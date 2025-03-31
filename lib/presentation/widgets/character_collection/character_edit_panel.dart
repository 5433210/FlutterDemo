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

class CharacterEditPanel extends ConsumerStatefulWidget {
  const CharacterEditPanel({Key? key}) : super(key: key);

  @override
  ConsumerState<CharacterEditPanel> createState() => _CharacterEditPanelState();
}

class _CharacterEditPanelState extends ConsumerState<CharacterEditPanel> {
  final _transformationController = TransformationController();
  final _isEditingController = ValueNotifier<bool>(false);
  ui.Image? _editedImage;
  ui.Image? _originalImage;

  @override
  Widget build(BuildContext context) {
    final selectedRegion = ref.watch(selectedRegionProvider);
    final editState = ref.watch(editPanelProvider);
    final imageState = ref.watch(workImageProvider);

    // 如果没有选中区域，显示空状态
    if (selectedRegion == null || imageState.imageData == null) {
      return const EmptyState(
        icon: Icons.crop_free,
        actionLabel: '未选择字符区域',
        message: '请使用左侧工具栏的框选工具选择一个字符区域，或从下方"作品集字结果"选择一个已保存的字符',
      );
    }

    // 转换图像数据
    if (_originalImage == null) {
      _convertImage(imageState.imageData!);
      return const Center(child: CircularProgressIndicator());
    }

    // 创建擦除工具配置
    final toolConfig = EraseToolConfig(
      initialBrushSize: 20.0,
      initialMode: EraseMode.normal,
      imageSize: Size(
        imageState.imageWidth,
        imageState.imageHeight,
      ),
      enableOptimizations: true,
    );

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
                IconButton(
                  icon: Icon(
                    Icons.invert_colors,
                    color: editState.isInverted ? Colors.blue : Colors.grey,
                  ),
                  tooltip: '反色处理',
                  onPressed: () =>
                      ref.read(editPanelProvider.notifier).toggleInvert(),
                ),

                // 提示文本
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

          // 画布区域
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

          // 字符输入
          CharacterInput(
            value: selectedRegion.character,
            onChanged: (value) {
              ref.read(selectedRegionProvider.notifier).updateCharacter(value);
            },
          ),

          const SizedBox(height: 16),

          // 操作按钮
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
                  try {
                    // 保存字符区域
                    await ref
                        .read(characterCollectionProvider.notifier)
                        .saveCurrentRegion();

                    // 如果有编辑后的图像，更新到存储
                    if (_editedImage != null) {
                      final bytes =
                          await ImageConverter.imageToBytes(_editedImage!);
                      if (bytes != null) {
                        // TODO: 实现更新编辑后图像的逻辑
                        // await ref.read(workImageProvider.notifier).updateImage(bytes);
                      }
                    }
                  } finally {
                    // 清理状态
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
    _editedImage?.dispose();
    _originalImage?.dispose();
    super.dispose();
  }

  Future<void> _convertImage(Uint8List imageData) async {
    _originalImage?.dispose();
    _originalImage = await ImageConverter.bytesToImage(imageData);
    if (mounted) {
      setState(() {});
    }
  }

  void _handleEditComplete(ui.Image image) {
    setState(() {
      _editedImage?.dispose();
      _editedImage = image;
      _isEditingController.value = false;
    });
  }
}
