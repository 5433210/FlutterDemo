import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';
import '../element_renderer.dart';

/// 字符位置类
class CharPosition {
  final String char;
  final Offset position;
  final double size;
  final int index;
  final int originalIndex;
  final Color fontColor;
  final Color backgroundColor;
  final bool isNewLine;

  CharPosition({
    required this.char,
    required this.position,
    required this.size,
    required this.index,
    required this.originalIndex,
    this.fontColor = Colors.black,
    this.backgroundColor = Colors.transparent,
    this.isNewLine = false,
  });

  Rect get innerRect {
    final padding = size * 0.15;
    return Rect.fromLTWH(
      position.dx + padding,
      position.dy + padding,
      size - padding * 2,
      size - padding * 2,
    );
  }

  Rect get rect => Rect.fromLTWH(position.dx, position.dy, size, size);
}

/// 集字元素渲染器
class CollectionElementRenderer extends ElementRenderer<ElementData> {
  final Map<String, List<CharPosition>> _positionsCache = {};
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, ui.Image> _textureCache = {};
  bool _initialized = false;
  final Stopwatch _renderStopwatch = Stopwatch();

  @override
  String get elementType => 'collection';

  @override
  bool get isInitialized => _initialized;

  @override
  bool get supportsCaching => true;

  @override
  bool get supportsGpuAcceleration => true;

  @override
  bool canRender(ElementData element) {
    return element.type == 'collection';
  }

  @override
  void clearCache([String? elementId]) {
    if (elementId != null) {
      _positionsCache.remove(elementId);
      _imageCache.remove(elementId);
    } else {
      _positionsCache.clear();
      _imageCache.clear();
      _textureCache.clear();
    }
  }

  @override
  void dispose() {
    clearCache();
    _initialized = false;
  }

  @override
  int estimateRenderTime(ElementData element, RenderQuality quality) {
    final text = element.properties['text'] as String? ?? '';
    final hasTexture = element.properties['hasTexture'] as bool? ?? false;

    int baseTime = 5;
    baseTime += text.length * 0.5 ~/ 1;

    if (hasTexture) {
      baseTime += 10;
    }

    switch (quality) {
      case RenderQuality.low:
        return baseTime;
      case RenderQuality.normal:
        return (baseTime * 1.5).toInt();
      case RenderQuality.high:
        return baseTime * 2;
    }
  }

  @override
  Rect getBounds(ElementData element, [Matrix4? transform]) {
    return element.bounds;
  }

  List<CharPosition> getCharPositions(
    String elementId,
    String text,
    Size availableSize,
    double fontSize,
    double letterSpacing,
    double lineSpacing,
    String writingMode,
    String textAlign,
    String verticalAlign,
    bool enableSoftLineBreak,
  ) {
    final cacheKey = elementId +
        text +
        fontSize.toString() +
        writingMode +
        textAlign +
        verticalAlign +
        enableSoftLineBreak.toString();
    if (_positionsCache.containsKey(cacheKey)) {
      return _positionsCache[cacheKey]!;
    }

    List<CharPosition> positions = [];

    // 处理软换行
    List<String> lines;
    if (enableSoftLineBreak) {
      lines =
          _wrapTextToLines(text, availableSize.width, fontSize, letterSpacing);
    } else {
      lines = text.split('\n');
    }

    int charIndex = 0;
    int originalCharIndex = 0;

    // 处理垂直布局
    if (writingMode == 'vertical-rl' || writingMode == 'vertical-lr') {
      return _calculateVerticalPositions(
          lines,
          availableSize,
          fontSize,
          letterSpacing,
          lineSpacing,
          writingMode,
          textAlign,
          verticalAlign,
          originalCharIndex);
    }

    // 水平布局
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      // 计算行的起始Y位置
      double y = lineIndex * (fontSize + lineSpacing);
      if (verticalAlign == 'middle' || verticalAlign == 'center') {
        final totalHeight =
            lines.length * fontSize + (lines.length - 1) * lineSpacing;
        y = (availableSize.height - totalHeight) / 2 +
            lineIndex * (fontSize + lineSpacing);
      }

      // 计算行内字符位置
      for (int i = 0; i < line.length; i++) {
        double x = i * (fontSize + letterSpacing);
        if (textAlign == 'center') {
          final lineWidth =
              line.length * fontSize + (line.length - 1) * letterSpacing;
          x = (availableSize.width - lineWidth) / 2 +
              i * (fontSize + letterSpacing);
        } else if (textAlign == 'right') {
          final lineWidth =
              line.length * fontSize + (line.length - 1) * letterSpacing;
          x = availableSize.width - lineWidth + i * (fontSize + letterSpacing);
        }

        positions.add(CharPosition(
          char: line[i],
          position: Offset(x, y),
          size: fontSize,
          index: charIndex,
          originalIndex: originalCharIndex,
          isNewLine: lineIndex > 0 && i == 0, // 第二行及以后行的第一个字符标记为新行
        ));
        charIndex++;
        originalCharIndex++;
      }

      // 添加换行符位置（对于原始换行符）
      if (!enableSoftLineBreak && lineIndex < lines.length - 1) {
        positions.add(CharPosition(
          char: '\n',
          position: Offset(line.length * (fontSize + letterSpacing), y),
          size: fontSize,
          index: charIndex,
          originalIndex: originalCharIndex,
          isNewLine: false, // 换行符本身不是新行的开始
        ));
        charIndex++;
        originalCharIndex++;
      }
    }

