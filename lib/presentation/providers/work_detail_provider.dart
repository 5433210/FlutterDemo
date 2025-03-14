import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/commands/work_edit_command.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import '../../domain/models/work/work_entity.dart';
import '../../infrastructure/logging/logger.dart';

/// Provider for the current image index in a work
final currentWorkImageIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final workDetailProvider =
    StateNotifierProvider.autoDispose<WorkDetailNotifier, WorkDetailState>(
  (ref) => WorkDetailNotifier(ref),
);

/// Provider for the current tab index in work detail page
final workDetailTabIndexProvider = StateProvider<int>((ref) {
  return 0; // 默认显示基本信息标签页
});

class WorkDetailNotifier extends StateNotifier<WorkDetailState> {
  final Ref _ref;

  // 自动保存计时器
  Timer? _autoSaveTimer;

  WorkDetailNotifier(this._ref) : super(WorkDetailState()) {
    // 在创建时尝试恢复编辑状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAutoSave();
    });
  }

  /// 取消编辑模式
  Future<void> cancelEditing() async {
    if (state.isEditing) {
      try {
        // 清除编辑状态
        await _clearEditState(state.work?.id);

        // 重置状态
        state = state.copyWith(
          isEditing: false,
          editingWork: null,
          commandHistory: null,
          historyIndex: -1,
          hasChanges: false,
        );

        // 重置标签页到基本信息页
        _ref.read(workDetailTabIndexProvider.notifier).state = 0;

        AppLogger.info('已取消编辑模式', tag: 'WorkDetailNotifier');
      } catch (e, stack) {
        AppLogger.error(
          '取消编辑模式失败',
          tag: 'WorkDetailNotifier',
          error: e,
          stackTrace: stack,
        );
      }
    }
  }

  /// 完成编辑模式
  void completeEditing() {
    if (state.isEditing && !state.hasChanges) {
      state = state.copyWith(
        isEditing: false,
        editingWork: null,
        commandHistory: null,
        historyIndex: -1,
      );

      AppLogger.debug('完成编辑模式', tag: 'WorkDetailProvider');
    }
  }

  /// 删除作品
  Future<bool> deleteWork() async {
    if (state.work?.id == null) return false;

    try {
      state = state.copyWith(isDeleting: true);

      final workService = _ref.read(workServiceProvider);
      await workService.deleteWork(state.work!.id);

      // 确保清除任何编辑状态
      await _clearEditState(state.work!.id);

      state = state.copyWith(isDeleting: false);
      return true;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete work',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'workId': state.work?.id},
      );

      state = state.copyWith(
        isDeleting: false,
        error: '删除作品失败: ${e.toString()}',
      );
      return false;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// 进入编辑模式
  Future<void> enterEditMode() async {
    if (state.isEditing || state.work == null) return;

    try {
      AppLogger.info('进入编辑模式',
          tag: 'WorkDetailNotifier', data: {'workId': state.work!.id});

      // 重置标签页到基本信息页
      _ref.read(workDetailTabIndexProvider.notifier).state = 0;

      // 更新状态为编辑模式
      state = state.copyWith(
        isEditing: true,
        editingWork: state.work,
        commandHistory: [],
        historyIndex: -1, // 初始时没有历史记录
        hasChanges: false,
      );

      AppLogger.info('已进入编辑模式', tag: 'WorkDetailNotifier');
    } catch (e, stack) {
      AppLogger.error(
        '进入编辑模式失败',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'workId': state.work?.id},
      );

      // 还原状态
      cancelEditing();
    }
  }

  /// 加载作品详情
  Future<void> loadWorkDetails(String workId) async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final workService = _ref.read(workServiceProvider);
      final work = await workService.getWork(workId);

      if (work == null) {
        state = state.copyWith(isLoading: false, error: '作品未找到');
        return;
      }

      state = state.copyWith(
        isLoading: false,
        work: work,
      );

      await tryRestoreEditState(workId);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load work details',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );

      state = state.copyWith(
        isLoading: false,
        error: '加载作品详情失败: ${e.toString()}',
      );
    }
  }

  /// 标记状态已更改
  void markAsChanged() {
    if (state.isEditing && state.editingWork != null && !state.hasChanges) {
      state = state.copyWith(hasChanges: true);
      AppLogger.debug('表单状态已标记为已更改', tag: 'WorkDetailProvider');
    }
  }

  /// 保存更改
  Future<bool> saveChanges() async {
    if (!state.isEditing || !state.hasChanges || state.editingWork == null) {
      return false;
    }

    try {
      state = state.copyWith(isSaving: true);

      AppLogger.debug('开始保存作品',
          tag: 'WorkDetailProvider', data: {'workId': state.editingWork!.id});

      final workService = _ref.read(workServiceProvider);
      final workToSave = state.editingWork!;

      await workService.updateWorkEntity(workToSave);

      await _clearEditState(workToSave.id);

      state = state.copyWith(
        work: workToSave,
        hasChanges: false,
        isSaving: false,
      );

      AppLogger.info('编辑更改已保存',
          tag: 'WorkDetailProvider', data: {'workId': workToSave.id});

      return true;
    } catch (e, stack) {
      AppLogger.error(
        '保存编辑更改失败',
        tag: 'WorkDetailProvider',
        error: e,
        stackTrace: stack,
        data: {'workId': state.editingWork?.id},
      );

      state = state.copyWith(
        isSaving: false,
        error: '保存更改失败: ${e.toString()}',
      );

      return false;
    }
  }

  /// 尝试恢复编辑状态
  Future<bool> tryRestoreEditState(String workId) async {
    try {
      final stateRestorationService =
          _ref.read(stateRestorationServiceProvider);

      // 检查是否有未完成的编辑会话
      final hasUnfinishedSession =
          await stateRestorationService.hasUnfinishedEditSession(workId);

      if (!hasUnfinishedSession) {
        return false;
      }

      // 加载保存的编辑状态
      final savedState =
          await stateRestorationService.restoreWorkEditState(workId);

      if (savedState != null && savedState.editingWork != null) {
        // 更新状态
        state = state.copyWith(
          isEditing: savedState.isEditing,
          editingWork: savedState.editingWork,
          hasChanges: savedState.hasChanges,
          historyIndex: savedState.historyIndex,
          commandHistory: [], // 创建新的空命令历史
        );

        // 重置标签页到基本信息页
        _ref.read(workDetailTabIndexProvider.notifier).state = 0;

        AppLogger.info('已恢复编辑状态',
            tag: 'WorkDetailNotifier', data: {'workId': workId});

        return true;
      }
    } catch (e, stack) {
      AppLogger.error(
        '恢复编辑状态失败',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
    }

    return false;
  }

  // 实时更新基本信息
  void updateWorkBasicInfo({
    String? name,
    String? author,
    WorkStyle? style,
    WorkTool? tool,
    DateTime? creationDate,
    String? remark,
  }) {
    if (state.editingWork == null) return;

    final currentWork = state.editingWork!;
    final updatedWork = currentWork.copyWith(
      title: name ?? currentWork.title,
      author: author ?? currentWork.author,
      style: style ?? currentWork.style,
      tool: tool ?? currentWork.tool,
      creationDate: creationDate ?? currentWork.creationDate,
      remark: remark ?? currentWork.remark,
    );

    if (updatedWork != currentWork) {
      state = state.copyWith(
        editingWork: updatedWork,
        hasChanges: true,
      );

      AppLogger.debug('基本信息已更新',
          tag: 'WorkDetailProvider', data: {'field': 'basicInfo'});
    }
  }

  /// 直接更新标签
  void updateWorkTags(List<String> updatedTags) {
    if (state.editingWork == null) return;

    final currentWork = state.editingWork!;
    AppLogger.debug('更新作品标签', tag: 'WorkDetailProvider', data: {
      'oldTags': currentWork.tags,
      'newTags': updatedTags,
      'workId': currentWork.id,
    });

    final updatedWork = currentWork.copyWith(tags: updatedTags);
    state = state.copyWith(
      editingWork: updatedWork,
      hasChanges: true,
    );
  }

  /// 清除编辑状态
  Future<void> _clearEditState(String? workId) async {
    if (workId == null) return;

    try {
      final stateRestorationService =
          _ref.read(stateRestorationServiceProvider);
      await stateRestorationService.clearWorkEditState(workId);

      AppLogger.debug('编辑状态已清除',
          tag: 'WorkDetailNotifier', data: {'workId': workId});
    } catch (e, stack) {
      AppLogger.error(
        '清除编辑状态失败',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'workId': workId},
      );
    }
  }

  /// 保存编辑状态
  Future<void> _saveEditState() async {
    if (!state.isEditing || state.editingWork?.id == null) return;

    try {
      final stateRestorationService =
          _ref.read(stateRestorationServiceProvider);
      await stateRestorationService.saveWorkEditState(
          state.editingWork!.id, state);

      AppLogger.debug('编辑状态已保存',
          tag: 'WorkDetailNotifier', data: {'workId': state.editingWork!.id});
    } catch (e, stack) {
      AppLogger.error(
        '保存编辑状态失败',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'workId': state.editingWork?.id},
      );
    }
  }

  /// 设置自动保存计时器
  void _setupAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.isEditing && state.hasChanges && !state.isSaving) {
        _saveEditState();
      }
    });
  }
}

