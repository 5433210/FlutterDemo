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
  Widget _buildHorizontalText({
    required String text,
    required TextStyle style,
    required TextAlign textAlign,
    required String verticalAlign,
    required bool isRightToLeft,
    required BoxConstraints constraints,
  }) {
    // 如果是从右到左的水平文本，需要反转文本
    if (isRightToLeft) {
      final lines = text.split('\n');
      final reversedLines = lines
          .map((line) => String.fromCharCodes(line.runes.toList().reversed))
          .toList();
      text = reversedLines.join('\n');
    }

    // 设置垂直对齐
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
        alignment = Alignment.center; // 对于 justify，我们会在容器中特别处理
        break;
      default:
        alignment = Alignment.topCenter;
    }

    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      alignment: alignment,
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }

  /// 构建垂直文本
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

    // 根据书写模式确定行的顺序
    // vertical-r (竖排右书): 从上到下，从右到左
    // vertical-l (竖排左书): 从上到下，从左到右

    // 注意：在属性面板中，vertical-r 的 isRightToLeft 设置为 false，vertical-l 的 isRightToLeft 设置为 true
    // 这里我们需要保持一致

    // 对于特殊字符，如横排文字、数字、英文等，可能需要特殊处理
    // 这里我们保持原样，实际应用中可能需要更复杂的处理

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
          alignment: _getVerticalAlignment(verticalAlign),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: _getVerticalMainAlignment(textAlign),
            children: [
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: _getVerticalMainAlignment(textAlign),
                  children: columnChars.map((char) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: effectiveLetterSpacing,
                      ),
                      child: Text(
                        char,
                        style: style,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
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

    // 竖排右书应该从右往左排列列
    if (writingMode == 'vertical-r') {
      // 竖排右书：从右往左排列，需要反转列的顺序
      finalColumns = finalColumns.reversed.toList();
      developer.log('竖排右书: 列已反转');
    } else {
      developer.log('竖排左书: 列保持原样');
    }

    // 添加调试日志
    developer.log(
        'Vertical text columns: ${finalColumns.length}, writing mode: $writingMode');

    // 返回包含所有列的水平滚动视图
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      controller: ScrollController(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: _getRowCrossAlignment(verticalAlign),
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

  /// 获取行的交叉轴对齐方式 (用于垂直文本中的行对齐)
  CrossAxisAlignment _getRowCrossAlignment(String verticalAlign) {
    switch (verticalAlign) {
      case 'top': // 在垂直模式中对应左对齐
        return CrossAxisAlignment.start;
      case 'middle':
        return CrossAxisAlignment.center;
      case 'bottom': // 在垂直模式中对应右对齐
        return CrossAxisAlignment.end;
      case 'justify':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.center;
    }
  }

  /// 获取垂直对齐方式（用于Container的alignment属性）
  Alignment _getVerticalAlignment(String verticalAlign) {
    switch (verticalAlign) {
      case 'top':
        return Alignment.topCenter;
      case 'middle':
        return Alignment.center;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'justify':
        return Alignment.center; // justify使用center，实际布局由内部控制
      default:
        return Alignment.topCenter;
    }
  }

  /// 获取垂直方向主轴对齐方式
  MainAxisAlignment _getVerticalMainAlignment(String textAlign) {
    switch (textAlign) {
      case 'left': // 在垂直模式中对应顶部对齐
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'right': // 在垂直模式中对应底部对齐
        return MainAxisAlignment.end;
      case 'justify':
        return MainAxisAlignment.spaceBetween;
      default:
        return MainAxisAlignment.start;
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
