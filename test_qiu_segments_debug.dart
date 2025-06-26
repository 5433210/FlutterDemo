void main() {
  print('=== 秋字分段问题调试 ===');

  // 模拟分段生成逻辑
  List<Map<String, dynamic>> generateSegments(
      String characters, bool wordMatchingMode) {
    if (!wordMatchingMode) {
      // Character matching mode: each character is a separate segment
      List<Map<String, dynamic>> segments = [];
      for (int i = 0; i < characters.length; i++) {
        segments.add({
          'text': characters[i],
          'startIndex': i,
          'length': 1,
        });
      }
      return segments;
    }

    // Word matching mode: smart segmentation
    List<Map<String, dynamic>> segments = [];
    String currentSegment = '';
    int segmentStartIndex = 0;

    bool isLatinChar(String char) {
      int code = char.codeUnitAt(0);
      return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
    }

    for (int i = 0; i < characters.length; i++) {
      String char = characters[i];

      if (char == ' ') {
        // End current segment on space
        if (currentSegment.isNotEmpty) {
          segments.add({
            'text': currentSegment,
            'startIndex': segmentStartIndex,
            'length': currentSegment.length,
          });
          currentSegment = '';
        }
        // Space as separate segment
        segments.add({
          'text': ' ',
          'startIndex': i,
          'length': 1,
        });
        segmentStartIndex = i + 1;
      } else if (isLatinChar(char)) {
        // Latin characters: form words
        if (currentSegment.isEmpty) {
          segmentStartIndex = i;
        }
        currentSegment += char;
      } else {
        // Chinese and other characters: end current word, separate segment
        if (currentSegment.isNotEmpty) {
          segments.add({
            'text': currentSegment,
            'startIndex': segmentStartIndex,
            'length': currentSegment.length,
          });
          currentSegment = '';
        }
        segments.add({
          'text': char,
          'startIndex': i,
          'length': 1,
        });
        segmentStartIndex = i + 1;
      }
    }

    // Handle last segment
    if (currentSegment.isNotEmpty) {
      segments.add({
        'text': currentSegment,
        'startIndex': segmentStartIndex,
        'length': currentSegment.length,
      });
    }

    return segments;
  }

  // 测试各种输入
  final testCases = [
    'na',
    'na ',
    'na 秋',
    'nature',
    'nature 秋',
    'nature秋',
    '秋',
  ];

  for (final testCase in testCases) {
    print('\n=== 测试输入: "$testCase" ===');
    final segments = generateSegments(testCase, true);
    print('生成的分段数量: ${segments.length}');
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      print(
          '  分段 $i: text="${segment['text']}", startIndex=${segment['startIndex']}, length=${segment['length']}');
    }

    // 验证字符覆盖
    int totalLength = 0;
    for (final segment in segments) {
      totalLength += segment['length'] as int;
    }
    print('  总字符长度: $totalLength, 原始长度: ${testCase.length}');
    if (totalLength == testCase.length) {
      print('  ✅ 分段覆盖完整');
    } else {
      print('  ❌ 分段覆盖不完整');
    }

    // 重建字符串验证
    String rebuilt = '';
    for (final segment in segments) {
      rebuilt += segment['text'] as String;
    }
    if (rebuilt == testCase) {
      print('  ✅ 重建字符串正确');
    } else {
      print('  ❌ 重建字符串错误: "$rebuilt" vs "$testCase"');
    }
  }
}
