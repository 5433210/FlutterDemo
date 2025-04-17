// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PracticePageImpl _$$PracticePageImplFromJson(Map<String, dynamic> json) =>
    _$PracticePageImpl(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      index: (json['index'] as num?)?.toInt() ?? 0,
      width: (json['width'] as num?)?.toDouble() ?? 210.0,
      height: (json['height'] as num?)?.toDouble() ?? 297.0,
      backgroundType: json['backgroundType'] as String? ?? 'color',
      backgroundImage: json['backgroundImage'] as String?,
      backgroundColor: json['backgroundColor'] as String? ?? '#FFFFFF',
      backgroundTexture: json['backgroundTexture'] as String?,
      backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
      margin: json['margin'] == null
          ? const EdgeInsets.all(20.0)
          : const EdgeInsetsConverter()
              .fromJson(json['margin'] as Map<String, dynamic>),
      layers: (json['layers'] as List<dynamic>?)
              ?.map((e) => PracticeLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PracticeLayer>[],
    );

Map<String, dynamic> _$$PracticePageImplToJson(_$PracticePageImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'index': instance.index,
      'width': instance.width,
      'height': instance.height,
      'backgroundType': instance.backgroundType,
      'backgroundImage': instance.backgroundImage,
      'backgroundColor': instance.backgroundColor,
      'backgroundTexture': instance.backgroundTexture,
      'backgroundOpacity': instance.backgroundOpacity,
      'margin': const EdgeInsetsConverter().toJson(instance.margin),
      'layers': instance.layers,
    };
