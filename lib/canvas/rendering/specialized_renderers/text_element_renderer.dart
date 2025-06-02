import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';
import '../canvas_rendering_engine.dart';

/// 文本元素专用渲染器
class TextElementRenderer extends ElementRenderer {
  // 文本样式缓存
  final Map<String, TextStyle> _styleCache = {};

  @override
  void dispose() {
    _styleCache.clear();
  }

  @override
  void render(Canvas canvas, ElementData element) {
    // 从properties中提取文本内容和样式
    final text = element.properties['text'] as String? ?? '';
    if (text.isEmpty) return;

    final style = _getTextStyle(element);
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(
      minWidth: 0,
      maxWidth: element.bounds.width,
    );

    // 计算文本位置（支持对齐）
    final offset = _calculateTextOffset(element, textPainter.size);

    textPainter.paint(canvas, offset);
  }

  /// 计算文本绘制偏移
  Offset _calculateTextOffset(ElementData element, Size textSize) {
    final align = element.properties['textAlign'] as String? ?? 'left';
    final valign = element.properties['verticalAlign'] as String? ?? 'top';

    double x = 0;
    double y = 0;

    // 水平对齐
    switch (align) {
      case 'center':
        x = (element.bounds.width - textSize.width) / 2;
        break;
      case 'right':
        x = element.bounds.width - textSize.width;
        break;
      default: // left
        x = 0;
        break;
    }

    // 垂直对齐
    switch (valign) {
      case 'middle':
        y = (element.bounds.height - textSize.height) / 2;
        break;
      case 'bottom':
        y = element.bounds.height - textSize.height;
        break;
      default: // top
        y = 0;
        break;
    }

    return Offset(x, y);
  }

  /// 生成样式缓存键
  String _generateStyleKey(ElementData element) {
    final props = element.properties;
    return '${props['fontSize']}_${props['color']}_${props['fontWeight']}_${props['fontStyle']}_${props['fontFamily']}';
  }

  /// 获取文本样式
  TextStyle _getTextStyle(ElementData element) {
    final styleKey = _generateStyleKey(element);

    return _styleCache.putIfAbsent(styleKey, () {
      final props = element.properties;

      return TextStyle(
        fontSize: (props['fontSize'] as num?)?.toDouble() ?? 14.0,
        color: _parseColor(props['color'] as String? ?? '#000000'),
        fontWeight: _parseFontWeight(props['fontWeight'] as String?),
        fontStyle: _parseFontStyle(props['fontStyle'] as String?),
        fontFamily: props['fontFamily'] as String?,
      );
    });
  }

  /// 解析颜色
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
      // 解析失败，返回默认颜色
    }
    return Colors.black;
  }

  /// 解析字体样式
  FontStyle? _parseFontStyle(String? style) {
    switch (style) {
      case 'italic':
        return FontStyle.italic;
      case 'normal':
        return FontStyle.normal;
      default:
        return null;
    }
  }

  /// 解析字体粗细
  FontWeight? _parseFontWeight(String? weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
      default:
        return null;
    }
  }
}
