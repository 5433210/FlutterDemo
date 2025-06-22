import 'package:charasgem/infrastructure/providers/config_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🧪 开始动态配置系统测试...');

  final container = ProviderContainer();

  try {
    // 测试配置初始化
    print('📦 测试配置初始化...');
    await container.read(configInitializationProvider.future);
    print('✅ 配置初始化成功');

    // 测试获取样式配置
    print('🎨 测试样式配置...');
    final styleItems = await container.read(activeStyleItemsProvider.future);
    print('📋 活跃样式项数量: ${styleItems.length}');
    for (final item in styleItems) {
      print('  - ${item.key}: ${item.displayName}');
    }

    // 测试获取工具配置
    print('🔧 测试工具配置...');
    final toolItems = await container.read(activeToolItemsProvider.future);
    print('📋 活跃工具项数量: ${toolItems.length}');
    for (final item in toolItems) {
      print('  - ${item.key}: ${item.displayName}');
    }

    // 测试显示名称映射
    print('🏷️ 测试显示名称映射...');
    final styleNames = await container.read(styleDisplayNamesProvider.future);
    final toolNames = await container.read(toolDisplayNamesProvider.future);
    print('样式名称映射: $styleNames');
    print('工具名称映射: $toolNames');

    print('🎉 所有测试通过！动态配置系统正常工作。');
  } catch (e, stackTrace) {
    print('❌ 测试失败: $e');
    print('堆栈跟踪: $stackTrace');
  } finally {
    container.dispose();
  }
}
