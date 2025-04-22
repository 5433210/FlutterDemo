import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 文本元素渲染器
class TextElementRenderer extends StatelessWidget {
  final Map<String, dynamic> element;
  final bool isEditing;
  final bool isSelected;
  final double scale;

  const TextElementRenderer({
    Key? key,
    required this.element,
    this.isEditing = false,
    this.isSelected = false,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 添加调试日志
    developer
        .log('Building TextElementRenderer with element: ${element['id']}');
    final content = element['content'] as Map<String, dynamic>;
    final String text = content['text'] as String? ?? '';
    final double fontSize =
        ((content['fontSize'] as num?) ?? 16.0).toDouble() * scale;
    final String fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final String fontWeight = content['fontWeight'] as String? ?? 'normal';
    final String fontStyle = content['fontStyle'] as String? ?? 'normal';
    final String fontColorStr = content['fontColor'] as String? ?? '#000000';
    final Color fontColor = _hexToColor(fontColorStr);
    final String backgroundColorStr =
        content['backgroundColor'] as String? ?? 'transparent';
    final Color backgroundColor = _hexToColor(backgroundColorStr);
    final String textAlignStr = content['textAlign'] as String? ?? 'left';
    final String verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final double letterSpacing =
        (content['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    final double lineHeight =
        (content['lineHeight'] as num?)?.toDouble() ?? 1.2;
    final bool underline = content['underline'] as bool? ?? false;
    final bool lineThrough = content['lineThrough'] as bool? ?? false;
    final String writingMode =
        content['writingMode'] as String? ?? 'horizontal-l';
    final double padding = (content['padding'] as num?)?.toDouble() ?? 4.0;

    // 解析文本对齐方式
    TextAlign textAlign;
    switch (textAlignStr) {
      case 'center':
        textAlign = TextAlign.center;
        break;
      case 'right':
        textAlign = TextAlign.right;
        break;
      case 'justify':
        textAlign = TextAlign.justify;
        break;
      case 'left':
      default:
        textAlign = TextAlign.left;
    }

    // 创建文本装饰列表
    final List<TextDecoration> decorations = [];
    if (underline) decorations.add(TextDecoration.underline);
    if (lineThrough) decorations.add(TextDecoration.lineThrough);

    // 创建基本文本样式
    final TextStyle textStyle = TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
      fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: fontColor,
      letterSpacing: letterSpacing,
      height: lineHeight,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: isSelected
            ? Border.all(
                color: Colors.blue.withAlpha(128),
                width: 1.0,
              )
            : null,
      ),
      child: isEditing
          ? TextField(
              controller: TextEditingController(text: text),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: textStyle,
              textAlign: textAlign,
              maxLines: null,
              onChanged: (value) {
                // 实际应用中，这里应该触发一个回调来更新文本内容
              },
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // 根据书写模式选择不同的渲染方式
                developer.log('Rendering text with writing mode: $writingMode');
                if (writingMode.startsWith('vertical')) {
                  return _buildVerticalText(
                    text: text,
                    style: textStyle,
                    textAlign: textAlignStr,
                    verticalAlign: verticalAlign,
                    writingMode: writingMode, // 直接传递writingMode
                    constraints: constraints,
                  );
                } else {
                  // 水平文本渲染
                  return _buildHorizontalText(
                    text: text,
                    style: textStyle,
                    textAlign: textAlign,
                    verticalAlign: verticalAlign,
                    isRightToLeft: writingMode == 'horizontal-r',
                    constraints: constraints,
                  );
                }
              },
            ),
    );
  }

  /// 构建水平文本
  /// 水平文本有两种模式：
  /// 1. horizontal-l：从左到右书写（正常模式）
  /// 2. horizontal-r：从右到左书写（类似阿拉伯文）
  Widget _buildHorizontalText({
    required String text,
    required TextStyle style,
    required TextAlign textAlign,
    required String verticalAlign,
    required bool isRightToLeft,
    required BoxConstraints constraints,
  }) {
    // 对于从右到左的水平文本，我们使用 TextDirection.rtl
    // 而不是反转文本，这样可以保持文本的原始顺序
    final textDirection = isRightToLeft ? TextDirection.rtl : TextDirection.ltr;

    // 根据垂直对齐设置 alignment
    Alignment alignment;
    switch (verticalAlign) {
      case 'top':
        alignment = Alignment.topCenter;
        break;
      case 'middle':
        alignment = Alignment.center;
        break;
      case 'bottom':
        alignment = Alignment.bottomCenter;
        break;
      case 'justify':
        // 对于垂直方向的 justify，我们需要特殊处理
        return _buildVerticalJustifiedText(
          text: text,
          style: style,
          textAlign: textAlign,
          textDirection: textDirection,
          constraints: constraints,
        );
      default:
        alignment = Alignment.topCenter;
    }

    // 对于水平方向的 justify，我们需要确保文本能换行
    if (textAlign == TextAlign.justify) {
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        alignment: alignment,
        child: Text(
          text,
          style: style,
          textAlign: textAlign,
          textDirection: textDirection,
          softWrap: true,
          overflow: TextOverflow.clip,
        ),
      );
    }

