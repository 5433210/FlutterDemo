import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/services.dart';
import '../../domain/models/common/date_range_filter.dart';
import '../../domain/models/work/work_filter.dart';
import '../../infrastructure/logging/logger.dart';
import '../../utils/throttle_helper.dart';
import '../providers/events/work_events_provider.dart';
import 'states/work_browse_state.dart';

/// 作品浏览视图模型
class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final WorkService _workService;
  final Ref _ref;
  Timer? _searchDebounce;
  final ThrottleHelper _loadThrottler = ThrottleHelper(
    minInterval: const Duration(milliseconds: 500),
  );

  WorkBrowseViewModel(this._workService, this._ref)
      : super(WorkBrowseState(
          isLoading: false,
          filter: const WorkFilter(),
          works: const [],
          requestStatus: LoadRequestStatus.idle,
          searchQuery: '',
        )) {
    Future.microtask(() => _initializeData());
  }

  void clearSelection() {
    state = state.copyWith(selectedWorks: {});
  }

  /// 全选所有作品
  void selectAll() {
    final allWorkIds = state.works.map((work) => work.id).toSet();

    AppLogger.debug('全选作品',
        tag: 'WorkBrowseViewModel', data: {'totalCount': allWorkIds.length});

    state = state.copyWith(selectedWorks: allWorkIds);
  }

  Future<void> deleteSelected() async {
    if (state.selectedWorks.isEmpty) return;

    AppLogger.debug('开始批量删除',
        tag: 'WorkBrowseViewModel',
        data: {'selectedCount': state.selectedWorks.length});

    try {
      state = state.copyWith(isLoading: true);

      // 记录要删除的作品ID
      final deletedWorkIds = Set<String>.from(state.selectedWorks);

      // 1. 执行删除操作
      await Future.wait(
          state.selectedWorks.map((id) => _workService.deleteWork(id)));

      AppLogger.debug('删除完成，准备刷新列表', tag: 'WorkBrowseViewModel');

      // 2. 发送删除事件通知
      for (final workId in deletedWorkIds) {
        _ref.read(workDeletedNotifierProvider.notifier).state = workId;
      }

      // 3. 重新加载作品列表
      final works = await _workService.queryWorks(state.filter);

      // 4. 更新状态
      state = state.copyWith(
        isLoading: false,
        works: works,
        batchMode: false, // 删除后退出批量模式
        selectedWorks: {}, // 清空选择
      );

      // 5. 清空删除事件通知状态
      Future.delayed(const Duration(milliseconds: 100), () {
        _ref.read(workDeletedNotifierProvider.notifier).state = null;
      });
    } catch (e, stack) {
      AppLogger.error('批量删除失败',
          tag: 'WorkBrowseViewModel', error: e, stackTrace: stack);

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadThrottler.cancel();
    super.dispose();
  }

  /// 刷新数据（按当前筛选条件重新查询）
  Future<void> refresh() async {
    await loadWorks(forceRefresh: true);
  }

  // 加载相关方法
  Future<void> loadWorks({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    // Capture the current state values before any async operations
    final currentPage = state.page;
    final currentPageSize = state.pageSize;

    AppLogger.debug('触发加载流程', tag: 'WorkBrowseViewModel', data: {
      'forceRefresh': forceRefresh,
      'page': currentPage,
      'pageSize': currentPageSize
    });

    // Update state to loading - use try/catch to handle potential state update errors
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        requestStatus: LoadRequestStatus.loading,
      );
    } catch (e) {
      AppLogger.error('Failed to update loading state',
          tag: 'WorkBrowseViewModel', error: e);
      return; // Exit early if we can't update state
    }

    try {
      // 使用分页查询
      final result = await _workService.queryWorksPaginated(
        filter: state.filter,
        page: currentPage,
        pageSize: currentPageSize,
      );

      // Log completion before attempting to update state
      AppLogger.debug('加载完成', tag: 'WorkBrowseViewModel', data: {
        'worksCount': result.items.length,
        'totalItems': result.totalCount,
        'currentPage': result.currentPage,
        'totalPages': result.totalPages,
      });

      // Update state with results - wrap in try/catch to handle potential errors
      try {
        state = state.copyWith(
          works: result.items,
          isLoading: false,
          error: null,
          totalItems: result.totalCount,
          totalPages: result.totalPages,
          hasMore: result.hasNextPage,
          requestStatus: LoadRequestStatus.idle,
        );
      } catch (e) {
        AppLogger.error('Failed to update state with results',
            tag: 'WorkBrowseViewModel', error: e);
      }
    } catch (e, stack) {
      _handleLoadError(e, stack);
    }
  }

  // 切换页码
  void setPage(int page) {
    if (page < 1 || (state.totalPages > 0 && page > state.totalPages)) return;

    AppLogger.debug('切换页码', tag: 'WorkBrowseViewModel', data: {
      'oldPage': state.page,
      'newPage': page,
    });

    state = state.copyWith(page: page);
    loadWorks(forceRefresh: true);
  }

  // 修改每页数量
  void setPageSize(int pageSize) {
    if (pageSize < 1) return;

    AppLogger.debug('修改每页数量', tag: 'WorkBrowseViewModel', data: {
      'oldPageSize': state.pageSize,
      'newPageSize': pageSize,
    });

    state = state.copyWith(
      pageSize: pageSize,
      page: 1, // 重置到第一页
    );
    loadWorks(forceRefresh: true);
  }

  // 搜索相关方法
  void setSearchQuery(String query) {
    AppLogger.debug('设置搜索关键词',
        tag: 'WorkBrowseViewModel', data: {'query': query});

    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce?.cancel();
    }

    // Update the search query in state immediately for UI feedback
    state = state.copyWith(searchQuery: query.trim());
    state.searchController.value = TextEditingValue(
      text: query,
      selection: TextSelection.collapsed(offset: query.length), // 光标置于文本末尾
    );

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final newFilter = state.filter.copyWith(keyword: query.trim());
      updateFilter(newFilter);
    });
  }

  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  // 批量操作相关方法
  void toggleBatchMode() {
    AppLogger.debug('切换批量模式',
        tag: 'WorkBrowseViewModel', data: {'currentMode': state.batchMode});

    state = state.copyWith(
      batchMode: !state.batchMode,
      selectedWorks: {}, // 退出批量模式时清空选择
    );
  }

  // 切换收藏状态
  Future<void> toggleFavorite(String workId) async {
    if (state.isLoading) return;

    try {
      AppLogger.debug('切换收藏状态', tag: 'WorkBrowseViewModel', data: {
        'workId': workId,
      });

      // 调用服务切换收藏状态
      final updatedWork = await _workService.toggleFavorite(workId);

      // 更新本地状态
      final updatedWorks = state.works.map((work) {
        if (work.id == workId) {
          return updatedWork;
        }
        return work;
      }).toList();

      state = state.copyWith(works: updatedWorks);

      // 如果启用了只显示收藏过滤，且取消了收藏，则需要刷新列表
      if (state.filter.isFavoriteOnly && !updatedWork.isFavorite) {
        await loadWorks(forceRefresh: true);
      }
    } catch (e, stack) {
      AppLogger.error('切换收藏状态失败',
          tag: 'WorkBrowseViewModel', error: e, stackTrace: stack);

      state = state.copyWith(
        error: e.toString(),
      );
    }
  }

  void toggleSelection(String workId) {
    final newSelection = Set<String>.from(state.selectedWorks);
    if (newSelection.contains(workId)) {
      newSelection.remove(workId);
    } else {
      newSelection.add(workId);
    }

    AppLogger.debug('切换选择状态',
        tag: 'WorkBrowseViewModel',
        data: {'workId': workId, 'selected': newSelection.contains(workId)});

    state = state.copyWith(selectedWorks: newSelection);
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarOpen: !state.isSidebarOpen);
  }

  /// 在窄屏模式下切换侧边栏（针对响应式设计优化）
  void toggleSidebarExclusive() {
    // 对于作品浏览页，只有筛选面板，所以直接切换即可
    // 这个方法为了保持与其他页面的API一致性
    state = state.copyWith(isSidebarOpen: !state.isSidebarOpen);
  }

  // 视图相关方法
  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
  }

  void updateDatePreset(DateRangePreset? preset) {
    if (preset == null || preset == DateRangePreset.all) {
      // 清除所有日期相关的筛选条件
      final newFilter = state.filter.copyWith(
        datePreset: DateRangePreset.all,
        dateRange: null,
      );
      updateFilter(newFilter);
      return;
    }

    final newFilter = state.filter.copyWith(
      datePreset: preset,
      dateRange: null,
    );
    updateFilter(newFilter);
  }

  void updateDateRange(DateTimeRange? range) {
    if (range == null) {
      // 清除所有日期相关的筛选条件
      final newFilter = state.filter.copyWith(
        datePreset: DateRangePreset.all,
        dateRange: null,
      );
      updateFilter(newFilter);
      return;
    }

    final newFilter = state.filter.copyWith(
      dateRange: range,
      datePreset: DateRangePreset.all, // 使用自定义时需要清除预设
    );
    updateFilter(newFilter);
  }

  // 筛选相关方法
  void updateFilter(WorkFilter? filter) {
    AppLogger.debug(
      '更新筛选条件',
      tag: 'WorkBrowseViewModel',
      data: {
        'oldFilter': state.filter.toString(),
        'newFilter': filter?.toString() ?? 'null',
      },
    );

    if (filter == null) {
      // 清除所有筛选条件
      final newFilter = state.filter.copyWith(
        datePreset: DateRangePreset.all,
        dateRange: null,
        keyword: null, // 确保清除搜索关键词
      );

      state = state.copyWith(
        works: [],
        filter: newFilter,
        page: 1,
        hasMore: true,
        error: null,
        searchQuery: '', // Clear the search query when resetting filter
      );

      // Update the controller text to empty
      state.searchController.text = '';
    } else {
      // Sync the search query with the filter keyword
      final searchQuery = filter.keyword ?? '';

      state = state.copyWith(
        works: [],
        filter: filter,
        page: 1,
        hasMore: true,
        error: null,
        searchQuery:
            searchQuery, // Set the search query to match filter keyword
      );

      // Update the controller text to match the filter keyword
      state.searchController.text = searchQuery;
    }

    loadWorks(forceRefresh: true);
  }

  // 更新标签
  Future<void> updateTags(String workId, List<String> newTags) async {
    if (state.isLoading) return;

    try {
      AppLogger.debug('更新作品标签', tag: 'WorkBrowseViewModel', data: {
        'workId': workId,
        'newTags': newTags,
      });

      // 查找要更新的作品
      final workToUpdate = state.works.firstWhere((w) => w.id == workId);

      // 更新标签
      final updatedWork = workToUpdate.updateTags(newTags);

      // 保存到服务器
      final savedWork = await _workService.updateWorkEntity(updatedWork);

      // 更新本地状态
      final updatedWorks = state.works.map((work) {
        return work.id == workId ? savedWork : work;
      }).toList();

      state = state.copyWith(works: updatedWorks);
    } catch (e) {
      AppLogger.error('更新标签失败',
          tag: 'WorkBrowseViewModel', error: e, data: {'workId': workId});
    }
  }

  void _handleLoadError(dynamic error, StackTrace stack) {
    AppLogger.error('加载作品列表失败',
        tag: 'WorkBrowseViewModel', error: error, stackTrace: stack);

    state = state.copyWith(
      isLoading: false,
      error: error.toString(),
      requestStatus: LoadRequestStatus.idle,
    );
  }

  Future<void> _initializeData() async {
    try {
      AppLogger.info('初始化作品浏览页数据',
          tag: 'WorkBrowseViewModel',
          data: {'initialFilter': state.filter.toString()});

      // If we have a keyword in the filter, ensure it's reflected in the search query
      final searchQuery = state.filter.keyword ?? '';

      state = state.copyWith(
        isLoading: true,
        error: null,
        works: const [],
        searchQuery: searchQuery,
      );

      // Update the controller text to match the filter keyword
      state.searchController.text = searchQuery;

      await loadWorks(forceRefresh: true);
    } catch (e, stack) {
      _handleLoadError(e, stack);
    }
  }
}
