import 'package:freezed_annotation/freezed_annotation.dart';

part 'element_style.freezed.dart';
part 'element_style.g.dart';

/// 元素的样式属性
@freezed
class ElementStyle with _$ElementStyle {
  const factory ElementStyle({
    /// 透明度
    @Default(1.0) double opacity,

    /// 是否可见
    @Default(true) bool visible,

    /// 是否锁定
    @Default(false) bool locked,

    /// 自定义样式属性
    @Default({}) Map<String, dynamic> properties,
  }) = _ElementStyle;

  /// 从JSON创建实例
  factory ElementStyle.fromJson(Map<String, dynamic> json) =>
      _$ElementStyleFromJson(json);

  const ElementStyle._();

  /// 移除样式属性
  ElementStyle removeProperty(String key) {
    final newProperties = Map<String, dynamic>.from(properties);
    newProperties.remove(key);
    return copyWith(properties: newProperties);
  }

  /// 设置锁定状态
  ElementStyle setLocked(bool value) => copyWith(locked: value);

  /// 设置透明度
  ElementStyle setOpacity(double value) => copyWith(opacity: value);

  /// 设置样式属性
  ElementStyle setProperty(String key, dynamic value) {
    final newProperties = Map<String, dynamic>.from(properties);
    newProperties[key] = value;
    return copyWith(properties: newProperties);
  }

  /// 设置可见性
  ElementStyle setVisible(bool value) => copyWith(visible: value);
}
