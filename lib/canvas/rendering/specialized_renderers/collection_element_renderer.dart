import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/interfaces/element_data.dart';
import '../canvas_rendering_engine.dart';

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
class CollectionElementRenderer extends ElementRenderer {
  final Map<String, List<CharPosition>> _positionsCache = {};
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, ui.Image> _textureCache = {};
  final Stopwatch _renderStopwatch = Stopwatch();

  /// 清除缓存
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
  void render(Canvas canvas, ElementData element) {
    _renderStopwatch.start();

    try {
      // 提取集字元素的属性
      final characters = element.properties['text'] as String? ?? '';
      final fontSize = element.properties['fontSize'] as double? ?? 24.0;

      if (characters.isEmpty) {
        _renderStopwatch.stop();
        return;
      }

      // 获取字符位置
      final positions = getCharPositions(
        element.id,
        characters,
        element.bounds.size,
        fontSize,
        0.0, // letterSpacing
        0.0, // lineSpacing
        'horizontal-l', // writingMode
        'left', // textAlign
        'top', // verticalAlign
        false, // enableSoftLineBreak
      );

      // 渲染每个字符
      for (final position in positions) {
        _renderCharacter(canvas, position, element);
      }
    } catch (e) {
      debugPrint('CollectionElementRenderer 渲染错误: $e');
    } finally {
      _renderStopwatch.stop();
    }
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

  /// 渲染单个字符
  void _renderCharacter(
      Canvas canvas, CharPosition position, ElementData element) {
    // 绘制字符背景
    if (position.backgroundColor != Colors.transparent) {
      final bgPaint = Paint()..color = position.backgroundColor;
      canvas.drawRect(position.rect, bgPaint);
    }

    // 绘制字符文本 (简化实现)
    final textPainter = TextPainter(
      text: TextSpan(
        text: position.char,
        style: TextStyle(
          fontSize: position.size,
          color: position.fontColor,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, position.position);
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
