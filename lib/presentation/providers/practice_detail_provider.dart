import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/repository_providers.dart';
import '../../application/services/practice/practice_service.dart';
import '../../domain/models/practice/practice_entity.dart';
import '../../domain/models/practice/practice_layer.dart';
import '../../domain/models/practice/practice_page.dart';

/// 练习详情Provider
final practiceDetailProvider = StateNotifierProvider.family<
    PracticeDetailNotifier, PracticeDetailState, String>(
  (ref, id) {
    final service =
        PracticeService(repository: ref.watch(practiceRepositoryProvider));
    return PracticeDetailNotifier(service: service)..loadPractice(id);
  },
);

/// 练习详情Notifier
class PracticeDetailNotifier extends StateNotifier<PracticeDetailState> {
  final PracticeService _service;
  String? _currentId;

  PracticeDetailNotifier({
    required PracticeService service,
  })  : _service = service,
        super(const PracticeDetailState());

  /// 添加图层
  Future<void> addLayer(int pageIndex, PracticeLayer layer) async {
    if (state.practice == null) return;
    try {
      final page =
          state.practice!.pages.firstWhere((p) => p.index == pageIndex);
      final updatedPage = page.addLayer(layer);
      final updated = state.practice!.updatePage(updatedPage);
      await _service.updatePractice(updated);
      state = state.copyWith(practice: updated);
    } catch (e) {
      state = state.copyWith(error: '添加图层失败: $e');
    }
  }

  /// 添加页面
  Future<void> addPage(PracticePage page) async {
    if (state.practice == null) return;

    try {
      final updated = state.practice!.addPage(page);
      await _service.updatePractice(updated);
      state = state.copyWith(practice: updated);
    } catch (e) {
      state = state.copyWith(error: '添加页面失败: $e');
    }
  }

  Future<void> deletePractice(String id) async {
    try {
      state = state.copyWith(isLoading: true);
      await _service.deletePractice(id);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  /// 加载练习
  Future<void> loadPractice(String id) async {
    if (id == _currentId && state.practice != null) return;

    state = state.copyWith(isLoading: true, error: null);
    _currentId = id;

    try {
      final practice = await _service.getPractice(id);
      if (practice == null) {
        state = state.copyWith(
          isLoading: false,
          error: '练习不存在',
        );
        return;
      }

      state = state.copyWith(
        practice: practice,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '加载练习失败: $e',
      );
    }
  }

  /// 删除图层
  Future<void> removeLayer(int pageIndex, String layerId) async {
    if (state.practice == null) return;
    try {
      final page =
          state.practice!.pages.firstWhere((p) => p.index == pageIndex);
      final updatedPage = page.removeLayer(layerId);
      final updated = state.practice!.updatePage(updatedPage);
      await _service.updatePractice(updated);
      state = state.copyWith(practice: updated);
    } catch (e) {
      state = state.copyWith(error: '删除图层失败: $e');
    }
  }

  /// 删除页面
  Future<void> removePage(int index) async {
    if (state.practice == null) return;

    try {
      final updated = state.practice!.removePage(index);
      await _service.updatePractice(updated);
      state = state.copyWith(practice: updated);
    } catch (e) {
      state = state.copyWith(error: '删除页面失败: $e');
    }
  }

  /// 更新图层
  Future<void> updateLayer(int pageIndex, PracticeLayer layer) async {
    if (state.practice == null) return;
    try {
      final page =
          state.practice!.pages.firstWhere((p) => p.index == pageIndex);
      final updatedPage = page.updateLayer(layer);
      final updated = state.practice!.updatePage(updatedPage);
      await _service.updatePractice(updated);
      state = state.copyWith(practice: updated);
    } catch (e) {
      state = state.copyWith(error: '更新图层失败: $e');
    }
  }

  /// 更新页面
  Future<void> updatePage(PracticePage page) async {
    if (state.practice == null) return;

    try {
      final updated = state.practice!.updatePage(page);
      await _service.updatePractice(updated);
      state = state.copyWith(practice: updated);
    } catch (e) {
      state = state.copyWith(error: '更新页面失败: $e');
    }
  }
}

/// 练习详情状态
class PracticeDetailState {
  final PracticeEntity? practice;
  final bool isLoading;
  final String? error;

  const PracticeDetailState({
    this.practice,
    this.isLoading = false,
    this.error,
  });

  PracticeDetailState copyWith({
    PracticeEntity? practice,
    bool? isLoading,
    String? error,
  }) {
    return PracticeDetailState(
      practice: practice ?? this.practice,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
