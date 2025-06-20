import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/work/work_service.dart';
import '../../domain/models/character/character_entity.dart';
import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_image.dart';
import '../../infrastructure/logging/logger.dart';
import 'events/work_events_provider.dart';

/// 作品详情提供器
final workDetailProvider =
    StateNotifierProvider<WorkDetailNotifier, WorkDetailState>((ref) {
  final workService = ref.watch(workServiceProvider);
  return WorkDetailNotifier(workService, ref);
});

/// 作品详情通知器
class WorkDetailNotifier extends StateNotifier<WorkDetailState> {
  final WorkService _workService;
  final Ref _ref;

  WorkDetailNotifier(this._workService, this._ref)
      : super(const WorkDetailState());

  /// 将字符添加到作品关联字符列表
  /// 添加单个字符到作品关联字符列表
  Future<void> addCollectedChar(CharacterEntity char) async {
    await addCollectedChars([char]);
  }

  /// 添加多个字符到作品关联字符列表
  Future<void> addCollectedChars(List<CharacterEntity> chars) async {
    if (state.work == null || chars.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      var updatedWork = state.work!;
      for (final char in chars) {
        updatedWork = updatedWork.addCollectedChar(char);
      }

      // 保存更新后的作品
      final savedWork = await _workService.updateWorkEntity(updatedWork);

      // 更新状态
      state = state.copyWith(
        work: savedWork,
        editingWork: state.isEditing ? savedWork : state.editingWork,
        isLoading: false,
      );

      AppLogger.debug('字符已添加到作品关联列表', tag: 'WorkDetailProvider', data: {
        'workId': savedWork.id,
        'addedCharCount': chars.length,
        'collectedCharsCount': savedWork.collectedChars.length,
      });
    } catch (e) {
      AppLogger.error('添加字符到作品失败', tag: 'WorkDetailProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: '操作失败: $e',
      );
    }
  }

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

    AppLogger.debug('Editing completed', tag: 'WorkDetailProvider', data: {
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

      // 发送删除事件通知
      _ref.read(workDeletedNotifierProvider.notifier).state = workId;

      // 清空删除事件通知状态
      Future.delayed(const Duration(milliseconds: 100), () {
        _ref.read(workDeletedNotifierProvider.notifier).state = null;
      });

      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Delete failed: $e',
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
        error: 'Loading failed: $e',
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

      AppLogger.debug('Work state before saving',
          tag: 'WorkDetailProvider',
          data: {
            'workId': state.editingWork!.id,
            'title': state.editingWork!.title,
            'tagCount': state.editingWork!.tags.length,
          });

      final updatedWork =
          await _workService.updateWorkEntity(state.editingWork!);

      AppLogger.debug('Work state after saving',
          tag: 'WorkDetailProvider',
          data: {
            'workId': updatedWork.id,
            'title': updatedWork.title,
            'tagCount': updatedWork.tags.length,
          });

      // 保存后直接更新状态，不重新加载
      AppLogger.debug(
        'Work saved successfully',
        tag: 'WorkDetailProvider',
        data: {
          'workId': updatedWork.id,
          'title': updatedWork.title,
          'tagCount': updatedWork.tags.length,
          'collectedCharsCount': updatedWork.collectedChars.length,
        },
      );

      state = state.copyWith(
        work: updatedWork,
        editingWork: updatedWork,
        isSaving: false,
        hasChanges: false,
      );

      return true;
    } catch (e) {
      AppLogger.error('Failed to save work',
          tag: 'WorkDetailProvider', error: e);
      state = state.copyWith(
        isSaving: false,
        error: 'Save failed: $e',
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

  /// 切换收藏状态
  Future<void> toggleFavorite() async {
    if (state.work == null) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final workId = state.work!.id;

      // 调用服务切换收藏状态
      final updatedWork = await _workService.toggleFavorite(workId);

      // 更新状态
      state = state.copyWith(
        work: updatedWork,
        editingWork: state.isEditing ? updatedWork : state.editingWork,
        isLoading: false,
      );

      AppLogger.debug('收藏状态已切换', tag: 'WorkDetailProvider', data: {
        'workId': workId,
        'isFavorite': updatedWork.isFavorite,
      });
    } catch (e) {
      AppLogger.error('切换收藏状态失败', tag: 'WorkDetailProvider', error: e);
      state = state.copyWith(
        isLoading: false,
        error: '操作失败: $e',
      );
    }
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
    String? style,
    String? tool,
    // DateTime? creationDate, // Removed as per requirements
  }) {
    if (state.editingWork == null) return;

    // Add logs to help with debugging
    AppLogger.debug('Updating work basic info',
        tag: 'WorkDetailProvider',
        data: {
          'workId': state.editingWork!.id,
          'title': title ?? '[unchanged]',
          'author': author ?? '[unchanged]',
          'style': style ?? '[unchanged]',
          'tool': tool ?? '[unchanged]',
          // 'creationDate': creationDate?.toString() ?? '[unchanged]',
          'remark': remark?.toString() ?? '[unchanged]',
        });
    final updatedWork = WorkEntity(
      id: state.editingWork!.id,
      title: title ?? state.editingWork!.title,
      author: author ?? state.editingWork!.author,
      remark: remark ?? state.editingWork!.remark,
      style: style ?? state.editingWork!.style,
      tool: tool ?? state.editingWork!.tool,
      // creationDate: creationDate ?? state.editingWork!.creationDate, // Removed field
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
