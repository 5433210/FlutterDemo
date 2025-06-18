import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/date_range_filter.dart';
import '../common/sort_option.dart';

part 'work_filter.freezed.dart';
part 'work_filter.g.dart';

DateTimeRange? _dateRangeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTimeRange) return value;
  return DateTimeRange(
    start: DateTime.parse(value['start']),
    end: DateTime.parse(value['end']),
  );
}

DateRangePreset _dateRangePresetFromJson(dynamic value) {
  if (value is DateRangePreset) return value;
  final str = value?.toString() ?? '';
  return DateRangePreset.values.firstWhere(
    (e) => e.name == str,
    orElse: () => DateRangePreset.all,
  );
}

String _dateRangePresetToJson(DateRangePreset preset) => preset.name;

Map<String, dynamic>? _dateRangeToJson(DateTimeRange? range) {
  if (range == null) return null;
  return {
    'start': range.start.toIso8601String(),
    'end': range.end.toIso8601String()
  };
}

// 处理可空的风格值
String? _workStyleFilterFromJson(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return value.toString();
}

/// 枚举序列化辅助方法
String? _workStyleToJson(String? style) => style;

// 处理可空的工具值
String? _workToolFilterFromJson(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return value.toString();
}

String? _workToolToJson(String? tool) => tool;

/// 作品筛选条件
@freezed
class WorkFilter with _$WorkFilter {
  const factory WorkFilter({
    /// 搜索关键字
    String? keyword,    /// 作品风格
    @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
    String? style,

    /// 创作工具
    @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
    String? tool,

    /// 标签
    @Default([]) List<String> tags,

    /// 创作日期区间
    @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
    DateTimeRange? dateRange,

    /// 创建时间区间
    @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
    DateTimeRange? createTimeRange,

    /// 修改时间区间
    @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
    DateTimeRange? updateTimeRange,

    /// 日期预设
    @Default(DateRangePreset.all)
    @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
    DateRangePreset datePreset,

    /// 排序选项
    @Default(SortOption()) SortOption sortOption,

    /// 分页大小
    int? limit,

    /// 分页偏移量
    int? offset,

    /// 是否只显示收藏
    @Default(false) bool isFavoriteOnly,
  }) = _WorkFilter;

  factory WorkFilter.fromJson(Map<String, dynamic> json) =>
      _$WorkFilterFromJson(json);

  const WorkFilter._();

  /// 是否为空过滤器
  bool get isEmpty =>
      keyword == null &&
      style == null &&
      tool == null &&
      tags.isEmpty &&
      dateRange == null &&
      createTimeRange == null &&
      updateTimeRange == null &&
      datePreset == DateRangePreset.all &&
      sortOption.isDefault &&
      isFavoriteOnly == false;

  /// 添加标签
  WorkFilter addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// 清除全部筛选
  WorkFilter clear() => const WorkFilter();

  /// 清除标签
  WorkFilter clearTags() => copyWith(tags: const []);

  /// 移除标签
  WorkFilter removeTag(String tag) {
    return copyWith(tags: [...tags]..remove(tag));
  }
}
