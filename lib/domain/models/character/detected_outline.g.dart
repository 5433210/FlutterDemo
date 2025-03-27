// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detected_outline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DetectedOutlineImpl _$$DetectedOutlineImplFromJson(
        Map<String, dynamic> json) =>
    _$DetectedOutlineImpl(
      boundingRect: const RectConverter()
          .fromJson(json['boundingRect'] as Map<String, dynamic>),
      contourPoints: const ContourPointsConverter()
          .fromJson(json['contourPoints'] as List),
    );

Map<String, dynamic> _$$DetectedOutlineImplToJson(
        _$DetectedOutlineImpl instance) =>
    <String, dynamic>{
      'boundingRect': const RectConverter().toJson(instance.boundingRect),
      'contourPoints':
          const ContourPointsConverter().toJson(instance.contourPoints),
    };
