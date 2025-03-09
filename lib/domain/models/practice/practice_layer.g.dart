// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_layer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PracticeLayerImpl _$$PracticeLayerImplFromJson(Map<String, dynamic> json) =>
    _$PracticeLayerImpl(
      id: json['id'] as String,
      type: $enumDecode(_$PracticeLayerTypeEnumMap, json['type']),
      imagePath: json['imagePath'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      visible: json['visible'] as bool? ?? true,
      locked: json['locked'] as bool? ?? false,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      order: (json['order'] as num?)?.toInt() ?? 0,
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => PracticeElement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createTime: DateTime.parse(json['create_time'] as String),
      updateTime: DateTime.parse(json['update_time'] as String),
    );

Map<String, dynamic> _$$PracticeLayerImplToJson(_$PracticeLayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$PracticeLayerTypeEnumMap[instance.type]!,
      'imagePath': instance.imagePath,
      'name': instance.name,
      'description': instance.description,
      'visible': instance.visible,
      'locked': instance.locked,
      'opacity': instance.opacity,
      'order': instance.order,
      'elements': instance.elements,
      'create_time': instance.createTime.toIso8601String(),
      'update_time': instance.updateTime.toIso8601String(),
    };

const _$PracticeLayerTypeEnumMap = {
  PracticeLayerType.source: 'source',
  PracticeLayerType.practice: 'practice',
  PracticeLayerType.reference: 'reference',
};
