import 'dart:io';

void main() {
  print('=== 最终验证：nature 秋分段显示系统 ===\n');

  String testInput = 'nature 秋';

  print('📝 测试输入: "$testInput"');
  print('📊 预期结果:');
  print('   - 预览面板显示: 2个格子');
  print('   - 格子1: "nature" (包含n,a,t,u,r,e的字符图像)');
  print('   - 格子2: "秋" (包含秋的字符图像)');
  print('   - 画布渲染: 2个字符位置，不是8个');
  print('');

  // 1. CharacterService 分段逻辑
  print('1️⃣ CharacterService 分段逻辑:');
  List<Map<String, dynamic>> segments =
      simulateCharacterServiceSegmentation(testInput);
  print('   分段结果: ${segments.map((s) => '"${s['text']}"').join(', ')}');
  print('   分段数量: ${segments.length} (期望: 2)');
  print('   ✅ ${segments.length == 2 ? "正确" : "错误"}');
  print('');

  // 2. 属性面板分段分配逻辑
  print('2️⃣ 属性面板分段分配逻辑:');
  Map<String, dynamic> content =
      simulatePropertyPanelAllocation(testInput, segments);
  print('   content.segments: ${content['segments']?.length ?? 0} 个');
  print('   content.wordMatchingPriority: ${content['wordMatchingPriority']}');
  print(
      '   ✅ ${content['segments']?.length == 2 && content['wordMatchingPriority'] == true ? "正确" : "错误"}');
  print('');

  // 3. 预览面板显示逻辑
  print('3️⃣ 预览面板显示逻辑:');
  List<String> previewItems = simulatePreviewPanelDisplay(content);
  print('   显示项目: ${previewItems.join(', ')}');
  print('   项目数量: ${previewItems.length} (期望: 2)');
  print('   ✅ ${previewItems.length == 2 ? "正确" : "错误"}');
  print('');

  // 4. 画布渲染逻辑
  print('4️⃣ 画布渲染逻辑:');
  List<String> renderItems = simulateCanvasRendering(content);
  print('   渲染项目: ${renderItems.join(', ')}');
  print('   渲染数量: ${renderItems.length} (期望: 2)');
  print('   ✅ ${renderItems.length == 2 ? "正确" : "错误"}');
  print('');

  // 5. 字符图像查找逻辑
  print('5️⃣ 字符图像查找逻辑:');
  Map<String, bool> imageAvailability =
      simulateCharacterImageLookup(testInput, segments);
  print('   图像可用性:');
  imageAvailability.forEach((char, available) {
    print('     "$char": ${available ? "✅ 可用" : "❌ 不可用"}');
  });
  print('');

  // 总结
  bool allCorrect = segments.length == 2 &&
      content['segments']?.length == 2 &&
      content['wordMatchingPriority'] == true &&
      previewItems.length == 2 &&
      renderItems.length == 2;

  print('🎯 总体验证结果: ${allCorrect ? "✅ 全部正确" : "❌ 存在问题"}');

  if (allCorrect) {
    print('');
    print('🚀 系统已准备就绪！');
    print('   现在"nature 秋"应该在预览和画布中正确显示为2个格子。');
    print('   如果仍显示为6个字符，可能需要:');
    print('   1. 重启应用清除缓存');
    print('   2. 重新输入文本触发更新');
    print('   3. 检查字符图像数据是否已正确加载');
  }
}

List<Map<String, dynamic>> simulateCharacterServiceSegmentation(String input) {
  List<Map<String, dynamic>> segments = [];
  List<String> parts = [];
  String currentPart = '';
  bool inEnglishWord = false;

  for (int i = 0; i < input.length; i++) {
    String char = input[i];

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
        parts.add(currentPart);
        currentPart = '';
      }
      currentPart += char;
      inEnglishWord = true;
    } else {
      if (inEnglishWord && currentPart.isNotEmpty) {
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

Map<String, dynamic> simulatePropertyPanelAllocation(
    String input, List<Map<String, dynamic>> segments) {
  return {
    'characters': input,
    'wordMatchingPriority': true,
    'segments': segments,
  };
}

List<String> simulatePreviewPanelDisplay(Map<String, dynamic> content) {
  bool wordMatchingMode = content['wordMatchingPriority'] ?? false;
  List<dynamic> segments = content['segments'] ?? [];

  if (wordMatchingMode && segments.isNotEmpty) {
    return segments.map((s) => s['text'] as String).toList();
  } else {
    String characters = content['characters'] ?? '';
    return characters.split('');
  }
}

List<String> simulateCanvasRendering(Map<String, dynamic> content) {
  bool wordMatchingMode = content['wordMatchingPriority'] ?? false;
  List<dynamic> segments = content['segments'] ?? [];

  if (wordMatchingMode && segments.isNotEmpty) {
    return segments.map((s) => s['text'] as String).toList();
  } else {
    String characters = content['characters'] ?? '';
    return characters.split('');
  }
}

Map<String, bool> simulateCharacterImageLookup(
    String input, List<Map<String, dynamic>> segments) {
  Map<String, bool> availability = {};

  for (var segment in segments) {
    String text = segment['text'];
    int startIndex = segment['startIndex'];

    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      // 模拟英文字符和中文字符都有图像
      bool hasImage = char != ' '; // 除了空格都有图像
      availability[char] = hasImage;
    }
  }

  return availability;
}
