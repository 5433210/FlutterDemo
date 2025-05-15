import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/restoration/state_restoration_service.dart';
import '../../application/services/services.dart';
import '../../domain/models/common/date_range_filter.dart';
import '../../domain/models/work/work_filter.dart';
import '../../infrastructure/logging/logger.dart';
import '../../utils/throttle_helper.dart';
import 'states/work_browse_state.dart';

/// 作品浏览视图模型
class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final WorkService _workService;
  final StateRestorationService _stateRestorationService;
  Timer? _searchDebounce;
  final ThrottleHelper _loadThrottler = ThrottleHelper(
    minInterval: const Duration(milliseconds: 500),
  );

  WorkBrowseViewModel(this._workService, this._stateRestorationService)
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

  Future<void> deleteSelected() async {
    if (state.selectedWorks.isEmpty) return;

    AppLogger.debug('开始批量删除',
        tag: 'WorkBrowseViewModel',
        data: {'selectedCount': state.selectedWorks.length});

    try {
      state = state.copyWith(isLoading: true);

      // 1. 执行删除操作
      await Future.wait(
          state.selectedWorks.map((id) => _workService.deleteWork(id)));

      AppLogger.debug('删除完成，准备刷新列表', tag: 'WorkBrowseViewModel');

      // 2. 重新加载作品列表
      final works = await _workService.queryWorks(state.filter);

      // 3. 更新状态
      state = state.copyWith(
        isLoading: false,
        works: works,
        batchMode: false, // 删除后退出批量模式
        selectedWorks: {}, // 清空选择
      );
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
    _saveState();
    super.dispose();
  }

  // 加载相关方法
  Future<void> loadWorks({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    AppLogger.debug('触发加载流程', tag: 'WorkBrowseViewModel', data: {
      'forceRefresh': forceRefresh,
      'page': state.page,
      'pageSize': state.pageSize
    });

    state = state.copyWith(
      isLoading: true,
      error: null,
      requestStatus: LoadRequestStatus.loading,
    );

    try {
      // 使用分页查询
      final result = await _workService.queryWorksPaginated(
        filter: state.filter,
        page: state.page,
        pageSize: state.pageSize,
      );

      state = state.copyWith(
        works: result.items,
        isLoading: false,
        error: null,
        totalItems: result.totalCount,
        totalPages: result.totalPages,
        hasMore: result.hasNextPage,
        requestStatus: LoadRequestStatus.idle,
      );

      AppLogger.debug('加载完成', tag: 'WorkBrowseViewModel', data: {
        'worksCount': result.items.length,
        'totalItems': result.totalCount,
        'currentPage': result.currentPage,
        'totalPages': result.totalPages,
      });
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

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      final newFilter = state.filter.copyWith(keyword: query.trim());
      updateFilter(newFilter);
    });
  }

  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
    _saveState();
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
    _saveState();
  }

  // 视图相关方法
  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
    _saveState();
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
      );
    } else {
      state = state.copyWith(
        works: [],
        filter: filter,
        page: 1,
        hasMore: true,
        error: null,
      );
    }

    loadWorks(forceRefresh: true);
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

      state = state.copyWith(
        isLoading: true,
        error: null,
        filter: const WorkFilter(),
        works: const [],
      );

      await loadWorks(forceRefresh: true);
    } catch (e, stack) {
      _handleLoadError(e, stack);
    }
  }

  void _saveState() {
    try {
      _stateRestorationService.saveWorkBrowseState(state);
    } catch (e, stack) {
      AppLogger.error(
        'Failed to save work browse state',
        tag: 'WorkBrowseViewModel',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
