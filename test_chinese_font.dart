import 'package:charasgem/utils/chinese_font_helper.dart';

void main() {
  print('=== 测试中文字符字体处理工具 ===');
  
  // 测试中文字符检测
  final testCases = [
    '书法',
    'Regular Script',  
    '书法 Script',
    'A',
    '中文English混合',
    '123',
    '',
  ];
  
  for (final text in testCases) {
    final containsChinese = ChineseFontHelper.containsChinese(text);
    final fontFamily = ChineseFontHelper.getFontFamilyForContent(text);
    
    print('文本: "$text"');
    print('  包含中文: $containsChinese');
    print('  字体: ${fontFamily ?? "默认字体"}');
    print('');
  }
  
  print('✅ 中文字符字体处理工具测试完成');
}
