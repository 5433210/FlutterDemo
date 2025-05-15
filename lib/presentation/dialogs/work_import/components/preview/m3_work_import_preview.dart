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
                        toolbarActions: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: handleAdd,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: isSmallWidth
                                      ? Text(l10n.import)
                                      : Text(l10n.workImportDialogAddImages),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => _handleAddFromGallery(),
                                  icon: const Icon(Icons.collections),
                                  label: isSmallWidth
                                      ? Text(l10n.workImportDialogFromGallery)
                                      : Text(
                                          l10n.workImportDialogFromGalleryLong),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: OutlinedButton.icon(
                              onPressed:
                                  handleDelete, // Disabled during processing
                              icon: const Icon(
                                Icons.delete_outline,
                              ),
                              label: isSmallWidth
                                  ? Text(l10n.delete)
                                  : Text(l10n.workImportDialogDeleteImage),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: theme.colorScheme.error,
                                side: BorderSide(
                                  color: theme.colorScheme.error.withAlpha(
                                    images.isEmpty || state.isProcessing
                                        ? 97
                                        : 255,
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
                confirmText: l10n.workImportDialogImport,
                cancelText: l10n.workImportDialogCancel,
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
            l10n.workImportDialogNoImages,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.workImportDialogNoImagesHint,
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
                label: Text(l10n.workImportDialogAddImages),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _handleAddFromGallery(),
                icon: const Icon(Icons.collections),
                label: Text(l10n.workImportDialogFromGallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 处理从图库添加图片
  Future<void> _handleAddFromGallery() async {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug('M3WorkImportPreview handling addImages from gallery');
    print('【WorkImportPreview】开始从图库添加图片，对话框context: $context');

    try {
      // 添加前获取当前图片数量
      final countBefore = ref.read(workImportProvider).images.length;
      print('【WorkImportPreview】添加前图片数量: $countBefore');

      // 确保在正确的上下文中调用，并使用非根导航器
      if (!mounted) {
        print('【WorkImportPreview】组件已卸载，取消操作');
        return;
      }

      // 在调用前记录当前的导航状态
      final navigator = Navigator.of(context);
      final canPop = navigator.canPop();
      print(
          '【WorkImportPreview】导航器状态：canPop = $canPop, navigatorContext = ${navigator.context}');

      await viewModel.addImagesFromGallery(context);

      // 检查组件是否仍然挂载
      if (!mounted) {
        print('【WorkImportPreview】addImagesFromGallery后组件已卸载');
        return;
      }

      // 检查导航器状态是否改变
      final navigatorAfter = Navigator.of(context);
      final canPopAfter = navigatorAfter.canPop();
      print(
          '【WorkImportPreview】addImagesFromGallery后导航器状态：canPop = $canPopAfter');

      // 添加后获取图片数量，用于确认添加成功
      final countAfter = ref.read(workImportProvider).images.length;
      AppLogger.debug(
          'Gallery images added: ${countAfter - countBefore} new images');
      print('【WorkImportPreview】添加后图片数量: $countAfter');

      // 如果图片数量没变，可能添加失败但未抛出异常
      if (countAfter == countBefore) {
        AppLogger.warning('No images added from gallery');
        print('【WorkImportPreview】未添加任何图片');
      }
    } catch (e) {
      print('【WorkImportPreview】从图库添加图片出错: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('从图库添加图片失败: $e')),
      );
    }
  }

  /// 处理从本地文件系统添加图片
  Future<void> _handleAddImages() async {
    final viewModel = ref.read(workImportProvider.notifier);
    AppLogger.debug('M3WorkImportPreview handling addImages from local');
    await viewModel.addImages([]);
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
    String title = l10n.workImportDialogDeleteImage;
    String message = l10n.workImportDialogDeleteImageConfirm;

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
}
