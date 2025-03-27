// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'processing_options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProcessingOptionsImpl _$$ProcessingOptionsImplFromJson(
        Map<String, dynamic> json) =>
    _$ProcessingOptionsImpl(
      inverted: json['inverted'] as bool? ?? false,
      showContour: json['showContour'] as bool? ?? false,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 128.0,
      noiseReduction: (json['noiseReduction'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$$ProcessingOptionsImplToJson(
        _$ProcessingOptionsImpl instance) =>
    <String, dynamic>{
      'inverted': instance.inverted,
      'showContour': instance.showContour,
      'threshold': instance.threshold,
      'noiseReduction': instance.noiseReduction,
    };
