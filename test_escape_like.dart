/// 测试 LIKE 操作符转义功能
void main() {
  print('=== SQLite LIKE 转义测试 ===');
  
  // 模拟转义函数
  String escapeLikePattern(String pattern) {
    return pattern
        .replaceAll('\\', '\\\\')  // 先转义反斜杠
        .replaceAll('%', '\\%')    // 转义百分号
        .replaceAll('_', '\\_');   // 转义下划线
  }
  
  // 测试案例
  final testCases = [
    '_',           // 下划线（会匹配单个字符）
    '%',           // 百分号（会匹配多个字符）
    '_%',          // 组合
    'test_name',   // 包含下划线的文本
    '50%',         // 包含百分号的文本
    '\\test',      // 包含反斜杠的文本
    '云',          // 普通中文字符
    'abc',         // 普通英文文本
  ];
  
  for (final testCase in testCases) {
    final escaped = escapeLikePattern(testCase);
    final query = 'SELECT * FROM table WHERE field LIKE \'%$escaped%\'';
    
    print('原始输入: "$testCase"');
    print('转义后: "$escaped"');
    print('SQL查询: $query');
    print('说明: ${_getExplanation(testCase, escaped)}');
    print('---');
  }
}

String _getExplanation(String original, String escaped) {
  if (original == '_') {
    return '下划线被转义为 \\_，现在只匹配字面上的下划线字符，而不是任意单个字符';
  } else if (original == '%') {
    return '百分号被转义为 \\%，现在只匹配字面上的百分号字符，而不是任意多个字符';
  } else if (original.contains('_')) {
    return '文本中的下划线被转义，避免意外的通配符匹配';
  } else if (original.contains('%')) {
    return '文本中的百分号被转义，避免意外的通配符匹配';
  } else {
    return '普通文本，无需转义';
  }
}
