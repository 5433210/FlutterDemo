import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  print('=== 备份卡顿诊断工具 ===\n');

  try {
    // 获取默认数据路径（和应用一样的逻辑）
    final appSupportDir = await getApplicationSupportDirectory();
    final defaultDataPath = path.join(appSupportDir.path, 'charasgem');
    final storagePath = path.join(defaultDataPath, 'storage');

    print('默认数据路径: $defaultDataPath');
    print('存储路径: $storagePath');
    print('');

    // 检查存储路径是否存在
    final storageDir = Directory(storagePath);
    if (!await storageDir.exists()) {
      print('❌ 存储目录不存在: $storagePath');
      return;
    }

    print('✅ 找到存储目录，开始分析...\n');

    // 分析各个子目录
    final subDirs = [
      'characters',
      'database',
      'practices',
      'library',
      'cache',
      'temp',
      'backups'
    ];

    int totalFiles = 0;
    int totalSize = 0;
    List<Map<String, dynamic>> largeItems = [];

    for (final subDir in subDirs) {
      final dirPath = path.join(storagePath, subDir);
      final dir = Directory(dirPath);

      if (await dir.exists()) {
        print('📁 分析目录: $subDir');

        int dirFiles = 0;
        int dirSize = 0;

        try {
          await for (final entity in dir.list(recursive: true)) {
            if (entity is File) {
              dirFiles++;
              totalFiles++;

              try {
                final stat = await entity.stat();
                dirSize += stat.size;
                totalSize += stat.size;

                // 记录大文件 (>5MB)
                if (stat.size > 5 * 1024 * 1024) {
                  largeItems.add({
                    'path': entity.path,
                    'size': stat.size,
                    'sizeMB': (stat.size / (1024 * 1024)).toStringAsFixed(2),
                    'dir': subDir
                  });
                }
              } catch (e) {
                print('  ⚠️ 无法访问文件: ${entity.path} ($e)');
              }
            }
          }

          print('  - 文件数: $dirFiles');
          print('  - 大小: ${(dirSize / (1024 * 1024)).toStringAsFixed(2)} MB');
          if (dirFiles > 1000) {
            print('  🚨 文件数量过多，可能导致备份缓慢');
          }
          if (dirSize > 50 * 1024 * 1024) {
            print('  🚨 目录过大，可能导致备份缓慢');
          }
        } catch (e) {
          print('  ❌ 扫描失败: $e');
        }
        print('');
      } else {
        print('📂 $subDir: 不存在');
      }
    }

    print('=== 总结 ===');
    print('总文件数: $totalFiles');
    print('总大小: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB');

    // 预估备份时间
    final estimatedMinutes = _estimateBackupTime(totalFiles, totalSize);
    print('预估备份时间: ${estimatedMinutes.toStringAsFixed(1)} 分钟');

    if (estimatedMinutes > 2.0) {
      print('\n🚨 可能的卡顿原因:');
      if (totalFiles > 5000) {
        print('- 文件数量过多 ($totalFiles 个)');
      }
      if (totalSize > 100 * 1024 * 1024) {
        print('- 数据量过大 (${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB)');
      }
      if (largeItems.length > 3) {
        print('- 大文件过多 (${largeItems.length} 个 >5MB)');
      }
    }

    if (largeItems.isNotEmpty) {
      print('\n📊 大文件列表 (>5MB):');
      largeItems.sort((a, b) => b['size'].compareTo(a['size']));
      for (int i = 0; i < largeItems.length && i < 10; i++) {
        final item = largeItems[i];
        print(
            '  ${item['sizeMB']} MB - ${item['dir']} - ${path.basename(item['path'])}');
      }
    }
  } catch (e, stack) {
    print('❌ 诊断失败: $e');
    print('Stack trace: $stack');
  }
}

double _estimateBackupTime(int fileCount, int totalSize) {
  // 保守估算:
  // - 每分钟处理 500 个小文件
  // - 每秒处理 5MB 数据
  // - 压缩开销 20%

  final fileProcessingTime = fileCount / 500.0; // 分钟
  final dataProcessingTime = (totalSize / (5 * 1024 * 1024)) / 60.0; // 分钟
  final compressionOverhead = (fileProcessingTime + dataProcessingTime) * 0.2;

  return fileProcessingTime + dataProcessingTime + compressionOverhead;
}
