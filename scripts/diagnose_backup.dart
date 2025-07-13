import 'dart:io';

import 'package:path/path.dart' as path;

class DirectoryAnalyzer {
  static Future<Map<String, dynamic>> analyzeDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return {
        'exists': false,
        'path': dirPath,
        'error': 'Directory does not exist'
      };
    }

    int fileCount = 0;
    int dirCount = 0;
    int totalSize = 0;
    List<Map<String, dynamic>> largeFiles = [];
    List<String> problematicFiles = [];

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          fileCount++;
          try {
            final stat = await entity.stat();
            totalSize += stat.size;

            // Track large files (>10MB)
            if (stat.size > 10 * 1024 * 1024) {
              largeFiles.add({
                'path': entity.path,
                'size': stat.size,
                'sizeMB': (stat.size / (1024 * 1024)).toStringAsFixed(2)
              });
            }
          } catch (e) {
            problematicFiles.add('${entity.path}: $e');
          }
        } else if (entity is Directory) {
          dirCount++;
        }
      }
    } catch (e) {
      return {
        'exists': true,
        'path': dirPath,
        'error': 'Error scanning directory: $e'
      };
    }

    return {
      'exists': true,
      'path': dirPath,
      'fileCount': fileCount,
      'directoryCount': dirCount,
      'totalSizeBytes': totalSize,
      'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      'largeFiles': largeFiles,
      'problematicFiles': problematicFiles,
      'estimatedBackupTimeMinutes': _estimateBackupTime(fileCount, totalSize),
    };
  }

  static double _estimateBackupTime(int fileCount, int totalSize) {
    // Conservative estimates:
    // - 1000 files per minute for small files
    // - 10MB per second for large files
    // - Additional overhead for ZIP compression

    final fileProcessingTime = fileCount / 1000.0; // minutes
    final dataProcessingTime =
        (totalSize / (10 * 1024 * 1024)) / 60.0; // minutes
    final compressionOverhead =
        (totalSize / (100 * 1024 * 1024)) * 0.5; // minutes

    return fileProcessingTime + dataProcessingTime + compressionOverhead;
  }
}

Future<void> main() async {
  print('=== 备份诊断工具 ===\n');

  // 分析可能的数据路径
  final possiblePaths = [
    r'C:\Users\wailik\AppData\Roaming\charasgem',
    r'C:\Users\wailik\AppData\Local\charasgem',
    r'C:\Users\wailik\Documents\charasgem',
    r'C:\Users\wailik\Documents\charasgem_data',
    path.join(Directory.current.path, 'data'),
    path.join(Directory.current.path, 'user_data'),
    path.join(Directory.current.path, 'storage'),
  ];

  for (final dataPath in possiblePaths) {
    print('检查路径: $dataPath');
    final analysis = await DirectoryAnalyzer.analyzeDirectory(dataPath);

    if (analysis['exists'] == true && analysis['error'] == null) {
      print('✅ 找到数据目录!');
      print('  文件数量: ${analysis['fileCount']}');
      print('  目录数量: ${analysis['directoryCount']}');
      print('  总大小: ${analysis['totalSizeMB']} MB');
      print(
          '  预估备份时间: ${analysis['estimatedBackupTimeMinutes'].toStringAsFixed(1)} 分钟');

      if (analysis['largeFiles'].isNotEmpty) {
        print('  🔍 大文件 (>10MB):');
        for (final file in analysis['largeFiles']) {
          print('    - ${file['sizeMB']} MB: ${file['path']}');
        }
      }

      if (analysis['problematicFiles'].isNotEmpty) {
        print('  ⚠️ 问题文件:');
        for (final file in analysis['problematicFiles']) {
          print('    - $file');
        }
      }

      print('');

      // 如果预估时间超过2分钟，提供优化建议
      if (analysis['estimatedBackupTimeMinutes'] > 2.0) {
        print('🚨 备份时间可能较长的原因:');
        if (analysis['fileCount'] > 5000) {
          print('  - 文件数量过多 (${analysis['fileCount']} 个文件)');
        }
        if (analysis['totalSizeBytes'] > 100 * 1024 * 1024) {
          print('  - 数据量过大 (${analysis['totalSizeMB']} MB)');
        }
        if (analysis['largeFiles'].length > 5) {
          print('  - 大文件过多 (${analysis['largeFiles'].length} 个 >10MB)');
        }
        print('');
      }
    } else if (analysis['exists'] == true) {
      print('❌ 扫描失败: ${analysis['error']}');
    } else {
      print('📁 不存在');
    }
    print('');
  }

  print('=== 诊断完成 ===');
}
