import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/app_theme_mode.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/settings/settings_section.dart';

class AppearanceSettings extends ConsumerWidget {
  const AppearanceSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final isDarkMode = themeMode == AppThemeMode.dark;
    final isSystemMode = themeMode == AppThemeMode.system;
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: l10n.themeMode,
      icon: Icons.palette_outlined,
      children: [
        ListTile(
          title: Text(l10n.themeModeDark),
          subtitle: Text(l10n.themeModeDescription),
          leading: Icon(Icons.dark_mode, color: colorScheme.primary),
          trailing: Switch(
            value: isDarkMode,
            activeColor: colorScheme.primary,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setThemeMode(
                    value ? AppThemeMode.dark : AppThemeMode.light,
                  );
            },
          ),
        ),
        ListTile(
          title: Text(l10n.languageSystem),
          subtitle: Text(l10n.themeModeSystemDescription),
          leading: Icon(Icons.settings_system_daydream_outlined,
              color: colorScheme.primary),
          trailing: Switch(
            value: isSystemMode,
            activeColor: colorScheme.primary,
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
