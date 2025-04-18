import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/work/work_service.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_image.dart';
import '../../infrastructure/logging/logger.dart';

/// 作品详情提供器
final workDetailProvider =
    StateNotifierProvider<WorkDetailNotifier, WorkDetailState>((ref) {
  final workService = ref.watch(workServiceProvider);
  return WorkDetailNotifier(workService);
});

/// 作品详情通知器
class WorkDetailNotifier extends StateNotifier<WorkDetailState> {
  final WorkService _workService;

  WorkDetailNotifier(this._workService) : super(const WorkDetailState());

  /// 取消编辑
  void cancelEditing() {
    state = state.copyWith(
      editingWork: state.work,
      isEditing: false,
      hasChanges: false,
    );
  }

  /// 完成编辑（从编辑模式切换回查看模式）
  void completeEditing() {
    // 确保已编辑的内容保持不变，只改变编辑状态
    // 修改此方法，确保work值也被更新为最新的editingWork值
    state = state.copyWith(
      work: state.editingWork, // 更新主要工作状态为编辑后的状态
      isEditing: false,
      hasChanges: false,
    );

    AppLogger.debug('编辑完成', tag: 'WorkDetailProvider', data: {
      'workId': state.work?.id,
      'title': state.work?.title,
      'tagCount': state.work?.tags.length,
      'isEditing': state.isEditing,
    });
  }

  /// 删除作品
  Future<bool> deleteWork(String workId) async {
    if (state.isSaving) return false;

    try {
      state = state.copyWith(isSaving: true, error: null);

      await _workService.deleteWork(workId);

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: '删除失败: $e',
      );
      return false;
    }
  }

  /// 进入编辑模式
  void enterEditMode() {
    if (state.work == null) return;
    startEditing();
  }

  /// 加载作品
  Future<void> loadWork(String workId) async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final work = await _workService.getWork(workId);
      state = state.copyWith(
        work: work,
        editingWork: work,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载失败: $e',
      );
    }
  }

  /// 加载作品详情
  Future<void> loadWorkDetails(String workId) async {
    await loadWork(workId);
  }

  /// 标记有更改
  void markAsChanged() {
    state = state.copyWith(hasChanges: true);
  }

  /// 保存作品
  Future<bool> saveChanges() async {
    if (state.isSaving || state.editingWork == null) return false;

    try {
      state = state.copyWith(isSaving: true, error: null);

      AppLogger.debug('保存作品前状态', tag: 'WorkDetailProvider', data: {
        'workId': state.editingWork!.id,
        'title': state.editingWork!.title,
        'tagCount': state.editingWork!.tags.length,
      });

      final updatedWork =
          await _workService.updateWorkEntity(state.editingWork!);

      AppLogger.debug('保存作品后状态', tag: 'WorkDetailProvider', data: {
        'workId': updatedWork.id,
        'title': updatedWork.title,
        'tagCount': updatedWork.tags.length,
      });

      state = state.copyWith(
        work: updatedWork,
        editingWork: updatedWork,
        isSaving: false,
        hasChanges: false,
      );

      loadWorkDetails(updatedWork.id);

      return true;
    } catch (e) {
      AppLogger.error('保存作品失败', tag: 'WorkDetailProvider', error: e);
      state = state.copyWith(
        isSaving: false,
        error: '保存失败: $e',
      );
      return false;
    }
  }

  /// 选择图片
  void selectImage(int index) {
    if (index < 0 || index >= (state.work?.images.length ?? 0)) return;

    state = state.copyWith(
      selectedImageIndex: index,
    );
  }

  /// 开始编辑
  void startEditing() {
    if (state.work == null) return;
    state = state.copyWith(
      editingWork: state.work,
      isEditing: true,
      hasChanges: false,
    );
  }

  /// 尝试恢复编辑状态
  Future<void> tryRestoreEditState(String workId) async {
    try {
      await loadWork(workId);
      startEditing();
    } catch (e) {
      // 恢复失败，不处理
    }
  }

  void updateWorkBasicInfo({
    String? title,
    String? author,
    String? remark,
    WorkStyle? style,
    WorkTool? tool,
    DateTime? creationDate,
  }) {
    if (state.editingWork == null) return;

    // 添加日志帮助调试
    AppLogger.debug('更新作品基本信息', tag: 'WorkDetailProvider', data: {
      'workId': state.editingWork!.id,
      'title': title ?? '[unchanged]',
      'author': author ?? '[unchanged]',
      'style': style?.value ?? '[unchanged]',
      'tool': tool?.value ?? '[unchanged]',
      'creationDate': creationDate?.toString() ?? '[unchanged]',
      'remark': remark?.toString() ?? '[unchanged]',
    });

    final updatedWork = WorkEntity(
      id: state.editingWork!.id,
      title: title ?? state.editingWork!.title,
      author: author ?? state.editingWork!.author,
      remark: remark ?? state.editingWork!.remark,
      style: style ?? state.editingWork!.style,
      tool: tool ?? state.editingWork!.tool,
      creationDate: creationDate ?? state.editingWork!.creationDate,
      createTime: state.editingWork!.createTime,
      updateTime: DateTime.now(),
      images: state.editingWork!.images,
      imageCount: state.editingWork!.imageCount,
      tags: state.editingWork!.tags,
      collectedChars: state.editingWork!.collectedChars,
    );

    state = state.copyWith(
      editingWork: updatedWork,
      hasChanges: true,
    );
  }

  /// 更新作品图片列表
  void updateWorkImages(List<WorkImage> images) {
    if (state.editingWork == null) return;

    final updatedWork = state.editingWork!.copyWith(
      images: images,
      imageCount: images.length,
      updateTime: DateTime.now(),
    );

    state = state.copyWith(
      editingWork: updatedWork,
      hasChanges: true,
    );
  }

  /// 更新作品标签
  void updateWorkTags(List<String> tags) {
    if (state.editingWork == null) return;

    // 添加日志帮助调试
    AppLogger.debug('更新作品标签', tag: 'WorkDetailProvider', data: {
      'workId': state.editingWork!.id,
      'oldTagCount': state.editingWork!.tags.length,
      'newTagCount': tags.length,
      'oldTags': state.editingWork!.tags,
      'newTags': tags,
    });

    final updatedWork = state.editingWork!.copyWith(
      tags: tags,
      updateTime: DateTime.now(),
    );

    state = state.copyWith(
      editingWork: updatedWork,
      hasChanges: true,
    );
  }
}

/// 作品详情状态
class WorkDetailState {
  final WorkEntity? work;
  final WorkEntity? editingWork;
  final bool isLoading;
  final bool isSaving;
  final bool isEditing;
  final bool hasChanges;
  final int historyIndex;
  final int selectedImageIndex;
  final String? error;

  const WorkDetailState({
    this.work,
    this.editingWork,
    this.isLoading = false,
    this.isSaving = false,
    this.isEditing = false,
    this.hasChanges = false,
    this.historyIndex = -1,
    this.selectedImageIndex = 0,
    this.error,
  });

  WorkDetailState copyWith({
    WorkEntity? work,
    WorkEntity? editingWork,
    bool? isLoading,
    bool? isSaving,
    bool? isEditing,
    bool? hasChanges,
    int? historyIndex,
    int? selectedImageIndex,
    String? error,
  }) {
    return WorkDetailState(
      work: work ?? this.work,
      editingWork: editingWork ?? this.editingWork,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isEditing: isEditing ?? this.isEditing,
      hasChanges: hasChanges ?? this.hasChanges,
      historyIndex: historyIndex ?? this.historyIndex,
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
      error: error,
    );
  }
}
