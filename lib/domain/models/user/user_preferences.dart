import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    @Default(128.0) double defaultThreshold,
    @Default(0.0) double defaultNoiseReduction,
    @Default(10.0) double defaultBrushSize,
    @Default(false) bool defaultInverted,
    @Default(false) bool defaultShowContour,
    @Default(1.0) double defaultContrast,
    @Default(0.0) double defaultBrightness,
    DateTime? updateTime,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}
