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
  final String? style;
  final String? tool;
  final DateRangeType? dateRangeType;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
    final SortOption sortOption;
  final String selectedStyle;
  final String selectedTool;
  final String? sortBy;
  final bool descending;
  final DateRangeFilter? dateFilter;

  const WorkFilter({
    this.style,
    this.tool,
    this.dateRangeType,
    this.customStartDate,
    this.customEndDate,
    this.selectedStyle  = '',
    this.selectedTool = '',
    this.sortOption = const SortOption(),
    this.sortBy,
    this.descending = true,
    this.dateFilter
  });

WorkFilter copyWith({
    SortOption? sortOption,
    String? Function()? selectedStyle,
    String? Function()? selectedTool,
    DateRangeFilter? Function()? dateFilter,
  }) {
    return WorkFilter(
      sortOption: sortOption ?? this.sortOption,
      selectedStyle: selectedStyle != null ? selectedStyle() ?? '' : this.selectedStyle,
      selectedTool: selectedTool != null ? selectedTool() ?? '' : this.selectedTool,
      dateFilter: dateFilter != null ? dateFilter() : this.dateFilter,
    );
  }

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (style?.isNotEmpty ?? false) {
      params['selectedStyle'] = style;
    }
    
    if (tool?.isNotEmpty ?? false) {
      params['selectedTool'] = tool;
    }

    // 处理日期范围
    if (dateRangeType != null) {
      final now = DateTime.now();
      DateTime? start;
      DateTime? end = now;

      switch (dateRangeType) {
        case DateRangeType.lastWeek:
          start = now.subtract(const Duration(days: 7));
          break;
        case DateRangeType.lastMonth:
          start = DateTime(now.year, now.month - 1, now.day);
          break;
        case DateRangeType.lastYear:
          start = DateTime(now.year - 1, now.month, now.day);
          break;
        case DateRangeType.custom:
          start = customStartDate;
          end = customEndDate ?? now;
          break;
        case null:
          // TODO: Handle this case.
          throw UnimplementedError();
      }

      if (start != null) {
        params['dateFilter'] = DateTimeRange(start: start, end: end);
      }
    }

    if (sortBy?.isNotEmpty ?? false) {
      params['orderBy'] = sortBy;
      params['descending'] = descending;
    }

    return params;
  }
}