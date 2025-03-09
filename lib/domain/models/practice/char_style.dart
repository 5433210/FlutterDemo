import 'package:freezed_annotation/freezed_annotation.dart';

part 'char_style.freezed.dart';
part 'char_style.g.dart';

/// 字符样式
@freezed
class CharStyle with _$CharStyle {
  const factory CharStyle({
    /// 颜色，默认黑色
    @Default('#000000') String color,

    /// 不透明度，默认完全不透明
    @Default(1.0) double opacity,

    /// 自定义样式属性
    @Default({}) Map<String, dynamic> customStyle,
  }) = _CharStyle;

  /// 从JSON创建实例
  factory CharStyle.fromJson(Map<String, dynamic> json) =>
      _$CharStyleFromJson(json);

  const CharStyle._();

  /// 删除自定义样式属性
  CharStyle removeCustomStyle(String key) {
    final newCustomStyle = Map<String, dynamic>.from(customStyle);
    newCustomStyle.remove(key);
    return copyWith(customStyle: newCustomStyle);
  }

  /// 设置颜色
  CharStyle setColor(String newColor) {
    return copyWith(color: newColor);
  }

  /// 设置自定义样式属性
  CharStyle setCustomStyle(String key, dynamic value) {
    final newCustomStyle = Map<String, dynamic>.from(customStyle);
    newCustomStyle[key] = value;
    return copyWith(customStyle: newCustomStyle);
  }

  /// 设置不透明度
  CharStyle setOpacity(double newOpacity) {
    return copyWith(opacity: newOpacity.clamp(0.0, 1.0));
  }
}
