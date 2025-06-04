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
    debugPrint('📄 TextElementRenderer.render - 文本内容: "$text"');
    debugPrint('📄 TextElementRenderer.render - 所有属性: ${element.properties.keys.join(', ')}');

    if (text.isEmpty) {
      debugPrint('⚠️ TextElementRenderer - 文本为空，跳过渲染');
      return;
    }

    try {
      final style = _getTextStyle(element);
      debugPrint('🎨 TextElementRenderer - 创建TextPainter');
      debugPrint('🎨 TextElementRenderer - 文本样式: $style');

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      );

      debugPrint('📏 TextElementRenderer - 布局文本，最大宽度: ${element.bounds.width}');
      textPainter.layout(
        minWidth: 0,
        maxWidth: element.bounds.width,
      );
      
      debugPrint('📏 TextElementRenderer - 文本尺寸: ${textPainter.size}');

      // 计算文本位置（支持对齐）
      final offset = _calculateTextOffset(element, textPainter.size);
      debugPrint(
          '📌 TextElementRenderer - 文本偏移: $offset, 文本尺寸: ${textPainter.size}');

      // 绘制文本
      textPainter.paint(canvas, offset);
      debugPrint('✅ TextElementRenderer - 文本已绘制');
    } catch (e, stackTrace) {
      debugPrint('❌ TextElementRenderer - 渲染文本时出错: $e');
      debugPrint('📍 Stack trace: $stackTrace');
    }
  }

  /// 计算文本绘制偏移
  Offset _calculateTextOffset(ElementData element, Size textSize) {
    final align = element.properties['textAlign'] as String? ?? 'left';
    final valign = element.properties['verticalAlign'] as String? ?? 'top';

    debugPrint('📏 计算文本偏移:');
    debugPrint('   - 水平对齐: $align');
    debugPrint('   - 垂直对齐: $valign');
    debugPrint('   - 元素尺寸: ${element.bounds.width} x ${element.bounds.height}');
    debugPrint('   - 文本尺寸: ${textSize.width} x ${textSize.height}');

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

    final offset = Offset(x, y);
    debugPrint('   - 计算结果偏移: $offset');

    return offset;
  }  /// 生成样式缓存键
  String _generateStyleKey(ElementData element) {
    final props = element.properties;
    final fontSize = props['fontSize'];
    
    // Check both color and fontColor for backward compatibility
    String? color = props['color'] as String?;
    if (color == null) {
      color = props['fontColor'] as String?;
    }
    
    final fontWeight = props['fontWeight'];
    final fontStyle = props['fontStyle'];
    final fontFamily = props['fontFamily'];

    final key = '${fontSize}_${color}_${fontWeight}_${fontStyle}_$fontFamily';
    debugPrint('🔑 生成样式缓存键: $key');
    return key;
  }  /// 获取文本样式
  TextStyle _getTextStyle(ElementData element) {
    final styleKey = _generateStyleKey(element);

    debugPrint('🎨 TextElementRenderer._getTextStyle - 样式键: $styleKey');

    final props = element.properties;
    final fontSize = (props['fontSize'] as num?)?.toDouble() ?? 14.0;
    
    // Check both color and fontColor for backward compatibility
    String? colorStr = props['color'] as String?;
    if (colorStr == null) {
      colorStr = props['fontColor'] as String?;
      if (colorStr != null) {
        debugPrint('⚠️ Using fontColor instead of color: $colorStr');
      }
    }
    colorStr ??= '#000000';
    
    final fontWeight = props['fontWeight'] as String?;
    final fontStyle = props['fontStyle'] as String?;
    final fontFamily = props['fontFamily'] as String?;

    debugPrint('🎨 文本样式信息:');
    debugPrint('   - fontSize: $fontSize');
    debugPrint('   - color: $colorStr');
    debugPrint('   - fontWeight: $fontWeight');
    debugPrint('   - fontStyle: $fontStyle');
    debugPrint('   - fontFamily: $fontFamily');

    return _styleCache.putIfAbsent(styleKey, () {
      try {
        final color = _parseColor(colorStr!);
        debugPrint('   - 解析后的颜色: $color');
        
        final style = TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: _parseFontWeight(fontWeight),
          fontStyle: _parseFontStyle(fontStyle),
          fontFamily: fontFamily,
        );

        debugPrint('✅ 创建了新的TextStyle: $style');
        return style;
      } catch (e) {
        debugPrint('❌ TextStyle创建失败: $e');
        // 提供一个回退样式以确保渲染
        return TextStyle(
          fontSize: fontSize, 
          color: Colors.black,
        );
      }
    });
  }  /// 解析颜色
  Color _parseColor(String colorStr) {
    try {
      debugPrint('🎨 解析颜色: $colorStr');

      if (colorStr.startsWith('#')) {
        final hex = colorStr.substring(1);
        if (hex.length == 6) {
          final color = Color(int.parse('FF$hex', radix: 16));
          debugPrint('   - 解析为: ${color.toString()}');
          return color;
        } else if (hex.length == 8) {
          final color = Color(int.parse(hex, radix: 16));
          debugPrint('   - 解析为: ${color.toString()}');
          return color;
        } else if (hex.length == 3) {
          // 处理短格式的HEX颜色，如#FFF
          final r = hex.substring(0, 1);
          final g = hex.substring(1, 2);
          final b = hex.substring(2, 3);
          final color = Color(int.parse('FF$r$r$g$g$b$b', radix: 16));
          debugPrint('   - 解析为: ${color.toString()} (短格式HEX)');
          return color;
        }
      }

      // 尝试解析常见颜色名称
      switch (colorStr.toLowerCase()) {
        case 'black':
          return Colors.black;
        case 'white':
          return Colors.white;
        case 'red':
          return Colors.red;
        case 'green':
          return Colors.green;
        case 'blue':
          return Colors.blue;
        case 'yellow':
          return Colors.yellow;
        // 添加更多颜色名称支持
        case 'gray':
        case 'grey':
          return Colors.grey;
        case 'purple':
          return Colors.purple;
        case 'orange':
          return Colors.orange;
        case 'brown':
          return Colors.brown;
        case 'pink':
          return Colors.pink;
        case 'cyan':
          return Colors.cyan;
        case 'transparent':
          return Colors.transparent;
        default:
          break;
      }

      // 尝试解析rgba格式
      if (colorStr.startsWith('rgba(') && colorStr.endsWith(')')) {
        final values = colorStr
            .substring(5, colorStr.length - 1)
            .split(',')
            .map((e) => e.trim())
            .toList();
        
        if (values.length == 4) {
          final r = int.parse(values[0]);
          final g = int.parse(values[1]);
          final b = int.parse(values[2]);
          final a = double.parse(values[3]);
          final color = Color.fromRGBO(r, g, b, a);
          debugPrint('   - 解析为: ${color.toString()} (RGBA格式)');
          return color;
        }
      }

      // 尝试解析rgb格式
      if (colorStr.startsWith('rgb(') && colorStr.endsWith(')')) {
        final values = colorStr
            .substring(4, colorStr.length - 1)
            .split(',')
            .map((e) => e.trim())
            .toList();
        
        if (values.length == 3) {
          final r = int.parse(values[0]);
          final g = int.parse(values[1]);
          final b = int.parse(values[2]);
          final color = Color.fromRGBO(r, g, b, 1.0);
          debugPrint('   - 解析为: ${color.toString()} (RGB格式)');
          return color;
        }
      }

      debugPrint('⚠️ 无法解析颜色: $colorStr，使用默认颜色黑色');
    } catch (e) {
      debugPrint('❌ 解析颜色时出错: $e');
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
