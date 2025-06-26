// 模拟数据库中的集字记录
final List<Map<String, dynamic>> mockCharacters = [
  // 英文单词
  {'id': '1', 'character': 'nature'},
  {'id': '2', 'character': 'natural'},
  {'id': '3', 'character': 'nation'},

  // 中文字符
  {'id': '4', 'character': '秋'},
  {'id': '5', 'character': '春'},
  {'id': '6', 'character': '夏'},

  // 单个英文字符
  {'id': '7', 'character': 'n'},
  {'id': '8', 'character': 'a'},
  {'id': '9', 'character': 't'},
  {'id': '10', 'character': 'u'},
  {'id': '11', 'character': 'r'},
  {'id': '12', 'character': 'e'},
];

/// 模拟精确搜索
List<Map<String, dynamic>> searchExact(String query) {
  return mockCharacters.where((char) => char['character'] == query).toList();
}

/// 模拟模糊搜索
List<Map<String, dynamic>> search(String query) {
  return mockCharacters
      .where((char) => char['character'].toString().contains(query))
      .toList();
}

/// 分割中英文混合文本
List<String> segmentMixedText(String text) {
  final segments = <String>[];
  StringBuffer currentSegment = StringBuffer();
  bool? isCurrentChinese;

  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    final isChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(char);
    final isEnglish = RegExp(r'[a-zA-Z]').hasMatch(char);

    if (isEnglish || isChinese) {
      // 如果当前字符类型与之前不同，结束当前分段
      if (isCurrentChinese != null && isCurrentChinese != isChinese) {
        if (currentSegment.isNotEmpty) {
          segments.add(currentSegment.toString());
          currentSegment.clear();
        }
      }

      currentSegment.write(char);
      isCurrentChinese = isChinese;
    } else {
      // 非字母和汉字的字符（如数字、标点等）
      if (currentSegment.isNotEmpty) {
        segments.add(currentSegment.toString());
        currentSegment.clear();
        isCurrentChinese = null;
      }

      // 对于空格等分隔符，直接跳过
      if (char.trim().isNotEmpty) {
        segments.add(char);
      }
    }
  }

  // 添加最后的分段
  if (currentSegment.isNotEmpty) {
    segments.add(currentSegment.toString());
  }

  return segments.where((s) => s.trim().isNotEmpty).toList();
}

/// 按字符逐个搜索
List<Map<String, dynamic>> searchByCharacters(String query) {
  final allResults = <Map<String, dynamic>>[];
  final addedIds = <String>{};

  print('[DEBUG] 开始字符逐个搜索: query="$query", queryLength=${query.length}');

  // 对每个字符进行搜索
  for (int i = 0; i < query.length; i++) {
    final char = query[i];

    // 跳过空白字符
    if (char.trim().isEmpty) continue;

    print('[DEBUG] 搜索单个字符: char="$char", index=$i');
    final results = search(char);

    print('[DEBUG] 单个字符搜索结果: char="$char", resultCount=${results.length}');

    // 去重添加结果
    for (final result in results) {
      if (!addedIds.contains(result['id'])) {
        allResults.add(result);
        addedIds.add(result['id']);
      }
    }
  }

  print(
      '[DEBUG] 字符搜索完成: query="$query", totalResults=${allResults.length}, uniqueResults=${addedIds.length}');

  return allResults;
}

/// 智能分词搜索 - 处理混合词语的情况
List<Map<String, dynamic>> searchWithSmartSegmentation(String query) {
  final allResults = <Map<String, dynamic>>[];
  final addedIds = <String>{};

  print('[DEBUG] 开始智能分词搜索: query="$query", queryLength=${query.length}');

  // 先按空格分割，处理明确的词边界
  final spaceSeparatedParts =
      query.split(' ').where((part) => part.trim().isNotEmpty).toList();

  if (spaceSeparatedParts.length > 1) {
    print(
        '[DEBUG] 检测到空格分隔的词语: parts=$spaceSeparatedParts, count=${spaceSeparatedParts.length}');

    // 对每个空格分隔的部分进行词匹配
    for (final part in spaceSeparatedParts) {
      final trimmedPart = part.trim();
      if (trimmedPart.isEmpty) continue;

      // 先尝试精确匹配这个部分
      final exactResults = searchExact(trimmedPart);
      print(
          '[DEBUG] 部分精确匹配: part="$trimmedPart", resultCount=${exactResults.length}');

      // 如果精确匹配有结果，添加到结果中
      if (exactResults.isNotEmpty) {
        for (final result in exactResults) {
          if (!addedIds.contains(result['id'])) {
            allResults.add(result);
            addedIds.add(result['id']);
          }
        }
      } else {
        // 如果精确匹配无结果，对这个部分进行字符匹配
        print('[DEBUG] 部分精确匹配无结果，进行字符匹配: part="$trimmedPart"');
        final charResults = searchByCharacters(trimmedPart);
        for (final result in charResults) {
          if (!addedIds.contains(result['id'])) {
            allResults.add(result);
            addedIds.add(result['id']);
          }
        }
      }
    }
  } else {
    // 没有空格分隔，尝试其他分词策略
    print('[DEBUG] 单一词语，尝试其他分词策略');

    // 检测是否有中英文混合
    final hasChinese = RegExp(r'[\u4e00-\u9fff]').hasMatch(query);
    final hasEnglish = RegExp(r'[a-zA-Z]').hasMatch(query);

    if (hasChinese && hasEnglish) {
      print('[DEBUG] 检测到中英文混合，进行智能分割');
      final segments = segmentMixedText(query);

      for (final segment in segments) {
        if (segment.trim().isEmpty) continue;

        // 对每个分段先尝试精确匹配
        final exactResults = searchExact(segment);
        if (exactResults.isNotEmpty) {
          for (final result in exactResults) {
            if (!addedIds.contains(result['id'])) {
              allResults.add(result);
              addedIds.add(result['id']);
            }
          }
        } else {
          // 精确匹配无结果，进行字符匹配
          final charResults = searchByCharacters(segment);
          for (final result in charResults) {
            if (!addedIds.contains(result['id'])) {
              allResults.add(result);
              addedIds.add(result['id']);
            }
          }
        }
      }
    } else {
      // 单一语言，先尝试精确匹配，再回退到字符匹配
      print('[DEBUG] 单一语言，先尝试精确匹配: query="$query"');

      // 先尝试精确匹配整个查询词
      final exactResults = searchExact(query);
      print(
          '[DEBUG] 单一语言精确匹配结果: query="$query", resultCount=${exactResults.length}');

      if (exactResults.isNotEmpty) {
        // 精确匹配有结果，使用精确匹配的结果
        print(
            '[DEBUG] 使用精确匹配结果: query="$query", resultCount=${exactResults.length}');
        for (final result in exactResults) {
          if (!addedIds.contains(result['id'])) {
            allResults.add(result);
            addedIds.add(result['id']);
          }
        }
      } else {
        // 精确匹配无结果，回退到字符匹配
        print('[DEBUG] 精确匹配无结果，回退到字符匹配: query="$query"');
        final charResults = searchByCharacters(query);
        allResults.addAll(charResults);
      }
    }
  }

  print(
      '[DEBUG] 智能分词搜索完成: query="$query", totalResults=${allResults.length}, uniqueResults=${addedIds.length}');

  return allResults;
}

