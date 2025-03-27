// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterImageImpl _$$CharacterImageImplFromJson(Map<String, dynamic> json) =>
    _$CharacterImageImpl(
      id: json['id'] as String,
      originalPath: json['originalPath'] as String,
      binaryPath: json['binaryPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String,
      svgPath: json['svgPath'] as String?,
      originalSize: const SizeConverter()
          .fromJson(json['originalSize'] as Map<String, dynamic>),
      options:
          ProcessingOptions.fromJson(json['options'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$CharacterImageImplToJson(
        _$CharacterImageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'originalPath': instance.originalPath,
      'binaryPath': instance.binaryPath,
      'thumbnailPath': instance.thumbnailPath,
      'svgPath': instance.svgPath,
      'originalSize': const SizeConverter().toJson(instance.originalSize),
      'options': instance.options,
    };
