import 'package:equatable/equatable.dart';

/// 文本元素内容
class TextElement extends Equatable {
  /// 文本内容
  final String content;

  /// 字体名称
  final String fontFamily;

  /// 字体大小
  final double fontSize;

  /// 颜色 (十六进制格式, 例如: '#000000')
  final String color;

  /// 对齐方式 ('left', 'center', 'right', 'justify')
  final String alignment;

  const TextElement({
    required this.content,
    required this.fontFamily,
    required this.fontSize,
    this.color = '#000000',
    this.alignment = 'left',
  });

  /// 从JSON数据创建文本元素
  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      content: json['content'] as String,
      fontFamily: json['fontFamily'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      color: json['color'] as String? ?? '#000000',
      alignment: json['alignment'] as String? ?? 'left',
    );
  }

  /// 用默认样式创建文本元素
  factory TextElement.standard({
    required String content,
    String fontFamily = 'Arial',
    double fontSize = 16.0,
  }) {
    return TextElement(
      content: content,
      fontFamily: fontFamily,
      fontSize: fontSize,
    );
  }

  @override
  List<Object?> get props => [content, fontFamily, fontSize, color, alignment];

  /// 更改字体
  TextElement changeFont({
    String? newFontFamily,
    double? newFontSize,
  }) {
    return copyWith(
      fontFamily: newFontFamily,
      fontSize: newFontSize,
    );
  }

  /// 创建一个带有更新属性的新实例
  TextElement copyWith({
    String? content,
    String? fontFamily,
    double? fontSize,
    String? color,
    String? alignment,
  }) {
    return TextElement(
      content: content ?? this.content,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      alignment: alignment ?? this.alignment,
    );
  }

  /// 设置文本对齐方式
  TextElement setAlignment(String newAlignment) {
    if (!['left', 'center', 'right', 'justify'].contains(newAlignment)) {
      throw ArgumentError('Invalid alignment: $newAlignment');
    }
    return copyWith(alignment: newAlignment);
  }

  /// 设置文本颜色
  TextElement setColor(String newColor) {
    return copyWith(color: newColor);
  }

  /// 设置文本内容
  TextElement setText(String newContent) {
    return copyWith(content: newContent);
  }

  /// 将文本元素转换为JSON数据
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'color': color,
      'alignment': alignment,
    };
  }
}
