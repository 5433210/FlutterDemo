import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/backup_models.dart';
import '../../domain/models/config/data_path_config.dart';
import '../../infrastructure/logging/logger.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_restart_service.dart';
import 'backup_registry_manager.dart';
import 'data_path_config_service.dart';

/// 数据路径切换管理器
class DataPathSwitchManager {
  static const String _legacyDataPathsKey = 'legacy_data_paths';

  /// 检查数据路径切换前的建议
  static Future<BackupRecommendation> checkPreSwitchRecommendations(
      BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      // 1. 检查是否已设置备份路径
      final backupPath = await BackupRegistryManager.getCurrentBackupPath();

      if (backupPath == null) {
        return BackupRecommendation(
          needsBackupPath: true,
          recommendBackup: true,
          reason: l10n.noBackupPathSetRecommendCreateBackup,
        );
      }

      // 2. 检查最近备份时间
      final lastBackupTime = await _getLastBackupTime();
      final now = DateTime.now();

      if (lastBackupTime == null) {
        return BackupRecommendation(
          needsBackupPath: false,
          recommendBackup: true,
          reason: l10n.noBackupExistsRecommendCreate,
        );
      }

      if (now.difference(lastBackupTime).inHours > 24) {
        return BackupRecommendation(
          needsBackupPath: false,
          recommendBackup: true,
          reason: l10n.oldBackupRecommendCreateNew,
        );
      }

      return BackupRecommendation(
        needsBackupPath: false,
        recommendBackup: false,
        reason: l10n.recentBackupCanSwitch,
      );
    } catch (e, stack) {
      AppLogger.error('检查数据路径切换建议失败',
          error: e, stackTrace: stack, tag: 'DataPathSwitchManager');

      return BackupRecommendation(
        needsBackupPath: true,
        recommendBackup: true,
        reason: l10n.checkFailedRecommendBackup,
      );
    }
  }

  /// 显示备份建议对话框
  static Future<BackupChoice> showBackupRecommendationDialog(
    BuildContext context,
    BackupRecommendation recommendation,
  ) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<BackupChoice>(
          context: context,
          barrierDismissible: true, // 允许点击外部关闭
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(l10n.dataSafetySuggestions),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.safetyTip,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(recommendation.reason),
                const SizedBox(height: 8),
                Text(l10n.backupEnsuresDataSafety),
                Text(l10n.quickRecoveryOnIssues),
                Text(l10n.canChooseDirectSwitch),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, BackupChoice.cancel),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, BackupChoice.skipBackup),
                child: Text(l10n.directSwitch),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, BackupChoice.createBackup),
                child: Text(l10n.backupFirst),
              ),
            ],
          ),
        ) ??
        BackupChoice.cancel;
  }

  /// 显示数据路径切换确认对话框
  static Future<bool> showDataPathSwitchConfirmDialog(
    BuildContext context,
    String newPath,
  ) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.confirmDataPathSwitch),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.newDataPath),
                const SizedBox(height: 8),
                Text(
                  newPath,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(l10n.notesTitle),
                Text(l10n.oldDataNotAutoDeleted),
                Text(l10n.canManuallyCleanLater),
                Text(l10n.confirmDataNormalBeforeClean),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.confirmSwitch),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 执行数据路径切换
  static Future<void> performDataPathSwitch(
      String newPath, BuildContext context) async {
    try {
      AppLogger.info('开始数据路径切换', tag: 'DataPathSwitchManager', data: {
        'newPath': newPath,
      });

      // 获取本地化字符串，避免在异步间隔后访问context
      final l10n = AppLocalizations.of(context);
      
      // 获取当前配置
      final currentConfig = await DataPathConfigService.readConfig();
      final oldPath = await currentConfig.getActualDataPath();

      // 1. 记录旧数据路径
      if (oldPath != newPath) {
        // 使用新的方法记录历史数据路径
        await DataPathConfigService.addHistoryDataPath(oldPath);

        // 为了向后兼容，同时也记录到旧的系统中
        await _recordLegacyDataPath(oldPath, l10n.legacyDataPathDescription);
      }

      // 2. 验证新路径
      final validationResult =
          await DataPathConfigService.validatePath(newPath);
      if (!validationResult.isValid) {
        throw Exception('路径验证失败: ${validationResult.errorMessage}');
      }

      // 3. 创建新配置并保存
      // 重新读取配置以获取更新后的历史路径
      final updatedConfig = await DataPathConfigService.readConfig();
      final newConfig = DataPathConfig.withCustomPath(
        newPath,
        historyPaths: updatedConfig.historyPaths,
      );

      await DataPathConfigService.writeConfig(newConfig);

      // 4. 确保新路径存在
      final newDirectory = Directory(newPath);
      if (!await newDirectory.exists()) {
        await newDirectory.create(recursive: true);
      }

      // 5. 写入数据版本信息
      await DataPathConfigService.writeDataVersion(newPath);

      AppLogger.info('数据路径切换完成，准备重启应用', tag: 'DataPathSwitchManager', data: {
        'oldPath': oldPath,
        'newPath': newPath,
        'historyPaths': newConfig.historyPaths,
      });

      // 6. 延迟一段时间后重启应用，让UI有时间显示成功消息
      // 定义重启函数，避免使用函数变量
      void restartApp() {
        try {
          AppRestartService.restartApp(context);
        } catch (e) {
          AppLogger.error('延迟重启应用时发生错误',
              error: e, tag: 'DataPathSwitchManager');
        }
      }
      
      Future.delayed(const Duration(milliseconds: 1500), restartApp);
    } catch (e, stack) {
      AppLogger.error('数据路径切换失败',
          error: e, stackTrace: stack, tag: 'DataPathSwitchManager');
      rethrow;
    }
  }

  /// 获取当前数据路径
  static Future<String?> getCurrentDataPath() async {
    try {
      final config = await DataPathConfigService.readConfig();
      return await config.getActualDataPath();
    } catch (e, stack) {
      AppLogger.error('获取当前数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathSwitchManager');
      return null;
    }
  }

  /// 记录旧数据路径
  static Future<void> _recordLegacyDataPath(
      String oldPath, [String? description]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyPathsJson = prefs.getStringList(_legacyDataPathsKey) ?? [];

      // 计算目录大小
      final sizeEstimate = await _calculateDirectorySize(oldPath);

      // 生成唯一ID
      final id = 'legacy_${DateTime.now().millisecondsSinceEpoch}';

      final legacyPath = LegacyDataPath(
        id: id,
        path: oldPath,
        switchedTime: DateTime.now(),
        sizeEstimate: sizeEstimate,
        status: 'pending_cleanup',
        description: description ?? 'Legacy data path from previous switch',
      );

      legacyPathsJson.add(legacyPath.toJson().toString());
      await prefs.setStringList(_legacyDataPathsKey, legacyPathsJson);

      AppLogger.info('记录旧数据路径', tag: 'DataPathSwitchManager', data: {
        'oldPath': oldPath,
        'sizeEstimate': sizeEstimate,
      });
    } catch (e, stack) {
      AppLogger.error('记录旧数据路径失败',
          error: e, stackTrace: stack, tag: 'DataPathSwitchManager');
    }
  }

  /// 获取最后备份时间
  static Future<DateTime?> _getLastBackupTime() async {
    try {
      final backups = await BackupRegistryManager.getAllBackups();
      if (backups.isEmpty) return null;

      return backups
          .map((backup) => backup.createdTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    } catch (e) {
      AppLogger.warning('获取最后备份时间失败', error: e, tag: 'DataPathSwitchManager');
      return null;
    }
  }

  /// 计算目录大小
  static Future<int> _calculateDirectorySize(String path) async {
    try {
      final directory = Directory(path);
      if (!await directory.exists()) return 0;

      int totalSize = 0;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            totalSize += size;
          } catch (e) {
            // 忽略无法访问的文件
          }
        }
      }
      return totalSize;
    } catch (e) {
      AppLogger.warning('计算目录大小失败', error: e, tag: 'DataPathSwitchManager');
      return 0;
    }
  }

  /// 验证路径有效性
  static Future<bool> validatePath(String path) async {
    try {
      final directory = Directory(path);

      // 检查路径是否存在或可以创建
      if (!await directory.exists()) {
        try {
          await directory.create(recursive: true);
          // 创建成功后删除测试目录
          await directory.delete();
          return true;
        } catch (e) {
          return false;
        }
      }

      // 检查是否有写入权限
      final testFile = File('$path${Platform.pathSeparator}test_write.tmp');
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
        return true;
      } catch (e) {
        return false;
      }
    } catch (e) {
      AppLogger.warning('验证路径有效性失败', error: e, tag: 'DataPathSwitchManager');
      return false;
    }
  }

  /// 获取路径可用空间
  static Future<int> getAvailableSpace(String path) async {
    try {
      final directory = Directory(path);
      // 检查目录是否存在
      if (!await directory.exists()) {
        return 0;
      }

      // 这里需要根据平台实现获取可用空间
      // 暂时返回0，实际实现需要使用平台特定的API
      return 0;
    } catch (e) {
      AppLogger.warning('获取路径可用空间失败', error: e, tag: 'DataPathSwitchManager');
      return 0;
    }
  }

  /// 显示数据路径切换确认对话框（包含合并选项）
  static Future<PathSwitchOptions?> showAdvancedDataPathSwitchDialog(
    BuildContext context,
    String newPath,
  ) async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<PathSwitchOptions>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.swap_horiz, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.dataPathSwitchOptions),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.newDataPath),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                newPath,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dataMergeOptions,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _PathSwitchOptionsWidget(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              const options = PathSwitchOptions(
                mergeBackupData: true,
                migrateFiles: false,
              );
              Navigator.pop(context, options);
            },
            child: Text(l10n.mergeOnlyBackupInfo),
          ),
          ElevatedButton(
            onPressed: () {
              const options = PathSwitchOptions(
                mergeBackupData: true,
                migrateFiles: true,
              );
              Navigator.pop(context, options);
            },
            child: Text(l10n.mergeAndMigrateFiles),
          ),
        ],
      ),
    );
  }

  /// 执行高级数据路径切换
  static Future<void> executeAdvancedPathSwitch(
    String newPath,
    PathSwitchOptions options,
  ) async {
    try {
      await BackupRegistryManager.switchBackupPathWithOptions(
        newPath,
        mergeHistoryBackups: options.mergeBackupData,
        migrateFiles: options.migrateFiles,
      );
    } catch (e, stack) {
      AppLogger.error('执行高级路径切换失败',
          error: e, stackTrace: stack, tag: 'DataPathSwitchManager');
      rethrow;
    }
  }
}

