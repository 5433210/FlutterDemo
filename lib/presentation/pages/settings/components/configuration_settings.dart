import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/providers/config_providers.dart';
import '../../../widgets/settings/settings_section.dart';
import '../../../pages/config/config_management_page.dart';

/// 配置管理设置组件
class ConfigurationSettings extends ConsumerWidget {
  const ConfigurationSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    // 监听配置初始化状态
    final initializationState = ref.watch(configInitializationProvider);
    
    // 监听活跃配置项数量
    final styleItemsAsync = ref.watch(activeStyleItemsProvider);
    final toolItemsAsync = ref.watch(activeToolItemsProvider);

    return SettingsSection(
      title: '配置管理', // TODO: 使用本地化
      icon: Icons.tune_outlined,
      children: [
        // 书法风格管理
        ListTile(
          title: const Text('书法风格'), // TODO: 使用本地化
          subtitle: styleItemsAsync.when(
            data: (items) => Text('${items.length} 个选项'), // TODO: 使用本地化
            loading: () => const Text('加载中...'), // TODO: 使用本地化
            error: (_, __) => const Text('加载失败'), // TODO: 使用本地化
          ),
          leading: Icon(Icons.brush_outlined, color: colorScheme.primary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToStyleConfig(context),
        ),
        
        // 书写工具管理
        ListTile(
          title: const Text('书写工具'), // TODO: 使用本地化
          subtitle: toolItemsAsync.when(
            data: (items) => Text('${items.length} 个选项'), // TODO: 使用本地化
            loading: () => const Text('加载中...'), // TODO: 使用本地化
            error: (_, __) => const Text('加载失败'), // TODO: 使用本地化
          ),
          leading: Icon(Icons.edit_outlined, color: colorScheme.primary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToToolConfig(context),
        ),

        // 配置管理综合入口
        ListTile(
          title: const Text('配置管理'), // TODO: 使用本地化
          subtitle: const Text('管理书法风格和书写工具配置'), // TODO: 使用本地化
          leading: Icon(Icons.settings_outlined, color: colorScheme.primary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToConfigManagement(context),
        ),

        // 初始化状态指示器
        initializationState.when(
          data: (isInitialized) => isInitialized 
              ? Container() // 已初始化，不显示任何内容
              : const ListTile(
                  title: Text('正在初始化配置...'), // TODO: 使用本地化
                  leading: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          loading: () => const ListTile(
            title: Text('正在初始化配置...'), // TODO: 使用本地化
            leading: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => ListTile(
            title: const Text('配置初始化失败'), // TODO: 使用本地化
            subtitle: Text(error.toString()),
            leading: Icon(Icons.error_outline, color: colorScheme.error),
            trailing: TextButton(
              onPressed: () => ref.refresh(configInitializationProvider),
              child: const Text('重试'), // TODO: 使用本地化
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToStyleConfig(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConfigManagementPage(
          category: 'style',
          title: '书法风格管理', // TODO: 使用本地化字符串
        ),
      ),
    );
  }

  void _navigateToToolConfig(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConfigManagementPage(
          category: 'tool',
          title: '书写工具管理', // TODO: 使用本地化字符串
        ),
      ),
    );
  }

  void _navigateToConfigManagement(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ConfigManagementPage(),
      ),
    );
  }
}
