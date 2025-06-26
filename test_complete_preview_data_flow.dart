import 'dart:io';

void main() {
  print('=== 验证实际字符图像数据结构 ===\n');

  // 模拟一个完整的集字元素content，包含所有必要的数据
  Map<String, dynamic> mockContent = {
    'characters': 'nature 秋',
    'wordMatchingPriority': true,
    'segments': [
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
    ],
    'characterImages': {
      '0': {
        'characterId': 'nature_n_001',
        'type': 'square',
        'format': 'binary',
      },
      '1': {
        'characterId': 'nature_a_002',
        'type': 'square',
        'format': 'binary',
      },
      '2': {
        'characterId': 'nature_t_003',
        'type': 'square',
        'format': 'binary',
      },
      '3': {
        'characterId': 'nature_u_004',
        'type': 'square',
        'format': 'binary',
      },
      '4': {
        'characterId': 'nature_r_005',
        'type': 'square',
        'format': 'binary',
      },
      '5': {
        'characterId': 'nature_e_006',
        'type': 'square',
        'format': 'binary',
      },
      '7': {
        'characterId': 'autumn_qiu_007',
        'type': 'square',
        'format': 'binary',
      },
    },
  };

  print('完整模拟数据结构:');
  print('  characters: "${mockContent['characters']}"');
  print('  wordMatchingPriority: ${mockContent['wordMatchingPriority']}');
  print('  segments数量: ${(mockContent['segments'] as List).length}');
  print(
      '  characterImages数量: ${(mockContent['characterImages'] as Map).length}');
  print('');

  // 验证预览面板会如何处理这个数据
  String characters = mockContent['characters'];
  bool wordMatchingMode = mockContent['wordMatchingPriority'];
  List<dynamic> segments = mockContent['segments'];
  Map<String, dynamic> characterImages = mockContent['characterImages'];

  print('预览面板处理逻辑验证:');

  if (wordMatchingMode && segments.isNotEmpty) {
    print('  ✅ 进入词匹配模式');

    for (int segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
      final segment = segments[segmentIndex] as Map<String, dynamic>;
      final text = segment['text'] as String;
      final startIndex = segment['startIndex'] as int;

      print('  处理分段 $segmentIndex: "$text" (startIndex: $startIndex)');

      if (text.length == 1) {
        print('    → 单字符分段，使用 _buildCharacterTile');
        String charIndex = '$startIndex';
        bool hasImage = characterImages.containsKey(charIndex);
        print('      查找字符图像 索引$charIndex: ${hasImage ? "✅ 找到" : "❌ 未找到"}');
        if (hasImage) {
          var imageInfo = characterImages[charIndex];
          print('      图像信息: $imageInfo');
        }
      } else {
        print('    → 多字符分段，使用 _buildSegmentTile');
        print('      需要显示的字符图像:');
        for (int i = 0; i < text.length; i++) {
          String char = text[i];
          int charIndex = startIndex + i;
          String indexKey = '$charIndex';
          bool hasImage = characterImages.containsKey(indexKey);

          print(
              '        字符 "$char" (索引$charIndex): ${hasImage ? "✅ 有图像" : "❌ 无图像"}');
          if (hasImage) {
            var imageInfo = characterImages[indexKey];
            print('          characterId: ${imageInfo['characterId']}');
          }
        }
      }
    }
  } else {
    print('  ❌ 进入字符匹配模式');
  }

  print('');
  print('总结:');
  print('  预览面板应该显示: ${segments.length} 个格子');
  print('  第1个格子: "nature"，包含6个字符图像');
  print('  第2个格子: "秋"，包含1个字符图像');
  print('  总字符图像数: ${characterImages.length} 个');
}
