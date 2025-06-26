/// Test script for word matching functionality
void main() {
  print('=== 词匹配功能测试 ===');

  // Test text segmentation
  testTextSegmentation();

  // Test character assignment logic
  testCharacterAssignment();

  print('\n✅ 所有测试完成');
}

void testTextSegmentation() {
  print('\n--- 文本分段测试 ---');

  final testCases = [
    'nature 秋',
    'hello world',
    '中文测试',
    'mixed 中文 content',
    'a1b2c3',
    '春夏秋冬',
  ];

  for (final text in testCases) {
    final segments = parseTextSegments(text);
    print('输入: "$text"');
    print('分段:');
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      print(
          '  [$i] "${segment.text}" (${segment.startIndex}-${segment.startIndex + segment.text.length - 1}) ${segment.isChinese ? "中文" : "英文"}');
    }
    print('');
  }
}

void testCharacterAssignment() {
  print('\n--- 字符分配测试 ---');

  const text = 'nature 秋';
  final segments = parseTextSegments(text);

  print('输入文本: "$text"');
  print('字符索引分配:');

  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final segmentInfo = findSegmentForIndex(segments, i);
    print(
        '[$i] "$char" -> 分段: ${segmentInfo['segmentIndex']}, 段内容: "${segmentInfo['segmentText']}"');
  }
}

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
