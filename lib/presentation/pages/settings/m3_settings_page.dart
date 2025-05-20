import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_sizes.dart';
import 'components/appearance_settings.dart';
import 'components/backup_settings.dart';
import 'components/cache_settings.dart';
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
          // 设置页面直接在主导航中，使用合适的方式返回
          // 使用路由替换回到主页，避免透明窗体问题
          Navigator.of(context, rootNavigator: true).pushReplacementNamed('/');
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
          StorageSettings(),
          Divider(),
          BackupSettings(),
          Divider(),
          CacheSettings(),
        ],
      ),
    );
  }
}
