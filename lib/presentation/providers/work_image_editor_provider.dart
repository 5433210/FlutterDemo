import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/work/work_image_service.dart';
import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_image.dart';
import '../../infrastructure/logging/logger.dart';
import './work_detail_provider.dart';

// Re-export selected image index provider
final selectedImageIndexProvider = StateProvider<int>((ref) => 0);

final workImageEditorProvider = StateNotifierProvider.family<
    WorkImageEditorNotifier, List<WorkImage>, WorkEntity>((ref, work) {
  final imageService = ref.watch(workImageServiceProvider);
  return WorkImageEditorNotifier(
    ref,
    imageService,
    work.id,
    work.images,
  );
});

typedef ProgressCallback = void Function(double progress, String message);

enum ImageOperation {
  add,
  delete,
  reorder,
}

class PendingOperation {
  final ImageOperation type;
  final String? imageId;
  final File? file;
  final int? oldIndex;
  final int? newIndex;

  PendingOperation.add(this.file)
      : type = ImageOperation.add,
        imageId = null,
        oldIndex = null,
        newIndex = null;

  PendingOperation.delete(this.imageId)
      : type = ImageOperation.delete,
        file = null,
        oldIndex = null,
        newIndex = null;

  PendingOperation.reorder(this.oldIndex, this.newIndex)
      : type = ImageOperation.reorder,
        imageId = null,
        file = null;
}

class WorkImageEditorNotifier extends StateNotifier<List<WorkImage>> {
  final Ref _ref;
  final WorkImageService _imageService;
  final String workId;
  final List<WorkImage> _originalImages;
  final List<PendingOperation> _pendingOperations = [];
  bool _hasUnsavedChanges = false;

  WorkImageEditorNotifier(
      this._ref, this._imageService, this.workId, List<WorkImage> images)
      : _originalImages = List.from(images),
        super(images);

  bool get hasUnsavedChanges => _hasUnsavedChanges;

  Future<void> addImage(File file) async {
    AppLogger.debug('添加新图片', tag: 'WorkImageEditor', data: {
      'filePath': file.path,
      'pendingCount': _pendingOperations.length + 1,
    });

    // Add to pending operations
    _pendingOperations.add(PendingOperation.add(file));

    // Create temporary image
    final tempImage = await _imageService.importImage(workId, file);
    state = [...state, tempImage];
    _hasUnsavedChanges = true;

    _ref.read(workDetailProvider.notifier).markAsChanged();
  }

  void cancelChanges() {
    AppLogger.debug('取消图片更改', tag: 'WorkImageEditor', data: {
      'pendingOperations': _pendingOperations.length,
    });

    // Restore original state
    state = List.from(_originalImages);
    _pendingOperations.clear();
    _hasUnsavedChanges = false;
  }

  Future<void> deleteImage(String imageId) async {
    if (state.length <= 1) return;

    AppLogger.debug('删除图片', tag: 'WorkImageEditor', data: {
      'imageId': imageId,
      'pendingCount': _pendingOperations.length + 1,
    });

    _pendingOperations.add(PendingOperation.delete(imageId));

    final images = state.where((img) => img.id != imageId).toList();
    state = _updateImageIndexes(images);
    _hasUnsavedChanges = true;

    _ref.read(workDetailProvider.notifier).markAsChanged();
  }

  Future<void> reorderImages(int oldIndex, int newIndex) async {
    AppLogger.debug('重排序图片', tag: 'WorkImageEditor', data: {
      'oldIndex': oldIndex,
      'newIndex': newIndex,
      'pendingCount': _pendingOperations.length + 1,
    });

    _pendingOperations.add(PendingOperation.reorder(oldIndex, newIndex));

    final images = [...state];
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);

    state = _updateImageIndexes(images);
    _hasUnsavedChanges = true;

    _ref.read(workDetailProvider.notifier).markAsChanged();
  }

  Future<void> saveChanges({ProgressCallback? onProgress}) async {
    if (!_hasUnsavedChanges) return;

    AppLogger.info('保存图片更改', tag: 'WorkImageEditor', data: {
      'pendingOperations': _pendingOperations.length,
    });

    try {
      onProgress?.call(0.0, '准备保存...');

      // Save changes to all images
      final savedImages = await _imageService.saveChanges(
        workId,
        state,
        onProgress: (progress, message) {
          onProgress?.call(progress, message);
        },
      );

      state = savedImages;
      _pendingOperations.clear();
      _hasUnsavedChanges = false;

      onProgress?.call(1.0, '保存完成');

      AppLogger.info('图片更改已保存', tag: 'WorkImageEditor');
    } catch (e) {
      AppLogger.error('保存图片更改失败', tag: 'WorkImageEditor', error: e);
      rethrow;
    }
  }

  /// Helper method to update image indexes
  List<WorkImage> _updateImageIndexes(List<WorkImage> images) {
    return images.asMap().entries.map((entry) {
      final index = entry.key;
      final image = entry.value;
      return image.copyWith(
        index: index,
        updateTime: DateTime.now(),
      );
    }).toList();
  }
}
