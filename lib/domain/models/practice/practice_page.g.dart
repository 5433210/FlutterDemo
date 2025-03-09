// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PageSizeImpl _$$PageSizeImplFromJson(Map<String, dynamic> json) =>
    _$PageSizeImpl(
      unit: json['unit'] as String? ?? 'mm',
      resUnit: json['resUnit'] as String? ?? 'dpi',
      resUnitValue: (json['resUnitValue'] as num?)?.toInt() ?? 300,
      width: (json['width'] as num?)?.toDouble() ?? 210.0,
      height: (json['height'] as num?)?.toDouble() ?? 297.0,
    );

Map<String, dynamic> _$$PageSizeImplToJson(_$PageSizeImpl instance) =>
    <String, dynamic>{
      'unit': instance.unit,
      'resUnit': instance.resUnit,
      'resUnitValue': instance.resUnitValue,
      'width': instance.width,
      'height': instance.height,
    };

_$PracticePageImpl _$$PracticePageImplFromJson(Map<String, dynamic> json) =>
    _$PracticePageImpl(
      index: (json['index'] as num).toInt(),
      size: json['size'] == null
          ? const PageSize()
          : PageSize.fromJson(json['size'] as Map<String, dynamic>),
      layers: (json['layers'] as List<dynamic>?)
              ?.map((e) => PracticeLayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createTime: DateTime.parse(json['create_time'] as String),
      updateTime: DateTime.parse(json['update_time'] as String),
    );

Map<String, dynamic> _$$PracticePageImplToJson(_$PracticePageImpl instance) =>
    <String, dynamic>{
      'index': instance.index,
      'size': instance.size,
      'layers': instance.layers,
      'create_time': instance.createTime.toIso8601String(),
      'update_time': instance.updateTime.toIso8601String(),
    };
