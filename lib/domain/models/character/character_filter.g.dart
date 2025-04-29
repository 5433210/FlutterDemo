// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterFilterImpl _$$CharacterFilterImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterFilterImpl(
      searchText: json['searchText'] as String?,
      isFavorite: json['isFavorite'] as bool?,
      workId: json['workId'] as String?,
      pageId: json['pageId'] as String?,
      style: _workStyleFilterFromJson(json['style']),
      tool: _workToolFilterFromJson(json['tool']),
      creationDatePreset: json['creationDatePreset'] == null
          ? DateRangePreset.all
          : _dateRangePresetFromJson(json['creationDatePreset']),
      creationDateRange: _dateRangeFromJson(json['creationDateRange']),
      collectionDatePreset: json['collectionDatePreset'] == null
          ? DateRangePreset.all
          : _dateRangePresetFromJson(json['collectionDatePreset']),
      collectionDateRange: _dateRangeFromJson(json['collectionDateRange']),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      sortOption: json['sortOption'] == null
          ? const SortOption()
          : SortOption.fromJson(json['sortOption'] as Map<String, dynamic>),
      limit: (json['limit'] as num?)?.toInt(),
      offset: (json['offset'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$CharacterFilterImplToJson(
        _$CharacterFilterImpl instance) =>
    <String, dynamic>{
      'searchText': instance.searchText,
      'isFavorite': instance.isFavorite,
      'workId': instance.workId,
      'pageId': instance.pageId,
      'style': _workStyleToJson(instance.style),
      'tool': _workToolToJson(instance.tool),
      'creationDatePreset': _dateRangePresetToJson(instance.creationDatePreset),
      'creationDateRange': _dateRangeToJson(instance.creationDateRange),
      'collectionDatePreset':
          _dateRangePresetToJson(instance.collectionDatePreset),
      'collectionDateRange': _dateRangeToJson(instance.collectionDateRange),
      'tags': instance.tags,
      'sortOption': instance.sortOption,
      'limit': instance.limit,
      'offset': instance.offset,
    };
