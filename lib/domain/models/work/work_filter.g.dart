// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkFilterImpl _$$WorkFilterImplFromJson(Map<String, dynamic> json) =>
    _$WorkFilterImpl(
      keyword: json['keyword'] as String?,
      style: _workStyleFilterFromJson(json['style']),
      tool: _workToolFilterFromJson(json['tool']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      dateRange: _dateRangeFromJson(json['dateRange']),
      createTimeRange: _dateRangeFromJson(json['createTimeRange']),
      updateTimeRange: _dateRangeFromJson(json['updateTimeRange']),
      datePreset: json['datePreset'] == null
          ? DateRangePreset.all
          : _dateRangePresetFromJson(json['datePreset']),
      sortOption: json['sortOption'] == null
          ? const SortOption()
          : SortOption.fromJson(json['sortOption'] as Map<String, dynamic>),
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
      isFavoriteOnly: json['isFavoriteOnly'] as bool? ?? false,
    );

Map<String, dynamic> _$$WorkFilterImplToJson(_$WorkFilterImpl instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'style': _workStyleToJson(instance.style),
      'tool': _workToolToJson(instance.tool),
      'tags': instance.tags,
      'dateRange': _dateRangeToJson(instance.dateRange),
      'createTimeRange': _dateRangeToJson(instance.createTimeRange),
      'updateTimeRange': _dateRangeToJson(instance.updateTimeRange),
      'datePreset': _dateRangePresetToJson(instance.datePreset),
      'sortOption': instance.sortOption,
      'limit': instance.limit,
      'offset': instance.offset,
      'isFavoriteOnly': instance.isFavoriteOnly,
    };
