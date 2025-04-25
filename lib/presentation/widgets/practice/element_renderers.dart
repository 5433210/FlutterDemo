import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:demo/presentation/widgets/practice/text_renderer.dart';
import 'package:flutter/material.dart';

/// 元素渲染器，负责渲染不同类型的元素
class ElementRenderers {
  /// 构建集字元素
  static Widget buildCollectionElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>;
    final characters = content['characters'] as String? ?? '';
    final writingMode = content['writingMode'] as String? ?? 'horizontal-l';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 24.0;
    final backgroundColor =
        _parseColor(content['backgroundColor'] as String? ?? '#FFFFFF');
    final letterSpacing = (content['letterSpacing'] as num?)?.toDouble() ?? 5.0;
    final lineSpacing = (content['lineSpacing'] as num?)?.toDouble() ?? 10.0;
    final padding = (content['padding'] as num?)?.toDouble() ?? 0.0;
    final textAlign = content['textAlign'] as String? ?? 'left';
    final verticalAlign = content['verticalAlign'] as String? ?? 'top';

    // 获取集字图片列表（实际应用中应该从数据库或其他存储中获取）
    final characterImages = content['characterImages'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: EdgeInsets.all(padding),
            child: _buildCollectionLayout(
              characters: characters,
              writingMode: writingMode,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              lineSpacing: lineSpacing,
              textAlign: textAlign,
              verticalAlign: verticalAlign,
              characterImages: characterImages,
              constraints: constraints,
              padding: padding,
            ),
          );
        },
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
    final transformedImageUrl = content['transformedImageUrl'] as String?;
    final fitMode = content['fitMode'] as String? ?? 'contain';
    final backgroundColor = content['backgroundColor'] as String?;

    // 新增支持：直接存储图像数据
    final String? base64ImageData = content['base64ImageData'] as String?;
    final Uint8List? rawImageData = content['rawImageData'] as Uint8List?;

    // 处理transformedImageData，可能是Uint8List或List<int>
    Uint8List? transformedImageData;
    final dynamic rawTransformedData = content['transformedImageData'];
    if (rawTransformedData is Uint8List) {
      transformedImageData = rawTransformedData;
    } else if (rawTransformedData is List<int>) {
      transformedImageData = Uint8List.fromList(rawTransformedData);
    }

    // 解析背景颜色
    Color? bgColor;
    if (backgroundColor != null && backgroundColor.isNotEmpty) {
      try {
        // 处理带#前缀的颜色代码
        final colorStr = backgroundColor.startsWith('#')
            ? backgroundColor.substring(1)
            : backgroundColor;

        // 添加FF前缀表示完全不透明
        final fullColorStr = colorStr.length == 6 ? 'FF$colorStr' : colorStr;

        // 解析颜色
        bgColor = Color(int.parse(fullColorStr, radix: 16));
      } catch (e) {
        debugPrint('解析背景颜色失败: $e');
      }
    }

    // 如果图片URL为空且没有图像数据，显示占位符
    if (imageUrl.isEmpty &&
        base64ImageData == null &&
        rawImageData == null &&
        transformedImageData == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        color: bgColor ?? Colors.grey.shade200,
        child: const Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    // 优先级：转换后的图像数据 > 转换后的图像URL > 原始图像数据（base64或raw）> 原始图像URL
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: bgColor, // 应用背景颜色
      child: _buildImageWidget(
        imageUrl: transformedImageUrl ?? imageUrl,
        fitMode: fitMode,
        transformedImageData: transformedImageData,
        base64ImageData: base64ImageData,
        rawImageData: rawImageData,
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
    final fontColorStr = content['fontColor'] as String? ?? '#000000';
    final backgroundColorStr =
        content['backgroundColor'] as String? ?? 'transparent';
    final textAlignStr = content['textAlign'] as String? ?? 'left';
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

    // 解析颜色
    final fontColor = _parseColor(fontColorStr);
    final backgroundColor = _parseColor(backgroundColorStr);

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

    // 使用 LayoutBuilder 获取容器约束
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用与文本属性面板预览区完全相同的容器结构
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Container(
            alignment: Alignment.topRight, // 与面板预览区保持一致
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(color: Colors.grey), // 与面板预览区保持一致
              borderRadius: BorderRadius.circular(4.0), // 与面板预览区保持一致
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: writingMode.startsWith('vertical')
                  ? TextRenderer.renderVerticalText(
                      text: text,
                      style: textStyle,
                      textAlign: textAlignStr,
                      verticalAlign: verticalAlign,
                      writingMode: writingMode,
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - padding * 2,
                        maxHeight: constraints.maxHeight - padding * 2,
                      ),
                      backgroundColor: Colors.transparent, // 已经在外层容器中设置了背景色
                    )
                  : TextRenderer.renderHorizontalText(
                      text: text,
                      style: textStyle,
                      textAlign: textAlignStr,
                      verticalAlign: verticalAlign,
                      writingMode: writingMode,
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth - padding * 2,
                        maxHeight: constraints.maxHeight - padding * 2,
                      ),
                      backgroundColor: Colors.transparent, // 已经在外层容器中设置了背景色
                    ),
            ),
          ),
        );
      },
    );
  }

  /// 构建集字布局
  static Widget _buildCollectionLayout({
    required String characters,
    required String writingMode,
    required double fontSize,
    required double letterSpacing,
    required double lineSpacing,
    required String textAlign,
    required String verticalAlign,
    required List<dynamic> characterImages,
    required BoxConstraints constraints,
    required double padding,
  }) {
    if (characters.isEmpty) {
      return const Center(
          child: Text('请输入汉字内容', style: TextStyle(color: Colors.grey)));
    }

    // 获取可用区域大小
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;

    // 字符列表
    final charList = characters.characters.toList();

    // 确定布局方向
    final isHorizontal = writingMode.startsWith('horizontal');
    final isLeftToRight = writingMode.endsWith('l');

    // 计算每个字符的位置
    final List<_CharacterPosition> positions = _calculateCharacterPositions(
      charList: charList,
      isHorizontal: isHorizontal,
      isLeftToRight: isLeftToRight,
      fontSize: fontSize,
      letterSpacing: letterSpacing,
      lineSpacing: lineSpacing,
      textAlign: textAlign,
      verticalAlign: verticalAlign,
      availableWidth: availableWidth,
      availableHeight: availableHeight,
    );

    // 创建自定义绘制器
    return CustomPaint(
      size: Size(availableWidth, availableHeight),
      painter: _CollectionPainter(
        characters: charList,
        positions: positions,
        fontSize: fontSize,
        characterImages: characterImages,
      ),
    );
  }

  /// 构建图像加载错误的占位Widget
  static Widget _buildImageErrorWidget(String errorMessage) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(errorMessage, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// 构建图片小部件，根据数据类型选择不同的加载方式
  static Widget _buildImageWidget({
    required String imageUrl,
    required String fitMode,
    Uint8List? transformedImageData,
    Uint8List? rawImageData,
    String? base64ImageData,
  }) {
    final BoxFit fit = _getFitMode(fitMode);

    // 优先使用转换后的图像数据
    if (transformedImageData != null) {
      return Image.memory(
        transformedImageData,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载内存图片数据失败: $error');
          return _buildImageErrorWidget('加载内存图片数据失败');
        },
      );
    }

    // 其次使用原始图像数据（raw形式）
    if (rawImageData != null) {
      return Image.memory(
        rawImageData,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载原始图片数据失败: $error');
          return _buildImageErrorWidget('加载原始图片数据失败');
        },
      );
    }

    // 再次使用Base64编码的图像数据
    if (base64ImageData != null && base64ImageData.isNotEmpty) {
      try {
        // 解码Base64数据为二进制
        final Uint8List decodedBytes = base64Decode(base64ImageData);
        return Image.memory(
          decodedBytes,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('解码Base64图片数据失败: $error');
            return _buildImageErrorWidget('解码Base64图片数据失败');
          },
        );
      } catch (e) {
        debugPrint('Base64解码错误: $e');
        return _buildImageErrorWidget('Base64图片数据格式错误');
      }
    }

    // 最后使用URL（文件或网络）
    if (imageUrl.isEmpty) {
      return _buildImageErrorWidget('没有可用的图像数据');
    }

    // 检查是否是本地文件路径
    if (imageUrl.startsWith('file://')) {
      // 提取文件路径（去掉file://前缀）
      final filePath = imageUrl.substring(7);

      // 使用File.image加载本地文件
      return Image.file(
        File(filePath),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('加载本地图片失败: $error');
          return _buildImageErrorWidget('加载本地图片失败');
        },
      );
    } else {
      // 使用网络图片加载
      return Image.network(
        imageUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget('加载网络图片失败');
        },
      );
    }
  }

  /// 计算字符位置
  static List<_CharacterPosition> _calculateCharacterPositions({
    required List<String> charList,
    required bool isHorizontal,
    required bool isLeftToRight,
    required double fontSize,
    required double letterSpacing,
    required double lineSpacing,
    required String textAlign,
    required String verticalAlign,
    required double availableWidth,
    required double availableHeight,
  }) {
    final List<_CharacterPosition> positions = [];

    if (charList.isEmpty) return positions;

    // 字符尺寸（假设是正方形）
    final charSize = fontSize;

    if (isHorizontal) {
      // 水平布局

      // 计算每行可容纳的字符数
      final charsPerRow =
          ((availableWidth + letterSpacing) / (charSize + letterSpacing))
              .floor();
      if (charsPerRow <= 0) return positions;

      // 计算行数
      final rowCount = (charList.length / charsPerRow).ceil();

      // 计算实际使用的高度
      final usedHeight = min(
          availableHeight, rowCount * charSize + (rowCount - 1) * lineSpacing);

      // 计算起始位置（考虑对齐方式）
      double startY = 0;
      switch (verticalAlign) {
        case 'top':
          startY = 0;
          break;
        case 'middle':
          startY = (availableHeight - usedHeight) / 2;
          break;
        case 'bottom':
          startY = availableHeight - usedHeight;
          break;
        case 'justify':
          // 如果行数大于1，则均匀分布
          if (rowCount > 1) {
            lineSpacing =
                (availableHeight - rowCount * charSize) / (rowCount - 1);
          }
          startY = 0;
          break;
      }

      // 遍历每个字符，计算位置
      for (int i = 0; i < charList.length; i++) {
        final rowIndex = i ~/ charsPerRow;
        final colIndex = i % charsPerRow;

        // 计算行的起始X位置（考虑水平对齐）
        final charsInThisRow = (rowIndex == rowCount - 1)
            ? (charList.length - rowIndex * charsPerRow)
            : charsPerRow;
        final rowWidth =
            charsInThisRow * charSize + (charsInThisRow - 1) * letterSpacing;

        double startX = 0;
        switch (textAlign) {
          case 'left':
            startX = isLeftToRight ? 0 : availableWidth - rowWidth;
            break;
          case 'center':
            startX = (availableWidth - rowWidth) / 2;
            break;
          case 'right':
            startX = isLeftToRight ? availableWidth - rowWidth : 0;
            break;
          case 'justify':
            // 如果字符数大于1，则均匀分布
            if (charsInThisRow > 1 && charsInThisRow < charsPerRow) {
              final justifiedLetterSpacing =
                  (availableWidth - charsInThisRow * charSize) /
                      (charsInThisRow - 1);
              startX = 0;

              // 为这一行的每个字符重新计算位置
              for (int j = 0; j < charsInThisRow; j++) {
                final index = rowIndex * charsPerRow + j;
                final x = isLeftToRight
                    ? startX + j * (charSize + justifiedLetterSpacing)
                    : availableWidth -
                        startX -
                        (j + 1) * charSize -
                        j * justifiedLetterSpacing;
                final y = startY + rowIndex * (charSize + lineSpacing);

                if (index < charList.length) {
                  positions.add(_CharacterPosition(
                    char: charList[index],
                    x: x,
                    y: y,
                    size: charSize,
                  ));
                }
              }

              // 跳过这一行的常规处理
              continue;
            } else {
              startX = isLeftToRight ? 0 : availableWidth - rowWidth;
            }
            break;
        }

        // 计算字符位置
        if (textAlign != 'justify' ||
            charsInThisRow == charsPerRow ||
            charsInThisRow == 1) {
          final x = isLeftToRight
              ? startX + colIndex * (charSize + letterSpacing)
              : startX +
                  (charsInThisRow - colIndex - 1) * (charSize + letterSpacing);
          final y = startY + rowIndex * (charSize + lineSpacing);

          positions.add(_CharacterPosition(
            char: charList[i],
            x: x,
            y: y,
            size: charSize,
          ));
        }
      }
    } else {
      // 垂直布局

      // 计算每列可容纳的字符数
      final charsPerCol =
          ((availableHeight + letterSpacing) / (charSize + letterSpacing))
              .floor();
      if (charsPerCol <= 0) return positions;

      // 计算列数
      final colCount = (charList.length / charsPerCol).ceil();

      // 计算实际使用的宽度
      final usedWidth = min(
          availableWidth, colCount * charSize + (colCount - 1) * lineSpacing);

      // 计算起始位置（考虑对齐方式）
      double startX = 0;
      switch (textAlign) {
        case 'left':
          startX = isLeftToRight ? 0 : availableWidth - usedWidth;
          break;
        case 'center':
          startX = (availableWidth - usedWidth) / 2;
          break;
        case 'right':
          startX = isLeftToRight ? availableWidth - usedWidth : 0;
          break;
        case 'justify':
          // 如果列数大于1，则均匀分布
          if (colCount > 1) {
            lineSpacing =
                (availableWidth - colCount * charSize) / (colCount - 1);
          }
          startX = 0;
          break;
      }

      // 遍历每个字符，计算位置
      for (int i = 0; i < charList.length; i++) {
        final colIndex = i ~/ charsPerCol;
        final rowIndex = i % charsPerCol;

        // 计算列的起始Y位置（考虑垂直对齐）
        final charsInThisCol = (colIndex == colCount - 1)
            ? (charList.length - colIndex * charsPerCol)
            : charsPerCol;
        final colHeight =
            charsInThisCol * charSize + (charsInThisCol - 1) * letterSpacing;

        double startY = 0;
        switch (verticalAlign) {
          case 'top':
            startY = isLeftToRight ? 0 : availableHeight - colHeight;
            break;
          case 'middle':
            startY = (availableHeight - colHeight) / 2;
            break;
          case 'bottom':
            startY = isLeftToRight ? availableHeight - colHeight : 0;
            break;
          case 'justify':
            // 如果字符数大于1，则均匀分布
            if (charsInThisCol > 1 && charsInThisCol < charsPerCol) {
              final justifiedLetterSpacing =
                  (availableHeight - charsInThisCol * charSize) /
                      (charsInThisCol - 1);
              startY = 0;

              // 为这一列的每个字符重新计算位置
              for (int j = 0; j < charsInThisCol; j++) {
                final index = colIndex * charsPerCol + j;
                final x = startX + colIndex * (charSize + lineSpacing);
                final y = isLeftToRight
                    ? startY + j * (charSize + justifiedLetterSpacing)
                    : availableHeight -
                        startY -
                        (j + 1) * charSize -
                        j * justifiedLetterSpacing;

                if (index < charList.length) {
                  positions.add(_CharacterPosition(
                    char: charList[index],
                    x: x,
                    y: y,
                    size: charSize,
                  ));
                }
              }

              // 跳过这一列的常规处理
              continue;
            } else {
              startY = isLeftToRight ? 0 : availableHeight - colHeight;
            }
            break;
        }

        // 计算字符位置
        if (verticalAlign != 'justify' ||
            charsInThisCol == charsPerCol ||
            charsInThisCol == 1) {
          final x = startX + colIndex * (charSize + lineSpacing);
          final y = isLeftToRight
              ? startY + rowIndex * (charSize + letterSpacing)
              : startY +
                  (charsInThisCol - rowIndex - 1) * (charSize + letterSpacing);

          positions.add(_CharacterPosition(
            char: charList[i],
            x: x,
            y: y,
            size: charSize,
          ));
        }
      }
    }

    return positions;
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
}

