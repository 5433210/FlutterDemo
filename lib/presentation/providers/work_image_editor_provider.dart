import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/models/work/work_image.dart';
import '../../infrastructure/logging/logger.dart';
import './work_detail_provider.dart';

final currentWorkImageIndexProvider = StateProvider<int>((ref) => 0);

final workImageEditorProvider = StateNotifierProvider.autoDispose<
    WorkImageEditorNotifier, WorkImageEditorState>((ref) {
  // Create the notifier
  final notifier = WorkImageEditorNotifier(ref);

  // Setup disposal callback
  ref.onDispose(() {
    AppLogger.debug('WorkImageEditorProvider disposed', tag: 'WorkImageEditor');
  });

  // Important: Don't call initialize methods that modify other providers here!

  return notifier;
});

/// Flag to indicate if initial synchronization is complete
final workImageInitializedProvider = StateProvider<bool>((ref) => false);

class WorkImageEditorNotifier extends StateNotifier<WorkImageEditorState> {
  final Ref _ref;

  WorkImageEditorNotifier(this._ref) : super(const WorkImageEditorState());

  // For backward compatibility - just calls addImages()
  Future<void> addImage() async {
    await addImages();
  }

  /// Add one or more images
  /// This is the consolidated method for adding images - always allows multiple selection
  Future<void> addImages() async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      AppLogger.debug('Starting image selection', tag: 'WorkImageEditor');

