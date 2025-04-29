// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_filter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PracticeFilterImpl _$$PracticeFilterImplFromJson(Map<String, dynamic> json) =>
    _$PracticeFilterImpl(
      keyword: json['keyword'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      status: json['status'] as String?,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
      offset: (json['offset'] as num?)?.toInt() ?? 0,
      sortField: json['sortField'] as String? ?? 'updateTime',
      sortOrder: json['sortOrder'] as String? ?? 'desc',
    );

Map<String, dynamic> _$$PracticeFilterImplToJson(
        _$PracticeFilterImpl instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'tags': instance.tags,
      'startTime': instance.startTime?.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'status': instance.status,
      'limit': instance.limit,
      'offset': instance.offset,
      'sortField': instance.sortField,
      'sortOrder': instance.sortOrder,
    };
