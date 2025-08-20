import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/storage/storage_interface.dart';
import '../../version_config.dart';
import 'backup_progress_manager.dart';
import 'data_version_mapping_service.dart';

/// 备份信息
class BackupInfo {
  /// 备份文件路径
  final String path;

  /// 备份创建时间
  final DateTime creationTime;

  /// 备份文件大小（字节）
  final int size;

  /// 备份描述
  final String? description;

  BackupInfo({
    required this.path,
    required this.creationTime,
    required this.size,
    this.description,
  });

  /// 备份文件名
  String get fileName => p.basename(path);

  /// 从文件创建备份信息
  static Future<BackupInfo> fromFile(File file, {IStorage? storage}) async {
    final filePath = file.path;

    // 首先检查文件是否存在
    if (!await file.exists()) {
      throw Exception('备份文件不存在: $filePath');
    }

    String? description;

    // 尝试从备份文件中提取描述信息
    if (storage != null) {
      try {
        // 创建临时目录
        final tempDir = await storage.createTempDirectory();
        final tempPath = tempDir.path;

        // 解压备份文件到临时目录
        final zipBytes = await file.readAsBytes();
        final archive = ZipDecoder().decodeBytes(zipBytes);

        // 查找备份信息文件
        final infoFile = archive.findFile('backup_info.json');
        if (infoFile != null) {
          // 解析备份信息文件
          final infoContent = utf8.decode(infoFile.content as List<int>);
          final infoJson = jsonDecode(infoContent) as Map<String, dynamic>;
          description = infoJson['description'] as String?;
        }

        // 清理临时目录
        await storage.deleteDirectory(tempPath);
      } catch (e) {
        // 如果提取失败，使用文件名作为描述
        description = p.basename(filePath);
      }
    } else {
      // 如果没有提供存储接口，使用文件名作为描述
      description = p.basename(filePath);
    }

    return BackupInfo(
      path: filePath,
      creationTime: await file.lastModified(),
      size: await file.length(),
      description: description,
    );
  }
}

/// 备份服务
class BackupService {
  final IStorage _storage;

  /// 备份目录路径
  late final String _backupDir;

  /// 构造函数
  BackupService({
    required IStorage storage,
  }) : _storage = storage {
    _backupDir = p.join(_storage.getAppDataPath(), 'backups');
  }

  /// 清理旧备份
  Future<int> cleanupOldBackups(int keepCount) async {
    try {
      AppLogger.info('开始清理旧备份',
          tag: 'BackupService', data: {'keepCount': keepCount});

      // 为整个清理过程添加30秒超时
      final cleanupResult = await Future.any([
        _performCleanup(keepCount),
        Future.delayed(const Duration(seconds: 30), () => -1), // 超时返回-1
      ]);

      if (cleanupResult == -1) {
        AppLogger.warning('清理旧备份超时，但这不影响备份创建成功',
            tag: 'BackupService', data: {'keepCount': keepCount});
        return 0; // 超时时返回0，表示没有清理但不是错误
      }

      AppLogger.info('清理旧备份完成',
          tag: 'BackupService', data: {'deletedCount': cleanupResult});
      return cleanupResult;
    } catch (e, stack) {
      AppLogger.warning('清理旧备份失败，但这不影响备份创建成功',
          error: e, stackTrace: stack, tag: 'BackupService');
      return 0; // 清理失败不应该影响备份创建的成功
    }
  }

  /// 执行实际的清理操作
  Future<int> _performCleanup(int keepCount) async {
    // 获取所有备份
    final backups = await getBackups();

    // 如果备份数量小于等于保留数量，不需要清理
    if (backups.length <= keepCount) {
      AppLogger.info('备份数量未超过保留数量，无需清理', tag: 'BackupService', data: {
        'currentCount': backups.length,
        'keepCount': keepCount,
      });
      return 0;
    }

    // 获取需要删除的备份
    final backupsToDelete = backups.sublist(keepCount);
    AppLogger.info('准备删除旧备份', tag: 'BackupService', data: {
      'totalBackups': backups.length,
      'toDeleteCount': backupsToDelete.length,
    });

    // 删除旧备份，为每个删除操作添加超时
    int deletedCount = 0;
    for (final backup in backupsToDelete) {
      try {
        // 为每个删除操作添加10秒超时
        final deleteResult = await Future.any([
          deleteBackup(backup.path),
          Future.delayed(const Duration(seconds: 10), () => false),
        ]);

        if (deleteResult) {
          deletedCount++;
          AppLogger.debug('成功删除备份文件',
              tag: 'BackupService', data: {'path': backup.path});
        } else {
          AppLogger.warning('删除备份文件超时或失败',
              tag: 'BackupService', data: {'path': backup.path});
        }
      } catch (e) {
        AppLogger.warning('删除单个备份文件时出错', tag: 'BackupService', data: {
          'path': backup.path,
          'error': e.toString(),
        });
      }
    }

    return deletedCount;
  }

