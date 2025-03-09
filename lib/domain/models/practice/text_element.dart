import 'dart:ui';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'text_element.freezed.dart';
part 'text_element.g.dart';

/// 文本元素
@freezed
class TextElement with _$TextElement {
  const factory TextElement({
    /// 文本内容
    required String text,

    /// 字体名称
    @Default('Arial') String fontFamily,

    /// 字体大小
    @Default(14.0) double fontSize,

    /// 字体颜色
    @Default('#000000') String color,

    /// 文本对齐方式
    @Default(TextAlign.left) TextAlign textAlign,

    /// 是否加粗
    @Default(false) bool bold,

    /// 是否斜体
    @Default(false) bool italic,

    /// 是否下划线
    @Default(false) bool underline,

    /// 行高
    @Default(1.2) double lineHeight,

    /// 字间距
    @Default(0.0) double letterSpacing,

    /// 自定义样式属性
    @Default({}) Map<String, dynamic> customStyle,
  }) = _TextElement;

  /// 从JSON创建实例
  factory TextElement.fromJson(Map<String, dynamic> json) =>
      _$TextElementFromJson(json);

  /// 简单文本
  factory TextElement.simple(String text) => TextElement(text: text);

  const TextElement._();

  /// 移除自定义样式
  TextElement removeCustomStyle(String key) {
    final newCustomStyle = Map<String, dynamic>.from(customStyle);
    newCustomStyle.remove(key);
    return copyWith(customStyle: newCustomStyle);
  }

  /// 设置对齐
  TextElement withAlign(TextAlign align) => copyWith(textAlign: align);

  /// 设置加粗
  TextElement withBold(bool bold) => copyWith(bold: bold);

  /// 设置颜色
  TextElement withColor(String color) => copyWith(color: color);

  /// 设置自定义样式
  TextElement withCustomStyle(String key, dynamic value) {
    final newCustomStyle = Map<String, dynamic>.from(customStyle);
    newCustomStyle[key] = value;
    return copyWith(customStyle: newCustomStyle);
  }

  /// 设置字体
  TextElement withFont(String fontFamily) => copyWith(fontFamily: fontFamily);

  /// 设置斜体
  TextElement withItalic(bool italic) => copyWith(italic: italic);

  /// 设置字间距
  TextElement withLetterSpacing(double spacing) =>
      copyWith(letterSpacing: spacing);

  /// 设置行高
  TextElement withLineHeight(double lineHeight) =>
      copyWith(lineHeight: lineHeight);

  /// 设置字号
  TextElement withSize(double fontSize) => copyWith(fontSize: fontSize);

  /// 设置下划线
  TextElement withUnderline(bool underline) => copyWith(underline: underline);
}
