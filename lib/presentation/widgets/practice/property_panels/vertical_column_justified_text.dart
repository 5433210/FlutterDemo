import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 竖排文本两端对齐组件
/// 用于实现竖排文本在水平方向上的两端对齐效果
class VerticalColumnJustifiedText extends StatelessWidget {
  final List<String> characters;
  final TextStyle style;
  final double maxHeight;
  final double columnWidth;
  final bool isRightToLeft; // 是否从右到左显示（竖排左书，列从左到右排列）
  final String verticalAlign; // 垂直对齐方式

  const VerticalColumnJustifiedText({
    Key? key,
    required this.characters,
    required this.style,
    required this.maxHeight,
    required this.columnWidth,
    required this.verticalAlign, // 垂直对齐方式
    this.isRightToLeft = false, // 默认为从左到右（竖排右书，列从右到左排列）
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果没有字符，则返回空容器
    if (characters.isEmpty) {
      return SizedBox(
        width: columnWidth,
        height: maxHeight,
      );
    }

    // 计算字符高度和间距，添加安全检查
    // 在竖排模式下，letterSpacing 控制字符纵向间距，lineHeight 控制列间距
    final charHeight = math.max(style.fontSize ?? 16.0, 1.0);
    final effectiveLetterSpacing = math.max(style.letterSpacing ?? 0.0, 0.0); // 纵向字符间距
    final effectiveCharHeight = math.max(charHeight + effectiveLetterSpacing, 10.0); // 字符高度+纵向间距

    // 计算总字符高度
    final totalCharsHeight = effectiveCharHeight * characters.length;

    // 计算需要分配的额外空间
    final extraSpace = maxHeight - totalCharsHeight;

    // 如果没有额外空间或额外空间为负，则使用普通文本显示
    if (extraSpace <= 0) {
      return _buildNormalVerticalText();
    }

    // 有额外空间，可以根据垂直对齐方式来布局

    // 根据垂直对齐方式决定列内文字的对齐方式
    MainAxisAlignment columnAlignment;
    switch (verticalAlign) {
      case 'top':
        columnAlignment = MainAxisAlignment.start;
        break;
      case 'middle':
        columnAlignment = MainAxisAlignment.center;
        break;
      case 'bottom':
        columnAlignment = MainAxisAlignment.end;
        break;
      case 'justify':
        // 对于垂直两端对齐，我们在列内使用两端对齐
        columnAlignment = MainAxisAlignment.spaceBetween;
        break;
      default:
        columnAlignment = MainAxisAlignment.start;
    }

    // 打印调试信息
    developer.log('竖排文本列: 垂直对齐=$verticalAlign, 列对齐=$columnAlignment');

    // 构建竖排文本列
    return SizedBox(
      width: columnWidth,
      height: maxHeight,
      child: ClipRect( // 添加剪裁防止溢出
        child: verticalAlign == 'justify' && characters.length > 1
          ? Column( // 🔧 垂直分佈时不使用滚动视图，确保spaceBetween生效
              mainAxisSize: MainAxisSize.max, // 使用max确保占满容器高度
              mainAxisAlignment: columnAlignment, // 根据垂直对齐方式决定列内文字的对齐方式
              children: characters.map((char) {
                return Text(
                  char,
                  style: style,
                  textAlign: TextAlign.center,
                );
              }).toList(),
            )
          : Column( // 🔧 对于非justify垂直对齐，也不使用ScrollView，这样才能正确处理center和bottom对齐
              mainAxisSize: MainAxisSize.max, // 🔧 使用max确保占满容器高度，让MainAxisAlignment生效
              mainAxisAlignment: columnAlignment, // 🔧 这样center和bottom对齐才能正确工作
              children: characters.map((char) {
                return Text(
                  char,
                  style: style,
                  textAlign: TextAlign.center,
                );
              }).toList(),
            ),
      ),
    );
  }

  /// 构建普通竖排文本（不使用两端对齐）
  Widget _buildNormalVerticalText() {
    // 根据垂直对齐方式决定列内文字的对齐方式
    MainAxisAlignment columnAlignment;
    switch (verticalAlign) {
      case 'top':
        columnAlignment = MainAxisAlignment.start;
        break;
      case 'middle':
        columnAlignment = MainAxisAlignment.center;
        break;
      case 'bottom':
        columnAlignment = MainAxisAlignment.end;
        break;
      case 'justify':
        // 对于垂直两端对齐，我们在列内使用两端对齐
        columnAlignment = MainAxisAlignment.spaceBetween;
        break;
      default:
        columnAlignment = MainAxisAlignment.start;
    }

    return SizedBox(
      width: columnWidth,
      height: maxHeight,
      child: ClipRect( // 添加剪裁防止溢出
        child: verticalAlign == 'justify' && characters.length > 1
          ? Column( // 🔧 垂直分佈时不使用滚动视图，确保spaceBetween生效
              mainAxisSize: MainAxisSize.max, // 使用max确保占满容器高度
              mainAxisAlignment: columnAlignment, // 根据垂直对齐方式决定列内文字的对齐方式
              children: characters.map((char) {
                return Text(
                  char,
                  style: style,
                  textAlign: TextAlign.center,
                );
              }).toList(),
            )
          : Column( // 🔧 对于非justify垂直对齐，也不使用ScrollView，这样才能正确处理center和bottom对齐
              mainAxisSize: MainAxisSize.max, // 🔧 使用max确保占满容器高度，让MainAxisAlignment生效
              mainAxisAlignment: columnAlignment, // 🔧 这样center和bottom对齐才能正确工作
              children: characters.map((char) {
                return Text(
                  char,
                  style: style,
                  textAlign: TextAlign.center,
                );
              }).toList(),
            ),
      ),
    );
  }
}
