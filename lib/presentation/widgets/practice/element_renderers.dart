import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:demo/presentation/widgets/practice/text_renderer.dart';
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

  /// 构建裁剪后的本地文件图像 - 这个方法现在已不再需要
  static Widget _buildCroppedFileImage(
    File file,
    BoxFit fit,
    double rectX,
    double rectY,
    double rectWidth,
    double rectHeight,
    double containerWidth,
    double containerHeight,
  ) {
    // 此方法已不再使用
    return Container(
      width: rectWidth,
      height: rectHeight,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('图像处理方法已更新', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  /// 构建裁剪后的图像 - 这个方法现在已不再需要，因为变换已在应用变换时处理完毕
  static Widget _buildCroppedImage({
    required Map<String, dynamic> croppedImageInfo,
    required String fitMode,
    required double width,
    required double height,
    required double containerWidth,
    required double containerHeight,
  }) {
    // 此方法已不再使用，但保留方法签名以防止编译错误
    // 实际的图像变换已经在用户点击"应用变换"按钮时处理，
    // 并将结果保存在content['transformedImageUrl']中

    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('图像处理方法已更新', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  /// 构建裁剪后的网络图像 - 这个方法现在已不再需要
  static Widget _buildCroppedNetworkImage(
    String imageUrl,
    BoxFit fit,
    double rectX,
    double rectY,
    double rectWidth,
    double rectHeight,
    double containerWidth,
    double containerHeight,
  ) {
    // 此方法已不再使用
    return Container(
      width: rectWidth,
      height: rectHeight,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('图像处理方法已更新', style: TextStyle(color: Colors.grey)),
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
