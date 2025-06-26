/// 测试实际元素数据结构中的"nature"预览问题
void main() {
  print('=== 测试实际元素数据结构 ===\n');

  // 模拟实际的element数据结构（类似于用户界面中的状态）
  final element = {
    'type': 'collection',
    'content': {
      'characters': 'nature',
      'wordMatchingPriority': true,
      'segments': [], // 可能问题在这里：segments数组为空
      'characterImages': {}
    }
  };

  print('模拟的element数据:');
  final content = element['content'] as Map<String, dynamic>;
  print('  characters: "${content['characters']}"');
  print('  wordMatchingPriority: ${content['wordMatchingPriority']}');
  print('  segments: ${content['segments']}');
  print('  segments.length: ${(content['segments'] as List).length}');
  print('');

  // 模拟预览面板的逻辑
  final characters = content['characters'] as String? ?? '';
  final wordMatchingMode = content['wordMatchingPriority'] as bool? ?? false;
  final segments = content['segments'] as List<dynamic>? ?? [];

  print('预览面板解析:');
  print('  characters: "$characters"');
  print('  wordMatchingMode: $wordMatchingMode');
  print('  segments.isEmpty: ${segments.isEmpty}');
  print('  segments.length: ${segments.length}');
  print('');

  // 预览面板构建逻辑的条件判断
  print('条件判断:');
  final condition1 = wordMatchingMode;
  final condition2 = segments.isNotEmpty;
  final finalCondition = condition1 && condition2;

  print('  wordMatchingMode: $condition1');
  print('  segments.isNotEmpty: $condition2');
  print('  wordMatchingMode && segments.isNotEmpty: $finalCondition');
  print('');

  // 模拟_buildPreviewItems方法
  final previewItems = <String>[];

  if (wordMatchingMode && segments.isNotEmpty) {
    print('进入词匹配模式分支:');
    // 这个分支不会执行，因为segments为空
    print('  → 构建分段tiles');
  } else {
    print('进入字符匹配模式分支:');
    print('  → 为每个字符构建CharacterTile');

    // 模拟字符匹配模式的逻辑
    for (int index = 0; index < characters.length; index++) {
      final char = characters[index];
      previewItems.add('CharacterTile("$char", index=$index)');
      print('    字符$index: "$char" → CharacterTile');
    }
  }

  print('');
  print('最终预览项目 (${previewItems.length}个):');
  for (int i = 0; i < previewItems.length; i++) {
    print('  ${previewItems[i]}');
  }

  print('');
  print('问题分析:');
  if (segments.isEmpty && wordMatchingMode) {
    print('❌ 发现问题: segments数组为空！');
    print('   虽然开启了词匹配模式，但segments没有生成');
    print('   导致条件判断失败，进入了字符匹配模式');
    print('   结果：为"nature"的每个字符(n,a,t,u,r,e)生成了6个CharacterTile');
  } else {
    print('✅ 数据结构正常');
  }

  print('');
  print('=== 测试完成 ===');
}
