import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/practice/practice_service.dart';
import '../../domain/models/practice/practice_filter.dart';
import '../../infrastructure/logging/logger.dart';
import 'states/practice_list_state.dart';

class PracticeListViewModel extends StateNotifier<PracticeListState> {
  final PracticeService _practiceService;
  Timer? _searchDebounce;

  PracticeListViewModel(this._practiceService)
      : super(PracticeListState(
          isLoading: false,
          filter: const PracticeFilter(),
          practices: const [],
          searchQuery: '',
        )) {
    Future.microtask(() => _initializeData());
  }

  // 清除所选练习
  void clearSelection() {
    state = state.copyWith(selectedPractices: {});
  }

  // 删除所选练习
  Future<void> deleteSelectedPractices() async {
    if (state.selectedPractices.isEmpty) return;

    state = state.copyWith(isLoading: true);

    try {
      await _practiceService.deletePractices(state.selectedPractices.toList());

      state = state.copyWith(
        isLoading: false,
        batchMode: false,
        selectedPractices: {},
      );

      // 重新加载练习列表
      loadPractices();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete practices: $e',
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  // 处理标签编辑
  Future<void> handleTagEdited(String id, List<String> newTags) async {
    try {
      // 获取当前练习实体
      final practice = await _practiceService.getPractice(id);
      if (practice == null) {
        AppLogger.debug('Practice not found: $id');
        return;
      }

      // 更新练习标签
      final updatedPractice = practice.copyWith(tags: newTags);
      final result = await _practiceService.updatePractice(updatedPractice);

      if (result.id == id) {
        AppLogger.debug('Updated tags successfully for practice: $id');

        // 更新本地状态
        final updatedPractices =
            List<Map<String, dynamic>>.from(state.practices);
        for (int i = 0; i < updatedPractices.length; i++) {
          if (updatedPractices[i]['id'] == id) {
            updatedPractices[i]['tags'] = newTags;
            break;
          }
        }

        state = state.copyWith(practices: updatedPractices);
      }
    } catch (e) {
      AppLogger.debug('Failed to update tags: $e');
      state = state.copyWith(error: 'Failed to update tags: $e');
    }
  }

  // 处理收藏状态切换
  Future<void> handleToggleFavorite(String id) async {
    AppLogger.debug('Toggle favorite status: ID=$id');
    try {
      final updatedPractice = await _practiceService.toggleFavorite(id);

      if (updatedPractice != null) {
        AppLogger.debug('New favorite status: ${updatedPractice.isFavorite}');

        // 更新本地状态
        final updatedPractices =
            List<Map<String, dynamic>>.from(state.practices);
        for (int i = 0; i < updatedPractices.length; i++) {
          if (updatedPractices[i]['id'] == id) {
            updatedPractices[i]['isFavorite'] = updatedPractice.isFavorite;
            break;
          }
        }

        // 如果我们正在按收藏过滤且这个练习被取消收藏，则从过滤后的列表中移除它
        if (state.filter.isFavorite && !updatedPractice.isFavorite) {
          updatedPractices.removeWhere((practice) => practice['id'] == id);
        }

        state = state.copyWith(practices: updatedPractices);
      }
    } catch (e) {
      AppLogger.debug('Toggle favorite failed: $e');
      state = state.copyWith(error: 'Toggle favorite failed: $e');
    }
  }

  // 加载练习数据
  Future<void> loadPractices({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) {
      debugPrint('PracticeListViewModel: 已经在加载中，跳过');
      return;
    }

    debugPrint('PracticeListViewModel: 开始加载练习数据，设置isLoading=true');
    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      // 更新过滤器的分页信息
      final filter = state.filter.copyWith(
        limit: state.pageSize,
        offset: (state.page - 1) * state.pageSize,
      );

      debugPrint(
          'PracticeListViewModel: 查询过滤条件: limit=${filter.limit}, offset=${filter.offset}, isFavorite=${filter.isFavorite}'); // 查询练习
      debugPrint('PracticeListViewModel: 调用 _practiceService.queryPractices');
      debugPrint('PracticeListViewModel: 详细过滤条件: ${filter.toJson()}');
      final practicesResult = await _practiceService.queryPractices(filter);
      debugPrint('PracticeListViewModel: 查询结果数量: ${practicesResult.length}');
      if (practicesResult.isEmpty) {
        debugPrint('PracticeListViewModel: ⚠️ 没有找到匹配的练习数据，检查过滤条件或数据库');
      }

      // 获取总数
      debugPrint('PracticeListViewModel: 调用 _practiceService.count');
      final totalCount = await _practiceService.count(filter);
      debugPrint('PracticeListViewModel: 总记录数: $totalCount');

      // 将 PracticeEntity 列表转换为 Map<String, dynamic> 列表
      final List<Map<String, dynamic>> practicesMap = [];

      for (final practice in practicesResult) {
        try {
          debugPrint(
              'PracticeListViewModel: 处理练习 ID=${practice.id}, 标题=${practice.title}');
          final Map<String, dynamic> practiceMap = {
            'id': practice.id,
            'title': practice.title,
            'status': practice.status,
            'createTime': practice.createTime.toIso8601String(),
            'updateTime': practice.updateTime.toIso8601String(),
            'pageCount': practice.pages.length,
            'thumbnail': practice.thumbnail,
            'isFavorite': practice.isFavorite,
            'tags': practice.tags,
          };

          practicesMap.add(practiceMap);
        } catch (e, stack) {
          debugPrint('PracticeListViewModel: 转换练习实体失败: $e');
          debugPrint('PracticeListViewModel: 错误堆栈: $stack');
          AppLogger.debug('Convert practice entity failed: $e');
        }
      }
      debugPrint(
          'PracticeListViewModel: 更新状态，练习数量: ${practicesMap.length}, 总数: $totalCount');

      // 如果没有数据但启用了收藏过滤，可能是因为没有收藏的练习
      if (practicesMap.isEmpty && filter.isFavorite) {
        debugPrint('PracticeListViewModel: ⚠️ 没有找到收藏的练习数据，考虑关闭收藏过滤器');
      }

      state = state.copyWith(
        practices: practicesMap,
        totalItems: totalCount,
        isLoading: false,
      );

      // 保存状态到持久化存储
      debugPrint('PracticeListViewModel: 持久化当前状态');
      state.persist();
    } catch (e, stackTrace) {
      debugPrint('PracticeListViewModel: 加载练习失败: $e');
      debugPrint('PracticeListViewModel: 错误堆栈: $stackTrace');
      AppLogger.debug('Load practices failed: $e');
      AppLogger.debug('Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        error: 'Load practices failed: $e',
      );
    }
  }

  // 重置过滤器
  void resetFilter() {
    debugPrint('PracticeListViewModel: 重置过滤器');
    final newFilter = PracticeFilter(
      sortField: state.filter.sortField,
      sortOrder: state.filter.sortOrder,
      limit: state.filter.limit,
    );

    state = state.copyWith(
      filter: newFilter,
      page: 1,
      searchQuery: '', // 清空搜索关键字
    );

    // 清空搜索框文本
    state.searchController.text = '';

    // 重新加载数据
    loadPractices(forceRefresh: true);

    // 保存重置后的状态
    state.persist();
  }

  // 切换页码
  void setPage(int page) {
    if (page < 1) return;

    state = state.copyWith(page: page);
    loadPractices(forceRefresh: true);
  }

  // 修改每页数量
  void setPageSize(int pageSize) {
    if (pageSize < 1) return;

    state = state.copyWith(
      pageSize: pageSize,
      page: 1, // 重置到第一页
    );
    loadPractices(forceRefresh: true);
  }

  // 设置搜索关键词
  void setSearchQuery(String query) {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce?.cancel();
    }

    // 立即更新searchQuery以保持UI与状态同步
    state = state.copyWith(searchQuery: query.trim());
    state.searchController.text = query.trim();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final newFilter = state.filter.copyWith(keyword: query.trim());
      updateFilter(newFilter);
    });
  }

  // 切换批量模式
  void toggleBatchMode() {
    state = state.copyWith(
      batchMode: !state.batchMode,
      selectedPractices: !state.batchMode ? {} : state.selectedPractices,
    );
  }

  // 切换过滤面板
  void toggleFilterPanel() {
    state = state.copyWith(isFilterPanelExpanded: !state.isFilterPanelExpanded);

    // 保存状态以记住过滤面板是否展开
    state.persist();
  }

  // 切换练习选择
  void togglePracticeSelection(String id) {
    final newSelection = Set<String>.from(state.selectedPractices);
    if (newSelection.contains(id)) {
      newSelection.remove(id);
    } else {
      newSelection.add(id);
    }

    state = state.copyWith(selectedPractices: newSelection);
  }

  // 切换视图模式（网格/列表）
  void toggleViewMode() {
    final newMode = state.viewMode == PracticeViewMode.grid
        ? PracticeViewMode.list
        : PracticeViewMode.grid;

    state = state.copyWith(viewMode: newMode);

    // 保存视图模式偏好
    state.persist();
  }

  // 更新过滤器
  void updateFilter(PracticeFilter filter) {
    AppLogger.debug('Update filter: isFavorite=${filter.isFavorite}');

    // 如果更新后的过滤器与当前过滤器相同，避免不必要的重新加载
    if (filter == state.filter) {
      debugPrint('PracticeListViewModel: 过滤器未变更，跳过更新');
      return;
    }

    // 确保searchQuery与filter.keyword保持同步
    final searchQuery = filter.keyword ?? '';

    state = state.copyWith(
      filter: filter,
      page: 1, // 重置到第一页
      searchQuery: searchQuery, // 同步搜索关键字到状态中
    );

    // 更新搜索框文本
    state.searchController.text = searchQuery;

    // 重新加载数据以应用新的过滤条件
    loadPractices(forceRefresh: true);

    // 保存过滤器状态
    state.persist();
  }

  // 初始化数据
  Future<void> _initializeData() async {
    try {
      debugPrint('PracticeListViewModel: 开始初始化数据...');

      // 尝试恢复之前保存的状态
      final savedState = await PracticeListStatePersistence.restore();
      debugPrint('PracticeListViewModel: 已恢复状态，过滤条件：${savedState.filter}');

      // 确保searchQuery与filter.keyword保持同步
      final updatedState = savedState.copyWith(
        isLoading: true,
        error: null,
        practices: const [],
        // 从filter.keyword同步到searchQuery，确保UI显示正确
        searchQuery: savedState.filter.keyword ?? '',
      );

      // 更新文本控制器以显示搜索关键字
      updatedState.searchController.text = updatedState.searchQuery;

      // 使用恢复的状态
      state = updatedState;

      // 加载练习数据，使用forceRefresh确保即使在loading状态也会加载
      debugPrint('PracticeListViewModel: 开始加载练习数据（强制刷新）');
      await loadPractices(forceRefresh: true);
    } catch (e, stack) {
      debugPrint('PracticeListViewModel: 初始化失败: $e');
      debugPrint('PracticeListViewModel: 错误堆栈: $stack');

      AppLogger.error('Failed to initialize practice list',
          tag: 'PracticeListViewModel', error: e, stackTrace: stack);

      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize: $e',
      );

      // 即使初始化失败，尝试加载数据（确保页面不会一直显示加载状态）
      try {
        debugPrint('PracticeListViewModel: 尝试重新加载练习数据');
        await loadPractices();
      } catch (loadError, loadStack) {
        debugPrint('PracticeListViewModel: 重试加载失败: $loadError');
        debugPrint('PracticeListViewModel: 错误堆栈: $loadStack');

        AppLogger.error('Failed to load practices after initialization failure',
            tag: 'PracticeListViewModel',
            error: loadError,
            stackTrace: loadStack);
      }
    }
  }
}