    // 正常的水平文本渲染
    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      alignment: alignment,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
      ),
    );
  }

  /// 构建垂直文本列
  Widget _buildVerticalColumn({
    required List<String> chars,
    required TextStyle style,
    required String textAlign,
    required String verticalAlign,
    required double letterSpacing,
  }) {
    // 根据水平对齐设置列内字符的对齐方式
    MainAxisAlignment mainAlignment;
    switch (textAlign) {
      case 'left':
        mainAlignment = MainAxisAlignment.start;
        break;
      case 'center':
        mainAlignment = MainAxisAlignment.center;
        break;
      case 'right':
        mainAlignment = MainAxisAlignment.end;
        break;
      case 'justify':
        // 对于 justify，我们平均分布字符
        mainAlignment = MainAxisAlignment.spaceBetween;
        break;
      default:
        mainAlignment = MainAxisAlignment.start;
    }

    // 根据垂直对齐设置容器的对齐方式
    Alignment containerAlignment;
    switch (verticalAlign) {
      case 'top':
        containerAlignment = Alignment.topCenter;
        break;
      case 'middle':
        containerAlignment = Alignment.center;
        break;
      case 'bottom':
        containerAlignment = Alignment.bottomCenter;
        break;
      case 'justify':
        // 对于 justify，我们使用 center，并在 Column 中处理两端对齐
        containerAlignment = Alignment.center;
        break;
      default:
        containerAlignment = Alignment.topCenter;
    }

    return Container(
      alignment: containerAlignment,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: mainAlignment,
          children: chars.map((char) {
            // 确保 letterSpacing 不为负值
            final effectivePadding = letterSpacing > 0 ? letterSpacing : 0.0;
            return Padding(
              padding: EdgeInsets.only(bottom: effectivePadding),
              child: Text(
                char,
                style: style,
                textAlign: TextAlign.center,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// 构建垂直方向两端对齐的水平文本
  Widget _buildVerticalJustifiedText({
    required String text,
    required TextStyle style,
    required TextAlign textAlign,
    required TextDirection textDirection,
    required BoxConstraints constraints,
  }) {
    // 将文本分割为行
    final lines = text.split('\n');

    // 创建垂直方向均匀分布的文本行
    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment:
            _getHorizontalCrossAlignment(textAlign, textDirection),
        children: lines
            .map((line) => Text(
                  line,
                  style: style,
                  textAlign: textAlign,
                  textDirection: textDirection,
                ))
            .toList(),
      ),
    );
  }

  /// 构建垂直文本
  /// 垂直文本有两种模式：
  /// 1. vertical-r：竖排右书，从右到左排列列，每列从上到下排列字符
  /// 2. vertical-l：竖排左书，从左到右排列列，每列从上到下排列字符
  Widget _buildVerticalText({
    required String text,
    required TextStyle style,
    required String textAlign,
    required String verticalAlign,
    required String writingMode,
    required BoxConstraints constraints,
  }) {
    // 添加调试日志
    developer
        .log('Building vertical text with mode: $writingMode, text: $text');

    if (text.isEmpty) {
      return const Center(child: Text(''));
    }

    // 处理行和字符
    List<String> lines = text.split('\n');

    // 计算每列可容纳的最大字符数
    final charHeight = style.fontSize ?? 16.0;
    final effectiveLineHeight = style.height ?? 1.2;
    final effectiveLetterSpacing = style.letterSpacing ?? 0.0;
    final maxCharsPerColumn = _calculateMaxCharsPerColumn(
      constraints.maxHeight,
      charHeight,
      effectiveLineHeight,
      effectiveLetterSpacing,
    );

    // 生成所有列的数据
    final allColumns = <Widget>[];

    // 为每一行创建列
    for (final line in lines) {
      final chars = line.characters.toList();
      int charIdx = 0;

      while (charIdx < chars.length) {
        // 计算当前列要显示多少字符
        final charsInThisColumn =
            math.min(maxCharsPerColumn, chars.length - charIdx);
        final columnChars = chars.sublist(charIdx, charIdx + charsInThisColumn);

        // 创建当前列的Widget
        final columnWidget = Container(
          width: charHeight * 1.5, // 设置固定宽度，基于字体大小
          height: constraints.maxHeight,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          child: _buildVerticalColumn(
            chars: columnChars,
            style: style,
            textAlign: textAlign,
            verticalAlign: verticalAlign,
            letterSpacing: effectiveLetterSpacing,
          ),
        );

        allColumns.add(columnWidget);
        charIdx += charsInThisColumn;
      }

      // 在每行末尾添加分隔符，除非是最后一行
      if (line != lines.last) {
        allColumns.add(
          Container(
            width: 1,
            height: constraints.maxHeight,
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            color: Colors.grey.withAlpha(77),
          ),
        );
      }
    }

    // 确保有内容显示，即使没有文本
    if (allColumns.isEmpty) {
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: const Center(
          child: Text(
            '',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 根据书写方向确定列的排列顺序
    // 竖排右书 (vertical-r) 应该是从右往左的列顺序
    // 竖排左书 (vertical-l) 应该是从左往右的列顺序
    List<Widget> finalColumns = allColumns;
    final isRightToLeft = writingMode == 'vertical-r';

    // 竖排右书应该从右往左排列列
    if (isRightToLeft) {
      finalColumns = finalColumns.reversed.toList();
      developer.log('竖排右书: 列已反转');
    } else {
      developer.log('竖排左书: 列保持原样');
    }

    // 添加调试日志
    developer.log(
        'Vertical text columns: ${finalColumns.length}, writing mode: $writingMode');

    // 处理垂直方向的对齐
    CrossAxisAlignment crossAlignment;
    switch (verticalAlign) {
      case 'top':
        crossAlignment = CrossAxisAlignment.start;
        break;
      case 'middle':
        crossAlignment = CrossAxisAlignment.center;
        break;
      case 'bottom':
        crossAlignment = CrossAxisAlignment.end;
        break;
      case 'justify':
        crossAlignment = CrossAxisAlignment.stretch;
        break;
      default:
        crossAlignment = CrossAxisAlignment.center;
    }

    // 返回包含所有列的水平滚动视图
    // 不使用 ScrollController 以避免可能的内存泄漏
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAlignment,
        textDirection: isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
        children: finalColumns,
      ),
    );
  }

  /// 计算每列最多可容纳的字符数
  int _calculateMaxCharsPerColumn(double maxHeight, double charHeight,
      double lineHeight, double letterSpacing) {
    // 计算单个字符的有效高度（包括行高和字间距）
    final effectiveCharHeight = charHeight * lineHeight + letterSpacing;

    // 计算可容纳的最大字符数（向下取整）
    return (maxHeight / effectiveCharHeight).floor();
  }

  /// 获取水平对齐的交叉轴对齐方式
  CrossAxisAlignment _getHorizontalCrossAlignment(
      TextAlign textAlign, TextDirection textDirection) {
    if (textDirection == TextDirection.rtl) {
      // 从右到左的文本，需要反转对齐方式
      switch (textAlign) {
        case TextAlign.left:
          return CrossAxisAlignment.end;
        case TextAlign.right:
          return CrossAxisAlignment.start;
        case TextAlign.center:
          return CrossAxisAlignment.center;
        case TextAlign.justify:
          return CrossAxisAlignment.stretch;
        default:
          return CrossAxisAlignment.start;
      }
    } else {
      // 从左到右的文本，正常对齐方式
      switch (textAlign) {
        case TextAlign.left:
          return CrossAxisAlignment.start;
        case TextAlign.right:
          return CrossAxisAlignment.end;
        case TextAlign.center:
          return CrossAxisAlignment.center;
        case TextAlign.justify:
          return CrossAxisAlignment.stretch;
        default:
          return CrossAxisAlignment.start;
      }
    }
  }

  /// 将十六进制颜色字符串转换为Color对象
  Color _hexToColor(String hexString) {
    if (hexString == 'transparent') {
      return Colors.transparent;
    }

    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }
}
