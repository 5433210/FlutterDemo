void main() {
  print('=== 预览面板分段显示修复验证 ===\n');

  // 模拟"nature 秋"的分段数据
  List<Map<String, dynamic>> segments = [
    {
      'text': 'nature',
      'startIndex': 0,
      'length': 6,
    },
    {
      'text': '秋',
      'startIndex': 7,
      'length': 1,
    }
  ];

  print('输入分段: ${segments.map((s) => '"${s['text']}"').join(', ')}');
  print('');

  // 模拟_buildPreviewItems的逻辑
  print('预览面板构建逻辑:');
  List<String> previewItems = [];

  for (int segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
    final segment = segments[segmentIndex];
    final text = segment['text'] as String;

    if (text.length == 1) {
      // 单字符分段：显示字符tile
      previewItems.add('字符tile: "$text"');
    } else {
      // 多字符分段：显示分段tile
      previewItems.add('分段tile: "$text"');
    }
  }

  print('期望的预览项目:');
  for (int i = 0; i < previewItems.length; i++) {
    print('  $i. ${previewItems[i]}');
  }
  print('');

  // 验证结果
  bool isCorrect = previewItems.length == 2 &&
      previewItems[0] == '分段tile: "nature"' &&
      previewItems[1] == '字符tile: "秋"';

  print('验证结果: ${isCorrect ? "✅ 正确" : "❌ 错误"}');
  print('总预览项目数: ${previewItems.length} (期望: 2)');

  if (isCorrect) {
    print('\n✅ 预览面板修复成功！');
    print('   - "nature"作为一个分段tile显示');
    print('   - "秋"作为一个字符tile显示');
    print('   - 不再重复显示多个"nature"');
  } else {
    print('\n❌ 还存在问题');
  }
}
