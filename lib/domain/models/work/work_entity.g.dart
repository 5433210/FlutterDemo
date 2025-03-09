// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkEntityImpl _$$WorkEntityImplFromJson(Map<String, dynamic> json) =>
    _$WorkEntityImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      remark: json['remark'] as String?,
      style: _workStyleFromJson(json['style']),
      tool: _workToolFromJson(json['tool']),
      creationDate: DateTime.parse(json['creation_date'] as String),
      createTime: DateTime.parse(json['create_time'] as String),
      updateTime: DateTime.parse(json['update_time'] as String),
      status: $enumDecodeNullable(_$WorkStatusEnumMap, json['status']) ??
          WorkStatus.draft,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => WorkImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      collectedChars: (json['collected_chars'] as List<dynamic>?)
              ?.map((e) => CharacterEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      imageCount: (json['imageCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$WorkEntityImplToJson(_$WorkEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'remark': instance.remark,
      'style': _workStyleToJson(instance.style),
      'tool': _workToolToJson(instance.tool),
      'creation_date': instance.creationDate.toIso8601String(),
      'create_time': instance.createTime.toIso8601String(),
      'update_time': instance.updateTime.toIso8601String(),
      'status': _$WorkStatusEnumMap[instance.status]!,
      'images': instance.images,
      'collected_chars': instance.collectedChars,
      'tags': instance.tags,
      'imageCount': instance.imageCount,
    };

const _$WorkStatusEnumMap = {
  WorkStatus.draft: 'draft',
  WorkStatus.published: 'published',
  WorkStatus.archived: 'archived',
};
