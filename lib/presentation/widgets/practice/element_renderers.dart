import 'package:flutter/material.dart';

/// 元素渲染器类
/// 包含所有元素渲染相关的方法
class ElementRenderers {
  /// 构建集字元素
  static Widget buildCollectionElement(Map<String, dynamic> element) {
    final characters = element['characters'] as String? ?? '';
    final direction = element['direction'] as String? ?? 'horizontal';
    final spacing = (element['spacing'] as num?)?.toDouble() ?? 10.0;

    return Container(
      padding: const EdgeInsets.all(4),
      child: Wrap(
        direction: direction == 'vertical' ? Axis.vertical : Axis.horizontal,
        spacing: spacing,
        runSpacing: spacing,
        children: characters.split('').map((char) {
          return Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.grey.withAlpha(128)), // 0.5 * 255 = 128
            ),
            child: Center(
              child: Text(
                char,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 构建组合内的子元素
  static Widget buildGroupChildElement(Map<String, dynamic> element) {
    final type = element['type'] as String? ?? '';
    final x = (element['relativeX'] as num?)?.toDouble() ?? 0.0;
    final y = (element['relativeY'] as num?)?.toDouble() ?? 0.0;
    final width = (element['width'] as num?)?.toDouble() ?? 50.0;
    final height = (element['height'] as num?)?.toDouble() ?? 50.0;
    final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;

    Widget content;

    switch (type) {
      case 'text':
        content = buildTextElement(element);
        break;
      case 'image':
        content = buildImageElement(element);
        break;
      case 'collection':
        content = buildCollectionElement(element);
        break;
      default:
        content = Container(
          color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
          child: const Center(child: Text('未知元素')),
        );
    }

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: rotation * 3.1415926 / 180,
        child: SizedBox(
          width: width,
          height: height,
          child: content,
        ),
      ),
    );
  }

  /// 构建组合元素
  static Widget buildGroupElement(Map<String, dynamic> element) {
    final children = element['children'] as List<dynamic>? ?? [];

    return Stack(
      children: [
        for (var child in children)
          buildGroupChildElement(child as Map<String, dynamic>),
      ],
    );
  }

  /// 构建图片元素
  static Widget buildImageElement(Map<String, dynamic> element) {
    final imageUrl = element['imageUrl'] as String? ?? '';
    final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

    return Opacity(
      opacity: opacity,
      child: imageUrl.isNotEmpty
          ? Image.network(imageUrl, fit: BoxFit.contain)
          : Container(
              color: Colors.grey.withAlpha(51), // 0.2 * 255 = 51
              child: const Center(child: Icon(Icons.image)),
            ),
    );
  }

  /// 构建文本元素
  static Widget buildTextElement(Map<String, dynamic> element) {
    final text = element['text'] as String? ?? '';
    final fontSize = (element['fontSize'] as num?)?.toDouble() ?? 14.0;
    final fontColor = element['fontColor'] as String? ?? '#000000';
    final textAlign = getTextAlign(element['textAlign'] as String? ?? 'left');

    return Container(
      padding: const EdgeInsets.all(4),
      color: Colors.transparent,
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          color:
              Color(int.parse(fontColor.substring(1), radix: 16) + 0xFF000000),
        ),
        textAlign: textAlign,
      ),
    );
  }

  /// 获取文本对齐方式
  static TextAlign getTextAlign(String align) {
    switch (align) {
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
}
