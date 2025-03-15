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

          // 创建临时图片对象
          final imageId = DateTime.now().millisecondsSinceEpoch.toString();
          final file = File(filePath);

          // 使用文件路径作为临时路径
          final newImage = WorkImage(
            id: imageId,
            workId: _ref.read(workDetailProvider).work!.id,
            path: file.path,
            originalPath: file.path,
            thumbnailPath: file.path,
            format: file.path.split('.').last.toLowerCase(),
            size: await file.length(),
            width: 0,
            height: 0,
            index: state.images.length,
            createTime: DateTime.now(),
            updateTime: DateTime.now(),
          );

          final newImages = [...state.images, newImage];
          state = state.copyWith(
            images: newImages,
            isProcessing: false,
          );

          // 更新选中索引到新图片
          _ref.read(currentWorkImageIndexProvider.notifier).state =
              newImages.length - 1;

          // 标记作品已更改
          _ref.read(workDetailProvider.notifier).markAsChanged();
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

      AppLogger.debug('删除图片', tag: 'WorkImageEditor', data: {
        'imageId': imageId,
      });

      final currentIndex = _ref.read(currentWorkImageIndexProvider);

      // 从列表中移除图片并重新计算索引
      final remainingImages =
          state.images.where((img) => img.id != imageId).toList();
      final reindexedImages = List<WorkImage>.generate(
        remainingImages.length,
        (index) => remainingImages[index].copyWith(
          index: index,
          updateTime: DateTime.now(),
        ),
      );

      state = state.copyWith(
        images: reindexedImages,
        isProcessing: false,
      );

      // 更新选中索引
      if (reindexedImages.isEmpty) {
        _ref.read(currentWorkImageIndexProvider.notifier).state = 0;
      } else if (currentIndex >= reindexedImages.length) {
        _ref.read(currentWorkImageIndexProvider.notifier).state =
            reindexedImages.length - 1;
      }

      // 标记作品已更改
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

      // 重新计算所有图片的索引
      final reindexedImages = List<WorkImage>.generate(
        items.length,
        (index) => items[index].copyWith(
          index: index,
          updateTime: DateTime.now(),
        ),
      );

      AppLogger.debug('重排序图片', tag: 'WorkImageEditor', data: {
        'oldIndex': oldIndex,
        'newIndex': newIndex,
      });

      state = state.copyWith(images: reindexedImages);

      // 更新选中索引
      _ref.read(currentWorkImageIndexProvider.notifier).state = newIndex;

      // 标记作品已更改
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

      // 保存所有图片
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
