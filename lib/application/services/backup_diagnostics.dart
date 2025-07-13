import 'dart:io';

import '../../../infrastructure/logging/logger.dart';

/// 备份诊断工具
class BackupDiagnostics {
  /// 检查备份前置条件
  static Future<BackupDiagnosticResult> checkBackupPreconditions({
    required String dataPath,
    required String backupPath,
  }) async {
    final issues = <String>[];
    final warnings = <String>[];

    try {
      AppLogger.info('开始备份诊断检查', tag: 'BackupDiagnostics');

      // 1. 检查数据目录
      final dataDir = Directory(dataPath);
      if (!await dataDir.exists()) {
        issues.add('数据目录不存在: $dataPath');
      } else {
        final dataDirSize = await _getDirectorySize(dataDir);
        AppLogger.info('数据目录大小', tag: 'BackupDiagnostics', data: {
          'path': dataPath,
          'sizeMB': (dataDirSize / 1024 / 1024).toStringAsFixed(2),
        });

        if (dataDirSize > 1024 * 1024 * 1024) {
          // > 1GB
          warnings.add(
              '数据目录较大 (${(dataDirSize / 1024 / 1024 / 1024).toStringAsFixed(2)} GB)，备份可能需要较长时间');
        }
      }

      // 2. 检查备份目录
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        try {
          await backupDir.create(recursive: true);
        } catch (e) {
          issues.add('无法创建备份目录: $backupPath');
        }
      }

      // 3. 检查可用存储空间
      if (await backupDir.exists()) {
        final freeSpace = await _getAvailableSpace(backupPath);
        final dataSize = await _getDirectorySize(dataDir);
        final estimatedBackupSize = (dataSize * 0.7).toInt(); // 假设压缩率30%

        AppLogger.info('存储空间检查', tag: 'BackupDiagnostics', data: {
          'freeSpaceMB': (freeSpace / 1024 / 1024).toStringAsFixed(2),
          'estimatedBackupSizeMB':
              (estimatedBackupSize / 1024 / 1024).toStringAsFixed(2),
        });

        if (freeSpace < estimatedBackupSize * 2) {
          // 需要2倍空间作为缓冲
          if (freeSpace < estimatedBackupSize) {
            issues.add(
                '存储空间不足。需要: ${(estimatedBackupSize / 1024 / 1024).toStringAsFixed(0)} MB，可用: ${(freeSpace / 1024 / 1024).toStringAsFixed(0)} MB');
          } else {
            warnings.add('存储空间紧张，建议清理后再备份');
          }
        }
      }

      // 4. 检查写入权限
      try {
        final testFile = File('$backupPath/test_write.tmp');
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        issues.add('备份目录无写入权限: $backupPath');
      }

      // 5. 检查大文件
      final largeFiles = await _findLargeFiles(dataDir);
      if (largeFiles.isNotEmpty) {
        warnings.add('发现 ${largeFiles.length} 个大文件 (>50MB)，可能影响备份速度');
        AppLogger.info('大文件列表', tag: 'BackupDiagnostics', data: {
          'largeFiles': largeFiles,
        });
      }

      AppLogger.info('备份诊断完成', tag: 'BackupDiagnostics', data: {
        'issues': issues.length,
        'warnings': warnings.length,
      });

      return BackupDiagnosticResult(
        canProceed: issues.isEmpty,
        issues: issues,
        warnings: warnings,
      );
    } catch (e, stack) {
      AppLogger.error('备份诊断失败',
          error: e, stackTrace: stack, tag: 'BackupDiagnostics');
      return BackupDiagnosticResult(
        canProceed: false,
        issues: ['诊断过程出错: $e'],
        warnings: [],
      );
    }
  }

  /// 获取目录大小
  static Future<int> _getDirectorySize(Directory dir) async {
    int totalSize = 0;
    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (e) {
            // 忽略无法访问的文件
          }
        }
      }
    } catch (e) {
      AppLogger.warning('获取目录大小失败', error: e, tag: 'BackupDiagnostics');
    }
    return totalSize;
  }

  /// 获取可用存储空间
  static Future<int> _getAvailableSpace(String path) async {
    try {
      // Windows 平台检查
      if (Platform.isWindows) {
        final result =
            await Process.run('dir', [path, '/-c'], runInShell: true);
        if (result.exitCode == 0) {
          final output = result.stdout as String;
          final lines = output.split('\n');
          for (final line in lines) {
            if (line.contains('bytes free')) {
              final match =
                  RegExp(r'(\d{1,3}(?:,\d{3})*)\s+bytes free').firstMatch(line);
              if (match != null) {
                final freeSpaceStr = match.group(1)!.replaceAll(',', '');
                return int.tryParse(freeSpaceStr) ?? 0;
              }
            }
          }
        }
      }

      // 回退方案：假设有足够空间
      return 1024 * 1024 * 1024; // 假设1GB可用空间
    } catch (e) {
      AppLogger.warning('获取可用空间失败', error: e, tag: 'BackupDiagnostics');
      return 1024 * 1024 * 1024; // 假设1GB可用空间
    }
  }

  /// 查找大文件
  static Future<List<String>> _findLargeFiles(Directory dir) async {
    final largeFiles = <String>[];
    const largeFileThreshold = 50 * 1024 * 1024; // 50MB

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            if (size > largeFileThreshold) {
              largeFiles.add(
                  '${entity.path} (${(size / 1024 / 1024).toStringAsFixed(1)} MB)');
            }
          } catch (e) {
            // 忽略无法访问的文件
          }
        }
      }
    } catch (e) {
      AppLogger.warning('查找大文件失败', error: e, tag: 'BackupDiagnostics');
    }

    return largeFiles;
  }
}

/// 备份诊断结果
class BackupDiagnosticResult {
  final bool canProceed;
  final List<String> issues;
  final List<String> warnings;

  BackupDiagnosticResult({
    required this.canProceed,
    required this.issues,
    required this.warnings,
  });

  bool get hasIssues => issues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}
