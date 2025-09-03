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
      style: json['style'] as String? ?? '',
      tool: json['tool'] as String? ?? '',
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      lastImageUpdateTime: json['lastImageUpdateTime'] == null
          ? null
          : DateTime.parse(json['lastImageUpdateTime'] as String),
      status: $enumDecodeNullable(_$WorkStatusEnumMap, json['status']) ??
          WorkStatus.draft,
      firstImageId: json['firstImageId'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => WorkImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      collectedChars: (json['collectedChars'] as List<dynamic>?)
              ?.map((e) => CharacterEntity.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      imageCount: (json['imageCount'] as num?)?.toInt(),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$WorkEntityImplToJson(_$WorkEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'remark': instance.remark,
      'style': instance.style,
      'tool': instance.tool,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'lastImageUpdateTime': instance.lastImageUpdateTime?.toIso8601String(),
      'status': _$WorkStatusEnumMap[instance.status]!,
      'firstImageId': instance.firstImageId,
      'images': instance.images,
      'collectedChars': instance.collectedChars,
      'tags': instance.tags,
      'imageCount': instance.imageCount,
      'metadata': instance.metadata,
    };

const _$WorkStatusEnumMap = {
  WorkStatus.draft: 'draft',
  WorkStatus.published: 'published',
  WorkStatus.archived: 'archived',
};
