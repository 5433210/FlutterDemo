import 'package:demo/presentation/models/date_range_filter.dart';
import 'package:flutter/material.dart';

enum SortField { 
  none,
  name,
  author,
  creationDate,
  importDate,
}

extension SortFieldX on SortField {
  String get label => switch(this) {
    SortField.none => '默认排序',
    SortField.name => '作品名称',
    SortField.author => '作者',
    SortField.creationDate => '创作时间',
    SortField.importDate => '导入时间',
  };

  String? get fieldName => switch(this) {
    SortField.none => null,
    SortField.name => 'name',
    SortField.author => 'author',
    SortField.creationDate => 'date',
    SortField.importDate => 'import_date',
  };
}

enum DateRangeType {
  lastWeek,
  lastMonth,
  lastYear,
  custom
}

class SortOption {
  final SortField field;
  final bool descending;

  const SortOption({
    this.field = SortField.none,
    this.descending = true,
  });

  bool get isEmpty => field == SortField.none;

  Map<String, dynamic> toQueryParams() {
    if (isEmpty) return {};
    
    return {
      'orderBy': field.fieldName,
      'descending': descending,
    };
  }

  SortOption copyWith({
    SortField? field,
    bool? descending,
  }) {
    return SortOption(
      field: field ?? this.field,
      descending: descending ?? this.descending,
    );
  }
}

class WorkFilter {
  final String? selectedStyle;
  final String? selectedTool;
  final DateRangeFilter? dateFilter;
  final SortOption sortOption;

  const WorkFilter({
    this.selectedStyle,
    this.selectedTool,
    this.dateFilter,
    this.sortOption = const SortOption(),
  });

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (selectedStyle?.isNotEmpty ?? false) {
      params['style'] = selectedStyle;
    }
    
    if (selectedTool?.isNotEmpty ?? false) {
      params['tool'] = selectedTool;
    }

    // 处理日期范围
    if (dateFilter != null) {
      final dateRange = dateFilter!.effectiveRange;
      if (dateRange != null) {
        params['fromDate'] = dateRange.start;
        params['toDate'] = dateRange.end;
      }
    }

    // 处理排序
    params.addAll(sortOption.toQueryParams());

    return params;
  }

  WorkFilter copyWith({
    String? Function()? selectedStyle,
    String? Function()? selectedTool,
    DateRangeFilter? Function()? dateFilter,
    SortOption? sortOption,
  }) {
    return WorkFilter(
      selectedStyle: selectedStyle?.call() ?? this.selectedStyle,
      selectedTool: selectedTool?.call() ?? this.selectedTool,
      dateFilter: dateFilter?.call() ?? this.dateFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}