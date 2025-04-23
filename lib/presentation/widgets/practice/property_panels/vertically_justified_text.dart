import 'package:flutter/material.dart';

/// 垂直方向两端对齐文本组件
/// 用于实现文本在垂直方向上的两端对齐效果
class VerticallyJustifiedText extends StatelessWidget {
  final List<String> lines;
  final TextStyle style;
  final TextAlign horizontalAlign;
  final double maxHeight;
  final double maxWidth;
  final bool isRightToLeft; // 是否从右到左显示（横排右书）

  const VerticallyJustifiedText({
    Key? key,
    required this.lines,
    required this.style,
    required this.horizontalAlign,
    required this.maxHeight,
    required this.maxWidth,
    this.isRightToLeft = false, // 默认为从左到右（横排左书）
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 如果没有文本或只有一行，则使用普通文本显示
    if (lines.isEmpty || lines.length == 1) {
      // 对于横排右书，需要反转字符顺序
      final displayText = isRightToLeft && lines.isNotEmpty
          ? String.fromCharCodes(lines.first.runes.toList().reversed)
          : (lines.isEmpty ? '' : lines.first);

      return SizedBox(
        width: maxWidth,
        height: maxHeight,
        child: Center(
          child: Text(
            displayText,
            style: style,
            textAlign: isRightToLeft ? TextAlign.right : horizontalAlign,
            textDirection:
                isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
          ),
        ),
      );
    }

    // 计算行间距
    final totalTextHeight =
        lines.length * (style.fontSize ?? 16.0) * (style.height ?? 1.2);
    final availableSpace = maxHeight - totalTextHeight;

    // 如果没有足够的空间，则使用普通的滚动视图
    if (availableSpace <= 0) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: _getCrossAxisAlignment(horizontalAlign),
          children: lines
              .map((line) => Text(
                    line,
                    style: style,
                    textAlign: horizontalAlign,
                  ))
              .toList(),
        ),
      );
    }

    // 注意：行间距由 MainAxisAlignment.spaceBetween 自动处理

    // 构建两端对齐的文本
    return SizedBox(
      width: maxWidth,
      height: maxHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: _getCrossAxisAlignment(horizontalAlign),
        children: lines.map((line) {
          // 对于横排右书，需要处理字符顺序
          String displayText = line;
          if (isRightToLeft && horizontalAlign != TextAlign.justify) {
            // 对于非两端对齐，反转字符顺序
            displayText = String.fromCharCodes(line.runes.toList().reversed);
          }

          // 如果是水平两端对齐，使用自定义的两端对齐渲染器
          if (horizontalAlign == TextAlign.justify && line.length > 1) {
            return SizedBox(
              width: maxWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection:
                    isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
                children: _buildJustifiedCharacters(line, style),
              ),
            );
          } else {
            // 其他对齐方式使用普通 Text 组件
            return Text(
              displayText,
              style: style,
              textAlign: isRightToLeft ? TextAlign.right : horizontalAlign,
              textDirection:
                  isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
            );
          }
        }).toList(),
      ),
    );
  }

  /// 构建水平两端对齐的字符列表
  List<Widget> _buildJustifiedCharacters(String text, TextStyle style) {
    if (text.isEmpty || text.length == 1) {
      return [Text(text, style: style)];
    }

    final characters = text.characters.toList();
    final result = <Widget>[];

    // 计算每个字符的宽度
    final charWidths = _calculateCharWidths(characters, style);

    for (int i = 0; i < characters.length; i++) {
      // 添加字符
      result.add(
        SizedBox(
          width: charWidths[i],
          child: Text(
            characters[i],
            style: style,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return result;
  }

  /// 计算每个字符的宽度
  List<double> _calculateCharWidths(List<String> characters, TextStyle style) {
    final List<double> widths = [];

    for (final char in characters) {
      // 计算单个字符的宽度
      final width = _calculateTextWidth(char, style);
      widths.add(width);
    }

    return widths;
  }

  /// 计算文本的实际宽度
  double _calculateTextWidth(String text, TextStyle style) {
    if (text.isEmpty) return 0.0;

    // 使用TextPainter计算实际文本宽度
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();

    return textPainter.width;
  }

  // 根据水平对齐方式获取交叉轴对齐方式
  CrossAxisAlignment _getCrossAxisAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return CrossAxisAlignment.start;
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
        return CrossAxisAlignment.end;
      case TextAlign.justify:
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }
}
