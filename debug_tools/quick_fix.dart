#!/usr/bin/env dart

/// 集字编辑页快速修复工具
/// 专门解决当前的UI交互问题

import 'dart:io';

void main() async {
  print('🔧 集字编辑页快速修复工具');
  print('=' * 50);

  // 1. 检查当前状态
  await checkCurrentState();

  // 2. 提供修复建议
  await provideFixes();

  // 3. 运行验证
  await runValidation();
}

Future<void> checkCurrentState() async {
  print('\n📊 检查当前状态...');

  // 检查属性面板文件
  final panelFile = File(
      'lib/presentation/widgets/practice/property_panels/m3_collection_property_panel.dart');
  if (await panelFile.exists()) {
    print('✅ 属性面板文件存在');

    final content = await panelFile.readAsString();

    // 检查关键方法
    final checks = {
      '_onTextChanged': content.contains('_onTextChanged'),
      'setState': content.contains('setState'),
      '_debounceTimer': content.contains('_debounceTimer'),
      '_wordMatchingMode': content.contains('_wordMatchingMode'),
    };

    checks.forEach((method, exists) {
      print('${exists ? "✅" : "❌"} $method: ${exists ? "存在" : "缺失"}');
    });

    // 检查潜在问题
    if (content.contains('setState') && content.contains('async')) {
      print('⚠️  发现异步setState调用，可能导致状态问题');
    }

    if (content.contains('Future.microtask')) {
      print('⚠️  发现microtask调用，可能影响响应性');
    }
  } else {
    print('❌ 属性面板文件不存在');
  }
}

Future<void> provideFixes() async {
  print('\n💡 快速修复建议:');

  print('''
1. 立即修复方案:
   - 在文本输入回调中添加空检查
   - 优化防抖时间到200ms
   - 确保setState只在mounted时调用
   
2. 调试方法:
   - 添加console.log跟踪状态变化
   - 使用Flutter Inspector检查widget树
   - 启用性能叠加层监控帧率
   
3. 验证步骤:
   - 输入文本后检查响应
   - 切换匹配模式测试
   - 观察预览更新是否同步
''');
}

Future<void> runValidation() async {
  print('\n🧪 运行验证...');

  try {
    // 检查语法
    print('检查Dart语法...');
    final analyzeResult = await Process.run(
      'flutter',
      ['analyze', '--no-fatal-infos'],
      workingDirectory: '.',
    );

    if (analyzeResult.exitCode == 0) {
      print('✅ 语法检查通过');
    } else {
      print('❌ 发现语法错误:');
      print(analyzeResult.stdout);
      print(analyzeResult.stderr);
    }

    // 检查构建
    print('\n检查是否可以构建...');
    final buildResult = await Process.run(
      'flutter',
      ['build', 'web', '--debug'],
      workingDirectory: '.',
    );

    if (buildResult.exitCode == 0) {
      print('✅ 构建成功');
    } else {
      print('❌ 构建失败，需要修复错误');
    }
  } catch (e) {
    print('❌ 验证过程出错: $e');
  }
}
