import 'package:demo/presentation/models/date_range_filter.dart';
import 'package:flutter/material.dart';

import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';

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
  final WorkStyle? style;
  final WorkTool? tool;
  final DateRangePreset? datePreset;
  final DateTimeRange? dateRange;
  final SortOption sortOption;

  const WorkFilter({
    this.style,
    this.tool,
    this.datePreset,
    this.dateRange,
    this.sortOption = const SortOption(),
  });

  bool get isEmpty => style == null && tool == null && dateRange == null;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (style != null) {
      params['style'] = style;
    }
    
    if (tool != null) {
      params['tool'] = tool;
    }

    // 处理日期范围
    if (datePreset != null) {
      final range = datePreset?.getRange();
      if (range != null) {
        params['fromDate'] = range.start;
        params['toDate'] = range.end;
      }      
    } else if (dateRange != null) {
      params['fromDate'] = dateRange?.start;
      params['toDate'] = dateRange?.end;
    }

    // 处理排序
    params.addAll(sortOption.toQueryParams());

    return params;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WorkFilter &&
           other.style == style &&
           other.tool == tool &&
           other.dateRange == dateRange;
  }

  @override
  int get hashCode => Object.hash(style, tool, dateRange);

  WorkFilter copyWith({
    WorkStyle? style,
    WorkTool? tool,
    DateTimeRange? dateRange,
    SortOption? sortOption,
  }) {
    return WorkFilter(
      style: style ?? this.style,
      tool: tool ?? this.tool,
      dateRange: dateRange ?? this.dateRange,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}