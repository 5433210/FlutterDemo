import 'dart:async';

import 'package:demo/application/services/work/work_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/services/state_restoration_service.dart';
import '../dialogs/work_import/work_import_dialog.dart';
import '../models/date_range_filter.dart';
import '../models/work_filter.dart';
import 'states/work_browse_state.dart';

class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final WorkService _workService;
  final StateRestorationService _stateRestorationService;
  Timer? _searchDebounce;

  WorkBrowseViewModel(this._workService, this._stateRestorationService)
      : super(WorkBrowseState()) {
    _restoreState();
    loadWorks();
  }

  void clearDateFilter() {
    final newFilter = state.filter.copyWith(
      datePreset: null,
      dateRange: null,
    );
    updateFilter(newFilter);
  }

  // 添加清空选择方法
  void clearSelection() {
    state = state.copyWith(
      selectedWorks: {},
    );
  }

  Future<void> deleteSelected() async {
    // 移除 BuildContext 参数
    if (state.selectedWorks.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      await Future.wait(
          state.selectedWorks.map((id) => _workService.deleteWork(id)));
      // 这里调用的是 WorkService.deleteWork()，它会删除文件

      await loadWorks();
      toggleBatchMode(); // 删除完成后退出批量模式
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteWork(String workId) async {
    try {
      state = state.copyWith(isLoading: true);
      await _workService.deleteWork(workId);

      // 使用现有的搜索和筛选条件重新查询
      final works = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: state.filter,
      );

      state = state.copyWith(
        isLoading: false,
        works: works,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> deleteWorks(List<String> workIds) async {
    try {
      state = state.copyWith(isLoading: true);

      // 批量删除
      for (final workId in workIds) {
        await _workService.deleteWork(workId);
        // 这里也调用了 WorkService.deleteWork()，它会删除文件
      }

      // 使用现有的搜索和筛选条件重新查询
      final works = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: state.filter,
      );

      state = state.copyWith(
        isLoading: false,
        works: works,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    // 保存状态
    _saveState();
    super.dispose();
  }

  // 添加辅助方法以获取有效的日期范围
  DateTimeRange? getEffectiveDateRange() {
    if (state.filter.datePreset != null) {
      return state.filter.datePreset!.getRange();
    }
    return state.filter.dateRange;
  }

  Future<String?> getWorkThumbnail(String workId) async {
    return await _workService.getWorkThumbnail(workId);
  }

  // 处理导入结果
  Future<void> handleImportResult(bool success) async {
    if (success) {
      state = state.copyWith(
        page: 1,
        hasMore: true,
      );
      await loadWorks();
    }
  }

  // 添加日期范围验证
  bool isDateRangeValid(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return start.isBefore(end) || start.isAtSameMomentAs(end);
  }

  // 添加分页加载功能
  Future<void> loadMoreWorks() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final moreWorks = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: state.filter,
        sortOption: state.filter.sortOption,
      );

      if (moreWorks.isEmpty) {
        state = state.copyWith(
          hasMore: false,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(
          works: [...state.works, ...moreWorks],
          page: nextPage,
          isLoadingMore: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoadingMore: false,
      );
    }
  }

  Future<void> loadWorks({bool forceRefresh = false}) async {
    // 如果正在加载且不是强制刷新，则直接返回
    if (state.isLoading && !forceRefresh) return;

    try {
      // 只有在强制刷新或首次加载时才显示加载状态
      if (forceRefresh || state.works.isEmpty) {
        state = state.copyWith(isLoading: true, error: null);
      }

      final filter = state.filter;
      final query = state.searchQuery;

      final results = await _workService.queryWorks(
        searchQuery: query,
        filter: filter,
      );

      state = state.copyWith(
        isLoading: false,
        works: results,
        totalCount: results.length,
        error: null,
      );

      _saveState();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to load works',
        tag: 'WorkBrowseViewModel',
        error: e,
        stackTrace: stack,
      );

      state = state.copyWith(
        isLoading: false,
        error: '加载作品失败: ${e.toString()}',
      );
    }
  }

  // 添加列表刷新功能
  Future<void> refreshWorks() async {
    state = state.copyWith(
      page: 1,
      hasMore: true,
      works: [],
    );
    await loadWorks();
  }

  Future<void> searchWorks(String query) async {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      state = state.copyWith(isLoading: true);
      try {
        final works = await _workService.queryWorks(
          searchQuery: query,
          filter: state.filter,
        );
        state = state.copyWith(
          works: works,
          searchQuery: query,
          isLoading: false,
        );
      } catch (e) {
        state = state.copyWith(
          error: e.toString(),
          isLoading: false,
        );
      }
    });
  }

  // 可以同时添加全选方法
  void selectAll() {
    final allIds = state.works
        .where((work) => work.id != null)
        .map((work) => work.id!)
        .toSet();

    state = state.copyWith(
      selectedWorks: allIds,
    );
  }

  void setSearchQuery(String query) {
    if (_searchDebounce?.isActive ?? false) {
      _searchDebounce?.cancel();
    }

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      state = state.copyWith(
        searchQuery: query,
        isLoading: true,
      );
      _loadFilteredWorks();
    });
  }

  void setSidebarState(bool sidebarOpen) {
    state = state.copyWith(isSidebarOpen: sidebarOpen);
    _saveState(); // 保存状态
  }

  void setViewMode(ViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
    _saveState(); // 保存状态
  }

  // 添加导入对话框功能
  Future<bool> showImportDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const WorkImportDialog(),
    );

    if (result == true) {
      // 导入成功后刷新列表
      await loadWorks();
      return true;
    }
    return false;
  }

  // 批量操作方法
  void toggleBatchMode() {
    state = state.copyWith(
      batchMode: !state.batchMode,
      selectedWorks: {}, // 退出批量模式时清空选择
    );
  }

  // 添加选择状态切换方法
  void toggleSelectAll() {
    if (state.selectedWorks.length == state.works.length) {
      clearSelection();
    } else {
      selectAll();
    }
  }

  void toggleSelection(String workId) {
    final newSelection = Set<String>.from(state.selectedWorks);
    if (newSelection.contains(workId)) {
      newSelection.remove(workId);
    } else {
      newSelection.add(workId);
    }
    state = state.copyWith(selectedWorks: newSelection);
  }

  void toggleSidebar() {
    state = state.copyWith(
      isSidebarOpen: !state.isSidebarOpen,
    );
    _saveState(); // 保存状态
  }

  void toggleSortDirection() {
    final newSortOption = state.filter.sortOption.copyWith(
      descending: !state.filter.sortOption.descending,
    );
    updateFilter(state.filter.copyWith(sortOption: newSortOption));
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
  }

  void update(WorkBrowseState Function(WorkBrowseState state) updater) {
    final newState = updater(state);
    // 状态变化时自动保存
    newState.persist();
    state = newState;
  }

  // 添加日期过滤相关方法
  void updateDatePreset(DateRangePreset? preset) {
    final newFilter = state.filter.copyWith(
      datePreset: () => preset,
      dateRange: null, // 清除自定义日期范围
    );
    updateFilter(newFilter);
  }

  void updateDateRange(DateTimeRange? range) {
    final newFilter = state.filter.copyWith(
      dateRange: () => range,
      datePreset: null, // 清除预设
    );
    updateFilter(newFilter);
  }

  void updateFilter(WorkFilter filter) {
    debugPrint('ViewModel - updateFilter: $filter');
    _loadFilteredWorksWithFilter(filter);
    // 在数据加载完成后的回调中保存状态
  }

  // 完善排序功能
  void updateSortField(SortField field) {
    if (field == state.filter.sortOption.field) {
      // 如果选择相同字段，切换排序方向
      toggleSortDirection();
    } else {
      // 选择新字段时，默认降序
      final newSortOption = state.filter.sortOption.copyWith(
        field: field,
        descending: true,
      );
      updateFilter(state.filter.copyWith(sortOption: newSortOption));
    }
  }

  Future<void> _loadFilteredWorks() async {
    debugPrint('ViewModel - _loadFilteredWorks started');
    debugPrint('Current state works count: ${state.works.length}'); // 添加当前状态记录

    state = state.copyWith(isLoading: true);
    try {
      debugPrint('ViewModel - current filter: ${state.filter}');
      final works = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: state.filter,
        sortOption: state.filter.sortOption,
      );
      debugPrint('ViewModel - got ${works.length} works');

      // 添加更详细的状态更新日志
      final newState = state.copyWith(
        works: works,
        isLoading: false,
      );
      debugPrint('New state works count: ${newState.works.length}');

      state = newState;
      debugPrint('State updated, current works count: ${state.works.length}');
    } catch (e) {
      debugPrint('ViewModel - error: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> _loadFilteredWorksWithFilter(WorkFilter filter) async {
    debugPrint('ViewModel - _loadFilteredWorksWithFilter started');

    state = state.copyWith(
      filter: filter,
      isLoading: true,
    );

    try {
      debugPrint('ViewModel - current filter: ${state.filter}');
      final works = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: filter, // Use the new filter directly
        sortOption: filter.sortOption,
      );
      debugPrint('ViewModel - got ${works.length} works');

      state = state.copyWith(
        works: works,
        isLoading: false,
      );
      debugPrint('State updated, current works count: ${state.works.length}');

      // 添加保存状态的调用
      _saveState();
    } catch (e) {
      debugPrint('ViewModel - error: $e');
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> _restoreState() async {
    final restoredState =
        await _stateRestorationService.restoreWorkBrowseState(this);
    if (restoredState != null) {
      state = restoredState;
    }
    await loadWorks();
  }

  // 添加 _saveState 方法来持久化当前状态
  void _saveState() {
    try {
      // 记录保存状态的日志
      AppLogger.debug(
        'Saving work browse state',
        tag: 'WorkBrowseViewModel',
        data: {
          'viewMode': state.viewMode.toString(),
          'isSidebarOpen': state.isSidebarOpen,
          'filter': state.filter.toString(),
          'searchQuery': state.searchQuery,
        },
      );

      // 调用状态恢复服务保存当前状态
      _stateRestorationService.saveWorkBrowseState(state);
    } catch (e, stack) {
      // 记录保存状态失败的错误
      AppLogger.error(
        'Failed to save work browse state',
        tag: 'WorkBrowseViewModel',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
