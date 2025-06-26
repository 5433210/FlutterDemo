#!/usr/bin/env dart
// 测试词匹配模式下的分段数据流

void main() {
  print('=== 测试词匹配模式分段数据流 ===\n');

  // 模拟属性面板的分段逻辑
  testPropertyPanelSegmentation();

  // 模拟数据流传递
  testDataFlow();

  // 测试集字渲染器的分段处理
  testRendererSegments();
}

void testPropertyPanelSegmentation() {
  print('1. 属性面板分段逻辑测试');

  String characters = 'nature 秋';
  bool wordMatchingMode = true;

  List<String> segments = _generateSegments(characters, wordMatchingMode);

  print('输入字符: "$characters"');
  print('词匹配模式: $wordMatchingMode');
  print('生成分段: $segments');

  // 模拟字符匹配模式
  wordMatchingMode = false;
  segments = _generateSegments(characters, wordMatchingMode);
  print('字符匹配模式分段: $segments');
  print('');
}

List<String> _generateSegments(String characters, bool wordMatchingMode) {
  if (!wordMatchingMode) {
    // 字符匹配模式：每个字符单独一段
    return characters.split('');
  }

  // 词匹配模式：智能分段
  List<String> segments = [];
  String currentSegment = '';

  for (int i = 0; i < characters.length; i++) {
    String char = characters[i];

    if (char == ' ') {
      // 遇到空格，结束当前分段
      if (currentSegment.isNotEmpty) {
        segments.add(currentSegment);
        currentSegment = '';
      }
      // 空格单独作为一段
      segments.add(' ');
    } else if (_isLatinChar(char)) {
      // 拉丁字符：组成词
      currentSegment += char;
    } else {
      // 中文等其他字符：结束当前词段，单独成段
      if (currentSegment.isNotEmpty) {
        segments.add(currentSegment);
        currentSegment = '';
      }
      segments.add(char);
    }
  }

  // 处理最后的分段
  if (currentSegment.isNotEmpty) {
    segments.add(currentSegment);
  }

  return segments.where((s) => s.isNotEmpty).toList();
}

bool _isLatinChar(String char) {
  if (char.isEmpty) return false;
  int code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}

void testDataFlow() {
  print('2. 数据流传递测试');

  // 模拟属性面板更新content
  Map<String, dynamic> content = {
    'characters': 'nature 秋',
    'wordMatchingPriority': true,
    'fontSize': 24.0,
  };

  print('属性面板content: $content');

  // 检查是否包含分段信息
  bool hasSegments = content.containsKey('segments');
  print('是否包含segments: $hasSegments');

  if (!hasSegments) {
    print('❌ 问题发现：content中缺少segments信息！');

    // 模拟添加分段信息
    List<String> segments = _generateSegments(content['characters'] as String,
        content['wordMatchingPriority'] as bool);
    content['segments'] = segments;
    print('修复后的content: $content');
  }
  print('');
}

void testRendererSegments() {
  print('3. 渲染器分段处理测试');

  Map<String, dynamic> element = {
    'content': {
      'characters': 'nature 秋',
      'wordMatchingPriority': true,
      'segments': ['nature', ' ', '秋'],
      'fontSize': 24.0,
    }
  };

  print('元素数据: ${element['content']}');

  // 模拟ElementRenderers.buildCollectionElement的参数提取
  final content = element['content'] as Map<String, dynamic>;
  final characters = content['characters'] as String? ?? '';
  final segments = content['segments'] as List<dynamic>? ?? [];

  print('提取的字符: "$characters"');
  print('提取的分段: $segments');

  // 检查CollectionElementRenderer是否接收segments参数
  print('需要检查CollectionElementRenderer是否支持segments参数');
  print('');
}
