import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 测试缩略图生成器
class TestThumbnail {
  /// 生成一个简单的测试缩略图
  static Future<Uint8List> generateTestThumbnail({
    double width = 300,
    double height = 400,
    String text = 'Test Thumbnail',
    Color backgroundColor = Colors.lightBlue,
    Color textColor = Colors.white,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width, height);
    
    // 绘制背景
    final paint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);
    
    // 绘制边框
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), borderPaint);
    
    // 绘制文本
    final textStyle = ui.TextStyle(
      color: textColor,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    
    final paragraphBuilder = ui.ParagraphBuilder(ui.ParagraphStyle(
      textAlign: TextAlign.center,
    ))
      ..pushStyle(textStyle)
      ..addText(text);
    
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(width: width - 20));
    
    // 将文本放在中间
    canvas.drawParagraph(
      paragraph,
      Offset((width - paragraph.width) / 2, (height - paragraph.height) / 2),
    );
    
    // 绘制一些图形
    final circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width / 4, height / 4), 30, circlePaint);
    
    final rectPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(width * 3/4 - 30, height * 3/4 - 30, 60, 60),
      rectPaint,
    );
    
    // 完成绘制
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }
}
