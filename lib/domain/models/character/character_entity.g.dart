// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterEntityImpl _$$CharacterEntityImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterEntityImpl(
      id: json['id'] as String,
      workId: json['workId'] as String,
      pageId: json['pageId'] as String,
      character: json['character'] as String,
      region: CharacterRegion.fromJson(json['region'] as Map<String, dynamic>),
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$CharacterEntityImplToJson(
        _$CharacterEntityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workId': instance.workId,
      'pageId': instance.pageId,
      'character': instance.character,
      'region': instance.region,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'tags': instance.tags,
      'note': instance.note,
    };
