import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

import '../../application/services/backup_registry_manager.dart';
import '../../application/services/data_path_config_service.dart';
import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/file_utils.dart';
import '../utils/localized_string_extensions.dart';

/// 备份路径设置界面
class BackupPathSettings extends StatefulWidget {
  const BackupPathSettings({Key? key}) : super(key: key);

  @override
  State<BackupPathSettings> createState() => _BackupPathSettingsState();
}

class _BackupPathSettingsState extends State<BackupPathSettings> {
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
              error: e, tag: 'BackupPathSettings');
        }
      }
    } catch (e) {
      AppLogger.error(l10n.loadCurrentBackupPathFailed,
          error: e, tag: 'BackupPathSettings');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectNewBackupPath() async {
    final l10n = AppLocalizations.of(context);
    try {
      // 🔧 修復：自動選擇在默認數據路徑下的backup目錄作為默認備份路徑
      String? initialDirectory;
      try {
        final defaultDataPath = await _getDefaultDataPath();
        initialDirectory = path.join(defaultDataPath, 'backup');
        
        // 確保備份目錄存在
        final backupDir = Directory(initialDirectory);
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
      } catch (e) {
        AppLogger.warning('無法創建默認備份目錄，使用系統默認路徑',
            error: e, tag: 'BackupPathSettings');
        initialDirectory = null;
      }

      final newPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: l10n.selectBackupStorageLocation,
        initialDirectory: initialDirectory,
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
          error: e, tag: 'BackupPathSettings');

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

  /// 獲取默認數據路徑
  Future<String> _getDefaultDataPath() async {
    return await DataPathConfigService.getDefaultDataPath();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.backupPathSettings),
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
