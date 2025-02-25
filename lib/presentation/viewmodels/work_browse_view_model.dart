import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../infrastructure/services/state_restoration_service.dart';
import '../../domain/interfaces/i_work_service.dart';
import '../dialogs/work_import/work_import_dialog.dart';
import '../models/date_range_filter.dart';
import '../models/work_filter.dart';
import 'states/work_browse_state.dart';

class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final IWorkService _workService;
  final StateRestorationService _stateRestorationService;
  Timer? _searchDebounce;

  WorkBrowseViewModel(this._workService, this._stateRestorationService) 
      : super(WorkBrowseState()) {
    _restoreState();
  }

  Future<void> _restoreState() async {
    final restoredState = await _stateRestorationService.restoreWorkBrowseState(this);
    if (restoredState != null) {
      state = restoredState;
    }
    await loadWorks();
  }

  Future<void> loadWorks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final works = await _workService.getAllWorks();
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

  void toggleSidebar() {
    state = state.copyWith(
      isSidebarOpen: !state.isSidebarOpen,
    );
  }

  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
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

  Future<String?> getWorkThumbnail(String workId) async {
    return await _workService.getWorkThumbnail(workId);
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

  void updateFilter(WorkFilter filter) {
    state = state.copyWith(filter: filter);
    _loadFilteredWorks();
  }

  void toggleSortDirection() {
    final newSortOption = state.filter.sortOption.copyWith(
      descending: !state.filter.sortOption.descending,
    );
    updateFilter(state.filter.copyWith(sortOption: newSortOption));
  }

  // 批量操作方法
  void toggleBatchMode() {
    state = state.copyWith(
      batchMode: !state.batchMode,
      selectedWorks: {},  // 退出批量模式时清空选择
    );
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

  Future<void> deleteSelected() async {
    if (state.selectedWorks.isEmpty) return;

    state = state.copyWith(isLoading: true);
    try {
      for (final workId in state.selectedWorks) {
        await _workService.deleteWork(workId);
      }
      // 重新加载数据
      await loadWorks();
      // 退出批量模式
      toggleBatchMode();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
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

  Future<void> _loadFilteredWorks() async {
    state = state.copyWith(isLoading: true);
    try {
      final works = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: state.filter,
        sortOption: state.filter.sortOption,
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

  // 添加状态恢复功能
  Future<void> restorePersistedState() async {
    try {
      final persistedState = await WorkBrowseState.restore();
      state = state.copyWith(
        viewMode: persistedState.viewMode,
        isSidebarOpen: persistedState.isSidebarOpen,
        filter: persistedState.filter,
      );
      
      // 使用恢复的过滤器重新加载数据
      await loadWorks();
    } catch (e) {
      debugPrint('Failed to restore state: $e');
      // 恢复失败时使用默认状态
      await loadWorks();
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
      dateRange: ()=>range,
      datePreset: null, // 清除预设
    );
    updateFilter(newFilter);
  }

  void clearDateFilter() {
    final newFilter = state.filter.copyWith(
      datePreset: null,
      dateRange: null,
    );
    updateFilter(newFilter);
  }

  // 添加日期范围验证
  bool isDateRangeValid(DateTime? start, DateTime? end) {
    if (start == null || end == null) return false;
    return start.isBefore(end) || start.isAtSameMomentAs(end);
  }

  // 添加辅助方法以获取有效的日期范围
  DateTimeRange? getEffectiveDateRange() {
    if (state.filter.datePreset != null) {
      return state.filter.datePreset!.getRange();
    }
    return state.filter.dateRange;
  }

  // 添加清空选择方法
  void clearSelection() {
    state = state.copyWith(
      selectedWorks: {},
    );
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

  // 添加选择状态切换方法
  void toggleSelectAll() {
    if (state.selectedWorks.length == state.works.length) {
      clearSelection();
    } else {
      selectAll();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    // 保存状态
    _stateRestorationService.saveWorkBrowseState(state);
    super.dispose();
  }

  void update(WorkBrowseState Function(WorkBrowseState state) updater) {
    final newState = updater(state);
    // 状态变化时自动保存
    newState.persist();
    state = newState;
  }

  Future<void> restoreState() async {
    state = await WorkBrowseState.restore();
  }

  void setSidebarState(bool sidebarOpen) {
    state = state.copyWith(isSidebarOpen: sidebarOpen);
    // 保存状态
    _stateRestorationService.saveWorkBrowseState(state);
  }

  void setViewMode(ViewMode viewMode) {
    state = state.copyWith(viewMode: viewMode);
    // 保存状态
    _stateRestorationService.saveWorkBrowseState(state);
  }
}