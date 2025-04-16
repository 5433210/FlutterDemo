import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/work_style.dart';
import '../../enums/work_tool.dart';
import '../common/date_range_filter.dart';
import '../common/sort_option.dart';

part 'character_filter.freezed.dart';
part 'character_filter.g.dart';

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
WorkStyle? _workStyleFilterFromJson(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return WorkStyle.fromValue(value);
}

/// 枚举序列化辅助方法
String? _workStyleToJson(WorkStyle? style) => style?.value;

// 处理可空的工具值
WorkTool? _workToolFilterFromJson(dynamic value) {
  if (value == null || value.toString().isEmpty) return null;
  return WorkTool.fromValue(value);
}

String? _workToolToJson(WorkTool? tool) => tool?.value;

/// 字符筛选条件模型 - 用于字符管理页面的筛选
@freezed
class CharacterFilter with _$CharacterFilter {
  /// Default constructor
  const factory CharacterFilter({
    /// 搜索文本（对应简体字、作品名称、作者等）
    String? searchText,

    /// 是否仅显示收藏的字符
    bool? isFavorite,

    /// 作品ID筛选
    String? workId,

    /// 作品风格
    @JsonKey(fromJson: _workStyleFilterFromJson, toJson: _workStyleToJson)
    WorkStyle? style,

    /// 创作工具
    @JsonKey(fromJson: _workToolFilterFromJson, toJson: _workToolToJson)
    WorkTool? tool,

    /// 创作时间筛选预设
    @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
    @Default(DateRangePreset.all)
    DateRangePreset creationDatePreset,

    /// 创作时间范围（自定义时间段）
    @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
    DateTimeRange? creationDateRange,

    /// 收集时间筛选预设
    @JsonKey(fromJson: _dateRangePresetFromJson, toJson: _dateRangePresetToJson)
    @Default(DateRangePreset.all)
    DateRangePreset collectionDatePreset,

    /// 收集时间范围（自定义时间段）
    @JsonKey(fromJson: _dateRangeFromJson, toJson: _dateRangeToJson)
    DateTimeRange? collectionDateRange,

    /// 标签筛选
    @Default([]) List<String> tags,

    /// 排序选项
    @Default(SortOption()) SortOption sortOption,

    /// 分页限制
    int? limit,

    /// 分页偏移
    int? offset,
  }) = _CharacterFilter;

  /// Create from JSON
  factory CharacterFilter.fromJson(Map<String, dynamic> json) =>
      _$CharacterFilterFromJson(json);

  const CharacterFilter._(); // Private constructor required for getters

  /// Check if filter is empty
  bool get isEmpty =>
      searchText == null &&
      workId == null &&
      isFavorite == null &&
      tags.isEmpty &&
      style == null &&
      tool == null &&
      creationDatePreset == DateRangePreset.all &&
      collectionDatePreset == DateRangePreset.all &&
      creationDateRange == null &&
      collectionDateRange == null &&
      sortOption.isDefault &&
      limit == null &&
      offset == null;

  /// 添加标签
  CharacterFilter addTag(String tag) {
    if (tags.contains(tag)) return this;
    return copyWith(tags: [...tags, tag]);
  }

  /// Create a clear filter with default sorting
  CharacterFilter clear() => const CharacterFilter();

  /// 清除标签
  CharacterFilter clearTags() => copyWith(tags: const []);

  /// 移除标签
  CharacterFilter removeTag(String tag) {
    return copyWith(tags: [...tags]..remove(tag));
  }
}
