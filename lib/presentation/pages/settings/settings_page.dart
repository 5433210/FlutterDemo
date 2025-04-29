import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/page_layout.dart';
import 'components/appearance_settings.dart';
import 'components/developer_settings.dart';
import 'components/language_settings.dart';
import 'components/storage_settings.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return PageLayout(
      toolbar: Text(l10n.settings),
      body: _buildSettingsContent(context, ref),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref) {
    return ListView(
      children: const [
        AppearanceSettings(),
        Divider(),
        LanguageSettings(),
        Divider(),
        StorageSettings(),
        Divider(),
        DeveloperSettings(),
      ],
    );
  }
}
