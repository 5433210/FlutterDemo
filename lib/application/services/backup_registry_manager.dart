import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/backup_models.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/storage/storage_interface.dart';

/// 备份注册管理器
class BackupRegistryManager {
  static const String _registryFileName = 'backup_registry.json';
  static const String _backupPathKey = 'current_backup_path';

  static final Random _random = Random();

  /// 获取备份注册表
  static Future<BackupRegistry> getRegistry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPath = prefs.getString(_backupPathKey);

      if (currentPath == null) {
        throw Exception('未设置备份路径');
      }

      final registryFile = File(path.join(currentPath, _registryFileName));

      if (!await registryFile.exists()) {
        AppLogger.info('备份注册表不存在，创建新的注册表', tag: 'BackupRegistryManager');
        return await _createNewRegistry(currentPath);
      }

      final registryJson = await registryFile.readAsString();
      final registry = BackupRegistry.fromJson(
          jsonDecode(registryJson) as Map<String, dynamic>);

      AppLogger.info('成功加载备份注册表', tag: 'BackupRegistryManager', data: {
        'backupCount': registry.backups.length,
        'path': currentPath,
      });

      return registry;
    } catch (e, stack) {
      AppLogger.error('获取备份注册表失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 设置新的备份路径（支持数据合并）
  static Future<void> setBackupLocation(String newPath,
      {IStorage? storage, bool mergeHistoryBackups = true}) async {
    try {
      AppLogger.info('设置新的备份路径', tag: 'BackupRegistryManager', data: {
        'newPath': newPath,
        'mergeHistoryBackups': mergeHistoryBackups,
      });

      final prefs = await SharedPreferences.getInstance();
      final currentPath = await getCurrentBackupPath();

      // 1. 确保目录存在
      final directory = Directory(newPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 2. 收集所有备份数据
      final allBackups = <BackupEntry>[];

      // 2.1 扫描新路径中已有的备份
      final newPathBackups = await _scanBackupsInPath(newPath);
      allBackups.addAll(newPathBackups);

      // 2.2 如果需要合并历史备份数据
      if (mergeHistoryBackups) {
        // 从当前路径合并备份
        if (currentPath != null && currentPath != newPath) {
          final currentPathBackups = await _mergeBackupsFromPath(currentPath);
          allBackups.addAll(currentPathBackups);

          // 将当前路径添加到历史记录
          await addHistoryBackupPath(currentPath);
        }

        // 从历史路径合并备份
        final historyPaths = await getHistoryBackupPaths();
        for (final historyPath in historyPaths) {
          if (historyPath != newPath && await Directory(historyPath).exists()) {
            final historyBackups = await _mergeBackupsFromPath(historyPath);
            allBackups.addAll(historyBackups);
          }
        }
      } else {
        // 如果不合并，仍然扫描原有备份（向后兼容）
        final existingBackups = await _scanExistingBackups(storage);
        allBackups.addAll(existingBackups);
      }

      // 3. 去重处理（基于文件名和大小）
      final uniqueBackups = _deduplicateBackups(allBackups);

      // 4. 创建新的注册表
      final registry = BackupRegistry(
        location: BackupLocation(
          path: newPath,
          createdTime: DateTime.now(),
          description: mergeHistoryBackups ? '主要备份位置（已合并历史数据）' : '主要备份位置',
        ),
        backups: uniqueBackups,
      );

      // 5. 保存注册表到新位置
      await _saveRegistry(newPath, registry);

      // 6. 更新当前路径
      await prefs.setString(_backupPathKey, newPath);

      AppLogger.info('成功设置新的备份路径', tag: 'BackupRegistryManager', data: {
        'newPath': newPath,
        'totalBackupsCount': uniqueBackups.length,
        'mergedHistoryData': mergeHistoryBackups,
      });
    } catch (e, stack) {
      AppLogger.error('设置备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 获取当前备份路径
  static Future<String?> getCurrentBackupPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_backupPathKey);
    } catch (e, stack) {
      AppLogger.error('获取当前备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return null;
    }
  }

  /// 扫描现有备份
  static Future<List<BackupEntry>> _scanExistingBackups(
      IStorage? storage) async {
    final backups = <BackupEntry>[];

    try {
      if (storage == null) {
        AppLogger.warning('未提供存储接口，无法扫描现有备份', tag: 'BackupRegistryManager');
        return backups;
      }

      // 扫描默认路径
      final defaultPath = path.join(storage.getAppDataPath(), 'backups');
      final defaultDir = Directory(defaultPath);

      if (await defaultDir.exists()) {
        AppLogger.info('扫描默认备份路径', tag: 'BackupRegistryManager', data: {
          'defaultPath': defaultPath,
        });

        final files = await defaultDir
            .list()
            .where((entity) => entity.path.endsWith('.zip'))
            .toList();

        for (final file in files) {
          if (file is File) {
            try {
              final stat = await file.stat();
              final backupEntry = BackupEntry(
                id: _generateId(),
                filename: path.basename(file.path),
                fullPath: file.path,
                size: stat.size,
                createdTime: stat.modified,
                location: 'legacy',
                description: '历史备份',
              );
              backups.add(backupEntry);
            } catch (e) {
              AppLogger.warning('扫描备份文件失败',
                  tag: 'BackupRegistryManager',
                  data: {
                    'filePath': file.path,
                    'error': e.toString(),
                  });
            }
          }
        }
      }

      AppLogger.info('扫描现有备份完成', tag: 'BackupRegistryManager', data: {
        'backupCount': backups.length,
      });
    } catch (e, stack) {
      AppLogger.error('扫描现有备份失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
    }

    return backups;
  }

  /// 创建新的注册表
  static Future<BackupRegistry> _createNewRegistry(String backupPath) async {
    final registry = BackupRegistry(
      location: BackupLocation(
        path: backupPath,
        createdTime: DateTime.now(),
        description: '主要备份位置',
      ),
      backups: [],
    );

    await _saveRegistry(backupPath, registry);
    return registry;
  }

  /// 保存注册表
  static Future<void> _saveRegistry(
      String backupPath, BackupRegistry registry) async {
    try {
      final registryFile = File(path.join(backupPath, _registryFileName));

      // 确保目录存在
      final directory = Directory(backupPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 更新统计信息
      final updatedRegistry = registry.updateStatistics();

      // 保存到文件
      await registryFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(updatedRegistry.toJson()),
      );

      AppLogger.info('保存备份注册表成功', tag: 'BackupRegistryManager', data: {
        'backupPath': backupPath,
        'backupCount': updatedRegistry.backups.length,
      });
    } catch (e, stack) {
      AppLogger.error('保存备份注册表失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 添加新备份到注册表
  static Future<void> addBackup(BackupEntry backup) async {
    try {
      final registry = await getRegistry();

      // 检查是否已存在相同的备份记录
      final existingBackup = registry.backups
          .where((existing) =>
              existing.id == backup.id ||
              (existing.filename == backup.filename &&
                  existing.fullPath == backup.fullPath))
          .firstOrNull;

      if (existingBackup != null) {
        AppLogger.warning('备份记录已存在，跳过添加', tag: 'BackupRegistryManager', data: {
          'existingId': existingBackup.id,
          'newId': backup.id,
          'filename': backup.filename,
        });
        return;
      }

      registry.addBackup(backup);
      await _saveRegistry(registry.location.path, registry);

      AppLogger.info('添加备份到注册表成功', tag: 'BackupRegistryManager', data: {
        'backupId': backup.id,
        'filename': backup.filename,
      });
    } catch (e, stack) {
      AppLogger.error('添加备份到注册表失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 删除备份
  static Future<void> deleteBackup(String backupId) async {
    try {
      final registry = await getRegistry();
      final backup = registry.getBackup(backupId);

      if (backup != null) {
        // 1. 删除物理文件
        final file = File(backup.fullPath);
        if (await file.exists()) {
          await file.delete();
          AppLogger.info('删除备份文件成功', tag: 'BackupRegistryManager', data: {
            'backupId': backupId,
            'filePath': backup.fullPath,
          });
        }

        // 2. 从注册表中移除
        registry.removeBackup(backupId);

        // 3. 更新配置文件
        await _saveRegistry(registry.location.path, registry);

        AppLogger.info('从注册表中删除备份成功', tag: 'BackupRegistryManager', data: {
          'backupId': backupId,
        });
      } else {
        AppLogger.warning('要删除的备份不存在', tag: 'BackupRegistryManager', data: {
          'backupId': backupId,
        });
      }
    } catch (e, stack) {
      AppLogger.error('删除备份失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 获取所有备份
  static Future<List<BackupEntry>> getAllBackups() async {
    try {
      final registry = await getRegistry();
      return registry.backups;
    } catch (e, stack) {
      AppLogger.error('获取所有备份失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 生成唯一ID
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomValue = _random.nextInt(10000);
    return 'backup_${timestamp}_$randomValue';
  }

  /// 为文件生成稳定的ID（基于文件路径和修改时间）
  static String _generateStableId(String filePath, DateTime modifiedTime) {
    final fileName = path.basename(filePath);
    final timeStamp = modifiedTime.millisecondsSinceEpoch;
    final hashSource = '$fileName-$timeStamp';

    // 使用文件名和修改时间的哈希作为稳定ID
    // 这确保同一个文件总是有相同的ID
    final hashCode = hashSource.hashCode.abs();
    return 'backup_stable_$hashCode';
  }

  /// 计算文件校验和
  static Future<String> calculateChecksum(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return 'sha256:${digest.toString()}';
    } catch (e, stack) {
      AppLogger.error('计算文件校验和失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 验证备份文件完整性
  static Future<bool> verifyBackupIntegrity(BackupEntry backup) async {
    try {
      final file = File(backup.fullPath);
      if (!await file.exists()) {
        return false;
      }

      // 检查文件大小
      final actualSize = await file.length();
      if (actualSize != backup.size) {
        AppLogger.warning('备份文件大小不匹配', tag: 'BackupRegistryManager', data: {
          'backupId': backup.id,
          'expectedSize': backup.size,
          'actualSize': actualSize,
        });
        return false;
      }

      // 如果有校验和，验证校验和
      if (backup.checksum != null) {
        final actualChecksum = await calculateChecksum(file);
        if (actualChecksum != backup.checksum) {
          AppLogger.warning('备份文件校验和不匹配', tag: 'BackupRegistryManager', data: {
            'backupId': backup.id,
            'expectedChecksum': backup.checksum,
            'actualChecksum': actualChecksum,
          });
          return false;
        }
      }

      return true;
    } catch (e, stack) {
      AppLogger.error('验证备份文件完整性失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return false;
    }
  }

  /// 清理无效备份引用
  static Future<int> cleanupInvalidReferences() async {
    try {
      final registry = await getRegistry();
      final validBackups = <BackupEntry>[];
      int removedCount = 0;

      for (final backup in registry.backups) {
        final file = File(backup.fullPath);
        if (await file.exists()) {
          validBackups.add(backup);
        } else {
          removedCount++;
          AppLogger.info('清理无效备份引用', tag: 'BackupRegistryManager', data: {
            'backupId': backup.id,
            'filePath': backup.fullPath,
          });
        }
      }

      if (removedCount > 0) {
        // 更新注册表
        final updatedRegistry = BackupRegistry(
          location: registry.location,
          backups: validBackups,
          settings: registry.settings,
        );

        await _saveRegistry(registry.location.path, updatedRegistry);

        AppLogger.info('清理无效备份引用完成', tag: 'BackupRegistryManager', data: {
          'removedCount': removedCount,
          'remainingCount': validBackups.length,
        });
      }

      return removedCount;
    } catch (e, stack) {
      AppLogger.error('清理无效备份引用失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return 0;
    }
  }

  /// 添加历史备份路径
  static Future<void> addHistoryBackupPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPaths = prefs.getStringList('backup_history_paths') ?? [];

      if (!currentPaths.contains(path)) {
        currentPaths.add(path);
        await prefs.setStringList('backup_history_paths', currentPaths);

        AppLogger.info('添加历史备份路径', tag: 'BackupRegistryManager', data: {
          'path': path,
          'totalHistoryPaths': currentPaths.length,
        });
      }
    } catch (e, stack) {
      AppLogger.error('添加历史备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
    }
  }

  /// 获取历史备份路径
  static Future<List<String>> getHistoryBackupPaths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('backup_history_paths') ?? [];
    } catch (e, stack) {
      AppLogger.error('获取历史备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return [];
    }
  }

  /// 移除历史备份路径
  static Future<void> removeHistoryBackupPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentPaths = prefs.getStringList('backup_history_paths') ?? [];

      if (currentPaths.remove(path)) {
        await prefs.setStringList('backup_history_paths', currentPaths);

        AppLogger.info('移除历史备份路径', tag: 'BackupRegistryManager', data: {
          'path': path,
          'remainingHistoryPaths': currentPaths.length,
        });
      }
    } catch (e, stack) {
      AppLogger.error('移除历史备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
    }
  }

  /// 清理无效的历史备份路径
  static Future<int> cleanupInvalidHistoryPaths() async {
    try {
      final historyPaths = await getHistoryBackupPaths();
      final validPaths = <String>[];
      int removedCount = 0;

      for (final path in historyPaths) {
        if (await Directory(path).exists()) {
          validPaths.add(path);
        } else {
          removedCount++;
          AppLogger.info('清理无效历史路径', tag: 'BackupRegistryManager', data: {
            'path': path,
          });
        }
      }

      if (removedCount > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('backup_history_paths', validPaths);

        AppLogger.info('清理无效历史路径完成', tag: 'BackupRegistryManager', data: {
          'removedCount': removedCount,
          'remainingCount': validPaths.length,
        });
      }

      return removedCount;
    } catch (e, stack) {
      AppLogger.error('清理无效历史路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return 0;
    }
  }

  /// 在切换备份路径时自动管理历史路径
  static Future<void> switchBackupPathWithHistory(String newPath) async {
    try {
      // 1. 获取当前路径并添加到历史记录
      final currentPath = await getCurrentBackupPath();
      if (currentPath != null && currentPath != newPath) {
        await addHistoryBackupPath(currentPath);
      }

      // 2. 设置新的备份路径并合并历史数据
      await setBackupLocation(newPath, mergeHistoryBackups: true);

      AppLogger.info('切换备份路径并合并历史数据', tag: 'BackupRegistryManager', data: {
        'oldPath': currentPath,
        'newPath': newPath,
      });
    } catch (e, stack) {
      AppLogger.error('切换备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 扫描指定路径下的备份文件
  static Future<List<BackupEntry>> _scanBackupsInPath(String backupPath) async {
    try {
      final backups = <BackupEntry>[];
      final directory = Directory(backupPath);

      if (!await directory.exists()) {
        return backups;
      }

      // 1. 尝试读取该路径下的注册表
      final registryFile = File(path.join(backupPath, _registryFileName));
      if (await registryFile.exists()) {
        try {
          final registryJson = await registryFile.readAsString();
          final registry = BackupRegistry.fromJson(
              jsonDecode(registryJson) as Map<String, dynamic>);

          // 验证注册表中的备份文件是否仍然存在
          for (final backup in registry.backups) {
            final file = File(backup.fullPath);
            if (await file.exists()) {
              backups.add(backup);
            }
          }
        } catch (e) {
          AppLogger.warning('读取路径注册表失败，尝试扫描文件系统',
              error: e, tag: 'BackupRegistryManager');
        }
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
            final backupEntry = await _createBackupEntryFromFile(entity);
            if (backupEntry != null) {
              backups.add(backupEntry);
            }
          }
        }
      }

      return backups;
    } catch (e, stack) {
      AppLogger.error('扫描备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return [];
    }
  }

  /// 从指定路径合并备份数据
  static Future<List<BackupEntry>> _mergeBackupsFromPath(
      String backupPath) async {
    try {
      final backups = await _scanBackupsInPath(backupPath);

      // 为备份条目标记来源路径
      final currentPath = await getCurrentBackupPath();
      final isLegacy = currentPath != backupPath;

      return backups
          .map((backup) => BackupEntry(
                id: backup.id,
                filename: backup.filename,
                fullPath: backup.fullPath,
                size: backup.size,
                createdTime: backup.createdTime,
                checksum: backup.checksum,
                appVersion: backup.appVersion,
                description: backup.description,
                location: isLegacy ? 'legacy' : 'current',
              ))
          .toList();
    } catch (e, stack) {
      AppLogger.error('合并备份数据失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return [];
    }
  }

  /// 从文件创建备份条目
  static Future<BackupEntry?> _createBackupEntryFromFile(File file) async {
    try {
      final stat = await file.stat();

      // 为扫描的文件生成稳定的ID（基于文件路径和修改时间）
      final stableId = _generateStableId(file.path, stat.modified);

      return BackupEntry(
        id: stableId,
        filename: path.basename(file.path),
        fullPath: file.path,
        size: stat.size,
        createdTime: stat.modified,
        location: 'legacy',
        description: 'Scanned backup file',
        checksum: await calculateChecksum(file),
      );
    } catch (e) {
      AppLogger.warning('创建备份条目失败',
          error: e,
          tag: 'BackupRegistryManager',
          data: {'filePath': file.path});
      return null;
    }
  }

  /// 去重备份列表
  static List<BackupEntry> _deduplicateBackups(List<BackupEntry> backups) {
    final uniqueBackups = <BackupEntry>[];
    final seen = <String>{};

    for (final backup in backups) {
      // 基于文件名和大小创建唯一键
      final key = '${backup.filename}_${backup.size}';

      if (!seen.contains(key)) {
        seen.add(key);
        uniqueBackups.add(backup);
      } else {
        AppLogger.info('跳过重复备份', tag: 'BackupRegistryManager', data: {
          'filename': backup.filename,
          'size': backup.size,
          'path': backup.fullPath,
        });
      }
    }

    // 按创建时间排序
    uniqueBackups.sort((a, b) => b.createdTime.compareTo(a.createdTime));

    return uniqueBackups;
  }

  /// 高级备份路径切换（提供用户选择）
  static Future<void> switchBackupPathWithOptions(
    String newPath, {
    required bool mergeHistoryBackups,
    required bool migrateFiles,
  }) async {
    try {
      final currentPath = await getCurrentBackupPath();

      if (currentPath != null && currentPath != newPath) {
        await addHistoryBackupPath(currentPath);
      }

      // 设置新路径
      await setBackupLocation(newPath,
          mergeHistoryBackups: mergeHistoryBackups);

      // 如果需要迁移文件
      if (migrateFiles && currentPath != null && currentPath != newPath) {
        await _migrateBackupFiles(currentPath, newPath);
      }

      AppLogger.info('高级路径切换完成', tag: 'BackupRegistryManager', data: {
        'oldPath': currentPath,
        'newPath': newPath,
        'mergeHistoryBackups': mergeHistoryBackups,
        'migrateFiles': migrateFiles,
      });
    } catch (e, stack) {
      AppLogger.error('高级路径切换失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 迁移备份文件到新路径
  static Future<void> _migrateBackupFiles(
      String sourcePath, String targetPath) async {
    try {
      final sourceDir = Directory(sourcePath);

      if (!await sourceDir.exists()) {
        return;
      }

      // 确保目标目录存在
      final targetDir = Directory(targetPath);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      await for (final entity in sourceDir.list()) {
        if (entity is File && entity.path.endsWith('.zip')) {
          final filename = path.basename(entity.path);
          final targetFile = File(path.join(targetPath, filename));

          if (!await targetFile.exists()) {
            await entity.copy(targetFile.path);
            AppLogger.info('迁移备份文件', tag: 'BackupRegistryManager', data: {
              'from': entity.path,
              'to': targetFile.path,
            });
          }
        }
      }
    } catch (e, stack) {
      AppLogger.error('迁移备份文件失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 删除整个备份路径及其下的所有文件
  static Future<void> deleteBackupPath(String backupPath,
      {bool removeFromHistory = true}) async {
    try {
      AppLogger.info('开始删除备份路径', tag: 'BackupRegistryManager', data: {
        'path': backupPath,
        'removeFromHistory': removeFromHistory,
      });

      final directory = Directory(backupPath);

      if (await directory.exists()) {
        // 删除目录及其所有内容
        await directory.delete(recursive: true);

        AppLogger.info('备份路径物理删除完成', tag: 'BackupRegistryManager', data: {
          'path': backupPath,
        });
      }

      // 从历史记录中移除
      if (removeFromHistory) {
        await removeHistoryBackupPath(backupPath);
      }

      // 检查是否是当前路径
      final currentPath = await getCurrentBackupPath();
      if (currentPath == backupPath) {
        // 如果删除的是当前路径，清除当前路径设置
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_backupPathKey);

        AppLogger.warning('当前备份路径被删除，已清除路径设置',
            tag: 'BackupRegistryManager', data: {'path': backupPath});
      }

      AppLogger.info('备份路径删除完成', tag: 'BackupRegistryManager', data: {
        'path': backupPath,
      });
    } catch (e, stack) {
      AppLogger.error('删除备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      rethrow;
    }
  }

  /// 批量删除多个备份路径
  static Future<List<String>> batchDeleteBackupPaths(List<String> paths) async {
    final failedPaths = <String>[];

    for (final path in paths) {
      try {
        await deleteBackupPath(path);
      } catch (e) {
        AppLogger.warning('批量删除备份路径失败',
            error: e, tag: 'BackupRegistryManager', data: {'path': path});
        failedPaths.add(path);
      }
    }

    AppLogger.info('批量删除备份路径完成', tag: 'BackupRegistryManager', data: {
      'totalCount': paths.length,
      'failedCount': failedPaths.length,
    });

    return failedPaths;
  }

  /// 安全删除备份路径（只在路径为空时删除）
  static Future<bool> safeDeleteBackupPath(String backupPath) async {
    try {
      final directory = Directory(backupPath);

      if (!await directory.exists()) {
        // 路径不存在，从历史记录中移除
        await removeHistoryBackupPath(backupPath);
        return true;
      }

      // 检查路径是否为空（只包含注册表文件）
      final files = await directory.list().toList();
      final hasOnlyRegistry =
          files.length == 1 && files.first.path.endsWith(_registryFileName);

      if (files.isEmpty || hasOnlyRegistry) {
        await deleteBackupPath(backupPath);
        return true;
      }

      return false; // 路径不为空，不安全删除
    } catch (e, stack) {
      AppLogger.error('安全删除备份路径失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return false;
    }
  }

  /// 检查文件是否与现有备份重复
  /// 返回重复的备份条目，如果没有重复则返回null
  static Future<BackupEntry?> checkForDuplicateBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final registry = await getRegistry();
      final filename = path.basename(filePath);
      final fileSize = await file.length();
      final fileChecksum = await calculateChecksum(file);

      // 检查是否有同名同大小的文件
      for (final backup in registry.backups) {
        if (backup.filename == filename && backup.size == fileSize) {
          // 进一步检查校验和
          if (backup.checksum != null && backup.checksum == fileChecksum) {
            AppLogger.info('发现重复备份 (校验和匹配)',
                tag: 'BackupRegistryManager',
                data: {
                  'filename': filename,
                  'size': fileSize,
                  'checksum': fileChecksum,
                  'existingBackupId': backup.id,
                });
            return backup;
          }
        }
      }

      // 如果没有找到精确匹配，检查是否有相同校验和但不同文件名的文件
      for (final backup in registry.backups) {
        if (backup.checksum != null && backup.checksum == fileChecksum) {
          AppLogger.info('发现重复备份 (内容相同但文件名不同)',
              tag: 'BackupRegistryManager',
              data: {
                'newFilename': filename,
                'existingFilename': backup.filename,
                'checksum': fileChecksum,
                'existingBackupId': backup.id,
              });
          return backup;
        }
      }

      return null;
    } catch (e, stack) {
      AppLogger.error('检查重复备份失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return null;
    }
  }

  /// 检查目标路径是否已存在文件
  static Future<bool> checkFileExistsAtPath(String targetPath) async {
    try {
      final file = File(targetPath);
      return await file.exists();
    } catch (e) {
      AppLogger.warning('检查文件是否存在失败',
          error: e, tag: 'BackupRegistryManager', data: {'path': targetPath});
      return false;
    }
  }

  /// 生成不重复的文件名
  static Future<String> generateUniqueFilename(
      String targetDirectory, String originalFilename) async {
    final extension = path.extension(originalFilename);
    final nameWithoutExtension =
        path.basenameWithoutExtension(originalFilename);

    String newFilename = originalFilename;
    int counter = 1;

    while (
        await checkFileExistsAtPath(path.join(targetDirectory, newFilename))) {
      newFilename = '${nameWithoutExtension}_$counter$extension';
      counter++;
    }

    return newFilename;
  }

  /// 清理重复的备份记录
  static Future<int> removeDuplicateBackups() async {
    try {
      final registry = await getRegistry();
      final originalCount = registry.backups.length;

      // 创建去重后的备份列表
      final uniqueBackups = <BackupEntry>[];
      final seenFiles = <String>{};
      final seenIds = <String>{};

      for (final backup in registry.backups) {
        final key = '${backup.filename}:${backup.fullPath}';

        // 检查文件是否实际存在
        final file = File(backup.fullPath);
        final fileExists = await file.exists();

        if (!fileExists) {
          AppLogger.info('移除不存在的备份记录', tag: 'BackupRegistryManager', data: {
            'backupId': backup.id,
            'filename': backup.filename,
            'path': backup.fullPath,
          });
          continue;
        }

        // 检查是否重复（基于文件路径和ID）
        if (seenFiles.contains(key) || seenIds.contains(backup.id)) {
          AppLogger.info('移除重复的备份记录', tag: 'BackupRegistryManager', data: {
            'backupId': backup.id,
            'filename': backup.filename,
            'reason':
                seenFiles.contains(key) ? 'duplicate_file' : 'duplicate_id',
          });
          continue;
        }

        seenFiles.add(key);
        seenIds.add(backup.id);
        uniqueBackups.add(backup);
      }

      // 如果发现重复记录，更新注册表
      final removedCount = originalCount - uniqueBackups.length;
      if (removedCount > 0) {
        final updatedRegistry = BackupRegistry(
          location: registry.location,
          backups: uniqueBackups,
          settings: registry.settings,
          statistics: registry.statistics,
        );

        await _saveRegistry(
            registry.location.path, updatedRegistry.updateStatistics());

        AppLogger.info('清理重复备份记录完成', tag: 'BackupRegistryManager', data: {
          'originalCount': originalCount,
          'uniqueCount': uniqueBackups.length,
          'removedCount': removedCount,
        });
      }

      return removedCount;
    } catch (e, stack) {
      AppLogger.error('清理重复备份记录失败',
          error: e, stackTrace: stack, tag: 'BackupRegistryManager');
      return 0;
    }
  }
}
