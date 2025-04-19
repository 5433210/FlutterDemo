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
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8.0),
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
  static Widget buildGroupElement(Map<String, dynamic> element) {
    // 组合元素需要处理子元素的渲染，这里简化为显示一个组合标识
    return Container(
      color: Colors.transparent,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: const Text(
        '组合元素',
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  /// 构建图片元素
  static Widget buildImageElement(Map<String, dynamic> element) {
    final content = element['content'] as Map<String, dynamic>;
    final imageUrl = content['imageUrl'] as String? ?? '';

    if (imageUrl.isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
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
          color: Colors.grey.shade200,
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.center,
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
      color: backgroundColor,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
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
