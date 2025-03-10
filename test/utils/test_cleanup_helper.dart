import 'dart:io';

import 'package:path/path.dart' as path;

/// 测试清理助手
class TestCleanupHelper {
  /// 归档旧的测试文件
  static Future<void> archiveOldTestFiles() async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final archiveDir = Directory('test/archive/$timestamp');

    if (!archiveDir.existsSync()) {
      archiveDir.createSync(recursive: true);
    }

    final dirs = [
      'test/reports',
      'test/logs',
    ];

    for (final dir in dirs) {
      final sourceDir = Directory(dir);
      if (!sourceDir.existsSync()) continue;

      final files = sourceDir.listSync().whereType<File>().where((f) => f
          .lastModifiedSync()
          .isBefore(DateTime.now().subtract(const Duration(days: 30))));

      for (final file in files) {
        final newPath = path.join(
          archiveDir.path,
          path.basename(dir),
          path.basename(file.path),
        );

        try {
          final targetDir = Directory(path.dirname(newPath));
          if (!targetDir.existsSync()) {
            targetDir.createSync(recursive: true);
          }

          file.copySync(newPath);
          file.deleteSync();
          print('已归档: ${file.path} -> $newPath');
        } catch (e) {
          print('归档失败: ${file.path}, 错误: $e');
        }
      }
    }
  }

  /// 清理旧的测试报告和日志
  static Future<void> cleanOldReports({
    int maxAgeDays = 7,
    int keepLastN = 5,
  }) async {
    final dirs = [
      Directory('test/reports'),
      Directory('test/logs'),
    ];

    for (final dir in dirs) {
      if (!dir.existsSync()) continue;

      final files = dir.listSync().whereType<File>().toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // 保留最新的N个文件
      final filesToKeep = files.take(keepLastN).toSet();

      // 删除超过指定天数的旧文件
      final now = DateTime.now();
      for (final file in files) {
        if (filesToKeep.contains(file)) continue;

        final fileAge = now.difference(file.lastModifiedSync());
        if (fileAge.inDays > maxAgeDays) {
          try {
            file.deleteSync();
            print('已删除旧文件: ${file.path}');
          } catch (e) {
            print('删除文件失败: ${file.path}, 错误: $e');
          }
        }
      }
    }
  }

  /// 清理测试缓存
  static Future<void> cleanTestCache() async {
    final cacheDir = Directory('.dart_tool/test');
    if (cacheDir.existsSync()) {
      try {
        cacheDir.deleteSync(recursive: true);
        print('已清理测试缓存');
      } catch (e) {
        print('清理测试缓存失败: $e');
      }
    }
  }

  /// 重置测试环境
  static Future<void> resetTestEnvironment() async {
    // 清理旧报告
    await cleanOldReports();

    // 清理缓存
    await cleanTestCache();

    // 创建必要的目录
    final dirs = [
      'test/reports',
      'test/logs',
      'test/data',
      'test/backup',
    ];

    for (final dir in dirs) {
      final directory = Directory(dir);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
        print('已创建目录: $dir');
      }
    }
  }
}
