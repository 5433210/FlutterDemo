import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/work/work_entity.dart';
import '../../../../domain/models/work/work_image.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../dialogs/common/image_operation_confirm_dialog.dart';
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

    // Show error message with SnackBar
    if (state.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: '关闭',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  notifier.clearError();
                },
              ),
            ),
          );
          // Auto clear error after showing
          notifier.clearError();
        }
      });
    }

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
            Text(AppLocalizations.of(context).imageRestoring),
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
              getImageRotation: (imagePath) {
                // 根据图片路径找到对应的图片，然后获取其临时旋转角度
                // 需要处理路径可能变化的情况
                WorkImage? foundImage;
                
                AppLogger.debug('查找图片旋转角度', tag: 'WorkImagesManagementView', data: {
                  'searchPath': imagePath,
                  'availableImagePaths': state.images.map((img) => img.path).take(3).toList(),
                });
                
                // 首先尝试精确匹配path
                for (final img in state.images) {
                  if (img.path == imagePath) {
                    foundImage = img;
                    break;
                  }
                }
                
                // 如果没找到，尝试匹配originalPath
                if (foundImage == null) {
                  for (final img in state.images) {
                    if (img.originalPath == imagePath) {
                      foundImage = img;
                      break;
                    }
                  }
                }
                
                // 如果还是没找到，使用当前选中的图片作为后备
                if (foundImage == null) {
                  if (state.images.isNotEmpty && currentIndex < state.images.length) {
                    foundImage = state.images[currentIndex];
                    AppLogger.warning('Image path not found, using current selected image', 
                        tag: 'WorkImagesManagementView',
                        data: {
                          'searchPath': imagePath,
                          'fallbackImageId': foundImage.id,
                          'fallbackImagePath': foundImage.path,
                        });
                  }
                }
                
                if (foundImage == null) {
                  AppLogger.error('No image found for rotation display', 
                      tag: 'WorkImagesManagementView',
                      data: {
                        'searchPath': imagePath,
                        'availableImages': state.images.length,
                      });
                  return 0.0;
                }
                
                final rotation = ref.read(workImageEditorProvider.notifier).getImageRotation(foundImage.id);
                
                AppLogger.debug('Image rotation lookup结果', tag: 'WorkImagesManagementView', data: {
                  'searchPath': imagePath,
                  'foundImageId': foundImage.id,
                  'foundImagePath': foundImage.path,
                  'foundImageUpdateTime': foundImage.updateTime.millisecondsSinceEpoch,
                  'rotation': rotation,
                });
                
                return rotation;
              },
              toolbarActions: [
                // 旋转图片按钮
                Tooltip(
                  message: '旋转90°',
                  preferBelow: false,
                  child: IconButton(
                    onPressed: (isProcessing || state.images.isEmpty)
                        ? null
                        : () => _handleRotateImage(context, ref),
                    icon: const Icon(Icons.rotate_right),
                  ),
                ),

                const SizedBox(width: 4),

                // 添加图片按钮 - 改为图标按钮
                Tooltip(
                  message: l10n.addImage,
                  preferBelow: false,
                  child: IconButton(
                    onPressed:
                        isProcessing ? null : () => notifier.addImages(context),
                    icon: const Icon(Icons.add_photo_alternate),
                  ),
                ),

                const SizedBox(width: 4),

                // 删除图片按钮 - 改为图标按钮
                Tooltip(
                  message: l10n.deleteImage,
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

      // 检查是否有提取的字符
      final hasCharacters = await notifier.hasExtractedCharacters(selectedImage.id);
      bool shouldDelete = false;

      if (hasCharacters) {
        final characterCount = await notifier.getCharacterCount(selectedImage.id);
        
        // 显示字符删除确认对话框
        shouldDelete = await ImageOperationConfirmDialog.showDeletionConfirm(
          context,
          characterCount,
          () {}, // 空回调，实际操作在返回后处理
        ) ?? false;
      } else {
        // 没有字符，显示普通删除确认对话框
        shouldDelete = await showDialog<bool>(
          context: context,
          barrierDismissible: false, // Prevent dismiss by tapping outside
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l10n.confirmDelete),
              content: Text(l10n.deleteMessage(1)),
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
                  child: Text(l10n.confirm),
                ),
              ],
            );
          },
        ) ?? false;
      }

      AppLogger.debug('Delete confirmation result',
          tag: 'WorkImagesManagementView', data: {'confirmed': shouldDelete});

      if (shouldDelete == true) {
        // Immediately update UI to show processing state
        if (context.mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deleting),
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
            content: Text(l10n.deleteFailed(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 处理图片旋转
  Future<void> _handleRotateImage(
      BuildContext context, WidgetRef ref) async {
    try {
      final state = ref.read(workImageEditorProvider);
      if (state.images.isEmpty) {
        AppLogger.warning('Attempted to rotate image but no images exist',
            tag: 'WorkImagesManagementView');
        return;
      }

      final notifier = ref.read(workImageEditorProvider.notifier);
      final currentIndex = ref.read(currentWorkImageIndexProvider);

      // 确保索引有效
      if (currentIndex < 0 || currentIndex >= state.images.length) {
        AppLogger.error('Invalid selected index for rotation',
            tag: 'WorkImagesManagementView',
            data: {
              'currentIndex': currentIndex,
              'imageCount': state.images.length
            });
        return;
      }

      final selectedImage = state.images[currentIndex];

      AppLogger.debug('Preparing to rotate image preview',
          tag: 'WorkImagesManagementView',
          data: {'imageId': selectedImage.id, 'index': currentIndex});

      // 检查是否有提取的字符
      final hasCharacters = await notifier.hasExtractedCharacters(selectedImage.id);
      
      if (hasCharacters) {
        final characterCount = await notifier.getCharacterCount(selectedImage.id);
        
        // 显示确认对话框
        final shouldRotate = await ImageOperationConfirmDialog.showRotationConfirm(
          context,
          characterCount,
          () {}, // 空回调，实际操作在返回后处理
        );

        if (shouldRotate != true) {
          return;
        }
      }

      // 执行预览旋转（不修改实际文件）
      AppLogger.debug('Rotating image preview',
          tag: 'WorkImagesManagementView',
          data: {'imageId': selectedImage.id});

      notifier.rotateImagePreview(selectedImage.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已调整预览角度，保存时将应用旋转'),
            duration: Duration(seconds: 2),
          ),
        );
      }

    } catch (e, stack) {
      AppLogger.error('Error in rotate preview operation',
          tag: 'WorkImagesManagementView', error: e, stackTrace: stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('调整预览角度失败: ${e.toString()}'),
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
    AppLogger.debug('WorkImagesManagementView._handleReorder',
        tag: 'WorkImagesManagementView',
        data: {
          'oldIndex': oldIndex,
          'newIndex': newIndex,
        });

    ref
        .read(workImageEditorProvider.notifier)
        .reorderImages(oldIndex, newIndex);
    // 更新详情页状态，标记为已更改
    ref.read(workDetailProvider.notifier).markAsChanged();
  }
}
