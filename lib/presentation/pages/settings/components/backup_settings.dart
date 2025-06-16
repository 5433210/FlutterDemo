import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import '../../../../infrastructure/backup/backup_service.dart';
import '../../../../infrastructure/logging/logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_sizes.dart';
import '../../../../utils/file_size_formatter.dart';
import '../../../providers/backup_settings_provider.dart';
import '../../../widgets/settings/settings_section.dart';

/// 备份设置面板
class BackupSettings extends ConsumerWidget {
  const BackupSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backupSettings = ref.watch(backupSettingsProvider);
    final backupList = ref.watch(backupListProvider);
    final l10n = AppLocalizations.of(context);

    return SettingsSection(
      title: l10n.backupSettings,
      icon: Icons.backup_outlined,
      children: [
        // 自动备份开关
        SwitchListTile(
          title: Text(l10n.autoBackup),
          subtitle: Text(l10n.autoBackupDescription),
          value: backupSettings.autoBackupEnabled,
          onChanged: (value) {
            ref
                .read(backupSettingsProvider.notifier)
                .setAutoBackupEnabled(value);
          },
        ),

        // 自动备份间隔（仅在自动备份启用时显示）
        if (backupSettings.autoBackupEnabled)
          ListTile(
            title: Text(l10n.autoBackupInterval),
            subtitle: Text(l10n.autoBackupIntervalDescription),
            trailing: DropdownButton<int>(
              value: backupSettings.autoBackupIntervalDays,
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text(l10n.days(1)),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(l10n.days(3)),
                ),
                DropdownMenuItem(
                  value: 7,
                  child: Text(l10n.days(7)),
                ),
                DropdownMenuItem(
                  value: 14,
                  child: Text(l10n.days(14)),
                ),
                DropdownMenuItem(
                  value: 30,
                  child: Text(l10n.days(30)),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref
                      .read(backupSettingsProvider.notifier)
                      .setAutoBackupIntervalDays(value);
                }
              },
            ),
          ),

