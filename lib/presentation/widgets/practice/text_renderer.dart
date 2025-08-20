// 移除过度详细的调试导入
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'property_panels/justified_text_renderer.dart';
import 'property_panels/vertical_column_justified_text.dart';
import 'text_renderer_helpers.dart';

/// 文本渲染器
/// 用于在画布和属性面板预览中统一渲染文本
class TextRenderer {
  /// 计算每列最多可容纳的字符数
  /// 在竖排模式下：lineHeight 实际上是列间距，letterSpacing 是纵向字符间距
  static int calculateMaxCharsPerColumn(double maxHeight, double charHeight,
      double lineHeight, double letterSpacing, {bool isVerticalMode = false}) {
    // 确保参数值在合理范围内，防止无限循环
    final safeCharHeight = math.max(charHeight, 1.0); // 最小字符高度1px
    final safeLetterSpacing = math.max(letterSpacing, 0.0); // 最小字符间距0px
    
    double effectiveCharHeight;
    if (isVerticalMode) {
      // 竖排模式：letterSpacing 是纵向字符间距，直接加到字符高度上
      // lineHeight 在竖排模式下是列间距，不影响单列内的字符布局
      effectiveCharHeight = safeCharHeight + safeLetterSpacing;
    } else {
      // 水平模式：使用原来的计算方式
      final safeLineHeight = math.max(lineHeight, 0.5); // 最小行高倍数0.5
      effectiveCharHeight = safeCharHeight * safeLineHeight + safeLetterSpacing;
    }
    
    // 确保有效字符高度不会太小，防止除法结果过大
    final minEffectiveHeight = math.max(effectiveCharHeight, 10.0); // 最小有效高度10px

    // 计算可容纳的最大字符数（向下取整），并限制最大值防止性能问题
    final maxChars = (maxHeight / minEffectiveHeight).floor();
    return math.min(maxChars, 1000); // 限制最大字符数为1000，防止无限循环
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
  /// 在竖排模式下，lineHeight控制列间距，letterSpacing控制纵向字符间距
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
    bool isVerticalMode = false, // 新增参数：是否为竖排模式
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
    EditPageLogger.rendererDebug('字重数值设置', 
      data: {'weightValue': weightValue});

    // 检查是否是思源字体，如果是则使用fontVariations
    bool isSourceHanFont =
        fontFamily == 'SourceHanSans' || fontFamily == 'SourceHanSerif';

    // 在竖排模式下，需要特殊处理间距参数
    double effectiveLetterSpacing;
    double effectiveLineHeight;
    
    if (isVerticalMode) {
      // 竖排模式下：不让TextStyle自动应用letterSpacing和height
      // 我们会在布局中手动控制这些间距
      effectiveLetterSpacing = 0.0; // 不传递给TextStyle
      effectiveLineHeight = 1.0; // 使用默认行高，不传递给TextStyle
    } else {
      // 水平模式下：正常传递参数
      effectiveLetterSpacing = letterSpacing;
      effectiveLineHeight = lineHeight;
    }

    // 创建样式
    TextStyle style;
    if (isSourceHanFont) {
      // 对思源字体使用fontVariations以获得更精确的字重控制
              EditPageLogger.rendererDebug('使用fontVariations设置思源字体字重', 
          data: {'weightValue': weightValue});
      style = TextStyle(
        fontSize: fontSize,
        fontFamily: fontFamily,
        // 仍然设置fontWeight以保持向后兼容性
        fontWeight: finalWeight,
        fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
        color: parsedFontColor,
        letterSpacing: effectiveLetterSpacing, // 使用调整后的值
        height: effectiveLineHeight, // 使用调整后的值
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
        letterSpacing: effectiveLetterSpacing, // 使用调整后的值
        height: effectiveLineHeight, // 使用调整后的值
        decoration: decorations.isEmpty
            ? TextDecoration.none
            : TextDecoration.combine(decorations),
      );
    }

    // 记录最终样式信息
    _logTextStyle(style, prefix: '最终');
    EditPageLogger.rendererDebug('文本样式创建完成');

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
      EditPageLogger.rendererError('解析颜色失败', error: e);
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
    EditPageLogger.rendererDebug('开始水平文本渲染', 
      data: {
        'fontFamily': style.fontFamily,
        'fontWeight': style.fontWeight.toString(),
        'fontSize': style.fontSize,
        'textAlign': textAlign,
        'verticalAlign': verticalAlign
      });
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
      EditPageLogger.rendererDebug('使用JustifiedTextRenderer渲染水平两端对齐文本');

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
          EditPageLogger.rendererDebug('渲染最终文本', 
            data: {
              'textStyle': style.toString(),
              'fontWeight': style.fontWeight.toString(),
              'fontFamily': style.fontFamily,
              'fontSize': style.fontSize
            });

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
    // 在竖排模式下，需要原始的间距值
    double? originalLetterSpacing,
    double? originalLineHeight,
  }) {
    // 添加调试日志
    EditPageLogger.rendererDebug('画布文本元素渲染', 
      data: {
        'writingMode': writingMode,
        'textAlign': textAlign,
        'verticalAlign': verticalAlign,
        'constraintsWidth': constraints.maxWidth,
        'constraintsHeight': constraints.maxHeight
      });

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
        originalLetterSpacing: originalLetterSpacing,
        originalLineHeight: originalLineHeight,
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
    // 在竖排模式下，需要原始的间距值而不是TextStyle中的值
    double? originalLetterSpacing,
    double? originalLineHeight,
  }) {
    EditPageLogger.rendererDebug('开始垂直文本渲染', 
      data: {
        'fontFamily': style.fontFamily,
        'fontWeight': style.fontWeight.toString(),
        'fontSize': style.fontSize,
        'textAlign': textAlign,
        'verticalAlign': verticalAlign,
        'writingMode': writingMode,
        'constraintsWidth': constraints.maxWidth,
        'constraintsHeight': constraints.maxHeight,
        'textLength': text.length,
        'fontStyle': style.fontStyle.toString(),
        'color': style.color.toString()
      });

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
      originalLetterSpacing: originalLetterSpacing ?? 0.0, // 传递原始字符间距
      originalLineHeight: originalLineHeight ?? 1.2, // 传递原始行高
    );

    // 在整个预览区域内应用对齐效果
    // 根据水平和垂直对齐方式决定容器的对齐方式
    // 注意：现在我们不再使用外层容器的alignment来覆盖内部对齐

    // 先处理水平对齐（现在只用于justify模式）
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

    // 删除过度详细的调试信息

    // 对于水平两端对齐，我们需要特殊处理
    if (textAlign == 'justify' && verticalAlign == 'justify') {
      // 🔧 双分佈情况：水平分佈（列之间）+ 垂直分佈（列内字符）
      // 列之间使用spaceBetween分佈，列内的字符也使用spaceBetween分佈
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        child: ClipRect(
          clipBehavior: Clip.hardEdge,
          child: contentWidget, // contentWidget中已经处理了双分佈逻辑
        ),
      );
    } else if (textAlign == 'justify') {
      // 只有水平分佈：列之间分佈，列内按verticalAlign对齐
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
      // 只有垂直分佈：列内字符分佈，列之间按textAlign对齐
      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        alignment: horizontalAlignment, // 只应用水平对齐，垂直分佈由列内处理
        child: ClipRect(clipBehavior: Clip.hardEdge, child: contentWidget),
      );
    } else {
      // 🔧 对于其他对齐方式，不应该在外层容器设置alignment，
      // 因为这会覆盖内部Column的mainAxisAlignment
      // 只有当verticalAlign不是middle、bottom、justify时才使用外层对齐
      Alignment? outerAlignment;
      if (verticalAlign == 'top') {
        // 顶部对齐时，只设置水平对齐，垂直对齐由内部处理
        switch (textAlign) {
          case 'left':
            outerAlignment = Alignment.topLeft;
            break;
          case 'center':
            outerAlignment = Alignment.topCenter;
            break;
          case 'right':
            outerAlignment = Alignment.topRight;
            break;
          default:
            outerAlignment = null; // 不设置对齐，让内部控制
        }
      } else {
        // 对于middle、bottom、justify，完全不设置外层对齐，让内部Column控制
        outerAlignment = null;
      }

      return Container(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        padding: EdgeInsets.all(padding),
        color: backgroundColor,
        alignment: outerAlignment, // 🔧 只在需要时设置外层对齐
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
    EditPageLogger.rendererDebug('字重兼容性测试', 
      data: {'fontFamily': fontFamily});

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
      final parsedWeight = _parseFontWeight(weight);
      _validateFontWeightForFamily(fontFamily, parsedWeight);
    }

    EditPageLogger.rendererDebug('字重兼容性测试完成');
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
    // 删除过度详细的调试信息

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
    required double originalLetterSpacing, // 原始字符间距
    required double originalLineHeight, // 原始行高
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
    // 使用传递进来的原始值而不是TextStyle中的值
    final effectiveLineHeight = originalLineHeight;
    final effectiveLetterSpacing = originalLetterSpacing;
    final maxCharsPerColumn = calculateMaxCharsPerColumn(
      constraints.maxHeight,
      charHeight,
      effectiveLineHeight,
      effectiveLetterSpacing,
      isVerticalMode: true, // 明确标识这是竖排模式
    );

    // 添加安全检查，防止无限循环
    if (maxCharsPerColumn <= 0) {
      // 如果计算结果无效，返回简单的错误显示
      return SizedBox(
        width: constraints.maxWidth,
        height: constraints.maxHeight,
        child: const Center(
          child: Text(
            '文本参数错误',
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // 生成所有列的数据
    final allColumns = <Widget>[];

    // 为每一行创建列，并记录每行的起始位置
    for (final line in lines) {
      final chars = line.characters.toList();
      int charIdx = 0;
      int columnCount = 0; // 添加列计数器防止无限循环
      const maxColumnsPerLine = 100; // 每行最大列数限制
      
      while (charIdx < chars.length && columnCount < maxColumnsPerLine) {
        // 计算当前列要显示多少字符
        final charsInThisColumn =
            math.min(maxCharsPerColumn, chars.length - charIdx);
            
        // 确保至少处理一个字符，防止无限循环
        final actualCharsInColumn = math.max(charsInThisColumn, 1);
        final safeEndIndex = math.min(charIdx + actualCharsInColumn, chars.length);
        final columnChars = chars.sublist(charIdx, safeEndIndex);

        // 创建当前列的Widget
        Widget columnWidget;

        // 如果是水平两端对齐（在竖排文本中对应垂直方向）
        if (textAlign == 'justify' && columnChars.length > 1) {
          // 使用固定宽度的列，确保在画布和预览区中保持一致
          final columnWidth = charHeight; // 基础列宽
          // 在竖排模式下，lineHeight 控制列间距
          final columnSpacing = (effectiveLineHeight - 1.0) * charHeight; // 列间距

          // 使用竖排文本两端对齐组件
          columnWidget = Container(
            margin: EdgeInsets.symmetric(horizontal: math.max(columnSpacing / 2, 2.0)), // 列间距
            decoration: const BoxDecoration(), // 添加decoration以支持clipBehavior
            clipBehavior: Clip.hardEdge, // 添加剪裁防止溢出
            child: VerticalColumnJustifiedText(
              characters: columnChars,
              style: style,
              maxHeight: constraints.maxHeight,
              columnWidth: columnWidth, // 使用固定宽度
              verticalAlign: verticalAlign, // 传递垂直对齐方式
              isRightToLeft: isRightToLeft,
            ),
          );
        } else {
          // 其他对齐方式使用普通容器
          // 打印调试信息
          // developer.log('创建列容器: 垂直对齐=$verticalAlign, 水平对齐=$textAlign');

          // 对于垂直对齐，我们需要完全重新设计列的布局逻辑
          // 使用固定宽度的列，确保在画布和预览区中保持一致
          final columnWidth = charHeight; // 基础列宽
          // 在竖排模式下，lineHeight 控制列间距
          final columnSpacing = (effectiveLineHeight - 1.0) * charHeight; // 列间距 = (倍数 - 1) * 字符高度

          // 根据垂直对齐方式确定Column的mainAxisAlignment
          MainAxisAlignment columnMainAxisAlignment;
          switch (verticalAlign) {
            case 'top':
              columnMainAxisAlignment = MainAxisAlignment.start;
              break;
            case 'middle':
              columnMainAxisAlignment = MainAxisAlignment.center;
              break;
            case 'bottom':
              columnMainAxisAlignment = MainAxisAlignment.end;
              break;
            case 'justify':
              // 只有多个字符时才使用spaceBetween，单字符使用center
              columnMainAxisAlignment = columnChars.length > 1 
                ? MainAxisAlignment.spaceBetween 
                : MainAxisAlignment.center;
              break;
            default:
              columnMainAxisAlignment = MainAxisAlignment.start;
          }

          // 计算字符总高度，用于判断是否需要滚动
          final characterHeight = charHeight;
          final totalCharacterSpacing = effectiveLetterSpacing * (columnChars.length - 1);
          final totalCharactersHeight = (characterHeight * columnChars.length) + totalCharacterSpacing;
          
          // 如果内容超出容器高度，使用滚动视图；否则使用固定布局
          Widget columnContent;
          if (totalCharactersHeight > constraints.maxHeight && verticalAlign != 'justify') {
            // 内容过长且非justify模式时使用滚动
            columnContent = SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start, // 滚动模式下总是从顶部开始
                children: TextRendererHelpers.buildCharacterWidgets(
                  columnChars,
                  columnWidth,
                  textAlign,
                  style,
                  effectiveLetterSpacing
                ),
              ),
            );
          } else {
            // 内容适中或justify模式时使用固定布局，能正确处理对齐
            columnContent = Column(
              mainAxisSize: MainAxisSize.max, // 🔧 使用max确保占满容器高度
              mainAxisAlignment: columnMainAxisAlignment, // 🔧 应用正确的垂直对齐
              children: verticalAlign == 'justify' && columnChars.length > 1
                ? TextRendererHelpers.buildCharacterWidgets(columnChars, columnWidth, textAlign, style, 0.0) // justify模式下不使用字符间距
                : TextRendererHelpers.buildCharacterWidgets(columnChars, columnWidth, textAlign, style, effectiveLetterSpacing),
            );
          }

          columnWidget = Container(
            width: columnWidth,
            height: constraints.maxHeight,
            margin: EdgeInsets.symmetric(horizontal: math.max(columnSpacing / 2, 2.0)), // 使用计算出的列间距
            decoration: const BoxDecoration(), // 添加decoration以支持clipBehavior
            clipBehavior: Clip.hardEdge, // 添加剪裁防止溢出
            child: columnContent,
          );
        }

        allColumns.add(columnWidget);
        charIdx += actualCharsInColumn; // 使用安全的字符数增量
        columnCount++; // 增加列计数器
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

    // 删除过度详细的布局调试信息

    // 对于水平两端对齐，我们需要特殊处理
    if (textAlign == 'justify' && columns.length > 1) {
      // 对于水平两端对齐，我们需要确保列在整个预览区域内平均分布
      // 并且首尾两排紧贴预览区边缘

      // 直接使用列，不需要Flexible包装，因为我们使用spaceBetween布局
      final wrappedColumns = columns;

      // 使用 LayoutBuilder 动态获取可用空间
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight, // 添加高度限制
            decoration: const BoxDecoration(), // 添加decoration以支持clipBehavior
            clipBehavior: Clip.hardEdge, // 添加剪裁以防止溢出
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // 使用 spaceBetween 实现两端对齐
              // 使用 MainAxisSize.max 确保 Row 占据所有可用空间
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start, // 确保列顶部对齐
              children: wrappedColumns, // 直接使用列，不需要包装
            ),
          );
        },
      );
    } else {
      // 🔧 对于其他水平对齐方式，需要根据textAlign设置正确的MainAxisAlignment
      MainAxisAlignment rowMainAxisAlignment;
      switch (textAlign) {
        case 'left':
          rowMainAxisAlignment = MainAxisAlignment.start;
          break;
        case 'center':
          rowMainAxisAlignment = MainAxisAlignment.center;
          break;
        case 'right':
          rowMainAxisAlignment = MainAxisAlignment.end;
          break;
        case 'justify':
          // 注意：这里不应该到达，因为justify在上面已经处理了
          rowMainAxisAlignment = MainAxisAlignment.spaceBetween;
          break;
        default:
          rowMainAxisAlignment = MainAxisAlignment.start;
      }

      // 计算所有列的总宽度，判断是否需要滚动
      // 获取单列宽度，包括间距（重用方法开始处的变量）
      final columnSpacing = (effectiveLineHeight - 1.0) * charHeight;
      final columnWidth = charHeight; // 基础列宽
      final totalColumnSpacing = math.max(columnSpacing, 4.0); // 每列的总宽度（包括间距）
      final totalColumnsWidth = (columnWidth + totalColumnSpacing) * columns.length;
      
      // 如果总宽度超过容器宽度，使用滚动视图；否则使用固定布局
      if (totalColumnsWidth > constraints.maxWidth) {
        // 内容过宽，需要滚动
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(), // 添加decoration以支持clipBehavior
          clipBehavior: Clip.hardEdge, // 添加剪裁防止溢出
          child: SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min, // 滚动模式下使用min
              crossAxisAlignment: CrossAxisAlignment.start, // 确保列顶部对齐
              children: columns.map((column) {
                // 确保每个列都被包装在固定高度的容器中
                return SizedBox(
                  height: constraints.maxHeight, // 限制列的最大高度
                  child: column,
                );
              }).toList(),
            ),
          ),
        );
      } else {
        // 内容适中，可以使用正确的对齐
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(), // 添加decoration以支持clipBehavior
          clipBehavior: Clip.hardEdge, // 添加剪裁防止溢出
          child: Row(
            mainAxisSize: MainAxisSize.max, // 🔧 使用max确保Row占满容器宽度
            mainAxisAlignment: rowMainAxisAlignment, // 🔧 应用正确的水平对齐
            crossAxisAlignment: CrossAxisAlignment.start, // 确保列顶部对齐
            children: columns.map((column) {
              // 确保每个列都被包装在固定高度的容器中
              return SizedBox(
                height: constraints.maxHeight, // 限制列的最大高度
                child: column,
              );
            }).toList(),
          ),
        );
      }
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
    EditPageLogger.rendererDebug('$prefix文本样式信息', 
      data: {
        'fontWeight': style.fontWeight.toString(),
        'fontFamily': style.fontFamily,
        'fontSize': style.fontSize,
        'color': style.color.toString(),
        'fontStyle': style.fontStyle.toString()
      });
  }

  /// 将字符串字重值转换为 FontWeight
  static FontWeight _parseFontWeight(String weight) {
    // 标准化字重值
    String normalizedWeight = weight.toLowerCase().trim();

    // 处理特殊的字符串值
    if (normalizedWeight == 'normal') {
      return FontWeight.w400;
    } else if (normalizedWeight == 'bold') {
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
    EditPageLogger.rendererError('无法识别的字重值，使用默认值', 
      data: {'invalidWeight': normalizedWeight, 'defaultWeight': 'w400'});
    return FontWeight.w400;
  }

  /// 确保字体族和字重的组合有效
  static void _validateFontWeightForFamily(
      String fontFamily, FontWeight weight) {
    // 验证字体族是否支持该字重
    bool isSourceHanFont =
        fontFamily == 'SourceHanSans' || fontFamily == 'SourceHanSerif';

    if (!isSourceHanFont && weight.index > FontWeight.w700.index) {
      // 检查系统字体的字重支持情况
      EditPageLogger.rendererError('系统字体可能不支持该字重', 
        data: {
          'fontFamily': fontFamily,
          'weight': weight.toString(),
          'isSourceHanFont': isSourceHanFont
        });
    }
  }
}