  /// 创建备份
  Future<String> createBackup({String? description}) async {
    final progressManager = BackupProgressManager();

    try {
      AppLogger.info('开始创建备份', tag: 'BackupService');

      // 开始备份进度
      progressManager.startBackup();

      // 生成备份文件名
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'backup_$timestamp.cgb';
      final backupPath = p.join(_backupDir, backupFileName);

      // 为整个备份过程添加超时机制
      final result = await Future.any([
        _performBackup(backupPath, description),
        Future.delayed(const Duration(minutes: 15), () {
          progressManager.failBackup('备份操作超时');
          throw TimeoutException('备份操作超时', const Duration(minutes: 15));
        }),
      ]);

      // 备份完成
      progressManager.completeBackup();
      AppLogger.info('备份创建完成', tag: 'BackupService');

      return result;
    } catch (e, stack) {
      AppLogger.error('创建备份失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      progressManager.failBackup('创建备份失败: $e');
      rethrow;
    }
  }

  /// 执行实际的备份操作
  Future<String> _performBackup(String backupPath, String? description) async {
    String? tempPath;
    final progressManager = BackupProgressManager();

    try {
      // 创建临时目录
      AppLogger.info('创建临时目录', tag: 'BackupService');
      progressManager.updateStep('创建临时目录...', detail: '正在准备备份环境');
      final tempDir = await _storage.createTempDirectory();
      tempPath = tempDir.path;

      // 备份数据库
      AppLogger.info('开始备份数据库', tag: 'BackupService');
      progressManager.updateStep('备份数据库...', detail: '正在复制数据库文件');
      progressManager.updateProgress(0, 4); // 0/4 步骤完成
      await _backupDatabase(tempPath);
      AppLogger.info('数据库备份完成', tag: 'BackupService');

      // 备份应用数据
      AppLogger.info('开始备份应用数据', tag: 'BackupService');
      progressManager.updateStep('备份应用数据...', detail: '正在复制用户文件');
      progressManager.updateProgress(1, 4); // 1/4 步骤完成
      await _backupAppData(tempPath);
      AppLogger.info('应用数据备份完成', tag: 'BackupService');

      // 创建备份信息文件（无论是否有描述都要创建）
      AppLogger.info('创建备份信息文件', tag: 'BackupService');
      progressManager.updateStep('创建信息文件...', detail: '正在保存备份信息');
      await _createBackupInfo(tempPath, description);

      // 创建ZIP文件
      AppLogger.info('开始创建ZIP文件', tag: 'BackupService', data: {
        'targetPath': backupPath,
      });
      progressManager.updateStep('压缩备份文件...', detail: '正在创建ZIP压缩包');
      progressManager.updateProgress(2, 4); // 2/4 步骤完成
      await _createZipArchive(tempPath, backupPath);
      AppLogger.info('ZIP文件创建完成', tag: 'BackupService');

      // 检查最终文件大小
      progressManager.updateStep('验证备份...', detail: '正在检查备份文件完整性');
      progressManager.updateProgress(3, 4); // 3/4 步骤完成
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        final fileSize = await backupFile.length();
        AppLogger.info('备份文件信息', tag: 'BackupService', data: {
          'path': backupPath,
          'size': fileSize,
          'sizeFormatted': '${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB',
        });
      }

      AppLogger.info('备份创建成功',
          tag: 'BackupService', data: {'path': backupPath});
      return backupPath;
    } finally {
      // 清理临时目录
      if (tempPath != null) {
        try {
          AppLogger.info('清理临时目录', tag: 'BackupService');
          await _storage.deleteDirectory(tempPath);
          AppLogger.info('临时目录清理完成', tag: 'BackupService');
        } catch (e) {
          AppLogger.warning('清理临时目录失败', tag: 'BackupService', data: {
            'error': e.toString(),
            'tempPath': tempPath,
          });
        }
      }
    }
  }