        // 保留备份数量
        ListTile(
          title: Text(l10n.keepBackupCount),
          subtitle: Text(l10n.keepBackupCountDescription),
          trailing: DropdownButton<int>(
            value: backupSettings.keepBackupCount,
            items: const [
              DropdownMenuItem(
                value: 1,
                child: Text('1'),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text('3'),
              ),
              DropdownMenuItem(
                value: 5,
                child: Text('5'),
              ),
              DropdownMenuItem(
                value: 10,
                child: Text('10'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref
                    .read(backupSettingsProvider.notifier)
                    .setKeepBackupCount(value);
              }
            },
          ),
        ),

        // 上次备份时间
        if (backupSettings.lastBackupTime != null)
          ListTile(
            title: Text(l10n.lastBackupTime),
            subtitle: Text(
              DateFormat.yMd().add_Hm().format(backupSettings.lastBackupTime!),
            ),
          ),

        const SizedBox(height: AppSizes.p16),

        // 备份操作按钮
        Wrap(
          spacing: AppSizes.p8,
          runSpacing: AppSizes.p8,
          alignment: WrapAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.backup),
              label: Text(l10n.createBackup),
              onPressed: () async {
                await _showCreateBackupDialog(context, ref);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.restore),
              label: Text(l10n.restoreBackup),
              onPressed: () async {
                await _showRestoreBackupDialog(context, ref);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.importBackup),
              onPressed: () async {
                await _importBackup(context, ref);
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: Text(l10n.exportBackup),
              onPressed: () async {
                await _showExportBackupDialog(context, ref);
              },
            ),
          ],
        ),

        const SizedBox(height: AppSizes.p16),

        // 备份列表
        Text(
          l10n.backupList,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSizes.p8),

        // 备份列表内容
        backupList.when(
          data: (backups) => _buildBackupList(context, ref, backups),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('${l10n.loadFailed}: $error'),
        ),
      ],
    );
  }

  /// 构建备份列表
  Widget _buildBackupList(
      BuildContext context, WidgetRef ref, List<BackupInfo> backups) {
    final l10n = AppLocalizations.of(context);

    if (backups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Center(
          child: Text(l10n.noBackups),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: backups.length,
      itemBuilder: (context, index) {
        final backup = backups[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text(backup.fileName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (backup.description != null &&
                    backup.description != backup.fileName)
                  Text(
                    backup.description!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                Text(
                  DateFormat.yMd().add_Hm().format(backup.creationTime),
                ),
                Text(
                  FileSizeFormatter.format(backup.size),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore),
                  tooltip: l10n.restore,
                  onPressed: () async {
                    final result = await _showRestoreConfirmDialog(context);
                    if (result != null && result.confirmed) {
                      // 显示加载对话框
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: AppSizes.p16),
                                Text(l10n.restoringBackup),
                              ],
                            ),
                          ),
                        );
                      }

                      // 恢复备份，并根据用户选择决定是否自动重启
                      final autoRestart = result.autoRestart;
                      final currentContext = context;

                      // 记录自动重启选项
                      AppLogger.info('用户选择的自动重启选项',
                          tag: 'BackupSettings',
                          data: {'autoRestart': autoRestart});

                      final success = await ref
                          .read(backupSettingsProvider.notifier)
                          .restoreFromBackup(
                            backup.path,
                            context:
                                currentContext.mounted ? currentContext : null,
                            autoRestart: autoRestart,
                          );

                      // 关闭加载对话框
                      if (context.mounted) {
                        Navigator.of(context).pop();

                        if (!success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.restoreFailure),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.download),
                  tooltip: l10n.exportBackup,
                  onPressed: () async {
                    await _exportBackup(context, ref, backup);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.deleteBackup,
                  onPressed: () async {
                    final confirmed = await _showDeleteConfirmDialog(context);
                    if (confirmed) {
                      final success = await ref
                          .read(backupSettingsProvider.notifier)
                          .deleteBackup(backup.path);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success ? l10n.deleteSuccess : l10n.deleteFailure,
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 导出备份
  Future<void> _exportBackup(
      BuildContext context, WidgetRef ref, BackupInfo backup) async {
    final l10n = AppLocalizations.of(context);

    // 选择导出位置
    final outputDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectExportLocation,
    );

    if (outputDirectory == null) {
      return; // 用户取消了选择
    }

    if (context.mounted) {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSizes.p16),
              Text(l10n.exportingBackup),
            ],
          ),
        ),
      );

      // 导出备份
      final exportPath = path.join(outputDirectory, backup.fileName);
      final success = await ref
          .read(backupSettingsProvider.notifier)
          .exportBackup(backup.path, exportPath);

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();

        // 显示结果
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.exportSuccess : l10n.exportFailure,
            ),
          ),
        );
      }
    }
  }

  /// 导入备份
  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);

    // 选择备份文件
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.selectImportFile,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result == null || result.files.isEmpty) {
      return; // 用户取消了选择
    }

    final file = result.files.first;
    if (file.path == null) {
      return; // 无效的文件路径
    }

    if (context.mounted) {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSizes.p16),
              Text(l10n.importing),
            ],
          ),
        ),
      );

      // 导入备份
      final success = await ref
          .read(backupSettingsProvider.notifier)
          .importBackup(file.path!);

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();

        // 显示结果
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? l10n.importSuccess : l10n.importFailure,
            ),
          ),
        );
      }
    }
  }

  /// 显示创建备份对话框
  Future<void> _showCreateBackupDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();

    final description = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.createBackupDescription),
            const SizedBox(height: AppSizes.p16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.backupDescription,
                hintText: l10n.backupDescriptionHint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );

    if (description != null && context.mounted) {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSizes.p16),
              Text(l10n.creatingBackup),
            ],
          ),
        ),
      );

      // 创建备份
      final backupPath = await ref
          .read(backupSettingsProvider.notifier)
          .createBackup(
              description: description.isNotEmpty ? description : null);

      // 关闭加载对话框
      if (context.mounted) {
        Navigator.of(context).pop();

        // 显示结果
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              backupPath != null ? l10n.backupSuccess : l10n.backupFailure,
            ),
          ),
        );
      }
    }
  }

  /// 显示删除确认对话框
  Future<bool> _showDeleteConfirmDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteBackup),
            content: Text(l10n.deleteMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.confirm),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 显示导出备份对话框
  Future<void> _showExportBackupDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final backupList = await ref.read(backupListProvider.future);

    if (backupList.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noBackups)),
        );
      }
      return;
    }

    if (context.mounted) {
      final selectedBackup = await showDialog<BackupInfo>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.exportBackup),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backupList.length,
              itemBuilder: (context, index) {
                final backup = backupList[index];
                return ListTile(
                  title: Text(backup.fileName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (backup.description != null &&
                          backup.description != backup.fileName)
                        Text(
                          backup.description!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      Text(
                        DateFormat.yMd().add_Hm().format(backup.creationTime),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(backup),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (selectedBackup != null && context.mounted) {
        await _exportBackup(context, ref, selectedBackup);
      }
    }
  }

  /// 显示恢复备份对话框
  Future<void> _showRestoreBackupDialog(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final backupList = await ref.read(backupListProvider.future);

    if (backupList.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noBackups)),
        );
      }
      return;
    }

    if (context.mounted) {
      final selectedBackup = await showDialog<BackupInfo>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.selectBackup),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: backupList.length,
              itemBuilder: (context, index) {
                final backup = backupList[index];
                return ListTile(
                  title: Text(backup.fileName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (backup.description != null &&
                          backup.description != backup.fileName)
                        Text(
                          backup.description!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      Text(
                        DateFormat.yMd().add_Hm().format(backup.creationTime),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).pop(backup),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        ),
      );

      if (selectedBackup != null && context.mounted) {
        final result = await _showRestoreConfirmDialog(context);

        if (result != null && result.confirmed && context.mounted) {
          // 显示加载对话框
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSizes.p16),
                  Text(l10n.restoringBackup),
                ],
              ),
            ),
          );

          // 恢复备份
          final autoRestart = result.autoRestart;
          final currentContext = context;

          // 记录自动重启选项
          AppLogger.info('用户选择的自动重启选项',
              tag: 'BackupSettings', data: {'autoRestart': autoRestart});

          final success =
              await ref.read(backupSettingsProvider.notifier).restoreFromBackup(
                    selectedBackup.path,
                    context: currentContext.mounted ? currentContext : null,
                    autoRestart: autoRestart,
                  );

          // 关闭加载对话框
          if (context.mounted) {
            Navigator.of(context).pop();

            if (!success) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.restoreFailure),
                ),
              );
            }
          }
        }
      }
    }
  }

  /// 显示恢复确认对话框
  Future<RestoreConfirmResult?> _showRestoreConfirmDialog(
      BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    return await showDialog<RestoreConfirmResult>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreConfirmMessage),
            const SizedBox(height: 8),
            // 添加自动重启提示
            Text(
              l10n.restartAfterRestored,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const RestoreConfirmResult(
                confirmed: true,
                autoRestart: true, // 始终自动重启
              ),
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }
}

/// 恢复确认对话框结果
class RestoreConfirmResult {
  /// 是否确认恢复
  final bool confirmed;

  /// 是否自动重启（始终为true，保留字段以保持兼容性）
  final bool autoRestart;

  /// 创建恢复确认结果
  ///
  /// [confirmed] 是否确认恢复
  /// [autoRestart] 保留参数，但始终为true
  const RestoreConfirmResult({
    required this.confirmed,
    this.autoRestart = true,
  });
}
