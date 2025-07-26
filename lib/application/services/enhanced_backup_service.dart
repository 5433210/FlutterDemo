import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';
import 'backup_registry_manager.dart';
import 'backup_service.dart';
import 'data_path_config_service.dart';
import 'unified_upgrade_service.dart';

/// 增强的备份服务
/// 基于配置文件的备份管理，支持多位置备份统一管理
class EnhancedBackupService {
  /// 应用重启后检查并完成备份恢复（第四阶段）
  static Future<void> checkAndCompleteRestoreAfterRestart(
      String dataPath) async {
    final markerFilePath = path.join(dataPath, 'restore_pending.json');
    AppLogger.info('检查是否有待完成的备份恢复', tag: 'EnhancedBackupService', data: {
      'dataPath': dataPath,
      'markerFilePath': markerFilePath,
    });

    final markerFile = File(markerFilePath);

    if (!await markerFile.exists()) {
      AppLogger.debug('没有找到恢复标记文件', tag: 'EnhancedBackupService', data: {
        'markerFilePath': markerFilePath,
        'exists': false,
      });
      return;
    }

    try {
      // 读取恢复标记文件
      final markerContent = await markerFile.readAsString();
      final markerData = json.decode(markerContent) as Map<String, dynamic>;

      final tempRestoreDir = markerData['temp_restore_dir'] as String;
      final backupId = markerData['backup_id'] as String;
      final backupFilename = markerData['backup_filename'] as String;

      AppLogger.info('发现待完成的备份恢复', tag: 'EnhancedBackupService', data: {
        'backupId': backupId,
        'backupFilename': backupFilename,
        'tempRestoreDir': tempRestoreDir,
      });

      // 检查临时恢复目录是否存在
      final tempDirectory = Directory(tempRestoreDir);
      if (!await tempDirectory.exists()) {
        AppLogger.error('临时恢复目录不存在', tag: 'EnhancedBackupService', data: {
          'tempRestoreDir': tempRestoreDir,
        });
        await markerFile.delete();
        return;
      }

      // 执行恢复操作
      await _performRestoreFromTempDirectory(
          tempRestoreDir, '$dataPath/storage');

      // 清理临时目录
      await tempDirectory.delete(recursive: true);

      // 删除标记文件
      await markerFile.delete();

      AppLogger.info('备份恢复完成', tag: 'EnhancedBackupService', data: {
        'backupId': backupId,
        'backupFilename': backupFilename,
      });
    } catch (e, stack) {
      AppLogger.error('完成备份恢复时发生错误',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');

      // 发生错误时，仍然尝试清理标记文件
      try {
        await markerFile.delete();
      } catch (deleteError) {
        AppLogger.warning('删除恢复标记文件失败',
            error: deleteError, tag: 'EnhancedBackupService');
      }
    }
  }

  /// 从临时目录执行恢复操作
  static Future<void> _performRestoreFromTempDirectory(
      String tempRestoreDir, String dataPath) async {
    AppLogger.info('开始从临时目录恢复数据', tag: 'EnhancedBackupService', data: {
      'tempRestoreDir': tempRestoreDir,
      'dataPath': dataPath,
    });

    // 确保目标数据目录存在
    await Directory(dataPath).create(recursive: true);

    // 1. 恢复 data 目录下的所有子目录到 dataPath
    final dataDir = Directory(path.join(tempRestoreDir, 'data'));
    if (await dataDir.exists()) {
      await for (final entity in dataDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath = path.relative(entity.path, from: dataDir.path);
          final targetFilePath = path.join(dataPath, relativePath);
          final targetDir = path.dirname(targetFilePath);

          await Directory(targetDir).create(recursive: true);

          try {
            // 如果目标文件已存在，先删除
            if (await File(targetFilePath).exists()) {
              await File(targetFilePath).delete();
            }

            await entity.copy(targetFilePath);

            AppLogger.debug('文件恢复完成', tag: 'EnhancedBackupService', data: {
              'source': entity.path,
              'target': targetFilePath,
            });
          } catch (e) {
            AppLogger.error('文件恢复失败', tag: 'EnhancedBackupService', data: {
              'source': entity.path,
              'target': targetFilePath,
              'error': e.toString(),
            });
          }
        }
      }
    }

    // 2. 恢复 database 目录到 dataPath/database
    final databaseDir = Directory(path.join(tempRestoreDir, 'database'));
    if (await databaseDir.exists()) {
      final targetDatabaseDir = Directory(path.join(dataPath, 'database'));
      await targetDatabaseDir.create(recursive: true);

      await for (final entity in databaseDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath =
              path.relative(entity.path, from: databaseDir.path);
          final targetFilePath =
              path.join(targetDatabaseDir.path, relativePath);
          final targetDir = path.dirname(targetFilePath);

          await Directory(targetDir).create(recursive: true);

          try {
            // 如果目标文件已存在，先删除
            if (await File(targetFilePath).exists()) {
              await File(targetFilePath).delete();
            }

            await entity.copy(targetFilePath);

            AppLogger.debug('数据库文件恢复完成', tag: 'EnhancedBackupService', data: {
              'source': entity.path,
              'target': targetFilePath,
            });
          } catch (e) {
            AppLogger.error('数据库文件恢复失败', tag: 'EnhancedBackupService', data: {
              'source': entity.path,
              'target': targetFilePath,
              'error': e.toString(),
            });
          }
        }
      }
      // // 数据库恢复标记逻辑：app.db -> app.db.new，并创建 db_ready_to_restore 文件
      // final restoredDbFile = File(path.join(databaseDir.path, 'app.db'));
      // if (await restoredDbFile.exists()) {
      //   final newDbFile = File(path.join(targetDatabaseDir.path, 'app.db.new'));
      //   await restoredDbFile.copy(newDbFile.path);
      //   final readyFile =
      //       File(path.join(targetDatabaseDir.path, 'db_ready_to_restore'));
      //   await readyFile.writeAsString('ready');
      //   AppLogger.info('数据库恢复标记已设置', tag: 'EnhancedBackupService', data: {
      //     'dbFile': newDbFile.path,
      //     'readyFile': readyFile.path,
      //   });
      // }
    }

