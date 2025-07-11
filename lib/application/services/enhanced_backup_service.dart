import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';
import 'backup_registry_manager.dart';
import 'backup_service.dart';

/// 增强的备份服务
/// 基于配置文件的备份管理，支持多位置备份统一管理
class EnhancedBackupService {
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
        throw Exception('请先设置备份路径');
      }

      // 2. 使用原始备份服务创建备份
      final backupFilePath =
          await _backupService.createBackup(description: description);

      // 3. 获取备份文件信息
      final backupFile = File(backupFilePath);
      if (!await backupFile.exists()) {
        throw Exception('备份文件创建失败');
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
        description: description ?? '手动创建的备份',
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
                  description: info.description ?? '历史备份',
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

  /// 恢复备份
  Future<void> restoreBackup(String backupId) async {
    try {
      final registry = await BackupRegistryManager.getRegistry();
      final backup = registry.getBackup(backupId);

      if (backup == null) {
        throw Exception('备份不存在: $backupId');
      }

      // 验证备份文件完整性
      final isValid = await BackupRegistryManager.verifyBackupIntegrity(backup);
      if (!isValid) {
        throw Exception('备份文件已损坏或不完整');
      }

      // 使用原始备份服务恢复
      await _backupService.restoreFromBackup(backup.fullPath);

      AppLogger.info('恢复备份成功', tag: 'EnhancedBackupService', data: {
        'backupId': backupId,
        'filename': backup.filename,
      });
    } catch (e, stack) {
      AppLogger.error('恢复备份失败',
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
        throw Exception('备份不存在: $backupId');
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
        throw Exception('源文件不存在: $sourcePath');
      }

      final backupPath = await BackupRegistryManager.getCurrentBackupPath();
      if (backupPath == null) {
        throw Exception('请先设置备份路径');
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
        description: description ?? '导入的备份',
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

          // 检查是否已经在注册表中
          final alreadyExists = backups.any((b) => b.filename == filename);
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

      return BackupEntry(
        id: _generateId(),
        filename: path.basename(file.path),
        fullPath: file.path,
        size: stat.size,
        createdTime: stat.modified,
        location: isLegacy ? 'legacy' : 'current',
        description: isLegacy ? '历史路径备份' : '当前路径备份',
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
      final allBackups = <BackupEntry>[];
      final paths = await getAllBackupPaths();

      for (final path in paths) {
        final backups = await scanBackupsInPath(path);
        allBackups.addAll(backups);
      }

      // 去重（基于文件名和大小）
      final uniqueBackups = <BackupEntry>[];
      for (final backup in allBackups) {
        final isDuplicate = uniqueBackups.any((existing) =>
            existing.filename == backup.filename &&
            existing.size == backup.size);

        if (!isDuplicate) {
          uniqueBackups.add(backup);
        }
      }

      // 按创建时间排序
      uniqueBackups.sort((a, b) => b.createdTime.compareTo(a.createdTime));

      AppLogger.info('获取所有路径备份完成', tag: 'EnhancedBackupService', data: {
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
}
