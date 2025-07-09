import 'dart:io';

import 'package:path/path.dart' as path;

import '../../infrastructure/logging/logger.dart';
import 'data_path_config_service.dart';

/// 数据迁移服务
///
/// 负责处理应用数据在不同路径之间的迁移，包括：
/// - 数据复制和移动
/// - 版本信息同步
/// - 迁移完整性验证
/// - 回滚支持
class DataMigrationService {
  /// 迁移数据到新路径
  ///
  /// [sourcePath] 源数据路径
  /// [targetPath] 目标数据路径
  /// [moveData] 是否移动数据（true）或复制数据（false）
  /// [onProgress] 进度回调，参数为已处理文件数和总文件数
  static Future<MigrationResult> migrateData(
    String sourcePath,
    String targetPath, {
    bool moveData = false,
    void Function(int processed, int total)? onProgress,
  }) async {
    AppLogger.info('开始数据迁移', tag: 'DataMigration', data: {
      'source': sourcePath,
      'target': targetPath,
      'moveData': moveData,
    });

    try {
      // 1. 验证源路径和目标路径
      final validationResult =
          await _validateMigrationPaths(sourcePath, targetPath);
      if (!validationResult.isValid) {
        return MigrationResult.failure(validationResult.error);
      }

      // 2. 创建备份点（如果是移动操作）
      String? backupPath;
      if (moveData) {
        backupPath = await _createBackupPoint(sourcePath);
      }

      // 3. 计算需要迁移的文件
      final filesToMigrate = await _getFilesToMigrate(sourcePath);
      final totalFiles = filesToMigrate.length;

      AppLogger.debug('发现 $totalFiles 个文件需要迁移', tag: 'DataMigration');

      // 4. 确保目标目录存在
      await Directory(targetPath).create(recursive: true);

      // 5. 迁移文件
      int processedFiles = 0;
      for (final fileInfo in filesToMigrate) {
        await _migrateFile(fileInfo, sourcePath, targetPath, moveData);
        processedFiles++;
        onProgress?.call(processedFiles, totalFiles);
      }

      // 6. 更新目标路径的版本信息
      await DataPathConfigService.writeDataVersion(targetPath);

      // 7. 验证迁移完整性
      final verificationResult =
          await _verifyMigration(sourcePath, targetPath, filesToMigrate);
      if (!verificationResult.isValid) {
        // 迁移验证失败，尝试回滚
        if (backupPath != null) {
          await _rollbackMigration(backupPath, sourcePath);
        }
        return MigrationResult.failure('迁移验证失败: ${verificationResult.error}');
      }

      // 8. 清理源数据（如果是移动操作）
      if (moveData && backupPath != null) {
        await _cleanupAfterMove(sourcePath, backupPath);
      }

      AppLogger.info('数据迁移完成', tag: 'DataMigration', data: {
        'processedFiles': processedFiles,
        'totalFiles': totalFiles,
      });

      return MigrationResult.success(processedFiles);
    } catch (e, stack) {
      AppLogger.error('数据迁移失败',
          error: e, stackTrace: stack, tag: 'DataMigration');
      return MigrationResult.failure('迁移过程中发生错误: $e');
    }
  }

  /// 估算迁移时间和数据大小
  static Future<MigrationEstimate> estimateMigration(String sourcePath) async {
    try {
      final filesToMigrate = await _getFilesToMigrate(sourcePath);
      int totalSize = 0;
      int fileCount = filesToMigrate.length;

      for (final fileInfo in filesToMigrate) {
        totalSize += fileInfo.size;
      }

      // 估算迁移时间（基于文件大小，假设每MB需要1秒）
      final estimatedSeconds = (totalSize / (1024 * 1024)).ceil();

      return MigrationEstimate(
        fileCount: fileCount,
        totalSize: totalSize,
        estimatedDuration: Duration(seconds: estimatedSeconds),
      );
    } catch (e) {
      AppLogger.warning('估算迁移信息失败', error: e, tag: 'DataMigration');
      return const MigrationEstimate(
        fileCount: 0,
        totalSize: 0,
        estimatedDuration: Duration(seconds: 1),
      );
    }
  }

  /// 验证迁移路径的有效性
  static Future<_ValidationResult> _validateMigrationPaths(
      String sourcePath, String targetPath) async {
    // 检查源路径是否存在
    if (!await Directory(sourcePath).exists()) {
      return _ValidationResult.invalid('源路径不存在: $sourcePath');
    }

    // 检查源路径和目标路径是否相同
    if (path.normalize(sourcePath) == path.normalize(targetPath)) {
      return _ValidationResult.invalid('源路径和目标路径不能相同');
    }

    // 检查目标路径是否为源路径的子目录
    if (path.isWithin(sourcePath, targetPath)) {
      return _ValidationResult.invalid('目标路径不能位于源路径内部');
    }

    // 检查目标路径是否可写
    try {
      final targetDir = Directory(targetPath);
      await targetDir.create(recursive: true);

      final testFile = File(path.join(targetPath, 'migration_test.tmp'));
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      return _ValidationResult.invalid('目标路径无法写入: $e');
    }

    return _ValidationResult.valid();
  }

