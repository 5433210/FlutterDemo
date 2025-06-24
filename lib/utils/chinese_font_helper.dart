import 'package:flutter/material.dart';

/// 中文字符字体处理工具类
class ChineseFontHelper {
  /// 检测文本是否包含中文字符
  static bool containsChinese(String text) {
    return RegExp(r'[\u4e00-\u9fff]').hasMatch(text);
  }

  /// 根据内容选择适当的字体
  /// 为中文字符返回思源黑体，其他字符返回null（使用默认字体）
  static String? getFontFamilyForContent(String content) {
    if (containsChinese(content)) {
      return 'SourceHanSans';  // 为中文字符使用思源黑体
    }
    return null;  // 英文等其他字符使用默认字体
  }

  /// 创建一个带有中文字体支持的TextStyle
  /// 如果原始样式为null，会创建一个基础样式
  static TextStyle? getTextStyleWithChineseSupport(
    String content, {
    TextStyle? baseStyle,
  }) {
    final fontFamily = getFontFamilyForContent(content);
    if (fontFamily != null) {
      // 如果需要中文字体，确保设置字体
      if (baseStyle != null) {
        return baseStyle.copyWith(fontFamily: fontFamily);
      } else {
        return TextStyle(fontFamily: fontFamily);
      }
    }
    return baseStyle;
  }

  /// 创建一个Text widget，自动处理中文字体
  static Widget createTextWithChineseSupport(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: getTextStyleWithChineseSupport(text, baseStyle: style),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
