import 'dart:convert';

/// 验证预览面板分段显示逻辑
void main() {
  print('=== 验证预览面板分段显示逻辑 ===');
  print('');

  // 模拟 "nature 秋" 的集字元素状态
  final content = {
    'characters': 'nature 秋',
    'wordMatchingPriority': true,
    'segments': [
      {'text': 'nature', 'startIndex': 0, 'length': 6},
      {'text': '秋', 'startIndex': 7, 'length': 1}
    ],
    'characterImages': {}
  };

  print('1. 集字元素状态:');
  print('   characters: "${content['characters']}"');
  print('   wordMatchingPriority: ${content['wordMatchingPriority']}');
  print('   segments: ${jsonEncode(content['segments'])}');
  print('');

  // 模拟预览面板的构建逻辑
  final characters = content['characters'] as String? ?? '';
  final wordMatchingMode = content['wordMatchingPriority'] as bool? ?? false;
  final segments = content['segments'] as List<dynamic>? ?? [];

  print('2. 预览面板解析:');
  print('   characters: "$characters"');
  print('   wordMatchingMode: $wordMatchingMode');
  print('   segments count: ${segments.length}');
  print('');

  // 模拟 _buildPreviewItems 方法
  List<Map<String, dynamic>> previewItems = [];

  if (wordMatchingMode && segments.isNotEmpty) {
    print('3. 词匹配模式 - 构建预览项:');

    for (int segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
      final segment = segments[segmentIndex] as Map<String, dynamic>;
      final text = segment['text'] as String;
      final startIndex = segment['startIndex'] as int;

      print('   分段 $segmentIndex:');
      print('     text: "$text"');
      print('     startIndex: $startIndex');
      print('     length: ${text.length}');

      if (text.length == 1) {
        // 单字符 - 显示字符图像
        previewItems.add({
          'type': 'character',
          'index': startIndex,
          'text': text,
          'widget': 'CharacterTile'
        });
        print('     → 生成 CharacterTile');
      } else {
        // 多字符 - 显示分段
        previewItems.add({
          'type': 'segment',
          'segmentIndex': segmentIndex,
          'text': text,
          'startIndex': startIndex,
          'widget': 'SegmentTile'
        });
        print('     → 生成 SegmentTile');
      }
      print('');
    }
  } else {
    print('3. 字符匹配模式 - 逐个字符:');
    for (int i = 0; i < characters.length; i++) {
      final char = characters[i];
      previewItems.add({
        'type': 'character',
        'index': i,
        'text': char,
        'widget': 'CharacterTile'
      });
      print('   字符 $i: "$char" → CharacterTile');
    }
  }

  print('4. 最终预览项列表:');
  for (int i = 0; i < previewItems.length; i++) {
    final item = previewItems[i];
    print('   项目 $i: ${item['widget']} - "${item['text']}"');
  }
  print('');

  // 验证期望结果
  print('5. 验证结果:');
  if (previewItems.length == 2) {
    final item1 = previewItems[0];
    final item2 = previewItems[1];

    bool isCorrect = item1['widget'] == 'SegmentTile' &&
        item1['text'] == 'nature' &&
        item2['widget'] == 'CharacterTile' &&
        item2['text'] == '秋';

    if (isCorrect) {
      print('   ✅ 正确: "nature" 显示为 SegmentTile，"秋" 显示为 CharacterTile');
      print('   ✅ 预览面板应显示 2 个格子（不重复）');
    } else {
      print('   ❌ 错误: 预览项不符合预期');
      print('   期望: SegmentTile("nature") + CharacterTile("秋")');
      print(
          '   实际: ${item1['widget']}("${item1['text']}") + ${item2['widget']}("${item2['text']}")');
    }
  } else {
    print('   ❌ 错误: 预览项数量不正确');
    print('   期望: 2 个项目');
    print('   实际: ${previewItems.length} 个项目');
  }

  print('');
  print('=== 测试完成 ===');
}
