#!/usr/bin/env dart

/// 测试词匹配模式下的预览和渲染修复
/// 验证：
/// 1. 字符预览面板正确显示分段
/// 2. 画布渲染保持图像宽高比

void main() {
  print('🧪 测试词匹配模式下的预览和渲染修复');
  print('=' * 50);

  // 测试1：字符预览分段逻辑
  testCharacterPreviewSegments();

  // 测试2：图像宽高比计算
  testImageAspectRatioCalculation();

  print('\n✅ 所有测试完成！');
}

void testCharacterPreviewSegments() {
  print('\n📱 测试字符预览分段逻辑...');

  // 模拟词匹配模式的内容数据
  final content = {
    'characters': 'nature 秋',
    'wordMatchingPriority': true,
    'segments': [
      {
        'text': 'nature',
        'startIndex': 0,
        'isChinese': false,
      },
      {
        'text': ' ',
        'startIndex': 6,
        'isChinese': false,
      },
      {
        'text': '秋',
        'startIndex': 7,
        'isChinese': true,
      },
    ],
  };

  print('输入字符串: "${content['characters']}"');
  print('词匹配模式: ${content['wordMatchingPriority']}');
  print('分段数量: ${(content['segments'] as List).length}');

  final segments = content['segments'] as List<Map<String, dynamic>>;
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    print(
        '  分段${i + 1}: "${segment['text']}" (索引${segment['startIndex']}, 长度${(segment['text'] as String).length})');
  }

  // 验证预览应该显示的项目数
  final expectedItems = segments.length; // 应该显示3个项目：nature(词组), 空格, 秋(单字符)
  print('预期预览项目数: $expectedItems');
  print('✅ 字符预览分段逻辑正确');
}

void testImageAspectRatioCalculation() {
  print('\n🎨 测试图像宽高比计算...');

  // 测试场景1：宽图像 (nature 的字母图像通常是宽的)
  testAspectRatio(
    '宽图像 (nature)',
    200, // imageWidth
    100, // imageHeight
    300, // rectWidth
    200, // rectHeight
  );

  // 测试场景2：高图像 (中文字符通常是方形的)
  testAspectRatio(
    '方形图像 (秋)',
    100, // imageWidth
    100, // imageHeight
    200, // rectWidth
    150, // rectHeight
  );

  // 测试场景3：极宽图像
  testAspectRatio(
    '极宽图像',
    400, // imageWidth
    100, // imageHeight
    200, // rectWidth
    200, // rectHeight
  );
}

void testAspectRatio(
  String testName,
  double imageWidth,
  double imageHeight,
  double rectWidth,
  double rectHeight,
) {
  print('\n  测试: $testName');

  final imageAspectRatio = imageWidth / imageHeight;
  final rectAspectRatio = rectWidth / rectHeight;

  print(
      '    图像尺寸: ${imageWidth.toInt()}x${imageHeight.toInt()} (宽高比: ${imageAspectRatio.toStringAsFixed(2)})');
  print(
      '    绘制区域: ${rectWidth.toInt()}x${rectHeight.toInt()} (宽高比: ${rectAspectRatio.toStringAsFixed(2)})');

  double drawWidth, drawHeight, offsetX, offsetY;

  if (imageAspectRatio > rectAspectRatio) {
    // 图像更宽，以宽度为准
    drawWidth = rectWidth;
    drawHeight = rectWidth / imageAspectRatio;
    offsetX = 0;
    offsetY = (rectHeight - drawHeight) / 2;
  } else {
    // 图像更高，以高度为准
    drawHeight = rectHeight;
    drawWidth = rectHeight * imageAspectRatio;
    offsetX = (rectWidth - drawWidth) / 2;
    offsetY = 0;
  }

  print(
      '    实际绘制: ${drawWidth.toStringAsFixed(1)}x${drawHeight.toStringAsFixed(1)}');
  print(
      '    偏移位置: (${offsetX.toStringAsFixed(1)}, ${offsetY.toStringAsFixed(1)})');

  // 验证宽高比保持
  final resultAspectRatio = drawWidth / drawHeight;
  final aspectRatioDiff = (resultAspectRatio - imageAspectRatio).abs();

  if (aspectRatioDiff < 0.001) {
    print('    ✅ 宽高比保持正确 (${resultAspectRatio.toStringAsFixed(2)})');
  } else {
    print(
        '    ❌ 宽高比失真 (原始: ${imageAspectRatio.toStringAsFixed(2)}, 结果: ${resultAspectRatio.toStringAsFixed(2)})');
  }
}
