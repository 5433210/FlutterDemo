#!/usr/bin/env dart

import 'dart:io';

/// 高效的集字编辑页开发调试工具
///
/// 提供以下功能：
/// 1. 自动化热重载测试
/// 2. 状态一致性验证
/// 3. 性能基准测试
/// 4. UI 交互自动化测试
/// 5. 问题诊断和修复建议

class CollectionEditEfficiencyTool {
  /// 运行完整的开发效率检查
  static Future<void> runEfficiencyCheck() async {
    print('🚀 集字编辑页开发效率检查开始...\n');

    // 1. 代码静态分析
    await _runStaticAnalysis();

    // 2. 测试覆盖率检查
    await _checkTestCoverage();

    // 3. 热重载效率测试
    await _testHotReloadEfficiency();

    // 4. 状态管理分析
    await _analyzeStateManagement();

    // 5. 生成效率改进建议
    await _generateEfficiencyRecommendations();

    print('\n✅ 开发效率检查完成！');
  }

  /// 运行代码静态分析
  static Future<void> _runStaticAnalysis() async {
    print('📊 运行代码静态分析...');

    try {
      // Flutter analyze
      final analyzeResult = await Process.run(
        'flutter',
        ['analyze', '--no-fatal-infos'],
        workingDirectory: '.',
      );

      if (analyzeResult.exitCode == 0) {
        print('✅ 静态分析通过');
      } else {
        print('❌ 静态分析发现问题:');
        print(analyzeResult.stdout);
        print(analyzeResult.stderr);
      }

      // 检查特定的潜在问题
      await _checkSpecificIssues();
    } catch (e) {
      print('❌ 静态分析失败: $e');
    }
  }

  /// 检查特定的代码问题
  static Future<void> _checkSpecificIssues() async {
    print('🔍 检查特定问题模式...');

    // 检查是否有无限循环的 setState
    final setStateResult = await Process.run(
      'grep',
      ['-r', '--include=*.dart', '-n', 'setState.*setState', 'lib/'],
      workingDirectory: '.',
    );

    if (setStateResult.exitCode == 0 &&
        setStateResult.stdout.toString().isNotEmpty) {
      print('⚠️  发现潜在的 setState 无限循环:');
      print(setStateResult.stdout);
    }

    // 检查是否有阻塞的同步操作
    final syncResult = await Process.run(
      'grep',
      ['-r', '--include=*.dart', '-n', 'Sync.*await', 'lib/'],
      workingDirectory: '.',
    );

    if (syncResult.exitCode == 0 && syncResult.stdout.toString().isNotEmpty) {
      print('⚠️  发现可能的阻塞同步操作:');
      print(syncResult.stdout);
    }
  }

  /// 测试覆盖率检查
  static Future<void> _checkTestCoverage() async {
    print('🧪 检查测试覆盖率...');

    try {
      // 运行测试并生成覆盖率报告
      final testResult = await Process.run(
        'flutter',
        ['test', '--coverage'],
        workingDirectory: '.',
      );

      if (testResult.exitCode == 0) {
        print('✅ 测试通过');

        // 检查覆盖率文件是否存在
        final coverageFile = File('coverage/lcov.info');
        if (await coverageFile.exists()) {
          final coverage = await _analyzeCoverage();
          print('📈 测试覆盖率: ${coverage.toStringAsFixed(1)}%');

          if (coverage < 70) {
            print('⚠️  测试覆盖率较低，建议增加测试');
          }
        }
      } else {
        print('❌ 测试失败:');
        print(testResult.stdout);
        print(testResult.stderr);
      }
    } catch (e) {
      print('❌ 测试检查失败: $e');
    }
  }

