import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../theme/app_sizes.dart';
import '../../../../pages/works/components/thumbnail_strip.dart';
import '../../../../viewmodels/states/work_import_state.dart';
import '../../../../viewmodels/work_import_view_model.dart';
import '../../../../widgets/common/base_card.dart';
import '../../../../widgets/common/base_image_preview.dart';
import '../../../../widgets/common/confirm_dialog.dart';

class WorkImportPreview extends StatelessWidget {
  final WorkImportState state;
  final WorkImportViewModel viewModel;
  final bool isProcessing;
  final VoidCallback? onAddImages;

  const WorkImportPreview({
    super.key,
    required this.state,
    required this.viewModel,
    this.isProcessing = false,
    this.onAddImages,
  });

  @override
  Widget build(BuildContext context) {
    if (state.images.isEmpty) {
      return BaseCard(
        child: InkWell(
          onTap: onAddImages,
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 48),
                  SizedBox(height: AppSizes.s),
                  Text('点击或拖拽图片以添加'),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.all(AppSizes.s),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                // 追加按钮
                IconButton(
                  onPressed: isProcessing ? null : onAddImages,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  tooltip: '追加图片',
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: AppSizes.s),
                Text(
                  '共 ${state.images.length} 张图片',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Image preview
          Expanded(
            child: BaseImagePreview(
              imagePaths: state.images.map((file) => file.path).toList(),
              initialIndex: state.selectedImageIndex,
              onIndexChanged: viewModel.selectImage,
              showThumbnails: false,
            ),
          ),

          // Thumbnail strip
          SizedBox(
            height: 100,
            child: ThumbnailStrip<File>(
              images: state.images,
              selectedIndex: state.selectedImageIndex,
              onTap: viewModel.selectImage,
              isEditable: !isProcessing,
              pathResolver: (file) => file.path,
              keyResolver: (file) => file.path,
              onReorder: viewModel.reorderImages,
              onRemove: isProcessing
                  ? null
                  : (index) => _handleRemoveImage(context, index),
            ),
          ),
        ],
      ),
    );
  }

  void _handleRemoveImage(BuildContext context, int index) {
    if (state.images.length > 1) {
      viewModel.removeImage(index);
    } else {
      showDialog(
        context: context,
        builder: (context) => ConfirmDialog(
          title: '确认删除',
          content: '这是最后一张图片，删除后将退出导入。确定要删除吗？',
          onConfirm: () {
            viewModel.removeImage(index);
            Navigator.of(context).pop(true);
          },
        ),
      );
    }
  }
}
