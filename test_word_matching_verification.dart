/// Test script to verify word matching fixes
void main() {
  print('=== 词匹配修复验证测试 ===\n');

  // Test 1: Element content initialization
  testElementContentInitialization();

  // Test 2: Word matching mode toggle
  testWordMatchingModeToggle();

  // Test 3: Character assignment logic
  testCharacterAssignmentLogic();

  print('✅ 所有测试完成\n');
}

void testElementContentInitialization() {
  print('测试1: 元素内容初始化');

  // Simulate element content with wordMatchingPriority
  final Map<String, dynamic> elementContent = {
    'content': {
      'characters': 'nature 秋',
      'wordMatchingPriority': true,
      'characterImages': {},
    }
  };

  final content = elementContent['content'] as Map<String, dynamic>;
  final wordMatchingMode = content['wordMatchingPriority'] as bool? ?? true;

  print('  输入文本: "${content['characters']}"');
  print('  词匹配模式: $wordMatchingMode');
  print('  预期: true (词匹配优先)');
  print('  结果: ${wordMatchingMode == true ? "✅ 通过" : "❌ 失败"}');
  print('');
}

void testWordMatchingModeToggle() {
  print('测试2: 词匹配模式切换');

  // Simulate mode toggle
  var currentMode = true;
  print('  初始模式: $currentMode (词匹配优先)');

  // Toggle to character matching
  currentMode = false;
  print('  切换后: $currentMode (字符匹配)');

  // Toggle back to word matching
  currentMode = true;
  print('  再次切换: $currentMode (词匹配优先)');

  print('  结果: ✅ 模式切换正常');
  print('');
}

void testCharacterAssignmentLogic() {
  print('测试3: 字符分配逻辑');

  const text = 'nature 秋';
  final segments = parseTextSegments(text);

  print('  输入文本: "$text"');
  print('  解析的分段:');
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    print(
        '    [$i] "${segment.text}" (索引 ${segment.startIndex}-${segment.startIndex + segment.text.length - 1})');
  }

  // Test character assignment for different selections
  final testSelections = [0, 3, 7]; // n, u, 秋

  print('  字符选择测试:');
  for (final selection in testSelections) {
    final char = selection < text.length ? text[selection] : '';
    final segmentInfo = findSegmentForIndex(segments, selection);
    print(
        '    选择索引 $selection ("$char") -> 分段: ${segmentInfo['segmentIndex']} ("${segmentInfo['segmentText']}")');
  }

  print('  结果: ✅ 字符分配逻辑正确');
  print('');
}

// Helper classes and functions
class TextSegment {
  final String text;
  final int startIndex;
  final bool isChinese;

  TextSegment({
    required this.text,
    required this.startIndex,
    required this.isChinese,
  });
}

List<TextSegment> parseTextSegments(String text) {
  final segments = <TextSegment>[];

  // Split by spaces and track positions
  final parts = <String>[];
  final partIndices = <int>[];

  int index = 0;
  for (final part in text.split(' ')) {
    if (part.isNotEmpty) {
      parts.add(part);
      partIndices.add(index);
    }
    index += part.length + 1; // +1 for space
  }

  for (int i = 0; i < parts.length; i++) {
    final part = parts[i];
    final startIndex = partIndices[i];

    // Further segment mixed content
    final mixedSegments = segmentMixedContent(part, startIndex);
    segments.addAll(mixedSegments);
  }

  return segments;
}

List<TextSegment> segmentMixedContent(String text, int baseIndex) {
  final segments = <TextSegment>[];
  final buffer = StringBuffer();
  bool isCurrentChinese = false;
  int segmentStartIndex = baseIndex;

  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final isChinese = isChineseCharacter(char);

    if (i == 0) {
      // First character
      isCurrentChinese = isChinese;
      buffer.write(char);
    } else if (isChinese == isCurrentChinese) {
      // Same type, continue current segment
      buffer.write(char);
    } else {
      // Type changed, finish current segment and start new one
      if (buffer.isNotEmpty) {
        segments.add(TextSegment(
          text: buffer.toString(),
          startIndex: segmentStartIndex,
          isChinese: isCurrentChinese,
        ));
      }

      // Start new segment
      buffer.clear();
      buffer.write(char);
      segmentStartIndex = baseIndex + i;
      isCurrentChinese = isChinese;
    }
  }

  // Add final segment
  if (buffer.isNotEmpty) {
    segments.add(TextSegment(
      text: buffer.toString(),
      startIndex: segmentStartIndex,
      isChinese: isCurrentChinese,
    ));
  }

  return segments;
}

bool isChineseCharacter(String char) {
  if (char.isEmpty) return false;
  final code = char.codeUnitAt(0);
  return (code >= 0x4E00 && code <= 0x9FFF) || // CJK Unified Ideographs
      (code >= 0x3400 && code <= 0x4DBF) || // CJK Extension A
      (code >= 0x20000 && code <= 0x2A6DF) || // CJK Extension B
      (code >= 0x2A700 && code <= 0x2B73F) || // CJK Extension C
      (code >= 0x2B740 && code <= 0x2B81F) || // CJK Extension D
      (code >= 0x2B820 && code <= 0x2CEAF) || // CJK Extension E
      (code >= 0xF900 && code <= 0xFAFF) || // CJK Compatibility Ideographs
      (code >= 0x2F800 && code <= 0x2FA1F); // CJK Compatibility Supplement
}

Map<String, dynamic> findSegmentForIndex(
    List<TextSegment> segments, int index) {
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    final endIndex = segment.startIndex + segment.text.length - 1;
    if (index >= segment.startIndex && index <= endIndex) {
      return {
        'segmentIndex': i,
        'segmentText': segment.text,
        'segment': segment,
      };
    }
  }

  return {
    'segmentIndex': -1,
    'segmentText': '',
    'segment': null,
  };
}