/// 智能搜索字符 - 词匹配优先，字符匹配回退
List<Map<String, dynamic>> searchCharactersWithMode(String query,
    {bool wordMatchingPriority = true}) {
  print('[DEBUG] === 开始智能搜索 ===');
  print('[DEBUG] query="$query", wordMatchingPriority=$wordMatchingPriority');

  if (query.trim().isEmpty) return [];

  List<Map<String, dynamic>> characters = [];

  if (wordMatchingPriority && query.length > 1) {
    // 词匹配优先模式：先尝试精确匹配（查找字符字段精确等于查询词的记录）
    print('[DEBUG] 尝试精确匹配: query="$query"');
    characters = searchExact(query);

    print('[DEBUG] 精确匹配结果: query="$query", resultCount=${characters.length}');
    if (characters.isNotEmpty) {
      print(
          '[DEBUG] 精确匹配结果详情: ${characters.map((c) => c['character']).toList()}');
    }

    // 如果没有精确匹配结果，尝试智能分词搜索
    if (characters.isEmpty) {
      print('[DEBUG] 精确匹配无结果，尝试智能分词搜索');
      characters = searchWithSmartSegmentation(query);
    }
  } else {
    // 仅字符匹配模式
    print('[DEBUG] 使用字符匹配模式: query="$query"');
    characters = searchByCharacters(query);
  }

  print(
      '[DEBUG] 最终搜索结果: query="$query", mode=${wordMatchingPriority ? 'word_priority' : 'character_only'}, resultCount=${characters.length}');
  if (characters.isNotEmpty) {
    print('[DEBUG] 最终结果详情: ${characters.map((c) => c['character']).toList()}');
  }

  return characters;
}

void main() {
  print('=== 测试集字搜索逻辑 ===\n');

  // 测试案例1: "nature 秋" - nature应该有候选集字
  print('【测试案例1】: "nature 秋"');
  print('期望: nature能找到精确匹配，秋能找到精确匹配');
  final result1 =
      searchCharactersWithMode('nature 秋', wordMatchingPriority: true);
  print('实际结果: ${result1.map((c) => c['character']).toList()}');

  // 分别测试 nature 和 秋
  print('\n单独测试 nature:');
  final natureResult =
      searchCharactersWithMode('nature', wordMatchingPriority: true);
  print('nature结果: ${natureResult.map((c) => c['character']).toList()}');

  print('\n单独测试 秋:');
  final qiuResult = searchCharactersWithMode('秋', wordMatchingPriority: true);
  print('秋结果: ${qiuResult.map((c) => c['character']).toList()}');

  print('\n${'=' * 50}\n');

  // 测试案例2: "na 秋" - na应该回退到n、a两个字符的占位符
  print('【测试案例2】: "na 秋"');
  print('期望: na应该回退到n、a两个字符，秋能找到精确匹配');
  final result2 = searchCharactersWithMode('na 秋', wordMatchingPriority: true);
  print('实际结果: ${result2.map((c) => c['character']).toList()}');

  // 分别测试 na 和 秋
  print('\n单独测试 na:');
  final naResult = searchCharactersWithMode('na', wordMatchingPriority: true);
  print('na结果: ${naResult.map((c) => c['character']).toList()}');

  print('\n${'=' * 50}\n');

  // 附加测试：验证分段逻辑
  print('【附加测试】: 分段逻辑验证');
  final segments1 = segmentMixedText('nature 秋');
  print('分段 "nature 秋": $segments1');

  final segments2 = segmentMixedText('na 秋');
  print('分段 "na 秋": $segments2');

  print('\n数据库中的集字记录:');
  for (final char in mockCharacters) {
    print('  ${char['id']}: "${char['character']}"');
  }
}
