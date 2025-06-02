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
      creationDate: _dateTimeFromJson(json['creationDate']),
      createTime: _dateTimeFromJson(json['createTime']),
      updateTime: _dateTimeFromJson(json['updateTime']),
      isFavorite: json['isFavorite'] == null
          ? false
          : _isFavoriteFromJson(json['isFavorite']),
      lastImageUpdateTime: _dateTimeFromJson(json['lastImageUpdateTime']),
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
    );

Map<String, dynamic> _$$WorkEntityImplToJson(_$WorkEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'remark': instance.remark,
      'style': _workStyleToJson(instance.style),
      'tool': _workToolToJson(instance.tool),
      'creationDate': _dateTimeToJson(instance.creationDate),
      'createTime': _dateTimeToJson(instance.createTime),
      'updateTime': _dateTimeToJson(instance.updateTime),
      'isFavorite': _isFavoriteToJson(instance.isFavorite),
      if (_dateTimeToJson(instance.lastImageUpdateTime) case final value?)
        'lastImageUpdateTime': value,
      'status': _$WorkStatusEnumMap[instance.status]!,
      'firstImageId': instance.firstImageId,
      'images': instance.images,
      'collectedChars': instance.collectedChars,
      'tags': instance.tags,
      'imageCount': instance.imageCount,
    };

const _$WorkStatusEnumMap = {
  WorkStatus.draft: 'draft',
  WorkStatus.published: 'published',
  WorkStatus.archived: 'archived',
};
