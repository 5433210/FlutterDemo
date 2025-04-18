// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PracticeLayerImpl _$$PracticeLayerImplFromJson(Map<String, dynamic> json) =>
    _$PracticeLayerImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      order: (json['order'] as num).toInt(),
      isVisible: json['isVisible'] as bool? ?? true,
      isLocked: json['isLocked'] as bool? ?? false,
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => PracticeElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PracticeElement>[],
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      backgroundImage: json['backgroundImage'] as String?,
    );

Map<String, dynamic> _$$PracticeLayerImplToJson(_$PracticeLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'order': instance.order,
      'isVisible': instance.isVisible,
      'isLocked': instance.isLocked,
      'elements': instance.elements,
      'opacity': instance.opacity,
      'backgroundImage': instance.backgroundImage,
    };
