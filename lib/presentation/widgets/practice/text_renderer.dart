import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'property_panels/justified_text_renderer.dart';
import 'property_panels/vertical_column_justified_text.dart';

/// 文本渲染器
/// 用于在画布和属性面板预览中统一渲染文本
class TextRenderer {
  /// 计算每列最多可容纳的字符数
  static int calculateMaxCharsPerColumn(double maxHeight, double charHeight,
      double lineHeight, double letterSpacing) {
    // 计算单个字符的有效高度（包括行高和字间距）
    final effectiveCharHeight = charHeight * lineHeight + letterSpacing;

    // 计算可容纳的最大字符数（向下取整）
    return (maxHeight / effectiveCharHeight).floor();
  }

  static String convertLTRHorizontalFittedText(String text,
      BoxConstraints constraints, double padding, TextStyle style) {
    final lines = splitTextToLines(text);
    final fittedLines = <String>[];

    // Create a TextPainter to measure text width
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      maxLines: 1,
      text: const TextSpan(text: ''), // Initialize with empty text
    );

    final maxWidth = constraints.maxWidth - padding * 2;

    for (final line in lines) {
      // Check if the line needs to be split due to width constraints
      textPainter.text = TextSpan(text: line, style: style);
      textPainter.layout(maxWidth: double.infinity);

      if (textPainter.width <= maxWidth) {
        // Line fits, no need to split
        fittedLines.add(line);
      } else {
        // Line needs splitting
        String currentLine = '';

        for (int i = 0; i < line.length; i++) {
          final char = line[i];
          final testLine = currentLine + char;

          textPainter.text = TextSpan(
            text: testLine,
            style: style,
          );
          textPainter.layout(maxWidth: double.infinity);

          if (textPainter.width <= maxWidth) {
            currentLine = testLine;
          } else {
            if (currentLine.isNotEmpty) {
              fittedLines.add(currentLine);
              currentLine = char;
            }
          }
        }

        if (currentLine.isNotEmpty) {
          fittedLines.add(currentLine);
        }
      }
    }

