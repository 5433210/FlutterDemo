import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_sizes.dart';
import '../../providers/settings_provider.dart';
import 'components/appearance_settings.dart';
import 'components/developer_settings.dart';
import 'components/language_settings.dart';
import 'components/m3_settings_navigation_bar.dart';
import 'components/storage_settings.dart';

/// Material 3 version of the settings page
class M3SettingsPage extends ConsumerWidget {
  const M3SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final hasChanges = false; // In the future, track changes if needed

    return Scaffold(
      appBar: M3SettingsNavigationBar(
        onSave: () {
          // Save settings if needed in the future
        },
        hasChanges: hasChanges,
      ),
      body: SafeArea(
        child: _buildSettingsContent(context, ref),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.m),
      child: ListView(
        children: const [
          AppearanceSettings(),
          Divider(),
          LanguageSettings(),
          Divider(),
          StorageSettings(),
          Divider(),
          DeveloperSettings(),
        ],
      ),
    );
  }
}
