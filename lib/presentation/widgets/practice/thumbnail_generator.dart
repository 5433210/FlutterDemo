import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 缩略图生成器
class ThumbnailGenerator {
  /// 生成字帖缩略图
  static Future<Uint8List?> generateThumbnail({
    required Map<String, dynamic> page,
    required String title,
  }) async {
    try {
      // 获取页面尺寸
      final pageWidth = page['width'] as double? ?? 595.0;
      final pageHeight = page['height'] as double? ?? 842.0;
      
      // 缩略图尺寸
      const thumbWidth = 300.0;
      const thumbHeight = 400.0;
      
      // 计算缩放比例
      final scaleX = thumbWidth / pageWidth;
      final scaleY = thumbHeight / pageHeight;
      final scale = math.min(scaleX, scaleY);
      
      // 创建一个简单的图像
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      
      // 绘制背景
      final bgColor = _parseColor(page['backgroundColor'] as String? ?? '#FFFFFF');
      final paint = Paint()..color = bgColor;
      canvas.drawRect(const Rect.fromLTWH(0, 0, thumbWidth, thumbHeight), paint);
      
      // 绘制元素
      if (page.containsKey('elements')) {
        final elements = page['elements'] as List<dynamic>;
        
        // 对元素进行排序，确保按照正确的图层顺序绘制
        final sortedElements = List<Map<String, dynamic>>.from(elements);
        
        // 绘制每个元素
        for (final element in sortedElements) {
          try {
            _drawElementThumbnail(canvas, element, scale);
          } catch (e) {
            debugPrint('绘制元素缩略图失败: $e');
          }
        }
      }
      
      // 绘制边框
      final borderPaint = Paint()
        ..color = Colors.grey
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawRect(const Rect.fromLTWH(0, 0, thumbWidth, thumbHeight), borderPaint);
      
      // 绘制标题（在底部）
      final textStyle = ui.TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      );
      
      // 绘制标题背景
      final bgPaint = Paint()..color = const Color.fromRGBO(255, 255, 255, 0.7);
      
      const textBgRect = Rect.fromLTWH(10, thumbHeight - 40, thumbWidth - 20, 30);
      
      canvas.drawRect(textBgRect, bgPaint);
      
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
      ))
        ..pushStyle(textStyle)
        ..addText(title);
      
      final paragraph = paragraphBuilder.build()
        ..layout(const ui.ParagraphConstraints(width: thumbWidth - 20));
      
      // 将标题放在底部
      canvas.drawParagraph(
        paragraph, 
        Offset(10, thumbHeight - paragraph.height - 10)
      );
      
      // 完成绘制
      final picture = recorder.endRecording();
      final img = await picture.toImage(thumbWidth.toInt(), thumbHeight.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final thumbnailData = byteData.buffer.asUint8List();
        debugPrint('生成缩略图成功: 大小 ${thumbnailData.length} 字节');
        return thumbnailData;
      }
      
      debugPrint('生成缩略图失败: byteData 为 null');
      return null;
    } catch (e) {
      debugPrint('生成缩略图失败: $e');
      return null;
    }
  }
  
  /// 绘制元素缩略图
  static void _drawElementThumbnail(Canvas canvas, Map<String, dynamic> element, double scale) {
    final type = element['type'] as String?;
    if (type == null) return;
    
    // 获取元素位置和尺寸
    final x = (element['x'] as num?)?.toDouble() ?? 0;
    final y = (element['y'] as num?)?.toDouble() ?? 0;
    final width = (element['width'] as num?)?.toDouble() ?? 100;
    final height = (element['height'] as num?)?.toDouble() ?? 100;
    
    // 应用缩放
    final scaledX = x * scale;
    final scaledY = y * scale;
    final scaledWidth = width * scale;
    final scaledHeight = height * scale;
    
    // 根据元素类型绘制
    switch (type) {
      case 'text':
        _drawTextElementThumbnail(
            canvas, element, scaledX, scaledY, scaledWidth, scaledHeight);
        break;
      case 'image':
        _drawImagePlaceholderThumbnail(
            canvas, scaledX, scaledY, scaledWidth, scaledHeight);
        break;
      case 'collection':
        _drawCollectionElementThumbnail(
            canvas, element, scaledX, scaledY, scaledWidth, scaledHeight);
        break;
      case 'group':
        _drawGroupElementThumbnail(canvas, element, scale);
        break;
      default:
        // 其他类型元素绘制一个占位矩形
        final paint = Paint()
          ..color = const Color.fromRGBO(128, 128, 128, 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
            Rect.fromLTWH(scaledX, scaledY, scaledWidth, scaledHeight), paint);
        break;
    }
  }
  
  /// 绘制集字元素缩略图
  static void _drawCollectionElementThumbnail(Canvas canvas, Map<String, dynamic> element, 
      double x, double y, double width, double height) {
    // 获取集字内容
    final content = element['content'] as Map<String, dynamic>?;
    if (content == null) return;
    
    final characters = content['characters'] as String? ?? '';
    if (characters.isEmpty) return;
    
    // 绘制背景
    final showBackground = content['showBackground'] as bool? ?? true;
    if (showBackground) {
      final bgColor = content['backgroundColor'] != null ? 
          _parseColor(content['backgroundColor'] as String) : 
          Colors.white;
      
      final bgPaint = Paint()..color = bgColor;
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);
    }
    
    // 绘制边框
    final borderPaint = Paint()
      ..color = const Color.fromARGB(128, 128, 128, 128)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), borderPaint);
    
    // 绘制网格线
    final gridLines = content['gridLines'] as bool? ?? false;
    if (gridLines) {
      final gridPaint = Paint()
        ..color = const Color.fromARGB(51, 128, 128, 128)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      
      // 简单绘制几条网格线
      for (int i = 1; i < 4; i++) {
        // 水平线
        canvas.drawLine(
          Offset(x, y + height * i / 4),
          Offset(x + width, y + height * i / 4),
          gridPaint
        );
        
        // 垂直线
        canvas.drawLine(
          Offset(x + width * i / 4, y),
          Offset(x + width * i / 4, y + height),
          gridPaint
        );
      }
    }
    
    // 绘制字符（简化处理，只显示前几个字符）
    final displayChars = characters.length > 4 ? characters.substring(0, 4) : characters;
    
    // 文本颜色
    final textColor = content['fontColor'] != null ? 
        _parseColor(content['fontColor'] as String) : 
        Colors.black;
    
    final fontSize = (content['fontSize'] as num? ?? 24).toDouble();
    final direction = content['direction'] as String? ?? 'horizontal';
    
    final textStyle = ui.TextStyle(
      color: textColor,
      fontSize: fontSize * 0.5, // 缩小字体以适应缩略图
    );
    
    if (direction == 'horizontal') {
      // 水平排列
      final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
      ))
        ..pushStyle(textStyle)
        ..addText(displayChars);
      
      final paragraph = paragraphBuilder.build()
        ..layout(ui.ParagraphConstraints(width: width - 10));
      
      // 居中显示
      final textX = x + (width - paragraph.longestLine) / 2;
      final textY = y + (height - paragraph.height) / 2;
      
      canvas.drawParagraph(paragraph, Offset(textX, textY));
    } else {
      // 垂直排列 - 简化处理，每个字符单独绘制
      final charHeight = fontSize * 0.7;
      final startY = y + (height - charHeight * displayChars.length) / 2;
      
      for (int i = 0; i < displayChars.length; i++) {
        final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
        ))
          ..pushStyle(textStyle)
          ..addText(displayChars[i]);
        
        final paragraph = paragraphBuilder.build()
          ..layout(ui.ParagraphConstraints(width: width - 10));
        
        final textX = x + (width - paragraph.longestLine) / 2;
        final textY = startY + i * charHeight;
        
        canvas.drawParagraph(paragraph, Offset(textX, textY));
      }
    }
  }
  
  /// 绘制组合元素缩略图
  static void _drawGroupElementThumbnail(Canvas canvas, Map<String, dynamic> group, double scale) {
    // 获取组内元素
    final children = group['children'] as List<dynamic>?;
    if (children == null || children.isEmpty) return;
    
    // 绘制每个子元素
    for (final child in children) {
      try {
        _drawElementThumbnail(canvas, child as Map<String, dynamic>, scale);
      } catch (e) {
        debugPrint('绘制组内元素缩略图失败: $e');
      }
    }
    
    // 绘制组边框
    final x = (group['x'] as num?)?.toDouble() ?? 0;
    final y = (group['y'] as num?)?.toDouble() ?? 0;
    final width = (group['width'] as num?)?.toDouble() ?? 100;
    final height = (group['height'] as num?)?.toDouble() ?? 100;
    
    final scaledX = x * scale;
    final scaledY = y * scale;
    final scaledWidth = width * scale;
    final scaledHeight = height * scale;
    
    final groupBorderPaint = Paint()
      ..color = const Color.fromARGB(128, 0, 0, 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRect(
      Rect.fromLTWH(scaledX, scaledY, scaledWidth, scaledHeight),
      groupBorderPaint
    );
  }
  
  /// 绘制图片占位符
  static void _drawImagePlaceholderThumbnail(Canvas canvas, double x, double y, double width, double height) {
    // 绘制图片占位符
    final paint = Paint()
      ..color = const Color.fromRGBO(128, 128, 128, 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
    
    // 绘制图片图标
    final iconPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // 绘制一个简单的图片图标（山和太阳）
    final centerX = x + width / 2;
    final centerY = y + height / 2;
    final iconSize = math.min(width, height) * 0.3;
    
    // 绘制山
    final mountainPath = Path()
      ..moveTo(centerX - iconSize, centerY + iconSize / 2)
      ..lineTo(centerX - iconSize / 2, centerY - iconSize / 3)
      ..lineTo(centerX, centerY + iconSize / 4)
      ..lineTo(centerX + iconSize / 2, centerY - iconSize / 2)
      ..lineTo(centerX + iconSize, centerY + iconSize / 2)
      ..close();
    
    canvas.drawPath(mountainPath, iconPaint);
    
    // 绘制太阳
    canvas.drawCircle(
      Offset(centerX - iconSize / 3, centerY - iconSize / 4), 
      iconSize / 6, 
      iconPaint
    );
  }
  
  /// 绘制文本元素缩略图
  static void _drawTextElementThumbnail(Canvas canvas, Map<String, dynamic> element, 
      double x, double y, double width, double height) {
    // 获取文本内容
    final content = element['content'] as Map<String, dynamic>?;
    if (content == null) return;
    
    final text = content['text'] as String? ?? '';
    if (text.isEmpty) return;
    
    // 绘制文本背景
    final bgColor = content['backgroundColor'] != null ? 
        _parseColor(content['backgroundColor'] as String) : 
        Colors.transparent;
    
    if (bgColor != Colors.transparent) {
      final bgPaint = Paint()..color = bgColor;
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), bgPaint);
    }
    
    // 绘制文本边框
    final borderPaint = Paint()
      ..color = const Color.fromRGBO(128, 128, 128, 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), borderPaint);
    
    // 绘制文本内容（简化处理，只显示前10个字符）
    final displayText = text.length > 10 ? '${text.substring(0, 10)}...' : text;
    
    // 文本颜色
    final textColor = content['textColor'] != null ? 
        _parseColor(content['textColor'] as String) : 
        Colors.black;
    
    final textStyle = ui.TextStyle(
      color: textColor,
      fontSize: 12 * (content['fontSize'] as num? ?? 16) / 16, // 缩放字体大小
    );
    
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle())
      ..pushStyle(textStyle)
      ..addText(displayText);
    
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width - 4));
    
    // 绘制文本，留出小边距
    canvas.drawParagraph(paragraph, Offset(x + 2, y + 2));
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
    return Colors.white; // 默认颜色
  }
}
