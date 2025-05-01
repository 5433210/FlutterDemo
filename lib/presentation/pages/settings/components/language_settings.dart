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
          leading: Icon(settings.language.icon),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
              groupValue: currentLanguage,
              onChanged: (value) async {
                if (value != null) {
                  AppLogger.info('用户选择了新的语言设置', tag: 'LanguageSettings', data: {
                    'newLanguage': value.toString(),
                    'previousLanguage': currentLanguage.toString(),
                  });

                  // 更新语言设置
                  await ref.read(settingsProvider.notifier).setLanguage(value);

                  // 关闭对话框
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }

                  // 延迟一下，确保设置已经保存
                  await Future.delayed(const Duration(milliseconds: 100));

                  // 重新构建整个应用
                  if (context.mounted) {
                    AppLogger.info('重新加载应用以应用新的语言设置', tag: 'LanguageSettings');
                    // 使用 Navigator 重新加载根路由，强制重新构建整个应用
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
