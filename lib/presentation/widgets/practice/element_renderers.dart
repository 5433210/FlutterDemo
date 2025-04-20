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

    if (imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 48, color: Colors.grey),
      );
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
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
    );
  }

  /// 构建文本元素
  static Widget buildTextElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>;
    final text = content['text'] as String? ?? '';
    final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 16.0;
    final fontFamily = content['fontFamily'] as String? ?? 'sans-serif';
    final fontColor = _parseColor(content['textColor'] as String? ?? '#000000');
    final backgroundColor =
        _parseColor(content['backgroundColor'] as String? ?? 'transparent');
    final textAlign =
        _parseTextAlign(content['alignment'] as String? ?? 'left');

    return Container(
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      color: backgroundColor,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          color: fontColor,
        ),
        textAlign: textAlign,
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

  /// 解析颜色字符串
  static Color _parseColor(String colorStr) {
    if (colorStr == 'transparent') return Colors.transparent;

    try {
      final buffer = StringBuffer();
      if (colorStr.length == 6 || colorStr.length == 7) buffer.write('ff');
      buffer.write(colorStr.replaceFirst('#', ''));
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
