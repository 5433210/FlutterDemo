// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_element.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PracticeElementImpl _$$PracticeElementImplFromJson(
        Map<String, dynamic> json) =>
    _$PracticeElementImpl(
      id: json['id'] as String,
      elementType: json['type'] as String,
      geometry:
          ElementGeometry.fromJson(json['geometry'] as Map<String, dynamic>),
      style: ElementStyle.fromJson(json['style'] as Map<String, dynamic>),
      content: ElementContent.fromJson(json['content'] as Map<String, dynamic>),
      createTime: (json['createTime'] as num?)?.toInt() ?? 0,
      updateTime: (json['updateTime'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PracticeElementImplToJson(
        _$PracticeElementImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.elementType,
      'geometry': instance.geometry,
      'style': instance.style,
      'content': instance.content,
      'createTime': instance.createTime,
      'updateTime': instance.updateTime,
    };
