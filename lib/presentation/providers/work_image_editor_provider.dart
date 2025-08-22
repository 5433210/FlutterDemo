import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/character/character_service.dart';
import '../../domain/models/work/work_image.dart';
import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/library/m3_library_picker_dialog.dart';
import './work_detail_provider.dart';

enum ImageSource {
  local,
  library,
}

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

  /// Add one or more images with source selection
  /// This is the consolidated method for adding images - allows selection from local files or library
  Future<void> addImages([BuildContext? context]) async {
    if (context == null) {
      // If no context provided, fallback to local file selection for backward compatibility
      await addImagesFromLocal();
      return;
    }

    // Show source selection dialog
    final source = await _showImageSourceDialog(context);
    if (source == null) return;

    switch (source) {
      case ImageSource.local:
        await addImagesFromLocal();
        break;
      case ImageSource.library:
        // Pass context immediately without await to avoid async gap
        if (context.mounted) {
          await addImagesFromLibrary(context);
        }
        break;
    }
  }

  /// Add images from local file system
  Future<void> addImagesFromLocal() async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      AppLogger.debug('Starting local image selection', tag: 'WorkImageEditor');

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

      final selectedFiles = result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .where((file) => file.existsSync())
          .toList();

      if (selectedFiles.isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          error: '没有找到有效的图片文件',
        );
        return;
      }

      AppLogger.info('Selected local files for work editing',
          tag: 'WorkImageEditor',
          data: {
            'fileCount': selectedFiles.length,
            'willAddToLibrary': true,
          });

      await _processSelectedFiles(selectedFiles, fromLibrary: false);
    } catch (e) {
      AppLogger.error('Error in local image selection',
          tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '添加本地图片失败: $e',
      );
    }
  }

  /// Add images from library
  Future<void> addImagesFromLibrary(BuildContext context) async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      AppLogger.debug('Starting library image selection',
          tag: 'WorkImageEditor');

      final selectedItems = await M3LibraryPickerDialog.showMulti(context);

      if (selectedItems == null || selectedItems.isEmpty) {
        AppLogger.debug('User cancelled library selection',
            tag: 'WorkImageEditor');
        state = state.copyWith(isProcessing: false);
        return;
      }

      final selectedFiles = selectedItems
          .map((item) => File(item.path))
          .where((file) => file.existsSync())
          .toList();

      if (selectedFiles.isEmpty) {
        state = state.copyWith(
          isProcessing: false,
          error: '没有找到有效的图库图片文件',
        );
        return;
      }

      AppLogger.info('Selected library files for work editing',
          tag: 'WorkImageEditor',
          data: {
            'fileCount': selectedFiles.length,
            'libraryItemIds': selectedItems.map((item) => item.id).toList(),
          });

      // Create library item ID mapping
      final libraryItemIds = <String, String>{};
      for (int i = 0; i < selectedFiles.length; i++) {
        libraryItemIds[selectedFiles[i].path] = selectedItems[i].id;
      }

      await _processSelectedFiles(selectedFiles,
          fromLibrary: true, libraryItemIds: libraryItemIds);
    } catch (e) {
      AppLogger.error('Error in library image selection',
          tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '添加图库图片失败: $e',
      );
    }
  }

  /// Process selected files (common logic for both local and library sources)
  Future<void> _processSelectedFiles(
    List<File> selectedFiles, {
    required bool fromLibrary,
    Map<String, String>? libraryItemIds,
  }) async {
    try {
      final workId = _ref.read(workDetailProvider).work!.id;
      final libraryImportService = _ref.read(libraryImportServiceProvider);
      final newImages = <WorkImage>[];
      int successCount = 0;
      int errorCount = 0;

      // If files are from local, add them to library first
      final finalLibraryItemIds = libraryItemIds ?? <String, String>{};

      if (!fromLibrary) {
        AppLogger.info('Adding local files to library first',
            tag: 'WorkImageEditor',
            data: {
              'fileCount': selectedFiles.length,
            });

        for (int i = 0; i < selectedFiles.length; i++) {
          final file = selectedFiles[i];
          try {
            AppLogger.debug('Adding file to library',
                tag: 'WorkImageEditor',
                data: {
                  'index': i + 1,
                  'total': selectedFiles.length,
                  'filePath': file.path,
                });

            final libraryItem =
                await libraryImportService.importFile(file.path);
            if (libraryItem != null) {
              finalLibraryItemIds[file.path] = libraryItem.id;
              AppLogger.debug('File added to library successfully',
                  tag: 'WorkImageEditor',
                  data: {
                    'filePath': file.path,
                    'libraryItemId': libraryItem.id,
                  });
            }
          } catch (e) {
            AppLogger.warning('Failed to add file to library, continuing',
                tag: 'WorkImageEditor',
                error: e,
                data: {'filePath': file.path});
            // Continue processing even if library import fails
          }
        }
      }

      // 检查重复图片（包括文件路径和图库ID）
      final existingPaths = state.images.map((img) => img.originalPath).toSet();
      final existingLibraryIds = state.images
          .where((img) => img.libraryItemId != null)
          .map((img) => img.libraryItemId!)
          .toSet();
      
      AppLogger.info('检查图片重复', tag: 'WorkImageEditor', data: {
        'totalSelectedFiles': selectedFiles.length,
        'existingImagesCount': state.images.length,
        'fromLibrary': fromLibrary,
        'existingLibraryIds': existingLibraryIds.length,
        'providedLibraryItemIds': finalLibraryItemIds.length,
      });
      
      final duplicateFiles = <File>[];
      final duplicateLibraryItems = <String>[]; // 图库项目名称
      final uniqueSelectedFiles = <File>[];
      int duplicateCount = 0;

      for (final file in selectedFiles) {
        final absolutePath = file.absolute.path;
        final libraryItemId = finalLibraryItemIds[file.path];
        bool isDuplicate = false;
        String? duplicateReason;
        
        // 检查与现有图片路径是否重复
        for (final existingPath in existingPaths) {
          if (File(existingPath).absolute.path == absolutePath) {
            isDuplicate = true;
            duplicateReason = '文件路径重复';
            break;
          }
        }
        
        // 如果来自图库，还要检查图库ID是否重复
        if (!isDuplicate && fromLibrary && libraryItemId != null) {
          if (existingLibraryIds.contains(libraryItemId)) {
            isDuplicate = true;
            duplicateReason = '图库图片已存在';
          }
        }
        
        if (isDuplicate) {
          duplicateFiles.add(file);
          duplicateCount++;
          
          // 记录图库项目名称用于提示
          if (fromLibrary && libraryItemId != null) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            duplicateLibraryItems.add(fileName);
          }
          
          AppLogger.debug('发现重复图片', tag: 'WorkImageEditor', data: {
            'filePath': file.path,
            'libraryItemId': libraryItemId,
            'reason': duplicateReason,
            'fromLibrary': fromLibrary,
          });
        } else {
          uniqueSelectedFiles.add(file);
          existingPaths.add(absolutePath); // 防止本批次内部重复
          if (libraryItemId != null) {
            existingLibraryIds.add(libraryItemId); // 防止图库ID重复
          }
        }
      }

      // 如果全部都是重复图片
      if (duplicateFiles.isNotEmpty && uniqueSelectedFiles.isEmpty) {
        String message;
        if (duplicateCount == 1) {
          final fileName = duplicateFiles.first.path.split(Platform.pathSeparator).last;
          if (fromLibrary && duplicateLibraryItems.isNotEmpty) {
            message = '图库图片 "$fileName" 已存在于当前作品中';
          } else {
            message = '图片 "$fileName" 已存在';
          }
        } else {
          if (fromLibrary && duplicateLibraryItems.isNotEmpty) {
            message = '选择的 $duplicateCount 张图库图片已存在于当前作品中，未添加任何新图片';
          } else {
            message = '选择的 $duplicateCount 张图片已存在，未添加任何新图片';
          }
        }
        
        state = state.copyWith(
          isProcessing: false,
          error: message,
        );
        return;
      }

      // 记录重复图片信息（用于后续提示）
      String? duplicateMessage;
      if (duplicateCount > 0) {
        if (duplicateCount == 1) {
          final fileName = duplicateFiles.first.path.split(Platform.pathSeparator).last;
          if (fromLibrary && duplicateLibraryItems.isNotEmpty) {
            duplicateMessage = '图库图片 "$fileName" 已存在于当前作品中';
          } else {
            duplicateMessage = '图片 "$fileName" 已存在';
          }
        } else {
          if (fromLibrary && duplicateLibraryItems.length == duplicateCount) {
            // 全部都是图库重复
            duplicateMessage = '$duplicateCount 张图库图片已存在于当前作品中';
          } else if (fromLibrary && duplicateLibraryItems.isNotEmpty) {
            // 混合重复（部分图库，部分文件）
            duplicateMessage = '$duplicateCount 张图片已存在（包含 ${duplicateLibraryItems.length} 张图库重复）';
          } else {
            duplicateMessage = '$duplicateCount 张图片已存在';
          }
        }
      }

      // Process each unique selected file for work import
      for (int i = 0; i < uniqueSelectedFiles.length; i++) {
        final file = uniqueSelectedFiles[i];
        try {
          if (!await file.exists()) {
            AppLogger.warning('Selected file does not exist',
                tag: 'WorkImageEditor', data: {'path': file.path});
            errorCount++;
            continue;
          }

          // Create a unique ID that includes timestamp and counter
          final imageId =
              '${DateTime.now().millisecondsSinceEpoch}_$successCount';
          final libraryItemId = finalLibraryItemIds[file.path];

          final newImage = WorkImage(
            id: imageId,
            workId: workId,
            libraryItemId: libraryItemId, // Link to library item if available
            path: file.path,
            originalPath: file.path,
            thumbnailPath: file.path,
            format: file.path.split('.').last.toLowerCase(),
            size: await file.length(),
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

        // 构造完整的状态消息
        String? finalMessage;
        if (duplicateMessage != null && errorCount > 0) {
          finalMessage = '$duplicateMessage，已成功添加 $successCount 张新图片，$errorCount 张图片处理失败';
        } else if (duplicateMessage != null) {
          finalMessage = '$duplicateMessage，已成功添加 $successCount 张新图片';
        } else if (errorCount > 0) {
          finalMessage = '已成功添加 $successCount 张图片，$errorCount 张图片处理失败';
        }

        AppLogger.debug('Adding images to work state',
            tag: 'WorkImageEditor',
            data: {
              'newImagesCount': newImages.length,
              'totalImagesCount': allImages.length,
              'successCount': successCount,
              'errorCount': errorCount,
              'duplicateCount': duplicateCount,
              'fromLibrary': fromLibrary,
              'libraryItemIdsCount': finalLibraryItemIds.length,
              'finalMessage': finalMessage,
            });

        state = state.copyWith(
          images: allImages,
          isProcessing: false,
          hasPendingAdditions: true,
          error: finalMessage, // 显示包含重复信息的消息
        );

        // Update selected index to the first new image
        _ref.read(currentWorkImageIndexProvider.notifier).state =
            state.images.length - newImages.length;

        // Mark work as changed
        _ref.read(workDetailProvider.notifier).markAsChanged();
        
      } else {
        // 没有新图片被添加
        String errorMessage;
        if (duplicateCount > 0 && errorCount > 0) {
          errorMessage = '$duplicateMessage，其余 $errorCount 张图片处理失败';
        } else if (duplicateCount > 0) {
          errorMessage = duplicateMessage!;
        } else {
          errorMessage = errorCount > 0 ? '所有选择的图片都处理失败' : '没有有效的图片文件';
        }
        
        state = state.copyWith(
          isProcessing: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      AppLogger.error('Error processing selected files',
          tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '处理选择的图片失败: $e',
      );
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addImages),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(l10n.fromLocal),
              subtitle: Text(l10n.imagePropertyPanelAutoImportNotice),
              onTap: () => Navigator.of(context).pop(ImageSource.local),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.fromGallery),
              subtitle: Text(l10n.existingItem),
              onTap: () => Navigator.of(context).pop(ImageSource.library),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
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
      // 注意：保留现有的 temporaryRotations，避免旋转信息丢失
      state = WorkImageEditorState(
        images: imagesCopy,
        deletedImageIds: const [],
        isProcessing: false,
        error: null,
        hasPendingAdditions: false, // Reset pending state on initialization
        temporaryRotations: state.temporaryRotations, // 保留旋转信息
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
        'originalOrder': state.images
            .map((img) => '${img.id}(${img.index})')
            .take(5)
            .toList(),
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
        'firstImageId':
            reindexedImages.isNotEmpty ? reindexedImages[0].id : null,
        'movedImageNewIndex':
            reindexedImages.indexWhere((img) => img.id == movingImage.id),
        'newOrder': reindexedImages
            .map((img) => '${img.id}(${img.index})')
            .take(5)
            .toList(),
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
      data: {
        'deletedIdsCleared': true, 
        'pendingAdditionsCleared': true,
        'temporaryRotationsCleared': true,
      },
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
        'currentOrder': state.images
            .map((img) => '${img.id}(${img.index})')
            .take(5)
            .toList(),
        'hasPendingAdditions': state.hasPendingAdditions,
        'deletedImageIds': state.deletedImageIds,
        'temporaryRotationsCount': state.temporaryRotations.length,
        'firstImageId': state.images.isNotEmpty ? state.images[0].id : null,
      });

      final workImageService = _ref.read(workImageServiceProvider);

      // 先删除标记为删除的图片
      for (final imageId in state.deletedImageIds) {
        AppLogger.debug('Deleting image and associated characters', 
            tag: 'WorkImageEditor', data: {'imageId': imageId});
        
        try {
          // 删除该图片关联的所有字符
          await _deleteImageCharacters(imageId);
          
          // 删除图片
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

      // 转换临时旋转信息：从 imageId -> rotation 转换为 originalPath -> rotation
      final imageRotations = <String, double>{};
      bool needUpdateCover = false;
      String? firstImageId;
      
      if (state.images.isNotEmpty) {
        // 按照index排序后取第一张图片
        final sortedImages = [...state.images]..sort((a, b) => a.index.compareTo(b.index));
        firstImageId = sortedImages.first.id;
      }

      for (final entry in state.temporaryRotations.entries) {
        final imageId = entry.key;
        final rotation = entry.value;
        
        if (rotation != 0.0) {
          // 删除该图片关联的所有字符（旋转会使字符位置失效）
          await _deleteImageCharacters(imageId);
          
          // 查找对应的图片
          WorkImage? image;
          for (final img in state.images) {
            if (img.id == imageId) {
              image = img;
              break;
            }
          }
          
          if (image == null) {
            AppLogger.warning('Image not found for rotation', tag: 'WorkImageEditor', data: {
              'searchId': imageId,
              'availableIds': state.images.map((img) => img.id).toList(),
            });
            continue;
          }
          
          // 只使用originalPath作为键，避免混乱
          imageRotations[image.originalPath] = rotation;
          
          // 如果旋转的是第一张图片，需要更新封面
          if (imageId == firstImageId) {
            needUpdateCover = true;
          }
          
          AppLogger.info('准备旋转图片', tag: 'WorkImageEditor', data: {
            'imageId': imageId,
            'originalPath': image.originalPath,
            'rotation': rotation,
            'isFirstImage': imageId == firstImageId,
          });
        }
      }

      AppLogger.info('调用 WorkImageService 保存所有更改', tag: 'WorkImageEditor', data: {
        'imageCount': state.images.length,
        'imageRotationsCount': imageRotations.length,
        'needUpdateCover': needUpdateCover,
      });

      // 调用 WorkImageService 保存所有更改（包括旋转）
      final savedImages = await workImageService.saveChanges(
        workId,
        state.images,
        onProgress: (progress, message) {
          AppLogger.info('保存进度', tag: 'WorkImageEditor', data: {
            'progress': progress,
            'message': message,
          });
        },
        imageRotations: imageRotations, // 传递旋转信息
      );

      AppLogger.info('图片保存完成', tag: 'WorkImageEditor', data: {
        'savedCount': savedImages.length,
        'savedOrder': savedImages
            .map((img) => '${img.id}(${img.index})')
            .take(5)
            .toList(),
        'needUpdateCover': needUpdateCover,
      });

      // 如果旋转了首图，重新生成封面
      if (needUpdateCover && firstImageId != null) {
        try {
          AppLogger.info('开始更新作品封面', tag: 'WorkImageEditor', data: {
            'workId': workId,
            'firstImageId': firstImageId,
            'reason': '首图已旋转',
          });
          
          await workImageService.updateCover(workId, firstImageId);
          
          AppLogger.info('作品封面更新完成', tag: 'WorkImageEditor', data: {
            'workId': workId,
            'firstImageId': firstImageId,
          });
        } catch (e) {
          AppLogger.error('更新作品封面失败', tag: 'WorkImageEditor', 
              error: e, data: {
                'workId': workId,
                'firstImageId': firstImageId,
              });
          // 不中断保存流程，封面更新失败不应影响主要功能
        }
      }

      // 建立旧ID到新ID的映射（用于处理新增图片的情况）
      final idMapping = <String, String>{};
      for (int i = 0; i < state.images.length && i < savedImages.length; i++) {
        final oldId = state.images[i].id;
        final newId = savedImages[i].id;
        if (oldId != newId) {
          idMapping[oldId] = newId;
          AppLogger.debug('图片ID映射', tag: 'WorkImageEditor', data: {
            'oldId': oldId,
            'newId': newId,
            'reason': '新增图片保存后ID变化',
          });
        }
      }

      // 更新temporaryRotations中的ID（如果有ID变化的话）
      // 注意：只有成功保存的旋转才被清除，失败的保留
      final updatedRotations = <String, double>{};
      for (final entry in state.temporaryRotations.entries) {
        final oldId = entry.key;
        final rotation = entry.value;
        final newId = idMapping[oldId] ?? oldId;
        
        // 检查这个旋转是否已经被成功应用
        bool wasApplied = false;
        if (rotation != 0.0) {
          for (final img in state.images) {
            if (img.id == oldId && imageRotations.containsKey(img.originalPath)) {
              wasApplied = true;
              break;
            }
          }
        }
        
        if (wasApplied) {
          AppLogger.info('旋转已应用，清除临时旋转', tag: 'WorkImageEditor', data: {
            'imageId': oldId,
            'rotation': rotation,
          });
          // 成功应用的旋转被清除，不再保留
        } else if (rotation != 0.0) {
          // 旋转未被应用（可能是因为图片找不到），保留它，并更新ID
          updatedRotations[newId] = rotation;
          AppLogger.warning('旋转未应用，保留临时旋转', tag: 'WorkImageEditor', data: {
            'oldImageId': oldId,
            'newImageId': newId,
            'rotation': rotation,
          });
        }
      }

      state = state.copyWith(
        images: savedImages,
        deletedImageIds: [],
        isProcessing: false,
        hasPendingAdditions: false, // Clear pending flag after successful save
        temporaryRotations: updatedRotations, // 使用更新后的旋转信息，而不是直接清空
      );

      // 立即清除图片缓存，确保旋转后的图片能正确显示
      // 先清除全局缓存
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      
      // 立即清除特定图片的缓存
      for (final image in savedImages) {
        try {
          // 清除各种可能的图片路径缓存
          for (final path in [image.path, image.originalPath, image.thumbnailPath]) {
            if (path.isNotEmpty) {
              final file = File(path);
              if (file.existsSync()) {
                FileImage(file).evict();
              }
            }
          }
        } catch (e) {
          AppLogger.warning('清除单个图片缓存失败', 
              tag: 'WorkImageEditor', 
              error: e, 
              data: {'imageId': image.id});
        }
      }
      
      AppLogger.info('已立即清除Flutter图片缓存，强制刷新旋转后图片', 
          tag: 'WorkImageEditor',
          data: {
            'clearedCacheCount': 'all',
            'savedImagesCount': savedImages.length,
            'specificCachesCleared': savedImages.length * 3, // 每个图片3个路径
          });
      
      // 延迟一帧后再次清除，确保所有UI组件都能看到更新
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // 等待一小段时间确保文件系统操作完成
        await Future.delayed(const Duration(milliseconds: 50));
        
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        AppLogger.debug('PostFrame 图片缓存延迟清除完成', tag: 'WorkImageEditor');
      });

      // 不重新加载作品详情，避免清空旋转状态
      // 直接更新当前状态以反映保存的结果
      AppLogger.info('保存完成，不重新加载避免状态重置', tag: 'WorkImageEditor', data: {
        'savedImagesCount': savedImages.length,
        'updatedRotationsCount': updatedRotations.length,
        'finalStateImageCount': state.images.length,
        'firstImageDetails': state.images.isNotEmpty ? {
          'id': state.images[0].id,
          'path': state.images[0].path,
          'updateTime': state.images[0].updateTime.millisecondsSinceEpoch,
        } : null,
        'currentTemporaryRotations': state.temporaryRotations,
      });
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

  /// 检查图片是否已提取字符
  Future<bool> hasExtractedCharacters(String imageId) async {
    try {
      final characterService = _ref.read(characterServiceProvider);
      final characters = await characterService.getCharactersByPageId(imageId);
      return characters.isNotEmpty;
    } catch (e) {
      AppLogger.error('检查图片字符提取状态失败', error: e, data: {'imageId': imageId});
      return false;
    }
  }

  /// 获取图片的已提取字符数量
  Future<int> getCharacterCount(String imageId) async {
    try {
      final characterService = _ref.read(characterServiceProvider);
      final characters = await characterService.getCharactersByPageId(imageId);
      return characters.length;
    } catch (e) {
      AppLogger.error('获取图片字符数量失败', error: e, data: {'imageId': imageId});
      return 0;
    }
  }

  /// 临时旋转图片预览（不修改实际文件）
  void rotateImagePreview(String imageId) {
    try {
      AppLogger.debug('Adding temporary rotation to image preview', tag: 'WorkImageEditor', data: {
        'imageId': imageId,
      });

      // 获取当前的临时旋转角度
      final currentRotation = state.temporaryRotations[imageId] ?? 0.0;
      // 每次增加90度
      final newRotation = (currentRotation + 90.0) % 360.0;
      
      // 更新临时旋转角度
      final updatedRotations = Map<String, double>.from(state.temporaryRotations);
      updatedRotations[imageId] = newRotation;
      
      state = state.copyWith(
        temporaryRotations: updatedRotations,
      );

      // 标记作品已更改，激活保存按钮
      _ref.read(workDetailProvider.notifier).markAsChanged();

      AppLogger.debug('Image preview rotation updated', 
          tag: 'WorkImageEditor',
          data: {
            'imageId': imageId,
            'newRotation': newRotation,
          });

    } catch (e, stackTrace) {
      AppLogger.error('Failed to rotate image preview',
          tag: 'WorkImageEditor', error: e, stackTrace: stackTrace);
    }
  }

  /// 获取图片的临时旋转角度
  double getImageRotation(String imageId) {
    final rotation = state.temporaryRotations[imageId] ?? 0.0;
    
    AppLogger.debug('获取图片旋转角度', tag: 'WorkImageEditor', data: {
      'imageId': imageId,
      'rotation': rotation,
      'hasTemporaryRotation': state.temporaryRotations.containsKey(imageId),
      'totalTemporaryRotations': state.temporaryRotations.length,
      'allRotations': state.temporaryRotations,
    });
    
    return rotation;
  }

  /// 清除错误状态
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
      AppLogger.debug('Error state cleared', tag: 'WorkImageEditor');
    }
  }

  /// 删除图片关联的所有字符
  Future<void> _deleteImageCharacters(String imageId) async {
    try {
      final characterService = _ref.read(characterServiceProvider);
      
      // 获取该图片的所有字符
      final characters = await characterService.getCharactersByPageId(imageId);
      
      if (characters.isNotEmpty) {
        AppLogger.info('删除图片关联的字符', 
            tag: 'WorkImageEditor',
            data: {
              'imageId': imageId,
              'characterCount': characters.length,
              'characterIds': characters.map((c) => c.id).toList(),
            });
        
        // 批量删除字符
        final characterIds = characters.map((c) => c.id).toList();
        await characterService.deleteBatchCharacters(characterIds);
        
        AppLogger.info('成功删除图片关联的字符', 
            tag: 'WorkImageEditor',
            data: {
              'imageId': imageId,
              'deletedCount': characters.length,
            });
      } else {
        AppLogger.debug('图片无关联字符，跳过删除', 
            tag: 'WorkImageEditor',
            data: {'imageId': imageId});
      }
    } catch (e) {
      AppLogger.error('删除图片关联字符失败',
          tag: 'WorkImageEditor', 
          error: e, 
          data: {'imageId': imageId});
      // 不重新抛出异常，避免影响主要操作
    }
  }
}

class WorkImageEditorState {
  final List<WorkImage> images;
  final List<String> deletedImageIds;
  final bool isProcessing;
  final String? error;
  final bool hasPendingAdditions; // Track if we've added new images
  final Map<String, double> temporaryRotations; // 临时旋转角度，key是imageId

  const WorkImageEditorState({
    this.images = const [],
    this.deletedImageIds = const [],
    this.isProcessing = false,
    this.error,
    this.hasPendingAdditions = false,
    this.temporaryRotations = const {},
  });

  WorkImageEditorState copyWith({
    List<WorkImage>? images,
    List<String>? deletedImageIds,
    bool? isProcessing,
    String? error,
    bool? hasPendingAdditions,
    Map<String, double>? temporaryRotations,
  }) {
    return WorkImageEditorState(
      images: images ?? this.images,
      deletedImageIds: deletedImageIds ?? this.deletedImageIds,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      hasPendingAdditions: hasPendingAdditions ?? this.hasPendingAdditions,
      temporaryRotations: temporaryRotations ?? this.temporaryRotations,
    );
  }
}
