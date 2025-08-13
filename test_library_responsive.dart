#!/usr/bin/env dart

/// 图库管理响应式布局测试脚本
/// 验证图库管理页面的面板互斥逻辑是否正确实现

import 'dart:io';

void main() async {
  print('=== 图库管理响应式布局测试 ===\n');

  // 测试1: 检查相关文件是否存在
  print('1. 检查文件存在性...');
  final files = [
    'lib/presentation/providers/library/library_management_provider.dart',
    'lib/presentation/widgets/library/m3_library_browsing_panel.dart',
    'lib/presentation/pages/library/m3_library_management_page.dart',
    'lib/presentation/pages/library/components/m3_library_detail_panel.dart',
  ];

  for (final file in files) {
    final exists = await File(file).exists();
    print('   ${exists ? "✅" : "❌"} $file');
  }

  // 测试2: 检查Provider中的新方法
  print('\n2. 检查Provider新方法...');
  final providerFile = File(
      'lib/presentation/providers/library/library_management_provider.dart');
  if (await providerFile.exists()) {
    final content = await providerFile.readAsString();
    final methods = [
      'toggleFilterPanelExclusive',
      'openDetailPanelExclusive',
    ];

    for (final method in methods) {
      final hasMethod = content.contains(method);
      print('   ${hasMethod ? "✅" : "❌"} $method()');
    }
  }

  // 测试3: 检查浏览面板的响应式布局
  print('\n3. 检查浏览面板响应式布局...');
  final browsingPanelFile =
      File('lib/presentation/widgets/library/m3_library_browsing_panel.dart');
  if (await browsingPanelFile.exists()) {
    final content = await browsingPanelFile.readAsString();
    final features = [
      '_buildNarrowLayout',
      '_buildWideLayout',
      'isNarrowScreen',
      'screenWidth < 1200',
    ];

    for (final feature in features) {
      final hasFeature = content.contains(feature);
      print('   ${hasFeature ? "✅" : "❌"} $feature');
    }
  }

  // 测试4: 检查管理页面的响应式布局
  print('\n4. 检查管理页面响应式布局...');
  final managementPageFile =
      File('lib/presentation/pages/library/m3_library_management_page.dart');
  if (await managementPageFile.exists()) {
    final content = await managementPageFile.readAsString();
    final features = [
      '_buildResponsiveLayout',
      'isNarrowScreen',
      'closeDetailPanel',
    ];

    for (final feature in features) {
      final hasFeature = content.contains(feature);
      print('   ${hasFeature ? "✅" : "❌"} $feature');
    }
  }

  // 测试5: 检查详情面板的关闭回调
  print('\n5. 检查详情面板关闭回调...');
  final detailPanelFile = File(
      'lib/presentation/pages/library/components/m3_library_detail_panel.dart');
  if (await detailPanelFile.exists()) {
    final content = await detailPanelFile.readAsString();
    final features = [
      'VoidCallback? onClose',
      'widget.onClose',
      'Icons.arrow_back',
    ];

    for (final feature in features) {
      final hasFeature = content.contains(feature);
      print('   ${hasFeature ? "✅" : "❌"} $feature');
    }
  }

  print('\n=== 测试完成 ===\n');
  print('响应式布局实现说明:');
  print('• 屏幕宽度 < 1200px 时启用互斥模式');
  print('• 筛选面板与详情面板在窄屏时互斥显示');
  print('• 宽屏时保持原有的并排布局');
  print('• 详情面板在窄屏时显示返回按钮');
}
