import '../../../domain/entities/work.dart';
import '../../models/work_filter.dart';
import 'package:flutter/material.dart';

enum ViewMode { grid, list }

class WorkBrowseState {
  // 视图状态
  final ViewMode viewMode;
  final bool isSidebarOpen;
  
  // 选择状态
  final bool batchMode;
  final Set<String> selectedWorks;
  
  // 搜索和过滤状态
  final String searchQuery;
  final WorkFilter filter;
  final SortOption sortOption;
  
  // 数据状态
  final bool isLoading;
  final List<Work> works;
  final String? error;
  final TextEditingController searchController;

  // 添加分页相关状态
  final int page;
  final int pageSize;
  final bool hasMore;
  final bool isLoadingMore;

  const WorkBrowseState({
    this.isLoading = false,
    this.error,
    this.works = const [],
    this.searchQuery = '',
    this.viewMode = ViewMode.grid,
    this.sortOption = const SortOption(),
    this.filter = const WorkFilter(),
    this.isSidebarOpen = true,  // 默认展开
    this.batchMode = false,
    this.selectedWorks = const {},
    TextEditingController? searchController,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = true,
    this.isLoadingMore = false,
  }) : searchController = searchController ?? TextEditingController();

  WorkBrowseState copyWith({
    bool? isLoading,
    String? error,
    List<Work>? works,
    String? searchQuery,  // 添加 searchQuery
    ViewMode? viewMode,
    SortOption? sortOption,
    WorkFilter? filter,
    bool? isSidebarOpen,  // 新增字段
    bool? batchMode,
    Set<String>? selectedWorks,
    TextEditingController? searchController,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return WorkBrowseState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      works: works ?? this.works,
      searchQuery: searchQuery ?? this.searchQuery,  // 保持搜索条件
      viewMode: viewMode ?? this.viewMode,
      sortOption: sortOption ?? this.sortOption,
      filter: filter ?? this.filter,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen,  // 复制 isSidebarOpen
      batchMode: batchMode ?? this.batchMode,
      selectedWorks: selectedWorks ?? this.selectedWorks,
      searchController: searchController ?? this.searchController,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}