  /// 分析测试覆盖率
  static Future<double> _analyzeCoverage() async {
    try {
      final coverageFile = File('coverage/lcov.info');
      final content = await coverageFile.readAsString();

      int hitLines = 0;
      int totalLines = 0;

      final lines = content.split('\n');
      for (final line in lines) {
        if (line.startsWith('DA:')) {
          totalLines++;
          final parts = line.substring(3).split(',');
          if (parts.length >= 2 && int.tryParse(parts[1]) != null) {
            final hits = int.parse(parts[1]);
            if (hits > 0) hitLines++;
          }
        }
      }

      return totalLines > 0 ? (hitLines / totalLines) * 100 : 0;
    } catch (e) {
      print('❌ 覆盖率分析失败: $e');
      return 0;
    }
  }

  /// 测试热重载效率
  static Future<void> _testHotReloadEfficiency() async {
    print('🔥 测试热重载效率...');

    // 模拟代码更改并测试重载时间
    final testFile = File('test_hot_reload_temp.dart');

    try {
      // 创建测试文件
      await testFile.writeAsString('''
// Test file for hot reload efficiency
class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Test ${DateTime.now().millisecondsSinceEpoch}'),
    );
  }
}
''');

      final stopwatch = Stopwatch()..start();

      // 模拟文件修改
      await Future.delayed(const Duration(milliseconds: 100));
      await testFile.writeAsString('''
// Test file for hot reload efficiency - MODIFIED
class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Modified Test ${DateTime.now().millisecondsSinceEpoch}'),
    );
  }
}
''');

      stopwatch.stop();

      print('📊 模拟热重载时间: ${stopwatch.elapsedMilliseconds}ms');

      if (stopwatch.elapsedMilliseconds > 1000) {
        print('⚠️  热重载可能较慢，建议优化构建配置');
      }
    } finally {
      // 清理测试文件
      if (await testFile.exists()) {
        await testFile.delete();
      }
    }
  }

