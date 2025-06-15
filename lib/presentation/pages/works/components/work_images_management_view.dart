import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/work_detail_provider.dart';
import '../../../providers/work_image_editor_provider.dart';
import '../../../widgets/works/enhanced_work_preview.dart';

/// 作品图片管理视图
class WorkImagesManagementView extends ConsumerWidget {
  final WorkEntity work;

  const WorkImagesManagementView({
    super.key,
    required this.work,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(workImageEditorProvider);
    final notifier = ref.read(workImageEditorProvider.notifier);
    final isProcessing = state.isProcessing;
    final currentIndex = ref.watch(currentWorkImageIndexProvider);
    final isInitialized = ref.watch(workImageInitializedProvider);

    // Add debugging to understand what state we're getting
    AppLogger.debug(
      'Building WorkImagesManagementView',
      tag: 'WorkImagesManagementView',
      data: {
        'imageCount': state.images.length,
        'selectedIndex': currentIndex,
        'isProcessing': isProcessing,
        'hasError': state.error != null,
        'workImagesCount': work.images.length,
        'isInitialized': isInitialized,
        'stateMatch': state.images.length == work.images.length,
        'deletedImageCount': state.deletedImageIds.length,
      },
    );

    // Detect inconsistent state with improved logic that accounts for deleted images
    final hasInconsistentState =
        _detectInconsistentState(state, work, isInitialized);

    if (hasInconsistentState) {
      AppLogger.warning(
        'Inconsistent state detected in WorkImagesManagementView',
        tag: 'WorkImagesManagementView',
        data: {
          'workId': work.id,
          'workImagesCount': work.images.length,
          'editorImagesCount': state.images.length,
          'isInitialized': isInitialized,
        },
      );

      // Force reinitialization to recover from inconsistent state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.exists(workImageEditorProvider)) {
          ref.read(workImageInitializedProvider.notifier).state = false;
          notifier.reset(); // Clear state first
          notifier.initialize(work.images);

          // After initialization, set the selected index
          final selectedIndex = ref.read(workDetailProvider).selectedImageIndex;
          notifier.updateSelectedIndex(selectedIndex);
        }
      });
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).workImageRestoring),
          ],
        ),
      );
    }

    // Check for normal initialization status
    if (!isInitialized && work.images.isNotEmpty) {
      AppLogger.debug(
        'Editor not initialized yet, initializing with work images',
        tag: 'WorkImagesManagementView',
        data: {
          'workId': work.id,
          'workImagesCount': work.images.length,
        },
      );

      // Try initializing the editor
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ref.exists(workImageEditorProvider)) {
          notifier.initialize(work.images);

          // After initialization, set the selected index
          final selectedIndex = ref.read(workDetailProvider).selectedImageIndex;
          notifier.updateSelectedIndex(selectedIndex);
        }
      });

      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // If images are empty but should exist, provide a loading state
    // but don't try to reinitialize here - that's handled by the provider
    if (state.images.isEmpty && work.images.isNotEmpty) {
      AppLogger.warning(
        'Editor has no images but work does',
        tag: 'WorkImagesManagementView',
        data: {
          'workId': work.id,
          'workImageCount': work.images.length,
        },
      );

      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Enhanced Work Preview
            EnhancedWorkPreview(
              images: state.images,
              selectedIndex: currentIndex,
              isEditing: true,
              showToolbar: true,
              toolbarActions: [
                // 添加图片按钮 - 改为图标按钮
                Tooltip(
                  message: l10n.addImages,
                  preferBelow: false,
                  child: IconButton(
                    onPressed: isProcessing ? null : () => notifier.addImages(),
                    icon: const Icon(Icons.add_photo_alternate),
                  ),
                ),

                const SizedBox(width: 4),

                // 删除图片按钮 - 改为图标按钮
                Tooltip(
                  message: l10n.deleteCurrentImage,
                  preferBelow: false,
                  child: IconButton(
                    onPressed: (isProcessing || state.images.isEmpty)
                        ? null
                        : () => _handleDeleteSelected(context, ref),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              ],
              onIndexChanged: isProcessing
                  ? null
                  : (index) => _handleIndexChanged(ref, index),
              onImagesReordered: isProcessing
                  ? null
                  : (oldIndex, newIndex) =>
                      _handleReorder(ref, oldIndex, newIndex),
            ),

            // Error message display
            if (state.error != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      state.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            // Processing overlay
            if (isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Helper method to detect inconsistent state with better logic
  bool _detectInconsistentState(
      WorkImageEditorState state, WorkEntity work, bool isInitialized) {
    // If we're not initialized, can't be inconsistent yet
    if (!isInitialized) return false;

    // If we have no images in state but should have some, that's inconsistent
    if (state.images.isEmpty && work.images.isNotEmpty) return true;

    // When adding images, we expect editor to have more images than work entity
    // This is normal during editing and shouldn't trigger a reset
    if (state.images.length > work.images.length) {
      AppLogger.debug(
        'Editor has more images than work - this is expected during editing',
        tag: 'WorkImagesManagementView',
        data: {
          'editorImagesCount': state.images.length,
          'workImagesCount': work.images.length,
          'difference': state.images.length - work.images.length,
        },
      );
      return false; // Not inconsistent, just new images being added
    }

    // If there are deleted images, account for them in the comparison
    final expectedCount = work.images.length - state.deletedImageIds.length;

    // Calculate if we have a legitimate inconsistency
    // Only flag as inconsistent if the current count is less than expected
    // after accounting for deletions - missing images is a real inconsistency
    final countMismatch = state.images.length < expectedCount;

    // Log the decision factors for debugging
    if (countMismatch) {
      AppLogger.debug(
        'Image count mismatch after deletion checks',
        tag: 'WorkImagesManagementView',
        data: {
          'stateImagesCount': state.images.length,
          'workImagesCount': work.images.length,
          'deletedCount': state.deletedImageIds.length,
          'expectedCount': expectedCount,
        },
      );
    }

    return countMismatch;
  }

  /// 处理删除选中图片
  Future<void> _handleDeleteSelected(
      BuildContext context, WidgetRef ref) async {
    try {
      final state = ref.read(workImageEditorProvider);
      if (state.images.isEmpty) {
        AppLogger.warning('Attempted to delete image but no images exist',
            tag: 'WorkImagesManagementView');
        return;
      }

      final notifier = ref.read(workImageEditorProvider.notifier);
      final currentIndex = ref.read(currentWorkImageIndexProvider);

      // Ensure index is valid
      if (currentIndex < 0 || currentIndex >= state.images.length) {
        AppLogger.error('Invalid selected index for deletion',
            tag: 'WorkImagesManagementView',
            data: {
              'currentIndex': currentIndex,
              'imageCount': state.images.length
            });
        return;
      }

      final selectedImage = state.images[currentIndex];

      AppLogger.debug('Preparing to delete image',
          tag: 'WorkImagesManagementView',
          data: {'imageId': selectedImage.id, 'index': currentIndex});

      // 确认删除
      final shouldDelete = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Prevent dismiss by tapping outside
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.workImageDeleteConfirmTitle),
            content: Text(l10n.workImageDeleteConfirmContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: Text(l10n.delete),
              ),
            ],
          );
        },
      );

      AppLogger.debug('Delete confirmation result',
          tag: 'WorkImagesManagementView', data: {'confirmed': shouldDelete});

      if (shouldDelete == true) {
        // Immediately update UI to show processing state
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.workImageDeleting),
              duration: const Duration(seconds: 1),
            ),
          );
        }

        await notifier.deleteImage(selectedImage.id);

        // 如果删除后没有图片了，标记作品详情发生了变化
        if (ref.read(workImageEditorProvider).images.isEmpty) {
          ref.read(workDetailProvider.notifier).markAsChanged();
        }
      }
    } catch (e, stack) {
      AppLogger.error('Error in delete operation',
          tag: 'WorkImagesManagementView', error: e, stackTrace: stack);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.workImageDeleteFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 处理图片索引变化
  void _handleIndexChanged(WidgetRef ref, int index) {
    ref.read(currentWorkImageIndexProvider.notifier).state = index;
  }

  /// 处理图片重新排序
  void _handleReorder(WidgetRef ref, int oldIndex, int newIndex) {
    ref
        .read(workImageEditorProvider.notifier)
        .reorderImages(oldIndex, newIndex);
    // 更新详情页状态，标记为已更改
    ref.read(workDetailProvider.notifier).markAsChanged();
  }
}
