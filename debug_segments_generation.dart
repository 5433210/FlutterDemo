#!/usr/bin/env dart

/// 检查 segments 生成逻辑的调试脚本

void main() {
  print('=== Segments 生成逻辑调试 ===');

  // 模拟不同匹配模式下的 segments 生成
  const text = 'nature 秋';

  print('\n输入文本: "$text"');

  // 词匹配模式下期望的 segments
  print('\n=== 词匹配模式期望结果 ===');
  final wordSegments = generateWordMatchingSegments(text);
  print('词匹配 segments:');
  for (int i = 0; i < wordSegments.length; i++) {
    final segment = wordSegments[i];
    print('  [$i] $segment');
  }

  // 字符匹配模式下的 segments
  print('\n=== 字符匹配模式结果 ===');
  final charSegments = generateCharacterMatchingSegments(text);
  print('字符匹配 segments:');
  for (int i = 0; i < charSegments.length; i++) {
    final segment = charSegments[i];
    print('  [$i] $segment');
  }

  print('\n=== 问题分析 ===');
  print('🔍 从用户的日志看到 segments 是字符分段，但期望是词分段');
  print('🔍 这表明 segments 生成逻辑没有根据 wordMatchingMode 参数正确工作');
  print('🔍 需要检查 segments 在何处生成，以及如何传递匹配模式参数');

  print('\n=== 修复建议 ===');
  print('1. 找到 segments 生成的位置（可能在 M3ContentSettingsPanel 中）');
  print('2. 确保 segments 生成时考虑 wordMatchingMode 参数');
  print('3. 词匹配模式：智能分词（nature 作为一个段）');
  print('4. 字符匹配模式：单字符分段（每个字符一个段）');
}

/// 生成词匹配模式的 segments
List<Map<String, dynamic>> generateWordMatchingSegments(String text) {
  final segments = <Map<String, dynamic>>[];

  // 简单的词分割逻辑（实际应该更智能）
  final words = text.split(' ');
  int startIndex = 0;

  for (int i = 0; i < words.length; i++) {
    final word = words[i];

    if (word.isNotEmpty) {
      segments.add({
        'text': word,
        'startIndex': startIndex,
        'length': word.length,
      });
      startIndex += word.length;
    }

    // 添加空格（除了最后一个词）
    if (i < words.length - 1) {
      segments.add({
        'text': ' ',
        'startIndex': startIndex,
        'length': 1,
      });
      startIndex += 1;
    }
  }

  return segments;
}

/// 生成字符匹配模式的 segments
List<Map<String, dynamic>> generateCharacterMatchingSegments(String text) {
  final segments = <Map<String, dynamic>>[];

  for (int i = 0; i < text.length; i++) {
    segments.add({
      'text': text[i],
      'startIndex': i,
      'length': 1,
    });
  }

  return segments;
}
