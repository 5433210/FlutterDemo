// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPreferencesImpl _$$UserPreferencesImplFromJson(
        Map<String, dynamic> json) =>
    _$UserPreferencesImpl(
      defaultThreshold: (json['defaultThreshold'] as num?)?.toDouble() ?? 128.0,
      defaultNoiseReduction:
          (json['defaultNoiseReduction'] as num?)?.toDouble() ?? 0.0,
      defaultBrushSize: (json['defaultBrushSize'] as num?)?.toDouble() ?? 10.0,
      defaultInverted: json['defaultInverted'] as bool? ?? false,
      defaultShowContour: json['defaultShowContour'] as bool? ?? false,
      defaultContrast: (json['defaultContrast'] as num?)?.toDouble() ?? 1.0,
      defaultBrightness: (json['defaultBrightness'] as num?)?.toDouble() ?? 0.0,
      updateTime: json['updateTime'] == null
          ? null
          : DateTime.parse(json['updateTime'] as String),
    );

Map<String, dynamic> _$$UserPreferencesImplToJson(
        _$UserPreferencesImpl instance) =>
    <String, dynamic>{
      'defaultThreshold': instance.defaultThreshold,
      'defaultNoiseReduction': instance.defaultNoiseReduction,
      'defaultBrushSize': instance.defaultBrushSize,
      'defaultInverted': instance.defaultInverted,
      'defaultShowContour': instance.defaultShowContour,
      'defaultContrast': instance.defaultContrast,
      'defaultBrightness': instance.defaultBrightness,
      'updateTime': instance.updateTime?.toIso8601String(),
    };
