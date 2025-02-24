import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/interfaces/i_work_service.dart';
import '../models/work_filter.dart';
import 'states/work_browse_state.dart';

class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final IWorkService _workService;

  WorkBrowseViewModel(this._workService) : super(WorkBrowseState(
    isLoading: false,
    error: null,
    works: [],
    allWorks: [],
    searchQuery: null,
    viewMode: ViewMode.grid,
    filter: const WorkFilter(),
    sortOption: const SortOption(),
    isSidebarOpen: true,
  ));

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
    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
    );

    try {
      // 搜索时带上现有的过滤条件
      final works = await _workService.queryWorks(
        searchQuery: query,
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

  void updateFilter(WorkFilter filter) async {
    state = state.copyWith(
      filter: filter,
      isLoading: true,
    );
    
    try {
      // 保持当前搜索条件,使用新的过滤条件查询
      final works = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: filter,
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

  void toggleSortDirection() {
    final currentSort = state.filter.sortOption;
    updateFilter(state.filter.copyWith(
      sortOption: currentSort.copyWith(
        descending: !currentSort.descending,  
      ),
    ));
  }
}