import 'package:flutter/material.dart';

/// 自定义两端对齐文本渲染器
/// 用于实现真正的两端对齐效果，特别是对中文等CJK文字
class JustifiedTextRenderer extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double lineHeight;
  final double maxWidth;
  final bool isRightToLeft; // 是否从右到左显示（横排右书）

  const JustifiedTextRenderer({
    Key? key,
    required this.text,
    required this.style,
    this.lineHeight = 1.2,
    required this.maxWidth,
    this.isRightToLeft = false, // 默认为从左到右（横排左书）
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 分割文本为行
    final paragraphs = text.split('\n');
    final List<String> wrappedLines = [];

    // 对每个段落进行自动断行处理
    for (final paragraph in paragraphs) {
      if (paragraph.isEmpty) {
        wrappedLines.add('');
        continue;
      }

      // 将长段落根据宽度自动断行
      final brokenLines = _breakTextIntoLines(paragraph, style, maxWidth);
      wrappedLines.addAll(brokenLines);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: wrappedLines.map((line) => _buildJustifiedLine(line)).toList(),
    );
  }

  /// 将长文本根据宽度自动断行
  List<String> _breakTextIntoLines(
      String text, TextStyle style, double maxWidth) {
    if (text.isEmpty) return [''];

    final List<String> lines = [];
    final characters = text.characters.toList();

    // 当前行的字符列表
    List<String> currentLine = [];
    // 当前行的宽度
    double currentLineWidth = 0.0;

    for (final char in characters) {
      // 计算当前字符的宽度
      final charWidth = _calculateTextWidth(char, style);

      // 如果添加当前字符后超出最大宽度，则开始新行
      if (currentLineWidth + charWidth > maxWidth && currentLine.isNotEmpty) {
        // 将当前行添加到行列表中
        lines.add(currentLine.join());
        // 重置当前行
        currentLine = [];
        currentLineWidth = 0.0;
      }

      // 添加字符到当前行
      currentLine.add(char);
      currentLineWidth += charWidth;
    }

    // 添加最后一行
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.join());
    }

    return lines;
  }

  /// 构建两端对齐的字符列表
  List<Widget> _buildJustifiedCharacters(List<String> characters,
      double spaceBetweenChars, List<double> charWidths) {
    final result = <Widget>[];

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

      // 在最后一个字符后不添加间距
      if (i < characters.length - 1) {
        result.add(
          SizedBox(width: spaceBetweenChars),
        );
      }
    }

    return result;
  }

  /// 构建单行两端对齐文本
  Widget _buildJustifiedLine(String line) {
    // 如果行为空或只有一个字符，则不需要两端对齐
    if (line.isEmpty || line.length == 1) {
      // 对于横排右书，需要反转字符顺序
      final displayText = isRightToLeft
          ? String.fromCharCodes(line.runes.toList().reversed)
          : line;

      return Text(
        displayText,
        style: style,
        textAlign: isRightToLeft ? TextAlign.right : TextAlign.left,
      );
    }

    // 获取字符列表
    var characters = line.characters.toList();

    // 对于横排右书，不需要反转字符顺序
    // 因为我们会使用 TextDirection.rtl 来控制显示方向

    // 计算每个字符的宽度
    final charWidths = _calculateCharWidths(characters, style);
    final totalCharsWidth = charWidths.reduce((a, b) => a + b);

    // 计算需要分配的额外空间
    final extraSpace = maxWidth - totalCharsWidth;

    // 如果没有额外空间或额外空间为负，则使用普通文本显示
    if (extraSpace <= 0) {
      // 对于横排右书，需要反转字符顺序
      final displayText = isRightToLeft
          ? String.fromCharCodes(line.runes.toList().reversed)
          : line;

      return Text(
        displayText,
        style: style,
        textAlign: isRightToLeft ? TextAlign.right : TextAlign.left,
      );
    }

    // 计算字符间距 (n-1个间隔)
    final spaceBetweenChars = extraSpace / (characters.length - 1);

    // 构建两端对齐的行
    return SizedBox(
      width: maxWidth,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
        children: _buildJustifiedCharacters(
            characters, spaceBetweenChars, charWidths),
      ),
    );
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
      // 使用textScaler替代已弃用的textScaleFactor
      textScaler: TextScaler.noScaling,
    )..layout();

    return textPainter.width;
  }
}
