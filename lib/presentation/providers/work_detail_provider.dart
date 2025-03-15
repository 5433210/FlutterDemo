import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/work/work_service.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/models/work/work_entity.dart';

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
    state = state.copyWith(
      isEditing: false,
      hasChanges: false,
    );
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

      final updatedWork =
          await _workService.updateWorkEntity(state.editingWork!);

      state = state.copyWith(
        work: updatedWork,
        editingWork: updatedWork,
        isSaving: false,
        hasChanges: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: '保存失败: $e',
      );
      return false;
    }
  }

  /// 选择图片
  void selectImage(int index) {
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

  /// 更新作品基本信息
  void updateWorkBasicInfo({
    String title = '',
    String author = '',
    String remark = '',
    WorkStyle? style,
    WorkTool? tool,
    DateTime? creationDate,
  }) {
    if (state.editingWork == null) return;

    final updatedWork = WorkEntity(
      id: state.editingWork!.id,
      title: title.isEmpty ? state.editingWork!.title : title,
      author: author.isEmpty ? state.editingWork!.author : author,
      remark: remark.isEmpty ? state.editingWork!.remark : remark,
      style: style ?? state.editingWork!.style,
      tool: tool ?? state.editingWork!.tool,
      creationDate: creationDate ?? state.editingWork!.creationDate,
      createTime: state.editingWork!.createTime,
      updateTime: DateTime.now(),
      images: state.editingWork!.images,
    );

    state = state.copyWith(
      editingWork: updatedWork,
      hasChanges: true,
    );
  }

  /// 更新作品标签
  void updateWorkTags(List<String> tags) {
    if (state.editingWork == null) return;

    final updatedWork = WorkEntity(
      id: state.editingWork!.id,
      title: state.editingWork!.title,
      author: state.editingWork!.author,
      remark: state.editingWork!.remark,
      style: state.editingWork!.style,
      tool: state.editingWork!.tool,
      creationDate: state.editingWork!.creationDate,
      createTime: state.editingWork!.createTime,
      updateTime: DateTime.now(),
      images: state.editingWork!.images,
      tags: tags,
      collectedChars: state.editingWork!.collectedChars,
      imageCount: state.editingWork!.imageCount,
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
