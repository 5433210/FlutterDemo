import 'package:demo/domain/entities/work.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
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

  Future<void> _loadWorks() async {
    state = state.copyWith(isLoading: true);
    try {
      final works = await _workService.getAllWorks();
      final filtered = _applyFilter(works, state.filter);
      state = state.copyWith(
        works: _applySortToWorks(filtered),
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
    if (filter.isEmpty) {
      return works;
    }

    var filtered = List<Work>.from(works);

    if (filter.style != null) {
      filtered = filtered.where((w) => w.style == filter.style).toList();
    }
  
    if (filter.tool != null) {
      filtered = filtered.where((w) => w.tool == filter.tool).toList();
    }
  
    if (filter.dateRange != null) {
      filtered = filtered.where((w) {
        final date = w.creationDate ?? w.createTime;
        if (date == null) return false;
        return date.isAfter(filter.dateRange!.start) && 
               date.isBefore(filter.dateRange!.end.add(const Duration(days: 1)));
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

  void updateFilter(WorkFilter filter) {
    if (filter == state.filter) {
      // If clicking the same filter, clear it
      state = state.copyWith(
        filter: const WorkFilter(),
        isLoading: true,
      );
    } else {
      state = state.copyWith(
        filter: filter,
        isLoading: true,
      );
    }
    _loadWorks();
  }

  void toggleStyle(WorkStyle? style) {
    final currentStyle = state.filter.style;
    final newFilter = state.filter.copyWith(
      style: currentStyle == style ? null : style,
    );
    updateFilter(newFilter);
  }

  void toggleTool(WorkTool? tool) {
    final currentTool = state.filter.tool;
    final newFilter = state.filter.copyWith(
      tool: currentTool == tool ? null : tool,
    );
    updateFilter(newFilter);
  }

  void toggleDateRange(DateTimeRange? dateRange) {
    final currentRange = state.filter.dateRange;
    final isEqual = currentRange != null && dateRange != null &&
        currentRange.start == dateRange.start && 
        currentRange.end == dateRange.end;
        
    final newFilter = state.filter.copyWith(
      dateRange: isEqual ? null : dateRange,
    );
    updateFilter(newFilter);
  }
}