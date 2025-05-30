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
      character: json['character'] as String? ?? '',
      characterId: json['characterId'] as String?,
      options: json['options'] == null
          ? const ProcessingOptions()
          : ProcessingOptions.fromJson(json['options'] as Map<String, dynamic>),
      isModified: json['isModified'] as bool? ?? false,
      isSelected: json['isSelected'] as bool? ?? false,
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      eraseData: (json['eraseData'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );

Map<String, dynamic> _$$CharacterRegionImplToJson(
        _$CharacterRegionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pageId': instance.pageId,
      'rect': const RectConverter().toJson(instance.rect),
      'character': instance.character,
      'characterId': instance.characterId,
      'options': instance.options,
      'isModified': instance.isModified,
      'isSelected': instance.isSelected,
      'createTime': instance.createTime?.toIso8601String(),
      'updateTime': instance.updateTime?.toIso8601String(),
      'rotation': instance.rotation,
      'eraseData': instance.eraseData,
    };
