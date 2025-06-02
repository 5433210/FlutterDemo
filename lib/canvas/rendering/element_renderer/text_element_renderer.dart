import 'dart:ui' as ui;

// No longer needed: import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../../core/canvas_state_manager.dart';
import '../../core/interfaces/element_data.dart';
import '../rendering_engine.dart';

/// 文本元素专用渲染器
///
/// 为文本元素提供高性能、专业的文本渲染实现
/// 支持富文本、多样式和文本特效
class TextElementRenderer {
  static const String rendererType = 'text';

  final CanvasStateManager stateManager;

  // 文本渲染缓存
  final Map<String, ui.Image> _textImageCache = {};

  // 文本测量缓存，避免重复计算文本尺寸
  final Map<String, Size> _textMeasurementCache = {};

  TextElementRenderer(this.stateManager);

  /// 清理资源
  void dispose() {
    _textImageCache.forEach((_, image) => image.dispose());
    _textImageCache.clear();
    _textMeasurementCache.clear();
  }

  /// 预加载文本资源
  Future<void> preloadResources(ElementData element) async {
    // 预先计算文本尺寸并缓存
    final textData = element.properties['text'] as String? ?? '';
    final fontSize = element.properties['fontSize'] as double? ?? 16.0;
    final fontFamily = element.properties['fontFamily'] as String? ?? 'Roboto';

    final cacheKey = '${textData}_${fontSize}_$fontFamily';

    if (!_textMeasurementCache.containsKey(cacheKey)) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: textData,
          style: TextStyle(
            fontSize: fontSize,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      _textMeasurementCache[cacheKey] =
          Size(textPainter.width, textPainter.height);
    }
  }

  /// 渲染文本元素到画布
  void renderElement(
      Canvas canvas, ElementData element, RenderingContext context) {
    if (!element.visible) return;

    final rect = element.bounds;
    final textData = element.properties['text'] as String? ?? '';
    final fontSize = element.properties['fontSize'] as double? ?? 16.0;
    final fontFamily = element.properties['fontFamily'] as String? ?? 'Roboto';
    final fontWeight = _parseFontWeight(element.properties['fontWeight']);
    final fontStyle = element.properties['fontStyle'] == 'italic'
        ? FontStyle.italic
        : FontStyle.normal;
    final color =
        _parseColor(element.properties['color'] as String? ?? '#000000');
    final textAlign =
        _parseTextAlign(element.properties['textAlign'] as String? ?? 'left');
    final letterSpacing = element.properties['letterSpacing'] as double? ?? 0.0;
    final lineHeight = element.properties['lineHeight'] as double? ?? 1.2;

    // 应用元素变换
    canvas.save();

    // 处理元素的变换矩阵
    if (element.transform != null) {
      canvas.transform(element.transform!);
    }

    // 创建文本绘制器
    final textPainter = TextPainter(
      text: TextSpan(
        text: textData,
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: fontFamily,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          color: color,
          letterSpacing: letterSpacing,
          height: lineHeight,
        ),
      ),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
    );

    // 布局文本
    textPainter.layout(
      minWidth: 0,
      maxWidth: rect.width,
    );

    // 根据对齐方式计算绘制位置
    final xPosition = _calculateXPosition(rect, textPainter, textAlign);
    final yPosition = rect.top + (rect.height - textPainter.height) / 2;

    // 绘制文本
    textPainter.paint(canvas, Offset(xPosition, yPosition));

    // 如果元素被选中，绘制选择指示器
    if (context.isSelected(element.id)) {
      _drawSelectionIndicator(canvas, rect, context);
    }

