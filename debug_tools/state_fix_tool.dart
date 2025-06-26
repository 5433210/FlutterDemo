#!/usr/bin/env dart

/// 集字编辑页状态调试修复工具
/// 专门解决输入后无法调整、预览显示不对等问题

import 'dart:io';

class CollectionStateFixTool {
  /// 运行状态修复检查
  static Future<void> runStateFix() async {
    print('🔧 集字编辑页状态修复开始...\n');

    // 1. 检查常见的状态锁定问题
    await _checkStateFreeze();

    // 2. 检查预览更新问题
    await _checkPreviewUpdate();

    // 3. 检查文本输入响应问题
    await _checkTextInputResponse();

    // 4. 生成修复方案
    await _generateFixSuggestions();

    print('\n✅ 状态修复检查完成！');
  }

  /// 检查状态冻结问题
  static Future<void> _checkStateFreeze() async {
    print('❄️  检查状态冻结问题...');

    // 检查是否有阻塞的 setState 调用
    final blockingSetState = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        '-A3',
        '-B3',
        'setState.*async\\|await.*setState',
        'lib/presentation/widgets/practice/property_panels/'
      ],
      workingDirectory: '.',
    );

    if (blockingSetState.exitCode == 0 &&
        blockingSetState.stdout.toString().isNotEmpty) {
      print('   ⚠️  发现可能导致状态冻结的代码:');
      print(blockingSetState.stdout);
    }

    // 检查循环更新
    final circularUpdate = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        '-A5',
        '-B5',
        'didUpdateWidget.*onElementPropertiesChanged',
        'lib/presentation/widgets/practice/property_panels/'
      ],
      workingDirectory: '.',
    );

    if (circularUpdate.exitCode == 0 &&
        circularUpdate.stdout.toString().isNotEmpty) {
      print('   ⚠️  发现可能的循环更新:');
      print(circularUpdate.stdout);
    }

    print('   📋 修复建议:');
    print('      1. 避免在 setState 中使用 await');
    print('      2. 使用 Future.microtask 延迟状态更新');
    print('      3. 添加状态更新锁防止并发修改');
  }

  /// 检查预览更新问题
  static Future<void> _checkPreviewUpdate() async {
    print('👀 检查预览更新问题...');

    // 检查预览更新逻辑
    final previewUpdate = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        '-A3',
        '-B3',
        '_updatePreview\\|preview.*update',
        'lib/presentation/widgets/practice/'
      ],
      workingDirectory: '.',
    );

    if (previewUpdate.exitCode == 0 &&
        previewUpdate.stdout.toString().isNotEmpty) {
      print('   📊 预览更新调用:');
      print(previewUpdate.stdout);
    }

    // 检查渲染器更新
    final renderUpdate = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        '-A3',
        '-B3',
        'markNeedsPaint\\|markNeedsLayout',
        'lib/presentation/widgets/practice/'
      ],
      workingDirectory: '.',
    );

    if (renderUpdate.exitCode == 0 &&
        renderUpdate.stdout.toString().isNotEmpty) {
      print('   🎨 渲染器更新调用:');
      print(renderUpdate.stdout);
    }

    print('   📋 修复建议:');
    print('      1. 确保数据变更后触发 repaint');
    print('      2. 检查 shouldRepaint 逻辑');
    print('      3. 添加预览数据变更监听');
  }

  /// 检查文本输入响应问题
  static Future<void> _checkTextInputResponse() async {
    print('⌨️  检查文本输入响应问题...');

    // 检查文本控制器更新
    final textController = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        '-A5',
        '-B5',
        '_textController.*text\\|text.*_textController',
        'lib/presentation/widgets/practice/property_panels/'
      ],
      workingDirectory: '.',
    );

    if (textController.exitCode == 0 &&
        textController.stdout.toString().isNotEmpty) {
      print('   📝 文本控制器使用:');
      print(textController.stdout);
    }

    // 检查防抖逻辑
    final debounce = await Process.run(
      'grep',
      [
        '-r',
        '--include=*.dart',
        '-n',
        '-A3',
        '-B3',
        '_debounceTimer\\|debounce',
        'lib/presentation/widgets/practice/property_panels/'
      ],
      workingDirectory: '.',
    );

    if (debounce.exitCode == 0 && debounce.stdout.toString().isNotEmpty) {
      print('   ⏱️  防抖逻辑:');
      print(debounce.stdout);
    }

    print('   📋 修复建议:');
    print('      1. 检查文本控制器监听器设置');
    print('      2. 优化防抖时间间隔');
    print('      3. 确保输入后状态同步');
  }

  /// 生成修复方案
  static Future<void> _generateFixSuggestions() async {
    print('\n🔧 推荐修复方案:');

    final fixes = [
      '1. 添加状态更新锁',
      '2. 优化异步状态更新流程',
      '3. 修复文本输入响应延迟',
      '4. 改进预览更新机制',
      '5. 添加调试日志和状态监控',
    ];

    for (final fix in fixes) {
      print('   $fix');
    }

    // 生成具体的代码修复建议
    await _generateCodeFixes();
  }

  /// 生成代码修复建议
  static Future<void> _generateCodeFixes() async {
    print('\n💡 具体代码修复建议:');

    print('''
1. 在属性面板中添加状态锁:
   ```dart
   bool _isUpdating = false;
   
   Future<void> _safeUpdateState(VoidCallback callback) async {
     if (_isUpdating) return;
     _isUpdating = true;
     try {
       await callback();
     } finally {
       _isUpdating = false;
     }
   }
   ```

2. 优化文本输入响应:
   ```dart
   void _onTextChanged(String value) {
     if (_debounceTimer?.isActive ?? false) {
       _debounceTimer!.cancel();
     }
     
     _debounceTimer = Timer(Duration(milliseconds: 300), () async {
       await _safeUpdateState(() async {
         // 更新逻辑
       });
     });
   }
   ```

3. 改进预览更新:
   ```dart
   void _updatePreview() {
     SchedulerBinding.instance.addPostFrameCallback((_) {
       if (mounted) {
         setState(() {
           // 预览更新逻辑
         });
       }
     });
   }
   ```

4. 添加调试监控:
   ```dart
   void _debugStateChange(String operation) {
     CollectionDebugHelper.logStateChange('PropertyPanel', operation, {
       'timestamp': DateTime.now().millisecondsSinceEpoch,
       'isUpdating': _isUpdating,
       'textLength': _textController.text.length,
     });
   }
   ```
''');
  }

  /// 应用快速修复
  static Future<void> applyQuickFixes() async {
    print('⚡ 应用快速修复...\n');

    // 读取当前属性面板文件
    final panelFile = File(
        'lib/presentation/widgets/practice/property_panels/m3_collection_property_panel.dart');

    if (!await panelFile.exists()) {
      print('❌ 属性面板文件不存在');
      return;
    }

    final content = await panelFile.readAsString();

    // 检查是否已经有状态锁
    if (!content.contains('_isUpdating')) {
      print('📝 建议添加状态锁防止并发更新');
      print('   在类的开始添加: bool _isUpdating = false;');
    }

    // 检查是否有安全的状态更新方法
    if (!content.contains('_safeUpdateState')) {
      print('📝 建议添加安全状态更新方法');
    }

    // 检查防抖配置
    if (content.contains('Duration(milliseconds:')) {
      final debounceMatch =
          RegExp(r'Duration\(milliseconds:\s*(\d+)\)').firstMatch(content);
      if (debounceMatch != null) {
        final duration = int.parse(debounceMatch.group(1)!);
        if (duration > 500) {
          print('⚠️  防抖时间过长 (${duration}ms)，建议降低到 200-300ms');
        }
      }
    }

    print('\n✅ 快速修复检查完成！');
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('用法:');
    print('  dart state_fix_tool.dart check  # 检查状态问题');
    print('  dart state_fix_tool.dart fix    # 应用快速修复');
    return;
  }

  switch (args[0]) {
    case 'check':
      await CollectionStateFixTool.runStateFix();
      break;
    case 'fix':
      await CollectionStateFixTool.applyQuickFixes();
      break;
    default:
      print('未知命令: ${args[0]}');
  }
}
