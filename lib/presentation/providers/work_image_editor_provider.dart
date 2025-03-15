import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/models/work/work_image.dart';
import '../../infrastructure/logging/logger.dart';
import './work_detail_provider.dart';

final currentWorkImageIndexProvider = StateProvider<int>((ref) => 0);

final workImageEditorProvider = StateNotifierProvider.autoDispose<
    WorkImageEditorNotifier, WorkImageEditorState>(
  (ref) => WorkImageEditorNotifier(ref),
);

class WorkImageEditorNotifier extends StateNotifier<WorkImageEditorState> {
  final Ref _ref;

  WorkImageEditorNotifier(this._ref) : super(const WorkImageEditorState());

  Future<void> addImage() async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null) {
          AppLogger.debug('添加新图片', tag: 'WorkImageEditor', data: {
            'filePath': filePath,
          });

          final workImageService = _ref.read(workImageServiceProvider);
          final workId = _ref.read(workDetailProvider).work?.id;

          if (workId != null) {
            final newImage = await workImageService.importImage(
              workId,
              File(filePath),
            );

            final newImages = [...state.images, newImage];
            state = state.copyWith(
              images: newImages,
              isProcessing: false,
            );

            // Update selected index to show new image
            _ref.read(currentWorkImageIndexProvider.notifier).state =
                newImages.length - 1;

            // Mark work as changed
            _ref.read(workDetailProvider.notifier).markAsChanged();
          }
        }
      } else {
        state = state.copyWith(isProcessing: false);
      }
    } catch (e) {
      AppLogger.error('添加图片失败', tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '添加图片失败: $e',
      );
      rethrow;
    }
  }

  Future<void> deleteImage(String imageId) async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      final workId = _ref.read(workDetailProvider).work?.id;
      if (workId == null) return;

      AppLogger.debug('删除图片', tag: 'WorkImageEditor', data: {
        'imageId': imageId,
      });

      final currentIndex = _ref.read(currentWorkImageIndexProvider);
      final workImageService = _ref.read(workImageServiceProvider);

      // Delete image file
      await workImageService.deleteImage(workId, imageId);

      // Update state
      final newImages = state.images.where((img) => img.id != imageId).toList();
      state = state.copyWith(
        images: newImages,
        isProcessing: false,
      );

      // Update selected index if needed
      if (newImages.isEmpty) {
        _ref.read(currentWorkImageIndexProvider.notifier).state = 0;
      } else if (currentIndex >= newImages.length) {
        _ref.read(currentWorkImageIndexProvider.notifier).state =
            newImages.length - 1;
      }

      // Mark work as changed
      _ref.read(workDetailProvider.notifier).markAsChanged();
    } catch (e) {
      AppLogger.error('删除图片失败', tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '删除图片失败: $e',
      );
      rethrow;
    }
  }

  Future<void> initialize(List<WorkImage> images) async {
    state = state.copyWith(images: images);
    _ref.read(currentWorkImageIndexProvider.notifier).state = 0;
  }

  Future<void> reorderImages(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      final items = List<WorkImage>.from(state.images);
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);

      AppLogger.debug('重排序图片', tag: 'WorkImageEditor', data: {
        'oldIndex': oldIndex,
        'newIndex': newIndex,
      });

      state = state.copyWith(images: items);

      // Update selected index
      _ref.read(currentWorkImageIndexProvider.notifier).state = newIndex;

      // Mark work as changed
      _ref.read(workDetailProvider.notifier).markAsChanged();
    } catch (e) {
      AppLogger.error('重排序图片失败', tag: 'WorkImageEditor', error: e);
      state = state.copyWith(error: '重排序图片失败: $e');
      rethrow;
    }
  }

  Future<void> saveChanges() async {
    try {
      state = state.copyWith(isProcessing: true, error: null);

      final workId = _ref.read(workDetailProvider).work?.id;
      if (workId == null) return;

      final workImageService = _ref.read(workImageServiceProvider);

      // Save images
      final savedImages = await workImageService.saveChanges(
        workId,
        state.images,
        onProgress: (progress, message) {
          AppLogger.debug('保存进度', tag: 'WorkImageEditor', data: {
            'progress': progress,
            'message': message,
          });
        },
      );

      state = state.copyWith(
        images: savedImages,
        isProcessing: false,
      );
    } catch (e) {
      AppLogger.error('保存图片更改失败', tag: 'WorkImageEditor', error: e);
      state = state.copyWith(
        isProcessing: false,
        error: '保存图片更改失败: $e',
      );
      rethrow;
    }
  }
}

class WorkImageEditorState {
  final List<WorkImage> images;
  final bool isProcessing;
  final String? error;

  const WorkImageEditorState({
    this.images = const [],
    this.isProcessing = false,
    this.error,
  });

  WorkImageEditorState copyWith({
    List<WorkImage>? images,
    bool? isProcessing,
    String? error,
  }) {
    return WorkImageEditorState(
      images: images ?? this.images,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}