      // Always use multiple selection - users can still select just one if they want
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true, // Always allow multiple selection
        withData: false,
        lockParentWindow: true,
        dialogTitle: '选择图片 (可按住Ctrl多选)',
      );

      AppLogger.debug('File picker result', tag: 'WorkImageEditor', data: {
        'hasResult': result != null,
        'fileCount': result?.files.length ?? 0
      });

      // Handle no selection case
      if (result == null || result.files.isEmpty) {
        AppLogger.debug('User cancelled file selection',
            tag: 'WorkImageEditor');
        state = state.copyWith(isProcessing: false);
        return;
      }

      final workId = _ref.read(workDetailProvider).work!.id;
      final newImages = <WorkImage>[];
      int successCount = 0;
      int errorCount = 0;

      // Process each selected file - works for single or multiple selection
      for (final file in result.files) {
        if (file.path == null) {
          errorCount++;
          continue;
        }

        try {
          final filePath = file.path!;
          final imageFile = File(filePath);

          // Basic verification
          if (!await imageFile.exists()) {
            AppLogger.warning('Selected file does not exist',
                tag: 'WorkImageEditor', data: {'path': filePath});
            errorCount++;
            continue;
          }

          // Create a unique ID that includes timestamp and counter
          final imageId =
              '${DateTime.now().millisecondsSinceEpoch}_$successCount';

          final newImage = WorkImage(
            id: imageId,
            workId: workId,
            path: imageFile.path,
            originalPath: imageFile.path,
            thumbnailPath: imageFile.path,
            format: imageFile.path.split('.').last.toLowerCase(),
            size: await imageFile.length(),
            width: 0,
            height: 0,
            index: state.images.length + newImages.length,
            createTime: DateTime.now(),
            updateTime: DateTime.now(),
          );

          newImages.add(newImage);
          successCount++;
        } catch (e) {
          AppLogger.error('Error processing file',
              tag: 'WorkImageEditor', error: e, data: {'path': file.path});
          errorCount++;
        }
      }

      if (newImages.isNotEmpty) {
        // Update state with all new images
        final allImages = [...state.images, ...newImages];

        AppLogger.debug('Adding images to state',
            tag: 'WorkImageEditor',
            data: {
              'newImagesCount': newImages.length,
              'totalImagesCount': allImages.length,
              'successCount': successCount,
              'errorCount': errorCount,
            });

        state = state.copyWith(
          images: allImages,
          isProcessing: false,
          hasPendingAdditions: true,
        );

        // Update selected index to the first new image
        _ref.read(currentWorkImageIndexProvider.notifier).state =
            state.images.length - newImages.length;

        // Mark work as changed
        _ref.read(workDetailProvider.notifier).markAsChanged();

        // Show user feedback about partial failures if any
        if (errorCount > 0 && successCount > 0) {
          state = state.copyWith(
              error: '已添加 $successCount 张图片，$errorCount 张图片无法处理');
        } else if (errorCount > 0 && successCount == 0) {
          state = state.copyWith(error: '无法处理所选图片');
        }
      } else {
        state = state.copyWith(isProcessing: false, error: '无法添加所选图片');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to add images',
          tag: 'WorkImageEditor', error: e, stackTrace: stackTrace);

      state = state.copyWith(
        isProcessing: false,
        error: '添加图片失败: ${e.toString()}',
      );
    }
  }

  Future<void> deleteImage(String imageId) async {
    try {
      AppLogger.debug('Starting image deletion', tag: 'WorkImageEditor', data: {
        'imageId': imageId,
        'currentImageCount': state.images.length,
      });

      state = state.copyWith(isProcessing: true, error: null);

      // Find the image in the current state
      final imageToDelete = state.images.firstWhere(
        (img) => img.id == imageId,
        orElse: () => throw Exception('Image not found: $imageId'),
      );

      AppLogger.debug('Found image to delete', tag: 'WorkImageEditor', data: {
        'imageId': imageId,
        'imagePath': imageToDelete.path,
      });

      final currentIndex = _ref.read(currentWorkImageIndexProvider);

      // Remove the image from the list and reindex
      final remainingImages =
          state.images.where((img) => img.id != imageId).toList();
      final reindexedImages = List<WorkImage>.generate(
        remainingImages.length,
        (index) => remainingImages[index].copyWith(
          index: index,
          updateTime: DateTime.now(),
        ),
      );

      // Add to deleted IDs list for tracking and future cleanup
      final updatedDeletedIds = [...state.deletedImageIds, imageId];

      // Update state with new image list and add deleted ID to tracking
      state = state.copyWith(
        images: reindexedImages,
        deletedImageIds: updatedDeletedIds,
        isProcessing: false,
      );

      // Log additional info about the deleted images tracking
      AppLogger.debug(
        'Updated deleted images tracking',
        tag: 'WorkImageEditor',
        data: {
          'deletedIds': updatedDeletedIds,
          'deletedCount': updatedDeletedIds.length,
        },
      );

      // Update selected index to prevent out-of-bounds access
      if (reindexedImages.isEmpty) {
        _ref.read(currentWorkImageIndexProvider.notifier).state = 0;
      } else if (currentIndex >= reindexedImages.length) {
        _ref.read(currentWorkImageIndexProvider.notifier).state =
            reindexedImages.length - 1;
      }

      // Mark the work as changed
      _ref.read(workDetailProvider.notifier).markAsChanged();

      AppLogger.debug('Image deleted successfully',
          tag: 'WorkImageEditor',
          data: {
            'remainingImageCount': reindexedImages.length,
            'deletedIdsCount': updatedDeletedIds.length,
          });
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete image',
          tag: 'WorkImageEditor', error: e, stackTrace: stackTrace);

      state = state.copyWith(
        isProcessing: false,
        error: '删除图片失败: ${e.toString()}',
      );
    }
  }

  /// Initialize the editor with images from a work
  /// This should only be called after provider creation, not during
  Future<void> initialize(List<WorkImage> images) async {
    // First check if still mounted before proceeding
    if (!mounted) {
      AppLogger.warning(
        'Attempted to initialize WorkImageEditor after disposal',
        tag: 'WorkImageEditor',
      );
      return;
    }

    // Reset initialized state to false at start of initialization
    _ref.read(workImageInitializedProvider.notifier).state = false;

    // Log the incoming images to verify they exist
    AppLogger.debug(
      'Initializing WorkImageEditor with images',
      tag: 'WorkImageEditor',
      data: {
        'imageCount': images.length,
        'imageIds': images.isNotEmpty
            ? images.map((img) => img.id).take(3).toList() +
                (images.length > 3 ? ['...'] : [])
            : [],
      },
    );

    if (images.isEmpty) {
      AppLogger.warning(
        'Attempted to initialize editor with empty images list',
        tag: 'WorkImageEditor',
      );
      return;
    }

    try {
      // Create a deep copy of images to prevent reference issues
      final imagesCopy = images.map((img) => img.copyWith()).toList();

      // Update our state with clean pending state
      state = WorkImageEditorState(
        images: imagesCopy,
        deletedImageIds: const [],
        isProcessing: false,
        error: null,
        hasPendingAdditions: false, // Reset pending state on initialization
      );

      // Verify images were properly loaded before marking as initialized
      if (state.images.isNotEmpty) {
        // Only mark as initialized if we actually have images
        _ref.read(workImageInitializedProvider.notifier).state = true;

        AppLogger.debug(
          'WorkImageEditor initialization successful',
          tag: 'WorkImageEditor',
          data: {
            'imageCount': state.images.length,
            'initialized': true,
          },
        );
      } else {
        AppLogger.error(
          'WorkImageEditor initialization failed - no images in state after update',
          tag: 'WorkImageEditor',
          data: {
            'providedImageCount': images.length,
          },
        );
      }
    } catch (e) {
      AppLogger.error(
        'Error during WorkImageEditor initialization',
        tag: 'WorkImageEditor',
        error: e,
      );
      // Ensure initialization flag is false on error
      _ref.read(workImageInitializedProvider.notifier).state = false;
    }
  }

  Future<void> reorderImages(int oldIndex, int newIndex) async {
    try {
      AppLogger.info('开始重排序图片', tag: 'WorkImageEditor', data: {
        'oldIndex': oldIndex,
        'newIndex': newIndex,
        'totalImages': state.images.length,
        'beforeAdjustment': 'oldIndex=$oldIndex, newIndex=$newIndex',
        'originalOrder': state.images.map((img) => '${img.id}(${img.index})').take(5).toList(),
      });

      // Flutter ReorderableListView 的标准调整逻辑
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      AppLogger.info('调整后的索引', tag: 'WorkImageEditor', data: {
        'adjustedOldIndex': oldIndex,
        'adjustedNewIndex': newIndex,
        'afterAdjustment': 'oldIndex=$oldIndex, newIndex=$newIndex',
      });

      final items = List<WorkImage>.from(state.images);
      
      // 记录移动前的图片信息
      final movingImage = items[oldIndex];
      AppLogger.info('移动的图片信息', tag: 'WorkImageEditor', data: {
        'movingImageId': movingImage.id,
        'movingImageIndex': movingImage.index,
        'movingImagePath': movingImage.path,
      });

      // 执行移动操作
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);

      // 重新计算所有图片的索引
      final reindexedImages = List<WorkImage>.generate(
        items.length,
        (index) => items[index].copyWith(
          index: index,
          updateTime: DateTime.now(),
        ),
      );

      AppLogger.info('重排序完成 - 内存中的状态', tag: 'WorkImageEditor', data: {
        'oldIndex': oldIndex,
        'newIndex': newIndex,
        'firstImageId': reindexedImages.isNotEmpty ? reindexedImages[0].id : null,
        'movedImageNewIndex': reindexedImages.indexWhere((img) => img.id == movingImage.id),
        'newOrder': reindexedImages.map((img) => '${img.id}(${img.index})').take(5).toList(),
        'allImagesCount': reindexedImages.length,
      });

      state = state.copyWith(images: reindexedImages);

      // 更新选中索引到移动后的位置
      _ref.read(currentWorkImageIndexProvider.notifier).state = newIndex;

      // 标记作品已更改
      _ref.read(workDetailProvider.notifier).markAsChanged();
      
      AppLogger.info('重排序完成 - 状态已更新', tag: 'WorkImageEditor', data: {
        'hasChanges': _ref.read(workDetailProvider).hasChanges,
        'stateImageCount': state.images.length,
        'currentSelectedIndex': _ref.read(currentWorkImageIndexProvider),
      });
    } catch (e) {
      AppLogger.error('重排序图片失败', tag: 'WorkImageEditor', error: e);
      state = state.copyWith(error: '重排序图片失败: $e');
      rethrow;
    }
  }

  /// Reset the state to initial empty state
  void reset() {
    // When resetting, make sure to clear the deleted images tracking
    state = const WorkImageEditorState();
    _ref.read(workImageInitializedProvider.notifier).state = false;
    AppLogger.debug(
      'Resetting WorkImageEditor state',
      tag: 'WorkImageEditor',
      data: {'deletedIdsCleared': true, 'pendingAdditionsCleared': true},
    );
  }

  Future<void> saveChanges() async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      final workId = _ref.read(workDetailProvider).work?.id;
      if (workId == null) return;

      AppLogger.info('开始保存图片更改', tag: 'WorkImageEditor', data: {
        'workId': workId,
        'imageCount': state.images.length,
        'currentOrder': state.images.map((img) => '${img.id}(${img.index})').take(5).toList(),
        'hasPendingAdditions': state.hasPendingAdditions,
        'deletedImageIds': state.deletedImageIds,
        'firstImageId': state.images.isNotEmpty ? state.images[0].id : null,
      });

      final workImageService = _ref.read(workImageServiceProvider);

      // 先删除标记为删除的图片
      for (final imageId in state.deletedImageIds) {
        try {
          await workImageService.deleteImage(workId, imageId);
        } catch (e) {
          AppLogger.warning('删除图片文件失败',
              tag: 'WorkImageEditor',
              error: e,
              data: {
                'imageId': imageId,
                'workId': workId,
              });
        }
      }

      // 保存所有图片 - 不再检查条件，确保顺序调整能被保存
      AppLogger.info('调用 Service 保存图片', tag: 'WorkImageEditor', data: {
        'imageCount': state.images.length,
        'saveReason': 'Always save to ensure order changes are persisted',
      });

      final savedImages = await workImageService.saveChanges(
        workId,
        state.images,
        onProgress: (progress, message) {
          AppLogger.info('保存进度', tag: 'WorkImageEditor', data: {
            'progress': progress,
            'message': message,
          });
        },
      );

      AppLogger.info('图片保存完成', tag: 'WorkImageEditor', data: {
        'savedCount': savedImages.length,
        'savedOrder': savedImages.map((img) => '${img.id}(${img.index})').take(5).toList(),
      });

      state = state.copyWith(
        images: savedImages,
        deletedImageIds: [],
        isProcessing: false,
        hasPendingAdditions: false, // Clear pending flag after successful save
      );

      // 移除此行 - 不要重新加载作品详情，会覆盖已编辑的更改
      // await _ref.read(workDetailProvider.notifier).loadWorkDetails(workId);
    } catch (e) {
      AppLogger.error('保存图片更改失败', tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '保存图片更改失败: $e',
      );
      rethrow;
    }
  }

  // 图片排序
  Future<void> sortImages() async {
    try {
      if (state.images.isEmpty || state.images.length <= 1) return;

      state = state.copyWith(isProcessing: true, error: null);

      // 根据文件名排序
      final sortedImages = List<WorkImage>.from(state.images)
        ..sort((a, b) => a.path.compareTo(b.path));

      // 重新计算索引
      final reindexedImages = List<WorkImage>.generate(
        sortedImages.length,
        (index) => sortedImages[index].copyWith(
          index: index,
          updateTime: DateTime.now(),
        ),
      );

      // 更新状态
      state = state.copyWith(
        images: reindexedImages,
        isProcessing: false,
      );

      // 如果当前选择的图片顺序变了，更新选择的索引到第一张
      _ref.read(currentWorkImageIndexProvider.notifier).state = 0;

      // 标记作品已更改
      _ref.read(workDetailProvider.notifier).markAsChanged();
    } catch (e) {
      AppLogger.error('图片排序失败', tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '图片排序失败: $e',
      );
    }
  }

  /// Update the selected index (to be called after initialization)
  void updateSelectedIndex(int index) {
    if (!mounted) return;

    final maxIndex = state.images.length - 1;
    final safeIndex = index.clamp(0, maxIndex < 0 ? 0 : maxIndex);

    // Now we can safely update the index provider
    _ref.read(currentWorkImageIndexProvider.notifier).state = safeIndex;

    AppLogger.debug(
      'Updated selected index',
      tag: 'WorkImageEditor',
      data: {
        'requestedIndex': index,
        'actualIndex': safeIndex,
        'maxIndex': maxIndex,
      },
    );
  }
}

class WorkImageEditorState {
  final List<WorkImage> images;
  final List<String> deletedImageIds;
  final bool isProcessing;
  final String? error;
  final bool hasPendingAdditions; // Track if we've added new images

  const WorkImageEditorState({
    this.images = const [],
    this.deletedImageIds = const [],
    this.isProcessing = false,
    this.error,
    this.hasPendingAdditions = false,
  });

  WorkImageEditorState copyWith({
    List<WorkImage>? images,
    List<String>? deletedImageIds,
    bool? isProcessing,
    String? error,
    bool? hasPendingAdditions,
  }) {
    return WorkImageEditorState(
      images: images ?? this.images,
      deletedImageIds: deletedImageIds ?? this.deletedImageIds,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      hasPendingAdditions: hasPendingAdditions ?? this.hasPendingAdditions,
    );
  }
}
