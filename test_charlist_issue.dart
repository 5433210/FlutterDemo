void main() {
  print('=== 检查CollectionElementRenderer的charList逻辑 ===\n');

  // 模拟输入参数
  String characters = 'nature 秋';
  bool wordMatchingMode = true;
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

  print('输入参数:');
  print('  characters: "$characters"');
  print('  wordMatchingMode: $wordMatchingMode');
  print('  segments: $segments');
  print('');

  // 模拟CollectionElementRenderer中的charList构建逻辑
  List<String> charList = [];
  List<bool> isNewLineList = [];

  bool isEmpty = characters.isEmpty;

  if (isEmpty) {
    charList.add(' ');
    isNewLineList.add(false);
  } else if (wordMatchingMode && segments.isNotEmpty) {
    // 词匹配模式：使用分段信息
    print('🔄 进入词匹配模式的charList构建逻辑');
    for (final segment in segments) {
      final text = segment['text'] as String;
      if (text == '\n') {
        isNewLineList.add(true);
        charList.add('\n');
      } else {
        charList.add(text);
        isNewLineList.add(false);
      }
    }
  } else {
    // 字符匹配模式：按行分割文本
    print('🔄 进入字符匹配模式的charList构建逻辑');
    final lines = characters.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineChars = line.split('').toList(); // 模拟characters.toList()
      charList.addAll(lineChars);

      isNewLineList.addAll(
          List.generate(lineChars.length, (index) => index == 0 && i > 0));

      if (i < lines.length - 1) {
        isNewLineList.add(true);
        charList.add('\n');
      }
    }
  }

  print('构建的charList:');
  for (int i = 0; i < charList.length; i++) {
    print('  [$i]: "${charList[i]}" (isNewLine: ${isNewLineList[i]})');
  }
  print('');

  print('期望的charList: ["nature", "秋"]');
  print('实际的charList: $charList');
  print('');

  bool isCorrect =
      charList.length == 2 && charList[0] == 'nature' && charList[1] == '秋';

  print('验证结果: ${isCorrect ? "✅ 正确" : "❌ 错误"}');

  if (!isCorrect) {
    print('\n问题分析:');
    print('- charList应该包含分段文本，而不是单个字符');
    print('- 这会导致AdvancedCollectionPainter收到错误的数据');
    print('- 进而导致画布渲染错误');
  }
}
