import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 模拟字符搜索逻辑
  String query = 'na 秋';
  print('[QIU_DEBUG] 处理查询: "$query"');

  // 模拟按字符逐个搜索
  print('\n[QIU_DEBUG] ===== 按字符逐个搜索 =====');
  for (int i = 0; i < query.length; i++) {
    final char = query[i];

    // 跳过空白字符
    if (char.trim().isEmpty) {
      print('[QIU_DEBUG] 跳过空白字符，索引: $i');
      continue;
    }

    print('[QIU_DEBUG] 搜索字符: "$char" (索引: $i)');
    // 这里应该调用 _repository.search(char)
    // 对于"秋"字，应该能找到结果
  }

  // 模拟空格分隔处理
  print('\n[QIU_DEBUG] ===== 按空格分隔处理 =====');
  final spaceSeparatedParts =
      query.split(' ').where((part) => part.trim().isNotEmpty).toList();
  print('[QIU_DEBUG] 空格分隔结果: $spaceSeparatedParts');

  for (final part in spaceSeparatedParts) {
    final trimmedPart = part.trim();
    print('[QIU_DEBUG] 处理部分: "$trimmedPart"');
    // 这里先尝试精确匹配，再回退到字符匹配
  }
}
