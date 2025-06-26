void main() {
  print('=== 测试搜索查询修复 ===');

  // 测试 _getSearchQuery 的逻辑
  testGetSearchQuery();
}

void testGetSearchQuery() {
  print('\n--- 测试 _getSearchQuery 方法逻辑 ---');

  // 模拟测试数据
  final testCases = [
    {
      'name': 'nature 秋 - 词匹配模式',
      'characters': 'nature 秋',
      'wordMatchingMode': true,
      'segments': [
        {'text': 'nature', 'startIndex': 0, 'length': 6},
        {'text': ' ', 'startIndex': 6, 'length': 1},
        {'text': '秋', 'startIndex': 7, 'length': 1},
      ],
      'tests': [
        {'selectedCharIndex': 0, 'expectedQuery': 'nature'}, // 选择 n
        {'selectedCharIndex': 3, 'expectedQuery': 'nature'}, // 选择 u
        {'selectedCharIndex': 5, 'expectedQuery': 'nature'}, // 选择 e
        {'selectedCharIndex': 6, 'expectedQuery': ' '}, // 选择空格
        {'selectedCharIndex': 7, 'expectedQuery': '秋'}, // 选择秋
      ]
    },
    {
      'name': 'na 秋 - 词匹配模式',
      'characters': 'na 秋',
      'wordMatchingMode': true,
      'segments': [
        {'text': 'na', 'startIndex': 0, 'length': 2},
        {'text': ' ', 'startIndex': 2, 'length': 1},
        {'text': '秋', 'startIndex': 3, 'length': 1},
      ],
      'tests': [
        {'selectedCharIndex': 0, 'expectedQuery': 'na'}, // 选择 n
        {'selectedCharIndex': 1, 'expectedQuery': 'na'}, // 选择 a
        {'selectedCharIndex': 2, 'expectedQuery': ' '}, // 选择空格
        {'selectedCharIndex': 3, 'expectedQuery': '秋'}, // 选择秋
      ]
    },
    {
      'name': 'nature 秋 - 字符匹配模式',
      'characters': 'nature 秋',
      'wordMatchingMode': false,
      'segments': [
        {'text': 'n', 'startIndex': 0, 'length': 1},
        {'text': 'a', 'startIndex': 1, 'length': 1},
        {'text': 't', 'startIndex': 2, 'length': 1},
        {'text': 'u', 'startIndex': 3, 'length': 1},
        {'text': 'r', 'startIndex': 4, 'length': 1},
        {'text': 'e', 'startIndex': 5, 'length': 1},
        {'text': ' ', 'startIndex': 6, 'length': 1},
        {'text': '秋', 'startIndex': 7, 'length': 1},
      ],
      'tests': [
        {'selectedCharIndex': 0, 'expectedQuery': 'n'},
        {'selectedCharIndex': 3, 'expectedQuery': 'u'},
        {'selectedCharIndex': 7, 'expectedQuery': '秋'},
      ]
    }
  ];

  for (final testCase in testCases) {
    print('\n${testCase['name']}:');

    final characters = testCase['characters'] as String;
    final wordMatchingMode = testCase['wordMatchingMode'] as bool;
    final segments = testCase['segments'] as List<Map<String, dynamic>>;
    final tests = testCase['tests'] as List<Map<String, dynamic>>;

    for (final test in tests) {
      final selectedCharIndex = test['selectedCharIndex'] as int;
      final expectedQuery = test['expectedQuery'] as String;

      // 模拟 _getSearchQuery 的逻辑
      String actualQuery = '';

      if (characters.isEmpty || selectedCharIndex >= characters.length) {
        actualQuery = '';
      } else if (wordMatchingMode) {
        // 在词匹配模式下，查找包含选中字符的segment
        bool found = false;
        for (final segment in segments) {
          final startIndex = segment['startIndex'] as int;
          final length = segment['length'] as int;
          final endIndex = startIndex + length - 1;

          if (selectedCharIndex >= startIndex &&
              selectedCharIndex <= endIndex) {
            actualQuery = segment['text'] as String;
            found = true;
            break;
          }
        }
        if (!found) {
          actualQuery = characters[selectedCharIndex];
        }
      } else {
        // 字符匹配模式，直接返回单个字符
        actualQuery = characters[selectedCharIndex];
      }

      final status = actualQuery == expectedQuery ? '✅' : '❌';
      print(
          '  选择索引 $selectedCharIndex (${characters[selectedCharIndex]}): 期望 "$expectedQuery", 实际 "$actualQuery" $status');
    }
  }
}
