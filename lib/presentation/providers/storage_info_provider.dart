import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/character/character_service.dart';
import '../../infrastructure/providers/storage_providers.dart';

/// 存储信息提供者
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final storage = ref.watch(initializedStorageProvider);
  final workService = ref.watch(workServiceProvider);
  final characterService = ref.watch(characterServiceProvider);
  final libraryService = ref.watch(libraryServiceProvider);

  // 获取应用数据目录
  final basePath = storage.getAppDataPath();
  final baseDir = Directory(basePath);

  // 获取作品数量
  final works = await workService.getAllWorks();
  final workCount = works.length;

  // 获取集字数量
  final characters = await characterService.getAllCharacters();
  final characterCount = characters.length;

  // 获取图库数量
  final libraryResult = await libraryService.getItems(pageSize: 1000);
  final libraryCount = libraryResult.totalCount;

  // 计算存储使用情况
  int totalSize = 0;
  int fileCount = 0;
  int cacheSize = 0;
  final subdirectories = <DirectoryInfo>[];

  if (await baseDir.exists()) {
    await for (final entity in baseDir.list()) {
      if (entity is Directory) {
        final size = await _calculateDirectorySize(entity.path);
        
        // 特别处理缓存目录
        if (entity.path.contains('temp') || entity.path.contains('cache')) {
          cacheSize += size;
        } else {
          subdirectories.add(DirectoryInfo(
            name: entity.path.split(Platform.pathSeparator).last,
            path: entity.path,
            size: size,
          ));
        }
        
        // 将所有目录大小都计入总大小
        totalSize += size;
      } else if (entity is File) {
        totalSize += await entity.length();
        fileCount++;
      }
    }
  }

  // 获取分区总空间（当前分区可用空间）
  int totalDiskSpace = 0;
  try {
    // 在实际应用中，应使用平台特定的API获取磁盘空间信息
    // 这里使用一个合理的估算值
    totalDiskSpace = totalSize * 10; // 假设总空间是使用空间的10倍
  } catch (e) {
    // 如果无法获取磁盘信息，使用合理的默认值
    totalDiskSpace = totalSize * 10;
  }

  final usagePercentage =
      totalDiskSpace > 0 ? (totalSize / totalDiskSpace) * 100 : 0.0;

  // 计算数据库大小
  final databaseSize =
      await _calculateSpecificDirectorySize(basePath, 'database');

  // 计算备份信息
  final backupSize = await _calculateSpecificDirectorySize(basePath, 'backups');
  int backupCount = 0;
  try {
    final backupDir = Directory('$basePath${Platform.pathSeparator}backups');
    if (await backupDir.exists()) {
      await for (final entity in backupDir.list()) {
        if (entity is File && entity.path.endsWith('.backup')) {
          backupCount++;
        }
      }
    }
  } catch (e) {
    // 忽略错误
  }

  return StorageInfo(
    path: basePath,
    totalSize: totalSize, // 使用实际应用数据总大小
    usedSize: totalSize,  // 保持一致
    usagePercentage: usagePercentage,
    workCount: workCount,
    characterCount: characterCount,
    libraryCount: libraryCount,
    fileCount: fileCount,
    cacheSize: cacheSize,
    subdirectories: subdirectories,
    workSize: await _calculateSpecificDirectorySize(basePath, 'works'),
    characterSize:
        await _calculateSpecificDirectorySize(basePath, 'characters'),
    librarySize: await _calculateSpecificDirectorySize(basePath, 'library'),
    databaseSize: databaseSize,
    backupCount: backupCount,
    backupSize: backupSize,
  );
});

Future<int> _calculateDirectorySize(String dirPath) async {
  int size = 0;
  final dir = Directory(dirPath);

  try {
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    }
  } catch (e) {
    // 忽略权限等错误
  }

  return size;
}

/// 计算特定子目录的大小
Future<int> _calculateSpecificDirectorySize(
    String basePath, String subDir) async {
  final fullPath = '$basePath${Platform.pathSeparator}$subDir';
  return await _calculateDirectorySize(fullPath);
}

class DirectoryInfo {
  final String name;
  final String path;
  final int size;

  DirectoryInfo({
    required this.name,
    required this.path,
    required this.size,
  });
}

class StorageInfo {
  final String path;
  final int totalSize;
  final int usedSize;
  final double usagePercentage;
  final int workCount;
  final int characterCount;
  final int libraryCount;
  final int fileCount;
  final int cacheSize;
  final int workSize;
  final int characterSize;
  final int librarySize;
  final int databaseSize;
  final int backupCount;
  final int backupSize;
  final List<DirectoryInfo> subdirectories;

  StorageInfo({
    required this.path,
    required this.totalSize,
    required this.usedSize,
    required this.usagePercentage,
    required this.workCount,
    required this.characterCount,
    required this.libraryCount,
    required this.fileCount,
    required this.cacheSize,
    required this.subdirectories,
    required this.characterSize,
    required this.librarySize,
    required this.workSize,
    required this.databaseSize,
    required this.backupCount,
    required this.backupSize,
  });
}
