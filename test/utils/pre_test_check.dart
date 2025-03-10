import 'dart:io';

/// 备份状态
class BackupStatus {
  final DateTime? lastBackup;
  final bool needsBackup;
  final String message;

  BackupStatus({
    this.lastBackup,
    required this.needsBackup,
    required this.message,
  });

  @override
  String toString() => message;
}

/// 磁盘空间状态
class DiskSpaceStatus {
  final int available;
  final int required;
  final bool sufficient;

  DiskSpaceStatus({
    required this.available,
    required this.required,
    required this.sufficient,
  });

  @override
  String toString() =>
      '可用: ${available}MB, 需要: ${required}MB, ${sufficient ? "充足" : "不足"}';
}

/// 预测试检查工具
class PreTestCheck {
  /// 所需的磁盘空间（MB）
  static const requiredDiskSpaceMB = 2048; // 2GB

  /// 建议的备份间隔（小时）
  static const backupIntervalHours = 24;

  /// 运行预检查
  static Future<PreTestCheckResult> runPreCheck() async {
    final result = PreTestCheckResult();

    try {
      // 1. 检查环境变量
      result.envVars = _checkEnvironmentVariables();

      // 2. 检查磁盘空间
      result.diskSpace = await _checkDiskSpace();

      // 3. 检查上次备份时间
      result.backupStatus = await _checkBackupStatus();

      // 4. 检查必要目录
      result.directories = await _checkDirectories();
    } catch (e, stack) {
      result.error = '$e\n$stack';
    }

    return result;
  }

  /// 检查备份状态
  static Future<BackupStatus> _checkBackupStatus() async {
    final backupDir = Directory('test/backup');
    if (!backupDir.existsSync()) {
      return BackupStatus(
        lastBackup: null,
        needsBackup: true,
        message: '未找到备份目录',
      );
    }

    final files = backupDir.listSync().whereType<File>().toList();

    if (files.isEmpty) {
      return BackupStatus(
        lastBackup: null,
        needsBackup: true,
        message: '未找到备份文件',
      );
    }

    final lastBackup = files
        .map((f) => f.lastModifiedSync())
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final hoursSinceLastBackup = DateTime.now().difference(lastBackup).inHours;

    return BackupStatus(
      lastBackup: lastBackup,
      needsBackup: hoursSinceLastBackup >= backupIntervalHours,
      message: '上次备份: ${lastBackup.toLocal()}',
    );
  }

  /// 检查必要目录
  static Future<Map<String, bool>> _checkDirectories() async {
    final dirs = {
      'test/data': false,
      'test/logs': false,
      'test/reports': false,
      'test/backup': false,
    };

    for (final dir in dirs.keys) {
      final directory = Directory(dir);
      try {
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }
        // 测试写入权限
        final testFile = File('$dir/write_test');
        await testFile.writeAsString('test');
        await testFile.delete();
        dirs[dir] = true;
      } catch (e) {
        print('目录检查失败 $dir: $e');
        dirs[dir] = false;
      }
    }

    return dirs;
  }

  /// 检查磁盘空间
  static Future<DiskSpaceStatus> _checkDiskSpace() async {
    final dir = Directory('test');
    if (Platform.isWindows) {
      final result = await Process.run('cmd', ['/c', 'dir', dir.path]);
      final lines = result.stdout.toString().split('\n');
      for (final line in lines) {
        if (line.contains('bytes free')) {
          final parts = line.trim().split(' ');
          final bytes = int.tryParse(parts[0].replaceAll(',', ''));
          if (bytes != null) {
            final mbFree = bytes ~/ (1024 * 1024);
            return DiskSpaceStatus(
              available: mbFree,
              required: requiredDiskSpaceMB,
              sufficient: mbFree >= requiredDiskSpaceMB,
            );
          }
        }
      }
    } else {
      final result = await Process.run('df', ['-m', dir.path]);
      final lines = result.stdout.toString().split('\n');
      if (lines.length > 1) {
        final parts = lines[1].split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final mbFree = int.tryParse(parts[3]) ?? 0;
          return DiskSpaceStatus(
            available: mbFree,
            required: requiredDiskSpaceMB,
            sufficient: mbFree >= requiredDiskSpaceMB,
          );
        }
      }
    }
    throw '无法获取磁盘空间信息';
  }

  /// 检查环境变量
  static Map<String, bool> _checkEnvironmentVariables() {
    return {
      'TEST_LOG_LEVEL': Platform.environment.containsKey('TEST_LOG_LEVEL'),
      'TEST_DATA_PATH': Platform.environment.containsKey('TEST_DATA_PATH'),
      'CI': Platform.environment.containsKey('CI'),
    };
  }
}

/// 预检查结果
class PreTestCheckResult {
  Map<String, bool> envVars = {};
  DiskSpaceStatus? diskSpace;
  BackupStatus? backupStatus;
  Map<String, bool> directories = {};
  String? error;

  bool get passed =>
      error == null &&
      diskSpace?.sufficient == true &&
      directories.values.every((v) => v);

  @override
  String toString() {
    final buffer = StringBuffer('预测试检查结果:\n');

    if (error != null) {
      buffer.writeln('错误: $error');
      return buffer.toString();
    }

    buffer.writeln('1. 环境变量:');
    envVars.forEach((k, v) => buffer.writeln('   - $k: ${v ? "已设置" : "未设置"}'));

    buffer.writeln('\n2. 磁盘空间:');
    buffer.writeln('   ${diskSpace.toString()}');

    buffer.writeln('\n3. 备份状态:');
    buffer.writeln('   ${backupStatus?.toString()}');

    buffer.writeln('\n4. 目录检查:');
    directories
        .forEach((k, v) => buffer.writeln('   - $k: ${v ? "可用" : "不可用"}'));

    buffer.writeln('\n总体状态: ${passed ? "通过" : "未通过"}');

    return buffer.toString();
  }
}
