import '../../../domain/entities/work.dart';
import '../../models/work_filter.dart';

enum ViewMode { grid, list }

class WorkBrowseState {
  final bool isLoading;
  final String? error;
  final List<Work> works;
  final List<Work> allWorks; // 添加 allWorks 字段
  final String? searchQuery;
  final ViewMode viewMode;
  final SortOption sortOption;
  final WorkFilter filter;

  const WorkBrowseState({
    this.isLoading = false,
    this.error,
    this.works = const [],
    this.allWorks = const [], // 初始化 allWorks
    this.searchQuery,
    this.viewMode = ViewMode.grid,
    this.sortOption = const SortOption(),
    this.filter = const WorkFilter(),
  });

  WorkBrowseState copyWith({
    bool? isLoading,
    String? error,
    List<Work>? works,
    List<Work>? allWorks, // 添加 allWorks
    String? searchQuery,
    ViewMode? viewMode,
    SortOption? sortOption,
    WorkFilter? filter,
  }) {
    return WorkBrowseState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      works: works ?? this.works,
      allWorks: allWorks ?? this.allWorks, // 复制 allWorks
      searchQuery: searchQuery ?? this.searchQuery,
      viewMode: viewMode ?? this.viewMode,
      sortOption: sortOption ?? this.sortOption,
      filter: filter ?? this.filter,
    );
  }
}