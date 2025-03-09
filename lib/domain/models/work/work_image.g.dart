// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkImageImpl _$$WorkImageImplFromJson(Map<String, dynamic> json) =>
    _$WorkImageImpl(
      path: json['path'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      index: (json['index'] as num).toInt(),
    );

Map<String, dynamic> _$$WorkImageImplToJson(_$WorkImageImpl instance) =>
    <String, dynamic>{
      'path': instance.path,
      'thumbnailPath': instance.thumbnailPath,
      'index': instance.index,
    };