    AppLogger.info('从临时目录恢复数据完成', tag: 'EnhancedBackupService');
  }

  /// 应用重启后自动恢复临时目录内容
  static Future<void> restorePendingFilesAfterRestart(String dataPath) async {
    final tempRestoreDir = Directory(path.join(dataPath, 'temp_restore'));
    if (await tempRestoreDir.exists()) {
      await for (final entity in tempRestoreDir.list(recursive: true)) {
        if (entity is File) {
          final relativePath =
              path.relative(entity.path, from: tempRestoreDir.path);
          final targetFilePath = path.join(dataPath, relativePath);
          final targetDir = path.dirname(targetFilePath);
          await Directory(targetDir).create(recursive: true);
          try {
            if (await File(targetFilePath).exists()) {
              await File(targetFilePath).delete();
            }
            await entity.rename(targetFilePath);
            AppLogger.info('重启后恢复临时文件', tag: 'EnhancedBackupService', data: {
              'source': entity.path,
              'target': targetFilePath,
              'result': 'success',
            });
          } catch (e) {
            AppLogger.error('重启后恢复临时文件失败', tag: 'EnhancedBackupService', data: {
              'source': entity.path,
              'target': targetFilePath,
              'result': 'fail',
              'error': e.toString(),
            });
          }
        }
      }
      await tempRestoreDir.delete(recursive: true);
      AppLogger.info('临时恢复目录已清理', tag: 'EnhancedBackupService');
    }
  }

  final BackupService _backupService;

  EnhancedBackupService({
    required BackupService backupService,
  }) : _backupService = backupService;

  /// 创建备份
  Future<void> createBackup({String? description}) async {
    try {
      AppLogger.info('开始创建增强备份', tag: 'EnhancedBackupService');

      // 1. 获取当前备份路径
      final backupPath = await BackupRegistryManager.getCurrentBackupPath();

      if (backupPath == null) {
        throw Exception('Please set backup path first');
      }

      // 2. 使用原始备份服务创建备份
      final backupFilePath =
          await _backupService.createBackup(description: description);

      // 3. 获取备份文件信息
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file creation failed');
      }

      // 4. 移动备份文件到指定位置（如果不在当前备份路径）
      final targetPath =
          await _moveBackupToTargetLocation(backupFile, backupPath);

      // 5. 计算校验和
      final checksum =
          await BackupRegistryManager.calculateChecksum(File(targetPath));

      // 6. 创建备份条目
      final backupEntry = BackupEntry(
        id: _generateId(),
        filename: path.basename(targetPath),
        fullPath: targetPath,
        size: await File(targetPath).length(),
        createdTime: DateTime.now(),
        location: 'current',
        description: description ?? 'Manually created backup',
        checksum: checksum,
        appVersion: await _getAppVersion(),
      );

      // 7. 添加到注册表
      await BackupRegistryManager.addBackup(backupEntry);

      AppLogger.info('增强备份创建成功', tag: 'EnhancedBackupService', data: {
        'backupId': backupEntry.id,
        'filename': backupEntry.filename,
        'size': backupEntry.size,
        'path': targetPath,
      });
    } catch (e, stack) {
      AppLogger.error('创建增强备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 获取所有备份
  Future<List<BackupEntry>> getBackups() async {
    try {
      // 首先尝试获取所有路径下的备份（多路径支持）
      final allBackups = await getAllBackupsFromAllPaths();

      if (allBackups.isNotEmpty) {
        AppLogger.info('从多路径获取所有备份成功', tag: 'EnhancedBackupService', data: {
          'backupCount': allBackups.length,
        });
        return allBackups;
      }

      // 如果多路径扫描失败，回退到原始方法
      final backups = await BackupRegistryManager.getAllBackups();

      AppLogger.info('从注册表获取所有备份成功', tag: 'EnhancedBackupService', data: {
        'backupCount': backups.length,
      });

      return backups;
    } catch (e, stack) {
      AppLogger.error('获取所有备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');

      // 如果配置文件不存在，回退到扫描文件系统
      try {
        AppLogger.info('回退到文件系统扫描', tag: 'EnhancedBackupService');
        final backupInfos = await _backupService.getBackups();

        // 转换为 BackupEntry 格式
        return backupInfos
            .map((info) => BackupEntry(
                  id: _generateId(),
                  filename: info.fileName,
                  fullPath: info.path,
                  size: info.size,
                  createdTime: info.creationTime,
                  location: 'legacy',
                  description: info.description ?? 'Legacy backup',
                ))
            .toList();
      } catch (fallbackError) {
        AppLogger.warning('文件系统扫描也失败',
            error: fallbackError, tag: 'EnhancedBackupService');
        return [];
      }
    }
  }

  /// 获取所有备份路径（包括历史路径）
  Future<List<String>> getAllBackupPaths() async {
    try {
      final paths = <String>[];

      // 1. 获取当前备份路径
      final currentPath = await BackupRegistryManager.getCurrentBackupPath();
      if (currentPath != null) {
        paths.add(currentPath);
      }

      // 2. 获取历史备份路径（从SharedPreferences或配置文件中获取）
      try {
        final historyPaths = await _getHistoryBackupPaths();
        for (final path in historyPaths) {
          if (!paths.contains(path) && await Directory(path).exists()) {
            paths.add(path);
          }
        }
      } catch (e) {
        AppLogger.warning('获取历史备份路径失败', error: e, tag: 'EnhancedBackupService');
      }

      return paths;
    } catch (e, stack) {
      AppLogger.error('获取所有备份路径失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      return [];
    }
  }

  /// 获取历史备份路径
  Future<List<String>> _getHistoryBackupPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyPathsJson =
          prefs.getStringList('backup_history_paths') ?? [];
      return historyPathsJson;
    } catch (e) {
      AppLogger.warning('读取历史备份路径失败', error: e, tag: 'EnhancedBackupService');
      return [];
    }
  }

  /// 删除备份
  Future<void> deleteBackup(String backupId) async {
    try {
      await BackupRegistryManager.deleteBackup(backupId);

      AppLogger.info('删除备份成功', tag: 'EnhancedBackupService', data: {
        'backupId': backupId,
      });
    } catch (e, stack) {
      AppLogger.error('删除备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 恢复备份（新的分阶段流程）
  /// 支持通过 backupId 或文件名来查找备份
  Future<void> restoreBackup(
    String backupIdOrFilename, {
    void Function(bool needsRestart, String message)? onRestoreComplete,
    bool autoRestart = false,
  }) async {
    try {
      final registry = await BackupRegistryManager.getRegistry();

      // 首先尝试通过ID查找
      BackupEntry? backup = registry.getBackup(backupIdOrFilename);

      // 如果通过ID找不到，尝试通过文件名查找
      backup ??= registry.backups.cast<BackupEntry?>().firstWhere(
            (b) => b?.filename == backupIdOrFilename,
            orElse: () => null,
          );

      if (backup == null) {
        throw Exception('Backup not found: $backupIdOrFilename');
      }

      // 阶段1：核验备份文件
      AppLogger.info('开始核验备份文件', tag: 'EnhancedBackupService', data: {
        'backupId': backup.id,
        'filename': backup.filename,
      });

      final isValid = await _verifyBackupFile(backup);
      if (!isValid) {
        throw Exception('Backup file verification failed');
      }

      // 阶段2：解压到临时目录
      AppLogger.info('开始解压备份文件到临时目录', tag: 'EnhancedBackupService');
      final tempRestoreDir = await _extractBackupToTempDirectory(backup);

      // 阶段3：创建恢复标记文件并重启应用
      AppLogger.info('创建恢复标记文件并准备重启', tag: 'EnhancedBackupService');
      await _createRestoreMarker(tempRestoreDir, backup);

      // 调用回调函数，通知需要重启
      if (onRestoreComplete != null) {
        onRestoreComplete(
            true, 'Backup file is ready, restart required to complete restore');
      }

      AppLogger.info('备份恢复准备完成，等待重启', tag: 'EnhancedBackupService', data: {
        'backupId': backup.id,
        'tempRestoreDir': tempRestoreDir,
      });
    } catch (e, stack) {
      AppLogger.error('恢复备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 验证备份文件完整性（第一阶段）
  Future<bool> _verifyBackupFile(BackupEntry backup) async {
    try {
      // 1. 检查文件是否存在
      final backupFile = File(backup.fullPath);
      if (!await backupFile.exists()) {
        AppLogger.error('备份文件不存在', tag: 'EnhancedBackupService', data: {
          'path': backup.fullPath,
        });
        return false;
      }

      // 2. 检查文件大小
      final actualSize = await backupFile.length();
      if (actualSize != backup.size) {
        AppLogger.error('备份文件大小不匹配', tag: 'EnhancedBackupService', data: {
          'expected': backup.size,
          'actual': actualSize,
        });
        return false;
      }

      // 3. 验证校验和（如果有的话）
      if (backup.checksum != null) {
        final actualChecksum =
            await BackupRegistryManager.calculateChecksum(backupFile);
        if (actualChecksum != backup.checksum) {
          AppLogger.error('备份文件校验和不匹配', tag: 'EnhancedBackupService', data: {
            'expected': backup.checksum,
            'actual': actualChecksum,
          });
          return false;
        }
      }

      // 4. 验证ZIP文件格式
      try {
        final zipBytes = await backupFile.readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);

        // 检查是否包含必要的目录
        bool hasDatabase = false;
        bool hasData = false;

        for (final file in archive) {
          if (file.name.startsWith('database/')) {
            hasDatabase = true;
          } else if (file.name.startsWith('data/')) {
            hasData = true;
          }
        }

        if (!hasDatabase || !hasData) {
          AppLogger.error('备份文件缺少必要的目录结构', tag: 'EnhancedBackupService', data: {
            'hasDatabase': hasDatabase,
            'hasData': hasData,
          });
          return false;
        }
      } catch (e) {
        AppLogger.error('备份文件ZIP格式验证失败',
            tag: 'EnhancedBackupService', error: e);
        return false;
      }

      AppLogger.info('备份文件核验通过', tag: 'EnhancedBackupService');
      return true;
    } catch (e, stack) {
      AppLogger.error('验证备份文件时发生错误',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      return false;
    }
  }

  /// 解压备份文件到临时目录（第二阶段）
  Future<String> _extractBackupToTempDirectory(BackupEntry backup) async {
    try {
      // 获取当前数据路径
      final config = await DataPathConfigService.readConfig();
      final currentDataPath = await config.getActualDataPath();

      // 创建临时恢复目录
      final tempRestoreDir = path.join(currentDataPath, 'temp_restore');
      final tempDirectory = Directory(tempRestoreDir);

      // 如果临时目录已存在，先清理
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }

      await tempDirectory.create(recursive: true);

      // 解压备份文件
      final backupFile = File(backup.fullPath);
      final zipBytes = await backupFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      for (final file in archive) {
        final filePath = path.join(tempRestoreDir, file.name);

        if (file.isFile) {
          // 创建文件目录
          final fileDir = path.dirname(filePath);
          await Directory(fileDir).create(recursive: true);

          // 写入文件内容
          await File(filePath).writeAsBytes(file.content as List<int>);
        } else {
          // 创建目录
          await Directory(filePath).create(recursive: true);
        }
      }

      AppLogger.info('备份文件解压完成', tag: 'EnhancedBackupService', data: {
        'tempRestoreDir': tempRestoreDir,
        'fileCount': archive.length,
      });

      // 检查并处理数据版本兼容性
      await _processBackupVersionCompatibility(tempRestoreDir, currentDataPath);

      return tempRestoreDir;
    } catch (e, stack) {
      AppLogger.error('解压备份文件到临时目录失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 处理备份版本兼容性和数据升级
  Future<void> _processBackupVersionCompatibility(
      String tempRestoreDir, String currentDataPath) async {
    try {
      // 检查是否存在 backup_info.json 文件
      final backupInfoFile =
          File(path.join(tempRestoreDir, 'backup_info.json'));

      if (!await backupInfoFile.exists()) {
        AppLogger.warning('备份信息文件不存在，跳过版本兼容性检查', tag: 'EnhancedBackupService');
        return;
      }

      // 读取备份信息
      final backupInfoContent = await backupInfoFile.readAsString();
      final backupInfo = json.decode(backupInfoContent) as Map<String, dynamic>;

      final backupDataVersion = backupInfo['dataVersion'] as String?;

      if (backupDataVersion == null) {
        AppLogger.warning('备份信息中缺少数据版本信息，跳过版本兼容性检查',
            tag: 'EnhancedBackupService');
        return;
      }

      AppLogger.info('开始处理备份版本兼容性', tag: 'EnhancedBackupService', data: {
        'backupDataVersion': backupDataVersion,
      });

      // 使用统一升级服务处理版本兼容性
      final upgradeResult = await UnifiedUpgradeService.upgradeForRestore(
        currentDataPath,
        backupDataVersion,
      );

      switch (upgradeResult.status) {
        case RestoreUpgradeStatus.compatible:
          AppLogger.info('备份数据版本兼容，无需升级', tag: 'EnhancedBackupService');
          break;

        case RestoreUpgradeStatus.upgraded:
          AppLogger.info('备份数据已成功升级', tag: 'EnhancedBackupService', data: {
            'fromVersion': upgradeResult.fromVersion,
            'toVersion': upgradeResult.toVersion,
          });
          break;

        case RestoreUpgradeStatus.appUpgradeRequired:
          throw Exception('需要升级应用程序才能恢复此备份。备份数据版本: $backupDataVersion');

        case RestoreUpgradeStatus.incompatible:
          throw Exception('备份数据版本不兼容，无法恢复。备份数据版本: $backupDataVersion');

        case RestoreUpgradeStatus.error:
          throw Exception('处理备份版本兼容性时发生错误: ${upgradeResult.errorMessage}');
      }
    } catch (e, stack) {
      AppLogger.error('处理备份版本兼容性失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 创建恢复标记文件（第三阶段）
  Future<void> _createRestoreMarker(
      String tempRestoreDir, BackupEntry backup) async {
    try {
      // 获取当前数据路径
      final config = await DataPathConfigService.readConfig();
      final currentDataPath = await config.getActualDataPath();

      // 创建标记文件
      final markerFile =
          File(path.join(currentDataPath, 'restore_pending.json'));

      final markerData = {
        'timestamp': DateTime.now().toIso8601String(),
        'backup_id': backup.id,
        'backup_filename': backup.filename,
        'backup_description': backup.description,
        'temp_restore_dir': tempRestoreDir,
        'data_path': currentDataPath,
        'restore_stage': 'pending',
      };

      await markerFile.writeAsString(json.encode(markerData));

      AppLogger.info('恢复标记文件创建完成', tag: 'EnhancedBackupService', data: {
        'markerFile': markerFile.path,
        'tempRestoreDir': tempRestoreDir,
      });
    } catch (e, stack) {
      AppLogger.error('创建恢复标记文件失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 验证备份完整性
  Future<bool> verifyBackupIntegrity(String backupId) async {
    try {
      final registry = await BackupRegistryManager.getRegistry();
      final backup = registry.getBackup(backupId);

      if (backup == null) {
        return false;
      }

      return await BackupRegistryManager.verifyBackupIntegrity(backup);
    } catch (e, stack) {
      AppLogger.error('验证备份完整性失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      return false;
    }
  }

  /// 清理无效备份引用
  Future<int> cleanupInvalidReferences() async {
    try {
      final removedCount =
          await BackupRegistryManager.cleanupInvalidReferences();

      AppLogger.info('清理无效备份引用完成', tag: 'EnhancedBackupService', data: {
        'removedCount': removedCount,
      });

      return removedCount;
    } catch (e, stack) {
      AppLogger.error('清理无效备份引用失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      return 0;
    }
  }

  /// 获取备份统计信息
  Future<BackupStatistics> getBackupStatistics() async {
    try {
      final registry = await BackupRegistryManager.getRegistry();
      return registry.statistics;
    } catch (e, stack) {
      AppLogger.error('获取备份统计信息失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');

      // 返回空统计信息
      return BackupStatistics(
        totalBackups: 0,
        currentLocationBackups: 0,
        legacyLocationBackups: 0,
        totalSize: 0,
      );
    }
  }

  /// 导出备份到指定位置
  Future<void> exportBackup(String backupId, String targetPath) async {
    try {
      final registry = await BackupRegistryManager.getRegistry();
      final backup = registry.getBackup(backupId);

      if (backup == null) {
        throw Exception('Backup not found: $backupId');
      }

      final sourceFile = File(backup.fullPath);
      final targetFile = File(targetPath);

      // 复制文件
      await sourceFile.copy(targetFile.path);

      AppLogger.info('导出备份成功', tag: 'EnhancedBackupService', data: {
        'backupId': backupId,
        'sourcePath': backup.fullPath,
        'targetPath': targetPath,
      });
    } catch (e, stack) {
      AppLogger.error('导出备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 导入备份从指定位置
  Future<void> importBackup(String sourcePath, {String? description}) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw Exception('Source file not found: $sourcePath');
      }

      final backupPath = await BackupRegistryManager.getCurrentBackupPath();
      if (backupPath == null) {
        throw Exception('Please set backup path first');
      }

      // 生成新的文件名
      final filename = path.basename(sourcePath);
      final targetPath = path.join(backupPath, filename);

      // 复制文件
      await sourceFile.copy(targetPath);

      // 计算校验和
      final checksum =
          await BackupRegistryManager.calculateChecksum(File(targetPath));

      // 创建备份条目
      final backupEntry = BackupEntry(
        id: _generateId(),
        filename: filename,
        fullPath: targetPath,
        size: await File(targetPath).length(),
        createdTime: DateTime.now(),
        location: 'current',
        description: description ?? 'Imported backup',
        checksum: checksum,
        appVersion: await _getAppVersion(),
      );

      // 添加到注册表
      await BackupRegistryManager.addBackup(backupEntry);

      AppLogger.info('导入备份成功', tag: 'EnhancedBackupService', data: {
        'backupId': backupEntry.id,
        'sourcePath': sourcePath,
        'targetPath': targetPath,
      });
    } catch (e, stack) {
      AppLogger.error('导入备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 扫描指定路径的备份文件
  Future<List<BackupEntry>> scanBackupsInPath(String backupPath) async {
    try {
      final backups = <BackupEntry>[];
      final directory = Directory(backupPath);

      if (!await directory.exists()) {
        AppLogger.warning('备份路径不存在',
            tag: 'EnhancedBackupService', data: {'path': backupPath});
        return backups;
      }

      // 1. 尝试读取该路径下的注册表
      try {
        final registryFile =
            File(path.join(backupPath, 'backup_registry.json'));
        if (await registryFile.exists()) {
          final registryJson = await registryFile.readAsString();
          final registry = BackupRegistry.fromJson(
              Map<String, dynamic>.from(json.decode(registryJson)));

          // 验证注册表中的备份文件是否仍然存在
          for (final backup in registry.backups) {
            final file = File(backup.fullPath);
            if (await file.exists()) {
              // 标记为历史路径的备份（如果不是当前路径）
              final currentPath =
                  await BackupRegistryManager.getCurrentBackupPath();
              final isLegacy = currentPath != backupPath;

              final updatedBackup = BackupEntry(
                id: backup.id,
                filename: backup.filename,
                fullPath: backup.fullPath,
                size: backup.size,
                createdTime: backup.createdTime,
                checksum: backup.checksum,
                appVersion: backup.appVersion,
                description: backup.description,
                location: isLegacy ? 'legacy' : 'current',
              );

              backups.add(updatedBackup);
            }
          }

          AppLogger.info('从注册表加载备份完成',
              tag: 'EnhancedBackupService',
              data: {'path': backupPath, 'count': backups.length});
        }
      } catch (e) {
        AppLogger.warning('读取路径注册表失败，尝试扫描文件系统',
            error: e, tag: 'EnhancedBackupService');
      }

      // 2. 扫描文件系统中的备份文件（补充注册表中可能缺失的文件）
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.zip')) {
          final filename = path.basename(entity.path);
          final fullPath = entity.path;

          // 检查是否已经在注册表中（基于文件名和完整路径）
          final alreadyExists = backups
              .any((b) => b.filename == filename && b.fullPath == fullPath);
          if (!alreadyExists) {
            final backupEntry =
                await _createBackupEntryFromFile(entity, backupPath);
            if (backupEntry != null) {
              backups.add(backupEntry);
            }
          }
        }
      }

      AppLogger.info('扫描备份路径完成',
          tag: 'EnhancedBackupService',
          data: {'path': backupPath, 'totalCount': backups.length});

      return backups;
    } catch (e, stack) {
      AppLogger.error('扫描备份路径失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      return [];
    }
  }

  /// 从文件创建备份条目
  Future<BackupEntry?> _createBackupEntryFromFile(
      File file, String backupPath) async {
    try {
      final stat = await file.stat();
      final currentPath = await BackupRegistryManager.getCurrentBackupPath();
      final isLegacy = currentPath != backupPath;

      // 为扫描的文件生成稳定的ID（基于文件路径和修改时间）
      final stableId = _generateStableId(file.path, stat.modified);

      return BackupEntry(
        id: stableId,
        filename: path.basename(file.path),
        fullPath: file.path,
        size: stat.size,
        createdTime: stat.modified,
        location: isLegacy ? 'legacy' : 'current',
        description:
            isLegacy ? 'Historical path backup' : 'Current path backup',
        checksum: await BackupRegistryManager.calculateChecksum(file),
      );
    } catch (e) {
      AppLogger.warning('创建备份条目失败',
          error: e,
          tag: 'EnhancedBackupService',
          data: {'filePath': file.path});
      return null;
    }
  }

  /// 获取所有路径下的备份（合并当前和历史路径）
  Future<List<BackupEntry>> getAllBackupsFromAllPaths() async {
    try {
      // 直接使用BackupRegistryManager获取所有备份
      final allBackups = await BackupRegistryManager.getAllBackups();

      if (allBackups.isNotEmpty) {
        // 按创建时间排序
        allBackups.sort((a, b) => b.createdTime.compareTo(a.createdTime));

        AppLogger.info('获取所有路径备份完成',
            tag: 'EnhancedBackupService',
            data: {'totalBackups': allBackups.length});

        return allBackups;
      }

      // 如果注册表为空，则尝试扫描所有路径
      final paths = await getAllBackupPaths();
      final scannedBackups = <BackupEntry>[];

      for (final path in paths) {
        final backups = await scanBackupsInPath(path);
        scannedBackups.addAll(backups);
      }

      // 去重（基于文件名和大小）
      final uniqueBackups = <BackupEntry>[];
      for (final backup in scannedBackups) {
        final isDuplicate = uniqueBackups.any((existing) =>
            existing.filename == backup.filename &&
            existing.size == backup.size);

        if (!isDuplicate) {
          uniqueBackups.add(backup);
        }
      }

      // 按创建时间排序
      uniqueBackups.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      AppLogger.info('扫描所有路径备份完成', tag: 'EnhancedBackupService', data: {
        'totalPaths': paths.length,
        'totalBackups': uniqueBackups.length
      });

      return uniqueBackups;
    } catch (e, stack) {
      AppLogger.error('获取所有路径备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      return [];
    }
  }

  /// 批量删除备份
  Future<List<String>> batchDeleteBackups(List<String> backupIds) async {
    final failedIds = <String>[];

    for (final backupId in backupIds) {
      try {
        await deleteBackup(backupId);
      } catch (e) {
        AppLogger.warning('批量删除备份失败',
            error: e,
            tag: 'EnhancedBackupService',
            data: {'backupId': backupId});
        failedIds.add(backupId);
      }
    }

    AppLogger.info('批量删除备份完成', tag: 'EnhancedBackupService', data: {
      'totalCount': backupIds.length,
      'failedCount': failedIds.length,
    });

    return failedIds;
  }

  /// 生成唯一ID
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomValue = Random().nextInt(10000);
    return 'backup_${timestamp}_$randomValue';
  }

  /// 移动备份文件到目标位置
  Future<String> _moveBackupToTargetLocation(
      File backupFile, String targetPath) async {
    try {
      final filename = path.basename(backupFile.path);
      final targetFilePath = path.join(targetPath, filename);

      // 如果文件已在目标位置，直接返回
      if (backupFile.path == targetFilePath) {
        return targetFilePath;
      }

      // 确保目标目录存在
      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // 移动文件
      await backupFile.copy(targetFilePath);
      await backupFile.delete();

      AppLogger.info('备份文件移动成功', tag: 'EnhancedBackupService', data: {
        'from': backupFile.path,
        'to': targetFilePath,
      });

      return targetFilePath;
    } catch (e, stack) {
      AppLogger.error('移动备份文件失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 获取应用版本
  Future<String> _getAppVersion() async {
    try {
      // 这里可以从 package_info_plus 获取版本信息
      // 暂时返回默认值
      return '1.0.0';
    } catch (e) {
      AppLogger.warning('获取应用版本失败', error: e, tag: 'EnhancedBackupService');
      return 'unknown';
    }
  }

  /// 切换备份路径并合并数据
  Future<void> switchBackupPathWithMerge(
    String newPath, {
    bool mergeHistoryBackups = true,
    bool migrateFiles = false,
  }) async {
    try {
      AppLogger.info('开始切换备份路径并合并数据', tag: 'EnhancedBackupService', data: {
        'newPath': newPath,
        'mergeHistoryBackups': mergeHistoryBackups,
        'migrateFiles': migrateFiles,
      });

      // 使用 BackupRegistryManager 的高级切换功能
      await BackupRegistryManager.switchBackupPathWithOptions(
        newPath,
        mergeHistoryBackups: mergeHistoryBackups,
        migrateFiles: migrateFiles,
      );

      AppLogger.info('备份路径切换并合并完成', tag: 'EnhancedBackupService', data: {
        'newPath': newPath,
      });
    } catch (e, stack) {
      AppLogger.error('切换备份路径并合并失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 获取路径切换预览信息
  Future<PathSwitchPreview> getPathSwitchPreview(String newPath) async {
    try {
      final currentPath = await BackupRegistryManager.getCurrentBackupPath();
      final historyPaths = await BackupRegistryManager.getHistoryBackupPaths();

      int totalBackups = 0;
      int currentPathBackups = 0;
      int historyPathBackups = 0;
      int newPathBackups = 0;

      // 统计当前路径备份
      if (currentPath != null) {
        final currentBackups = await scanBackupsInPath(currentPath);
        currentPathBackups = currentBackups.length;
        totalBackups += currentPathBackups;
      }

      // 统计历史路径备份
      for (final path in historyPaths) {
        if (path != newPath && await Directory(path).exists()) {
          final backups = await scanBackupsInPath(path);
          historyPathBackups += backups.length;
          totalBackups += backups.length;
        }
      }

      // 统计新路径现有备份
      if (await Directory(newPath).exists()) {
        final newBackups = await scanBackupsInPath(newPath);
        newPathBackups = newBackups.length;
      }

      return PathSwitchPreview(
        currentPath: currentPath,
        newPath: newPath,
        historyPaths: historyPaths,
        currentPathBackups: currentPathBackups,
        historyPathBackups: historyPathBackups,
        newPathBackups: newPathBackups,
        totalBackupsAfterMerge: totalBackups + newPathBackups,
      );
    } catch (e, stack) {
      AppLogger.error('获取路径切换预览失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 为文件生成稳定的ID（基于文件路径和修改时间）
  String _generateStableId(String filePath, DateTime modifiedTime) {
    final fileName = path.basename(filePath);
    final timeStamp = modifiedTime.millisecondsSinceEpoch;
    final hashSource = '$fileName-$timeStamp';

    // 使用文件名和修改时间的哈希作为稳定ID
    // 这确保同一个文件总是有相同的ID
    final hashCode = hashSource.hashCode.abs();
    return 'backup_stable_$hashCode';
  }

  /// 检查路径是否是外部路径（不在应用目录内）
  Future<bool> _isExternalPath(String filePath) async {
    try {
      // 获取应用目录
      final appDir = Directory.current;
      final appPath = appDir.path;

      // 将路径标准化
      final normalizedFilePath = path.normalize(filePath);
      final normalizedAppPath = path.normalize(appPath);

      // 检查文件路径是否以应用路径开头
      return !normalizedFilePath.startsWith(normalizedAppPath);
    } catch (e) {
      AppLogger.warning('检查外部路径失败，假设为外部路径',
          error: e, tag: 'EnhancedBackupService');
      return true; // 保守处理，假设是外部路径
    }
  }

  /// 从外部备份文件恢复
  Future<void> _restoreFromExternalBackup(
    BackupEntry backup, {
    void Function(bool needsRestart, String message)? onRestoreComplete,
    bool autoRestart = false,
  }) async {
    try {
      AppLogger.info('开始从外部路径恢复备份', tag: 'EnhancedBackupService', data: {
        'externalPath': backup.fullPath,
        'filename': backup.filename,
      });

      // 方案：创建一个临时的BackupService实例，使用外部文件所在的目录作为basePath
      // 这样就可以绕过路径验证
      final externalDir = path.dirname(backup.fullPath);

      // 创建一个专门处理外部路径的备份服务实例
      await _restoreFromExternalPathWithTempService(
        backup.fullPath,
        externalDir,
        onRestoreComplete: onRestoreComplete,
        autoRestart: autoRestart,
      );
    } catch (e, stack) {
      AppLogger.error('从外部路径恢复备份失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 使用临时服务从外部路径恢复
  Future<void> _restoreFromExternalPathWithTempService(
    String backupFilePath,
    String externalDir, {
    void Function(bool needsRestart, String message)? onRestoreComplete,
    bool autoRestart = false,
  }) async {
    try {
      // 将外部备份文件复制到当前数据路径下的临时目录
      // 这样确保路径在 LocalStorage 的允许范围内
      String? tempBackupPath;

      try {
        // 获取当前数据路径
        final config = await DataPathConfigService.readConfig();
        final currentDataPath = await config.getActualDataPath();

        // 在当前数据路径下创建临时目录
        final tempDir =
            Directory(path.join(currentDataPath, 'temp', 'external_restore'));
        await tempDir.create(recursive: true);

        final tempFileName =
            'external_restore_${DateTime.now().millisecondsSinceEpoch}_${path.basename(backupFilePath)}';
        tempBackupPath = path.join(tempDir.path, tempFileName);

        AppLogger.info('创建当前数据路径内的临时文件', tag: 'EnhancedBackupService', data: {
          'currentDataPath': currentDataPath,
          'tempDir': tempDir.path,
          'tempBackupPath': tempBackupPath,
        });

        // 复制外部备份文件到当前数据路径内的临时位置
        final sourceFile = File(backupFilePath);
        final tempBackupFile = File(tempBackupPath);
        await sourceFile.copy(tempBackupFile.path);

        AppLogger.info('外部备份文件复制到当前数据路径完成，开始恢复',
            tag: 'EnhancedBackupService',
            data: {
              'tempPath': tempBackupPath,
            });

        // 直接解压和恢复备份文件，避免LocalStorage路径验证问题
        await _directRestoreFromBackup(
          tempBackupPath,
          currentDataPath,
          onRestoreComplete: onRestoreComplete,
          autoRestart: autoRestart,
        );

        AppLogger.info('外部备份恢复成功', tag: 'EnhancedBackupService');
      } finally {
        // 清理临时文件
        try {
          if (tempBackupPath != null) {
            final tempBackupFile = File(tempBackupPath);
            if (await tempBackupFile.exists()) {
              await tempBackupFile.delete();
              AppLogger.debug('临时备份文件删除完成', tag: 'EnhancedBackupService');
            }
          }
        } catch (e) {
          AppLogger.warning('清理外部恢复临时文件失败',
              error: e, tag: 'EnhancedBackupService');
        }
      }
    } catch (e, stack) {
      AppLogger.error('使用临时服务从外部路径恢复失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 直接从备份文件恢复，避免LocalStorage路径验证问题
  Future<void> _directRestoreFromBackup(
    String backupPath,
    String targetDataPath, {
    void Function(bool needsRestart, String message)? onRestoreComplete,
    bool autoRestart = false,
  }) async {
    try {
      AppLogger.info('开始直接从备份恢复', tag: 'EnhancedBackupService', data: {
        'backupPath': backupPath,
        'targetDataPath': targetDataPath,
      });

      // 检查备份文件是否存在
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file does not exist: $backupPath');
      }

      // 创建临时解压目录
      final tempExtractDir =
          Directory(path.join(targetDataPath, 'temp', 'extract'));
      await tempExtractDir.create(recursive: true);

      try {
        // 解压备份文件
        AppLogger.info('开始解压备份文件', tag: 'EnhancedBackupService');
        await _extractBackupArchive(backupPath, tempExtractDir.path);

        // 恢复文件到目标位置
        AppLogger.info('开始恢复文件到目标位置', tag: 'EnhancedBackupService');
        await _restoreFilesToTarget(tempExtractDir.path, targetDataPath);

        AppLogger.info('直接备份恢复成功', tag: 'EnhancedBackupService');

        // 调用回调，通知恢复完成需要重启
        if (onRestoreComplete != null) {
          onRestoreComplete(true,
              'Backup restored successfully, restart required to apply changes.');
        }
      } finally {
        // 清理临时解压目录
        try {
          await tempExtractDir.delete(recursive: true);
          AppLogger.debug('临时解压目录清理完成', tag: 'EnhancedBackupService');
        } catch (e) {
          AppLogger.warning('清理临时解压目录失败',
              error: e, tag: 'EnhancedBackupService');
        }
      }
    } catch (e, stack) {
      AppLogger.error('直接备份恢复失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 解压备份归档文件
  Future<void> _extractBackupArchive(
      String archivePath, String extractPath) async {
    try {
      // 读取归档文件
      final archiveFile = File(archivePath);
      final bytes = await archiveFile.readAsBytes();

      // 解码归档
      final archive = ZipDecoder().decodeBytes(bytes);

      // 提取文件
      for (final file in archive) {
        final fileName = file.name;
        final filePath = path.join(extractPath, fileName);

        if (file.isFile) {
          // 创建文件目录
          final fileDir = path.dirname(filePath);
          await Directory(fileDir).create(recursive: true);

          // 写入文件内容
          await File(filePath).writeAsBytes(file.content as List<int>);
        } else {
          // 创建目录
          await Directory(filePath).create(recursive: true);
        }
      }

      AppLogger.info('备份归档解压完成',
          tag: 'EnhancedBackupService', data: {'fileCount': archive.length});
    } catch (e, stack) {
      AppLogger.error('解压备份归档失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }

  /// 恢复文件到目标位置
  Future<void> _restoreFilesToTarget(
      String extractPath, String targetPath) async {
    try {
      final extractDir = Directory(extractPath);

      // 1. 恢复 data 目录下的所有子目录到 targetPath
      final dataDir = Directory(path.join(extractPath, 'data'));
      if (await dataDir.exists()) {
        await for (final entity in dataDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath = path.relative(entity.path, from: dataDir.path);
            final targetFilePath = path.join(targetPath, relativePath);
            final targetDir = path.dirname(targetFilePath);
            await Directory(targetDir).create(recursive: true);
            bool existed = await File(targetFilePath).exists();
            try {
              await entity.copy(targetFilePath);
              AppLogger.info('文件恢复', tag: 'EnhancedBackupService', data: {
                'source': entity.path,
                'target': targetFilePath,
                'existedBefore': existed,
                'result': 'success',
              });
            } catch (e) {
              // 文件占用异常，暂存到 temp_restore 目录
              final tempRestorePath =
                  path.join(targetPath, 'temp_restore', relativePath);
              await Directory(path.dirname(tempRestorePath))
                  .create(recursive: true);
              await entity.copy(tempRestorePath);
              AppLogger.warning('文件占用，暂存到临时恢复目录',
                  tag: 'EnhancedBackupService',
                  data: {
                    'source': entity.path,
                    'target': tempRestorePath,
                    'existedBefore': existed,
                    'result': 'pending',
                    'error': e.toString(),
                  });
            }
          }
        }
      }

      // 2. 恢复 database 整个目录到 targetPath/database 下
      final databaseDir = Directory(path.join(extractPath, 'database'));
      if (await databaseDir.exists()) {
        final targetDatabaseDir = Directory(path.join(targetPath, 'database'));
        await targetDatabaseDir.create(recursive: true);
        await for (final entity in databaseDir.list(recursive: true)) {
          if (entity is File) {
            final relativePath =
                path.relative(entity.path, from: databaseDir.path);
            final targetFilePath =
                path.join(targetDatabaseDir.path, relativePath);
            final targetDir = path.dirname(targetFilePath);
            await Directory(targetDir).create(recursive: true);
            bool existed = await File(targetFilePath).exists();
            try {
              await entity.copy(targetFilePath);
              AppLogger.info('文件恢复', tag: 'EnhancedBackupService', data: {
                'source': entity.path,
                'target': targetFilePath,
                'existedBefore': existed,
                'result': 'success',
              });
            } catch (e) {
              AppLogger.error('文件恢复失败', tag: 'EnhancedBackupService', data: {
                'source': entity.path,
                'target': targetFilePath,
                'existedBefore': existed,
                'result': 'fail',
                'error': e.toString(),
              });
            }
          }
        }
      }

      AppLogger.info('文件恢复到目标位置完成', tag: 'EnhancedBackupService');
    } catch (e, stack) {
      AppLogger.error('恢复文件到目标位置失败',
          error: e, stackTrace: stack, tag: 'EnhancedBackupService');
      rethrow;
    }
  }
}
