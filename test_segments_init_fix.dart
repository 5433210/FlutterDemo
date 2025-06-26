/// 验证修复后的分段初始化逻辑
void main() {
  print('=== 验证分段初始化修复 ===\n');

  // 模拟修复前的问题场景
  print('模拟修复前的问题场景:');
  final elementBefore = {
    'type': 'collection',
    'content': {
      'characters': 'nature',
      'wordMatchingPriority': true,
      'segments': [], // 已存在但为空的segments
      'characterImages': {}
    }
  };

  final contentBefore = elementBefore['content'] as Map<String, dynamic>;
  final charactersBefore = contentBefore['characters'] as String? ?? '';
  final hasSegmentsKey = contentBefore.containsKey('segments');
  final segmentsEmpty = (contentBefore['segments'] as List).isEmpty;

  print('  characters: "$charactersBefore"');
  print('  有segments键: $hasSegmentsKey');
  print('  segments为空: $segmentsEmpty');
  print('  修复前的条件: !containsKey(segments) && characters.isNotEmpty');
  print('  条件判断结果: ${!hasSegmentsKey && charactersBefore.isNotEmpty}');
  print('  → 因为已有segments键，所以不会调用_updateSegments()');
  print('');

  // 模拟修复后的逻辑
  print('模拟修复后的逻辑:');
  print('  新条件: characters.isNotEmpty');
  print('  条件判断结果: ${charactersBefore.isNotEmpty}');
  print('  → 只要有characters就会调用_updateSegments()');
  print('');

  // 模拟_updateSegments()的执行
  print('模拟_updateSegments()执行:');
  final segments = _generateSegments(charactersBefore, true);
  print('  生成的segments:');
  for (int i = 0; i < segments.length; i++) {
    final segment = segments[i];
    print(
        '    分段$i: "${segment['text']}" (位置${segment['startIndex']}, 长度${segment['length']})');
  }

  // 模拟更新后的element状态
  final elementAfter = {
    'type': 'collection',
    'content': {
      'characters': 'nature',
      'wordMatchingPriority': true,
      'segments': segments, // 现在有正确的segments
      'characterImages': {}
    }
  };

  print('');
  print('更新后的element状态:');
  final contentAfter = elementAfter['content'] as Map<String, dynamic>;
  final segmentsAfter = contentAfter['segments'] as List<dynamic>;
  print('  segments.length: ${segmentsAfter.length}');
  print('  segments内容: ${segmentsAfter.map((s) => s['text']).join(', ')}');

  // 模拟预览面板的条件判断
  print('');
  print('预览面板条件判断:');
  final wordMatchingMode = contentAfter['wordMatchingPriority'] as bool;
  final segmentsNotEmpty = segmentsAfter.isNotEmpty;
  final finalCondition = wordMatchingMode && segmentsNotEmpty;

  print('  wordMatchingMode: $wordMatchingMode');
  print('  segments.isNotEmpty: $segmentsNotEmpty');
  print('  最终条件: $finalCondition');

  if (finalCondition) {
    print('  ✅ 进入词匹配模式分支');
    print('  → 生成1个SegmentTile("nature")');
  } else {
    print('  ❌ 进入字符匹配模式分支');
    print('  → 生成6个CharacterTile');
  }

  print('');
  print('=== 修复验证完成 ===');
}

/// 模拟分段生成方法
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
  int segmentStartIndex = 0;

  for (int i = 0; i < characters.length; i++) {
    String char = characters[i];

    if (char == ' ') {
      if (currentSegment.isNotEmpty) {
        segments.add({
          'text': currentSegment,
          'startIndex': segmentStartIndex,
          'length': currentSegment.length,
        });
        currentSegment = '';
      }
      segments.add({
        'text': ' ',
        'startIndex': i,
        'length': 1,
      });
      segmentStartIndex = i + 1;
    } else if (_isLatinChar(char)) {
      if (currentSegment.isEmpty) {
        segmentStartIndex = i;
      }
      currentSegment += char;
    } else {
      if (currentSegment.isNotEmpty) {
        segments.add({
          'text': currentSegment,
          'startIndex': segmentStartIndex,
          'length': currentSegment.length,
        });
        currentSegment = '';
      }
      segments.add({
        'text': char,
        'startIndex': i,
        'length': 1,
      });
      segmentStartIndex = i + 1;
    }
  }

  if (currentSegment.isNotEmpty) {
    segments.add({
      'text': currentSegment,
      'startIndex': segmentStartIndex,
      'length': currentSegment.length,
    });
  }

  return segments;
}

bool _isLatinChar(String char) {
  int code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
}
