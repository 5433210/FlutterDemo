/// 测试单独输入"nature"的分段逻辑
void main() {
  print('=== 测试单独"nature"的分段问题 ===\n');

  // 模拟用户只输入"nature"的情况
  const inputText = 'nature';
  const wordMatchingMode = true;

  print('输入: "$inputText"');
  print('词匹配模式: $wordMatchingMode');
  print('');

  // 模拟属性面板的分段生成逻辑
  final segments = _generateSegments(inputText, wordMatchingMode);

  print('生成的分段:');
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    print(
        '  分段$i: "${segment['text']}" (起始位置: ${segment['startIndex']}, 长度: ${segment['length']})');
  }
  print('');

  // 模拟预览面板构建逻辑
  print('预览面板构建逻辑:');
  final previewItems = <String>[];

  if (wordMatchingMode && segments.isNotEmpty) {
    for (int segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
      final segment = segments[segmentIndex];
      final text = segment['text'] as String;
      final startIndex = segment['startIndex'] as int;

      if (text.length == 1) {
        // 单字符 - CharacterTile
        previewItems.add('CharacterTile("$text", index=$startIndex)');
        print('  分段$segmentIndex: 单字符 "$text" → CharacterTile');
      } else {
        // 多字符 - SegmentTile
        previewItems.add('SegmentTile("$text", index=$startIndex)');
        print('  分段$segmentIndex: 词组 "$text" → SegmentTile');
      }
    }
  } else {
    // 字符模式：逐个字符
    for (int i = 0; i < inputText.length; i++) {
      final char = inputText[i];
      previewItems.add('CharacterTile("$char", index=$i)');
      print('  字符$i: "$char" → CharacterTile');
    }
  }

  print('');
  print('最终预览项目列表:');
  for (int i = 0; i < previewItems.length; i++) {
    print('  项目$i: ${previewItems[i]}');
  }

  print('');
  print('验证结果:');
  if (segments.length == 1 && segments[0]['text'] == 'nature') {
    print('✅ 分段正确: 只有一个"nature"分段');
  } else {
    print('❌ 分段错误: 预期1个分段，实际${segments.length}个分段');
  }

  if (previewItems.length == 1 &&
      previewItems[0].contains('SegmentTile("nature"')) {
    print('✅ 预览正确: 只有一个SegmentTile');
  } else {
    print('❌ 预览错误: 预期1个SegmentTile，实际${previewItems.length}个项目');
    for (int i = 0; i < previewItems.length; i++) {
      print('    ${previewItems[i]}');
    }
  }

  print('');
  print('=== 测试完成 ===');
}

/// 模拟属性面板的分段生成方法
List<Map<String, dynamic>> _generateSegments(
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
    } else if (_isLatinChar(char)) {
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

/// 检查是否为拉丁字符
bool _isLatinChar(String char) {
  int code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) || // A-Z
      (code >= 97 && code <= 122); // a-z
}
