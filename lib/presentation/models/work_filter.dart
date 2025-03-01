import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/enums/work_style.dart';
import '../../domain/enums/work_tool.dart';
import 'date_range_filter.dart';

enum SortField {
  none,
  name,
  author,
  creationDate,
  importDate,
  updateDate // 添加更新时间选项
}

class SortOption {
  final SortField field;
  final bool descending;

  const SortOption({
    this.field = SortField.creationDate, // 默认按创作时间
    this.descending = true, // 默认降序
  });

  factory SortOption.fromJson(Map<String, dynamic> json) {
    return SortOption(
      field: SortField.values[json['field'] as int],
      descending: json['descending'] as bool,
    );
  }

  bool get isEmpty => field == SortField.none;

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

  Map<String, dynamic> toQueryParams() {
    if (isEmpty) return {};

    return {
      'orderBy': field.fieldName,
      'descending': descending,
    };
  }
}

class WorkFilter {
  final WorkStyle? style;
  final WorkTool? tool;
  final DateRangePreset? datePreset; // 新增：快捷日期预设
  final DateTimeRange? dateRange; // 新增：自定义日期范围
  final SortOption sortOption;

  const WorkFilter({
    this.style,
    this.tool,
    this.datePreset,
    this.dateRange,
    this.sortOption = const SortOption(),
  });

  factory WorkFilter.fromJson(Map<String, dynamic> json) {
    return WorkFilter(
      style: json['style'] != null
          ? WorkStyle.fromValue(json['style'] as String)
          : null,
      tool: json['tool'] != null
          ? WorkTool.fromValue(json['tool'] as String)
          : null,
      datePreset: json['datePreset'] != null
          ? DateRangePreset.values[json['datePreset'] as int]
          : null,
      dateRange: json['dateRange'] != null
          ? DateTimeRange(
              start: DateTime.parse(json['dateRange']['start']),
              end: DateTime.parse(json['dateRange']['end']),
            )
          : null,
      sortOption: json['sortOption'] != null
          ? SortOption.fromJson(json['sortOption'])
          : const SortOption(),
    );
  }

  factory WorkFilter.fromJsonString(String jsonString) =>
      WorkFilter.fromJson(jsonDecode(jsonString));

  @override
  int get hashCode => Object.hash(
        style,
        tool,
        datePreset,
        dateRange,
        sortOption,
      );

  bool get isEmpty =>
      style == null &&
      tool == null &&
      datePreset == null &&
      dateRange == null &&
      sortOption.field == SortField.none;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkFilter &&
          style == other.style &&
          tool == other.tool &&
          datePreset == other.datePreset &&
          dateRange == other.dateRange &&
          sortOption == other.sortOption;

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
        'dateRange': dateRange != null
            ? {
                'start': dateRange!.start.toIso8601String(),
                'end': dateRange!.end.toIso8601String(),
              }
            : null,
        'sortOption': sortOption.toJson(),
      };

  // 添加字符串转换方法，方便存储和调试
  String toJsonString() => jsonEncode(toJson());

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
}

extension SortFieldX on SortField {
  String? get fieldName => switch (this) {
        SortField.none => null,
        SortField.name => 'name',
        SortField.author => 'author',
        SortField.creationDate => 'creationDate', // 修正字段名
        SortField.importDate => 'createTime', // 修正字段名
        SortField.updateDate => 'updateTime', // 修正字段名
      };

  String get label => switch (this) {
        SortField.none => '默认排序',
        SortField.name => '作品名称',
        SortField.author => '作者',
        SortField.creationDate => '创作时间',
        SortField.importDate => '导入时间',
        SortField.updateDate => '更新时间',
      };
}