    _positionsCache[cacheKey] = positions;
    return positions;
  }

  @override
  Path getHitTestPath(ElementData element, [Matrix4? transform]) {
    final path = Path();
    path.addRect(element.bounds);
    return path;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  Color parseColor(String colorStr) {
    if (colorStr == 'transparent') {
      return Colors.transparent;
    }

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

  @override
  Future<ui.Image?> prerender(
      ElementData element, RenderContext context) async {
    return null;
  }

  @override
  void render(ElementData element, RenderContext context) {
    _renderStopwatch.start();

    final canvas = context.canvas;
    final text = element.properties['text'] as String? ?? '';

    if (text.isEmpty) {
      _renderStopwatch.stop();
      _renderStopwatch.reset();
      return;
    }

    final writingMode =
        element.properties['writingMode'] as String? ?? 'horizontal-tb';
    final fontSize = element.properties['fontSize'] as double? ?? 16.0;
    final letterSpacing = element.properties['letterSpacing'] as double? ?? 0.0;
    final lineSpacing = element.properties['lineSpacing'] as double? ?? 0.0;
    final textAlign = element.properties['textAlign'] as String? ?? 'left';
    final verticalAlign =
        element.properties['verticalAlign'] as String? ?? 'top';
    final fontColor = element.properties['fontColor'] as String? ?? '#000000';
    final enableSoftLineBreak =
        element.properties['enableSoftLineBreak'] as bool? ?? false;

    final positions = getCharPositions(
      element.id,
      text,
      element.bounds.size,
      fontSize,
      letterSpacing,
      lineSpacing,
      writingMode,
      textAlign,
      verticalAlign,
      enableSoftLineBreak,
    );

    for (final pos in positions) {
      if (pos.char != '\n') {
        if (pos.backgroundColor != Colors.transparent) {
          final bgPaint = Paint()..color = pos.backgroundColor;
          canvas.drawRect(pos.rect, bgPaint);
        }

        final textPainter = TextPainter(
          text: TextSpan(
            text: pos.char,
            style: TextStyle(
              fontSize: pos.size,
              color: parseColor(fontColor),
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, pos.position);
      }
    }

    _renderStopwatch.stop();
    _renderStopwatch.reset();
  }

  @override
  void renderSelection(ElementData element, RenderContext context) {
    final canvas = context.canvas;
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(element.bounds, paint);
  }

  @override
  void updateCache(ElementData element) {
    clearCache(element.id);
  }

  List<CharPosition> _calculateVerticalPositions(
    List<String> lines,
    Size availableSize,
    double fontSize,
    double letterSpacing,
    double lineSpacing,
    String writingMode,
    String textAlign,
    String verticalAlign,
    int startingOriginalIndex,
  ) {
    List<CharPosition> positions = [];
    int charIndex = 0;
    int originalIndex = startingOriginalIndex;

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];

      // 垂直布局中，列的X位置
      double x;
      if (writingMode == 'vertical-rl') {
        x = availableSize.width - (lineIndex + 1) * (fontSize + lineSpacing);
      } else {
        x = lineIndex * (fontSize + lineSpacing);
      }

      // 计算字符在列中的位置
      for (int i = 0; i < line.length; i++) {
        double y = i * (fontSize + letterSpacing);
        if (textAlign == 'center') {
          final lineHeight =
              line.length * fontSize + (line.length - 1) * letterSpacing;
          y = (availableSize.height - lineHeight) / 2 +
              i * (fontSize + letterSpacing);
        }

        positions.add(CharPosition(
          char: line[i],
          position: Offset(x, y),
          size: fontSize,
          index: charIndex,
          originalIndex: originalIndex,
          isNewLine: lineIndex > 0 && i == 0,
        ));
        charIndex++;
        originalIndex++;
      }
    }

    return positions;
  }

  List<String> _wrapTextToLines(
      String text, double maxWidth, double fontSize, double letterSpacing) {
    if (maxWidth <= 0) return [text];

    final charWidth = fontSize + letterSpacing;
    final maxCharsPerLine = (maxWidth / charWidth).floor();
    if (maxCharsPerLine <= 0) return [text];

    List<String> lines = [];
    String currentLine = '';

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '\n') {
        lines.add(currentLine);
        currentLine = '';
      } else if (currentLine.length >= maxCharsPerLine) {
        lines.add(currentLine);
        currentLine = char;
      } else {
        currentLine += char;
      }
    }

    if (currentLine.isNotEmpty) {
      lines.add(currentLine);
    }

    return lines.isEmpty ? [''] : lines;
  }
}
