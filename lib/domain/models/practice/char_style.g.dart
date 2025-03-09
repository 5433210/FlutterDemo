// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'char_style.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharStyleImpl _$$CharStyleImplFromJson(Map<String, dynamic> json) =>
    _$CharStyleImpl(
      color: json['color'] as String? ?? '#000000',
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      customStyle: json['customStyle'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$$CharStyleImplToJson(_$CharStyleImpl instance) =>
    <String, dynamic>{
      'color': instance.color,
      'opacity': instance.opacity,
      'customStyle': instance.customStyle,
    };
