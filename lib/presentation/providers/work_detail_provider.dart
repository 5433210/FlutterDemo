import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/value_objects/work/work_entity.dart';
import '../../infrastructure/logging/logger.dart';

/// Provider for the current image index in a work
final currentWorkImageIndexProvider = StateProvider<int>((ref) {
  return 0;
});

final workDetailProvider =
    StateNotifierProvider.autoDispose<WorkDetailNotifier, WorkDetailState>(
  (ref) => WorkDetailNotifier(ref),
);

class WorkDetailNotifier extends StateNotifier<WorkDetailState> {
  final Ref _ref;

  WorkDetailNotifier(this._ref) : super(WorkDetailState());

  Future<bool> deleteWork() async {
    if (state.work?.id == null) return false;

    try {
      state = state.copyWith(isDeleting: true);

      final workService = _ref.read(workServiceProvider);
      await workService.deleteWork(state.work!.id!);

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
}

class WorkDetailState {
  final bool isLoading;
  final WorkEntity? work;
  final String? error;
  final bool isDeleting;

  WorkDetailState({
    this.isLoading = false,
    this.work,
    this.error,
    this.isDeleting = false,
  });

  WorkDetailState copyWith({
    bool? isLoading,
    WorkEntity? work,
    String? error,
    bool? isDeleting,
  }) {
    return WorkDetailState(
      isLoading: isLoading ?? this.isLoading,
      work: work ?? this.work,
      error: error ?? this.error,
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }
}
