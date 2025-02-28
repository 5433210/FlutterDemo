import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/value_objects/practice/practice_entity.dart';
import '../../domain/value_objects/practice/practice_layer.dart';
import '../../infrastructure/logging/logger.dart';

final practiceDetailProvider =
    StateNotifierProvider<PracticeDetailNotifier, PracticeDetailState>(
  (ref) => PracticeDetailNotifier(ref),
);

class PracticeDetailNotifier extends StateNotifier<PracticeDetailState> {
  final Ref _ref;

  PracticeDetailNotifier(this._ref) : super(PracticeDetailState());

  /// 删除字帖
  Future<bool> deletePractice(String id) async {
    try {
      state = state.copyWith(isLoading: true);

      final service = _ref.read(practiceServiceProvider);
      final result = await service.deletePractice(id);

      state = state.copyWith(isLoading: false);
      return result;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete practice',
        tag: 'PracticeDetailNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// 获取字帖
  Future<PracticeEntity?> getPractice(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final service = _ref.read(practiceServiceProvider);
      final practice = await service.getPractice(id);

      state = state.copyWith(
        isLoading: false,
        practice: practice,
      );
      return practice;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get practice',
        tag: 'PracticeDetailNotifier',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// 更新图层状态
  void updateLayer(PracticeLayer layer) {
    if (state.practice == null) return;

    final currentPractice = state.practice!;
    final pageIndex = 0; // 简化示例，假设只操作第一页

    // 获取当前页面
    final currentPages = currentPractice.pages;
    if (pageIndex >= currentPages.length) return;

    final currentPage = currentPages[pageIndex];

    // 更新该页面的图层
    final updatedLayers = currentPage.layers.map((l) {
      if (l.index == layer.index) {
        return layer; // 使用新的图层替换
      }
      return l;
    }).toList();

    // 创建更新后的页面
    final updatedPage = currentPage.copyWith(layers: updatedLayers);

    // 创建更新后的页面列表
    final updatedPages = currentPages.toList();
    updatedPages[pageIndex] = updatedPage;

    // 更新状态
    state = state.copyWith(
      practice: currentPractice.copyWith(pages: updatedPages),
    );
  }
}

class PracticeDetailState {
  final bool isLoading;
  final PracticeEntity? practice;
  final String? error;

  PracticeDetailState({
    this.isLoading = false,
    this.practice,
    this.error,
  });

  PracticeDetailState copyWith({
    bool? isLoading,
    PracticeEntity? practice,
    String? error,
  }) {
    return PracticeDetailState(
      isLoading: isLoading ?? this.isLoading,
      practice: practice ?? this.practice,
      error: error ?? this.error,
    );
  }
}
