import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/services/library/library_import_service.dart';
import '../../application/services/work/work_service.dart';
import '../../domain/models/work/work_entity.dart';
import '../../infrastructure/logging/logger.dart';
import '../widgets/library/m3_library_picker_dialog.dart';
import 'states/work_import_state.dart';

/// 作品导入视图模型
class WorkImportViewModel extends StateNotifier<WorkImportState> {
  final WorkService _workService;
  final LibraryImportService _libraryImportService;

  WorkImportViewModel(this._workService, this._libraryImportService)
      : super(WorkImportState.initial());

  /// 判断是否可以保存
  bool get canSubmit {
    return state.hasImages &&
        state.title.trim().isNotEmpty &&
        !state.isProcessing;
  }

  /// 添加图片（从本地文件系统或传入的文件列表）
  Future<void> addImages([List<File>? files]) async {
    try {
      state = state.copyWith(error: null);

      // 如果没有传入文件，则打开文件选择器
      if (files == null || files.isEmpty) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
        );

        if (result == null || result.files.isEmpty) {
          return;
        }

        files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        if (files.isEmpty) return;
      }

      state = state.copyWith(
        isProcessing: true,
        error: null,
      );
      state = state.copyWith(
        images: [...state.images, ...files],
        imageFromGallery: [
          ...state.imageFromGallery,
          ...List.filled(files.length, false)
        ], // 标记为本地文件
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: '添加图片失败: $e',
      );
    }
  }

  /// 从图库中选择并添加图片（确保不会导致父对话框关闭）
  Future<void> addImagesFromGallery(BuildContext context) async {
    try {
      state = state.copyWith(error: null);

      final selectedItems = await M3LibraryPickerDialog.showMulti(
        context,
      );

      AppLogger.debug('选择图库项', data: {'count': selectedItems?.length ?? 0});

      // 如果没有选择任何项目，则直接返回
      if (selectedItems == null || selectedItems.isEmpty) {
        AppLogger.debug('没有选择图库项，返回');

        return;
      }

      state = state.copyWith(
        isProcessing: true,
        error: null,
      );

      // 将选择的图库项目转换为文件

      final selectedFiles = selectedItems
          .map((item) => File(item.path))
          .where((file) => file.existsSync())
          .toList();

      if (selectedFiles.isEmpty) {
        throw Exception('没有找到有效的图片文件');
      }

      // 添加文件并确保强制更新状态
      final updatedImages = [...state.images, ...selectedFiles];

      AppLogger.debug('从图库添加图片', data: {
        'selectedCount': selectedFiles.length,
        'totalCount': updatedImages.length
      }); // 更新状态，设置选中索引为第一张新图片
      state = state.copyWith(
        images: updatedImages,
        imageFromGallery: [
          ...state.imageFromGallery,
          ...List.filled(selectedFiles.length, true)
        ], // 标记为图库文件
        isProcessing: false,
        selectedImageIndex: state.images.length,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: '从图库添加图片失败: $e',
      );
      rethrow;
    }
  }

  /// 清理状态（关闭对话框时调用）
  void cleanup() {
    reset();
  }

  /// 导入作品
  Future<bool> importWork() async {
    if (!canSubmit) return false;

    try {
      state =
          state.copyWith(isProcessing: true, error: null, statusMessage: null);

      // 1. 先将本地选择的图片添加到图库
      final localImageIndexes = <int>[];
      for (int i = 0; i < state.images.length; i++) {
        if (i < state.imageFromGallery.length && !state.imageFromGallery[i]) {
          localImageIndexes.add(i);
        }
      }

      AppLogger.debug('检测到需要添加到图库的本地图片', data: {
        'totalImages': state.images.length,
        'localImageCount': localImageIndexes.length,
        'localIndexes': localImageIndexes,
      }); // 如果有本地图片需要添加到图库，提示用户
      if (localImageIndexes.isNotEmpty) {
        state = state.copyWith(
          statusMessage: '正在将 ${localImageIndexes.length} 张本地图片添加到图库...',
        );

        // 让用户有时间看到提示信息
        await Future.delayed(const Duration(milliseconds: 800));
      } // 将本地图片添加到图库
      final libraryItemIds = <String, String>{}; // filePath -> libraryItemId 映射

      for (int i = 0; i < localImageIndexes.length; i++) {
        final index = localImageIndexes[i];
        try {
          final file = state.images[index];

          // 更新进度提示
          state = state.copyWith(
            statusMessage:
                '正在添加第 ${i + 1}/${localImageIndexes.length} 张图片到图库...',
          );

          // 让用户看到每个步骤的进度
          await Future.delayed(const Duration(milliseconds: 500));

          AppLogger.debug('正在将图片添加到图库', data: {
            'index': index,
            'filePath': file.path,
          });

          final libraryItem = await _libraryImportService.importFile(file.path);

          // 记录图片文件路径与图库项目ID的映射关系
          if (libraryItem != null) {
            libraryItemIds[file.path] = libraryItem.id;
            AppLogger.debug('图片已成功添加到图库并记录映射', data: {
              'index': index,
              'filePath': file.path,
              'libraryItemId': libraryItem.id,
            });
          }

          // 添加完成后稍作停顿
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          AppLogger.warning('添加图片到图库失败，继续处理', error: e, data: {
            'index': index,
            'filePath': state.images[index].path,
          });
          // 不抛出错误，继续处理后续图片
        }
      }

      // 更新状态提示
      state = state.copyWith(
        statusMessage: '正在导入作品...',
      );

      // 让用户看到导入作品的提示
      await Future.delayed(const Duration(milliseconds: 600));

      // 2. 创建新的作品实体
      final work = WorkEntity(
        id: const Uuid().v4(),
        title: state.title.trim(),
        author: state.author?.trim() ?? '',
        style: state.style ?? 'other', // Use default string value
        tool: state.tool ?? 'other', // Use default string value
        remark: state.remark?.trim(),
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
      ); // 3. 执行导入操作，传递libraryItemIds映射
      await _workService.importWork(
        state.images,
        work,
        libraryItemIds: libraryItemIds.isNotEmpty ? libraryItemIds : null,
      );

      // 导入成功后重置状态
      reset();
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: '导入失败: $e',
      );
      return false;
    }
  }

  /// 初始化现有作品的图片
  Future<void> initialize(List<File> images) async {
    if (images.isEmpty) return;

    try {
      state = state.copyWith(
        images: images,
        imageFromGallery: List.filled(images.length, true), // 假设初始化的图片都来自图库
        isProcessing: true,
        error: null,
      );

      state = state.copyWith(
        selectedImageIndex: 0,
        isProcessing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: '初始化图片失败: $e',
      );
    }
  }

  /// 删除图片
  void removeImage(int index) {
    if (index < 0 || index >= state.images.length) return;

    final newImages = List<File>.from(state.images);
    newImages.removeAt(index);

    // 同时删除对应的来源标记
    final newImageFromGallery = List<bool>.from(state.imageFromGallery);
    if (index < newImageFromGallery.length) {
      newImageFromGallery.removeAt(index);
    }

    // 如果删除的是当前选中项，需要更新选中索引
    final newSelectedIndex = _calculateNewSelectedIndex(
      oldIndex: index,
      maxIndex: newImages.length - 1,
    );

    state = state.copyWith(
      images: newImages,
      imageFromGallery: newImageFromGallery,
      selectedImageIndex: newSelectedIndex,
    );
  }

  /// 重新排序图片
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.images.length ||
        newIndex < 0 ||
        newIndex > state.images.length) {
      return;
    }

    final images = List<File>.from(state.images);
    final imageFromGallery = List<bool>.from(state.imageFromGallery);

    final item = images.removeAt(oldIndex);
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    images.insert(adjustedNewIndex, item);

    // 同时重新排序图片来源标记
    if (oldIndex < imageFromGallery.length) {
      final galleryFlag = imageFromGallery.removeAt(oldIndex);
      if (adjustedNewIndex < imageFromGallery.length) {
        imageFromGallery.insert(adjustedNewIndex, galleryFlag);
      } else {
        imageFromGallery.add(galleryFlag);
      }
    }

    state = state.copyWith(
      images: images,
      imageFromGallery: imageFromGallery,
      selectedImageIndex: _calculateNewSelectedIndex(
        oldIndex: oldIndex,
        newIndex: adjustedNewIndex,
        maxIndex: images.length - 1,
      ),
    );
  }

  /// 重置状态
  void reset() {
    state = WorkImportState.clean();
  }

  /// 选择图片
  void selectImage(int index) {
    if (index < 0 || index >= state.images.length) return;
    state = state.copyWith(selectedImageIndex: index);
  }

  /// 设置作者
  void setAuthor(String? author) {
    state = state.copyWith(author: author?.trim() ?? '');
  }

  /// 设置备注
  void setRemark(String? remark) {
    state = state.copyWith(remark: remark?.trim() ?? '');
  }

  /// 设置画风
  void setStyle(String? style) {
    if (style == null) return;
    state = state.copyWith(style: style);
  }

  /// 设置画风 (string version for compatibility)
  void setStyleByString(String? styleStr) {
    setStyle(styleStr); // Now just use the main method
  }

  /// 设置标题
  void setTitle(String? title) {
    state = state.copyWith(title: title?.trim() ?? '');
  }

  /// 设置创作工具
  void setTool(String? tool) {
    if (tool == null) return;
    state = state.copyWith(tool: tool);
  }

  /// 设置创作工具 (string version for compatibility)
  void setToolByString(String? toolStr) {
    setTool(toolStr); // Now just use the main method
  }

  /// 计算新的选中索引
  int _calculateNewSelectedIndex({
    required int oldIndex,
    int? newIndex,
    required int maxIndex,
  }) {
    int selectedIndex = state.selectedImageIndex;

    // 重新排序时的索引计算
    if (newIndex != null) {
      if (selectedIndex == oldIndex) {
        return newIndex;
      }
      if (selectedIndex > oldIndex && selectedIndex <= newIndex) {
        return selectedIndex - 1;
      }
      if (selectedIndex < oldIndex && selectedIndex >= newIndex) {
        return selectedIndex + 1;
      }
      return selectedIndex;
    }

    // 删除时的索引计算
    if (selectedIndex == oldIndex) {
      return maxIndex >= 0 ? maxIndex : 0;
    }
    if (selectedIndex > oldIndex) {
      return selectedIndex - 1;
    }
    return selectedIndex;
  }
}
