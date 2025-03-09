import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/services.dart';
import '../../domain/enums/sort_field.dart';
import '../../domain/models/common/date_range_filter.dart';
import '../../domain/models/work/work_filter.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/services/state_restoration_service.dart';
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

  void clearDateFilter() {
    final newFilter = state.filter.copyWith(
      datePreset: DateRangePreset.all,
      dateRange: null,
    );
    updateFilter(newFilter);
  }

  void clearSelection() {
    state = state.copyWith(
      selectedWorks: {},
    );
  }

  Future<void> deleteSelected() async {
    if (state.selectedWorks.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      await Future.wait(
          state.selectedWorks.map((id) => _workService.deleteWork(id)));

      final works = await _workService.queryWorks(
        state.filter,
      );

      state = state.copyWith(
        isLoading: false,
        works: works,
      );
      toggleBatchMode();
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

      final works = await _workService.queryWorks(
        state.filter,
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
    _loadThrottler.cancel();
    _saveState();
    super.dispose();
  }

  DateTimeRange? getEffectiveDateRange() {
    return state.filter.datePreset.getRange();
  }

  Future<String?> getWorkThumbnail(String workId) async {
    return await _workService.getWorkThumbnail(workId);
  }

  Future<void> handleImportResult(bool success) async {
    if (success) {
      state = state.copyWith(
        page: 1,
        hasMore: true,
      );
      await loadWorks();
    }
  }

  bool isDateRangeValid(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return start.isBefore(end) || start.isAtSameMomentAs(end);
  }

  Future<void> loadMoreWorks() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.page + 1;
      final moreWorks = await _workService.queryWorks(
        state.filter,
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
    if (state.isLoading) return;

    AppLogger.debug(
      '开始加载作品列表',
      tag: 'WorkBrowseViewModel',
      data: {
        'forceRefresh': forceRefresh,
        'currentState': {
          'isLoading': state.isLoading,
          'worksCount': state.works.length,
          'hasError': state.error != null,
        }
      },
    );

    try {
      state = state.copyWith(isLoading: true, error: null);

      await _loadThrottler.throttle(
        () => _executeLoadOperation(forceRefresh),
        forceExecute: forceRefresh,
      );
    } catch (e, stack) {
      _handleLoadError(e, stack);
    }
  }

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
          state.filter,
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

  void selectAll() {
    final allIds = state.works
        .where((work) => work.id != null)
        .map((work) => work.id)
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
    _saveState();
  }

  void setViewMode(ViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
    _saveState();
  }

  void toggleBatchMode() {
    state = state.copyWith(
      batchMode: !state.batchMode,
      selectedWorks: {}, // 退出批量模式时清空选择
    );
  }

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
    _saveState();
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
    _saveState();
  }

  void updateDatePreset(DateRangePreset? preset) {
    final newFilter = state.filter.copyWith(
      datePreset: preset!,
      dateRange: null,
    );
    updateFilter(newFilter);
  }

  void updateDateRange(DateTimeRange? range) {
    final newFilter = state.filter
        .copyWith(dateRange: range!, datePreset: DateRangePreset.all);
    updateFilter(newFilter);
  }

  void updateFilter(WorkFilter filter) {
    state = state.copyWith(filter: filter);
    _loadFilteredWorksWithFilter(filter);
  }

  void updateSortField(SortField field) {
    if (field == state.filter.sortOption.field) {
      toggleSortDirection();
    } else {
      final newSortOption = state.filter.sortOption.copyWith(
        field: field,
        descending: true,
      );
      updateFilter(state.filter.copyWith(sortOption: newSortOption));
    }
  }

  Future<void> _executeLoadOperation(bool forceRefresh) async {
    try {
      final filter = state.filter;
      AppLogger.debug(
        '执行加载操作',
        tag: 'WorkBrowseViewModel',
        data: {
          'filter': filter.toString(),
          'forceRefresh': forceRefresh,
        },
      );

      final clearedBatchMode = state.batchMode && forceRefresh
          ? state.copyWith(batchMode: false, selectedWorks: {})
          : state;

      if (clearedBatchMode != state) {
        state = clearedBatchMode;
      }

      final works = await _workService.queryWorks(
        filter,
      );
      AppLogger.debug(
        '查询作品完成',
        tag: 'WorkBrowseViewModel',
        data: {
          'worksCount': works.length,
        },
      );

      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          works: works,
          error: null,
        );

        _saveState();
      }
    } catch (e) {
      AppLogger.error(
        '加载作品失败',
        tag: 'WorkBrowseViewModel',
        error: e,
      );
      rethrow;
    }
  }

  void _handleLoadError(dynamic error, StackTrace stack) {
    AppLogger.error('加载作品列表失败',
        tag: 'WorkBrowseViewModel', error: error, stackTrace: stack);

    state = state.copyWith(
      isLoading: false,
      error: error.toString(),
    );
  }

  Future<void> _initializeData() async {
    try {
      AppLogger.info('初始化作品浏览页数据', tag: 'WorkBrowseViewModel', data: {
        'initialFilter': state.filter.toString(),
      });

      state = state.copyWith(
        isLoading: true,
        error: null,
        filter: const WorkFilter(), // 使用空的过滤器
        works: const [], // 清空作品列表
      );

      await loadWorks(forceRefresh: true);
    } catch (e, stack) {
      _handleLoadError(e, stack);
    }
  }

  Future<void> _loadFilteredWorks() async {
    state = state.copyWith(isLoading: true);
    try {
      final works = await _workService.queryWorks(
        state.filter,
      );

      state = state.copyWith(
        works: works,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<void> _loadFilteredWorksWithFilter(WorkFilter filter) async {
    state = state.copyWith(
      filter: filter,
      isLoading: true,
    );

    try {
      final works = await _workService.queryWorks(
        filter,
      );

      state = state.copyWith(
        works: works,
        isLoading: false,
      );

      _saveState();
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
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
