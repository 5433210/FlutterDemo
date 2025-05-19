import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/practice/practice_filter.dart';
import '../../../infrastructure/logging/logger.dart';

class PracticeListState {
  // 视图状态
  final PracticeViewMode viewMode;
  final bool isFilterPanelExpanded;

  // 选择状态
  final bool batchMode;
  final Set<String> selectedPractices;

  // 搜索和过滤状态
  final String searchQuery;
  final PracticeFilter filter;

  // 数据状态
  final bool isLoading;
  final List<Map<String, dynamic>> practices;
  final String? error;
  final TextEditingController searchController;

  // 分页相关状态
  final int page;
  final int pageSize;
  final int totalItems;

  PracticeListState({
    this.viewMode = PracticeViewMode.grid,
    this.isFilterPanelExpanded = true,
    this.batchMode = false,
    this.selectedPractices = const {},
    this.searchQuery = '',
    this.filter = const PracticeFilter(),
    this.isLoading = false,
    this.practices = const [],
    this.error,
    TextEditingController? searchController,
    this.page = 1,
    this.pageSize = 20,
    this.totalItems = 0,
  }) : searchController = searchController ?? TextEditingController();

  PracticeListState copyWith({
    PracticeViewMode? viewMode,
    bool? isFilterPanelExpanded,
    bool? batchMode,
    Set<String>? selectedPractices,
    String? searchQuery,
    PracticeFilter? filter,
    bool? isLoading,
    List<Map<String, dynamic>>? practices,
    String? error,
    TextEditingController? searchController,
    int? page,
    int? pageSize,
    int? totalItems,
  }) {
    return PracticeListState(
      viewMode: viewMode ?? this.viewMode,
      isFilterPanelExpanded:
          isFilterPanelExpanded ?? this.isFilterPanelExpanded,
      batchMode: batchMode ?? this.batchMode,
      selectedPractices: selectedPractices ?? this.selectedPractices,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      practices: practices ?? this.practices,
      error: error,
      searchController: searchController ?? this.searchController,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  void dispose() {
    searchController.dispose();
  }

  // 序列化方法，用于保存状态
  Map<String, dynamic> toJson() {
    AppLogger.debug('Serializing PracticeListState', tag: 'State');

    final result = {
      'viewMode': viewMode.index,
      'isFilterPanelExpanded': isFilterPanelExpanded,
      'searchQuery': searchQuery,
      'filter': filter.toJson(),
      'page': page,
      'pageSize': pageSize,
      // 不序列化临时状态如 batchMode, selectedPractices, isLoading 等
    };

    AppLogger.debug('PracticeListState serialized successfully', tag: 'State');
    return result;
  }

  // 反序列化方法，用于恢复状态
  static PracticeListState fromJson(Map<String, dynamic> json) {
    try {
      AppLogger.debug('Deserializing PracticeListState',
          tag: 'State', data: {'json': json});

      final result = PracticeListState(
        viewMode: json['viewMode'] != null
            ? PracticeViewMode.values[json['viewMode'] as int]
            : PracticeViewMode.grid,
        isFilterPanelExpanded: json['isFilterPanelExpanded'] as bool? ?? true,
        searchQuery: json['searchQuery'] as String? ?? '',
        filter: json['filter'] != null
            ? PracticeFilter.fromJson(json['filter'] as Map<String, dynamic>)
            : const PracticeFilter(),
        page: json['page'] as int? ?? 1,
        pageSize: json['pageSize'] as int? ?? 20,
        // 默认值
        isLoading: false,
        practices: const [],
        selectedPractices: const {},
      );

      AppLogger.debug('PracticeListState deserialized successfully',
          tag: 'State',
          data: {
            'viewMode': result.viewMode.toString(),
            'isFilterPanelExpanded': result.isFilterPanelExpanded,
          });

      return result;
    } catch (e, stack) {
      AppLogger.error(
        'Error deserializing PracticeListState',
        tag: 'State',
        error: e,
        stackTrace: stack,
      );

      // 出错时返回默认状态
      return PracticeListState();
    }
  }
}

enum PracticeViewMode { grid, list }

// 扩展方法，提供状态持久化功能
extension PracticeListStatePersistence on PracticeListState {
  static const String _keyPracticeListState = 'practice_list_state';

  Future<void> persist() async {
    try {
      AppLogger.debug('Persisting PracticeListState', tag: 'State');

      final prefs = await SharedPreferences.getInstance();
      final jsonData = toJson();
      final jsonString = jsonEncode(jsonData);
      await prefs.setString(_keyPracticeListState, jsonString);

      AppLogger.debug('PracticeListState persisted successfully', tag: 'State');
    } catch (e, stack) {
      AppLogger.error('Failed to persist PracticeListState',
          tag: 'State', error: e, stackTrace: stack);
    }
  }

  static Future<PracticeListState> restore() async {
    try {
      AppLogger.debug('Restoring PracticeListState', tag: 'State');

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPracticeListState);

      if (jsonString == null) {
        AppLogger.debug('No saved PracticeListState found, using defaults',
            tag: 'State');
        return PracticeListState();
      }

      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final state = PracticeListState.fromJson(jsonData);

      AppLogger.debug('PracticeListState restored successfully',
          tag: 'State', data: {'viewMode': state.viewMode.toString()});

      return state;
    } catch (e, stack) {
      AppLogger.error('Failed to restore PracticeListState',
          tag: 'State', error: e, stackTrace: stack);
      return PracticeListState();
    }
  }
}