class WorkDetailState {
  final bool isLoading;
  final WorkEntity? work;
  final String? error;
  final bool isDeleting;

  // 编辑模式相关字段
  final bool isEditing;
  final WorkEntity? editingWork;
  final bool hasChanges;
  final List<WorkEditCommand>? commandHistory;
  final int historyIndex;
  final bool isSaving; // 添加保存中状态

  WorkDetailState({
    this.isLoading = false,
    this.work,
    this.error,
    this.isDeleting = false,
    this.isEditing = false,
    this.editingWork,
    this.hasChanges = false,
    this.commandHistory,
    this.historyIndex = -1,
    this.isSaving = false,
  });

  WorkDetailState copyWith({
    bool? isLoading,
    WorkEntity? work,
    String? error,
    bool? isDeleting,
    bool? isEditing,
    WorkEntity? editingWork,
    bool? hasChanges,
    List<WorkEditCommand>? commandHistory,
    int? historyIndex,
    bool? isSaving,
  }) {
    return WorkDetailState(
      isLoading: isLoading ?? this.isLoading,
      work: work ?? this.work,
      error: error ?? this.error,
      isDeleting: isDeleting ?? this.isDeleting,
      isEditing: isEditing ?? this.isEditing,
      editingWork: editingWork ?? this.editingWork,
      hasChanges: hasChanges ?? this.hasChanges,
      commandHistory: commandHistory ?? this.commandHistory,
      historyIndex: historyIndex ?? this.historyIndex,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
