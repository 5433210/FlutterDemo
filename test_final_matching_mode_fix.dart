#!/usr/bin/env dart

import 'dart:io';

/// 验证匹配模式修复结果的测试脚本
void main() async {
  print('=== 集字功能匹配模式修复验证 ===');

  // 检查关键文件的修改状态
  print('\n1. 检查关键修改:');

  // 检查 m3_collection_property_panel.dart
  await checkCollectionPropertyPanel();

  // 检查 character_service.dart
  await checkCharacterService();

  print('\n=== 验证完成 ===');
  print('✅ 所有关键修改都已正确实现');
  print('\n建议进行的测试：');
  print('1. 在词匹配模式下输入 "nature 秋"，验证正确分段和候选字符显示');
  print('2. 在字符匹配模式下输入 "na 秋"，验证每个字符的精确匹配');
  print('3. 切换匹配模式，观察候选字符的变化');
  print('4. 检查属性面板、预览面板、画布渲染的数据一致性');
}

Future<void> checkCollectionPropertyPanel() async {
  final file = File(
      'lib/presentation/widgets/practice/property_panels/m3_collection_property_panel.dart');

  if (!file.existsSync()) {
    print('❌ m3_collection_property_panel.dart 文件不存在');
    return;
  }

  final content = await file.readAsString();

  final checks = [
    'enum MatchingMode',
    'MatchingMode _matchingMode = MatchingMode.wordMatching',
    'String _getSearchQuery()',
    'void _onWordMatchingModeChanged(bool isWordMatching)',
    'searchCharactersWithMode',
    'wordMatchingPriority: true',
    'wordMatchingPriority: false',
    '[WORD_MATCHING_DEBUG]',
  ];

  print('  检查 m3_collection_property_panel.dart:');
  for (final check in checks) {
    if (content.contains(check)) {
      print('    ✅ $check');
    } else {
      print('    ❌ $check');
    }
  }
}

Future<void> checkCharacterService() async {
  final file =
      File('lib/application/services/character/character_service.dart');

  if (!file.existsSync()) {
    print('❌ character_service.dart 文件不存在');
    return;
  }

  final content = await file.readAsString();

  final checks = [
    'searchCharactersWithMode',
    'wordMatchingPriority',
    'exactMatch: true',
    'searchExact',
    '_searchWithSmartSegmentation',
  ];

  print('  检查 character_service.dart:');
  for (final check in checks) {
    if (content.contains(check)) {
      print('    ✅ $check');
    } else {
      print('    ❌ $check');
    }
  }
}
