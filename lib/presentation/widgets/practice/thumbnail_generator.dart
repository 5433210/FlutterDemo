import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 缩略图生成器
class ThumbnailGenerator {
  /// 生成字帖缩略图
  ///
  /// 根据页面内容生成缩略图
  static Future<Uint8List?> generateThumbnail(
    Map<String, dynamic> page, {
    double width = 300.0,
    double height = 400.0,
    String? title,
  }) async {
    try {
      debugPrint('开始生成缩略图，尺寸: ${width}x$height');

      // 创建一个记录器
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 绘制背景
      final bgColorStr = page['backgroundColor'] as String? ?? '#FFFFFF';
      debugPrint('页面背景颜色: $bgColorStr');
      final bgColor = _parseColor(bgColorStr);
      final paint = Paint()..color = bgColor;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

      // 获取页面元素
      final elements = page['elements'] as List<dynamic>? ?? [];
      debugPrint('页面元素数量: ${elements.length}');

      // 计算缩放比例
      final pageWidth = (page['width'] as num?)?.toDouble() ?? 210.0;
      final pageHeight = (page['height'] as num?)?.toDouble() ?? 297.0;
      final scaleX = width / pageWidth;
      final scaleY = height / pageHeight;
      final scale = scaleX < scaleY ? scaleX : scaleY;
      debugPrint('缩放比例: $scale (原始尺寸: ${pageWidth}x$pageHeight)');

      // 应用缩放
      canvas.save(); // 保存初始状态
      canvas.scale(scale);

      // 绘制元素
      for (final element in elements) {
        // 检查元素是否隐藏
        final isHidden = element['hidden'] == true;
        if (isHidden) continue;

        // 检查元素所在图层的隐藏状态
        final layerId = element['layerId'] as String?;
        bool isLayerHidden = false;
        if (layerId != null && page.containsKey('layers')) {
          final layers = page['layers'] as List<dynamic>;
          final layer = layers.firstWhere(
            (l) => l['id'] == layerId,
            orElse: () => <String, dynamic>{},
          );
          isLayerHidden = layer['isVisible'] == false;
        }
        if (isLayerHidden) continue;

        // 获取元素属性
        final type = element['type'] as String;
        final x = (element['x'] as num).toDouble();
        final y = (element['y'] as num).toDouble();
        final elementWidth = (element['width'] as num).toDouble();
        final elementHeight = (element['height'] as num).toDouble();
        final rotation = (element['rotation'] as num?)?.toDouble() ?? 0.0;
        final opacity = (element['opacity'] as num?)?.toDouble() ?? 1.0;

        // 保存画布状态
        canvas.save();

        // 应用透明度
        canvas.saveLayer(
          Rect.fromLTWH(x, y, elementWidth, elementHeight),
          Paint()..color = Colors.white.withAlpha((opacity * 255).toInt()),
        );

        // 应用旋转
        canvas.translate(x + elementWidth / 2, y + elementHeight / 2);
        canvas.rotate(rotation * 3.1415926 / 180);
        canvas.translate(-(x + elementWidth / 2), -(y + elementHeight / 2));

        // 绘制元素
        switch (type) {
          case 'text':
            _drawTextElement(canvas, element, x, y);
            break;
          case 'image':
            _drawImageElement(canvas, element, x, y);
            break;
          case 'collection':
            _drawCollectionElement(canvas, element, x, y);
            break;
          case 'group':
            // 组合元素需要递归绘制
            _drawGroupElement(canvas, element, x, y);
            break;
        }

        // 恢复画布状态
        canvas.restore();
        canvas.restore();
      }

      // 重置缩放，确保标题以正常大小显示
      canvas.save();
      canvas.restore();
      canvas.save();

      // 添加明显的视觉元素，帮助确认图像是否正确渲染
      debugPrint('添加明显的视觉元素，帮助确认图像是否正确渲染');

      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0;
      canvas.drawRect(Rect.fromLTWH(0, 0, width, height), borderPaint);

      // 绘制对角线，确保图像有可见内容
      final linePaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 3.0;
      canvas.drawLine(const Offset(0, 0), Offset(width, height), linePaint);
      canvas.drawLine(Offset(width, 0), Offset(0, height), linePaint);

      // 在中心绘制一个圆形
      final circlePaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(width / 2, height / 2), 50, circlePaint);

      // 绘制标题
      if (title != null && title.isNotEmpty) {
        debugPrint('绘制标题: $title');

        // 绘制标题背景
        final bgPaint = Paint()
          ..color = Colors.white.withAlpha(178); // 使用withAlpha替代withOpacity
        final textBgRect = Rect.fromLTWH(10, height - 40, width - 20, 30);
        canvas.drawRect(textBgRect, bgPaint);

        // 绘制标题文本
        final textStyle = ui.TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: ui.FontWeight.bold,
        );

        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
        ))
          ..pushStyle(textStyle)
          ..addText(title);

        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: width - 20));

        // 将标题放在底部
        canvas.drawParagraph(
          paragraph,
          Offset(10, height - paragraph.height - 10),
        );
      }

      // 恢复画布状态
      canvas.restore();

      // 完成绘制
      final picture = recorder.endRecording();
      final img = await picture.toImage(width.toInt(), height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        return byteData.buffer.asUint8List();
      }

      return null;
    } catch (e, stack) {
      debugPrint('生成缩略图失败: $e');
      debugPrint('堆栈跟踪: $stack');
      return null;
    }
  }

  /// 绘制集字元素
  static void _drawCollectionElement(
      Canvas canvas, Map<String, dynamic> element, double x, double y) {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) {
        debugPrint('集字元素内容为空');
        return;
      }

      final characters = content['characters'] as List<dynamic>? ?? [];
      if (characters.isEmpty) {
        debugPrint('集字元素字符列表为空');
        return;
      }

      debugPrint('集字元素字符数量: ${characters.length}');

      final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 24.0;
      final fontColor =
          _parseColor(content['fontColor'] as String? ?? '#000000');
      final backgroundColor = content['backgroundColor'] != null
          ? _parseColor(content['backgroundColor'] as String)
          : null;
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      debugPrint('集字元素尺寸: ${width}x$height, 字体大小: $fontSize, 字体颜色: $fontColor');

      // 绘制背景
      if (backgroundColor != null) {
        final bgPaint = Paint()..color = backgroundColor;
        canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);
      } else {
        // 如果没有背景色，绘制一个浅色背景以便于区分
        final bgPaint = Paint()..color = Colors.blue.withAlpha(30);
        canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);
      }

      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.blue.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), borderPaint);

      // 获取字符文本
      final text = characters.map((c) => c['char'] as String? ?? '').join('');
      debugPrint('集字元素文本: $text');

      // 创建文本样式
      final textStyle = ui.TextStyle(
        color: fontColor,
        fontSize: fontSize,
      );

      // 创建段落
      final paragraphStyle = ui.ParagraphStyle(
        textAlign: TextAlign.center,
      );

      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(text);

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width));

      // 绘制文本
      canvas.drawParagraph(paragraph, Offset(x, y));

      // 绘制一些示例字符图像
      final cellSize = fontSize * 1.2;
      final cols = (width / cellSize).floor();
      final rows = (height / cellSize).floor();

      if (cols > 0 && rows > 0) {
        for (int i = 0; i < math.min(characters.length, cols * rows); i++) {
          final col = i % cols;
          final row = i ~/ cols;
          final charX = x + col * cellSize;
          final charY = y + row * cellSize;

          // 绘制字符边框
          final charBorderPaint = Paint()
            ..color = Colors.red.withAlpha(100)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.5;
          canvas.drawRect(
            Rect.fromLTWH(charX, charY, cellSize, cellSize),
            charBorderPaint,
          );
        }
      }
    } catch (e, stack) {
      debugPrint('绘制集字元素失败: $e');
      debugPrint('堆栈跟踪: $stack');
    }
  }

  /// 绘制组合元素
  static void _drawGroupElement(
      Canvas canvas, Map<String, dynamic> element, double x, double y) {
    try {
      final children = element['children'] as List<dynamic>? ?? [];
      if (children.isEmpty) return;

      // 获取组合元素的位置和大小
      final groupX = (element['x'] as num).toDouble();
      final groupY = (element['y'] as num).toDouble();

      // 保存画布状态
      canvas.save();

      // 应用组合元素的变换
      canvas.translate(groupX, groupY);

      // 绘制子元素
      for (final child in children) {
        final childX = (child['x'] as num).toDouble();
        final childY = (child['y'] as num).toDouble();
        final childType = child['type'] as String;

        switch (childType) {
          case 'text':
            _drawTextElement(canvas, child, childX, childY);
            break;
          case 'image':
            _drawImageElement(canvas, child, childX, childY);
            break;
          case 'collection':
            _drawCollectionElement(canvas, child, childX, childY);
            break;
        }
      }

      // 恢复画布状态
      canvas.restore();
    } catch (e) {
      debugPrint('绘制组合元素失败: $e');
    }
  }

  /// 绘制图片元素
  static void _drawImageElement(
      Canvas canvas, Map<String, dynamic> element, double x, double y) {
    // 简化实现，实际应用中需要加载图片
    final width = (element['width'] as num).toDouble();
    final height = (element['height'] as num).toDouble();

    // 绘制占位符
    final paint = Paint()
      ..color = Colors.grey.withAlpha(128) // 使用withAlpha替代withOpacity
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);

    // 绘制图片图标
    final iconPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 绘制图片图标（简化版）
    final iconRect = Rect.fromLTWH(
      x + width / 4,
      y + height / 4,
      width / 2,
      height / 2,
    );
    canvas.drawRect(iconRect, iconPaint);

    // 绘制对角线
    canvas.drawLine(
      Offset(x + width / 4, y + height / 4),
      Offset(x + width * 3 / 4, y + height * 3 / 4),
      iconPaint,
    );
    canvas.drawLine(
      Offset(x + width * 3 / 4, y + height / 4),
      Offset(x + width / 4, y + height * 3 / 4),
      iconPaint,
    );
  }

  /// 绘制文本元素
  static void _drawTextElement(
      Canvas canvas, Map<String, dynamic> element, double x, double y) {
    try {
      final content = element['content'] as Map<String, dynamic>?;
      if (content == null) return;

      final text = content['text'] as String? ?? '';
      final fontSize = (content['fontSize'] as num?)?.toDouble() ?? 16.0;
      final fontColor =
          _parseColor(content['fontColor'] as String? ?? '#000000');
      final backgroundColor = content['backgroundColor'] != null
          ? _parseColor(content['backgroundColor'] as String)
          : null;
      final alignment = content['alignment'] as String? ?? 'left';
      final width = (element['width'] as num).toDouble();
      final height = (element['height'] as num).toDouble();

      // 绘制背景
      if (backgroundColor != null) {
        final bgPaint = Paint()..color = backgroundColor;
        canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);
      }

      // 创建文本样式
      final textStyle = ui.TextStyle(
        color: fontColor,
        fontSize: fontSize,
      );

      // 创建段落
      final paragraphStyle = ui.ParagraphStyle(
        textAlign: _getTextAlign(alignment),
      );

      final paragraphBuilder = ui.ParagraphBuilder(paragraphStyle)
        ..pushStyle(textStyle)
        ..addText(text);

      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width));

      // 绘制文本
      canvas.drawParagraph(paragraph, Offset(x, y));
    } catch (e) {
      debugPrint('绘制文本元素失败: $e');
    }
  }

  /// 获取文本对齐方式
  static TextAlign _getTextAlign(String alignment) {
    switch (alignment) {
      case 'left':
        return TextAlign.left;
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

  /// 解析颜色字符串
  static Color _parseColor(String colorStr) {
    if (colorStr.startsWith('#')) {
      String hexColor = colorStr.substring(1);
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor'; // 添加透明度
      }
      return Color(int.parse(hexColor, radix: 16));
    }
    return Colors.black; // 默认颜色
  }
}
