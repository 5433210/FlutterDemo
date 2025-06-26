import 'dart:io';

void main() {
  print('=== 检查字符图像索引映射问题 ===\n');

  String content = 'nature 秋';
  print('输入内容: "$content"');
  print('字符长度: ${content.length}');
  print('');

  // 1. 模拟原始字符索引映射
  print('原始字符索引映射:');
  for (int i = 0; i < content.length; i++) {
    String char = content[i];
    print('  索引 $i: "$char" ${char == ' ' ? '(空格)' : ''}');
  }
  print('');

  // 2. 模拟分段
  List<Map<String, dynamic>> segments = [
    {'text': 'nature', 'startIndex': 0, 'length': 6},
    {'text': '秋', 'startIndex': 7, 'length': 1},
  ];

  print('分段信息:');
  for (int i = 0; i < segments.length; i++) {
    var segment = segments[i];
    print(
        '  分段 $i: "${segment['text']}" (索引: ${segment['startIndex']}-${segment['startIndex'] + segment['length'] - 1})');
  }
  print('');

  // 3. 模拟字符图像映射（假设我们有0-7的图像数据）
  Map<String, Map<String, dynamic>> characterImages = {};
  for (int i = 0; i < content.length; i++) {
    if (content[i] != ' ') {
      // 跳过空格
      characterImages['$i'] = {
        'characterId': 'char_${content[i]}_$i',
        'type': 'square',
        'format': 'binary',
      };
    }
  }

  print('模拟字符图像映射:');
  characterImages.forEach((key, value) {
    print('  索引 $key: characterId="${value['characterId']}"');
  });
  print('');

  // 4. 验证分段中每个字符的图像查找
  print('分段字符图像查找验证:');
  for (int segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
    var segment = segments[segmentIndex];
    String segmentText = segment['text'];
    int startIndex = segment['startIndex'];

    print('  分段 $segmentIndex ("$segmentText"):');
    for (int i = 0; i < segmentText.length; i++) {
      int charIndex = startIndex + i;
      String char = segmentText[i];
      bool hasImage = characterImages.containsKey('$charIndex');

      print('    字符 "$char" (索引: $charIndex): ${hasImage ? "✅ 有图像" : "❌ 无图像"}');
      if (hasImage) {
        print('      图像ID: ${characterImages['$charIndex']!['characterId']}');
      }
    }
  }
  print('');

  // 5. 检查是否遗漏了某些索引
  print('索引覆盖检查:');
  Set<int> coveredIndices = {};
  for (var segment in segments) {
    int startIndex = segment['startIndex'];
    int length = segment['length'];
    for (int i = 0; i < length; i++) {
      coveredIndices.add(startIndex + i);
    }
  }

  for (int i = 0; i < content.length; i++) {
    bool covered = coveredIndices.contains(i);
    String char = content[i];
    print('  索引 $i ("$char"): ${covered ? "✅ 被分段覆盖" : "❌ 未被覆盖"}');
  }
}
