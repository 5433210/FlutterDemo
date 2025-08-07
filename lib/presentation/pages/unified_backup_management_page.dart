import 'dart:async';
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
import '../../utils/app_restart_service.dart';
import '../../utils/file_size_formatter.dart';
import '../utils/localized_string_extensions.dart';
import '../widgets/dialogs/backup_progress_dialog.dart';

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
  final Map<String, bool> _expandedPaths = {}; // 跟踪每个路径的展开状态
  bool _isLoading = false;
  String? _currentPath;
  bool _isCancelled = false;
  bool _isProcessingRestore = false; // 跟踪是否正在处理恢复操作

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _isCancelled = true;
    // 注意：不要在这里重置 _isProcessingRestore，让异步回调自己处理
    super.dispose();
  }

  /// 加载备份数据
  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前备份路径
      _currentPath = await BackupRegistryManager.getCurrentBackupPath();

      // 获取所有路径
      _allPaths = [];
      _pathBackups.clear();

      // 1. 添加当前路径（如果有）
      if (_currentPath != null) {
        _allPaths.add(_currentPath!);
        // 获取当前路径的备份
        final currentPathBackups =
            await BackupRegistryManager.getCurrentPathBackups();
        _pathBackups[_currentPath!] = currentPathBackups;
      }

      // 2. 获取历史路径
      final historyPaths = await BackupRegistryManager.getHistoryBackupPaths();

      // 3. 添加历史路径（排除当前路径）
      for (final path in historyPaths) {
        if (path != _currentPath && await Directory(path).exists()) {
          _allPaths.add(path);

          // 获取该历史路径的备份
          final historyPathBackups =
              await BackupRegistryManager.getHistoryPathBackups(path);
          _pathBackups[path] = historyPathBackups;
        }
      }

      // 4. 设置默认展开状态
      if (_expandedPaths.isEmpty && _allPaths.isNotEmpty) {
        _expandedPaths[_allPaths[0]] = true; // 默认展开第一个路径
      }

      AppLogger.info('加载备份数据完成', tag: 'BackupManagementUI', data: {
        'currentPath': _currentPath,
        'totalPaths': _allPaths.length,
        'totalBackups': _pathBackups.values.expand((x) => x).length,
      });
    } catch (e) {
      AppLogger.error('加载备份数据失败', error: e, tag: 'BackupManagementUI');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).loadDataFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && !_isCancelled) {
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
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'clean_duplicate_backups',
                child: Row(
                  children: [
                    const Icon(Icons.cleaning_services, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(l10n.cleanDuplicateRecords),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_all_backups',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.deleteAllBackups,
                        style: const TextStyle(color: Colors.red)),
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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent, // 移除分割线
        ),
        child: ExpansionTile(
          onExpansionChanged: (isExpanded) {
            setState(() {
              _expandedPaths[path] = isExpanded;
            });
          },
          initiallyExpanded: _expandedPaths[path] ?? false,
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
                  labelStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                ),
              if (!isCurrent)
                Chip(
                  label: Text(l10n.historicalPaths),
                  backgroundColor: Colors.orange,
                  labelStyle:
                      const TextStyle(color: Colors.white, fontSize: 12),
                ),
              const SizedBox(width: 8),
              Text(l10n.backupCount(backups.length)),
              const SizedBox(width: 8),
            ],
          ),
          leading: backups.isEmpty
              ? Icon(Icons.folder_open, color: Colors.grey.shade400)
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 改进的展开指示器，带提示和图标变化
              Tooltip(
                message: backups.isEmpty
                    ? l10n.noBackupsInPath
                    : (_expandedPaths[path] ?? false)
                        ? l10n.collapseFileList
                        : l10n.expandFileList(backups.length),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: backups.isEmpty
                        ? Colors.grey.shade100
                        : (_expandedPaths[path] ?? false)
                            ? Colors.blue.shade100
                            : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    backups.isEmpty
                        ? Icons.folder_open
                        : (_expandedPaths[path] ?? false)
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                    color: backups.isEmpty
                        ? Colors.grey.shade500
                        : (_expandedPaths[path] ?? false)
                            ? Colors.blue.shade700
                            : Colors.blue.shade600,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (action) =>
                    _handlePathAction(action, path, backups),
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
            ],
          ),
          children: [
            if (backups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(AppSizes.p16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(l10n.noBackupFilesInPathMessage,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            else ...[
              // 备份文件列表头部
              Container(
                color: Colors.grey.shade50,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.backup, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      l10n.backupFileListTitle(backups.length),
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              ...backups.map((backup) => _buildBackupTile(backup, path, l10n)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackupTile(
      BackupEntry backup, String path, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: backup.location == 'current'
              ? Colors.green.shade100
              : Colors.orange.shade100,
          child: Icon(
            backup.location == 'current' ? Icons.backup : Icons.history,
            color: backup.location == 'current'
                ? Colors.green.shade700
                : Colors.orange.shade700,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                backup.filename,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: backup.location == 'current'
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: backup.location == 'current'
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                ),
              ),
              child: Text(
                backup.location == 'current'
                    ? l10n.currentLabel
                    : l10n.historyLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: backup.location == 'current'
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (backup.description.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    backup.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat.yMd().add_Hm().format(backup.createdTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.storage, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    FileSizeFormatter.format(backup.size),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: PopupMenuButton<String>(
            onSelected: (action) => _handleBackupAction(action, backup, path),
            icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    const Icon(Icons.restore, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(l10n.restore),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download, color: Colors.green),
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
                      const Icon(Icons.import_export, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(l10n.importToCurrentPathButton),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(l10n.delete,
                        style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      case 'clean_duplicate_backups':
        await _cleanDuplicateBackups();
        break;
      case 'delete_all_backups':
        await _deleteAllBackups();
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
    if (!mounted) return;
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
    // 检查页面是否仍然挂载
    if (!mounted || _isCancelled) return;

    final l10n = AppLocalizations.of(context);

    try {
      // 获取当前备份路径进行基本检查
      final backupPath = await BackupRegistryManager.getCurrentBackupPath();
      if (backupPath == null) {
        throw Exception(l10n.pleaseSetBackupPathFirst);
      }

      // TODO: 未来可以添加更详细的备份前诊断
      AppLogger.info('备份前检查通过', tag: 'UnifiedBackupManagement');
    } catch (e) {
      // 基本检查失败
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.backupPreCheckFailed(e.toString())),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // 创建取消令牌
    bool isOperationCancelled = false;

    // 显示可取消的进度对话框
    final dialogCompleter = Completer<void>();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BackupProgressDialog(
        title: l10n.createBackup,
        message: l10n.backupMayTakeMinutes,
        onCancel: () {
          isOperationCancelled = true;
          Navigator.of(dialogContext).pop();
          dialogCompleter.complete();
        },
      ),
    ).then((_) {
      if (!dialogCompleter.isCompleted) {
        dialogCompleter.complete();
      }
    });

    try {
      final serviceLocator = ref.read(syncServiceLocatorProvider);
      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 创建备份 (添加15分钟超时)
      await Future.any([
        backupService.createBackup(description: description),
        Future.delayed(const Duration(minutes: 15), () {
          throw TimeoutException(
              l10n.backupOperationTimeoutError, const Duration(minutes: 15));
        }),
      ]);

      // 检查是否被取消
      if (isOperationCancelled || _isCancelled || !mounted) {
        if (mounted) {
          // 确保对话框关闭
          if (!dialogCompleter.isCompleted) {
            dialogCompleter.complete();
          }
          // 只关闭进度对话框，不关闭页面
          if (Navigator.of(context).canPop()) {
            final currentRoute = ModalRoute.of(context);
            if (currentRoute != null && !currentRoute.isFirst) {
              Navigator.of(context).pop();
            }
          }
        }
        return;
      }

      // 标记对话框应该关闭
      if (!dialogCompleter.isCompleted) {
        dialogCompleter.complete();
      }

      // 关闭进度对话框 - 只关闭对话框，不关闭页面
      if (mounted) {
        // 等待一小段时间确保对话框有时间关闭
        await Future.delayed(const Duration(milliseconds: 100));

        // 只关闭当前的进度对话框
        if (mounted && Navigator.of(context).canPop()) {
          final currentRoute = ModalRoute.of(context);
          if (currentRoute != null && !currentRoute.isFirst) {
            Navigator.of(context).pop();
          }
        }

        // 重新加载数据
        await _loadData();

        if (mounted && !_isCancelled && !isOperationCancelled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.backupSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // 标记对话框应该关闭
      if (!dialogCompleter.isCompleted) {
        dialogCompleter.complete();
      }

      // 错误时只关闭对话框，不关闭页面
      if (mounted) {
        // 等待一小段时间确保对话框有时间关闭
        await Future.delayed(const Duration(milliseconds: 100));

        // 只关闭当前的进度对话框
        if (mounted && Navigator.of(context).canPop()) {
          final currentRoute = ModalRoute.of(context);
          if (currentRoute != null && !currentRoute.isFirst) {
            Navigator.of(context).pop();
          }
        }

        if (!_isCancelled && !isOperationCancelled) {
          String errorMessage =
              '${l10n.createBackup} ${l10n.backupFailure}: $e';

          // 为超时错误提供更友好的消息
          if (e is TimeoutException) {
            errorMessage = l10n.backupTimeoutDetailedError;
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 8),
            ),
          );
        }
      }

      // 只在页面仍然挂载且未被取消时记录错误日志
      if (mounted && !_isCancelled && !isOperationCancelled) {
        AppLogger.error('Failed to create backup',
            error: e, tag: 'UnifiedBackupManagement');
      }
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context);
    // 选择备份文件
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: l10n.selectBackupFileToImportDialog,
      type: FileType.custom,
      allowedExtensions: ['cgb', 'zip'], // 支持新备份格式和旧格式
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
    if (!mounted || _isCancelled) return;

    final l10n = AppLocalizations.of(context);

    // 存储对话框上下文以便精确关闭
    BuildContext? dialogContext;

    try {
      // 首先检查是否有重复备份
      final duplicateBackup =
          await BackupRegistryManager.checkForDuplicateBackup(filePath);

      if (duplicateBackup != null) {
        // 显示重复文件确认对话框
        if (!mounted) return;
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(l10n.duplicateBackupFound),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.duplicateBackupFoundDesc),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.existingBackupInfo(duplicateBackup.filename)),
                      Text(l10n.backupCreationTime(DateFormat.yMd()
                          .add_Hm()
                          .format(duplicateBackup.createdTime))),
                      Text(l10n.backupSize(
                          FileSizeFormatter.format(duplicateBackup.size))),
                      if (duplicateBackup.checksum != null)
                        Text(l10n.backupChecksum(
                            duplicateBackup.checksum!.substring(0, 8))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.continueDuplicateImport),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelAction),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.continueImport),
              ),
            ],
          ),
        );

        if (shouldProceed != true) {
          return; // 用户选择取消导入
        }
      }

      // 显示进度对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext ctx) {
          dialogContext = ctx; // 保存对话框上下文
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSizes.p16),
                Text(l10n.importingBackupProgressMessage),
                const SizedBox(height: AppSizes.p8),
                Text(l10n.pleaseWaitMessage,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      );

      final serviceLocator = ref.read(syncServiceLocatorProvider);
      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 导入备份
      await backupService.importBackup(filePath);

      // 检查是否被取消
      if (_isCancelled || !mounted) {
        return;
      }

      // 强制关闭进度对话框
      if (dialogContext != null && mounted) {
        try {
          _safeCloseDialog(dialogContext);
          AppLogger.debug('导入进度对话框已关闭', tag: 'UnifiedBackupManagement');
        } catch (e) {
          AppLogger.warning('关闭导入进度对话框失败',
              tag: 'UnifiedBackupManagement', data: {'error': e.toString()});
          // 备用方案：使用原始上下文
          try {
            if (mounted) Navigator.of(context).pop();
          } catch (e2) {
            AppLogger.error('备用关闭方案也失败',
                tag: 'UnifiedBackupManagement', data: {'error': e2.toString()});
          }
        }
      }

      // 等待确保对话框关闭
      await Future.delayed(const Duration(milliseconds: 300));

      // 重新加载数据
      if (mounted) {
        await _loadData();
      }

      if (mounted && !_isCancelled) {
        final message = duplicateBackup != null
            ? '${l10n.backupImportSuccessMessage} ${l10n.duplicateFileImported}'
            : l10n.backupImportSuccessMessage;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // 确保对话框关闭
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (e2) {
          try {
            if (mounted) Navigator.of(context).pop();
          } catch (e3) {
            // 忽略
          }
        }
      }

      if (mounted && !_isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importBackupFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      // 只在页面仍然挂载且未被取消时记录错误日志
      if (mounted && !_isCancelled) {
        AppLogger.error('Failed to import backup',
            error: e, tag: 'UnifiedBackupManagement');
      }
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

  /// 清理重复的备份记录
  Future<void> _cleanDuplicateBackups() async {
    final l10n = AppLocalizations.of(context);

    // 显示确认对话框
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.cleaning_services, color: Colors.orange),
            const SizedBox(width: 8),
            Text(l10n.cleanDuplicateRecordsTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.cleanDuplicateRecordsDescription),
            const SizedBox(height: 8),
            Text(l10n.continueQuestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() => _isLoading = true);

      // 执行清理操作
      final removedCount = await BackupRegistryManager.removeDuplicateBackups();

      // 重新加载数据
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cleanupCompletedWithCount(removedCount)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('清理重复备份记录失败',
          error: e, tag: 'UnifiedBackupManagementPage');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.cleanupOperationFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteBackupPath(String path) async {
    final l10n = AppLocalizations.of(context);
    if (!mounted) return;
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
      if (!mounted) return;
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

    // 创建进度跟踪器
    final progressNotifier = ValueNotifier<int>(0);
    // 保存对话框上下文
    BuildContext? dialogContext;

    try {
      // 显示带进度的对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context; // 保存对话框上下文
          return AlertDialog(
            title: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text(l10n.exportingBackupsProgress),
              ],
            ),
            content: ValueListenableBuilder<int>(
              valueListenable: progressNotifier,
              builder: (context, progress, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.exportingBackupsProgressFormat(backups.length)),
                    const SizedBox(height: AppSizes.p8),
                    LinearProgressIndicator(
                      value: backups.isNotEmpty ? progress / backups.length : 0,
                    ),
                    const SizedBox(height: AppSizes.p8),
                    Text(l10n.processedProgress(progress, backups.length)),
                  ],
                );
              },
            ),
          );
        },
      );

      int successCount = 0;
      int failCount = 0;

      for (int i = 0; i < backups.length; i++) {
        final backup = backups[i];
        try {
          // 使用backup的fullPath而不是手动构建路径
          final targetFilePath = p.join(outputDirectory, backup.filename);

          final sourceFile = File(backup.fullPath);
          if (await sourceFile.exists()) {
            await sourceFile.copy(targetFilePath);
            successCount++;
          } else {
            failCount++;
            AppLogger.warning(l10n.backupFileNotFound,
                tag: 'UnifiedBackupManagement',
                data: {
                  'file': backup.fullPath,
                });
          }
        } catch (e) {
          failCount++;
          // 只在页面仍然挂载且未被取消时记录错误日志
          if (mounted && !_isCancelled) {
            AppLogger.error('Failed to export single backup',
                error: e,
                tag: 'UnifiedBackupManagement',
                data: {
                  'backup': backup.filename,
                  'fullPath': backup.fullPath,
                });
          }
        }

        // 更新进度
        progressNotifier.value = i + 1;

        // 给UI一些时间更新
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // 关闭进度对话框
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      // 显示结果
      if (mounted && !_isCancelled) {
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
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted && !_isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.batchExportFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      // 只在页面仍然挂载且未被取消时记录错误日志
      if (mounted && !_isCancelled) {
        AppLogger.error('Failed to batch export',
            error: e, tag: 'UnifiedBackupManagement');
      }
    } finally {
      // 确保清理资源
      progressNotifier.dispose();
    }
  }

  Future<void> _restoreBackup(BackupEntry backup) async {
    if (!mounted || _isCancelled) return;
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

    // 防止重复恢复操作
    if (_isProcessingRestore) {
      AppLogger.warning('已有恢复操作正在进行中', tag: 'UnifiedBackupManagementPage');
      return;
    }

    _isProcessingRestore = true;

    // 保存对话框上下文
    BuildContext? dialogContext;

    // 创建一个Completer来等待恢复完成
    final Completer<void> restoreCompleter = Completer<void>();

    // 显示进度对话框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context; // 保存对话框上下文
        return AlertDialog(
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
        );
      },
    );

    try {
      final serviceLocator = ref.read(syncServiceLocatorProvider);
      final backupService = serviceLocator.get<EnhancedBackupService>();

      // 恢复备份
      await backupService.restoreBackup(
        backup.id,
        onRestoreComplete: (needsRestart, message) async {
          try {
            AppLogger.info('备份恢复完成，处理重启逻辑',
                tag: 'UnifiedBackupManagementPage',
                data: {
                  'needsRestart': needsRestart,
                  'message': message,
                  'isProcessingRestore': _isProcessingRestore,
                  'mounted': mounted,
                  'isCancelled': _isCancelled,
                });

            // 立即检查Widget状态，如果已销毁则直接返回
            if (!mounted || _isCancelled) {
              AppLogger.warning('Widget已被销毁或已取消，跳过重启处理',
                  tag: 'UnifiedBackupManagementPage',
                  data: {
                    'mounted': mounted,
                    'isCancelled': _isCancelled,
                    'isProcessingRestore': _isProcessingRestore,
                  });
              restoreCompleter.complete();
              return;
            }

            if (needsRestart) {
              AppLogger.info('准备关闭进度对话框并显示重启提示',
                  tag: 'UnifiedBackupManagementPage');
              // 关闭当前进度对话框
              _safeCloseDialog(dialogContext);

              AppLogger.info('进度对话框关闭完成，开始延迟',
                  tag: 'UnifiedBackupManagementPage');

              // 延迟一小段时间确保对话框关闭
              await Future.delayed(const Duration(milliseconds: 300));

              AppLogger.info('延迟完成，检查Widget状态',
                  tag: 'UnifiedBackupManagementPage',
                  data: {
                    'mounted': mounted,
                    'isCancelled': _isCancelled,
                  });

              if (mounted && !_isCancelled) {
                AppLogger.info('开始显示成功消息', tag: 'UnifiedBackupManagementPage');

                // 显示成功消息
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.appWillRestartInSeconds(message)),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );

                AppLogger.info('成功消息显示完成，开始延迟重启流程',
                    tag: 'UnifiedBackupManagementPage');

                // 参考数据路径切换的方式，延迟重启
                Future.delayed(const Duration(seconds: 3), () {
                  AppLogger.info('延迟重启回调被调用',
                      tag: 'UnifiedBackupManagementPage',
                      data: {
                        'mounted': mounted,
                        'isCancelled': _isCancelled,
                      });

                  if (mounted && !_isCancelled) {
                    AppLogger.info('执行延迟重启',
                        tag: 'UnifiedBackupManagementPage');
                    AppRestartService.restartApp(context);
                  } else {
                    AppLogger.warning('延迟重启时Widget已被销毁',
                        tag: 'UnifiedBackupManagementPage',
                        data: {
                          'mounted': mounted,
                          'isCancelled': _isCancelled,
                        });
                  }
                });

                AppLogger.info('延迟重启已设置', tag: 'UnifiedBackupManagementPage');
              } else {
                AppLogger.warning('Widget状态检查失败，无法显示重启提示',
                    tag: 'UnifiedBackupManagementPage',
                    data: {
                      'mounted': mounted,
                      'isCancelled': _isCancelled,
                    });
              }
            } else {
              // 如果不需要重启，显示成功消息
              if (mounted && !_isCancelled) {
                _safeCloseDialog(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 5),
                  ),
                );
              }
            }
          } catch (e) {
            AppLogger.error('恢复回调处理失败',
                error: e, tag: 'UnifiedBackupManagementPage');
          } finally {
            // 无论如何都要完成Completer
            if (!restoreCompleter.isCompleted) {
              restoreCompleter.complete();
            }
          }
        },
        autoRestart: true, // 启用自动重启
      );

      // 等待恢复回调完成
      await restoreCompleter.future;

      AppLogger.info('恢复操作完全完成', tag: 'UnifiedBackupManagementPage');
    } catch (e) {
      // 关闭进度对话框
      _safeCloseDialog(dialogContext);

      // 只在页面仍然挂载且未被取消时显示错误消息
      if (!_isCancelled && mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupRestoreFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      // 只在页面仍然挂载且未被取消时记录错误日志
      if (mounted && !_isCancelled) {
        AppLogger.error('Failed to restore backup',
            error: e, tag: 'UnifiedBackupManagement');
      }
    } finally {
      // 重置恢复状态标志
      _isProcessingRestore = false;
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

    // 保存对话框上下文
    BuildContext? dialogContext;

    try {
      // 构建源文件路径 - 修复：直接使用backup.fullPath而不是尝试构建路径
      final sourcePath = backup.fullPath;
      final targetPath = p.join(outputDirectory, backup.filename);

      // 检查目标文件是否已存在
      final targetExists =
          await BackupRegistryManager.checkFileExistsAtPath(targetPath);

      if (targetExists) {
        // 显示文件重复确认对话框
        if (!mounted) return;
        final userChoice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(l10n.fileExistsTitle),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.targetLocationExists),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    targetPath,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.targetPathLabel),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('cancel'),
                child: Text(l10n.cancelAction),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('overwrite'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text(l10n.overwriteFile,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (userChoice == 'cancel') {
          return; // 用户取消导出
        }
        // 如果是 'overwrite'，保持原始路径不变
      }

      // 显示进度对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context; // 保存对话框上下文
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSizes.p16),
                Text(l10n.exportingBackupMessage),
                const SizedBox(height: AppSizes.p8),
                Text(l10n.pleaseWaitMessage,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      );

      // 复制文件
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('${l10n.sourceBackupFileNotFound}: $sourcePath');
      }

      await sourceFile.copy(targetPath);

      // 关闭进度对话框
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();

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
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportBackupFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }

      // 只在页面仍然挂载且未被取消时记录错误日志
      if (mounted && !_isCancelled) {
        AppLogger.error('Failed to export backup',
            error: e, tag: 'UnifiedBackupManagement');
      }
    }
  }

  Future<void> _importBackupToCurrentPath(BackupEntry backup) async {
    final l10n = AppLocalizations.of(context);
    // 显示确认对话框
    if (!mounted) return;
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

    // 保存对话框上下文
    BuildContext? dialogContext;

    try {
      if (_currentPath == null) {
        throw Exception(l10n.currentBackupPathNotSet);
      }

      // 构建源文件路径和目标文件路径
      final sourcePath = p.join(backup.id, backup.filename);
      final targetPath = p.join(_currentPath!, backup.filename);

      // 检查目标文件是否已存在
      final targetExists =
          await BackupRegistryManager.checkFileExistsAtPath(targetPath);

      if (targetExists) {
        // 显示文件重复确认对话框
        if (!mounted) return;
        final userChoice = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text(l10n.fileExistsTitle),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.currentPathFileExistsMessage),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    backup.filename,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.pleaseSelectOperation),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('cancel'),
                child: Text(l10n.cancelAction),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop('overwrite'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text(l10n.overwriteFileAction,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );

        if (userChoice == 'cancel') {
          return; // 用户取消导入
        }
        // 如果是 'overwrite'，保持原始路径不变
      }

      // 显示进度对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          dialogContext = context; // 保存对话框上下文
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSizes.p16),
                Text(l10n.importingToCurrentPathMessage),
                const SizedBox(height: AppSizes.p8),
                Text(l10n.pleaseWaitMessage,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      );

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

      // 重新加载数据
      await _loadData();

      // 关闭进度对话框
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted && !_isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.importToCurrentPathSuccessMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 关闭进度对话框
      if (mounted && dialogContext != null) {
        Navigator.of(dialogContext!).pop();
      }

      if (mounted && !_isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.importBackupFailedMessage}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // 只在页面仍然挂载且未被取消时记录错误日志
      if (mounted && !_isCancelled) {
        AppLogger.error('Failed to import backup to current path',
            error: e, tag: 'UnifiedBackupManagement');
      }
    }
  }

  Future<void> _deleteBackup(BackupEntry backup, String path) async {
    final l10n = AppLocalizations.of(context);
    // 显示确认对话框
    if (!mounted) return;
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
                .processLineBreaks),
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

      // 只在页面仍然挂载且未被取消时记录错误日志
      if (mounted && !_isCancelled) {
        AppLogger.error('Failed to delete backup',
            error: e, tag: 'UnifiedBackupManagement');
      }
    }
  }

  /// 删除所有备份
  Future<void> _deleteAllBackups() async {
    final l10n = AppLocalizations.of(context);

    // 计算总备份数
    final totalBackups = _pathBackups.values.expand((x) => x).length;

    if (totalBackups == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noBackupsToDelete),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 显示确认对话框
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            Text(l10n.confirmDeleteAllBackups),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteBackupsCountMessage(totalBackups)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.allBackupsDeleteWarning,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.deleteRangeTitle),
            ..._pathBackups.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child:
                    Text(l10n.deleteRangeItem(entry.key, entry.value.length)),
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
            child: Text(l10n.confirmDeleteAllButton,
                style: const TextStyle(color: Colors.white)),
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
    final l10n = AppLocalizations.of(context);

    // 计算总数用于进度显示
    final totalBackups = _pathBackups.values.expand((x) => x).length;

    // 创建一个ValueNotifier来跟踪进度
    final progressNotifier = ValueNotifier<int>(0);

    // 存储对话框上下文以便精确关闭
    BuildContext? dialogContext;

    // 显示进度对话框
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        dialogContext = ctx; // 保存对话框上下文
        return AlertDialog(
          title: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 16),
              Text(l10n.deletingBackups),
            ],
          ),
          content: ValueListenableBuilder<int>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.deletingBackupsProgress),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: totalBackups > 0 ? progress / totalBackups : 0,
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.processedCount(progress, totalBackups)),
                ],
              );
            },
          ),
        );
      },
    );

    try {
      int deletedCount = 0;
      int failedCount = 0;
      int processedCount = 0;
      List<String> failedFiles = [];

      AppLogger.info('开始删除所有备份', tag: 'UnifiedBackupManagement', data: {
        'totalPaths': _pathBackups.length,
        'totalBackups': totalBackups,
      });

      // 遍历所有路径的备份
      for (final entry in _pathBackups.entries) {
        final path = entry.key;
        final backups = entry.value;

        AppLogger.info('处理路径: $path',
            tag: 'UnifiedBackupManagement',
            data: {'backupCount': backups.length});

        for (final backup in backups) {
          try {
            AppLogger.debug('删除备份: ${backup.filename}',
                tag: 'UnifiedBackupManagement',
                data: {'fullPath': backup.fullPath});

            // 使用backup的fullPath而不是手动构建路径
            final backupFile = File(backup.fullPath);

            if (await backupFile.exists()) {
              await backupFile.delete();
              AppLogger.debug('文件删除成功: ${backup.fullPath}',
                  tag: 'UnifiedBackupManagement');
            } else {
              AppLogger.warning('文件不存在: ${backup.fullPath}',
                  tag: 'UnifiedBackupManagement');
            }

            // 从注册表中移除
            await BackupRegistryManager.deleteBackup(backup.id);
            AppLogger.debug('注册表删除成功: ${backup.id}',
                tag: 'UnifiedBackupManagement');

            deletedCount++;
          } catch (e) {
            failedCount++;
            failedFiles.add('${backup.filename}: $e');
            AppLogger.error('删除备份失败',
                error: e,
                tag: 'UnifiedBackupManagement',
                data: {
                  'backup': backup.filename,
                  'path': path,
                  'fullPath': backup.fullPath,
                  'backupId': backup.id,
                });
          }

          // 更新进度
          processedCount++;
          progressNotifier.value = processedCount;

          // 给UI一些时间更新
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }

      AppLogger.info('删除操作完成', tag: 'UnifiedBackupManagement', data: {
        'deletedCount': deletedCount,
        'failedCount': failedCount,
        'totalProcessed': processedCount,
      });

      // 强制关闭进度对话框
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!).pop();
          AppLogger.debug('进度对话框已关闭', tag: 'UnifiedBackupManagement');
        } catch (e) {
          AppLogger.warning('关闭进度对话框失败',
              tag: 'UnifiedBackupManagement', data: {'error': e.toString()});
          // 备用方案：使用原始上下文
          try {
            Navigator.of(context).pop();
          } catch (e2) {
            AppLogger.error('备用关闭方案也失败',
                tag: 'UnifiedBackupManagement', data: {'error': e2.toString()});
          }
        }
      }

      // 等待确保对话框关闭
      await Future.delayed(const Duration(milliseconds: 300));

      // 重新加载数据
      if (mounted) {
        await _loadData();
      }

      // 显示结果
      if (mounted) {
        if (failedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.successDeletedCount(deletedCount)),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // 显示部分失败的详细信息
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.deleteCompleteTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.deleteSuccessCount(deletedCount)),
                  if (failedCount > 0) ...[
                    Text(l10n.deleteFailCount(failedCount)),
                    const SizedBox(height: 8),
                    Text(l10n.deleteFailDetails,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ...failedFiles.take(5).map((error) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2),
                          child: Text('• $error',
                              style: const TextStyle(fontSize: 12)),
                        )),
                    if (failedFiles.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child:
                            Text(l10n.moreErrorsCount(failedFiles.length - 5)),
                      ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.done),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('删除所有备份失败',
          error: e,
          tag: 'UnifiedBackupManagement',
          data: {
            'totalBackups': totalBackups,
            'pathCount': _pathBackups.length,
          });

      // 确保对话框关闭
      if (dialogContext != null && mounted) {
        try {
          Navigator.of(dialogContext!).pop();
        } catch (e2) {
          try {
            Navigator.of(context).pop();
          } catch (e3) {
            // 忽略
          }
        }
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.deleteFailedMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 清理资源
      progressNotifier.dispose();
    }
  }

  /// 安全地关闭对话框，避免Widget生命周期问题
  void _safeCloseDialog(BuildContext? dialogContext) {
    AppLogger.info('_safeCloseDialog 被调用',
        tag: 'UnifiedBackupManagementPage',
        data: {
          'dialogContext': dialogContext != null ? 'not null' : 'null',
          'mounted': mounted,
          'isCancelled': _isCancelled,
        });

    if (dialogContext == null) {
      AppLogger.debug('对话框上下文为空，无需关闭', tag: 'UnifiedBackupManagementPage');
      return;
    }

    if (!mounted || _isCancelled) {
      AppLogger.warning('Widget已被销毁或已取消，无法安全关闭对话框',
          tag: 'UnifiedBackupManagementPage');
      return;
    }

    try {
      AppLogger.info('尝试关闭对话框', tag: 'UnifiedBackupManagementPage');

      // 检查Navigator是否仍然可用
      if (Navigator.canPop(dialogContext)) {
        AppLogger.info('Navigator.canPop 返回 true，开始关闭对话框',
            tag: 'UnifiedBackupManagementPage');
        Navigator.of(dialogContext).pop();
        AppLogger.debug('对话框关闭成功', tag: 'UnifiedBackupManagementPage');
      } else {
        AppLogger.debug('对话框无法弹出，可能已关闭', tag: 'UnifiedBackupManagementPage');
      }
    } catch (e) {
      AppLogger.warning('关闭对话框失败，可能是Widget已被销毁',
          error: e, tag: 'UnifiedBackupManagementPage');

      // 尝试备用方案
      if (mounted && !_isCancelled) {
        try {
          AppLogger.info('尝试备用关闭方案', tag: 'UnifiedBackupManagementPage');
          Navigator.of(context).pop();
          AppLogger.debug('备用关闭方案成功', tag: 'UnifiedBackupManagementPage');
        } catch (e2) {
          AppLogger.error('备用关闭方案也失败',
              error: e2, tag: 'UnifiedBackupManagementPage');
        }
      }
    }
  }
}
