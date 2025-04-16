// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_detail_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterFormatInfoImpl _$$CharacterFormatInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterFormatInfoImpl(
      format: $enumDecode(_$CharacterImageTypeEnumMap, json['format']),
      name: json['name'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$CharacterFormatInfoImplToJson(
        _$CharacterFormatInfoImpl instance) =>
    <String, dynamic>{
      'format': _$CharacterImageTypeEnumMap[instance.format]!,
      'name': instance.name,
      'description': instance.description,
    };

const _$CharacterImageTypeEnumMap = {
  CharacterImageType.original: 'original',
  CharacterImageType.binary: 'binary',
  CharacterImageType.thumbnail: 'thumbnail',
  CharacterImageType.squareBinary: 'squareBinary',
  CharacterImageType.squareTransparent: 'squareTransparent',
  CharacterImageType.transparent: 'transparent',
  CharacterImageType.outline: 'outline',
  CharacterImageType.squareOutline: 'squareOutline',
};
