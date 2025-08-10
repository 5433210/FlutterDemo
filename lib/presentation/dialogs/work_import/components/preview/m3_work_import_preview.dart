import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/work/work_image.dart';
import '../../../../../infrastructure/logging/logger.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../providers/work_import_provider.dart';
import '../../../../widgets/works/enhanced_work_preview.dart';
import '../../../common/dialog_button_group.dart';
import '../../../common/dialogs.dart';

/// Material 3 version of the preview component for work import dialog
class M3WorkImportPreview extends ConsumerStatefulWidget {
  final bool showBottomButtons;

  const M3WorkImportPreview({
    super.key,
    this.showBottomButtons = true,
  });

  @override
  ConsumerState<M3WorkImportPreview> createState() =>
      _M3WorkImportPreviewState();
}

class _M3WorkImportPreviewState extends ConsumerState<M3WorkImportPreview> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workImportProvider);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    AppLogger.debug(
        'Building M3WorkImportPreview with ${state.images.length} images');

    // Log image paths for debugging
    if (state.images.isNotEmpty) {
      AppLogger.debug('First image path: ${state.images.first.path}');
    }

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

    // Ensure we have valid images for debugging
    AppLogger.debug('Mapped ${images.length} WorkImage objects for preview');

    // Create a function to handle the "Add Image" button click
    VoidCallback? handleAdd =
        state.isProcessing ? null : () => _handleAddImages();

    // Create a function to handle the "Delete Image" button click
    VoidCallback? handleDelete = (images.isEmpty || state.isProcessing)
        ? null
        : () => _handleDeleteSelected();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use constraints to adapt layout
        final isSmallWidth = constraints.maxWidth < 500;
        // Approximate height for buttons (used for spacing calculation)

        return Column(
          children: [
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0, // Remove card elevation for cleaner UI
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      12), // Material 3 uses larger radius
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withAlpha(128),
                    width: 1,
                  ),
                ),
                child: images.isEmpty
                    ? _buildEmptyState(theme, l10n, handleAdd)
                    : EnhancedWorkPreview(
                        images: images,
                        selectedIndex: state.selectedImageIndex,
                        isEditing: !state
                            .isProcessing, // Disable editing during processing
                        showToolbar: true,
                        getImageRotation: (imagePath) => 
                            ref.read(workImportProvider.notifier).getImageRotation(imagePath),
                        toolbarActions: [
                          // 旋转图片按钮
                          Tooltip(
                            message: '旋转90°',
                            preferBelow: false,
                            child: IconButton(
                              onPressed: state.isProcessing
                                  ? null
                                  : () => _handleRotateImage(),
                              icon: const Icon(Icons.rotate_right),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // 添加图片按钮 - 使用统一的图标按钮样式
                          Tooltip(
                            message: l10n.addImage,
                            preferBelow: false,
                            child: IconButton(
                              onPressed: state.isProcessing
                                  ? null
                                  : () => _handleAddImages(),
                              icon: const Icon(Icons.add_photo_alternate),
                            ),
                          ),

                          const SizedBox(width: 4),

                          // 删除图片按钮 - 使用统一的图标按钮样式
                          Tooltip(
                            message: l10n.deleteImage,
                            preferBelow: false,
                            child: IconButton(
                              onPressed: (images.isEmpty || state.isProcessing)
                                  ? null
                                  : () => _handleDeleteSelected(),
                              icon: const Icon(Icons.delete_outline),
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
                // If processing, return an empty function, otherwise return the actual cancel handler
                onCancel: state.isProcessing
                    ? () {}
                    : () => Navigator.of(context).pop(),
                // If disabled or processing, return an empty function, otherwise return the actual confirm handler
                onConfirm: (images.isEmpty || state.isProcessing)
                    ? () {}
                    : () {
                        _handleConfirmAndClose();
                      },
                confirmText: l10n.import,
                cancelText: l10n.cancel,
                isProcessing: state.isProcessing,
              ),
          ],
        );
      },
    );
  }

  // Build empty state view
  Widget _buildEmptyState(
      ThemeData theme, AppLocalizations l10n, VoidCallback? onAdd) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: theme.colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noImages,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addImageHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonalIcon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(l10n.addImage),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理添加图片（支持来源选择）
  Future<void> _handleAddImages() async {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug('M3WorkImportPreview handling addImages with source selection');
    
    if (!mounted) return;
    
    await viewModel.addImagesWithSource(context);
  }

  Future<void> _handleConfirmAndClose() async {
    final viewModel = ref.read(workImportProvider.notifier);
    final success = await viewModel.importWork();
    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleDeleteSelected() async {
    final state = ref.read(workImportProvider);
    final l10n = AppLocalizations.of(context);
    if (state.images.isEmpty) return;

    final isLastImage = state.images.length == 1;
    String title = l10n.deleteImage;
    String message = l10n.deleteMessage(1);

    final confirmed = await showConfirmDialog(
      context: context,
      title: title,
      message: message,
    );

    if (confirmed == true) {
      final viewModel = ref.read(workImportProvider.notifier);
      AppLogger.debug(
          'M3WorkImportPreview removing image at index: ${state.selectedImageIndex}');
      viewModel.removeImage(state.selectedImageIndex);

      if (isLastImage && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _handleImagesReordered(int oldIndex, int newIndex) {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug(
        'M3WorkImportPreview reordering images: $oldIndex -> $newIndex');
    viewModel.reorderImages(oldIndex, newIndex);
  }

  void _handleIndexChanged(int index) {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug('M3WorkImportPreview selecting image: $index');
    viewModel.selectImage(index);
  }

  /// 处理图片旋转
  void _handleRotateImage() {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug('M3WorkImportPreview rotating current image');
    viewModel.rotateCurrentImage();
  }
}
