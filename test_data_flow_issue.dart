import 'dart:io';

void main() {
  print('=== 检查数据流传递问题 ===\n');

  // 模拟属性面板产生的content
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
  };

  print('模拟属性面板content:');
  print('  characters: "${mockContent['characters']}"');
  print('  wordMatchingPriority: ${mockContent['wordMatchingPriority']}');
  print('  segments: ${mockContent['segments']}');
  print('');

  // 模拟element_renderers.dart传递给CollectionElementRenderer的characterImages
  var characterImages = mockContent; // 传递完整的content

  print('传递给CollectionElementRenderer的characterImages:');
  print('  类型: ${characterImages.runtimeType}');
  print('  包含segments: ${characterImages.containsKey('segments')}');

  if (characterImages.containsKey('segments')) {
    var segments = characterImages['segments'] as List<dynamic>;
    print('  segments数量: ${segments.length}');
    for (int i = 0; i < segments.length; i++) {
      var segment = segments[i] as Map<String, dynamic>;
      print('    段 $i: "${segment['text']}"');
    }
  }
  print('');

  // 模拟AdvancedCollectionPainter._getSegments()方法
  List<Map<String, dynamic>> extractedSegments = [];

  try {
    final segments = characterImages['segments'] as List<dynamic>? ?? [];
    extractedSegments = segments.cast<Map<String, dynamic>>();
  } catch (e) {
    print('提取分段信息时出错: $e');
  }

  print('AdvancedCollectionPainter提取的segments:');
  print('  数量: ${extractedSegments.length}');
  for (int i = 0; i < extractedSegments.length; i++) {
    var segment = extractedSegments[i];
    print(
        '    段 $i: "${segment['text']}" (startIndex: ${segment['startIndex']}, length: ${segment['length']})');
  }
  print('');

  // 模拟_isWordMatchingMode检查
  bool isWordMatchingMode = false;
  try {
    isWordMatchingMode =
        characterImages['wordMatchingPriority'] as bool? ?? false;
  } catch (e) {
    print('提取词匹配模式时出错: $e');
  }

  print('词匹配模式: $isWordMatchingMode');
  print('');

  // 验证渲染路径
  if (isWordMatchingMode && extractedSegments.isNotEmpty) {
    print('✅ 应该使用分段渲染模式');
    print('   格子数量: ${extractedSegments.length}');
    print(
        '   格子内容: ${extractedSegments.map((s) => '"${s['text']}"').join(', ')}');
  } else {
    print('❌ 使用字符渲染模式');
    print('   原因: 词匹配模式=$isWordMatchingMode, 分段数量=${extractedSegments.length}');
  }
}
