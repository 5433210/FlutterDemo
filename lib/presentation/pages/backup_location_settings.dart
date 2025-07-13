import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../application/services/backup_registry_manager.dart';
import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/file_utils.dart';
import '../utils/localized_string_extensions.dart';

/// 备份位置设置界面
class BackupLocationSettings extends StatefulWidget {
  const BackupLocationSettings({Key? key}) : super(key: key);

  @override
  State<BackupLocationSettings> createState() => _BackupLocationSettingsState();
}

class _BackupLocationSettingsState extends State<BackupLocationSettings> {
  String? _currentPath;
  BackupRegistry? _registry;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentPath();
  }

  Future<void> _loadCurrentPath() async {
    final l10n = AppLocalizations.of(context);
    try {
      setState(() => _isLoading = true);

      final currentPath = await BackupRegistryManager.getCurrentBackupPath();
      setState(() => _currentPath = currentPath);

      if (currentPath != null) {
        try {
          final registry = await BackupRegistryManager.getRegistry();
          setState(() => _registry = registry);
        } catch (e) {
          AppLogger.warning(l10n.loadBackupRegistryFailed,
              error: e, tag: 'BackupLocationSettings');
        }
      }
    } catch (e) {
      AppLogger.error(l10n.loadCurrentBackupPathFailed,
          error: e, tag: 'BackupLocationSettings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectNewBackupPath() async {
    final l10n = AppLocalizations.of(context);
    try {
      final newPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectBackupStorageLocation,
      );

      if (newPath != null) {
        setState(() => _isLoading = true);

        await BackupRegistryManager.setBackupLocation(newPath);
        await _loadCurrentPath();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupPathSetSuccessfully)),
          );
        }
      }
    } catch (e) {
      AppLogger.error(l10n.setBackupPathFailed,
          error: e, tag: 'BackupLocationSettings');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.setBackupPathFailed}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 删除当前路径下的所有备份
  Future<void> _deleteAllBackupsInCurrentPath() async {
    final l10n = AppLocalizations.of(context);
    if (_currentPath == null || _registry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未设置备份路径')),
      );
      return;
    }

    final backupCount = _registry!.backups.length;
    if (backupCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该路径下没有备份文件')),
      );
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('危险操作确认'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('您即将删除该路径下的所有备份文件：'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _currentPath!,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            Text('将删除 $backupCount 个备份文件，此操作不可撤销！'),
            const SizedBox(height: 8),
            Text(
              '请确认您真的要执行此操作。',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            child: const Text(
              '确认删除全部',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performDeleteAllBackups();
    }
  }

  /// 执行删除所有备份操作
  Future<void> _performDeleteAllBackups() async {
    // 保存对话框上下文
    BuildContext? dialogContext;

    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context; // 保存对话框上下文
        return const AlertDialog(
          title: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('正在删除备份...'),
            ],
          ),
          content: Text('正在删除所有备份文件，请稍候...'),
        );
      },
    );

    try {
      int deletedCount = 0;
      int failedCount = 0;
      List<String> failedFiles = [];

      final backups = _registry!.backups;
      for (final backup in backups) {
        try {
          // 删除文件
          final backupFile = File(backup.fullPath);
          if (await backupFile.exists()) {
            await backupFile.delete();
          }

          // 从注册表中移除
          await BackupRegistryManager.deleteBackup(backup.id);
          deletedCount++;
        } catch (e) {
          failedCount++;
          failedFiles.add('${backup.filename}: $e');
          AppLogger.error('删除备份失败',
              error: e,
              tag: 'BackupLocationSettings',
              data: {'backup': backup.filename, 'path': _currentPath});
        }
      }

      // 先关闭进度对话框，再处理后续操作
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      // 重新加载数据
      await _loadCurrentPath();

      // 显示结果
      if (mounted) {
        final message = failedCount == 0
            ? '成功删除 $deletedCount 个备份文件'
            : '删除完成：成功 $deletedCount 个，失败 $failedCount 个';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: failedCount == 0 ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );

        if (failedCount > 0) {
          // 显示失败详情
          AppLogger.warning('部分备份删除失败',
              tag: 'BackupLocationSettings',
              data: {'failedFiles': failedFiles});
        }
      }
    } catch (e) {
      AppLogger.error('删除所有备份失败', error: e, tag: 'BackupLocationSettings');

      // 确保对话框关闭
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 清理重复的备份记录
  Future<void> _cleanDuplicateBackups() async {
    final l10n = AppLocalizations.of(context);

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cleaning_services, color: Colors.orange),
            SizedBox(width: 8),
            Text('清理重复记录'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('此操作将：'),
            SizedBox(height: 8),
            Text('• 删除重复的备份记录'),
            Text('• 删除指向不存在文件的记录'),
            Text('• 保留唯一且有效的备份记录'),
            SizedBox(height: 12),
            Text('注意：此操作不会删除实际的备份文件，只会整理记录。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelAction),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              '开始清理',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performCleanDuplicateBackups();
    }
  }

  /// 执行清理重复备份记录操作
  Future<void> _performCleanDuplicateBackups() async {
    // 保存对话框上下文
    BuildContext? dialogContext;

    // 显示进度对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context; // 保存对话框上下文
        return const AlertDialog(
          title: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('正在清理重复记录...'),
            ],
          ),
          content: Text('正在检查和清理重复的备份记录，请稍候...'),
        );
      },
    );

    try {
      final removedCount = await BackupRegistryManager.removeDuplicateBackups();

      // 先关闭进度对话框，再处理后续操作
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      // 重新加载数据
      await _loadCurrentPath();

      // 显示结果
      if (mounted) {
        final message = removedCount == 0
            ? '未发现重复记录，备份注册表已是最新状态'
            : '清理完成，已移除 $removedCount 条重复或无效记录';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: removedCount == 0 ? Colors.blue : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('清理重复备份记录失败', error: e, tag: 'BackupLocationSettings');

      // 确保对话框关闭
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清理操作失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupLocationSettings),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 当前备份位置
                  _buildCurrentLocationCard(),

                  const SizedBox(height: 16),

                  // 备份统计
                  if (_registry != null) _buildStatisticsCard(),

                  const SizedBox(height: 16),

                  // 帮助信息
                  _buildHelpCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildCurrentLocationCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.backupStorageLocation,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade50,
              ),
              child: Text(
                _currentPath ?? l10n.notSet,
                style: TextStyle(
                  fontSize: 14,
                  color: _currentPath != null
                      ? Colors.black87
                      : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _selectNewBackupPath,
                icon: const Icon(Icons.folder_open),
                label: Text(
                    _currentPath != null ? l10n.changePath : l10n.selectPath),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final l10n = AppLocalizations.of(context);
    final statistics = _registry!.statistics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.backupStatistics,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatisticItem(
                l10n.totalBackups, statistics.totalBackups.toString()),
            _buildStatisticItem(l10n.currentLocation,
                statistics.currentLocationBackups.toString()),
            _buildStatisticItem(l10n.historyLocation,
                statistics.legacyLocationBackups.toString()),
            _buildStatisticItem(
                l10n.totalSize, FileUtils.formatFileSize(statistics.totalSize)),
            if (statistics.lastBackupTime != null)
              _buildStatisticItem(
                l10n.lastBackup,
                FileUtils.formatDateTime(statistics.lastBackupTime!),
              ),
            const SizedBox(height: 12),
            // 清理重复记录按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cleanDuplicateBackups,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('清理重复记录'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 删除备份按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _deleteAllBackupsInCurrentPath,
                icon: const Icon(Icons.delete),
                label: const Text('删除所有备份'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  l10n.usageInstructions,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.backupLocationTips.processLineBreaks,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
