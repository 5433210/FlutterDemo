import 'dart:async';

/// 模拟测试"na"问题修复效果
void main() async {
  print('=== 测试"na"问题修复效果 ===\n');

  // 模拟修复前后的行为
  await testSearchBehavior();
}

/// 测试搜索行为
Future<void> testSearchBehavior() async {
  print('1. 模拟修复前的行为（错误）：');
  await simulateOldBehavior('na');

  print('\n2. 模拟修复后的行为（正确）：');
  await simulateNewBehavior('na');

  print('\n3. 测试其他词语：');
  final testCases = ['nature', 'n', 'a', 'nat', 'natur'];
  for (final testCase in testCases) {
    print('\n输入: "$testCase"');
    await simulateNewBehavior(testCase);
  }
}

/// 模拟修复前的错误行为
Future<void> simulateOldBehavior(String query) async {
  print('输入: "$query"');
  print('检测：单一语言（英文）');
  print('执行：直接调用字符逐个搜索');
  print('搜索："n" (LIKE查询) -> 匹配到 [nature, can, an, ...]');
  print('搜索："a" (LIKE查询) -> 匹配到 [nature, cat, car, ...]');
  print('结果：包含了不相关的"nature"等词语 ❌');
}

/// 模拟修复后的正确行为
Future<void> simulateNewBehavior(String query) async {
  print('输入: "$query"');
  print('检测：单一语言（英文）');
  print('执行：先尝试精确匹配');

  // 模拟数据库
  final exactMatches = getExactMatches(query);

  if (exactMatches.isNotEmpty) {
    print('精确匹配: character="$query" -> 找到 $exactMatches');
    print('结果：只返回精确匹配的结果 ✅');
  } else {
    print('精确匹配: character="$query" -> 无结果');
    print('回退：执行字符逐个搜索');
    final charMatches = getCharacterMatches(query);
    print('字符搜索结果: $charMatches');
    print('结果：返回字符匹配的结果（包含相关字符的词语）');
  }
}

/// 模拟精确匹配结果
List<String> getExactMatches(String query) {
  // 模拟数据库中的记录
  final database = [
    'a',
    'n',
    'na',
    'nat',
    'nature',
    'natural',
    '你',
    '好',
    '你好',
    '世界',
    '春',
    '秋'
  ];

  return database.where((record) => record == query).toList();
}

/// 模拟字符匹配结果
List<String> getCharacterMatches(String query) {
  final database = [
    'a',
    'n',
    'na',
    'nat',
    'nature',
    'natural',
    'can',
    'an',
    'cat',
    'car',
    '你',
    '好',
    '你好',
    '世界',
    '春',
    '秋'
  ];

  final results = <String>{};

  // 模拟对每个字符进行LIKE查询
  for (int i = 0; i < query.length; i++) {
    final char = query[i];
    final matches = database.where((record) => record.contains(char)).toList();
    results.addAll(matches);
  }

  return results.toList();
}
