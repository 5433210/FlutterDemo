import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../application/providers/import_export_providers.dart';
import '../../application/services/backup_registry_manager.dart';
import '../../application/services/enhanced_backup_service.dart';
import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_sizes.dart';
import '../../utils/file_size_formatter.dart';

/// 统一备份管理页面
/// 整合所有备份文件操作：创建、删除、导出、导入、恢复、路径管理
class UnifiedBackupManagementPage extends ConsumerStatefulWidget {
  const UnifiedBackupManagementPage({super.key});

  @override
  ConsumerState<UnifiedBackupManagementPage> createState() =>
      _UnifiedBackupManagementPageState();
}

class _UnifiedBackupManagementPageState
    extends ConsumerState<UnifiedBackupManagementPage> {
  List<String> _allPaths = [];
  final Map<String, List<BackupEntry>> _pathBackups = {};
  bool _isLoading = false;
  String? _currentPath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final serviceLocator = ref.read(syncServiceLocatorProvider);

      if (!serviceLocator.isRegistered<EnhancedBackupService>()) {
        throw Exception(
            AppLocalizations.of(context).backupServiceNotInitialized);
      }

      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 获取当前路径
      _currentPath = await BackupRegistryManager.getCurrentBackupPath();

      // 获取所有路径
      _allPaths = await backupService.getAllBackupPaths();

      // 为每个路径加载备份
      _pathBackups.clear();
      for (final path in _allPaths) {
        final backups = await backupService.scanBackupsInPath(path);
        _pathBackups[path] = backups;
      }

      AppLogger.info('Unified backup management data loaded successfully',
          tag: 'UnifiedBackupManagement',
          data: {
            'pathCount': _allPaths.length,
            'totalBackups': _pathBackups.values.expand((x) => x).length,
          });
    } catch (e, stack) {
      AppLogger.error('Failed to load unified backup management data',
          error: e, stackTrace: stack, tag: 'UnifiedBackupManagement');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${AppLocalizations.of(context).loadDataFailed}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupManagement),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: l10n.refresh,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_backup',
                child: Row(
                  children: [
                    const Icon(Icons.backup),
                    const SizedBox(width: 8),
                    Text(l10n.createBackup),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import_backup',
                child: Row(
                  children: [
                    const Icon(Icons.upload_file),
                    const SizedBox(width: 8),
                    Text(l10n.importBackup),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'cleanup_invalid_paths',
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services),
                    const SizedBox(width: 8),
                    Text(l10n.cleanupInvalidPaths),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_allPaths.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noBackupPaths,
                style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.backup),
              label: Text(l10n.createFirstBackup),
              onPressed: () => _createBackup(),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.p16),
      itemCount: _allPaths.length + 1, // +1 for summary card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildSummaryCard();
        }

        final pathIndex = index - 1;
        final path = _allPaths[pathIndex];
        final backups = _pathBackups[path] ?? [];
        final isCurrent = path == _currentPath;

        return _buildPathCard(path, backups, isCurrent, l10n);
      },
    );
  }

  Widget _buildSummaryCard() {
    final l10n = AppLocalizations.of(context);
    final totalBackups = _pathBackups.values.expand((x) => x).length;
    final currentPathBackups =
        _currentPath != null ? (_pathBackups[_currentPath!]?.length ?? 0) : 0;
    final legacyBackups = totalBackups - currentPathBackups;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.p16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupOverview,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(l10n.totalBackups,
                      totalBackups.toString(), Icons.folder_copy),
                ),
                Expanded(
                  child: _buildStatItem(l10n.currentLocation,
                      currentPathBackups.toString(), Icons.folder_special),
                ),
                Expanded(
                  child: _buildStatItem(l10n.historyLocation,
                      legacyBackups.toString(), Icons.history),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.backup),
                    label: Text(l10n.createBackup),
                    onPressed: _createBackup,
                  ),
                ),
                const SizedBox(width: AppSizes.p8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(l10n.importBackup),
                    onPressed: _importBackup,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPathCard(String path, List<BackupEntry> backups, bool isCurrent,
      AppLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.p16),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              isCurrent ? Icons.folder_special : Icons.folder_outlined,
              color: isCurrent ? Colors.blue : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                path,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: isCurrent ? Colors.blue : null,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            if (isCurrent)
              Chip(
                label: Text(l10n.currentPath),
                backgroundColor: Colors.blue,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            if (!isCurrent)
              Chip(
                label: Text(l10n.historicalPaths),
                backgroundColor: Colors.orange,
                labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            const SizedBox(width: 8),
            Text(l10n.backupCount(backups.length)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handlePathAction(action, path, backups),
          itemBuilder: (context) => [
            if (!isCurrent)
              PopupMenuItem(
                value: 'delete_path',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.deletePathButton),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'export_all',
              child: Row(
                children: [
                  const Icon(Icons.download),
                  const SizedBox(width: 8),
                  Text(l10n.exportAllBackupsButton),
                ],
              ),
            ),
          ],
        ),
        children: [
          if (backups.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSizes.p16),
              child: Text(l10n.noBackupFilesInPathMessage,
                  style: const TextStyle(color: Colors.grey)),
            )
          else
            ...backups.map((backup) => _buildBackupTile(backup, path, l10n)),
        ],
      ),
    );
  }

  Widget _buildBackupTile(
      BackupEntry backup, String path, AppLocalizations l10n) {
    return ListTile(
      leading: Icon(
        backup.location == 'current' ? Icons.backup : Icons.history,
        color: backup.location == 'current' ? Colors.green : Colors.orange,
      ),
      title: Text(backup.filename),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(backup.description),
          Text(
            DateFormat.yMd().add_Hm().format(backup.createdTime),
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            FileSizeFormatter.format(backup.size),
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleBackupAction(action, backup, path),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'restore',
            child: Row(
              children: [
                const Icon(Icons.restore),
                const SizedBox(width: 8),
                Text(l10n.restore),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'export',
            child: Row(
              children: [
                const Icon(Icons.download),
                const SizedBox(width: 8),
                Text(l10n.export),
              ],
            ),
          ),
          if (backup.location == 'legacy')
            PopupMenuItem(
              value: 'import_to_current',
              child: Row(
                children: [
                  const Icon(Icons.import_export),
                  const SizedBox(width: 8),
                  Text(l10n.importToCurrentPathButton),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 8),
                Text(l10n.delete),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'create_backup':
        await _createBackup();
        break;
      case 'import_backup':
        await _importBackup();
        break;
      case 'cleanup_invalid_paths':
        await _cleanupInvalidPaths();
        break;
    }
  }

  Future<void> _handlePathAction(
      String action, String path, List<BackupEntry> backups) async {
    switch (action) {
      case 'delete_path':
        await _deleteBackupPath(path);
        break;
      case 'export_all':
        await _exportAllBackups(path, backups);
        break;
    }
  }

  Future<void> _handleBackupAction(
      String action, BackupEntry backup, String path) async {
    switch (action) {
      case 'restore':
        await _restoreBackup(backup);
        break;
      case 'export':
        await _exportBackup(backup);
        break;
      case 'import_to_current':
        await _importBackupToCurrentPath(backup);
        break;
      case 'delete':
        await _deleteBackup(backup, path);
        break;
    }
  }

  // 实现各种操作方法...
  Future<void> _createBackup() async {
    final l10n = AppLocalizations.of(context);
    // 显示创建备份对话框
    final controller = TextEditingController();
    final description = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.createBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.backupDescriptionInputLabel),
            const SizedBox(height: AppSizes.p16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.backupDescriptionInputLabel,
                hintText: l10n.backupDescriptionInputExample,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );

    if (description != null) {
      await _performBackupCreation(description.isNotEmpty ? description : null);
    }
  }

  Future<void> _performBackupCreation(String? description) async {
    final l10n = AppLocalizations.of(context);
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.p16),
            Text(l10n.creatingBackupProgressMessage),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.creatingBackupPleaseWaitMessage,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      final serviceLocator = ref.read(syncServiceLocatorProvider);
      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 创建备份
      await backupService.createBackup(description: description);

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        // 重新加载数据
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupSuccess),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.createBackup} ${l10n.backupFailure}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      AppLogger.error('Failed to create backup',
          error: e, tag: 'UnifiedBackupManagement');
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context);
    // 选择备份文件
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.selectBackupFileToImportDialog,
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

    await _performBackupImport(file.path!);
  }

  Future<void> _performBackupImport(String filePath) async {
    final l10n = AppLocalizations.of(context);
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.p16),
            Text(l10n.importingBackupProgressMessage),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.pleaseWaitMessage, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      final serviceLocator = ref.read(syncServiceLocatorProvider);
      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 导入备份
      await backupService.importBackup(filePath);

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        // 重新加载数据
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupImportSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importBackupFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      AppLogger.error('Failed to import backup',
          error: e, tag: 'UnifiedBackupManagement');
    }
  }

  Future<void> _cleanupInvalidPaths() async {
    final l10n = AppLocalizations.of(context);
    try {
      final removedCount =
          await BackupRegistryManager.cleanupInvalidHistoryPaths();
      await _loadData(); // 重新加载数据

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cleanupCompletedMessage(removedCount))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.cleanupFailedMessage(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteBackupPath(String path) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.dangerousOperationConfirmTitle),
          ],
        ),
        content: Text(l10n.deletePathConfirmContent(path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.confirmDeleteButton,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // 删除路径下的所有备份文件
        final directory = Directory(path);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }

        // 从历史记录中移除
        await BackupRegistryManager.removeHistoryBackupPath(path);

        await _loadData(); // 重新加载数据

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupPathDeletedMessage)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteFailedMessage(e.toString()))),
          );
        }
      }
    }
  }

  // 其他操作方法的占位符
  Future<void> _exportAllBackups(String path, List<BackupEntry> backups) async {
    final l10n = AppLocalizations.of(context);
    if (backups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noBackupFilesToExportMessage)),
      );
      return;
    }

    // 选择导出位置
    final outputDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectExportLocationDialog,
    );

    if (outputDirectory == null) {
      return; // 用户取消了选择
    }

    await _performBatchExport(backups, path, outputDirectory);
  }

  Future<void> _performBatchExport(List<BackupEntry> backups, String sourcePath,
      String outputDirectory) async {
    final l10n = AppLocalizations.of(context);
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.p16),
            Text(l10n.exportingBackupsProgressFormat(backups.length)),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.pleaseWaitMessage, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      int successCount = 0;
      int failCount = 0;

      for (final backup in backups) {
        try {
          final sourceFilePath = p.join(sourcePath, backup.filename);
          final targetFilePath = p.join(outputDirectory, backup.filename);

          final sourceFile = File(sourceFilePath);
          if (await sourceFile.exists()) {
            await sourceFile.copy(targetFilePath);
            successCount++;
          } else {
            failCount++;
            AppLogger.warning(l10n.backupFileNotFound,
                tag: 'UnifiedBackupManagement',
                data: {
                  'file': sourceFilePath,
                });
          }
        } catch (e) {
          failCount++;
          AppLogger.error('Failed to export single backup',
              error: e,
              tag: 'UnifiedBackupManagement',
              data: {
                'backup': backup.filename,
              });
        }
      }

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        final failedMessage =
            failCount > 0 ? l10n.exportFailedPartFormat(failCount) : '';
        final message = l10n.exportCompletedFormat(successCount, failedMessage);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
            action: SnackBarAction(
              label: l10n.viewAction,
              onPressed: () {
                // 可以添加打开文件夹的功能
              },
            ),
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.batchExportFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      AppLogger.error('Failed to batch export',
          error: e, tag: 'UnifiedBackupManagement');
    }
  }

  Future<void> _restoreBackup(BackupEntry backup) async {
    final l10n = AppLocalizations.of(context);
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.confirmRestoreTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.confirmRestoreMessage),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.backupFileLabel(backup.filename)),
            Text(l10n.backupDescriptionLabel(backup.description)),
            Text(l10n.backupTimeLabel(
                DateFormat.yMd().add_Hm().format(backup.createdTime))),
            const SizedBox(height: AppSizes.p8),
            Text(
              l10n.restoreWarningMessage,
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.appWillRestartMessage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              foregroundColor: Colors.orange,
            ),
            child: Text(l10n.confirmRestoreButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performBackupRestore(backup);
    }
  }

  Future<void> _performBackupRestore(BackupEntry backup) async {
    final l10n = AppLocalizations.of(context);
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.p16),
            Text(l10n.restoringBackupMessage),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.doNotCloseAppMessage,
                style: const TextStyle(fontSize: 12, color: Colors.red)),
          ],
        ),
      ),
    );

    try {
      final serviceLocator = ref.read(syncServiceLocatorProvider);
      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 恢复备份
      await backupService.restoreBackup(backup.filename);

      // 恢复成功，应用可能已经重启了
      // 如果还在这里，说明恢复完成但没有重启
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupRestoreSuccessMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupRestoreFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      AppLogger.error('Failed to restore backup',
          error: e, tag: 'UnifiedBackupManagement');
    }
  }

  Future<void> _exportBackup(BackupEntry backup) async {
    final l10n = AppLocalizations.of(context);
    // 选择导出位置
    final outputDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: l10n.selectExportLocationDialog,
    );

    if (outputDirectory == null) {
      return; // 用户取消了选择
    }

    await _performBackupExport(backup, outputDirectory);
  }

  Future<void> _performBackupExport(
      BackupEntry backup, String outputDirectory) async {
    final l10n = AppLocalizations.of(context);
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.p16),
            Text(l10n.exportingBackupMessage),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.pleaseWaitMessage, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      // 构建源文件路径和目标文件路径
      final backupPath =
          backup.location == 'current' ? (_currentPath ?? '') : backup.id;
      final sourcePath = p.join(backupPath, backup.filename);
      final targetPath = p.join(outputDirectory, backup.filename);

      // 复制文件
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('${l10n.sourceBackupFileNotFound}: $sourcePath');
      }

      await sourceFile.copy(targetPath);

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccessMessage(targetPath)),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: l10n.viewAction,
              onPressed: () {
                // 可以添加打开文件夹的功能
              },
            ),
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportBackupFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      AppLogger.error('Failed to export backup',
          error: e, tag: 'UnifiedBackupManagement');
    }
  }

  Future<void> _importBackupToCurrentPath(BackupEntry backup) async {
    final l10n = AppLocalizations.of(context);
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.import_export, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.importToCurrentPathTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.importToCurrentPathMessage),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.backupFileLabel(backup.filename)),
            Text(l10n.backupDescriptionLabel(backup.description)),
            Text(l10n.backupTimeLabel(
                DateFormat.yMd().add_Hm().format(backup.createdTime))),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.importToCurrentPathDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.blue),
              foregroundColor: Colors.blue,
            ),
            child: Text(l10n.confirmImportButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performBackupImportToCurrentPath(backup);
    }
  }

  Future<void> _performBackupImportToCurrentPath(BackupEntry backup) async {
    final l10n = AppLocalizations.of(context);
    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.p16),
            Text(l10n.importingToCurrentPathMessage),
            const SizedBox(height: AppSizes.p8),
            Text(l10n.pleaseWaitMessage, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );

    try {
      if (_currentPath == null) {
        throw Exception(l10n.currentBackupPathNotSet);
      }

      // 构建源文件路径和目标文件路径
      final sourcePath = p.join(backup.id, backup.filename);
      final targetPath = p.join(_currentPath!, backup.filename);

      // 复制文件
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('${l10n.sourceBackupFileNotFound}: $sourcePath');
      }

      await sourceFile.copy(targetPath);

      // 创建新的备份条目
      final newBackupEntry = BackupEntry(
        id: backup.id, // 使用新的ID
        filename: backup.filename,
        fullPath: targetPath,
        description: '${backup.description} ${l10n.importedSuffix}',
        createdTime: DateTime.now(), // 使用当前时间
        size: backup.size,
        location: 'current',
        checksum: backup.checksum,
      );

      // 添加到注册表
      await BackupRegistryManager.addBackup(newBackupEntry);

      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        // 重新加载数据
        await _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importToCurrentPathSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.importBackupFailedMessage}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      AppLogger.error('Failed to import backup to current path',
          error: e, tag: 'UnifiedBackupManagement');
    }
  }

  Future<void> _deleteBackup(BackupEntry backup, String path) async {
    final l10n = AppLocalizations.of(context);
    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.confirmDeleteTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n
                .confirmDeleteBackup(backup.filename, backup.description)
                .replaceAll('\\n', '\n')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.confirmDeleteAction,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performBackupDeletion(backup, path);
    }
  }

  Future<void> _performBackupDeletion(BackupEntry backup, String path) async {
    final l10n = AppLocalizations.of(context);
    try {
      // 构建备份文件路径
      final backupFilePath = p.join(path, backup.filename);
      final backupFile = File(backupFilePath);

      // 删除备份文件
      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      // 从注册表中移除
      await BackupRegistryManager.deleteBackup(backup.id);

      // 重新加载数据
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupDeletedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.deleteBackupFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      AppLogger.error('Failed to delete backup',
          error: e, tag: 'UnifiedBackupManagement');
    }
  }
}
