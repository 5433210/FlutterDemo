// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'char_transform.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharTransformImpl _$$CharTransformImplFromJson(Map<String, dynamic> json) =>
    _$CharTransformImpl(
      scaleX: (json['scaleX'] as num?)?.toDouble() ?? 1.0,
      scaleY: (json['scaleY'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$$CharTransformImplToJson(_$CharTransformImpl instance) =>
    <String, dynamic>{
      'scaleX': instance.scaleX,
      'scaleY': instance.scaleY,
      'rotation': instance.rotation,
    };
