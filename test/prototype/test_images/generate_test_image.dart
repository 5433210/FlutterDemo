import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

/// 生成测试用的字体图像
Future<void> main() async {
  // 确保Flutter引擎初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 创建一个500x500的图像
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  const size = Size(500, 500);

  // 设置背景
  canvas.drawRect(
    Offset.zero & size,
    Paint()..color = Colors.white,
  );

  // 绘制汉字
  final textPainter = TextPainter(
    text: const TextSpan(
      text: '测',
      style: TextStyle(
        color: Colors.black,
        fontSize: 400,
        fontWeight: FontWeight.w400,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  textPainter.layout();

  // 居中绘制
  final position = Offset(
    (size.width - textPainter.width) / 2,
    (size.height - textPainter.height) / 2,
  );
  textPainter.paint(canvas, position);

  // 转换为图像
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    size.width.toInt(),
    size.height.toInt(),
  );

  // 转换为PNG数据
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  // 确保目录存在
  final directory = path.join(
    Directory.current.path,
    'assets',
    'test_images',
  );
  await Directory(directory).create(recursive: true);

  // 保存文件
  final file = File(path.join(directory, 'test_char.png'));
  await file.writeAsBytes(pngBytes);

  print('测试图像已生成: ${file.path}');
  exit(0);
}

/* 使用说明

1. 在项目根目录运行：
   flutter run test/prototype/test_images/generate_test_image.dart

2. 检查生成的图像：
   assets/test_images/test_char.png

3. 更新pubspec.yaml：
   flutter:
     assets:
       - assets/test_images/
*/
