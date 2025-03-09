// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'element_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CharsContentImpl _$$CharsContentImplFromJson(Map<String, dynamic> json) =>
    _$CharsContentImpl(
      chars: (json['chars'] as List<dynamic>?)
              ?.map((e) => CharElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$CharsContentImplToJson(_$CharsContentImpl instance) =>
    <String, dynamic>{
      'chars': instance.chars,
      'runtimeType': instance.$type,
    };

_$ImageContentImpl _$$ImageContentImplFromJson(Map<String, dynamic> json) =>
    _$ImageContentImpl(
      image: ImageElement.fromJson(json['image'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$ImageContentImplToJson(_$ImageContentImpl instance) =>
    <String, dynamic>{
      'image': instance.image,
      'runtimeType': instance.$type,
    };

_$TextContentImpl _$$TextContentImplFromJson(Map<String, dynamic> json) =>
    _$TextContentImpl(
      text: TextElement.fromJson(json['text'] as Map<String, dynamic>),
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$TextContentImplToJson(_$TextContentImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'runtimeType': instance.$type,
    };
