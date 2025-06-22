import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../../application/services/backup_service.dart';
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
      final exportPath = p.join(outputDirectory, backup.fileName);
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
      bool dialogShown = false;
      NavigatorState? navigatorState;
      try {
        AppLogger.info('准备显示加载对话框', tag: 'BackupSettings');
        navigatorState = Navigator.of(context);
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
                const SizedBox(height: AppSizes.p8),
                Text(
                  '这可能需要几分钟时间，请耐心等待...',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
        dialogShown = true;
        AppLogger.info('加载对话框已显示', tag: 'BackupSettings');
      } catch (e) {
        AppLogger.error('显示加载对话框失败', tag: 'BackupSettings', error: e, data: {
          'error': e.toString(),
          'contextMounted': context.mounted,
        });
        // 如果无法显示对话框，直接返回
        return;
      }

      try {
        AppLogger.info('开始创建备份UI流程', tag: 'BackupSettings', data: {
          'description': description,
        });

        // 执行备份操作
        final backupPath = await ref
            .read(backupSettingsProvider.notifier)
            .createBackup(
                description: description.isNotEmpty ? description : null);

        AppLogger.info('备份操作完成', tag: 'BackupSettings', data: {
          'backupPath': backupPath,
          'success': backupPath != null,
        });

        // 关闭加载对话框
        if (context.mounted && dialogShown) {
          AppLogger.info('准备关闭加载对话框', tag: 'BackupSettings', data: {
            'dialogShown': dialogShown,
            'contextMounted': context.mounted,
            'navigatorMounted': navigatorState.mounted,
          });

          // 尝试多种方式关闭对话框
          bool dialogClosed = false;

          // 方法1：使用保存的NavigatorState
          if (navigatorState.mounted) {
            try {
              if (navigatorState.canPop()) {
                navigatorState.pop();
                dialogClosed = true;
                AppLogger.info('使用保存的NavigatorState关闭对话框成功',
                    tag: 'BackupSettings');
              } else {
                AppLogger.warning('保存的NavigatorState无法执行pop操作',
                    tag: 'BackupSettings');
              }
            } catch (e) {
              AppLogger.warning('使用保存的NavigatorState关闭对话框失败',
                  tag: 'BackupSettings', error: e);
            }
          }

          // 方法2：如果方法1失败，尝试使用当前context的Navigator
          if (!dialogClosed) {
            try {
              final currentNavigator = Navigator.of(context);
              if (currentNavigator.canPop()) {
                currentNavigator.pop();
                dialogClosed = true;
                AppLogger.info('使用当前Navigator关闭对话框成功', tag: 'BackupSettings');
              } else {
                AppLogger.warning('当前Navigator无法执行pop操作',
                    tag: 'BackupSettings');
              }
            } catch (e) {
              AppLogger.warning('使用当前Navigator关闭对话框失败',
                  tag: 'BackupSettings', error: e);
            }
          }

          // 方法3：如果前两种方法都失败，尝试强制关闭
          if (!dialogClosed) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
              dialogClosed = true;
              AppLogger.info('使用rootNavigator关闭对话框成功', tag: 'BackupSettings');
            } catch (e) {
              AppLogger.error('所有方法都无法关闭对话框', tag: 'BackupSettings', error: e);
            }
          }

          if (!dialogClosed) {
            AppLogger.error('无法关闭加载对话框，所有方法都失败了', tag: 'BackupSettings');
          }
        }

        // 显示结果
        if (context.mounted) {
          if (backupPath != null) {
            AppLogger.info('显示备份成功消息', tag: 'BackupSettings');
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.backupSuccess),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: '查看',
                    onPressed: () {
                      // 可以添加查看备份文件的功能
                    },
                  ),
                ),
              );
              AppLogger.info('备份成功消息已显示', tag: 'BackupSettings');
            } catch (e) {
              AppLogger.error('显示备份成功消息失败', tag: 'BackupSettings', error: e);
            }
          } else {
            AppLogger.warning('备份路径为null，显示失败消息', tag: 'BackupSettings');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('备份创建超时或失败，请检查存储空间是否足够'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: '重试',
                  onPressed: () => _showCreateBackupDialog(context, ref),
                ),
              ),
            );
          }
        }
      } catch (e, stackTrace) {
        AppLogger.error('备份操作异常',
            tag: 'BackupSettings', error: e, stackTrace: stackTrace);

        // 关闭加载对话框
        if (context.mounted && dialogShown) {
          AppLogger.info('异常处理：准备关闭加载对话框', tag: 'BackupSettings', data: {
            'dialogShown': dialogShown,
            'contextMounted': context.mounted,
            'navigatorMounted': navigatorState.mounted,
          });

          // 尝试多种方式关闭对话框
          bool dialogClosed = false;

          // 方法1：使用保存的NavigatorState
          if (navigatorState.mounted) {
            try {
              if (navigatorState.canPop()) {
                navigatorState.pop();
                dialogClosed = true;
                AppLogger.info('异常处理：使用保存的NavigatorState关闭对话框成功',
                    tag: 'BackupSettings');
              } else {
                AppLogger.warning('异常处理：保存的NavigatorState无法执行pop操作',
                    tag: 'BackupSettings');
              }
            } catch (navError) {
              AppLogger.warning('异常处理：使用保存的NavigatorState关闭对话框失败',
                  tag: 'BackupSettings', error: navError);
            }
          }

          // 方法2：如果方法1失败，尝试使用当前context的Navigator
          if (!dialogClosed) {
            try {
              final currentNavigator = Navigator.of(context);
              if (currentNavigator.canPop()) {
                currentNavigator.pop();
                dialogClosed = true;
                AppLogger.info('异常处理：使用当前Navigator关闭对话框成功',
                    tag: 'BackupSettings');
              } else {
                AppLogger.warning('异常处理：当前Navigator无法执行pop操作',
                    tag: 'BackupSettings');
              }
            } catch (navError) {
              AppLogger.warning('异常处理：使用当前Navigator关闭对话框失败',
                  tag: 'BackupSettings', error: navError);
            }
          }

          // 方法3：如果前两种方法都失败，尝试强制关闭
          if (!dialogClosed) {
            try {
              Navigator.of(context, rootNavigator: true).pop();
              dialogClosed = true;
              AppLogger.info('异常处理：使用rootNavigator关闭对话框成功',
                  tag: 'BackupSettings');
            } catch (navError) {
              AppLogger.error('异常处理：所有方法都无法关闭对话框',
                  tag: 'BackupSettings', error: navError);
            }
          }

          if (!dialogClosed) {
            AppLogger.error('异常处理：无法关闭加载对话框，所有方法都失败了',
                tag: 'BackupSettings',
                data: {
                  'originalError': e.toString(),
                });
          }

          // 显示详细的错误信息
          String errorMessage;
          if (e.toString().contains('Permission denied') ||
              e.toString().contains('Access is denied')) {
            errorMessage = '备份失败：没有足够的文件访问权限';
          } else if (e.toString().contains('No space left') ||
              e.toString().contains('Disk full')) {
            errorMessage = '备份失败：存储空间不足';
          } else if (e.toString().contains('timeout') ||
              e.toString().contains('TimeoutException')) {
            errorMessage = '备份失败：操作超时，可能是因为数据量过大';
          } else {
            errorMessage = '备份失败: ${e.toString()}';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: '重试',
                onPressed: () => _showCreateBackupDialog(context, ref),
              ),
            ),
          );
        }
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
