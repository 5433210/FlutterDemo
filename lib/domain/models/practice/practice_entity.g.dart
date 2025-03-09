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
              ?.map((e) => PracticePage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      status: json['status'] as String? ?? 'active',
      createTime: DateTime.parse(json['create_time'] as String),
      updateTime: DateTime.parse(json['update_time'] as String),
    );

Map<String, dynamic> _$$PracticeEntityImplToJson(
        _$PracticeEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'pages': instance.pages,
      'tags': instance.tags,
      'status': instance.status,
      'create_time': instance.createTime.toIso8601String(),
      'update_time': instance.updateTime.toIso8601String(),
    };