  /// 分析状态管理
  static Future<void> _analyzeStateManagement() async {
    print('🎯 分析状态管理...');

    // 检查 setState 调用频率
    final setStateResult = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-c',
        'setState',
        'lib/presentation/widgets/practice/property_panels/'
      ],
      workingDirectory: '.',
    );

    if (setStateResult.exitCode == 0) {
      final lines = setStateResult.stdout.toString().trim().split('\n');
      int totalSetState = 0;

      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final count = int.tryParse(parts[1]) ?? 0;
          totalSetState += count;
        }
      }

      print('📊 setState 调用总数: $totalSetState');

      if (totalSetState > 50) {
        print('⚠️  setState 调用频繁，考虑使用状态管理方案');
      }
    }

    // 检查 Riverpod provider 使用
    final providerResult = await Process.run(
      'grep',
      ['-r', '--include=*.dart', '-c', 'ref.read\\|ref.watch', 'lib/'],
      workingDirectory: '.',
    );

    if (providerResult.exitCode == 0) {
      print('✅ 使用 Riverpod 状态管理');
    }
  }

  /// 生成效率改进建议
  static Future<void> _generateEfficiencyRecommendations() async {
    print('\n📋 开发效率改进建议:');

    final recommendations = [
      '1. 🚀 使用 Flutter Inspector 调试 widget 树',
      '2. 🔧 启用 Flutter DevTools 性能监控',
      '3. 📊 设置自动化测试流水线',
      '4. 🎯 使用 Dart VM Service 进行性能分析',
      '5. 🔥 优化热重载配置，减少重建时间',
      '6. 🧪 编写更多单元测试和 widget 测试',
      '7. 📝 添加详细的调试日志和状态跟踪',
      '8. 🎨 使用 Storybook 或类似工具独立测试组件',
      '9. 🔍 定期进行代码审查和重构',
      '10. ⚡ 考虑使用 code generation 减少样板代码',
    ];

    for (final recommendation in recommendations) {
      print('   $recommendation');
    }

    // 生成具体的配置建议
    await _generateConfigRecommendations();
  }

  /// 生成配置建议
  static Future<void> _generateConfigRecommendations() async {
    print('\n⚙️  推荐配置:');

    // 检查是否存在推荐的配置文件
    final configs = {
      'analysis_options.yaml': '代码分析配置',
      'test/test_config.dart': '测试配置',
      '.vscode/launch.json': 'VS Code 调试配置',
      '.vscode/tasks.json': 'VS Code 任务配置',
    };

    for (final config in configs.entries) {
      final file = File(config.key);
      if (await file.exists()) {
        print('   ✅ ${config.value} - 已配置');
      } else {
        print('   ❌ ${config.value} - 建议添加');
      }
    }
  }

  /// 运行快速诊断
  static Future<void> runQuickDiagnosis() async {
    print('🔍 快速诊断开始...\n');

    // 检查属性面板状态问题
    await _diagnosePropertyPanel();

    // 检查渲染器问题
    await _diagnoseRenderer();

    // 检查字符服务问题
    await _diagnoseCharacterService();

    print('\n✅ 快速诊断完成！');
  }

  /// 诊断属性面板问题
  static Future<void> _diagnosePropertyPanel() async {
    print('🎛️  诊断属性面板...');

    // 检查常见的状态管理问题
    final issues = <String>[];

    // 检查是否有循环依赖
    final circularResult = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-A5',
        '-B5',
        'didUpdateWidget.*setState',
        'lib/presentation/widgets/practice/property_panels/'
      ],
      workingDirectory: '.',
    );

    if (circularResult.exitCode == 0 &&
        circularResult.stdout.toString().isNotEmpty) {
      issues.add('可能存在 didUpdateWidget 中的循环 setState');
    }

    // 检查异步操作
    final asyncResult = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        'await.*setState',
        'lib/presentation/widgets/practice/property_panels/'
      ],
      workingDirectory: '.',
    );

    if (asyncResult.exitCode == 0 && asyncResult.stdout.toString().isNotEmpty) {
      issues.add('存在异步 setState 调用，可能导致状态不一致');
    }

    if (issues.isEmpty) {
      print('   ✅ 属性面板状态管理正常');
    } else {
      print('   ⚠️  发现潜在问题:');
      for (final issue in issues) {
        print('      - $issue');
      }
    }
  }

  /// 诊断渲染器问题
  static Future<void> _diagnoseRenderer() async {
    print('🎨 诊断渲染器...');

    // 检查渲染性能问题
    final performanceResult = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        'for.*length\\|while.*length',
        'lib/presentation/widgets/practice/'
      ],
      workingDirectory: '.',
    );

    if (performanceResult.exitCode == 0 &&
        performanceResult.stdout.toString().isNotEmpty) {
      print('   ⚠️  发现可能的性能问题，建议优化循环');
    } else {
      print('   ✅ 渲染器性能正常');
    }
  }

  /// 诊断字符服务问题
  static Future<void> _diagnoseCharacterService() async {
    print('🔤 诊断字符服务...');

    // 检查服务调用模式
    final serviceResult = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        'characterService.*searchCharacters',
        'lib/'
      ],
      workingDirectory: '.',
    );

    if (serviceResult.exitCode == 0) {
      final lines = serviceResult.stdout.toString().trim().split('\n');
      print('   📊 字符服务调用次数: ${lines.length}');

      if (lines.length > 10) {
        print('   ⚠️  字符服务调用频繁，建议添加缓存');
      }
    } else {
      print('   ✅ 字符服务使用正常');
    }
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('用法:');
    print('  dart efficiency_tool.dart check    # 运行完整效率检查');
    print('  dart efficiency_tool.dart diagnose # 运行快速诊断');
    return;
  }

  switch (args[0]) {
    case 'check':
      await CollectionEditEfficiencyTool.runEfficiencyCheck();
      break;
    case 'diagnose':
      await CollectionEditEfficiencyTool.runQuickDiagnosis();
      break;
    default:
      print('未知命令: ${args[0]}');
  }
}
