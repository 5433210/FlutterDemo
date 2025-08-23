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
      noiseReduction: (json['noiseReduction'] as num?)?.toDouble() ?? 0.0,
      brushSize: (json['brushSize'] as num?)?.toDouble() ?? 10.0,
      contrast: (json['contrast'] as num?)?.toDouble() ?? 1.0,
      brightness: (json['brightness'] as num?)?.toDouble() ?? 0.0,
      characterAspectRatio: (json['characterAspectRatio'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$ProcessingOptionsImplToJson(
        _$ProcessingOptionsImpl instance) =>
    <String, dynamic>{
      'inverted': instance.inverted,
      'showContour': instance.showContour,
      'threshold': instance.threshold,
      'noiseReduction': instance.noiseReduction,
      'brushSize': instance.brushSize,
      'contrast': instance.contrast,
      'brightness': instance.brightness,
      'characterAspectRatio': instance.characterAspectRatio,
    };
