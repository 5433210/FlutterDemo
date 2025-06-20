// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkImageImpl _$$WorkImageImplFromJson(Map<String, dynamic> json) =>
    _$WorkImageImpl(
      id: json['id'] as String,
      workId: json['workId'] as String,
      libraryItemId: json['libraryItemId'] as String?,
      originalPath: json['originalPath'] as String,
      path: json['path'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      index: (json['index'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      format: json['format'] as String,
      size: (json['size'] as num).toInt(),
      createTime: DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
    );

Map<String, dynamic> _$$WorkImageImplToJson(_$WorkImageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workId': instance.workId,
      'libraryItemId': instance.libraryItemId,
      'originalPath': instance.originalPath,
      'path': instance.path,
      'thumbnailPath': instance.thumbnailPath,
      'index': instance.index,
      'width': instance.width,
      'height': instance.height,
      'format': instance.format,
      'size': instance.size,
      'createTime': instance.createTime.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
    };
