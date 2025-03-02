import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/work.dart';
import '../../../infrastructure/logging/logger.dart'; // 添加日志导入
import '../../models/work_filter.dart';

enum LoadRequestStatus {
  idle, // 空闲
  throttled, // 节流中（已请求但等待执行）
  loading, // 加载中
}

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

  // 添加一个字段表示请求状态
  final LoadRequestStatus requestStatus;

  WorkBrowseState({
    this.isLoading = false,
    this.error,
    this.works = const [],
    this.searchQuery = '',
    this.viewMode = ViewMode.grid,
    this.sortOption = const SortOption(),
    this.filter = const WorkFilter(),
    this.isSidebarOpen = true, // 默认展开
    this.batchMode = false,
    this.selectedWorks = const {},
    TextEditingController? searchController,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.requestStatus = LoadRequestStatus.idle,
  }) : searchController = searchController ?? TextEditingController();

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkBrowseState &&
        listEquals(works, other.works) && // 使用 listEquals 比较列表
        filter == other.filter &&
        viewMode == other.viewMode &&
        isLoading == other.isLoading &&
        error == other.error &&
        batchMode == other.batchMode &&
        setEquals(selectedWorks, other.selectedWorks); // 使用 setEquals 比较集合
  }

  WorkBrowseState copyWith({
    bool? isLoading,
    String? error,
    List<Work>? works,
    String? searchQuery, // 添加 searchQuery
    ViewMode? viewMode,
    SortOption? sortOption,
    WorkFilter? filter,
    bool? isSidebarOpen, // 新增字段
    bool? batchMode,
    Set<String>? selectedWorks,
    TextEditingController? searchController,
    int? page,
    int? pageSize,
    bool? hasMore,
    bool? isLoadingMore,
    int? totalCount,
    LoadRequestStatus? requestStatus,
  }) {
    // Add debug print to verify state updates
    debugPrint(
        'WorkBrowseState.copyWith - new works count: ${works?.length ?? this.works.length}');

    return WorkBrowseState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      works: works ?? this.works,
      searchQuery: searchQuery ?? this.searchQuery, // 保持搜索条件
      viewMode: viewMode ?? this.viewMode,
      sortOption: sortOption ?? this.sortOption,
      filter: filter ?? this.filter,
      isSidebarOpen: isSidebarOpen ?? this.isSidebarOpen, // 复制 isSidebarOpen
      batchMode: batchMode ?? this.batchMode,
      selectedWorks: selectedWorks ?? this.selectedWorks,
      searchController: searchController ?? this.searchController,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      requestStatus: requestStatus ?? this.requestStatus,
    );
  }

  void dispose() {
    searchController.dispose();
  }

  // 添加 toJson 方法，用于序列化
  Map<String, dynamic> toJson() {
    AppLogger.debug('Serializing WorkBrowseState', tag: 'State');

    final result = {
      'viewMode': viewMode.index,
      'isSidebarOpen': isSidebarOpen,
      'searchQuery': searchQuery,
      'filter': filter.toJson(),
      'sortOption': sortOption.toJson(),
      'page': page,
      'pageSize': pageSize,
      'hasMore': hasMore,
      // 不序列化状态数据如 isLoading、works、error 等
      // 不序列化 TextEditingController
      // 不序列化 batchMode 和 selectedWorks，因为这些是临时选择状态
    };

    AppLogger.debug('WorkBrowseState serialized successfully', tag: 'State');
    return result;
  }

  // 添加 fromJson 静态方法，用于反序列化
  static WorkBrowseState fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('Deserializing WorkBrowseState',
          tag: 'State', data: {'json': json});

      final result = WorkBrowseState(
        viewMode: json['viewMode'] != null
            ? ViewMode.values[json['viewMode'] as int]
            : ViewMode.grid,
        isSidebarOpen: json['isSidebarOpen'] as bool? ?? true,
        searchQuery: json['searchQuery'] as String? ?? '',
        filter: json['filter'] != null
            ? WorkFilter.fromJson(json['filter'] as Map<String, dynamic>)
            : const WorkFilter(),
        sortOption: json['sortOption'] != null
            ? SortOption.fromJson(json['sortOption'] as Map<String, dynamic>)
            : const SortOption(),
        page: json['page'] as int? ?? 1,
        pageSize: json['pageSize'] as int? ?? 20,
        hasMore: json['hasMore'] as bool? ?? true,
        // 默认值
        isLoading: false,
        works: const [],
        selectedWorks: const {},
      );

      AppLogger.debug('WorkBrowseState deserialized successfully',
          tag: 'State',
          data: {
            'viewMode': result.viewMode.toString(),
            'isSidebarOpen': result.isSidebarOpen,
          });

      return result;
    } catch (e, stack) {
      AppLogger.error(
        'Error deserializing WorkBrowseState',
        tag: 'State',
        error: e,
        stackTrace: stack,
        data: {'json': json},
      );

      // 出错时返回默认状态
      return WorkBrowseState();
    }
  }
}

extension WorkBrowseStatePersistence on WorkBrowseState {
  static const String _keyWorkBrowseState = 'work_browse_state';

  Future<void> persist() async {
    try {
      AppLogger.debug('Persisting WorkBrowseState', tag: 'State');

      final prefs = await SharedPreferences.getInstance();
      final jsonData = toJson();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_keyWorkBrowseState, jsonString);

      AppLogger.debug('WorkBrowseState persisted successfully', tag: 'State');
    } catch (e, stack) {
      AppLogger.error('Failed to persist WorkBrowseState',
          tag: 'State', error: e, stackTrace: stack);
    }
  }

  static Future<WorkBrowseState> restore() async {
    try {
      AppLogger.debug('Restoring WorkBrowseState', tag: 'State');

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyWorkBrowseState);

      if (jsonString == null) {
        AppLogger.debug('No saved WorkBrowseState found, using defaults',
            tag: 'State');
        return WorkBrowseState();
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = WorkBrowseState.fromJson(jsonData);

      AppLogger.debug('WorkBrowseState restored successfully',
          tag: 'State', data: {'viewMode': state.viewMode.toString()});

      return state;
    } catch (e, stack) {
      AppLogger.error('Failed to restore WorkBrowseState',
          tag: 'State', error: e, stackTrace: stack);
      return WorkBrowseState();
    }
  }

  // 删除旧方法，我们现在使用更强大的JSON序列化方法
}
