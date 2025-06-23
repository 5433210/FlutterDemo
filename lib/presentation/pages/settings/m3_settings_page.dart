import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_sizes.dart';
import '../../utils/cross_navigation_helper.dart';

import 'components/appearance_settings.dart';
import 'components/app_version_settings.dart';
import 'components/backup_settings.dart';
import 'components/cache_settings.dart';
import 'components/configuration_settings.dart';
import 'components/language_settings.dart';
import 'components/m3_settings_navigation_bar.dart';
import 'components/storage_settings.dart';

/// Material 3 version of the settings page
class M3SettingsPage extends ConsumerWidget {
  const M3SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Remove unused variables to fix warnings
    const hasChanges = false; // In the future, track changes if needed

    return Scaffold(
      appBar: M3SettingsNavigationBar(
        onSave: () {
          // Save settings if needed in the future
        },
        hasChanges: hasChanges,
        onBackPressed: () {
          // 使用CrossNavigationHelper来处理返回导航，显示“返回到之前的页面”对话框
          CrossNavigationHelper.handleBackNavigation(context, ref);
        },
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
          ConfigurationSettings(),
          Divider(),
          StorageSettings(),
          Divider(),
          BackupSettings(),
          Divider(),
          CacheSettings(),
          Divider(),
          AppVersionSettings(),
        ],
      ),
    );
  }
}
