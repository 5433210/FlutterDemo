// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkFilterImpl _$$WorkFilterImplFromJson(Map<String, dynamic> json) =>
    _$WorkFilterImpl(
      keyword: json['keyword'] as String?,
      style: WorkStyle.fromValue(json['style']),
      tool: WorkTool.fromValue(json['tool']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      dateRange: _dateRangeFromJson(json['dateRange']),
      createTimeRange: _dateRangeFromJson(json['create_time_range']),
      updateTimeRange: _dateRangeFromJson(json['update_time_range']),
      datePreset: json['datePreset'] == null
          ? DateRangePreset.all
          : _dateRangePresetFromJson(json['datePreset']),
      sortOption: json['sortOption'] == null
          ? const SortOption()
          : SortOption.fromJson(json['sortOption'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$WorkFilterImplToJson(_$WorkFilterImpl instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'style': _workStyleToJson(instance.style),
      'tool': _workToolToJson(instance.tool),
      'tags': instance.tags,
      'dateRange': _dateRangeToJson(instance.dateRange),
      'create_time_range': _dateRangeToJson(instance.createTimeRange),
      'update_time_range': _dateRangeToJson(instance.updateTimeRange),
      'datePreset': _dateRangePresetToJson(instance.datePreset),
      'sortOption': instance.sortOption,
    };
