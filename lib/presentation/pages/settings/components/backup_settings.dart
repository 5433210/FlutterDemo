import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/providers/import_export_providers.dart';
import '../../../../application/services/enhanced_backup_service.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/settings/settings_section.dart';
import '../../backup_path_settings.dart';
import '../../unified_backup_management_page.dart';

/// 备份设置面板
class BackupSettings extends ConsumerWidget {
  const BackupSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsSection(
      title: l10n.backupSettings,
      icon: Icons.backup_outlined,
      children: [
        // 备份路径设置
        ListTile(
          title: Text(l10n.backupPathSettings),
          subtitle: Text(l10n.backupPathSettingsSubtitle),
          leading: Icon(
            Icons.folder_outlined,
            color: colorScheme.primary,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => _showBackupPathSettings(context),
        ),

        // 备份管理
        ListTile(
          title: Text(l10n.backupManagement),
          subtitle: Text(l10n.backupManagementSubtitle),
          leading: Icon(
            Icons.backup_outlined,
            color: colorScheme.primary,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          onTap: () => _showUnifiedBackupManagement(context, ref),
        ),
      ],
    );
  }

  /// 显示统一备份管理页面
  void _showUnifiedBackupManagement(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    try {
      final serviceLocator = ref.read(syncServiceLocatorProvider);

      if (!serviceLocator.isRegistered<EnhancedBackupService>()) {
        _showServiceNotAvailableDialog(context, ref, l10n.backupManagement);
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UnifiedBackupManagementPage(),
        ),
      );
    } catch (e) {
      AppLogger.error(l10n.openBackupManagementFailed,
          error: e, tag: 'BackupSettings');
      _showErrorDialog(context, l10n.openBackupManagementFailed, e.toString());
    }
  }

  /// 显示备份路径设置
  void _showBackupPathSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BackupPathSettings(),
      ),
    );
  }

  /// 显示服务不可用对话框
  void _showServiceNotAvailableDialog(
      BuildContext context, WidgetRef ref, String featureName) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupNotAvailable),
        content: Text(l10n.backupNotAvailableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  /// 显示错误对话框
  void _showErrorDialog(
      BuildContext context, String title, String errorMessage) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}
