// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_style.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ElementStyleImpl _$$ElementStyleImplFromJson(Map<String, dynamic> json) =>
    _$ElementStyleImpl(
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      properties: json['properties'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$ElementStyleImplToJson(_$ElementStyleImpl instance) =>
    <String, dynamic>{
      'opacity': instance.opacity,
      'visible': instance.visible,
      'locked': instance.locked,
      'properties': instance.properties,
    };