/// 路径切换选项
class PathSwitchOptions {
  /// 是否合并备份数据
  final bool mergeBackupData;

  /// 是否迁移文件
  final bool migrateFiles;

  const PathSwitchOptions({
    required this.mergeBackupData,
    required this.migrateFiles,
  });
}

/// 路径切换选项 Widget
class _PathSwitchOptionsWidget extends StatefulWidget {
  @override
  _PathSwitchOptionsWidgetState createState() =>
      _PathSwitchOptionsWidgetState();
}

class _PathSwitchOptionsWidgetState extends State<_PathSwitchOptionsWidget> {
  bool _mergeBackupData = true;
  bool _migrateFiles = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        CheckboxListTile(
          title: Text(l10n.mergeBackupInfo),
          subtitle: Text(l10n.mergeBackupInfoDesc),
          value: _mergeBackupData,
          onChanged: (value) {
            setState(() {
              _mergeBackupData = value ?? true;
            });
          },
        ),
        CheckboxListTile(
          title: Text(l10n.migrateBackupFiles),
          subtitle: Text(l10n.migrateBackupFilesDesc),
          value: _migrateFiles,
          onChanged: (value) {
            setState(() {
              _migrateFiles = value ?? false;
            });
          },
        ),
        if (!_migrateFiles)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.fileMigrationWarning,
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
