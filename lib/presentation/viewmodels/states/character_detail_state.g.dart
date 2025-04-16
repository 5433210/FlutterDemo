// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'character_detail_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharacterDetailStateImpl _$$CharacterDetailStateImplFromJson(
        Map<String, dynamic> json) =>
    _$CharacterDetailStateImpl(
      character: json['character'] == null
          ? null
          : CharacterView.fromJson(json['character'] as Map<String, dynamic>),
      relatedCharacters: (json['relatedCharacters'] as List<dynamic>?)
              ?.map((e) => CharacterView.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedFormat: (json['selectedFormat'] as num?)?.toInt() ?? 0,
      originalPath: json['originalPath'] as String?,
      binaryPath: json['binaryPath'] as String?,
      transparentPath: json['transparentPath'] as String?,
      squareBinaryPath: json['squareBinaryPath'] as String?,
      squareTransparentPath: json['squareTransparentPath'] as String?,
      outlinePath: json['outlinePath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$$CharacterDetailStateImplToJson(
        _$CharacterDetailStateImpl instance) =>
    <String, dynamic>{
      'character': instance.character,
      'relatedCharacters': instance.relatedCharacters,
      'selectedFormat': instance.selectedFormat,
      'originalPath': instance.originalPath,
      'binaryPath': instance.binaryPath,
      'transparentPath': instance.transparentPath,
      'squareBinaryPath': instance.squareBinaryPath,
      'squareTransparentPath': instance.squareTransparentPath,
      'outlinePath': instance.outlinePath,
      'thumbnailPath': instance.thumbnailPath,
      'isLoading': instance.isLoading,
      'error': instance.error,
    };
