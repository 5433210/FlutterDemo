void main() {
  print('=== 当前元素调试脚本 ===');

  // 模拟 "nature" 的集字元素
  Map<String, dynamic> element = {
    'id': 'test-collection-element',
    'type': 'collection',
    'content': {
      'characters': 'nature',
      'wordMatchingPriority': true,
      'segments': [], // 模拟初始状态为空
    }
  };

  print('初始元素状态:');
  print('  characters: ${element['content']['characters']}');
  print(
      '  wordMatchingPriority: ${element['content']['wordMatchingPriority']}');
  print('  segments: ${element['content']['segments']}');

  // 模拟属性面板的 _generateSegments 方法
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
      int charCode = char.codeUnitAt(0);
      return (charCode >= 65 && charCode <= 90) || // A-Z
          (charCode >= 97 && charCode <= 122); // a-z
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

  // 生成分段
  final content = element['content'] as Map<String, dynamic>;
  final characters = content['characters'] as String;
  final wordMatchingMode = content['wordMatchingPriority'] as bool;

  List<Map<String, dynamic>> segments =
      generateSegments(characters, wordMatchingMode);

  print('\n生成的分段:');
  for (int i = 0; i < segments.length; i++) {
    print('  分段 $i: ${segments[i]}');
  }

  // 更新元素
  element['content']['segments'] = segments;

  print('\n更新后的元素状态:');
  print('  characters: ${element['content']['characters']}');
  print(
      '  wordMatchingPriority: ${element['content']['wordMatchingPriority']}');
  print('  segments: ${element['content']['segments']}');

  // 模拟预览面板的逻辑
  print('\n预览面板逻辑模拟:');
  final previewWordMatchingMode =
      content['wordMatchingPriority'] as bool? ?? false;
  final previewSegments = content['segments'] as List<dynamic>? ?? [];

  print('  预览面板读取到的 wordMatchingMode: $previewWordMatchingMode');
  print('  预览面板读取到的 segments: $previewSegments');

  if (previewWordMatchingMode && previewSegments.isNotEmpty) {
    print('  预览面板应该进入词匹配模式，显示 ${previewSegments.length} 个分段');
    for (int i = 0; i < previewSegments.length; i++) {
      final segment = previewSegments[i] as Map<String, dynamic>;
      final text = segment['text'] as String;
      if (text.length == 1) {
        print('    分段 $i: 单字符 "$text" -> 显示字符图像');
      } else {
        print('    分段 $i: 多字符词组 "$text" -> 显示分段Tile');
      }
    }
  } else {
    print('  预览面板进入字符匹配模式，显示 ${characters.length} 个字符');
    for (int i = 0; i < characters.length; i++) {
      print('    字符 $i: "${characters[i]}" -> 显示字符图像');
    }
  }
}
