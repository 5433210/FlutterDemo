import 'dart:math' as math;
import 'dart:ui' as ui;

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
    if (text.isEmpty) {
      return SizedBox(width: maxWidth);
    }

    // 分割文本为段落
    final paragraphs = text.split('\n');

    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用可用宽度，但不超过maxWidth
        final availableWidth = constraints.maxWidth > 0
            ? math.min(constraints.maxWidth, maxWidth)
            : maxWidth;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: paragraphs.map((paragraph) {
            // 空段落显示为空行
            if (paragraph.isEmpty) {
              return SizedBox(
                height: style.fontSize! * lineHeight,
              );
            }

            // 处理段落
            return _JustifiedParagraph(
              text: paragraph,
              style: style,
              lineHeight: lineHeight,
              maxWidth: availableWidth,
              isRightToLeft: isRightToLeft,
            );
          }).toList(),
        );
      },
    );
  }
}

/// 处理单行的两端对齐
class _JustifiedLine extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double lineHeight;
  final double maxWidth;
  final bool isRightToLeft;

  const _JustifiedLine({
    required this.text,
    required this.style,
    required this.lineHeight,
    required this.maxWidth,
    required this.isRightToLeft,
  });

  @override
  Widget build(BuildContext context) {
    // 如果行是空的或只有一个字符，不需要两端对齐
    if (text.isEmpty || text.length == 1 || text.trim().isEmpty) {
      return Container(
        height: style.fontSize! * lineHeight,
        alignment: isRightToLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          isRightToLeft ? _reverseString(text) : text,
          style: style,
          textAlign: isRightToLeft ? TextAlign.right : TextAlign.left,
        ),
      );
    }

    return CustomPaint(
      size: Size(maxWidth, style.fontSize! * lineHeight),
      painter: _JustifiedTextPainter(
        text: text,
        style: style,
        maxWidth: maxWidth,
        isRightToLeft: isRightToLeft,
      ),
    );
  }

  String _reverseString(String text) {
    return String.fromCharCodes(text.runes.toList().reversed);
  }
}

/// 处理单个段落的两端对齐
class _JustifiedParagraph extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double lineHeight;
  final double maxWidth;
  final bool isRightToLeft;

  const _JustifiedParagraph({
    required this.text,
    required this.style,
    required this.lineHeight,
    required this.maxWidth,
    required this.isRightToLeft,
  });

  @override
  Widget build(BuildContext context) {
    // 计算段落需要的行数和每行的文本
    final lines = _breakTextIntoLines(text, style, maxWidth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: lines.map((line) {
        return _JustifiedLine(
          text: line,
          style: style,
          lineHeight: lineHeight,
          maxWidth: maxWidth,
          isRightToLeft: isRightToLeft,
        );
      }).toList(),
    );
  }

  /// 将文本分解成多行，考虑到字符宽度和可用空间
  List<String> _breakTextIntoLines(
      String text, TextStyle style, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: maxWidth);

    // 获取TextPainter自动计算的行边界
    final List<ui.LineMetrics> lines = textPainter.computeLineMetrics();
    final List<String> textLines = [];

    // 根据行边界提取每行文本
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final start = textPainter
          .getPositionForOffset(Offset(0, line.baseline - line.ascent))
          .offset;
      final end = i < lines.length - 1
          ? textPainter
                  .getPositionForOffset(
                      Offset(0, lines[i + 1].baseline - lines[i + 1].ascent))
                  .offset -
              1
          : text.length;

      if (start < end && end <= text.length) {
        textLines.add(text.substring(start, end));
      }
    }

    return textLines;
  }
}

/// 自定义绘制器，用于精确控制字符位置以实现两端对齐
class _JustifiedTextPainter extends CustomPainter {
  final String text;
  final TextStyle style;
  final double maxWidth;
  final bool isRightToLeft;

  const _JustifiedTextPainter({
    required this.text,
    required this.style,
    required this.maxWidth,
    required this.isRightToLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final String displayText = text.trim();
    if (displayText.isEmpty) return;

    // 计算字符宽度和总宽度
    final List<double> charWidths = [];
    double totalWidth = 0;

    // 获取字符列表，并根据方向设置
    final characters = displayText.characters.toList();
    final displayChars =
        isRightToLeft ? characters.reversed.toList() : characters;

    // 计算每个字符的宽度
    for (final char in displayChars) {
      final width = _measureTextWidth(char, style);
      charWidths.add(width);
      totalWidth += width;
    }

    // 计算需要分配的额外空间
    final double extraSpace = size.width - totalWidth;

    // 如果没有足够的空间或只有一个字符，直接绘制不对齐
    if (extraSpace <= 0 || displayChars.length <= 1) {
      final textPainter = TextPainter(
        text: TextSpan(text: displayText, style: style),
        textDirection: isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
        textAlign: isRightToLeft ? TextAlign.right : TextAlign.left,
      );
      textPainter.layout(maxWidth: size.width);
      textPainter.paint(
          canvas, Offset(0, (size.height - textPainter.height) / 2));
      return;
    }

    // 计算间距
    final double spacing = extraSpace / (displayChars.length - 1);

    // 绘制每个字符，带有计算好的间距
    double xPos = 0;
    for (int i = 0; i < displayChars.length; i++) {
      final char = displayChars[i];
      final width = charWidths[i];

      final textPainter = TextPainter(
        text: TextSpan(text: char, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // 将字符绘制在计算好的位置上
      textPainter.paint(
          canvas, Offset(xPos, (size.height - textPainter.height) / 2));

      // 更新下一个字符的位置
      xPos += width + (i < displayChars.length - 1 ? spacing : 0);
    }
  }

  @override
  bool shouldRepaint(_JustifiedTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.style != style ||
        oldDelegate.maxWidth != maxWidth ||
        oldDelegate.isRightToLeft != isRightToLeft;
  }

  /// 测量文本宽度的辅助方法
  double _measureTextWidth(String text, TextStyle style) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    );
    textPainter.layout();
    return textPainter.width;
  }
}
