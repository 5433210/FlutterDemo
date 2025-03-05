import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/app_theme_mode.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/settings/settings_section.dart';

class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final isDarkMode = themeMode == AppThemeMode.dark;
    final isSystemMode = themeMode == AppThemeMode.system;

    return SettingsSection(
      title: '外观',
      icon: Icons.palette_outlined,
      children: [
        ListTile(
          title: const Text('深色模式'),
          subtitle: const Text('使用深色主题'),
          leading: const Icon(Icons.dark_mode),
          trailing: Switch(
            value: isDarkMode,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(
                    value ? AppThemeMode.dark : AppThemeMode.light,
                  );
            },
          ),
        ),
        ListTile(
          title: const Text('跟随系统'),
          subtitle: const Text('根据系统设置自动切换深色/浅色模式'),
          leading: const Icon(Icons.settings_system_daydream_outlined),
          trailing: Switch(
            value: isSystemMode,
            onChanged: (value) {
              if (value) {
                ref
                    .read(settingsProvider.notifier)
                    .setThemeMode(AppThemeMode.system);
              } else {
                ref.read(settingsProvider.notifier).setThemeMode(
                      isDarkMode ? AppThemeMode.dark : AppThemeMode.light,
                    );
              }
            },
          ),
        ),
      ],
    );
  }
}
