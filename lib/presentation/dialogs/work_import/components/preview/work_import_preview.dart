import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/work/work_image.dart';
import '../../../../../infrastructure/logging/logger.dart';
import '../../../../providers/work_import_provider.dart';
import '../../../../widgets/works/enhanced_work_preview.dart';
import '../../../common/dialog_button_group.dart';
import '../../../common/dialogs.dart';

/// Displays a preview of work images during import with editing capabilities
class WorkImportPreview extends ConsumerStatefulWidget {
  final bool showBottomButtons;

  const WorkImportPreview({
    super.key,
    this.showBottomButtons = true,
  });

  @override
  ConsumerState<WorkImportPreview> createState() => _WorkImportPreviewState();
}

class _WorkImportPreviewState extends ConsumerState<WorkImportPreview> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workImportProvider);
    final theme = Theme.of(context);

    AppLogger.debug(
        'Building WorkImportPreview with ${state.images.length} images');

    final images = state.images
        .map((file) => WorkImage(
              id: file.path,
              path: file.path,
              workId: '', // Will be set during import
              originalPath: file.path,
              thumbnailPath: file.path,
              index: state.images.indexOf(file),
              width: 0, // Will be set during import
              height: 0, // Will be set during import
              format: 'image',
              size: 0, // Will be set during import
              createTime: DateTime.now(),
              updateTime: DateTime.now(),
            ))
        .toList();

    // 创建一个函数来处理"添加图片"按钮的点击
    VoidCallback? handleAdd =
        state.isProcessing ? null : () => _handleAddImages();

    // 创建一个函数来处理"删除图片"按钮的点击
    VoidCallback? handleDelete = (images.isEmpty || state.isProcessing)
        ? null
        : () => _handleDeleteSelected();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use constraints to adapt layout
        final isSmallWidth = constraints.maxWidth < 500;
        final buttonHeight = 60.0; // Approximate height for buttons
        final previewHeight = constraints.maxHeight - buttonHeight;

        return Column(
          children: [
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0, // Remove card elevation for cleaner UI
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: EnhancedWorkPreview(
                  images: images,
                  selectedIndex: state.selectedImageIndex,
                  isEditing: !state.isProcessing, // 处理中禁用编辑
                  showToolbar: true,
                  toolbarActions: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: FilledButton.tonalIcon(
                        onPressed: handleAdd, // 处理中禁用
                        icon: const Icon(Icons.add_photo_alternate),
                        label: isSmallWidth
                            ? const Text('添加')
                            : const Text('添加图片'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: OutlinedButton.icon(
                        onPressed: handleDelete, // 处理中禁用
                        icon: const Icon(
                          Icons.delete_outline,
                        ),
                        label: isSmallWidth
                            ? const Text('删除')
                            : const Text('删除图片'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: theme.colorScheme.error.withOpacity(
                              images.isEmpty || state.isProcessing ? 0.38 : 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  onIndexChanged:
                      state.isProcessing ? null : _handleIndexChanged,
                  onImagesReordered:
                      state.isProcessing ? null : _handleImagesReordered,
                ),
              ),
            ),
            // Only show the bottom buttons if requested
            if (widget.showBottomButtons) const SizedBox(height: 16),
            if (widget.showBottomButtons)
              DialogButtonGroup(
                // 如果正在处理，返回一个空函数，否则返回实际的取消处理函数
                onCancel: state.isProcessing
                    ? () {}
                    : () => Navigator.of(context).pop(),
                // 如果禁用或处理中，返回一个空函数，否则返回实际的确认处理函数
                onConfirm: (images.isEmpty || state.isProcessing)
                    ? () {}
                    : () async {
                        final success = await _handleConfirm();
                        if (success && mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
                confirmText: '导入',
                isProcessing: state.isProcessing,
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleAddImages() async {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug('WorkImportPreview handling addImages');
    await viewModel.addImages([]);
  }

  Future<bool> _handleConfirm() async {
    final viewModel = ref.read(workImportProvider.notifier);
    return viewModel.importWork();
  }

  Future<void> _handleDeleteSelected() async {
    final state = ref.read(workImportProvider);
    if (state.images.isEmpty) return;

    final isLastImage = state.images.length == 1;
    String title = isLastImage ? '确认删除' : '删除图片';
    String message = isLastImage ? '这是最后一张图片，删除后将退出导入。确定要删除吗？' : '确定要删除选中的图片吗？';

    final confirmed = await showConfirmDialog(
      context: context,
      title: title,
      message: message,
    );

    if (confirmed == true) {
      final viewModel = ref.read(workImportProvider.notifier);
      AppLogger.debug(
          'WorkImportPreview removing image at index: ${state.selectedImageIndex}');
      viewModel.removeImage(state.selectedImageIndex);

      if (isLastImage && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleImagesReordered(int oldIndex, int newIndex) {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug(
        'WorkImportPreview reordering images: $oldIndex -> $newIndex');
    viewModel.reorderImages(oldIndex, newIndex);
  }

  void _handleIndexChanged(int index) {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug('WorkImportPreview selecting image: $index');
    viewModel.selectImage(index);
  }
}
