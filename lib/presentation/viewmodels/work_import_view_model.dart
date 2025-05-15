import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/services/work/work_service.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/models/work/work_entity.dart';
import '../../infrastructure/image/image_processor.dart';
import '../../infrastructure/logging/logger.dart';
import '../widgets/library/m3_library_picker_dialog.dart';
import 'states/work_import_state.dart';

/// 作品导入视图模型
class WorkImportViewModel extends StateNotifier<WorkImportState> {
  final WorkService _workService;
  final ImageProcessor _imageProcessor;

  WorkImportViewModel(this._workService, this._imageProcessor)
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
      print('【WorkImportViewModel】准备从图库添加图片，传入context: $context');

      // 使用图库选择对话框选择图片，确保使用rootNavigator=false，避免关闭父对话框
      // 注意这里的context是WorkImportDialog的context
      print(
          '【WorkImportViewModel】将显示图库选择对话框，当前状态: ${state.isProcessing ? "处理中" : "空闲"}');
      final selectedItems = await M3LibraryPickerDialog.showMulti(
        context,
      );

      print(
          '【WorkImportViewModel】图库选择对话框关闭，选择结果: ${selectedItems?.length ?? 0}项');
      AppLogger.debug('选择图库项', data: {'count': selectedItems?.length ?? 0});

      // 如果没有选择任何项目，则直接返回
      if (selectedItems == null || selectedItems.isEmpty) {
        AppLogger.debug('没有选择图库项，返回');
        print('【WorkImportViewModel】没有选择图库项，操作取消');
        return;
      }

      state = state.copyWith(
        isProcessing: true,
        error: null,
      );
      print('【WorkImportViewModel】已设置isProcessing=true');

      // 将选择的图库项目转换为文件
      print('【WorkImportViewModel】处理选中的图库项...');
      final selectedFiles = selectedItems
          .map((item) => File(item.path))
          .where((file) => file.existsSync())
          .toList();

      if (selectedFiles.isEmpty) {
        print('【WorkImportViewModel】没有找到有效的图片文件');
        throw Exception('没有找到有效的图片文件');
      }

      // 添加文件并确保强制更新状态
      final updatedImages = [...state.images, ...selectedFiles];

      print('【WorkImportViewModel】准备更新状态: ${selectedFiles.length}个新图片');
      AppLogger.debug('从图库添加图片', data: {
        'selectedCount': selectedFiles.length,
        'totalCount': updatedImages.length
      });

      // 更新状态，设置选中索引为第一张新图片
      state = state.copyWith(
        images: updatedImages,
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
      state = state.copyWith(isProcessing: true, error: null);

      // 创建新的作品实体
      final work = WorkEntity(
        id: const Uuid().v4(),
        title: state.title.trim(),
        author: state.author?.trim() ?? '',
        style: state.style ?? WorkStyle.other,
        tool: state.tool ?? WorkTool.other,
        creationDate: state.creationDate ?? DateTime.now(),
        remark: state.remark?.trim(),
        createTime: DateTime.now(),
        updateTime: DateTime.now(),
      );

      // 执行导入操作
      await _workService.importWork(state.images, work);

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

    // 如果删除的是当前选中项，需要更新选中索引
    final newSelectedIndex = _calculateNewSelectedIndex(
      oldIndex: index,
      maxIndex: newImages.length - 1,
    );

    state = state.copyWith(
      images: newImages,
      selectedImageIndex: newSelectedIndex,
    );
  }

  /// 重新排序图片
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.images.length ||
        newIndex < 0 ||
        newIndex > state.images.length) return;

    final images = List<File>.from(state.images);
    final item = images.removeAt(oldIndex);
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    images.insert(adjustedNewIndex, item);

    state = state.copyWith(
      images: images,
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

  /// 设置创作日期
  void setCreationDate(DateTime? date) {
    state = state.copyWith(creationDate: date);
  }

  /// 设置备注
  void setRemark(String? remark) {
    state = state.copyWith(remark: remark?.trim() ?? '');
  }

  /// 设置画风
  void setStyle(WorkStyle? style) {
    if (style == null) return;
    state = state.copyWith(style: style);
  }

  /// 设置画风 (string version for compatibility)
  void setStyleByString(String? styleStr) {
    if (styleStr == null) return;

    final style = WorkStyle.values.firstWhere(
      (s) => s.value == styleStr,
      orElse: () => WorkStyle.other,
    );
    state = state.copyWith(style: style);
  }

  /// 设置标题
  void setTitle(String? title) {
    state = state.copyWith(title: title?.trim() ?? '');
  }

  /// 设置创作工具
  void setTool(WorkTool? tool) {
    if (tool == null) return;
    state = state.copyWith(tool: tool);
  }

  /// 设置创作工具 (string version for compatibility)
  void setToolByString(String? toolStr) {
    if (toolStr == null) return;

    final tool = WorkTool.values.firstWhere(
      (t) => t.value == toolStr,
      orElse: () => WorkTool.other,
    );
    state = state.copyWith(tool: tool);
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
