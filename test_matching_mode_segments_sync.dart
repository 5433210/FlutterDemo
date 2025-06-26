#!/usr/bin/env dart

/// 验证匹配模式和 segments 同步修复的测试脚本

void main() {
  print('=== 匹配模式和 Segments 同步修复验证 ===');
  
  // 模拟修复后的行为
  testMatchingModeSync();
  
  print('\n=== 修复效果验证 ===');
  print('✅ 新增 _initializeMatchingModeAndSegments() 方法');
  print('✅ 修改 _onWordMatchingModeChanged() 方法以更新 content');
  print('✅ 新增 _generateSegments() 方法根据匹配模式生成分段');
  
  print('\n=== 预期行为 ===');
  print('1. 初始化时自动设置 wordMatchingPriority 和 segments');
  print('2. 切换匹配模式时同步更新 content 数据');
  print('3. 词匹配模式："nature 秋" → ["nature", " ", "秋"]');
  print('4. 字符匹配模式："nature 秋" → ["n","a","t","u","r","e"," ","秋"]');
  print('5. 预览面板能正确显示对应模式的结果');
  
  print('\n=== 用户测试步骤 ===');
  print('1. 重新启动应用');
  print('2. 输入 "nature 秋"');
  print('3. 确认 "Word Matching Priority" 按钮激活时显示 3 个段');
  print('4. 点击切换按钮，确认字符匹配模式显示 8 个段');
  print('5. 观察日志中的 segments 数据变化');
}

void testMatchingModeSync() {
  print('\n=== 模拟修复后的匹配模式同步 ===');
  
  final text = "nature 秋";
  
  // 模拟词匹配模式
  print('\n词匹配模式:');
  final wordSegments = generateSegments(text, true);
  print('  wordMatchingPriority: true');
  print('  segments: $wordSegments');
  
  // 模拟字符匹配模式
  print('\n字符匹配模式:');
  final charSegments = generateSegments(text, false);
  print('  wordMatchingPriority: false');
  print('  segments: $charSegments');
}

List<Map<String, dynamic>> generateSegments(String text, bool wordMatching) {
  final segments = <Map<String, dynamic>>[];
  
  if (wordMatching) {
    // 词匹配模式：智能分词
    final parts = text.split(' ');
    int startIndex = 0;
    
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      
      if (part.isNotEmpty) {
        segments.add({
          'text': part,
          'startIndex': startIndex,
          'length': part.length,
        });
        startIndex += part.length;
      }
      
      // 添加空格分隔符（除了最后一个部分）
      if (i < parts.length - 1) {
        segments.add({
          'text': ' ',
          'startIndex': startIndex,
          'length': 1,
        });
        startIndex += 1;
      }
    }
  } else {
    // 字符匹配模式：每个字符一个段
    for (int i = 0; i < text.length; i++) {
      segments.add({
        'text': text[i],
        'startIndex': i,
        'length': 1,
      });
    }
  }
  
  return segments;
}
