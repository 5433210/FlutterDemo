// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PracticeEntityImpl _$$PracticeEntityImplFromJson(Map<String, dynamic> json) =>
    _$PracticeEntityImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      pages: (json['pages'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      status: json['status'] as String? ?? 'active',
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      pageCount: (json['pageCount'] as num?)?.toInt() ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      thumbnail: _bytesFromJson(json['thumbnail']),
    );

Map<String, dynamic> _$$PracticeEntityImplToJson(
        _$PracticeEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'pages': instance.pages,
      'tags': instance.tags,
      'status': instance.status,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'pageCount': instance.pageCount,
      'metadata': instance.metadata,
      'thumbnail': _bytesToJson(instance.thumbnail),
    };
