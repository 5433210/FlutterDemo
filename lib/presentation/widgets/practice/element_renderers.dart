import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 元素渲染器，负责渲染不同类型的元素
class ElementRenderers {
  /// 构建集字元素
  static Widget buildCollectionElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final direction = content['direction'] as String? ?? 'horizontal';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 24.0;
    final fontColor = _parseColor(content['fontColor'] as String? ?? '#000000');
    final backgroundColor =
        _parseColor(content['backgroundColor'] as String? ?? '#FFFFFF');
    final charSpacing = (content['charSpacing'] as num?)?.toDouble() ?? 10.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8.0),
      color: backgroundColor,
      child: _buildCharacterGrid(
        content: characters,
        direction: direction,
        flowDirection: 'top-to-bottom', // Default value
        fontSize: fontSize,
        fontColor: fontColor,
        lineSpacing: lineSpacing,
        letterSpacing: charSpacing,
      ),
    );
  }

  /// 构建组合元素
  static Widget buildGroupElement(Map<String, dynamic> element,
      {bool isSelected = false}) {
    final content = element['content'] as Map<String, dynamic>;
    final List<dynamic> children = content['children'] as List<dynamic>;

    // 使用Stack来渲染所有子元素
    return Stack(
      children: [
        // 先渲染子元素
        Stack(
          clipBehavior: Clip.none,
          children: children.map<Widget>((child) {
            final String type = child['type'] as String;
            final double x = (child['x'] as num).toDouble();
            final double y = (child['y'] as num).toDouble();
            final double width = (child['width'] as num).toDouble();
            final double height = (child['height'] as num).toDouble();
            final double rotation =
                (child['rotation'] as num? ?? 0.0).toDouble();
            final double opacity = (child['opacity'] as num? ?? 1.0).toDouble();

            // 根据子元素类型渲染不同的内容
            Widget childWidget;
            switch (type) {
              case 'text':
                childWidget = buildTextElement(child);
                break;
              case 'image':
                childWidget = buildImageElement(child);
                break;
              case 'collection':
                childWidget = buildCollectionElement(child);
                break;
              case 'group':
                // 递归处理嵌套组合，并传递选中状态
                childWidget = buildGroupElement(child, isSelected: isSelected);
                break;
              default:
                childWidget = Container(
                  color: Colors.grey.withAlpha(51), // 0.2 的不透明度
                  child: Center(child: Text('未知元素类型: $type')),
                );
            }

            // 当组合被选中时，为子元素添加边框显示选中状态
            // 不再在这里添加边框，而是在Positioned中直接处理

            // 使用Positioned和Transform确保子元素在正确的位置和角度
            return Positioned(
              left: x - 1, //消除1像素边框宽度的影响
              top: y - 1, //消除1像素边框宽度的影响
              width: width,
              height: height,
              child: Transform.rotate(
                angle: rotation * (3.14159265359 / 180),
                // 添加原点参数，确保旋转以元素中心为原点
                alignment: Alignment.center,
                child: Opacity(
                  opacity: opacity,
                  // 无论组合是否被选中，都为子元素添加边框
                  child: Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      border: Border.all(
                        // 根据组合选中状态决定边框颜色
                        color: isSelected
                            ? Colors.blue.withAlpha(179) // 选中状态：蓝色边框，70% 的不透明度
                            : Colors.grey.withAlpha(179), // 默认状态：灰色边框，70% 的不透明度
                        width: 1.0,
                      ),
                    ),
                    child: childWidget,
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // 不再添加组合控件的边框，因为在 practice_edit_page.dart 中已经添加了边框
      ],
    );
  }

  /// 构建图片元素
  static Widget buildImageElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>;
    final imageUrl = content['imageUrl'] as String? ?? '';

    // 获取图片变换属性
    final flipHorizontal = content['flipHorizontal'] as bool? ?? false;
    final flipVertical = content['flipVertical'] as bool? ?? false;
    final fitMode = content['fitMode'] as String? ?? 'contain';

    // 裁剪属性
    final cropTop = (content['cropTop'] as num?)?.toDouble() ?? 0.0;
    final cropBottom = (content['cropBottom'] as num?)?.toDouble() ?? 0.0;
    final cropLeft = (content['cropLeft'] as num?)?.toDouble() ?? 0.0;
    final cropRight = (content['cropRight'] as num?)?.toDouble() ?? 0.0;

    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    // 创建裁剪区域
    EdgeInsets cropPadding = EdgeInsets.only(
      top: cropTop,
      bottom: cropBottom,
      left: cropLeft,
      right: cropRight,
    );

    // 应用裁剪和变换
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: cropPadding,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(
            flipHorizontal ? -1.0 : 1.0,
            flipVertical ? -1.0 : 1.0,
          ),
        child: Image.network(
          imageUrl,
          fit: _getFitMode(fitMode),
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              color: Colors.grey.shade200,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('加载图片失败', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 构建文本元素
  static Widget buildTextElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>? ?? {};
    final text = content['text'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final fontWeight = content['fontWeight'] as String? ?? 'normal';
    final fontStyle = content['fontStyle'] as String? ?? 'normal';
    final fontColor = _parseColor(content['fontColor'] as String? ?? '#000000');
    final backgroundColor =
        _parseColor(content['backgroundColor'] as String? ?? 'transparent');
    final textAlign =
        _parseTextAlign(content['textAlign'] as String? ?? 'left');
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 0.0;
    final lineHeight = (content['lineHeight'] as num?)?.toDouble() ?? 1.2;
    final underline = content['underline'] as bool? ?? false;
    final lineThrough = content['lineThrough'] as bool? ?? false;
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;

    // 创建文本装饰列表
    final List<TextDecoration> decorations = [];
    if (underline) decorations.add(TextDecoration.underline);
    if (lineThrough) decorations.add(TextDecoration.lineThrough);

    // 基本文本样式
    final textStyle = TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
      fontStyle: fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
      color: fontColor,
      letterSpacing: letterSpacing,
      height: lineHeight,
      decoration: decorations.isEmpty
          ? TextDecoration.none
          : TextDecoration.combine(decorations),
    );

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
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(padding),
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          Widget textWidget;

          // 根据书写方向创建适当的文本布局
          if (writingMode.startsWith('vertical')) {
            // 垂直文本（竖排）
            final isRightToLeft = writingMode == 'vertical-l';
            textWidget = _buildVerticalTextLayout(
              text: text,
              style: textStyle,
              textAlign: textAlign,
              verticalAlign: verticalAlign,
              constraints: constraints,
              isRightToLeft: isRightToLeft,
              letterSpacing: letterSpacing,
            );
          } else {
            // 水平文本
            final isRightToLeft = writingMode == 'horizontal-r';
            textWidget = _buildHorizontalTextLayout(
              text: text,
              style: textStyle,
              textAlign: textAlign,
              isRightToLeft: isRightToLeft,
            );
          }

          // 在垂直对齐为 justify 的情况下，我们使用特殊处理
          if (verticalAlign == 'justify') {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: textWidget,
            );
          } else {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              alignment: alignment,
              child: textWidget,
            );
          }
        },
      ),
    );
  }

  /// 构建集字网格
  static Widget _buildCharacterGrid({
    required String content,
    required String direction,
    required String flowDirection,
    required double fontSize,
    required Color fontColor,
    required double lineSpacing,
    required double letterSpacing,
  }) {
    if (content.isEmpty) {
      return const Center(
          child: Text('请输入汉字内容', style: TextStyle(color: Colors.grey)));
    }

    // 按照方向布局
    final isHorizontal = direction == 'horizontal';
    final characters = content.characters.toList();

    if (isHorizontal) {
      // 水平布局
      final isTopToBottom = flowDirection == 'top-to-bottom';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        verticalDirection:
            isTopToBottom ? VerticalDirection.down : VerticalDirection.up,
        children: _splitIntoChunks(characters).map((row) {
          return Padding(
            padding: EdgeInsets.only(bottom: lineSpacing),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: row.map((char) {
                return Padding(
                  padding: EdgeInsets.only(right: letterSpacing),
                  child: Text(
                    char,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: fontColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      );
    } else {
      // 垂直布局 (从右往左)
      final isTopToBottom = flowDirection == 'top-to-bottom';

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: _splitIntoChunks(characters, isVertical: true).map((column) {
          return Padding(
            padding: EdgeInsets.only(left: lineSpacing),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              verticalDirection:
                  isTopToBottom ? VerticalDirection.down : VerticalDirection.up,
              children: column.map((char) {
                return Padding(
                  padding: EdgeInsets.only(bottom: letterSpacing),
                  child: Text(
                    char,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: fontColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      );
    }
  }

  /// 构建水平文本布局
  static Widget _buildHorizontalTextLayout({
    required String text,
    required TextStyle style,
    required TextAlign textAlign,
    required bool isRightToLeft,
  }) {
    if (text.isEmpty) {
      return const Center(child: Text(''));
    }

    if (isRightToLeft) {
      // 对于从右到左的水平文本，我们需要反转每一行的字符顺序
      final lines = text.split('\n');
      final reversedLines = lines
          .map((line) => String.fromCharCodes(line.runes.toList().reversed))
          .toList();
      text = reversedLines.join('\n');
    }

    return SingleChildScrollView(
      child: Text(
        text,
        style: style,
        textAlign: textAlign,
      ),
    );
  }

  /// 构建垂直文本布局
  static Widget _buildVerticalTextLayout({
    required String text,
    required TextStyle style,
    required TextAlign textAlign,
    required String verticalAlign,
    required BoxConstraints constraints,
    required bool isRightToLeft,
    required double letterSpacing,
  }) {
    if (text.isEmpty) {
      return const Center(child: Text(''));
    }

    // 处理行和字符
    List<String> lines = text.split('\n');

    // 如果是从右到左模式，反转行顺序
    if (isRightToLeft) {
      lines = lines.reversed.toList();
    }

    // 计算每列可容纳的最大字符数
    final charHeight = style.fontSize ?? 16.0;
    final effectiveLineHeight = style.height ?? 1.2;
    final effectiveLetterSpacing = letterSpacing;
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
        final int charsInThisColumn =
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
            color: Colors.grey.withOpacity(0.3),
          ),
        );
      }
    }

    // 根据书写方向确定列的排列顺序
    final finalColumns =
        isRightToLeft ? allColumns.reversed.toList() : allColumns;

    // 返回包含所有列的水平滚动视图
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: _getRowCrossAlignment(verticalAlign),
        children: finalColumns,
      ),
    );
  }

  /// 计算每列最多可容纳的字符数
  static int _calculateMaxCharsPerColumn(double maxHeight, double charHeight,
      double lineHeight, double letterSpacing) {
    // 计算单个字符的有效高度（包括行高和字间距）
    final effectiveCharHeight = charHeight * lineHeight + letterSpacing;

    // 计算可容纳的最大字符数（向下取整）
    return (maxHeight / effectiveCharHeight).floor();
  }

  /// 获取行间书写方向的变换矩阵
  static Matrix4 _getBlockDirectionTransform(String direction) {
    switch (direction) {
      case 'right-to-left':
        return Matrix4.identity()..scale(-1.0, 1.0, 1.0);
      case 'top-to-bottom':
        return Matrix4.identity(); // 默认不变
      case 'bottom-to-top':
        return Matrix4.identity()..scale(1.0, -1.0, 1.0);
      default:
        return Matrix4.identity();
    }
  }

  /// 获取图片适应模式
  static BoxFit _getFitMode(String fitMode) {
    switch (fitMode) {
      case 'contain':
        return BoxFit.contain;
      case 'cover':
        return BoxFit.cover;
      case 'fill':
        return BoxFit.fill;
      case 'none':
        return BoxFit.none;
      default:
        return BoxFit.contain;
    }
  }

  /// 获取垂直文本的水平主轴对齐方式
  static MainAxisAlignment _getHorizontalMainAlignment(
      TextAlign textAlign, bool isRightToLeft) {
    if (isRightToLeft) {
      // 对于从右到左的竖排文本
      switch (textAlign) {
        case TextAlign.left:
          return MainAxisAlignment.end;
        case TextAlign.right:
          return MainAxisAlignment.start;
        case TextAlign.center:
        case TextAlign.justify:
          return MainAxisAlignment.center;
        default:
          return MainAxisAlignment.end;
      }
    } else {
      // 对于从左到右的竖排文本
      switch (textAlign) {
        case TextAlign.left:
          return MainAxisAlignment.start;
        case TextAlign.right:
          return MainAxisAlignment.end;
        case TextAlign.center:
        case TextAlign.justify:
          return MainAxisAlignment.center;
        default:
          return MainAxisAlignment.start;
      }
    }
  }

  /// 获取行内书写方向的旋转
  static int _getRotationQuarterTurns(String direction) {
    switch (direction) {
      case 'vertical-rl': // 从右向左
        return 3; // 顺时针旋转270度（或逆时针90度）
      case 'vertical-lr': // 从左向右(竖排)
        return 1; // 顺时针旋转90度
      case 'sideways-rl': // 从下到上
        return 2; // 旋转180度
      default:
        return 0; // 水平方向，不旋转
    }
  }

  /// 获取行的交叉轴对齐方式 (用于垂直文本中的行对齐)
  static CrossAxisAlignment _getRowCrossAlignment(String verticalAlign) {
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
  static Alignment _getVerticalAlignment(String verticalAlign) {
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

  /// 获取垂直文本的交叉轴对齐方式
  static CrossAxisAlignment _getVerticalCrossAlignment(
      TextAlign textAlign, bool isRightToLeft) {
    // 在垂直文本中，交叉轴控制字符在列中的对齐
    switch (textAlign) {
      case TextAlign.center:
        return CrossAxisAlignment.center;
      case TextAlign.right:
        // 根据书写方向翻转左右对齐
        return isRightToLeft
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end;
      case TextAlign.left:
        // 根据书写方向翻转左右对齐
        return isRightToLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start;
      case TextAlign.justify:
        return CrossAxisAlignment.center; // Justify handled separately
      default:
        return CrossAxisAlignment.center;
    }
  }

  /// 获取垂直方向主轴对齐方式
  static MainAxisAlignment _getVerticalMainAlignment(TextAlign textAlign) {
    switch (textAlign) {
      case TextAlign.left: // 在垂直模式中对应顶部对齐
        return MainAxisAlignment.start;
      case TextAlign.center:
        return MainAxisAlignment.center;
      case TextAlign.right: // 在垂直模式中对应底部对齐
        return MainAxisAlignment.end;
      case TextAlign.justify:
        return MainAxisAlignment.spaceBetween;
      default:
        return MainAxisAlignment.start;
    }
  }

  /// 解析颜色字符串
  static Color _parseColor(String colorStr) {
    if (colorStr == 'transparent') return Colors.transparent;

    try {
      final buffer = StringBuffer();
      if (colorStr.startsWith('#')) {
        if (colorStr.length == 7) {
          // #RRGGBB format
          buffer.write('ff'); // Add full opacity
          buffer.write(colorStr.substring(1));
        } else if (colorStr.length == 9) {
          // #AARRGGBB format
          buffer.write(colorStr.substring(1));
        } else {
          return Colors.black; // Invalid format
        }
      } else {
        buffer.write('ff'); // Default full opacity
        buffer.write(colorStr);
      }
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  /// 解析文本对齐方式
  static TextAlign _parseTextAlign(String align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      case 'left':
      default:
        return TextAlign.left;
    }
  }

  /// 将字符列表分割成多行
  static List<List<String>> _splitIntoChunks(List<String> items,
      {bool isVertical = false}) {
    if (items.isEmpty) return [];

    // 简单实现：每行/列固定数量的字符，可以根据实际需求优化
    final chunkSize = isVertical ? 10 : 20;

    // 创建分组
    final List<List<String>> chunks = [];
    for (var i = 0; i < items.length; i += chunkSize) {
      final end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
      chunks.add(items.sublist(i, end));
    }

    return chunks;
  }
}
