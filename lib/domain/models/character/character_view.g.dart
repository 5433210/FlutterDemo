// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_view.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterViewImpl _$$CharacterViewImplFromJson(Map<String, dynamic> json) =>
    _$CharacterViewImpl(
      id: json['id'] as String,
      character: json['character'] as String,
      workId: json['workId'] as String,
      pageId: json['pageId'] as String,
      title: json['title'] as String,
      tool: json['tool'] as String?,
      style: json['style'] as String?,
      author: json['author'] as String?,
      collectionTime: DateTime.parse(json['collectionTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      region: CharacterRegion.fromJson(json['region'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CharacterViewImplToJson(_$CharacterViewImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'character': instance.character,
      'workId': instance.workId,
      'pageId': instance.pageId,
      'title': instance.title,
      'tool': instance.tool,
      'style': instance.style,
      'author': instance.author,
      'collectionTime': instance.collectionTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'tags': instance.tags,
      'region': instance.region,
    };
