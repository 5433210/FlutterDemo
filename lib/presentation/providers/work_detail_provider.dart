import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/commands/work_edit_commands.dart';
import '../../application/providers/service_providers.dart';
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

  /// 取消编辑模式，放弃所有更改
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

        // 如果需要，可以在这里添加其他清理工作

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

  /// 完成编辑模式 - 新增此方法，由UI层在保存完成并显示反馈后调用
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
      await workService.deleteWork(state.work!.id!);

      // 确保清除任何编辑状态
      await _clearEditState(state.work!.id!);

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

      // 将当前作品复制一份作为编辑副本
      final editingWork = state.work;

      // 重置标签页到基本信息页
      _ref.read(workDetailTabIndexProvider.notifier).state = 0;

      // 更新状态为编辑模式
      state = state.copyWith(
        isEditing: true,
        editingWork: editingWork,
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

  /// 执行编辑命令
  Future<void> executeCommand(WorkEditCommand command) async {
    if (!state.isEditing || state.editingWork == null) return;

    try {
      AppLogger.info('执行编辑命令',
          tag: 'WorkDetailNotifier', data: {'command': command.description});

      // 执行命令
      final updatedWork = await command.execute(state.editingWork!);

      // 当执行新命令时，需要丢弃当前位置之后的所有命令
      List<WorkEditCommand> newHistory;
      if (state.historyIndex < 0) {
        // 没有历史记录，创建新列表
        newHistory = [command];
      } else {
        // 有历史记录，保留当前位置之前的命令
        newHistory = List<WorkEditCommand>.from(
            state.commandHistory!.sublist(0, state.historyIndex + 1));
        newHistory.add(command);
      }

      // 更新状态
      state = state.copyWith(
        editingWork: updatedWork,
        hasChanges: true,
        commandHistory: newHistory,
        historyIndex: newHistory.length - 1,
      );

      // 保存编辑状态
      await _saveEditState();

      AppLogger.info('命令执行完成',
          tag: 'WorkDetailNotifier', data: {'command': command.description});
    } catch (e, stack) {
      AppLogger.error(
        '执行编辑命令失败',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'command': command.description},
      );

      // 可以考虑在这里添加失败的视觉反馈
    }
  }

  /// 获取命令历史副本
  List<WorkEditCommand>? getCommandHistory() {
    return state.commandHistory != null
        ? List.from(state.commandHistory!)
        : null;
  }

  /// 加载作品详情
  Future<void> loadWorkDetails(String workId) async {
    // 如果已经在加载，防止重复触发
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final workService = _ref.read(workServiceProvider);
      final work = await workService.getWorkEntity(workId);

      if (work == null) {
        state = state.copyWith(isLoading: false, error: '作品未找到');
        return;
      }

      state = state.copyWith(
        isLoading: false,
        work: work,
      );

      // 加载后尝试恢复编辑状态
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

  /// 重做操作
  Future<void> redo() async {
    if (!state.canRedo) return;

    try {
      AppLogger.info('执行重做操作', tag: 'WorkDetailNotifier');

      // 添加额外检查，确保索引有效
      if (state.commandHistory == null ||
          state.commandHistory!.isEmpty ||
          state.historyIndex + 1 >= state.commandHistory!.length) {
        AppLogger.warning('无效的重做操作：命令历史为空或索引无效', tag: 'WorkDetailNotifier');
        return;
      }

      // 获取要重做的命令
      final command = state.commandHistory![state.historyIndex + 1];

      // 执行命令
      final updatedWork = await command.execute(state.editingWork!);

      // 更新状态
      state = state.copyWith(
        editingWork: updatedWork,
        historyIndex: state.historyIndex + 1,
      );

      // 保存编辑状态
      await _saveEditState();

      AppLogger.info('重做操作完成',
          tag: 'WorkDetailNotifier', data: {'command': command.description});
    } catch (e, stack) {
      AppLogger.error(
        '重做操作失败',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
      );
    }
  }

  /// 保存更改
  Future<bool> saveChanges() async {
    if (!state.isEditing || !state.hasChanges || state.editingWork == null) {
      return false;
    }

    try {
      // 将状态设置为保存中
      state = state.copyWith(isSaving: true);

      // 日志 - 开始保存
      AppLogger.debug('开始保存编辑后的作品',
          tag: 'WorkDetailProvider', data: {'workId': state.editingWork!.id});

      // 获取服务
      final workService = _ref.read(workServiceProvider);

      // 保存更改 - 直接使用 updateWorkEntity
      await workService.updateWorkEntity(state.editingWork!);

      // 清除编辑状态 - 保存成功后
      await _clearEditState(state.editingWork!.id);

      // 保留当前编辑模式状态，避免立即设置为false导致页面切换
      // 将返回false的逻辑移到UI层处理
      final savedWork = state.editingWork;

      // 更新状态，但保持编辑模式，让UI层控制退出编辑模式的时机
      state = state.copyWith(
        work: savedWork, // 更新主作品为已编辑的版本
        hasChanges: false,
        isSaving: false,
        // 不立即重置这些状态，由UI层控制
        // isEditing: false,
        // editingWork: null,
        // commandHistory: null,
        // historyIndex: -1,
      );

      AppLogger.info('编辑更改已保存，等待UI反馈',
          tag: 'WorkDetailProvider', data: {'workId': savedWork!.id});

      return true;
    } catch (e, stack) {
      AppLogger.error(
        '保存编辑更改失败',
        tag: 'WorkDetailProvider',
        error: e,
        stackTrace: stack,
        data: {'workId': state.editingWork?.id},
      );

      // 即使失败也要重置保存中状态
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

      AppLogger.info('检测到未完成的编辑会话',
          tag: 'WorkDetailNotifier', data: {'workId': workId});

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
          // 命令历史无法从持久化存储中恢复，因为命令包含服务依赖
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

  /// 撤销操作
  Future<void> undo() async {
    if (!state.canUndo) return;

    try {
      AppLogger.info('执行撤销操作', tag: 'WorkDetailNotifier');

      // 获取要撤销的命令
      final command = state.commandHistory![state.historyIndex];

      // 撤销命令
      final updatedWork = await command.undo(state.editingWork!);

      // 更新状态
      state = state.copyWith(
        editingWork: updatedWork,
        historyIndex: state.historyIndex - 1,
      );

      // 保存编辑状态
      await _saveEditState();

      AppLogger.info('撤销操作完成',
          tag: 'WorkDetailNotifier', data: {'command': command.description});
    } catch (e, stack) {
      AppLogger.error(
        '撤销操作失败',
        tag: 'WorkDetailNotifier',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // 在 WorkDetailNotifier 类中添加方法，实时更新基本信息
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

    // 只更新提供的字段
    final updatedWork = currentWork.copyWith(
      name: name ?? currentWork.name,
      author: author ?? currentWork.author,
      style: style ?? currentWork.style,
      tool: tool ?? currentWork.tool,
      creationDate: creationDate ?? currentWork.creationDate,
      remark: remark ?? currentWork.remark,
    );

    // 检查是否有实际变化
    final hasChanged = updatedWork != currentWork;

    if (hasChanged) {
      state = state.copyWith(
        editingWork: updatedWork,
        hasChanges: true,
      );

      AppLogger.debug('基本信息已更新',
          tag: 'WorkDetailProvider', data: {'field': 'basicInfo'});
    }
  }

  /// 直接更新标签，不使用命令模式
  void updateWorkTags(List<String> updatedTags) {
    if (state.editingWork == null) return;

    final currentWork = state.editingWork!;

    // 创建新的元数据对象，确保tags数组被深拷贝
    final updatedMetadata = WorkMetadata(
      tags: List<String>.from(updatedTags), // 确保深拷贝
    );

    // 记录详细日志，显示更新前后的标签
    AppLogger.debug('更新作品标签', tag: 'WorkDetailProvider', data: {
      'oldTags': currentWork.metadata?.tags,
      'newTags': updatedTags,
      'workId': currentWork.id,
    });

    // 创建带有更新后元数据的新作品对象
    final updatedWork = currentWork.copyWith(metadata: updatedMetadata);

    // 更新状态
    state = state.copyWith(
      editingWork: updatedWork,
      hasChanges: true, // 标记有更改
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
          state.editingWork!.id!, state);

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
    // 每30秒自动保存一次
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

  // 检查是否可以重做操作 - 添加更严格的检查
  bool get canRedo =>
      isEditing &&
      commandHistory != null &&
      commandHistory!.isNotEmpty && // 确保命令历史不为空
      historyIndex >= -1 && // 确保索引有效
      historyIndex < commandHistory!.length - 1; // 确保有更多命令可重做

  // 检查是否可以撤销操作 - 添加更严格的检查
  bool get canUndo =>
      isEditing &&
      commandHistory != null &&
      commandHistory!.isNotEmpty && // 确保命令历史不为空
      historyIndex >= 0; // 确保有命令可撤销

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
