import 'package:demo/domain/entities/work.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/interfaces/i_work_service.dart';
import '../models/work_filter.dart';
import 'states/work_browse_state.dart';

class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final IWorkService _workService;

  WorkBrowseViewModel(this._workService) 
      : super(const WorkBrowseState());

  void toggleSidebar() {
    state = state.copyWith(isSidebarOpen: !state.isSidebarOpen);
  }

   void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
   }

  Future<void> loadWorks() async {
    state = state.copyWith(isLoading: true);
    try {
      final works = await _workService.getAllWorks();
      // 默认按创建时间降序排序
      works.sort((a, b) => (b.createTime ?? DateTime.now())
          .compareTo(a.createTime ?? DateTime.now()));
      
      state = state.copyWith(
        works: works,
        allWorks: works,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  void updateFilter(WorkFilter newFilter) {
    // 如果点击已选中的筛选条件，则清除该条件
    if (state.filter == newFilter) {
      state = state.copyWith(
        filter: const WorkFilter(),
        works: _applySortToWorks(state.allWorks),
      );
    } else {
      final filteredWorks = _applyFilter(state.allWorks, newFilter);
      state = state.copyWith(
        filter: newFilter,
        works: _applySortToWorks(filteredWorks),
      );
    }
  }

  void toggleSortDirection() {
    final newSortOption = state.sortOption.copyWith(
      descending: !state.sortOption.descending,
    );
    state = state.copyWith(
      sortOption: newSortOption,
      works: _applySortToWorks(state.works),
    );
  }

  List<Work> _applySortToWorks(List<Work> works) {
    final sorted = List<Work>.from(works);
    sorted.sort((a, b) {
      // 始终使用 createTime 作为默认排序字段
      final result = (a.createTime ?? DateTime.now())
          .compareTo(b.createTime ?? DateTime.now());
      return state.sortOption.descending ? -result : result;
    });
    return sorted;
  }

  List<Work> _applyFilter(List<Work> works, WorkFilter filter) {
    var filtered = List<Work>.from(works);

    if (state.searchQuery?.isNotEmpty ?? false) {
      final query = state.searchQuery!.toLowerCase();
      filtered = filtered.where((work) {
        return (work.name?.toLowerCase().contains(query) ?? false) ||
               (work.author?.toLowerCase().contains(query) ?? false) ||
               (work.style?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (filter.selectedStyle != null) {
      filtered = filtered.where((w) => w.style == filter.selectedStyle).toList();
    }
  
    if (filter.selectedTool != null) {
      filtered = filtered.where((w) => w.tool == filter.selectedTool).toList();
    }
  
    if (filter.dateFilter != null) {
      filtered = filtered.where((w) {
        final date = w.creationDate;
        if (date == null) return false;
        return filter.dateFilter!.contains(date);
      }).toList();
    }

    return filtered;
  }

  Future<void> searchWorks(String query) async {
    state = state.copyWith(
      searchQuery: query,
      isLoading: true,
      error: null
    );
    
    try {
      final filtered = _applyFilter(state.allWorks, state.filter);
      state = state.copyWith(
        works: _applySortToWorks(filtered),
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<String?> getWorkThumbnail(String workId) async {
    try {
      return await _workService.getWorkThumbnail(workId);
    } catch (e) {
      return null;
    }
  }

  Future<void> deleteWork(String workId) async {
    try {
      await _workService.deleteWork(workId);
      await loadWorks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshAfterImport() async {
    await loadWorks();
  }
}