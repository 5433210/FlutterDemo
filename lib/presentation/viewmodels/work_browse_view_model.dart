import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../domain/interfaces/i_work_service.dart';
import '../models/work_filter.dart';
import 'states/work_browse_state.dart';

class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final IWorkService _workService;
  Timer? _searchDebounce;

  WorkBrowseViewModel(this._workService) : super(const WorkBrowseState()) {
    loadWorks();
  }

  Future<void> loadWorks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final works = await _workService.getAllWorks();
      state = state.copyWith(
        isLoading: false,
        works: works,
        allWorks: works,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarOpen: !state.isSidebarOpen);
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
    // ...现有删除逻辑
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    state.dispose();
    super.dispose();
  }
}