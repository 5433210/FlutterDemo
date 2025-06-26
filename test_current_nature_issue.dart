import 'dart:io';

void main() {
  print('=== 检查"nature 秋"分段问题 ===\n');

  // 模拟词匹配模式下的分段逻辑
  String content = 'nature 秋';
  bool wordMatchingMode = true;

  print('输入内容: "$content"');
  print('词匹配模式: $wordMatchingMode');
  print('');

  // 1. 检查分段逻辑
  List<Map<String, dynamic>> segments = _simulateSegmentation(content);
  print('分段结果:');
  for (int i = 0; i < segments.length; i++) {
    var segment = segments[i];
    print(
        '  段 $i: "${segment['text']}" (索引: ${segment['startIndex']}, 长度: ${segment['length']})');
  }
  print('');

  // 2. 检查格子数量
  int expectedGrids = segments.length; // 应该是2个格子
  print('期望格子数: $expectedGrids');
  print('');

  // 3. 检查每个格子的内容
  print('格子内容分配:');
  for (int i = 0; i < segments.length; i++) {
    var segment = segments[i];
    print('  格子 $i: "${segment['text']}"');
  }
  print('');

  // 4. 验证是否正确
  bool isCorrect = segments.length == 2 &&
      segments[0]['text'] == 'nature' &&
      segments[1]['text'] == '秋';

  print('验证结果: ${isCorrect ? "✅ 正确" : "❌ 错误"}');

  if (!isCorrect) {
    print('\n问题分析:');
    if (segments.length != 2) {
      print('- 分段数量错误，期望2个，实际${segments.length}个');
    }
    if (segments.isNotEmpty && segments[0]['text'] != 'nature') {
      print('- 第一段内容错误，期望"nature"，实际"${segments[0]['text']}"');
    }
    if (segments.length > 1 && segments[1]['text'] != '秋') {
      print('- 第二段内容错误，期望"秋"，实际"${segments[1]['text']}"');
    }
  }
}

List<Map<String, dynamic>> _simulateSegmentation(String content) {
  // 模拟CharacterService中的分段逻辑
  List<Map<String, dynamic>> segments = [];

  // 简单的英文单词和中文字符分段
  List<String> parts = [];
  String currentPart = '';
  bool inEnglishWord = false;

  for (int i = 0; i < content.length; i++) {
    String char = content[i];

    if (char == ' ') {
      if (currentPart.isNotEmpty) {
        parts.add(currentPart);
        currentPart = '';
      }
      inEnglishWord = false;
      continue;
    }

    bool isEnglish = RegExp(r'[a-zA-Z]').hasMatch(char);

    if (isEnglish) {
      if (!inEnglishWord && currentPart.isNotEmpty) {
        // 从中文切换到英文，保存当前部分
        parts.add(currentPart);
        currentPart = '';
      }
      currentPart += char;
      inEnglishWord = true;
    } else {
      if (inEnglishWord && currentPart.isNotEmpty) {
        // 从英文切换到中文，保存当前部分
        parts.add(currentPart);
        currentPart = '';
      }
      currentPart += char;
      inEnglishWord = false;
    }
  }

  if (currentPart.isNotEmpty) {
    parts.add(currentPart);
  }

  // 转换为Map格式
  int startIndex = 0;
  for (String part in parts) {
    segments.add({
      'text': part,
      'startIndex': startIndex,
      'length': part.length,
    });
    startIndex += part.length + 1; // +1 for space
  }

  return segments;
}