/// 字符位置类
class _CharacterPosition {
  final String char;
  final double x;
  final double y;
  final double size;

  _CharacterPosition({
    required this.char,
    required this.x,
    required this.y,
    required this.size,
  });
}

/// 集字绘制器
class _CollectionPainter extends CustomPainter {
  final List<String> characters;
  final List<_CharacterPosition> positions;
  final double fontSize;
  final List<dynamic> characterImages;

  _CollectionPainter({
    required this.characters,
    required this.positions,
    required this.fontSize,
    required this.characterImages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 绘制每个字符
    for (final position in positions) {
      // 查找字符对应的图片
      final charImage = _findCharacterImage(position.char);

      if (charImage != null) {
        // 绘制图片
        _drawCharacterImage(canvas, position, charImage);
      } else {
        // 找不到图片，绘制文本作为占位符
        _drawCharacterText(canvas, position);
      }
    }
  }

  @override
  bool shouldRepaint(_CollectionPainter oldDelegate) {
    return oldDelegate.characters != characters ||
        oldDelegate.positions != positions ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.characterImages != characterImages;
  }

  /// 绘制字符图片
  void _drawCharacterImage(
      Canvas canvas, _CharacterPosition position, dynamic charImage) {
    // 获取图片数据 (实际应用中应该使用这些数据来加载图片)

    // 创建绘制区域
    final rect = Rect.fromLTWH(
      position.x,
      position.y,
      position.size,
      position.size,
    );

    // 绘制占位符
    final paint = Paint()
      ..color = Colors.grey.withAlpha(77) // 约等于 0.3 不透明度
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    // 绘制字符文本作为占位符
    final textPainter = TextPainter(
      text: TextSpan(
        text: position.char,
        style: TextStyle(
          fontSize: position.size * 0.7,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.x + (position.size - textPainter.width) / 2,
        position.y + (position.size - textPainter.height) / 2,
      ),
    );
  }

  /// 绘制字符文本
  void _drawCharacterText(Canvas canvas, _CharacterPosition position) {
    // 创建绘制区域
    final rect = Rect.fromLTWH(
      position.x,
      position.y,
      position.size,
      position.size,
    );

    // 绘制占位符背景
    final paint = Paint()
      ..color = Colors.grey.withAlpha(26) // 约等于 0.1 不透明度
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, paint);

    // 绘制字符文本
    final textPainter = TextPainter(
      text: TextSpan(
        text: position.char,
        style: TextStyle(
          fontSize: position.size * 0.7,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.x + (position.size - textPainter.width) / 2,
        position.y + (position.size - textPainter.height) / 2,
      ),
    );
  }

  /// 查找字符对应的图片
  dynamic _findCharacterImage(String char) {
    // 在characterImages中查找对应字符的图片
    for (final image in characterImages) {
      if (image['character'] == char) {
        return image;
      }
    }
    return null;
  }
}
