import 'package:flutter/material.dart';

/// TextRenderer 辅助方法类
class TextRendererHelpers {
  /// 构建字符小部件列表
  static List<Widget> buildCharacterWidgets(
    List<String> characters,
    double columnWidth,
    String textAlign,
    TextStyle style,
    double characterSpacing,
  ) {
    return characters.asMap().entries.map((entry) {
      final int index = entry.key;
      final String char = entry.value;
      final bool isLastChar = index == characters.length - 1;

      // 处理水平对齐
      Widget charWidget;

      // 对于两端对齐，我们需要特殊处理
      if (textAlign == 'justify') {
        // 对于单个字符，两端对齐没有意义，使用居中对齐
        charWidget = SizedBox(
          width: columnWidth, // 使用与列相同的宽度
          child: Center(
            child: Text(
              softWrap: false, // 竖排不允许文本换行
              char,
              style: style,
              textAlign: TextAlign.center, // 确保字符居中显示
            ),
          ),
        );
      } else {
        // 对于其他对齐方式，我们使用 Container 和 Alignment 来实现
        Alignment alignment;
        switch (textAlign) {
          case 'left':
            alignment = Alignment.centerLeft;
            break;
          case 'center':
            alignment = Alignment.center;
            break;
          case 'right':
            alignment = Alignment.centerRight;
            break;
          default:
            alignment = Alignment.center;
        }

        charWidget = Container(
          width: columnWidth, // 使用与列相同的宽度
          alignment: alignment,
          child: Text(
            softWrap: false, // 竖排不允许文本换行
            char,
            style: style,
            textAlign: TextAlign.center, // 确保字符居中显示
          ),
        );
      }

      // 如果不是最后一个字符，添加字符间距
      if (!isLastChar && characterSpacing > 0) {
        return Padding(
          padding: EdgeInsets.only(bottom: characterSpacing),
          child: charWidget,
        );
      } else {
        return charWidget;
      }
    }).toList();
  }
}