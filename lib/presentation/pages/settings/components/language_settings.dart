import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/enums/app_language.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/settings/settings_section.dart';

class LanguageSettings extends ConsumerWidget {
  const LanguageSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    AppLogger.debug('LanguageSettings.build', tag: 'LanguageSettings', data: {
      'currentLanguage': settings.language.toString(),
      'displayName': settings.language.getDisplayName(context),
      'currentLocale': Localizations.localeOf(context).toString(),
    });

    return SettingsSection(
      title: l10n.language,
      icon: Icons.language,
      children: [
        ListTile(
          title: Text(l10n.language),
          subtitle: Text(settings.language.getDisplayName(context)),
          leading: Icon(settings.language.icon, color: colorScheme.primary),
          trailing: Icon(Icons.arrow_forward_ios,
              size: 16, color: colorScheme.onSurfaceVariant),
          onTap: () => _showLanguageSelector(context, ref, settings.language),
        ),
      ],
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    AppLanguage currentLanguage,
  ) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    AppLogger.debug('_showLanguageSelector', tag: 'LanguageSettings', data: {
      'currentLanguage': currentLanguage.toString(),
      'currentLocale': Localizations.localeOf(context).toString(),
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppLanguage.values.map((language) {
            return RadioListTile<AppLanguage>(
              title: Text(language.getDisplayName(context)),
              value: language,
              activeColor: colorScheme.primary,
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  AppLogger.info('Language settings changed',
                      tag: 'LanguageSettings',
                      data: {
                        'newLanguage': value.toString(),
                        'previousLanguage': currentLanguage.toString(),
                      });

                  // Update language settings
                  await ref.read(settingsProvider.notifier).setLanguage(value);

                  // Close dialog
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  // Small delay to ensure settings are saved
                  await Future.delayed(const Duration(milliseconds: 100));

                  // Rebuild entire app
                  if (context.mounted) {
                    AppLogger.info(
                        'Reloading app to apply new language settings',
                        tag: 'LanguageSettings');
                    // Use Navigator to reload root route, forcing rebuild of entire app
                    Navigator.of(context, rootNavigator: true)
                        .pushNamedAndRemoveUntil(
                      '/',
                      (route) => false,
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
