/// 测试"na"被误识别为"nature"的问题
///
/// 分析点：
/// 1. _segmentMixedText如何处理"na"
/// 2. searchExact和search的区别
/// 3. 分词逻辑是否正确
void main() {
  print('=== 测试"na"输入分词问题 ===\n');

  // 测试分词算法
  testSegmentation();

  print('\n=== 问题分析 ===');
  analyzeIssue();
}

/// 测试分词算法模拟
void testSegmentation() {
  print('1. 测试分词算法：');

  final testCases = [
    'na',
    'nature',
    'nature 秋',
    'na秋',
    'nat',
    'natur',
    'n',
    'a',
  ];

  for (final testCase in testCases) {
    final segments = segmentMixedTextSimulation(testCase);
    print('输入: "$testCase" -> 分段: $segments');
  }
}

/// 模拟_segmentMixedText方法
List<String> segmentMixedTextSimulation(String text) {
  final segments = <String>[];
  StringBuffer currentSegment = StringBuffer();
  bool? isCurrentChinese;

  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(char);
    final isEnglish = RegExp(r'[a-zA-Z]').hasMatch(char);

    if (isEnglish || isChinese) {
      // 如果当前字符类型与之前不同，结束当前分段
      if (isCurrentChinese != null && isCurrentChinese != isChinese) {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment.toString());
          currentSegment.clear();
        }
      }

      currentSegment.write(char);
      isCurrentChinese = isChinese;
    } else {
      // 非字母和汉字的字符（如数字、标点等）
      if (currentSegment.isNotEmpty) {
        segments.add(currentSegment.toString());
        currentSegment.clear();
        isCurrentChinese = null;
      }

      // 对于空格等分隔符，直接跳过
      if (char.trim().isNotEmpty) {
        segments.add(char);
      }
    }
  }

  // 添加最后的分段
  if (currentSegment.isNotEmpty) {
    segments.add(currentSegment.toString());
  }

  return segments.where((s) => s.trim().isNotEmpty).toList();
}

/// 分析问题可能原因
void analyzeIssue() {
  print('可能的问题原因：');
  print('1. 如果输入"na"，分词后应该是["na"]');
  print('2. searchExact("na")应该只查找character字段精确等于"na"的记录');
  print('3. search("na")会使用LIKE查询，可能匹配到"nature"等包含"na"的记录');
  print('');

  print('关键检查点：');
  print('1. _searchWithSmartSegmentation中对单一英文词的处理逻辑');
  print('2. 是否在某个地方错误地调用了search而不是searchExact');
  print('3. 是否有其他扩展匹配逻辑');
  print('');

  print('建议的修复策略：');
  print('1. 在CharacterService中添加调试日志，跟踪"na"的处理流程');
  print('2. 确保词匹配模式下优先使用searchExact');
  print('3. 检查是否有fallback逻辑错误地扩展了搜索范围');
}
