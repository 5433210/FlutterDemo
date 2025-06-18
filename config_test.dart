import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lib/infrastructure/providers/config_providers.dart';

/// 配置管理测试应用
class ConfigTestApp extends StatelessWidget {
  const ConfigTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(
      child: MaterialApp(
        title: 'Config Test',
        home: ConfigTestPage(),
      ),
    );
  }
}

class ConfigTestPage extends ConsumerWidget {
  const ConfigTestPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configInit = ref.watch(configInitializationProvider);
    final styleConfig = ref.watch(styleConfigNotifierProvider);
    final toolConfig = ref.watch(toolConfigNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('配置管理测试')),
      body: Column(
        children: [
          Card(
            child: ListTile(
              title: const Text('配置初始化'),
              subtitle: configInit.when(
                data: (initialized) =>
                    Text(initialized ? '✅ 初始化成功' : '❌ 初始化失败'),
                loading: () => const Text('🔄 正在初始化...'),
                error: (error, stack) => Text('❌ 初始化错误: $error'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('书法风格配置'),
              subtitle: styleConfig.when(
                data: (config) => Text(config != null
                    ? '✅ 加载成功 (${config.items.length} 项)'
                    : '⚠️ 配置为空'),
                loading: () => const Text('🔄 正在加载...'),
                error: (error, stack) => Text('❌ 加载错误: $error'),
              ),
              trailing: ElevatedButton(
                onPressed: () => _testStyleConfig(ref),
                child: const Text('测试'),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('书写工具配置'),
              subtitle: toolConfig.when(
                data: (config) => Text(config != null
                    ? '✅ 加载成功 (${config.items.length} 项)'
                    : '⚠️ 配置为空'),
                loading: () => const Text('🔄 正在加载...'),
                error: (error, stack) => Text('❌ 加载错误: $error'),
              ),
              trailing: ElevatedButton(
                onPressed: () => _testToolConfig(ref),
                child: const Text('测试'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _testStyleConfig(WidgetRef ref) {
    print('🧪 测试书法风格配置...');
    ref.read(styleConfigNotifierProvider.notifier).reload();
  }

  void _testToolConfig(WidgetRef ref) {
    print('🧪 测试书写工具配置...');
    ref.read(toolConfigNotifierProvider.notifier).reload();
  }
}

void main() {
  runApp(const ConfigTestApp());
}
