// 词匹配渲染验证脚本
// 验证分段渲染逻辑是否正确工作

void main() {
  print('=== 词匹配渲染逻辑验证 ===\n');

  // 测试用例1：中英文混合
  testWordMatchingRendering();
}

void testWordMatchingRendering() {
  print('测试1: 中英文混合 "nature 秋"');

  // 模拟content数据结构
  final content = {
    'characters': 'nature 秋',
    'wordMatchingMode': true,
    'segments': [
      {
        'text': 'nature',
        'startIndex': 0,
        'length': 6,
        'isChinese': false,
      },
      {
        'text': '秋',
        'startIndex': 7,
        'length': 1,
        'isChinese': true,
      }
    ],
    'characterImages': {
      '0': {'characterId': 'char_n', 'type': 'square-binary'},
      '1': {'characterId': 'char_n', 'type': 'square-binary'},
      '2': {'characterId': 'char_n', 'type': 'square-binary'},
      '3': {'characterId': 'char_n', 'type': 'square-binary'},
      '4': {'characterId': 'char_n', 'type': 'square-binary'},
      '5': {'characterId': 'char_n', 'type': 'square-binary'},
      '7': {'characterId': 'char_autumn', 'type': 'square-binary'},
    }
  };

  // 模拟字符位置（9个字符，包括空格）
  final positions = [
    CharacterPosition(
        char: 'n', x: 0, y: 0, size: 50, index: 0, originalIndex: 0),
    CharacterPosition(
        char: 'a', x: 55, y: 0, size: 50, index: 1, originalIndex: 1),
    CharacterPosition(
        char: 't', x: 110, y: 0, size: 50, index: 2, originalIndex: 2),
    CharacterPosition(
        char: 'u', x: 165, y: 0, size: 50, index: 3, originalIndex: 3),
    CharacterPosition(
        char: 'r', x: 220, y: 0, size: 50, index: 4, originalIndex: 4),
    CharacterPosition(
        char: 'e', x: 275, y: 0, size: 50, index: 5, originalIndex: 5),
    CharacterPosition(
        char: ' ', x: 330, y: 0, size: 50, index: 6, originalIndex: 6),
    CharacterPosition(
        char: '秋', x: 385, y: 0, size: 50, index: 7, originalIndex: 7),
  ];

  print('原始字符位置:');
  for (int i = 0; i < positions.length; i++) {
    final pos = positions[i];
    print(
        '  [$i] "${pos.char}" at (${pos.x}, ${pos.y}) originalIndex: ${pos.originalIndex}');
  }

  print('\n分段信息:');
  final segments = content['segments'] as List<Map<String, dynamic>>;
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    print(
        '  分段$i: "${segment['text']}" 起始索引: ${segment['startIndex']} 长度: ${segment['length']}');
  }

  print('\n词匹配模式渲染结果:');
  // 验证分段渲染逻辑
  for (final segment in segments) {
    final startIndex = segment['startIndex'] as int;
    final length = segment['length'] as int;
    final text = segment['text'] as String;

    // 找到该分段对应的字符位置
    final segmentPositions = positions.where((pos) {
      return pos.originalIndex >= startIndex &&
          pos.originalIndex < startIndex + length;
    }).toList();

    if (segmentPositions.isNotEmpty) {
      // 计算分段边界
      final bounds = calculateSegmentBounds(segmentPositions);
      print('  分段 "$text":');
      print(
          '    包含字符: ${segmentPositions.map((p) => '"${p.char}"').join(', ')}');
      print(
          '    边界区域: (${bounds.left}, ${bounds.top}) 到 (${bounds.right}, ${bounds.bottom})');
      print('    宽度: ${bounds.width}, 高度: ${bounds.height}');
      print('    -> 渲染为一个合并的格子，显示字符图像');
    }
  }

  print('\n结论:');
  print('- "nature"应该被渲染为一个合并的格子');
  print('- "秋"应该被渲染为一个单独的格子');
  print('- 空格不参与渲染');
  print('- 预览和画布应该显示2个格子而不是6个');
}

class CharacterPosition {
  final String char;
  final double x;
  final double y;
  final double size;
  final int index;
  final int originalIndex;

  CharacterPosition({
    required this.char,
    required this.x,
    required this.y,
    required this.size,
    required this.index,
    required this.originalIndex,
  });
}

class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  Rect.fromLTRB(this.left, this.top, this.right, this.bottom);

  double get width => right - left;
  double get height => bottom - top;
}

Rect calculateSegmentBounds(List<CharacterPosition> segmentPositions) {
  if (segmentPositions.isEmpty) {
    return Rect.fromLTRB(0, 0, 0, 0);
  }

  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;

  for (final pos in segmentPositions) {
    if (pos.x < minX) minX = pos.x;
    if (pos.y < minY) minY = pos.y;
    if (pos.x + pos.size > maxX) maxX = pos.x + pos.size;
    if (pos.y + pos.size > maxY) maxY = pos.y + pos.size;
  }

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}