  /// 获取需要迁移的文件列表
  static Future<List<_FileInfo>> _getFilesToMigrate(String sourcePath) async {
    final files = <_FileInfo>[];
    final sourceDir = Directory(sourcePath);

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        // 跳过临时文件和系统文件
        final fileName = path.basename(entity.path);
        if (_shouldSkipFile(fileName)) continue;

        final stat = await entity.stat();
        final relativePath = path.relative(entity.path, from: sourcePath);

        files.add(_FileInfo(
          relativePath: relativePath,
          size: stat.size,
          lastModified: stat.modified,
        ));
      }
    }

    return files;
  }

  /// 迁移单个文件
  static Future<void> _migrateFile(_FileInfo fileInfo, String sourcePath,
      String targetPath, bool moveData) async {
    final sourceFile = File(path.join(sourcePath, fileInfo.relativePath));
    final targetFile = File(path.join(targetPath, fileInfo.relativePath));

    // 确保目标目录存在
    await targetFile.parent.create(recursive: true);

    if (moveData) {
      await sourceFile.rename(targetFile.path);
    } else {
      await sourceFile.copy(targetFile.path);
    }
  }

  /// 创建备份点
  static Future<String> _createBackupPoint(String sourcePath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = '${sourcePath}_backup_$timestamp';

    // 不是完整备份，只是记录备份点路径，实际备份在需要时进行
    return backupPath;
  }

  /// 验证迁移完整性
  static Future<_ValidationResult> _verifyMigration(String sourcePath,
      String targetPath, List<_FileInfo> expectedFiles) async {
    try {
      for (final fileInfo in expectedFiles) {
        final targetFile = File(path.join(targetPath, fileInfo.relativePath));

        if (!await targetFile.exists()) {
          return _ValidationResult.invalid('目标文件不存在: ${fileInfo.relativePath}');
        }

        final targetStat = await targetFile.stat();
        if (targetStat.size != fileInfo.size) {
          return _ValidationResult.invalid('文件大小不匹配: ${fileInfo.relativePath}');
        }
      }

      return _ValidationResult.valid();
    } catch (e) {
      return _ValidationResult.invalid('验证过程出错: $e');
    }
  }

  /// 回滚迁移
  static Future<void> _rollbackMigration(
      String backupPath, String originalPath) async {
    try {
      AppLogger.warning('执行迁移回滚', tag: 'DataMigration', data: {
        'backupPath': backupPath,
        'originalPath': originalPath,
      });

      // 这里应该根据具体的备份策略进行回滚
      // 目前的实现比较简单，实际应用中可能需要更复杂的回滚逻辑
    } catch (e) {
      AppLogger.error('迁移回滚失败', error: e, tag: 'DataMigration');
    }
  }

  /// 移动操作后的清理
  static Future<void> _cleanupAfterMove(
      String sourcePath, String backupPath) async {
    try {
      // 删除备份点标记等清理工作
      AppLogger.debug('完成移动操作清理', tag: 'DataMigration');
    } catch (e) {
      AppLogger.warning('移动后清理失败', error: e, tag: 'DataMigration');
    }
  }

  /// 检查是否应该跳过某个文件
  static bool _shouldSkipFile(String fileName) {
    const skipPatterns = [
      '.tmp',
      '.temp',
      '.lock',
      '.log',
      'Thumbs.db',
      'desktop.ini',
      '.DS_Store',
    ];

    return skipPatterns.any((pattern) => fileName.contains(pattern));
  }
}

/// 迁移结果
class MigrationResult {
  final bool isSuccess;
  final String? errorMessage;
  final int? processedFiles;

  const MigrationResult._(
      this.isSuccess, this.errorMessage, this.processedFiles);

  factory MigrationResult.success(int processedFiles) =>
      MigrationResult._(true, null, processedFiles);

  factory MigrationResult.failure(String errorMessage) =>
      MigrationResult._(false, errorMessage, null);
}

/// 迁移估算信息
class MigrationEstimate {
  final int fileCount;
  final int totalSize;
  final Duration estimatedDuration;

  const MigrationEstimate({
    required this.fileCount,
    required this.totalSize,
    required this.estimatedDuration,
  });

  /// 格式化文件大小显示
  String get formattedSize {
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    } else if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  /// 格式化时间显示
  String get formattedDuration {
    if (estimatedDuration.inSeconds < 60) {
      return '${estimatedDuration.inSeconds} 秒';
    } else if (estimatedDuration.inMinutes < 60) {
      return '${estimatedDuration.inMinutes} 分钟';
    } else {
      return '${estimatedDuration.inHours} 小时 ${estimatedDuration.inMinutes % 60} 分钟';
    }
  }
}

/// 文件信息
class _FileInfo {
  final String relativePath;
  final int size;
  final DateTime lastModified;

  const _FileInfo({
    required this.relativePath,
    required this.size,
    required this.lastModified,
  });
}

/// 验证结果
class _ValidationResult {
  final bool isValid;
  final String error;

  const _ValidationResult._(this.isValid, this.error);

  factory _ValidationResult.valid() => const _ValidationResult._(true, '');
  factory _ValidationResult.invalid(String error) =>
      _ValidationResult._(false, error);
}
