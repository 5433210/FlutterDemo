import 'dart:convert';

void main() {
  print('测试JSON转义字符问题...');
  
  // 测试不同的问题字符串
  final testCases = [
    'KÕ(\\Á',      // 原始字符串
    'KÕ(\\\\Á',    // 双反斜杠
    'KÕ(\Á',       // 单反斜杠
    'KÕ(\\\\\\Á',  // 三反斜杠
  ];
  
  for (int i = 0; i < testCases.length; i++) {
    final testString = testCases[i];
    print('\n=== 测试案例 ${i + 1}: "$testString" ===');
    
    try {
      // 测试直接JSON编码
      final testData = {'title': testString};
      final jsonString = jsonEncode(testData);
      print('JSON编码成功: $jsonString');
      
      // 测试解码
      final decoded = jsonDecode(jsonString);
      print('JSON解码成功: $decoded');
      
    } catch (e) {
      print('JSON处理失败: $e');
    }
  }
  
  // 测试手动构造的问题JSON
  print('\n=== 测试手动构造的问题JSON ===');
  final problemJson = '{"title":"KÕ(\\Á","author":""}';
  print('问题JSON: $problemJson');
  
  try {
    final decoded = jsonDecode(problemJson);
    print('手动JSON解码成功: $decoded');
  } catch (e) {
    print('手动JSON解码失败: $e');
  }
  
  // 测试修复后的JSON
  print('\n=== 测试修复后的JSON ===');
  final fixedJson = '{"title":"KÕ(\\\\Á","author":""}';
  print('修复JSON: $fixedJson');
  
  try {
    final decoded = jsonDecode(fixedJson);
    print('修复JSON解码成功: $decoded');
  } catch (e) {
    print('修复JSON解码失败: $e');
  }
} 