    canvas.restore();
  }

  /// 判断元素是否需要重绘
  bool shouldRepaint(ElementData oldElement, ElementData newElement) {
    // 检查关键属性是否变化
    if (oldElement.visible != newElement.visible) return true;
    if (oldElement.transform != newElement.transform) return true;

    final oldText = oldElement.properties['text'] as String? ?? '';
    final newText = newElement.properties['text'] as String? ?? '';
    if (oldText != newText) return true;

    final oldFontSize = oldElement.properties['fontSize'] as double? ?? 16.0;
    final newFontSize = newElement.properties['fontSize'] as double? ?? 16.0;
    if (oldFontSize != newFontSize) return true;

    final oldColor = oldElement.properties['color'] as String? ?? '#000000';
    final newColor = newElement.properties['color'] as String? ?? '#000000';
    if (oldColor != newColor) return true;

    // 其他属性的变化检查...

    return false;
  }

  /// 计算文本X轴位置
  double _calculateXPosition(
      Rect rect, TextPainter textPainter, TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return rect.left + (rect.width - textPainter.width) / 2;
      case TextAlign.right:
      case TextAlign.end:
        return rect.right - textPainter.width;
      case TextAlign.justify:
      case TextAlign.left:
      case TextAlign.start:
        return rect.left;
    }
  }

  /// 绘制控制点
  void _drawControlHandles(Canvas canvas, Rect rect, RenderingContext context) {
    const handleSize = 8.0;
    final handlePaint = Paint()
      ..color = context.selectionColor
      ..style = PaintingStyle.fill;

    // 角控制点
    final handles = [
      Rect.fromCenter(
          center: rect.topLeft, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.topRight, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.bottomLeft, width: handleSize, height: handleSize),
      Rect.fromCenter(
          center: rect.bottomRight, width: handleSize, height: handleSize),
    ];

    // 边控制点
    handles.addAll([
      Rect.fromCenter(
          center: Offset(rect.left + rect.width / 2, rect.top),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.right, rect.top + rect.height / 2),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.left + rect.width / 2, rect.bottom),
          width: handleSize,
          height: handleSize),
      Rect.fromCenter(
          center: Offset(rect.left, rect.top + rect.height / 2),
          width: handleSize,
          height: handleSize),
    ]);

    for (var handle in handles) {
      canvas.drawRect(handle, handlePaint);
    }
  }

  /// 绘制选择指示器
  void _drawSelectionIndicator(
      Canvas canvas, Rect rect, RenderingContext context) {
    final paint = Paint()
      ..color = context.selectionColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);

    final borderPaint = Paint()
      ..color = context.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(rect, borderPaint);

    // 绘制控制点
    _drawControlHandles(canvas, rect, context);
  }

  /// 解析颜色字符串
  Color _parseColor(String colorStr) {
    if (colorStr == 'transparent') {
      return Colors.transparent;
    }

    if (colorStr.startsWith('#')) {
      String hexColor = colorStr.replaceAll('#', '');

      if (hexColor.length == 3) {
        // 扩展3位色值为6位
        hexColor = hexColor.split('').map((e) => '$e$e').join('');
      }

      if (hexColor.length == 6) {
        // 添加不透明度
        hexColor = 'FF$hexColor';
      }

      return Color(int.parse(hexColor, radix: 16));
    }

    // 默认黑色
    return Colors.black;
  }

  /// 解析字体粗细
  FontWeight _parseFontWeight(dynamic value) {
    if (value == null) return FontWeight.normal;

    if (value is int) {
      switch (value) {
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
        default:
          return FontWeight.normal;
      }
    } else if (value is String) {
      switch (value.toLowerCase()) {
        case 'thin':
          return FontWeight.w100;
        case 'extralight':
          return FontWeight.w200;
        case 'light':
          return FontWeight.w300;
        case 'normal':
          return FontWeight.w400;
        case 'medium':
          return FontWeight.w500;
        case 'semibold':
          return FontWeight.w600;
        case 'bold':
          return FontWeight.w700;
        case 'extrabold':
          return FontWeight.w800;
        case 'black':
          return FontWeight.w900;
        default:
          return FontWeight.normal;
      }
    }

    return FontWeight.normal;
  }

  /// 解析文本对齐方式
  TextAlign _parseTextAlign(String align) {
    switch (align.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      case 'start':
        return TextAlign.start;
      case 'end':
        return TextAlign.end;
      default:
        return TextAlign.left;
    }
  }
}
