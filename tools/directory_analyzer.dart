// ignore_for_file: avoid_print, curly_braces_in_flow_control_structures

import 'dart:io';
import 'package:path/path.dart' as p;

/// 简单的目录分析工具
class DirectoryAnalyzer {
  static Future<DirectoryInfo> analyze(String dirPath) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      return DirectoryInfo(
        path: dirPath,
        exists: false,
        totalFiles: 0,
        totalSize: 0,
        largeFiles: [],
        subdirectories: {},
      );
    }

    int fileCount = 0;
    int totalSize = 0;
    final largeFiles = <FileInfo>[];
    final subdirs = <String, DirectoryInfo>{};

    try {
      // 分析主目录
      await for (final entity in dir.list()) {
        if (entity is File) {
          fileCount++;
          final size = await entity.length();
          totalSize += size;

          // 记录大文件 (>10MB)
          if (size > 10 * 1024 * 1024) {
            largeFiles.add(FileInfo(
              path: entity.path,
              name: p.basename(entity.path),
              size: size,
            ));
          }
        } else if (entity is Directory) {
          final subdirName = p.basename(entity.path);
          // 递归分析子目录，但限制深度
          try {
            subdirs[subdirName] = await _analyzeSubdirectory(entity.path, 1);
          } catch (e) {
            print('无法分析子目录 $subdirName: $e');
            subdirs[subdirName] = DirectoryInfo(
              path: entity.path,
              exists: true,
              totalFiles: 0,
              totalSize: 0,
              largeFiles: [],
              subdirectories: {},
            );
          }
        }
      }
    } catch (e) {
      print('分析目录时出错 $dirPath: $e');
    }

    return DirectoryInfo(
      path: dirPath,
      exists: true,
      totalFiles: fileCount,
      totalSize: totalSize,
      largeFiles: largeFiles,
      subdirectories: subdirs,
    );
  }

  static Future<DirectoryInfo> _analyzeSubdirectory(
      String dirPath, int depth) async {
    if (depth > 2) return DirectoryInfo.empty(dirPath); // 限制递归深度

    final dir = Directory(dirPath);
    int fileCount = 0;
    int totalSize = 0;
    final largeFiles = <FileInfo>[];

    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          fileCount++;
          final size = await entity.length();
          totalSize += size;

          if (size > 10 * 1024 * 1024) {
            largeFiles.add(FileInfo(
              path: entity.path,
              name: p.basename(entity.path),
              size: size,
            ));
          }
        } else if (entity is Directory) {
          final subInfo = await _analyzeSubdirectory(entity.path, depth + 1);
          fileCount += subInfo.totalFiles;
          totalSize += subInfo.totalSize;
          largeFiles.addAll(subInfo.largeFiles);
        }
      }
    } catch (e) {
      print('分析子目录时出错 $dirPath: $e');
    }

    return DirectoryInfo(
      path: dirPath,
      exists: true,
      totalFiles: fileCount,
      totalSize: totalSize,
      largeFiles: largeFiles,
      subdirectories: {},
    );
  }

  static String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}

class DirectoryInfo {
  final String path;
  final bool exists;
  final int totalFiles;
  final int totalSize;
  final List<FileInfo> largeFiles;
  final Map<String, DirectoryInfo> subdirectories;

  DirectoryInfo({
    required this.path,
    required this.exists,
    required this.totalFiles,
    required this.totalSize,
    required this.largeFiles,
    required this.subdirectories,
  });

  factory DirectoryInfo.empty(String path) => DirectoryInfo(
        path: path,
        exists: false,
        totalFiles: 0,
        totalSize: 0,
        largeFiles: [],
        subdirectories: {},
      );

  void printSummary() {
    print('\n=== 目录分析: ${p.basename(path)} ===');
    if (!exists) {
      print('目录不存在');
      return;
    }

    print('总文件数: $totalFiles');
    print('总大小: ${DirectoryAnalyzer.formatSize(totalSize)}');

    if (largeFiles.isNotEmpty) {
      print('\n大文件 (>10MB):');
      for (final file in largeFiles) {
        print('  ${file.name}: ${DirectoryAnalyzer.formatSize(file.size)}');
      }
    }

    if (subdirectories.isNotEmpty) {
      print('\n子目录:');
      for (final entry in subdirectories.entries) {
        final subdir = entry.value;
        print(
            '  ${entry.key}: ${subdir.totalFiles} 文件, ${DirectoryAnalyzer.formatSize(subdir.totalSize)}');
      }
    }
  }
}

class FileInfo {
  final String path;
  final String name;
  final int size;

  FileInfo({
    required this.path,
    required this.name,
    required this.size,
  });
}
