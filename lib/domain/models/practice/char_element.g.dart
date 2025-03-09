// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'char_element.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharElementImpl _$$CharElementImplFromJson(Map<String, dynamic> json) =>
    _$CharElementImpl(
      charId: json['charId'] as String,
      position: CharPosition.fromJson(json['position'] as Map<String, dynamic>),
      transform: json['transform'] == null
          ? const CharTransform()
          : CharTransform.fromJson(json['transform'] as Map<String, dynamic>),
      style: json['style'] == null
          ? const CharStyle()
          : CharStyle.fromJson(json['style'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CharElementImplToJson(_$CharElementImpl instance) =>
    <String, dynamic>{
      'charId': instance.charId,
      'position': instance.position,
      'transform': instance.transform,
      'style': instance.style,
    };
