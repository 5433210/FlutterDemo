import 'package:demo/domain/entities/work.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/interfaces/i_work_service.dart';
import '../../infrastructure/config/storage_paths.dart';
import '../models/work_filter.dart';
import 'states/work_browse_state.dart';

class WorkBrowseViewModel extends StateNotifier<WorkBrowseState> {
  final IWorkService _workService;  // 使用接口而不是具体实现
  final StoragePaths _paths;

  WorkBrowseViewModel(this._workService, this._paths) 
      : super(const WorkBrowseState());

  Future<void> loadWorks() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final works = await _workService.queryWorks(
        searchQuery: state.searchQuery,
        filter: state.filter,
      );
      
      state = state.copyWith(
        isLoading: false,
        allWorks: works,
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
    state = state.copyWith(
      filter: filter,
      works: _applyFilter(state.allWorks, filter),
    );
  }

  void updateSearch(String query) {
    state = state.copyWith(
      searchQuery: query,
      works: _applyFilter(state.allWorks, state.filter),
    );
  }

  void updateViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  List<Work> _applyFilter(List<Work> works, WorkFilter filter) {
    var filtered = List<Work>.from(works);

    // 应用搜索
    if (state.searchQuery?.isNotEmpty ?? false) {
      final query = state.searchQuery!.toLowerCase();
      filtered = filtered.where((work) {
        return (work.name?.toLowerCase().contains(query) ?? false) ||
               (work.author?.toLowerCase().contains(query) ?? false) ||
               (work.style?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // 应用风格筛选
    if (filter.selectedStyle != null) {
      filtered = filtered.where((w) => w.style == filter.selectedStyle).toList();
    }

    // 应用工具筛选
    if (filter.selectedTool != null) {
      filtered = filtered.where((w) => w.tool == filter.selectedTool).toList();
    }

    // 应用日期筛选
    if (filter.dateFilter != null) {
      filtered = filtered.where((w) {
        final date = DateTime.tryParse(w.creationDate as String? ?? DateTime.now().toIso8601String());
        if (date == null) return false;
        return filter.dateFilter!.contains(date);
      }).toList();
    }

    // 修改排序逻辑，使用 sortOption
    if (!filter.sortOption.isEmpty) {
      filtered.sort((a, b) {
        int result;
        switch (filter.sortOption.field) {
          case SortField.name:
            result = (a.name ?? '').compareTo(b.name ?? '');
            break;
          case SortField.author:
            result = (a.author ?? '').compareTo(b.author ?? '');
            break;
          case SortField.creationDate:
            result = (a.creationDate ?? DateTime.now()).compareTo(b.creationDate ?? DateTime.now());
            break;
          case SortField.importDate:
            result = (a.importDate ?? DateTime.now())
                .compareTo(b.importDate ?? DateTime.now());
            break;
          case SortField.none:
            result = 0;
            break;
        }
        return filter.sortOption.descending ? -result : result;
      });
    }

    return filtered;
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
      await loadWorks(); // 重新加载数据
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}