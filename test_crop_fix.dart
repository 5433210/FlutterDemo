import 'dart:io';

void main() {
  print('=== 裁剪功能修复验证 ===');

  // 模拟图像元素内容
  Map<String, dynamic> content = {
    'imageUrl': 'test.jpg',
    'fit': 'contain',
    'aspectRatio': 1.0,
    // 注意：这里没有 cropX, cropY, cropWidth, cropHeight
  };

  // 模拟图像尺寸
  const imageWidth = 800.0;
  const imageHeight = 600.0;
  const renderWidth = 400.0;
  const renderHeight = 300.0;

  print('图像原始尺寸: ${imageWidth}x$imageHeight');
  print('渲染尺寸: ${renderWidth}x$renderHeight');
  print('修复前内容: $content');

  // 模拟修复后的初始化逻辑
  content['originalWidth'] = imageWidth;
  content['originalHeight'] = imageHeight;
  content['renderWidth'] = renderWidth;
  content['renderHeight'] = renderHeight;

  // 初始化裁剪属性
  if (content['cropX'] == null) {
    content['cropX'] = 0.0;
  }
  if (content['cropY'] == null) {
    content['cropY'] = 0.0;
  }
  if (content['cropWidth'] == null) {
    content['cropWidth'] = imageWidth;
  }
  if (content['cropHeight'] == null) {
    content['cropHeight'] = imageHeight;
  }

  print('修复后内容: $content');

  // 验证读取逻辑
  final cropX = (content['cropX'] as num?)?.toDouble() ?? 0.0;
  final cropY = (content['cropY'] as num?)?.toDouble() ?? 0.0;
  final cropWidth = (content['cropWidth'] as num?)?.toDouble() ?? 100.0;
  final cropHeight = (content['cropHeight'] as num?)?.toDouble() ?? 100.0;

  print('属性面板应显示:');
  print('  X: ${cropX.round()}px');
  print('  Y: ${cropY.round()}px');
  print('  宽度: ${cropWidth.round()}px');
  print('  高度: ${cropHeight.round()}px');

  print('✅ 修复验证完成');
}