    text = fittedLines.join('\n');
    // developer.log('text: $text');
    return text;
  }

  static String convertRTLHorizontalFittedText(String text,
      BoxConstraints constraints, double padding, TextStyle style) {
    final lines = splitTextToLines(text);
    final reversedLines = <String>[];

    // Create a TextPainter to measure text width
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      maxLines: 1,
      text: const TextSpan(text: ''), // Initialize with empty text
    );

    final maxWidth = constraints.maxWidth - padding * 2;

    for (final line in lines) {
      // First reverse the characters in the line for RTL rendering
      final reversedLine = String.fromCharCodes(line.runes.toList().reversed);

      // Check if the line needs to be split due to width constraints
      textPainter.text = TextSpan(text: reversedLine, style: style);
      textPainter.layout(maxWidth: double.infinity);

      if (textPainter.width <= maxWidth) {
        // Line fits, no need to split
        reversedLines.add(reversedLine);
      } else {
        // Line needs splitting for RTL text
        String currentLine = '';
        List<String> segmentedLines = [];

        // Process character by character for RTL text, starting from the end
        for (int i = reversedLine.length - 1; i >= 0; i--) {
          final char = reversedLine[i];
          final testLine =
              char + currentLine; // Add new chars at beginning for RTL

          textPainter.text = TextSpan(
            text: testLine,
            style: style,
          );
          textPainter.layout(maxWidth: double.infinity);

          if (textPainter.width <= maxWidth) {
            currentLine = testLine;
          } else {
            if (currentLine.isNotEmpty) {
              segmentedLines.insert(0, currentLine);
              currentLine = char;
            } else {
              // Single character is too wide, add it anyway
              segmentedLines.insert(0, char);
              currentLine = '';
            }
          }
        }

        if (currentLine.isNotEmpty) {
          segmentedLines.insert(0, currentLine);
        }

        // Add lines in reverse order to maintain correct RTL reading order
        reversedLines.addAll(segmentedLines.reversed);
      }
    }

    text = reversedLines.join('\n');
    // developer.log('text: $text');
    return text;
  }

  /// 创建文本样式
  static TextStyle createTextStyle({
    required double fontSize,
    required String fontFamily,
    required String fontWeight,
    required String fontStyle,
    required String fontColor,
    required double letterSpacing,
    required double lineHeight,
    required bool underline,
    required bool lineThrough,
  }) {
    // 创建文本装饰列表
    final List<TextDecoration> decorations = [];
    if (underline) decorations.add(TextDecoration.underline);
    if (lineThrough) decorations.add(TextDecoration.lineThrough);

    // 解析颜色
    Color parsedFontColor;
    try {
      parsedFontColor = Color(int.parse(fontColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      developer.log('解析颜色失败: $e');
      parsedFontColor = Colors.black;
    }

    // 创建基本文本样式
    return TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
      fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: parsedFontColor,
      letterSpacing: letterSpacing,
      height: lineHeight,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );
  }

  /// 获取列对齐方式
  static CrossAxisAlignment getColumnAlignment(String textAlign) {
    switch (textAlign) {
      case 'left': // 左对齐
        return CrossAxisAlignment.start;
      case 'center': // 水平居中
        return CrossAxisAlignment.center;
      case 'right': // 右对齐
        return CrossAxisAlignment.end;
      case 'justify': // 两端对齐
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }

  /// 获取文本对齐方式
  static TextAlign getTextAlign(String textAlign) {
    switch (textAlign) {
      case 'left':
        return TextAlign.left;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  /// 获取垂直方向主轴对齐方式
  static MainAxisAlignment getVerticalMainAlignment(String verticalAlign) {
    switch (verticalAlign) {
      case 'top': // 顶部对齐
        return MainAxisAlignment.start;
      case 'middle': // 垂直居中
        return MainAxisAlignment.center;
      case 'bottom': // 底部对齐
        return MainAxisAlignment.end;
      case 'justify': // 两端对齐
        return MainAxisAlignment.spaceBetween;
      default:
        return MainAxisAlignment.start;
    }
  }

  /// 将十六进制颜色字符串转换为Color对象
  static Color hexToColor(String hexString) {
    if (hexString == 'transparent') {
      return Colors.transparent;
    }

    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    try {
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      developer.log('解析颜色失败: $e');
      return Colors.black;
    }
  }

  /// 渲染水平文本
  static Widget renderHorizontalText({
    required String text,
    required TextStyle style,
    required String textAlign,
    required String verticalAlign,
    required String writingMode,
    required BoxConstraints constraints,
    double padding = 0.0,
    Color backgroundColor = Colors.transparent,
  }) {
    // // 添加调试日志
    // developer.log(
    //     '水平文本渲染: writingMode=$writingMode, textAlign=$textAlign, verticalAlign=$verticalAlign');
    // developer.log(
    //     '水平文本约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');
    // developer.log('水平文本内容: text=$text');
    // developer.log(
    //     '水平文本样式: fontSize=${style.fontSize}, fontFamily=${style.fontFamily}, fontWeight=${style.fontWeight}, fontStyle=${style.fontStyle}, color=${style.color}');

    final isRightToLeft = writingMode == 'horizontal-r';
    final textAlignEnum = getTextAlign(textAlign);

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
        // 如果垂直对齐是两端对齐，且有多行文本，使用特殊处理
        if (splitTextToLines(text).length > 1) {
          return _buildVerticalJustifiedText(
            text: text,
            style: style,
            textAlign: textAlignEnum,
            isRightToLeft: isRightToLeft,
            constraints: constraints,
            padding: padding,
            backgroundColor: backgroundColor,
          );
        }
        // 单行文本使用居中对齐
        alignment = Alignment.center;
        break;
      default:
        alignment = Alignment.topCenter;
    }

    // 处理从右到左的文本和自动换行
    text = isRightToLeft
        ? convertRTLHorizontalFittedText(text, constraints, padding, style)
        : convertLTRHorizontalFittedText(text, constraints, padding, style);

    // 对于水平两端对齐，使用我们的 JustifiedTextRenderer
    if (textAlign == 'justify') {
      developer.log('使用JustifiedTextRenderer渲染水平两端对齐文本');

      // 分割文本为行
      final lines = splitTextToLines(text);

      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        alignment: alignment,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: lines.map((line) {
              // 对于每行文本使用JustifiedTextRenderer
              return JustifiedTextRenderer(
                text: line,
                style: style,
                lineHeight: style.height ?? 1.2,
                maxWidth: constraints.maxWidth - padding * 2,
                isRightToLeft: isRightToLeft,
              );
            }).toList(),
          ),
        ),
      );
    }

    // 正常的水平文本渲染
    return Container(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      padding: EdgeInsets.all(padding),
      color: backgroundColor,
      alignment: alignment,
      child: SingleChildScrollView(
        child: Text(
          softWrap: false,
          overflow: TextOverflow.clip,
          text,
          style: style,
          textAlign: textAlignEnum,
          textDirection: isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
        ),
      ),
    );
  }

  /// 渲染文本
  /// 根据书写模式选择不同的渲染方式
  static Widget renderText({
    required String text,
    required TextStyle style,
    required String textAlign,
    required String verticalAlign,
    required String writingMode,
    required BoxConstraints constraints,
    double padding = 0.0,
    Color backgroundColor = Colors.transparent,
  }) {
    // 添加调试日志
    developer.log(
        '画布文本元素渲染: writingMode=$writingMode, textAlign=$textAlign, verticalAlign=$verticalAlign');
    developer.log(
        '画布文本元素约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');

    // 根据书写模式选择不同的渲染方式
    if (writingMode.startsWith('vertical')) {
      return renderVerticalText(
        text: text,
        style: style,
        textAlign: textAlign,
        verticalAlign: verticalAlign,
        writingMode: writingMode,
        constraints: constraints,
        padding: padding,
        backgroundColor: backgroundColor,
      );
    } else {
      return renderHorizontalText(
        text: text,
        style: style,
        textAlign: textAlign,
        verticalAlign: verticalAlign,
        writingMode: writingMode,
        constraints: constraints,
        padding: padding,
        backgroundColor: backgroundColor,
      );
    }
  }

  /// 渲染垂直文本
  static Widget renderVerticalText({
    required String text,
    required TextStyle style,
    required String textAlign,
    required String verticalAlign,
    required String writingMode,
    required BoxConstraints constraints,
    double padding = 0.0,
    Color backgroundColor = Colors.transparent,
  }) {
    // 添加调试日志
    developer.log(
        '垂直文本渲染: writingMode=$writingMode, textAlign=$textAlign, verticalAlign=$verticalAlign');
    developer.log(
        '垂直文本约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');
    developer.log('垂直文本内容: text=$text');
    developer.log(
        '垂直文本样式: fontSize=${style.fontSize}, fontFamily=${style.fontFamily}, fontWeight=${style.fontWeight}, fontStyle=${style.fontStyle}, color=${style.color}');

    // 竖排左书（vertical-l）列从左到右排列，竖排右书（vertical-r）列从右到左排列
    final isRightToLeft = writingMode == 'vertical-l';

    // 创建内容小部件
    final contentWidget = _buildVerticalTextLayout(
      text: text,
      style: style,
      verticalAlign: verticalAlign,
      textAlign: textAlign,
      constraints: BoxConstraints(
        maxWidth: constraints.maxWidth - padding * 2,
        maxHeight: constraints.maxHeight - padding * 2,
      ),
      isRightToLeft: isRightToLeft,
    );

    // 在整个预览区域内应用对齐效果
    // 根据水平和垂直对齐方式决定容器的对齐方式
    Alignment containerAlignment;

    // 先处理水平对齐
    Alignment horizontalAlignment;
    switch (textAlign) {
      case 'left':
        horizontalAlignment = Alignment.centerLeft;
        break;
      case 'center':
        horizontalAlignment = Alignment.center;
        break;
      case 'right':
        horizontalAlignment = Alignment.centerRight;
        break;
      case 'justify':
        // 对于水平两端对齐，我们需要特殊处理
        // 在竖排文本中，水平两端对齐意味着列之间应该平均分布
        // 而列内的文字应该按照垂直对齐方式来对齐
        horizontalAlignment = Alignment.center; // 使用居中对齐，因为我们将在外部容器中处理两端对齐
        break;
      default:
        horizontalAlignment = Alignment.centerLeft;
    }

    // 再处理垂直对齐
    Alignment verticalAlignment;
    switch (verticalAlign) {
      case 'top':
        verticalAlignment = Alignment.topCenter;
        break;
      case 'middle':
        verticalAlignment = Alignment.center;
        break;
      case 'bottom':
        verticalAlignment = Alignment.bottomCenter;
        break;
      case 'justify':
        // 对于垂直两端对齐，我们使用居中对齐
        verticalAlignment = Alignment.center;
        break;
      default:
        verticalAlignment = Alignment.topCenter;
    }

    // 组合水平和垂直对齐
    if (horizontalAlignment == Alignment.centerLeft) {
      if (verticalAlignment == Alignment.topCenter) {
        containerAlignment = Alignment.topLeft;
      } else if (verticalAlignment == Alignment.bottomCenter) {
        containerAlignment = Alignment.bottomLeft;
      } else {
        containerAlignment = Alignment.centerLeft;
      }
    } else if (horizontalAlignment == Alignment.centerRight) {
      if (verticalAlignment == Alignment.topCenter) {
        containerAlignment = Alignment.topRight;
      } else if (verticalAlignment == Alignment.bottomCenter) {
        containerAlignment = Alignment.bottomRight;
      } else {
        containerAlignment = Alignment.centerRight;
      }
    } else {
      // center
      containerAlignment = verticalAlignment;
    }

    // 打印调试信息
    developer.log(
        '预览区域对齐方式: 水平=$textAlign, 垂直=$verticalAlign, 容器对齐=$containerAlignment');

    // 打印调试信息
    developer.log(
        '竖排文本对齐方式: 水平=$textAlign, 垂直=$verticalAlign, 容器对齐=$containerAlignment');

    // 对于水平两端对齐，我们需要特殊处理
    if (textAlign == 'justify') {
      // 对于水平两端对齐，我们需要将列在整个预览区域内平均分布
      // 而列内的文字应该按照垂直对齐方式来对齐
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: contentWidget,
        ),
      );
    } else if (verticalAlign == 'justify') {
      // 对于垂直两端对齐，我们需要特殊处理
      // 在竖排文本中，垂直两端对齐意味着列内的文字应该垂直均匀分布
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        alignment: horizontalAlignment, // 只应用水平对齐，垂直对齐由列内处理
        child: ClipRect(clipBehavior: Clip.hardEdge, child: contentWidget),
      );
    } else {
      // 对于其他对齐方式，我们使用原来的实现
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        alignment: containerAlignment, // 在整个预览区域内应用水平和垂直对齐
        child: ClipRect(clipBehavior: Clip.hardEdge, child: contentWidget),
      );
    }
  }

  /// 将文本分割为行
  static List<String> splitTextToLines(String text) {
    return text.split('\n');
  }

  /// 构建垂直方向两端对齐的文本
  static Widget _buildVerticalJustifiedText({
    required String text,
    required TextStyle style,
    required TextAlign textAlign,
    required bool isRightToLeft,
    required BoxConstraints constraints,
    double padding = 0.0,
    Color backgroundColor = Colors.transparent,
  }) {
    // 打印调试信息
    developer.log(
        '垂直两端对齐文本: textAlign=${textAlign.toString()}, isRightToLeft=$isRightToLeft');
    developer.log(
        '垂直两端对齐文本约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');
    developer.log('垂直两端对齐文本内容: text=$text');
    developer.log(
        '垂直两端对齐文本样式: fontSize=${style.fontSize}, fontFamily=${style.fontFamily}, fontWeight=${style.fontWeight}, fontStyle=${style.fontStyle}, color=${style.color}');
    developer.log('垂直两端对齐文本行数: ${splitTextToLines(text).length}');

    final lines = splitTextToLines(isRightToLeft
        ? convertRTLHorizontalFittedText(text, constraints, padding, style)
        : convertLTRHorizontalFittedText(text, constraints, padding, style));

    // 计算行高
    final lineHeight = style.fontSize! * (style.height ?? 1.2);

    // 计算总文本高度
    final totalTextHeight = lines.length * lineHeight;

    // 计算可用空间
    final availableHeight = constraints.maxHeight - padding * 2;

    // 如果总文本高度小于可用高度，则使用两端对齐
    if (totalTextHeight < availableHeight && lines.length > 1) {
      // 注意：这里不需要显式设置行间距，因为我们使用 MainAxisAlignment.spaceBetween

      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // 使用两端对齐
          crossAxisAlignment: CrossAxisAlignment.stretch, // 确保子元素占据整个宽度
          children: lines.map((line) {
            // 如果水平对齐也是两端对齐，则使用 JustifiedTextRenderer
            if (textAlign == TextAlign.justify) {
              return JustifiedTextRenderer(
                text: line,
                style: style,
                lineHeight: style.height ?? 1.2,
                maxWidth: constraints.maxWidth - padding * 2,
                isRightToLeft: false,
              );
            } else {
              // 否则使用普通的 Text 组件
              return SizedBox(
                width: constraints.maxWidth - padding * 2, // 确保占据整个容器宽度
                child: Text(
                  softWrap: false,
                  line,
                  style: style,
                  textAlign: textAlign,
                  textDirection:
                      isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
                ),
              );
            }
          }).toList(),
        ),
      );
    } else {
      // 如果总文本高度大于可用高度，则使用滚动视图
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // 确保子元素占据整个宽度
            children: lines.map((line) {
              // 如果水平对齐也是两端对齐，则使用 JustifiedTextRenderer
              if (textAlign == TextAlign.justify) {
                return JustifiedTextRenderer(
                  text: line,
                  style: style,
                  lineHeight: style.height ?? 1.2,
                  maxWidth: constraints.maxWidth - padding * 2,
                  isRightToLeft: isRightToLeft,
                );
              } else {
                // 否则使用普通的 Text 组件
                return SizedBox(
                  width: constraints.maxWidth - padding * 2, // 确保占据整个容器宽度
                  child: Text(
                    softWrap: false,
                    line,
                    style: style,
                    textAlign: textAlign,
                    textDirection:
                        isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
                  ),
                );
              }
            }).toList(),
          ),
        ),
      );
    }
  }

  /// 构建垂直文本布局
  static Widget _buildVerticalTextLayout({
    required String text,
    required TextStyle style,
    required String verticalAlign,
    required String textAlign,
    required BoxConstraints constraints,
    required bool isRightToLeft,
  }) {
    if (text.isEmpty) {
      text = '预览文本内容\n第二行文本\n第三行文本';
    }

    // 处理行和字符
    List<String> lines = splitTextToLines(text);

    // 注意：不需要反转行顺序
    // 无论是竖排左书还是竖排右书，行的顺序都应该是从上往下的

    // 计算每列可容纳的最大字符数
    final charHeight = style.fontSize ?? 16.0;
    final effectiveLineHeight = style.height ?? 1.2;
    final effectiveLetterSpacing = style.letterSpacing ?? 0.0;
    final maxCharsPerColumn = calculateMaxCharsPerColumn(
      constraints.maxHeight,
      charHeight,
      effectiveLineHeight,
      effectiveLetterSpacing,
    );

    // 生成所有列的数据
    final allColumns = <Widget>[];
    int newLineIndex = 0;
    int currentIndex = 0;

    // 为每一行创建列，并记录每行的起始位置
    for (final line in lines) {
      final chars = line.characters.toList();
      int charIdx = 0;

      newLineIndex = currentIndex;
      while (charIdx < chars.length) {
        // 计算当前列要显示多少字符
        final charsInThisColumn =
            math.min(maxCharsPerColumn, chars.length - charIdx);
        final columnChars = chars.sublist(charIdx, charIdx + charsInThisColumn);

        // 创建当前列的Widget
        Widget columnWidget;

        // 如果是水平两端对齐（在竖排文本中对应垂直方向）
        if (textAlign == 'justify' && columnChars.length > 1) {
          // 使用固定宽度的列，确保在画布和预览区中保持一致
          final columnWidth = charHeight; // 增加容器宽度，使对齐效果更明显

          // 使用竖排文本两端对齐组件
          columnWidget = VerticalColumnJustifiedText(
            characters: columnChars,
            style: style,
            maxHeight: constraints.maxHeight,
            columnWidth: columnWidth, // 使用固定宽度
            verticalAlign: verticalAlign, // 传递垂直对齐方式
            isRightToLeft: isRightToLeft,
          );
        } else {
          // 其他对齐方式使用普通容器
          // 打印调试信息
          // developer.log('创建列容器: 垂直对齐=$verticalAlign, 水平对齐=$textAlign');

          // 对于垂直对齐，我们需要修改容器结构
          // 不使用 SingleChildScrollView 包裹 Column，因为这会导致 mainAxisAlignment 失效
          // 使用固定宽度的列，确保在画布和预览区中保持一致
          final columnWidth = charHeight; // 增加容器宽度，使对齐效果更明显

          columnWidget = Container(
            width: columnWidth,
            height: constraints.maxHeight,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: getVerticalMainAlignment(verticalAlign),
              children: columnChars.map((char) {
                // 确保 letterSpacing 不为负值
                final effectivePadding =
                    effectiveLetterSpacing > 0 ? effectiveLetterSpacing : 0.0;

                // 处理水平对齐
                Widget charWidget;

                // 对于两端对齐，我们需要特殊处理
                if (textAlign == 'justify') {
                  // 对于单个字符，两端对齐没有意义，使用居中对齐
                  // 使用固定宽度的容器，确保在画布和预览区中保持一致
                  charWidget = SizedBox(
                    width: columnWidth, // 使用与列相同的宽度
                    child: Center(
                      child: Text(
                        softWrap: false,
                        char,
                        style: style,
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

                  // 使用固定宽度的容器，确保在画布和预览区中保持一致
                  charWidget = Container(
                    width: columnWidth, // 使用与列相同的宽度
                    alignment: alignment,
                    child: Text(
                      softWrap: false,
                      char,
                      style: style,
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: effectivePadding,
                  ),
                  child: charWidget,
                );
              }).toList(),
            ),
          );
        }

        allColumns.add(columnWidget);
        currentIndex++;
        charIdx += charsInThisColumn;
      }
    }

    // 确保有内容显示，即使没有文本
    if (allColumns.isEmpty) {
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: const Center(
          child: Text(
            '暂无内容',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // 根据书写方向确定列的排列顺序
    // 竖排左书(isRightToLeft=true) - 从左向右显示列
    // 竖排右书(isRightToLeft=false) - 从右向左显示列
    final List<Widget> columns;
    if (isRightToLeft) {
      // 竖排左书 - 从左向右显示列，不需要反转
      columns = allColumns.toList();
    } else {
      // 竖排右书 - 从右向左显示列
      columns = allColumns.reversed.toList();
    }

    // 创建ScrollController，用于控制滚动位置
    final ScrollController scrollController = ScrollController();

    // 打印调试信息
    developer.log(
        '垂直文本布局: 垂直对齐=$verticalAlign, 水平对齐=$textAlign, 列数=${columns.length}');
    developer.log(
        '垂直文本布局约束: width=${constraints.maxWidth}, height=${constraints.maxHeight}');
    developer.log('垂直文本布局书写方向: isRightToLeft=$isRightToLeft');
    developer.log('垂直文本布局内容: text=$text');
    developer.log(
        '垂直文本布局样式: fontSize=${style.fontSize}, fontFamily=${style.fontFamily}, fontWeight=${style.fontWeight}, fontStyle=${style.fontStyle}, color=${style.color}');
    developer.log('垂直文本布局行数: ${lines.length}');

    // 对于水平两端对齐，我们需要特殊处理
    if (textAlign == 'justify' && columns.length > 1) {
      // 对于水平两端对齐，我们需要确保列在整个预览区域内平均分布
      // 并且首尾两排紧贴预览区边缘

      // 使用 Flexible 包裹每个列，确保它们能够适应可用空间
      final wrappedColumns = columns.map((column) {
        return Flexible(
          // 使用 FlexFit.loose 允许列收缩
          fit: FlexFit.loose,
          child: column,
        );
      }).toList();

      // 使用 LayoutBuilder 动态获取可用空间
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            // 添加剪裁以防止溢出
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: Row(
              // textDirection:
              //     isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // 使用 spaceBetween 实现两端对齐
              // 使用 MainAxisSize.max 确保 Row 占据所有可用空间
              mainAxisSize: MainAxisSize.max,
              children: wrappedColumns,
            ),
          );
        },
      );
    } else {
      // 对于其他对齐方式，我们使用原来的实现
      return SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          // textDirection: isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: columns,
        ),
      );
    }
  }
}
