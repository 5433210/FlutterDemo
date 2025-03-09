// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_geometry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ElementGeometryImpl _$$ElementGeometryImplFromJson(
        Map<String, dynamic> json) =>
    _$ElementGeometryImpl(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 100.0,
      height: (json['height'] as num?)?.toDouble() ?? 100.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$$ElementGeometryImplToJson(
        _$ElementGeometryImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'rotation': instance.rotation,
      'scale': instance.scale,
    };
