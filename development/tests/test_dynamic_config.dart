// 简单的动态配置测试脚本
// 用于验证配置服务是否正常工作

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/infrastructure/providers/config_providers.dart';

void main() async {
  print('开始测试动态配置功能...');
  
  // 创建Provider容器
  final container = ProviderContainer();
  
  try {
    print('测试获取风格配置项...');
    final styleItems = await container.read(activeStyleItemsProvider.future);
    print('风格配置项数量: ${styleItems.length}');
    for (final item in styleItems) {
      print('  - ${item.key}: ${item.displayName}');
    }
    
    print('\n测试获取工具配置项...');
    final toolItems = await container.read(activeToolItemsProvider.future);
    print('工具配置项数量: ${toolItems.length}');
    for (final item in toolItems) {
      print('  - ${item.key}: ${item.displayName}');
    }
    
    print('\n测试获取风格显示名称映射...');
    final styleNames = await container.read(styleDisplayNamesProvider.future);
    print('风格显示名称映射: $styleNames');
    
    print('\n测试获取工具显示名称映射...');
    final toolNames = await container.read(toolDisplayNamesProvider.future);
    print('工具显示名称映射: $toolNames');
    
    print('\n✅ 动态配置功能测试完成！');
  } catch (e, stackTrace) {
    print('❌ 测试失败: $e');
    print('Stack trace: $stackTrace');
  } finally {
    container.dispose();
  }
}
