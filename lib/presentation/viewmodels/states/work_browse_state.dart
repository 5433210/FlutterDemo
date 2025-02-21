import 'package:flutter/material.dart';

import '../../../domain/entities/work.dart';

class WorkBrowseState {
  final List<Work> works;
  final bool isLoading;
  final String? error;
  final SortOption sortOption;
  final String? searchQuery;
  final WorkFilter filter;

  const WorkBrowseState({
    this.works = const [],
    this.isLoading = false,
    this.error,
    this.sortOption = const SortOption(),
    this.searchQuery,
    this.filter = const WorkFilter(),
  });

  WorkBrowseState copyWith({
    List<Work>? works,
    bool? isLoading,
    String? error,
    SortOption? sortOption,
    String? searchQuery,
    WorkFilter? filter,
  }) => WorkBrowseState(
    works: works ?? this.works,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    sortOption: sortOption ?? this.sortOption,
    searchQuery: searchQuery ?? this.searchQuery,
    filter: filter ?? this.filter,
  );
}

class SortOption {
  final SortField field;
  final SortOrder order;

  const SortOption({
    this.field = SortField.updateTime,
    this.order = SortOrder.descending,
  });
}

enum SortField { name, author, createTime, updateTime }
enum SortOrder { ascending, descending }

class WorkFilter {
  final List<String> styles;
  final List<String> tools;
  final DateTimeRange? dateRange;

  const WorkFilter({
    this.styles = const [],
    this.tools = const [],
    this.dateRange,
  });

  bool get isEmpty => styles.isEmpty && tools.isEmpty && dateRange == null;
}