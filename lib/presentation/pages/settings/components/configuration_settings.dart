import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../infrastructure/providers/config_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pages/config/config_management_page.dart';
import '../../../widgets/settings/settings_section.dart';

/// 配置管理设置组件
class ConfigurationSettings extends ConsumerWidget {
  const ConfigurationSettings({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    // 监听配置初始化状态
    final initializationState = ref.watch(configInitializationProvider);

    // 监听活跃配置项数量
    final styleItemsAsync = ref.watch(activeStyleItemsProvider);
    final toolItemsAsync = ref.watch(activeToolItemsProvider);

    return SettingsSection(
      title: localizations.configManagement,
      icon: Icons.tune_outlined,
      children: [
        // 书法风格管理
        ListTile(
          title: Text(localizations.calligraphyStyle),
          subtitle: styleItemsAsync.when(
            data: (items) => Text(localizations.itemsCount(items.length)),
            loading: () => Text(localizations.loading),
            error: (_, __) => Text(localizations.loadFailed),
          ),
          leading: Icon(Icons.brush_outlined, color: colorScheme.primary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToStyleConfig(context),
        ),

        // 书写工具管理
        ListTile(
          title: Text(localizations.writingTool),
          subtitle: toolItemsAsync.when(
            data: (items) => Text(localizations.itemsCount(items.length)),
            loading: () => Text(localizations.loading),
            error: (_, __) => Text(localizations.loadFailed),
          ),
          leading: Icon(Icons.edit_outlined, color: colorScheme.primary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToToolConfig(context),
        ),

        // 配置管理综合入口
        ListTile(
          title: Text(localizations.configManagement),
          subtitle: Text(localizations.configManagementDescription),
          leading: Icon(Icons.settings_outlined, color: colorScheme.primary),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _navigateToConfigManagement(context),
        ),

        // 初始化状态指示器
        initializationState.when(
          data: (isInitialized) => isInitialized
              ? Container() // 已初始化，不显示任何内容
              : ListTile(
                  title: Text(localizations.configInitializing),
                  leading: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
          loading: () => ListTile(
            title: Text(localizations.configInitializing),
            leading: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (error, _) => ListTile(
            title: Text(localizations.configInitializationFailed),
            subtitle: Text(error.toString()),
            leading: Icon(Icons.error_outline, color: colorScheme.error),
            trailing: TextButton(
              onPressed: () => ref.refresh(configInitializationProvider),
              child: Text(localizations.retry),
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToStyleConfig(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfigManagementPage(
          category: 'style',
          title: localizations.calligraphyStyle,
        ),
      ),
    );
  }

  void _navigateToToolConfig(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfigManagementPage(
          category: 'tool',
          title: localizations.writingTool,
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
