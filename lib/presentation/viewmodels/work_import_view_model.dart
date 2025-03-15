import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../application/services/work/work_service.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/models/work/work_entity.dart';
import '../../infrastructure/image/image_processor.dart';
import 'states/work_import_state.dart';

/// 作品导入视图模型
class WorkImportViewModel extends StateNotifier<WorkImportState> {
  final WorkService _workService;
  final ImageProcessor _imageProcessor;

  WorkImportViewModel(this._workService, this._imageProcessor)
      : super(WorkImportState.initial());

  /// 判断是否可以保存
  bool get canSubmit {
    return state.images.isNotEmpty &&
        state.title.trim().isNotEmpty &&
        !state.isProcessing;
  }

  /// 添加图片
  Future<void> addImages(List<File> files) async {
    if (files.isEmpty) return;

    try {
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

      state = state.copyWith(isProcessing: false);
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

  /// 重新排序
  void reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= state.images.length ||
        newIndex < 0 ||
        newIndex > state.images.length) return;

    final images = List<File>.from(state.images);
    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);

    state = state.copyWith(
      images: images,
      selectedImageIndex: _calculateNewSelectedIndex(
        oldIndex: oldIndex,
        newIndex: newIndex,
        maxIndex: images.length - 1,
      ),
    );
  }

  /// 重置
  void reset() {
    state = WorkImportState.initial();
  }

  /// 选择图片
  void selectImage(int index) {
    if (index < 0 || index >= state.images.length) return;
    state = state.copyWith(selectedImageIndex: index);
  }

  /// 设置作者
  void setAuthor(String author) {
    state = state.copyWith(author: author.trim());
  }

  /// 设置创作日期
  void setCreationDate(DateTime date) {
    state = state.copyWith(creationDate: date);
  }

  /// 设置备注
  void setRemark(String remark) {
    state = state.copyWith(remark: remark.trim());
  }

  /// 设置画风
  void setStyle(String? styleStr) {
    if (styleStr == null) return;
    final style = WorkStyle.values.firstWhere(
      (s) => s.toString().split('.').last == styleStr,
      orElse: () => WorkStyle.other,
    );
    state = state.copyWith(style: style);
  }

  /// 设置标题
  void setTitle(String title) {
    state = state.copyWith(title: title.trim());
  }

  /// 设置创作工具
  void setTool(String? toolStr) {
    if (toolStr == null) return;
    final tool = WorkTool.values.firstWhere(
      (t) => t.toString().split('.').last == toolStr,
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
