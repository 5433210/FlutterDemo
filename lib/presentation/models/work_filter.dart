import 'package:demo/presentation/models/date_range_filter.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';

enum SortField { 
  none,
  name,
  author,
  creationDate,
  importDate,
  updateDate  // 添加更新时间选项
}

extension SortFieldX on SortField {
  String get label => switch(this) {
    SortField.none => '默认排序',
    SortField.name => '作品名称',
    SortField.author => '作者',
    SortField.creationDate => '创作时间',
    SortField.importDate => '导入时间',
    SortField.updateDate => '更新时间',
  };

  String? get fieldName => switch(this) {
    SortField.none => null,
    SortField.name => 'name',
    SortField.author => 'author',
    SortField.creationDate => 'date',
    SortField.importDate => 'import_date',
    // TODO: Handle this case.
    SortField.updateDate =>'update_date',
  };
}

class SortOption {
  final SortField field;
  final bool descending;

  const SortOption({
    this.field = SortField.creationDate,  // 默认按创作时间
    this.descending = true,  // 默认降序
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

  Map<String, dynamic> toJson() => {
    'field': field.index,
    'descending': descending,
  };

  factory SortOption.fromJson(Map<String, dynamic> json) {
    return SortOption(
      field: SortField.values[json['field'] as int],
      descending: json['descending'] as bool,
    );
  }
}

class WorkFilter {
  final WorkStyle? style;
  final WorkTool? tool;
  final DateRangePreset? datePreset;  // 新增：快捷日期预设
  final DateTimeRange? dateRange;      // 新增：自定义日期范围
  final SortOption sortOption;         // 新增：排序选项

  const WorkFilter({
    this.style,
    this.tool,
    this.datePreset,
    this.dateRange,
    this.sortOption = const SortOption(),
  });

  bool get isEmpty => 
    style == null && 
    tool == null && 
    datePreset == null &&
    dateRange == null &&
    sortOption.field == SortField.none;

  Map<String, dynamic> toQueryParams() {
    final params = <String, dynamic>{};
    
    if (style != null) {
      params['style'] = style!.value;
    }
    
    if (tool != null) {
      params['tool'] = tool!.value;
    }

    if (dateRange != null) {
      params['date_from'] = dateRange!.start.toIso8601String();
      params['date_to'] = dateRange!.end.toIso8601String();
    }

    if (!sortOption.isEmpty) {
      params.addAll(sortOption.toQueryParams());
    }

    return params;
  }

  WorkFilter copyWith({
    WorkStyle? Function()? style,
    WorkTool? Function()? tool,
    DateRangePreset? Function()? datePreset,
    DateTimeRange? Function()? dateRange,
    SortOption? sortOption,
  }) {
    return WorkFilter(
      style: style != null ? style() : this.style,
      tool: tool != null ? tool() : this.tool,
      datePreset: datePreset != null ? datePreset() : this.datePreset,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      sortOption: sortOption ?? this.sortOption,
    );
  }

  Map<String, dynamic> toJson() => {
    'style': style?.value,
    'tool': tool?.value,
    'datePreset': datePreset?.index,
    'dateRange': dateRange != null ? {
      'start': dateRange!.start.toIso8601String(),
      'end': dateRange!.end.toIso8601String(),
    } : null,
    'sortOption': sortOption.toJson(),
  };

  factory WorkFilter.fromJson(Map<String, dynamic> json) {
    return WorkFilter(
      style: json['style'] != null ? WorkStyle.values.firstWhere(
        (e) => e.value == json['style'],
      ) : null,
      tool: json['tool'] != null ? WorkTool.values.firstWhere(
        (e) => e.value == json['tool'],
      ) : null,
      datePreset: json['datePreset'] != null ? 
        DateRangePreset.values[json['datePreset'] as int] : null,
      dateRange: json['dateRange'] != null ? DateTimeRange(
        start: DateTime.parse(json['dateRange']['start']),
        end: DateTime.parse(json['dateRange']['end']),
      ) : null,
      sortOption: json['sortOption'] != null ? 
        SortOption.fromJson(json['sortOption']) : const SortOption(),
    );
  }

  // 添加字符串转换方法，方便存储和调试
  String toJsonString() => jsonEncode(toJson());
  
  factory WorkFilter.fromJsonString(String jsonString) =>
      WorkFilter.fromJson(jsonDecode(jsonString));

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is WorkFilter &&
    style == other.style &&
    tool == other.tool &&
    datePreset == other.datePreset &&
    dateRange == other.dateRange &&
    sortOption == other.sortOption;

  @override
  int get hashCode => Object.hash(
    style, 
    tool, 
    datePreset,
    dateRange,
    sortOption,
  );
}