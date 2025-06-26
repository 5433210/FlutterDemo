#!/usr/bin/env dart
// 调试"nature 秋"词匹配模式分段问题

void main() {
  print('=== 调试nature词匹配模式分段问题 ===\n');

  // 测试属性面板分段逻辑
  testPropertyPanelSegmentation();

  // 测试数据传递
  testDataTransfer();

  // 测试渲染器逻辑
  testRendererLogic();
}

void testPropertyPanelSegmentation() {
  print('1. 属性面板分段逻辑测试');

  String characters = 'nature 秋';
  bool wordMatchingMode = true;

  // 模拟属性面板的_generateSegments方法
  List<Map<String, dynamic>> segments =
      _generateSegments(characters, wordMatchingMode);

  print('输入字符: "$characters"');
  print('词匹配模式: $wordMatchingMode');
  print('生成分段: $segments');
  print('分段数量: ${segments.length}');
  print('');

  // 验证每个分段
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    print('分段$i: $segment');
  }
  print('');
}

void testDataTransfer() {
  print('2. 数据传递测试');

  // 模拟content数据结构
  Map<String, dynamic> content = {
    'characters': 'nature 秋',
    'wordMatchingPriority': true,
    'segments': _generateSegments('nature 秋', true),
    'fontSize': 24.0,
  };

  print('Content数据: $content');
  print('');

  // 模拟ElementRenderers的数据提取
  final characters = content['characters'] as String? ?? '';
  final segments = content['segments'] as List<dynamic>? ?? [];
  final wordMatchingMode = content['wordMatchingPriority'] as bool? ?? false;

  print('ElementRenderers提取的数据:');
  print('  characters: "$characters"');
  print('  wordMatchingMode: $wordMatchingMode');
  print('  segments: $segments');
  print('  segments类型: ${segments.runtimeType}');
  print('');

  // 检查characterImages数据结构
  Map<String, dynamic> characterImages = {
    'wordMatchingPriority': wordMatchingMode,
    'segments': segments,
  };

  print('characterImages数据: $characterImages');
  print('');
}

void testRendererLogic() {
  print('3. 渲染器逻辑测试');

  // 模拟AdvancedCollectionPainter的逻辑
  Map<String, dynamic> characterImages = {
    'wordMatchingPriority': true,
    'segments': _generateSegments('nature 秋', true),
  };

  // 测试_isWordMatchingMode
  bool wordMatchingMode =
      characterImages['wordMatchingPriority'] as bool? ?? false;
  print('获取词匹配模式: $wordMatchingMode');

  // 测试_getSegments
  final segmentsData = characterImages['segments'] as List<dynamic>? ?? [];
  List<Map<String, dynamic>> segments =
      segmentsData.cast<Map<String, dynamic>>();
  print('获取分段数据: $segments');
  print('分段数量: ${segments.length}');

  if (wordMatchingMode && segments.isNotEmpty) {
    print('✅ 应该进入分段渲染模式');
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final text = segment['text'] as String? ?? '';
      final startIndex = segment['startIndex'] as int? ?? 0;
      final length = segment['length'] as int? ?? 0;
      print('  分段$i: "$text" (位置:$startIndex, 长度:$length)');
    }
  } else {
    print('❌ 不会进入分段渲染模式');
  }
  print('');
}

// 复制属性面板的分段逻辑
List<Map<String, dynamic>> _generateSegments(
    String characters, bool wordMatchingMode) {
  if (!wordMatchingMode) {
    // 字符匹配模式：每个字符单独一段
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

  // 词匹配模式：智能分段
  List<Map<String, dynamic>> segments = [];
  String currentSegment = '';
  int currentStartIndex = 0;

  for (int i = 0; i < characters.length; i++) {
    String char = characters[i];

    if (char == ' ') {
      // 遇到空格，结束当前分段
      if (currentSegment.isNotEmpty) {
        segments.add({
          'text': currentSegment,
          'startIndex': currentStartIndex,
          'length': currentSegment.length,
        });
        currentSegment = '';
      }
      // 空格单独作为一段
      segments.add({
        'text': ' ',
        'startIndex': i,
        'length': 1,
      });
      currentStartIndex = i + 1;
    } else if (_isLatinChar(char)) {
      // 拉丁字符：组成词
      if (currentSegment.isEmpty) {
        currentStartIndex = i;
      }
      currentSegment += char;
    } else {
      // 中文等其他字符：结束当前词段，单独成段
      if (currentSegment.isNotEmpty) {
        segments.add({
          'text': currentSegment,
          'startIndex': currentStartIndex,
          'length': currentSegment.length,
        });
        currentSegment = '';
      }
      segments.add({
        'text': char,
        'startIndex': i,
        'length': 1,
      });
      currentStartIndex = i + 1;
    }
  }

  // 处理最后的分段
  if (currentSegment.isNotEmpty) {
    segments.add({
      'text': currentSegment,
      'startIndex': currentStartIndex,
      'length': currentSegment.length,
    });
  }

  return segments.where((s) => (s['text'] as String).isNotEmpty).toList();
}

bool _isLatinChar(String char) {
  if (char.isEmpty) return false;
  int code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}
