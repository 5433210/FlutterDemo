import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
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
  /// 负责解析和验证字重，创建TextStyle对象
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
    EditPageLogger.editPageDebug(
      '创建文本样式',
      data: {
        'fontFamily': fontFamily,
        'fontWeight': fontWeight,
        'fontSize': fontSize,
        'fontStyle': fontStyle,
      },
    );

    // 验证字重是否有效
    if (!_isValidWeight(fontWeight)) {
      EditPageLogger.editPageWarning('无效的字重值，将使用默认值', data: {'invalidWeight': fontWeight, 'defaultWeight': 'w400'});
      fontWeight = 'w400';
    }

    // 创建文本装饰列表
    final List<TextDecoration> decorations = [];
    if (underline) decorations.add(TextDecoration.underline);
    if (lineThrough) decorations.add(TextDecoration.lineThrough);

    // 解析颜色
    Color parsedFontColor;
    try {
      parsedFontColor = Color(int.parse(fontColor.replaceFirst('#', '0xFF')));
    } catch (e) {
      EditPageLogger.editPageError('解析文本颜色失败', error: e, data: {'fontColor': fontColor});
      parsedFontColor = Colors.black;
    }

    // 解析字重值
    final finalWeight = _parseFontWeight(fontWeight);
    _validateFontWeightForFamily(fontFamily, finalWeight);

    // 获取字重数值（用于fontVariations）
    final int weightValue = _getWeightValue(fontWeight);
    developer.log('字重数值: $weightValue (用于fontVariations)');

    // 检查是否是思源字体，如果是则使用fontVariations
    bool isSourceHanFont =
        fontFamily == 'SourceHanSans' || fontFamily == 'SourceHanSerif';

    // 创建样式
    TextStyle style;
    if (isSourceHanFont) {
      // 对思源字体使用fontVariations以获得更精确的字重控制
      developer.log('使用fontVariations设置思源字体字重: $weightValue');
      style = TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        // 仍然设置fontWeight以保持向后兼容性
        fontWeight: finalWeight,
        fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        color: parsedFontColor,
        letterSpacing: letterSpacing,
        height: lineHeight,
        decoration: decorations.isEmpty
            ? TextDecoration.none
            : TextDecoration.combine(decorations),
        // 添加fontVariations属性
        fontVariations: [FontVariation('wght', weightValue.toDouble())],
      );
    } else {
      // 对其他字体使用标准fontWeight
      style = TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        fontWeight: finalWeight,
        fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        color: parsedFontColor,
        letterSpacing: letterSpacing,
        height: lineHeight,
        decoration: decorations.isEmpty
            ? TextDecoration.none
            : TextDecoration.combine(decorations),
      );
    }

    // 记录最终样式信息
    _logTextStyle(style, prefix: '最终');
    developer.log('=======================');

    return style;
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

  /// 检查字重是否被系统字体支持
  static bool isSupportedBySystemFont(FontWeight weight) {
    return weight.index <= FontWeight.w700.index;
  }

  /// 验证字重值是否有效的公开方法
  static bool isValidFontWeight(String weight) {
    return _isValidWeight(weight);
  }

  /// 提供字重解析和验证功能的公开方法
  static FontWeight parseAndValidateFontWeight(
      String weight, String fontFamily) {
    final parsedWeight = _parseFontWeight(weight);
    _validateFontWeightForFamily(fontFamily, parsedWeight);
    return parsedWeight;
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
    developer.log('--- 开始水平文本渲染 ---');
    developer.log('文本样式:');
    developer.log('- fontFamily: ${style.fontFamily}');
    developer.log('- fontWeight: ${style.fontWeight}');
    developer.log('- fontSize: ${style.fontSize}');
    developer.log('对齐方式: textAlign=$textAlign, verticalAlign=$verticalAlign');
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
      child: Builder(
        builder: (context) {
          developer.log('渲染最终文本:');
          developer.log('- TextStyle: ${style.toString()}');
          developer.log('- 实际字重: ${style.fontWeight}');
          developer.log('- 实际字体: ${style.fontFamily}');
          developer.log('- 实际字号: ${style.fontSize}');

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth - padding * 2, // 确保占据整个容器宽度
              child: Text(
                softWrap: true, // 允许文本换行
                overflow: TextOverflow.clip,
                text,
                style: style,
                textAlign: textAlignEnum,
                textDirection:
                    isRightToLeft ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          );
        },
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
    developer.log('--- 开始垂直文本渲染 ---');
    developer.log('文本样式:');
    developer.log('- fontFamily: ${style.fontFamily}');
    developer.log('- fontWeight: ${style.fontWeight}');
    developer.log('- fontSize: ${style.fontSize}');
    developer.log('渲染参数: textAlign=$textAlign, verticalAlign=$verticalAlign');
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

  /// 测试字重兼容性
  static void testFontWeightCompatibility(String fontFamily) {
    developer.log('===== 开始字重兼容性测试 =====');
    developer.log('测试字体: $fontFamily');

    final testWeights = [
      'w100',
      'w200',
      'w300',
      'w400',
      'w500',
      'w600',
      'w700',
      'w800',
      'w900',
      'normal',
      'bold'
    ];

    for (final weight in testWeights) {
      developer.log('\n测试字重: $weight');
      final parsedWeight = _parseFontWeight(weight);
      _validateFontWeightForFamily(fontFamily, parsedWeight);
    }

    developer.log('字重兼容性测试完成');
    developer.log('=========================');
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
                    softWrap: true, // 允许文本换行
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

    // 为每一行创建列，并记录每行的起始位置
    for (final line in lines) {
      final chars = line.characters.toList();
      int charIdx = 0;
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
                      child: Builder(
                        builder: (context) {
                          developer.log('渲染字符: $char');
                          developer.log('- 使用字重: ${style.fontWeight}');

                          return Text(
                            softWrap: true, // 允许文本换行
                            char,
                            style: style,
                            textAlign: TextAlign.center, // 确保字符居中显示
                          );
                        },
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
                      softWrap: true, // 允许文本换行
                      char,
                      style: style,
                      textAlign: TextAlign.center, // 确保字符居中显示
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

  /// 从字重字符串获取数值
  static int _getWeightValue(String weight) {
    // 标准化字重值
    String normalizedWeight = weight.toLowerCase().trim();

    // 处理特殊的字符串值
    if (normalizedWeight == 'normal') {
      return 400;
    } else if (normalizedWeight == 'bold') {
      return 700;
    }

    // 处理数值型字重格式（w100-w900）
    if (normalizedWeight.startsWith('w')) {
      // 提取数值部分
      final weightValue = int.tryParse(normalizedWeight.substring(1));
      if (weightValue != null &&
          weightValue >= 100 &&
          weightValue <= 900 &&
          weightValue % 100 == 0) {
        return weightValue;
      }
    }

    // 默认值
    return 400;
  }

  /// 验证字重值是否有效
  static bool _isValidWeight(String weight) {
    // 标准化字重值
    String normalizedWeight = weight.toLowerCase().trim();

    // 检查是否是有效的字符串值
    if (normalizedWeight == 'normal' || normalizedWeight == 'bold') {
      return true;
    }

    // 检查是否是有效的数值型字重格式（w100-w900）
    if (normalizedWeight.startsWith('w')) {
      final weightValue = int.tryParse(normalizedWeight.substring(1));
      return weightValue != null &&
          weightValue >= 100 &&
          weightValue <= 900 &&
          weightValue % 100 == 0;
    }

    return false;
  }

  /// 记录文本样式信息
  static void _logTextStyle(TextStyle style, {String prefix = ''}) {
    developer.log('$prefix文本样式信息:');
    developer.log('- 字重: ${style.fontWeight}');
    developer.log('- 字体: ${style.fontFamily}');
    developer.log('- 字号: ${style.fontSize}');
    developer.log('- 颜色: ${style.color}');
    developer.log('- 字体样式: ${style.fontStyle}');
  }

  /// 将字符串字重值转换为 FontWeight
  static FontWeight _parseFontWeight(String weight) {
    developer.log('===== 字重解析开始 =====');
    developer.log('输入字重值: $weight');

    // 标准化字重值
    String normalizedWeight = weight.toLowerCase().trim();

    try {
      // 处理特殊的字符串值
      if (normalizedWeight == 'normal') {
        developer.log('转换 normal -> w400');
        return FontWeight.w400;
      } else if (normalizedWeight == 'bold') {
        developer.log('转换 bold -> w700');
        return FontWeight.w700;
      }

      // 处理数值型字重格式（w100-w900）
      if (normalizedWeight.startsWith('w')) {
        // 提取数值部分
        final weightValue = int.tryParse(normalizedWeight.substring(1));
        if (weightValue != null &&
            weightValue >= 100 &&
            weightValue <= 900 &&
            weightValue % 100 == 0) {
          developer.log('解析数值字重: w$weightValue');
          switch (weightValue) {
            case 100:
              return FontWeight.w100;
            case 200:
              return FontWeight.w200;
            case 300:
              return FontWeight.w300;
            case 400:
              return FontWeight.w400;
            case 500:
              return FontWeight.w500;
            case 600:
              return FontWeight.w600;
            case 700:
              return FontWeight.w700;
            case 800:
              return FontWeight.w800;
            case 900:
              return FontWeight.w900;
          }
        }
      }

      // 如果字重值无效，使用默认值
      developer.log('无法识别的字重值 "$normalizedWeight"，使用默认值 w400');
      return FontWeight.w400;
    } finally {
      developer.log('字重解析完成');
      developer.log('=====================');
    }
  }

  /// 确保字体族和字重的组合有效
  static void _validateFontWeightForFamily(
      String fontFamily, FontWeight weight) {
    developer.log('===== 字体族字重验证 =====');
    developer.log('字体族: $fontFamily');
    developer.log('字重: $weight');

    // 验证字体族是否支持该字重
    bool isSourceHanFont =
        fontFamily == 'SourceHanSans' || fontFamily == 'SourceHanSerif';

    if (isSourceHanFont) {
      developer.log('使用思源字体，支持所有字重');
    } else {
      // 检查系统字体的字重支持情况
      if (weight.index > FontWeight.w700.index) {
        developer.log('警告：系统字体可能不支持 ${weight.toString()} 字重');
      } else {
        developer.log('使用系统默认字体，常见字重应该受支持');
      }
    }
    developer.log('=======================');
  }
}
