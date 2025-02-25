import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  WorkBrowseState({
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

@override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkBrowseState &&
        listEquals(works, other.works) &&  // 使用 listEquals 比较列表
        filter == other.filter &&
        viewMode == other.viewMode &&
        isLoading == other.isLoading &&
        error == other.error &&
        batchMode == other.batchMode &&
        setEquals(selectedWorks, other.selectedWorks);  // 使用 setEquals 比较集合
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(works),
        filter,
        viewMode,
        isLoading,
        error,
        batchMode,
        Object.hashAll(selectedWorks),
      );
      
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
    // Add debug print to verify state updates
    debugPrint('WorkBrowseState.copyWith - new works count: ${works?.length ?? this.works.length}');

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

  void dispose() {
    searchController.dispose();
  }

  static restore() {}
}

extension WorkBrowseStatePersistence on WorkBrowseState {
  static const String _keyViewMode = 'work_browse_view_mode';
  static const String _keySidebarOpen = 'work_browse_sidebar_open';
  static const String _keyFilter = 'work_browse_filter';
  
  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyViewMode, viewMode.toString());
    await prefs.setBool(_keySidebarOpen, isSidebarOpen);
    await prefs.setString(_keyFilter, filter.toJson().toString());
  }

  static Future<WorkBrowseState> restore() async {
    final prefs = await SharedPreferences.getInstance();
    return WorkBrowseState(
      viewMode: _parseViewMode(prefs.getString(_keyViewMode)),
      isSidebarOpen: prefs.getBool(_keySidebarOpen) ?? true,
      filter: _parseFilter(prefs.getString(_keyFilter)),
    );
  }

  static ViewMode _parseViewMode(String? value) {
    if (value == null) return ViewMode.grid;
    return ViewMode.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => ViewMode.grid,
    );
  }

  static WorkFilter _parseFilter(String? value) {
    if (value == null) return const WorkFilter();
    try {
      return WorkFilter.fromJson(jsonDecode(value));
    } catch (e) {
      return const WorkFilter();
    }
  }
}