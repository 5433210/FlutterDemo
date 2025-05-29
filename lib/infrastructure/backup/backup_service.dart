import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../logging/logger.dart';
import '../persistence/database_interface.dart';
import '../storage/storage_interface.dart';

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
  final DatabaseInterface _database;

  /// 备份目录路径
  late final String _backupDir;

  /// 构造函数
  BackupService({
    required IStorage storage,
    required DatabaseInterface database,
  })  : _storage = storage,
        _database = database {
    _backupDir = p.join(_storage.getAppDataPath(), 'backups');
  }

  /// 清理旧备份
  Future<int> cleanupOldBackups(int keepCount) async {
    try {
      AppLogger.info('清理旧备份',
          tag: 'BackupService', data: {'keepCount': keepCount});

      // 获取所有备份
      final backups = await getBackups();

      // 如果备份数量小于等于保留数量，不需要清理
      if (backups.length <= keepCount) {
        return 0;
      }

      // 获取需要删除的备份
      final backupsToDelete = backups.sublist(keepCount);

      // 删除旧备份
      int deletedCount = 0;
      for (final backup in backupsToDelete) {
        final success = await deleteBackup(backup.path);
        if (success) {
          deletedCount++;
        }
      }

      AppLogger.info('清理旧备份完成',
          tag: 'BackupService', data: {'deletedCount': deletedCount});
      return deletedCount;
    } catch (e, stack) {
      AppLogger.error('清理旧备份失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      return 0;
    }
  }

  /// 创建备份
  Future<String> createBackup({String? description}) async {
    try {
      AppLogger.info('开始创建备份', tag: 'BackupService');

      // 生成备份文件名
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupFileName = 'backup_$timestamp.zip';
      final backupPath = p.join(_backupDir, backupFileName);

      // 创建临时目录
      final tempDir = await _storage.createTempDirectory();
      final tempPath = tempDir.path;

      // 备份数据库
      await _backupDatabase(tempPath);

      // 备份应用数据
      await _backupAppData(tempPath);

      // 创建备份描述文件
      if (description != null) {
        await _createBackupInfo(tempPath, description);
      }

      // 创建ZIP文件
      await _createZipArchive(tempPath, backupPath);

      // 清理临时目录
      await _storage.deleteDirectory(tempPath);

      AppLogger.info('备份创建成功',
          tag: 'BackupService', data: {'path': backupPath});
      return backupPath;
    } catch (e, stack) {
      AppLogger.error('创建备份失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      rethrow;
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

      // 过滤出ZIP文件
      final zipFiles =
          files.where((file) => file.toLowerCase().endsWith('.zip')).toList();

      // 创建备份信息列表
      final backups = <BackupInfo>[];
      for (final file in zipFiles) {
        try {
          final backupFile = File(file);
          final backupInfo =
              await BackupInfo.fromFile(backupFile, storage: _storage);
          backups.add(backupInfo);
        } catch (e) {
          AppLogger.warning('无法读取备份文件信息',
              tag: 'BackupService', data: {'file': file, 'error': e});
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

      // 添加每个文件到归档
      for (final entity in entities) {
        final relativePath = p.relative(entity.path, from: dirPath);
        final archiveFilePath = p.join(archivePath, relativePath);

        if (entity is File) {
          // 读取文件内容
          final bytes = await entity.readAsBytes();

          // 创建归档文件
          final archiveFile = ArchiveFile(
            archiveFilePath.replaceAll('\\', '/'),
            bytes.length,
            bytes,
          );

          // 添加到归档
          archive.addFile(archiveFile);
        } else if (entity is Directory) {
          // 递归添加子目录
          await _addDirectoryToArchive(
            entity.path,
            archiveFilePath,
            archive,
          );
        }
      }
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

      // 需要备份的目录
      final dirsToBackup = [
        'works',
        'characters',
        'practices',
        'library', // 添加图库目录
      ];

      // 创建应用数据备份目录
      final dataBackupDir = p.join(tempPath, 'data');
      await _storage.createDirectory(dataBackupDir);

      // 备份每个目录
      for (final dir in dirsToBackup) {
        final sourcePath = p.join(appDataPath, dir);
        final targetPath = p.join(dataBackupDir, dir);

        // 检查源目录是否存在
        if (await _storage.directoryExists(sourcePath)) {
          // 创建目标目录
          await _storage.createDirectory(targetPath);

          // 复制目录内容
          await _copyDirectory(sourcePath, targetPath);

          // 记录特定目录的备份情况
          if (dir == 'library') {
            AppLogger.info('图库数据备份完成',
                tag: 'BackupService', data: {'path': sourcePath});
          }
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
    int retryCount = 0;
    while (true) {
      try {
        await _storage.copyFile(sourcePath, targetPath);
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
          'source': sourcePath,
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
  Future<void> _createBackupInfo(String tempPath, String description) async {
    try {
      final infoPath = p.join(tempPath, 'backup_info.json');
      final info = {
        'timestamp': DateTime.now().toIso8601String(),
        'description': description,
        'version': '1.0',
      };

      await _storage.writeFile(infoPath, utf8.encode(jsonEncode(info)));
    } catch (e, stack) {
      AppLogger.error('创建备份信息文件失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      // 不抛出异常，备份信息文件不是必须的
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
      // 检查文件扩展名
      if (!filePath.toLowerCase().endsWith('.zip')) {
        AppLogger.warning('文件扩展名不是.zip',
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

      // 关闭数据库连接
      await _database.close();

      // 等待一段时间，确保数据库连接完全关闭
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

      // 重新打开数据库
      await _database.initialize();

      // 通知用户需要重启应用
      throw NeedsRestartException('数据库恢复需要重启应用');
    } catch (e, stack) {
      if (e is NeedsRestartException) {
        // 这不是真正的错误，只是需要重启的信号
        rethrow;
      }

      AppLogger.error('恢复数据库失败',
          error: e, stackTrace: stack, tag: 'BackupService');
      // 尝试重新打开数据库
      try {
        await _database.initialize();
      } catch (openError) {
        AppLogger.error('重新打开数据库失败', error: openError, tag: 'BackupService');
      }
      rethrow;
    }
  }
}

/// 表示需要重启应用的异常
class NeedsRestartException implements Exception {
  final String message;

  NeedsRestartException(this.message);

  @override
  String toString() => 'NeedsRestartException: $message';
}
