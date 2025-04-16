// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_detail_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterFormatInfoImpl _$$CharacterFormatInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterFormatInfoImpl(
      format: $enumDecode(_$CharacterImageFormatEnumMap, json['format']),
      name: json['name'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$CharacterFormatInfoImplToJson(
        _$CharacterFormatInfoImpl instance) =>
    <String, dynamic>{
      'format': _$CharacterImageFormatEnumMap[instance.format]!,
      'name': instance.name,
      'description': instance.description,
    };

const _$CharacterImageFormatEnumMap = {
  CharacterImageFormat.original: 'original',
  CharacterImageFormat.binary: 'binary',
  CharacterImageFormat.transparent: 'transparent',
  CharacterImageFormat.squareBinary: 'squareBinary',
  CharacterImageFormat.squareTransparent: 'squareTransparent',
};
