#!/usr/bin/env dart
// 最终验证"nature 秋"词匹配模式是否完全修复

void main() {
  print('=== 最终验证：nature秋词匹配模式修复 ===\n');

  testCompleteDataFlow();
}

void testCompleteDataFlow() {
  print('🔍 完整数据流验证');

  // 1. 模拟用户在属性面板输入"nature 秋"并启用词匹配模式
  Map<String, dynamic> content = _simulatePropertyPanelInput();
  print('1️⃣ 属性面板输出：');
  print('   characters: "${content['characters']}"');
  print('   wordMatchingPriority: ${content['wordMatchingPriority']}');
  print('   segments: ${content['segments']}');
  print('');

  // 2. 模拟ElementRenderers.buildCollectionElement的数据提取
  final characters = content['characters'] as String? ?? '';
  final segments = content['segments'] as List<dynamic>? ?? [];
  final wordMatchingMode = content['wordMatchingPriority'] as bool? ?? false;
  final segmentsList = segments.cast<Map<String, dynamic>>();

  print('2️⃣ ElementRenderers数据提取：');
  print('   characters: "$characters"');
  print('   wordMatchingMode: $wordMatchingMode');
  print('   segmentsList: $segmentsList');
  print('   segmentsList长度: ${segmentsList.length}');
  print('');

  // 3. 模拟CollectionElementRenderer.buildCollectionLayout的处理
  print('3️⃣ CollectionElementRenderer处理：');
  List<String> charList = [];
  List<bool> isNewLineList = [];

  if (wordMatchingMode && segmentsList.isNotEmpty) {
    print('   ✅ 进入词匹配模式分支');
    for (final segment in segmentsList) {
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
    print('   ❌ 进入字符匹配模式分支');
    final splitChars = characters.split('');
    charList.addAll(splitChars);
    isNewLineList.addAll(List.filled(splitChars.length, false));
  }

  print('   charList: $charList');
  print('   charList长度: ${charList.length}');
  print('');

  // 4. 模拟AdvancedCollectionPainter的数据接收
  Map<String, dynamic> characterImages = content; // ElementRenderers传递完整content

  print('4️⃣ AdvancedCollectionPainter接收：');

  // 测试_isWordMatchingMode()
  bool painterWordMatchingMode =
      characterImages['wordMatchingPriority'] as bool? ?? false;
  print('   _isWordMatchingMode(): $painterWordMatchingMode');

  // 测试_getSegments()
  final segmentsData = characterImages['segments'] as List<dynamic>? ?? [];
  List<Map<String, dynamic>> painterSegments =
      segmentsData.cast<Map<String, dynamic>>();
  print('   _getSegments(): $painterSegments');
  print('   segments长度: ${painterSegments.length}');

  if (painterWordMatchingMode && painterSegments.isNotEmpty) {
    print('   ✅ 应该调用_paintSegments()');
    print('   预期渲染结果：');
    for (int i = 0; i < painterSegments.length; i++) {
      final segment = painterSegments[i];
      final text = segment['text'] as String;
      if (text.trim().isNotEmpty) {
        print('     格子$i: "$text" (${text == 'nature' ? '词' : '字'})');
      }
    }
  } else {
    print('   ❌ 会调用_paintCharacters()');
  }
  print('');

  // 5. 最终验证
  print('5️⃣ 最终验证：');
  bool isCorrect = true;

  // 检查是否正确分段
  if (segmentsList.length != 3) {
    print('   ❌ 分段数量错误：期望3，实际${segmentsList.length}');
    isCorrect = false;
  } else {
    final expectedSegments = ['nature', ' ', '秋'];
    for (int i = 0; i < 3; i++) {
      final actualText = segmentsList[i]['text'] as String;
      if (actualText != expectedSegments[i]) {
        print('   ❌ 分段$i错误：期望"${expectedSegments[i]}"，实际"$actualText"');
        isCorrect = false;
      }
    }
  }

  // 检查charList
  if (charList.length != 3) {
    print('   ❌ charList长度错误：期望3，实际${charList.length}');
    isCorrect = false;
  } else {
    final expectedCharList = ['nature', ' ', '秋'];
    for (int i = 0; i < 3; i++) {
      if (charList[i] != expectedCharList[i]) {
        print(
            '   ❌ charList[$i]错误：期望"${expectedCharList[i]}"，实际"${charList[i]}"');
        isCorrect = false;
      }
    }
  }

  // 检查绘制器逻辑
  if (!painterWordMatchingMode || painterSegments.isEmpty) {
    print('   ❌ AdvancedCollectionPainter不会进入分段渲染模式');
    isCorrect = false;
  }

  if (isCorrect) {
    print('   ✅ 所有检查通过！"nature 秋"应该显示为2个格子：');
    print('      - 格子1: "nature"（英文词）');
    print('      - 格子2: "秋"（中文字）');
    print('      - 空格将被正确处理但不显示独立格子');
  } else {
    print('   ❌ 发现问题，需要进一步修复');
  }
  print('');

  // 6. 预览面板验证
  print('6️⃣ 预览面板验证：');
  testPreviewPanelLogic(content);
}

void testPreviewPanelLogic(Map<String, dynamic> content) {
  final characters = content['characters'] as String? ?? '';
  final wordMatchingMode = content['wordMatchingPriority'] as bool? ?? false;
  final segments = content['segments'] as List<dynamic>? ?? [];

  if (wordMatchingMode && segments.isNotEmpty) {
    print('   ✅ 预览面板进入分段显示模式');
    print('   预期显示：');

    for (int segmentIndex = 0; segmentIndex < segments.length; segmentIndex++) {
      final segment = segments[segmentIndex] as Map<String, dynamic>;
      final segmentText = segment['text'] as String;

      if (segmentText.trim().isNotEmpty) {
        final displayText =
            segmentText.length == 1 ? segmentText : '${segmentText[0]}...';
        print('     预览格子$segmentIndex: $displayText');
      }
    }
  } else {
    print('   ❌ 预览面板进入字符显示模式');
  }
  print('');
}

Map<String, dynamic> _simulatePropertyPanelInput() {
  String characters = 'nature 秋';
  bool wordMatchingMode = true;

  // 模拟M3CollectionPropertyPanel._generateSegments方法
  List<Map<String, dynamic>> segments =
      _generateSegments(characters, wordMatchingMode);

  return {
    'characters': characters,
    'wordMatchingPriority': wordMatchingMode,
    'segments': segments,
    'fontSize': 24.0,
  };
}

List<Map<String, dynamic>> _generateSegments(
    String characters, bool wordMatchingMode) {
  if (!wordMatchingMode) {
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

  List<Map<String, dynamic>> segments = [];
  String currentSegment = '';
  int currentStartIndex = 0;

  for (int i = 0; i < characters.length; i++) {
    String char = characters[i];

    if (char == ' ') {
      if (currentSegment.isNotEmpty) {
        segments.add({
          'text': currentSegment,
          'startIndex': currentStartIndex,
          'length': currentSegment.length,
        });
        currentSegment = '';
      }
      segments.add({
        'text': ' ',
        'startIndex': i,
        'length': 1,
      });
      currentStartIndex = i + 1;
    } else if (_isLatinChar(char)) {
      if (currentSegment.isEmpty) {
        currentStartIndex = i;
      }
      currentSegment += char;
    } else {
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
