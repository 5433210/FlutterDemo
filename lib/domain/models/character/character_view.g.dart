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
      tool: $enumDecodeNullable(_$WorkToolEnumMap, json['tool']),
      style: $enumDecodeNullable(_$WorkStyleEnumMap, json['style']),
      author: json['author'] as String?,
      creationTime: json['creationTime'] == null
          ? null
          : DateTime.parse(json['creationTime'] as String),
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
      'creationTime': instance.creationTime?.toIso8601String(),
      'collectionTime': instance.collectionTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
      'isFavorite': instance.isFavorite,
      'tags': instance.tags,
      'region': instance.region,
    };

const _$WorkToolEnumMap = {
  WorkTool.brush: 'brush',
  WorkTool.hardPen: 'hardPen',
  WorkTool.other: 'other',
};

const _$WorkStyleEnumMap = {
  WorkStyle.regular: 'regular',
  WorkStyle.running: 'running',
  WorkStyle.cursive: 'cursive',
  WorkStyle.clerical: 'clerical',
  WorkStyle.seal: 'seal',
  WorkStyle.other: 'other',
};
