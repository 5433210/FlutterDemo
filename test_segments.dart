#!/usr/bin/env dart

// 测试 segments 生成逻辑
void main() {
  print('=== Testing Segments Generation Logic ===');

  // Test cases
  final testCases = [
    'nature 秋',
    '秋天',
    'hello world',
    'A测试B',
    '中文 english 混合',
    '',
    'single',
    '单个字符',
  ];

  for (final testCase in testCases) {
    print('\nTesting: "$testCase"');

    // Character matching mode
    final charSegments = generateSegments(testCase, false);
    print('Character Mode: $charSegments');

    // Word matching mode
    final wordSegments = generateSegments(testCase, true);
    print('Word Mode: $wordSegments');
  }
}

/// Generate segments based on characters and matching mode (copied from the main code)
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

/// Check if character is Latin alphabet
bool isLatinChar(String char) {
  if (char.isEmpty) return false;
  int code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}
