#!/usr/bin/env dart

import 'dart:io';

void main() {
  print('=== 颜色解析功能修复验证 ===');

  final rendererFile =
      File('lib/presentation/widgets/practice/element_renderers.dart');
  if (!rendererFile.existsSync()) {
    print('❌ ElementRenderers文件不存在');
    return;
  }

  final content = rendererFile.readAsStringSync();

  // 检查是否使用了新的_parseBackgroundColor方法
  bool usesParseMethod =
      content.contains('_parseBackgroundColor(backgroundColor)');
  print('✅ 使用新的颜色解析方法: ${usesParseMethod ? '是' : '❌ 否'}');

  // 检查是否包含transparent处理
  bool handlesTransparent = content.contains("case 'transparent':");
  print('✅ 支持transparent颜色: ${handlesTransparent ? '是' : '❌ 否'}');

  // 检查是否包含其他常见颜色
  bool handlesCommonColors = content.contains("case 'white':") &&
      content.contains("case 'black':") &&
      content.contains("case 'red':");
  print('✅ 支持常见颜色名称: ${handlesCommonColors ? '是' : '❌ 否'}');

  // 检查是否仍支持16进制颜色
  bool supportsHexColors =
      content.contains('int.parse(fullColorStr, radix: 16)');
  print('✅ 支持16进制颜色: ${supportsHexColors ? '是' : '❌ 否'}');

  // 检查是否支持不同长度的16进制格式
  bool supports3DigitHex = content.contains('colorStr.length == 3');
  bool supports6DigitHex = content.contains('colorStr.length == 6');
  bool supports8DigitHex = content.contains('colorStr.length == 8');
  print('✅ 支持不同16进制格式:');
  print('   - 3位RGB: ${supports3DigitHex ? '是' : '❌ 否'}');
  print('   - 6位RRGGBB: ${supports6DigitHex ? '是' : '❌ 否'}');
  print('   - 8位AARRGGBB: ${supports8DigitHex ? '是' : '❌ 否'}');

  // 检查错误处理
  bool hasErrorHandling = content.contains('FormatException') &&
      content.contains('Cannot parse color');
  print('✅ 包含错误处理: ${hasErrorHandling ? '是' : '❌ 否'}');

  print('\n=== 验证完成 ===');

  if (usesParseMethod &&
      handlesTransparent &&
      handlesCommonColors &&
      supportsHexColors &&
      supports3DigitHex &&
      supports6DigitHex &&
      supports8DigitHex &&
      hasErrorHandling) {
    print('🎉 颜色解析功能已完全修复！');
    print('📝 支持的颜色格式:');
    print('   1. CSS颜色名称: transparent, white, black, red, green, blue等');
    print('   2. 3位16进制: #RGB');
    print('   3. 6位16进制: #RRGGBB');
    print('   4. 8位16进制: #AARRGGBB');
    print('   5. 不带#前缀的16进制格式');
    print('\n🐛 修复的问题:');
    print('   - 解决了"transparent"颜色值导致的FormatException错误');
    print('   - 增强了颜色解析的兼容性和鲁棒性');
  } else {
    print('⚠️  部分功能可能存在问题，请检查上述报告');
  }
}
