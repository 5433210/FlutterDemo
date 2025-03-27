// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_region.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterRegionImpl _$$CharacterRegionImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterRegionImpl(
      id: json['id'] as String,
      pageId: json['pageId'] as String,
      rect:
          const RectConverter().fromJson(json['rect'] as Map<String, dynamic>),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      character: json['character'] as String,
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
      options:
          ProcessingOptions.fromJson(json['options'] as Map<String, dynamic>),
      erasePoints:
          const OffsetListConverter().fromJson(json['erasePoints'] as List?),
    );

Map<String, dynamic> _$$CharacterRegionImplToJson(
        _$CharacterRegionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageId': instance.pageId,
      'rect': const RectConverter().toJson(instance.rect),
      'rotation': instance.rotation,
      'character': instance.character,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
      'options': instance.options,
      'erasePoints': const OffsetListConverter().toJson(instance.erasePoints),
    };
