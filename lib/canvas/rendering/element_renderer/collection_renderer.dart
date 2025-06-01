// filepath: lib/canvas/rendering/element_renderer/collection_renderer.dart

import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';

/// 新的集字元素渲染器
/// 替换有问题的collection_element_renderer.dart，提供清洁的实现
class CollectionRenderer extends CustomPainter {
  final ElementData elementData;
  final Map<String, dynamic> renderingOptions;

  CollectionRenderer({
    required this.elementData,
    Map<String, dynamic>? options,
  }) : renderingOptions = options ?? {};

  @override
  void paint(Canvas canvas, Size size) {
    final properties = elementData.properties;

    // 获取集字内容
    final characters = properties['characters'] as String? ?? '';
    if (characters.isEmpty) {
      _drawPlaceholder(canvas, size);
      return;
    }

    // 获取渲染参数
    final fontSize = properties['fontSize'] as double? ?? 16.0;
    final fontColor = properties['fontColor'] as String? ?? '#000000';
    final writingMode = properties['writingMode'] as String? ?? 'horizontal-l';
    final letterSpacing = properties['letterSpacing'] as double? ?? 0.0;
    final lineSpacing = properties['lineSpacing'] as double? ?? 0.0;
    final textAlign = properties['textAlign'] as String? ?? 'left';
    final verticalAlign = properties['verticalAlign'] as String? ?? 'top';

    // 渲染集字内容
    _renderCollection(
      canvas,
      size,
      characters,
      fontSize,
      fontColor,
      writingMode,
      letterSpacing,
      lineSpacing,
      textAlign,
      verticalAlign,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    if (oldDelegate is! CollectionRenderer) return true;
    return elementData != oldDelegate.elementData ||
        renderingOptions != oldDelegate.renderingOptions;
  }
  void _drawPlaceholder(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '请输入汉字内容',
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  TextAlign _getTextAlign(String align) {
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

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        final hex = colorStr.substring(1);
        if (hex.length == 6) {
          return Color(int.parse('FF$hex', radix: 16));
        } else if (hex.length == 8) {
          return Color(int.parse(hex, radix: 16));
        }
      }
    } catch (e) {
      // 解析失败时返回黑色
    }
    return Colors.black;
  }

  void _renderCollection(
    Canvas canvas,
    Size size,
    String characters,
    double fontSize,
    String fontColor,
    String writingMode,
    double letterSpacing,
    double lineSpacing,
    String textAlign,
    String verticalAlign,
  ) {
    // 解析颜色
    final color = _parseColor(fontColor);

    // 创建文本样式
    final textStyle = TextStyle(
      fontSize: fontSize,
      color: color,
      letterSpacing: letterSpacing,
      height: 1.0 + (lineSpacing / fontSize),
    );

    // 判断书写方向
    final isHorizontal = writingMode.startsWith('horizontal');

    if (isHorizontal) {
      _renderHorizontalText(
          canvas, size, characters, textStyle, textAlign, verticalAlign);
    } else {
      _renderVerticalText(
          canvas, size, characters, textStyle, textAlign, verticalAlign);
    }
  }

  void _renderHorizontalText(
    Canvas canvas,
    Size size,
    String characters,
    TextStyle textStyle,
    String textAlign,
    String verticalAlign,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: characters, style: textStyle),
      textDirection: TextDirection.ltr,
      textAlign: _getTextAlign(textAlign),
    );

    textPainter.layout(maxWidth: size.width);

    // 计算垂直位置
    double y;
    switch (verticalAlign) {
      case 'middle':
        y = (size.height - textPainter.height) / 2;
        break;
      case 'bottom':
        y = size.height - textPainter.height;
        break;
      default: // top
        y = 0;
        break;
    }

    textPainter.paint(canvas, Offset(0, y));
  }

  void _renderVerticalText(
    Canvas canvas,
    Size size,
    String characters,
    TextStyle textStyle,
    String textAlign,
    String verticalAlign,
  ) {
    // 简化的垂直文本渲染
    final charList = characters.characters.toList();
    double x = size.width / 2;
    double y = 0;

    for (final char in charList) {
      final textPainter = TextPainter(
        text: TextSpan(text: char, style: textStyle),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y));
      y += textStyle.fontSize! + (textStyle.height! - 1) * textStyle.fontSize!;
    }
  }
}