  /// 删除备份
  Future<bool> deleteBackup(String backupPath) async {
    try {
      AppLogger.info('删除备份', tag: 'BackupService', data: {'path': backupPath});

      // 检查备份文件是否存在
      if (!await _storage.fileExists(backupPath)) {
        AppLogger.warning('备份文件不存在，无法删除',
            tag: 'BackupService', data: {'path': backupPath});
        return false;
      }

      // 删除备份文件
      await _storage.deleteFile(backupPath);

      AppLogger.info('备份删除成功', tag: 'BackupService');
      return true;
    } catch (e, stack) {
      AppLogger.error('删除备份失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      return false;
    }
  }

  /// 导出备份到外部位置
  Future<bool> exportBackup(String backupPath, String exportPath) async {
    try {
      AppLogger.info('导出备份',
          tag: 'BackupService',
          data: {'source': backupPath, 'target': exportPath});

      // 检查备份文件是否存在
      if (!await _storage.fileExists(backupPath)) {
        AppLogger.warning('备份文件不存在，无法导出',
            tag: 'BackupService', data: {'path': backupPath});
        return false;
      }

      // 直接使用File API复制文件，绕过存储服务的路径验证
      try {
        final sourceFile = File(backupPath);

        // 确保目标目录存在
        final targetDir = Directory(p.dirname(exportPath));
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        // 复制文件
        await sourceFile.copy(exportPath);

        AppLogger.info('备份导出成功',
            tag: 'BackupService', data: {'path': exportPath});
        return true;
      } catch (fileError) {
        AppLogger.error('文件复制失败',
            error: fileError,
            tag: 'BackupService',
            data: {'source': backupPath, 'target': exportPath});
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('导出备份失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      return false;
    }
  }

  /// 获取所有备份
  Future<List<BackupInfo>> getBackups() async {
    try {
      // 确保备份目录存在
      if (!await _storage.directoryExists(_backupDir)) {
        await _storage.createDirectory(_backupDir);
        return [];
      }

      // 获取所有备份文件
      final files = await _storage.listDirectoryFiles(_backupDir);

      // 过滤出备份文件（支持.zip和.cgb扩展名）
      final backupFiles = files.where((file) {
        final lowerFile = file.toLowerCase();
        return lowerFile.endsWith('.zip') || lowerFile.endsWith('.cgb');
      }).toList();

      // 创建备份信息列表
      final backups = <BackupInfo>[];
      for (final file in backupFiles) {
        try {
          final backupFile = File(file);

          // 首先检查文件是否真的存在
          if (!await backupFile.exists()) {
            AppLogger.warning('备份文件已不存在，跳过', tag: 'BackupService', data: {
              'fileName': p.basename(file),
              'path': file,
            });
            continue;
          }

          // 为每个文件的信息获取添加超时
          BackupInfo? backupInfo;
          try {
            backupInfo = await Future.any([
              BackupInfo.fromFile(backupFile, storage: _storage),
              Future.delayed(const Duration(seconds: 5), () async {
                // 超时时检查文件是否存在，如果不存在则返回null
                if (!await backupFile.exists()) {
                  AppLogger.info('超时检查发现文件已被删除', tag: 'BackupService', data: {
                    'fileName': p.basename(file),
                  });
                  return null;
                }
                return BackupInfo(
                  path: file,
                  creationTime: await backupFile.lastModified(),
                  size: await backupFile.length(),
                  description: p.basename(file),
                );
              }),
            ]);
          } catch (timeoutError) {
            AppLogger.warning('获取备份文件信息时发生错误', tag: 'BackupService', data: {
              'fileName': p.basename(file),
              'error': timeoutError.toString(),
            });
            backupInfo = null;
          }

          // 只有当backupInfo不为null时才添加到列表
          if (backupInfo != null) {
            backups.add(backupInfo);
          } else {
            AppLogger.info('备份文件信息获取失败或文件已被删除，跳过', tag: 'BackupService', data: {
              'fileName': p.basename(file),
            });
          }
        } catch (e) {
          AppLogger.warning('无法读取备份文件信息，跳过', tag: 'BackupService', data: {
            'file': file,
            'error': e.toString(),
          });

          // 即使读取失败，也尝试创建基本的备份信息
          try {
            final backupFile = File(file);
            if (await backupFile.exists()) {
              final basicBackupInfo = BackupInfo(
                path: file,
                creationTime: await backupFile.lastModified(),
                size: await backupFile.length(),
                description: p.basename(file),
              );
              backups.add(basicBackupInfo);
              AppLogger.info('使用基本信息创建备份条目', tag: 'BackupService', data: {
                'fileName': p.basename(file),
              });
            } else {
              AppLogger.info('备份文件已不存在，跳过创建基本信息', tag: 'BackupService', data: {
                'fileName': p.basename(file),
              });
            }
          } catch (basicError) {
            AppLogger.warning('创建基本备份信息也失败，可能文件已被删除',
                tag: 'BackupService',
                data: {
                  'file': file,
                  'error': basicError.toString(),
                });
            // 文件可能在处理过程中被删除，这是正常情况，不需要特殊处理
          }
        }
      }

      // 按创建时间排序（最新的在前）
      backups.sort((a, b) => b.creationTime.compareTo(a.creationTime));

      return backups;
    } catch (e, stack) {
      AppLogger.error('获取备份列表失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      return [];
    }
  }

  /// 从外部位置导入备份
  Future<bool> importBackup(String importPath) async {
    try {
      AppLogger.info('导入备份', tag: 'BackupService', data: {'path': importPath});

      // 直接使用File API检查文件是否存在，绕过存储服务的路径验证
      final importFile = File(importPath);
      if (!await importFile.exists()) {
        AppLogger.warning('导入文件不存在',
            tag: 'BackupService', data: {'path': importPath});
        return false;
      }

      // 验证备份文件
      if (!await _isValidBackupFileExternal(importPath)) {
        AppLogger.warning('无效的备份文件',
            tag: 'BackupService', data: {'path': importPath});
        return false;
      }

      // 生成目标路径
      final fileName = p.basename(importPath);
      final targetPath = p.join(_backupDir, fileName);

      // 如果目标路径已存在同名文件，生成一个新的文件名
      String finalTargetPath = targetPath;
      if (await _storage.fileExists(targetPath)) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileNameWithoutExt = p.basenameWithoutExtension(fileName);
        final fileExt = p.extension(fileName);
        final newFileName = '${fileNameWithoutExt}_$timestamp$fileExt';
        finalTargetPath = p.join(_backupDir, newFileName);
      }

      // 确保备份目录存在
      await _storage.ensureDirectoryExists(_backupDir);

      // 直接使用File API复制文件，绕过存储服务的路径验证
      try {
        await importFile.copy(finalTargetPath);

        AppLogger.info('备份导入成功',
            tag: 'BackupService', data: {'path': finalTargetPath});
        return true;
      } catch (fileError) {
        AppLogger.error('文件复制失败',
            error: fileError,
            tag: 'BackupService',
            data: {'source': importPath, 'target': finalTargetPath});
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('导入备份失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      return false;
    }
  }

  /// 初始化
  Future<void> initialize() async {
    try {
      // 确保备份目录存在
      if (!await _storage.directoryExists(_backupDir)) {
        await _storage.createDirectory(_backupDir);
      }
    } catch (e, stack) {
      AppLogger.error('初始化备份服务失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 从备份恢复
  ///
  /// [backupPath] 备份文件路径
  /// [onRestoreComplete] 恢复完成后的回调函数，参数为是否需要重启应用
  /// [autoRestart] 是否在需要重启时自动重启应用
  Future<bool> restoreFromBackup(
    String backupPath, {
    void Function(bool needsRestart, String message)? onRestoreComplete,
    bool autoRestart = false,
  }) async {
    try {
      AppLogger.info('开始从备份恢复',
          tag: 'BackupService', data: {'path': backupPath});

      // 检查备份文件是否存在
      if (!await _storage.fileExists(backupPath)) {
        throw Exception('备份文件不存在: $backupPath');
      }

      // 创建临时目录
      final tempDir = await _storage.createTempDirectory();
      final tempPath = tempDir.path;

      // 解压备份文件
      await _extractZipArchive(backupPath, tempPath);

      // 检查备份兼容性
      await _validateBackupCompatibility(tempPath);

      // 先恢复应用数据，再恢复数据库
      await _restoreAppData(tempPath);

      try {
        // 恢复数据库（这一步可能会抛出NeedsRestartException）
        await _restoreDatabase(tempPath);
      } catch (e) {
        // 清理临时目录
        await _storage.deleteDirectory(tempPath);

        if (e is NeedsRestartException) {
          // 这不是真正的错误，只是需要重启的信号
          AppLogger.info('恢复过程需要重启应用',
              tag: 'BackupService',
              data: {'message': e.message, 'autoRestart': autoRestart});

          // 调用回调函数，通知需要重启
          if (onRestoreComplete != null) {
            onRestoreComplete(true, e.message);
          }

          // 自动重启由 BackupSettingsNotifier 处理，不需要创建标记文件

          // 创建恢复就绪标记文件
          final dbDir = p.join(_storage.getAppDataPath(), 'database');
          final readyMarkerPath = p.join(dbDir, 'db_ready_to_restore');

          try {
            await File(readyMarkerPath).writeAsString('ready');
            AppLogger.info('已创建数据库恢复就绪标记文件',
                tag: 'BackupService', data: {'path': readyMarkerPath});
          } catch (e) {
            AppLogger.error('创建数据库恢复就绪标记文件失败', tag: 'BackupService', error: e);
          }

          // 不再抛出异常，而是返回true表示恢复成功
          return true;
        } else {
          // 其他异常重新抛出
          rethrow;
        }
      }

      // 清理临时目录
      await _storage.deleteDirectory(tempPath);

      AppLogger.info('从备份恢复成功', tag: 'BackupService');

      // 调用回调函数，通知恢复完成但不需要重启
      if (onRestoreComplete != null) {
        onRestoreComplete(false, '恢复完成');
      }

      return true;
    } catch (e, stack) {
      AppLogger.error('从备份恢复失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      return false;
    }
  }

  /// 将目录添加到归档
  Future<void> _addDirectoryToArchive(
      String dirPath, String archivePath, Archive archive) async {
    try {
      // 获取目录中的所有文件
      final dir = Directory(dirPath);
      final entities = await dir.list().toList();

      AppLogger.info('处理目录到归档', tag: 'BackupService', data: {
        'dirPath': dirPath,
        'archivePath': archivePath,
        'entityCount': entities.length,
      });

      // 添加每个文件到归档
      int fileCount = 0;
      int totalSize = 0;

      for (final entity in entities) {
        final relativePath = p.relative(entity.path, from: dirPath);
        final archiveFilePath = p.join(archivePath, relativePath);

        if (entity is File) {
          // 读取文件内容
          final bytes = await entity.readAsBytes();
          totalSize += bytes.length;
          fileCount++;

          // 创建归档文件
          final archiveFile = ArchiveFile(
            archiveFilePath.replaceAll('\\', '/'),
            bytes.length,
            bytes,
          );

          // 添加到归档
          archive.addFile(archiveFile);

          // 每处理10个文件记录一次进度
          if (fileCount % 10 == 0) {
            AppLogger.info('归档进度', tag: 'BackupService', data: {
              'processedFiles': fileCount,
              'totalFiles': entities.whereType<File>().length,
              'currentDir': p.basename(dirPath),
              'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
            });
          }
        } else if (entity is Directory) {
          // 递归添加子目录
          await _addDirectoryToArchive(
            entity.path,
            archiveFilePath,
            archive,
          );
        }
      }

      AppLogger.info('目录归档完成', tag: 'BackupService', data: {
        'dirPath': dirPath,
        'fileCount': fileCount,
        'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
      });
    } catch (e, stack) {
      AppLogger.error('将目录添加到归档失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 备份应用数据
  Future<void> _backupAppData(String tempPath) async {
    try {
      final appDataPath = _storage.getAppDataPath();

      // 需要备份的目录（排除临时文件和缓存）
      final dirsToBackup = [
        'works', // 作品数据
        'characters', // 集字数据
        'practices', // 字帖数据
        'library', // 图库数据
        'database', // 数据库文件（单独处理）
      ];

      // 排除的目录（临时文件和缓存不需要备份）
      final dirsToExclude = [
        'temp', // 临时文件目录
        'cache', // 缓存目录
      ];

      // 创建应用数据备份目录
      final dataBackupDir = p.join(tempPath, 'data');
      await _storage.createDirectory(dataBackupDir);

      // 备份每个目录
      for (final dir in dirsToBackup) {
        // 跳过数据库目录，因为数据库有单独的备份逻辑
        if (dir == 'database') continue;

        final sourcePath = p.join(appDataPath, dir);
        final targetPath = p.join(dataBackupDir, dir);

        // 检查源目录是否存在
        if (await _storage.directoryExists(sourcePath)) {
          // 创建目标目录
          await _storage.createDirectory(targetPath);

          // 复制目录内容，排除不需要的子目录
          await _copyDirectorySelective(sourcePath, targetPath, dirsToExclude);

          AppLogger.info('数据目录备份完成', tag: 'BackupService', data: {
            'directory': dir,
            'sourcePath': sourcePath,
          });
        } else {
          AppLogger.info('数据目录不存在，跳过备份', tag: 'BackupService', data: {
            'directory': dir,
            'sourcePath': sourcePath,
          });
        }
      }
    } catch (e, stack) {
      AppLogger.error('备份应用数据失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 备份数据库
  Future<void> _backupDatabase(String tempPath) async {
    try {
      // 获取数据库路径
      final basePath = _storage.getAppDataPath();
      final dbPath = p.join(basePath, 'database', 'app.db');

      // 创建数据库备份目录
      final dbBackupDir = p.join(tempPath, 'database');
      await _storage.createDirectory(dbBackupDir);

      // 复制数据库文件
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        final dbBackupPath = p.join(dbBackupDir, p.basename(dbPath));
        await _storage.copyFile(dbPath, dbBackupPath);
      }
    } catch (e, stack) {
      AppLogger.error('备份数据库失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 选择性复制目录（排除指定的子目录）
  Future<void> _copyDirectorySelective(
      String sourcePath, String targetPath, List<String> excludeDirs) async {
    try {
      // 确保目标目录存在
      await _storage.ensureDirectoryExists(targetPath);

      // 获取源目录中的所有文件和目录
      final entities = await Directory(sourcePath).list().toList();

      AppLogger.debug('选择性复制目录', tag: 'BackupService', data: {
        'source': sourcePath,
        'target': targetPath,
        'itemCount': entities.length,
        'excludeDirs': excludeDirs,
      });

      // 复制每个文件和目录
      for (final entity in entities) {
        final fileName = p.basename(entity.path);
        final targetFilePath = p.join(targetPath, fileName);

        // 如果是目录，检查是否需要排除
        if (entity is Directory) {
          if (excludeDirs.contains(fileName)) {
            AppLogger.debug('跳过排除目录', tag: 'BackupService', data: {
              'directory': fileName,
              'path': entity.path,
            });
            continue;
          }

          final targetSubDir = p.join(targetPath, fileName);
          await _storage.ensureDirectoryExists(targetSubDir);
          await _copyDirectorySelective(entity.path, targetSubDir, excludeDirs);
        } else if (entity is File) {
          // 复制文件，添加重试机制
          await _copyFileWithRetry(entity.path, targetFilePath);
        }
      }
    } catch (e, stack) {
      AppLogger.error('选择性复制目录失败',
          error: e,
          stackTrace: stack,
          tag: 'BackupService',
          data: {
            'source': sourcePath,
            'target': targetPath,
            'excludeDirs': excludeDirs
          });
      rethrow;
    }
  }

  /// 复制目录
  Future<void> _copyDirectory(String sourcePath, String targetPath) async {
    try {
      // 确保目标目录存在
      await _storage.ensureDirectoryExists(targetPath);

      // 获取源目录中的所有文件和目录
      final entities = await Directory(sourcePath).list().toList();

      AppLogger.debug('复制目录', tag: 'BackupService', data: {
        'source': sourcePath,
        'target': targetPath,
        'itemCount': entities.length
      });

      // 复制每个文件和目录
      for (final entity in entities) {
        final fileName = p.basename(entity.path);
        final targetFilePath = p.join(targetPath, fileName);

        // 如果是目录，递归复制
        if (entity is Directory) {
          final targetSubDir = p.join(targetPath, fileName);
          await _storage.ensureDirectoryExists(targetSubDir);
          await _copyDirectory(entity.path, targetSubDir);
        } else if (entity is File) {
          // 复制文件，添加重试机制
          await _copyFileWithRetry(entity.path, targetFilePath);
        }
      }
    } catch (e, stack) {
      AppLogger.error('复制目录失败',
          error: e,
          stackTrace: stack,
          tag: 'BackupService',
          data: {'source': sourcePath, 'target': targetPath});
      rethrow;
    }
  }

  /// 带重试机制的文件复制
  Future<void> _copyFileWithRetry(String sourcePath, String targetPath,
      {int maxRetries = 3}) async {
    final fileName = p.basename(sourcePath);

    // 🔥 关键修复：检查文件大小，跳过过大的文件以防止卡顿
    try {
      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        final fileStat = await sourceFile.stat();
        final fileSizeMB = fileStat.size / (1024 * 1024);

        // 跳过超过200MB的文件 - 这是防止卡顿的关键
        if (fileSizeMB > 200) {
          AppLogger.warning('跳过超大文件以避免备份卡顿', tag: 'BackupService', data: {
            'file': fileName,
            'sizeMB': fileSizeMB.toStringAsFixed(2),
            'reason': '文件过大，可能导致备份卡顿超过2分钟'
          });
          return; // 直接返回，不复制此文件
        }

        // 对于大文件（>50MB）记录警告
        if (fileSizeMB > 50) {
          AppLogger.info('正在处理大文件', tag: 'BackupService', data: {
            'file': fileName,
            'sizeMB': fileSizeMB.toStringAsFixed(2),
            'note': '可能需要较长时间'
          });
        }
      }
    } catch (e) {
      // 如果无法获取文件信息，记录但继续尝试复制
      AppLogger.debug('无法获取文件大小信息',
          tag: 'BackupService',
          data: {'file': fileName, 'error': e.toString()});
    }

    int retryCount = 0;
    while (true) {
      try {
        final startTime = DateTime.now();
        await _storage.copyFile(sourcePath, targetPath);
        final duration = DateTime.now().difference(startTime);

        // 记录耗时较长的文件复制
        if (duration.inSeconds > 10) {
          AppLogger.info('文件复制耗时较长',
              tag: 'BackupService',
              data: {'file': fileName, 'duration': '${duration.inSeconds}秒'});
        }

        return;
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          AppLogger.error('复制文件失败，已达到最大重试次数',
              tag: 'BackupService',
              error: e,
              data: {
                'source': sourcePath,
                'target': targetPath,
                'retries': retryCount
              });
          rethrow;
        }

        AppLogger.warning('复制文件失败，准备重试', tag: 'BackupService', data: {
          'source': fileName,
          'target': targetPath,
          'retry': retryCount,
          'error': e.toString()
        });

        // 延迟后重试
        await Future.delayed(Duration(milliseconds: 200 * retryCount));
      }
    }
  }

  /// 创建备份信息文件
  Future<void> _createBackupInfo(String tempPath, String? description) async {
    try {
      final infoPath = p.join(tempPath, 'backup_info.json');

      // 获取当前数据版本
      final currentDataVersion = await _getCurrentDataVersion();

      final info = {
        'timestamp': DateTime.now().toIso8601String(),
        'description': description ?? '', // 如果没有描述则使用空字符串
        'dataVersion': currentDataVersion, // 使用统一的数据版本
        'platform': Platform.operatingSystem,
        'excludedDirectories': ['temp', 'cache'], // 记录排除的目录
        'includedDirectories': [
          'works',
          'characters',
          'practices',
          'library',
          'database'
        ],
      };

      await _storage.writeFile(infoPath, utf8.encode(jsonEncode(info)));

      AppLogger.info('备份信息文件创建完成', tag: 'BackupService', data: {
        'backupVersion': info['backupVersion'],
        'appVersion': info['appVersion'],
        'platform': info['platform'],
      });
    } catch (e, stack) {
      AppLogger.error('创建备份信息文件失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      // 不抛出异常，备份信息文件不是必须的
    }
  }

  /// 获取当前数据版本
  Future<String> _getCurrentDataVersion() async {
    try {
      return DataVersionMappingService.getCurrentDataVersion();
    } catch (e, stack) {
      AppLogger.error('获取当前数据版本失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      // 返回默认版本
      return 'v4'; // 默认使用最新版本
    }
  }

  /// 创建ZIP归档
  Future<void> _createZipArchive(String sourcePath, String targetPath) async {
    try {
      // 创建一个归档
      final archive = Archive();

      // 添加文件到归档
      await _addDirectoryToArchive(sourcePath, '', archive);

      // 编码归档为ZIP格式
      final zipData = ZipEncoder().encode(archive);

      // 写入ZIP文件
      await _storage.writeFile(targetPath, zipData);
    } catch (e, stack) {
      AppLogger.error('创建ZIP归档失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 解压ZIP归档
  Future<void> _extractZipArchive(String zipPath, String targetPath) async {
    try {
      // 读取ZIP文件
      final zipBytes = await _storage.readFile(zipPath);

      // 解码ZIP数据
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // 解压文件
      for (final file in archive) {
        final filePath = p.join(targetPath, file.name);

        if (file.isFile) {
          // 确保目录存在
          final fileDir = p.dirname(filePath);
          await _storage.ensureDirectoryExists(fileDir);

          // 写入文件
          await _storage.writeFile(filePath, file.content as List<int>);
        } else {
          // 创建目录
          await _storage.createDirectory(filePath);
        }
      }
    } catch (e, stack) {
      AppLogger.error('解压ZIP归档失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 验证外部备份文件是否有效（直接使用File API）
  Future<bool> _isValidBackupFileExternal(String filePath) async {
    try {
      // 🔧 恢復原始邏輯：只檢查 .cgb 格式
      final lowerFilePath = filePath.toLowerCase();
      if (!lowerFilePath.endsWith('.cgb')) {
        AppLogger.warning('文件擴展名不是 .cgb',
            tag: 'BackupService', data: {'path': filePath});
        return false;
      }

      // 读取ZIP文件
      final file = File(filePath);
      if (!await file.exists()) {
        AppLogger.warning('文件不存在',
            tag: 'BackupService', data: {'path': filePath});
        return false;
      }

      final zipBytes = await file.readAsBytes();
      AppLogger.debug('读取ZIP文件成功',
          tag: 'BackupService',
          data: {'path': filePath, 'size': zipBytes.length});

      // 尝试解码ZIP数据
      try {
        final archive = ZipDecoder().decodeBytes(zipBytes);
        AppLogger.debug('解码ZIP数据成功',
            tag: 'BackupService', data: {'fileCount': archive.length});

        // 检查是否包含必要的目录和文件
        bool hasDatabase = false;
        bool hasData = false;

        // 记录备份文件内容
        final fileList = <String>[];

        for (final file in archive) {
          final fileName = file.name;
          fileList.add(fileName);

          if (fileName.startsWith('database/')) {
            hasDatabase = true;
          } else if (fileName.startsWith('data/')) {
            hasData = true;
          }

          // 如果找到了必要的目录，提前返回
          if (hasDatabase && hasData) {
            // 记录备份文件内容
            AppLogger.debug('备份文件内容',
                tag: 'BackupService', data: {'files': fileList});
            return true;
          }
        }

        // 记录备份文件内容
        AppLogger.warning('备份文件内容不完整', tag: 'BackupService', data: {
          'files': fileList,
          'hasDatabase': hasDatabase,
          'hasData': hasData
        });

        // 如果没有找到必要的目录，返回false
        return false;
      } catch (e) {
        // 如果解码失败，说明不是有效的ZIP文件
        AppLogger.error('解码备份文件失败', tag: 'BackupService', error: e);
        return false;
      }
    } catch (e) {
      // 任何异常都表示文件无效
      AppLogger.error('验证备份文件失败', tag: 'BackupService', error: e);
      return false;
    }
  }

  /// 验证备份兼容性
  Future<void> _validateBackupCompatibility(String tempPath) async {
    try {
      final infoPath = p.join(tempPath, 'backup_info.json');

      // 检查备份信息文件是否存在
      if (!await _storage.fileExists(infoPath)) {
        AppLogger.warning('备份信息文件不存在，跳过兼容性检查', tag: 'BackupService');
        return;
      }

      // 读取备份信息
      final infoBytes = await _storage.readFile(infoPath);
      final infoJson =
          jsonDecode(utf8.decode(infoBytes)) as Map<String, dynamic>;

      final backupVersion = infoJson['backupVersion'] as String?;
      final appVersion = infoJson['appVersion'] as String?;
      final platform = infoJson['platform'] as String?;
      final compatibility = infoJson['compatibility'] as Map<String, dynamic>?;

      AppLogger.info('检查备份兼容性', tag: 'BackupService', data: {
        'backupVersion': backupVersion,
        'backupAppVersion': appVersion,
        'backupPlatform': platform,
        'currentPlatform': Platform.operatingSystem,
      });

      // 检查平台兼容性（警告级别）
      if (platform != null && platform != Platform.operatingSystem) {
        AppLogger.warning('备份来自不同平台，可能存在兼容性问题', tag: 'BackupService', data: {
          'backupPlatform': platform,
          'currentPlatform': Platform.operatingSystem,
        });
      }

      // 检查应用版本兼容性
      if (compatibility != null) {
        final minAppVersion = compatibility['minAppVersion'] as String?;
        final maxAppVersion = compatibility['maxAppVersion'] as String?;
        // 获取当前应用版本
        final currentAppVersion = _getCurrentAppVersion();

        if (minAppVersion != null &&
            _compareVersions(currentAppVersion, minAppVersion) < 0) {
          throw Exception(
              '当前应用版本($currentAppVersion)低于备份要求的最低版本($minAppVersion)，无法恢复此备份');
        }

        if (maxAppVersion != null &&
            _compareVersions(currentAppVersion, maxAppVersion) > 0) {
          AppLogger.warning('当前应用版本可能高于备份兼容的最高版本，恢复后可能需要数据迁移',
              tag: 'BackupService',
              data: {
                'currentVersion': currentAppVersion,
                'maxSupportedVersion': maxAppVersion,
              });
        }
      }

      // 检查备份格式版本
      if (backupVersion != null) {
        // 支持的备份格式版本
        final supportedBackupVersions = _getSupportedBackupVersions();
        if (!supportedBackupVersions.contains(backupVersion)) {
          throw Exception('不支持的备份格式版本: $backupVersion');
        }
      }

      AppLogger.info('备份兼容性检查通过', tag: 'BackupService');
    } catch (e, stack) {
      if (e.toString().contains('不支持') || e.toString().contains('无法恢复')) {
        AppLogger.error('备份兼容性检查失败',
            error: e, stackTrace: stack, tag: 'BackupService');
        rethrow;
      } else {
        AppLogger.warning('备份兼容性检查出现问题，但继续恢复', tag: 'BackupService', data: {
          'error': e.toString(),
        });
      }
    }
  }

  /// 比较版本号（简单实现）
  /// 返回值：-1表示v1 < v2，0表示相等，1表示v1 > v2
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    final maxLength = math.max(parts1.length, parts2.length);

    for (int i = 0; i < maxLength; i++) {
      final part1 = i < parts1.length ? parts1[i] : 0;
      final part2 = i < parts2.length ? parts2[i] : 0;

      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }

    return 0;
  }

  /// 恢复应用数据
  Future<void> _restoreAppData(String tempPath) async {
    try {
      final appDataPath = _storage.getAppDataPath();
      final dataBackupDir = p.join(tempPath, 'data');

      AppLogger.info('开始恢复应用数据',
          tag: 'BackupService',
          data: {'sourcePath': dataBackupDir, 'targetPath': appDataPath});

      // 检查备份数据目录是否存在
      if (!await _storage.directoryExists(dataBackupDir)) {
        throw Exception('备份中未找到应用数据目录');
      }

      // 需要恢复的目录
      final dirsToRestore = [
        'works',
        'characters',
        'practices',
        'library', // 添加图库目录
      ];

      // 恢复每个目录
      for (final dir in dirsToRestore) {
        final sourcePath = p.join(dataBackupDir, dir);
        final targetPath = p.join(appDataPath, dir);

        AppLogger.info('准备恢复目录', tag: 'BackupService', data: {
          'directory': dir,
          'sourcePath': sourcePath,
          'targetPath': targetPath
        });

        // 检查源目录是否存在
        if (await _storage.directoryExists(sourcePath)) {
          // 删除目标目录（如果存在）
          if (await _storage.directoryExists(targetPath)) {
            AppLogger.info('删除现有目标目录',
                tag: 'BackupService', data: {'path': targetPath});
            await _storage.deleteDirectory(targetPath);
          }

          // 创建目标目录
          await _storage.createDirectory(targetPath);

          // 复制目录内容
          await _copyDirectory(sourcePath, targetPath);

          AppLogger.info('成功恢复目录',
              tag: 'BackupService', data: {'directory': dir});

          // 为图库目录添加特定日志
          if (dir == 'library') {
            AppLogger.info('图库数据恢复完成',
                tag: 'BackupService', data: {'path': targetPath});
          }
        } else {
          AppLogger.warning('源目录不存在，跳过恢复',
              tag: 'BackupService',
              data: {'directory': dir, 'path': sourcePath});
        }
      }

      AppLogger.info('应用数据恢复完成', tag: 'BackupService');
    } catch (e, stack) {
      AppLogger.error('恢复应用数据失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 恢复数据库
  Future<void> _restoreDatabase(String tempPath) async {
    try {
      // 获取数据库路径
      final basePath = _storage.getAppDataPath();
      final dbPath = p.join(basePath, 'database', 'app.db');
      final dbDir = p.dirname(dbPath);

      // 获取备份数据库路径
      final dbBackupDir = p.join(tempPath, 'database');

      // 检查备份数据库目录是否存在
      final dbBackupDirExists = await Directory(dbBackupDir).exists();
      AppLogger.debug('备份数据库目录状态',
          tag: 'BackupService',
          data: {'exists': dbBackupDirExists, 'path': dbBackupDir});

      if (!dbBackupDirExists) {
        throw Exception('备份中未找到数据库目录');
      }

      // 列出备份数据库目录中的所有文件
      final dbBackupFiles = Directory(dbBackupDir).listSync();
      AppLogger.debug('备份数据库目录内容',
          tag: 'BackupService',
          data: {'files': dbBackupFiles.map((e) => e.path).toList()});

      // 查找数据库文件
      final dbBackupFile = dbBackupFiles.whereType<File>().firstWhere(
            (file) => p.basename(file.path) == p.basename(dbPath),
            orElse: () => throw Exception('备份中未找到数据库文件'),
          );

      AppLogger.debug('找到备份数据库文件',
          tag: 'BackupService',
          data: {'path': dbBackupFile.path, 'size': dbBackupFile.lengthSync()});

      // 创建恢复标记文件，包含备份数据库的路径
      final restoreMarkerPath = p.join(dbDir, 'restore_pending.json');
      final restoreInfo = {
        'backup_db_path': dbBackupFile.path,
        'timestamp': DateTime.now().toIso8601String(),
        'original_db_path': dbPath,
      };

      // 写入恢复标记文件
      await File(restoreMarkerPath).writeAsString(jsonEncode(restoreInfo));

      AppLogger.info('已创建数据库恢复标记文件，应用将在下次启动时完成恢复',
          tag: 'BackupService',
          data: {'markerPath': restoreMarkerPath, 'restoreInfo': restoreInfo});

      // 等待一段时间，确保文件操作完成
      await Future.delayed(const Duration(milliseconds: 500));

      // 复制备份数据库文件到待恢复位置
      final pendingDbPath = p.join(dbDir, 'app.db.new');

      // 确保目标目录存在
      await Directory(dbDir).create(recursive: true);

      // 复制文件
      await dbBackupFile.copy(pendingDbPath);
      final pendingDbFile = File(pendingDbPath);
      final pendingDbExists = await pendingDbFile.exists();
      final pendingDbSize = pendingDbExists ? await pendingDbFile.length() : 0;

      AppLogger.info('已准备好数据库恢复文件，应用将在下次启动时完成恢复', tag: 'BackupService', data: {
        'pendingDbPath': pendingDbPath,
        'exists': pendingDbExists,
        'size': pendingDbSize,
        'originalSize': dbBackupFile.lengthSync()
      });

      // 通知用户需要重启应用以完成数据库恢复
      throw NeedsRestartException('数据库恢复需要重启应用');
    } catch (e, stack) {
      if (e is NeedsRestartException) {
        // 这不是真正的错误，只是需要重启的信号
        rethrow;
      }

      AppLogger.error('恢复数据库失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
    }
  }

  /// 获取当前应用版本
  String _getCurrentAppVersion() {
    try {
      return VersionConfig.versionInfo.shortVersion;
    } catch (e) {
      // 如果VersionConfig未初始化，抛出异常而不是返回默认值
      AppLogger.error('VersionConfig未初始化', 
          tag: 'BackupService', data: {'error': e.toString()});
      throw StateError('无法获取应用版本，请确保 VersionConfig 已正确初始化: $e');
    }
  }

  /// 获取支持的备份格式版本列表
  List<String> _getSupportedBackupVersions() {
    // 基于当前版本动态生成支持的版本列表
    final currentVersion = _getCurrentAppVersion();
    final parts = currentVersion.split('.');
    final majorMinor = '${parts[0]}.${parts.length > 1 ? parts[1] : '0'}';
    
    // 支持当前版本和前一个小版本
    final currentMajorMinor = double.tryParse(majorMinor) ?? 1.0;
    final previousVersion = (currentMajorMinor - 0.1).toStringAsFixed(1);
    
    return [previousVersion, majorMinor];
  }
}

/// 表示需要重启应用的异常
class NeedsRestartException implements Exception {
  final String message;

  NeedsRestartException(this.message);

  @override
  String toString() => 'NeedsRestartException: $message';
}
