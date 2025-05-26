import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../application/services/character/character_service.dart';
import '../../infrastructure/providers/storage_providers.dart';

/// 存储信息提供者
final storageInfoProvider = FutureProvider<StorageInfo>((ref) async {
  final storage = ref.watch(initializedStorageProvider);
  final workService = await ref.watch(workServiceProvider.future);
  final characterService = await ref.watch(characterServiceProvider.future);
  final libraryService = await ref.watch(libraryServiceProvider.future);

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
        // 特别处理缓存目录
        if (entity.path.contains('temp') || entity.path.contains('cache')) {
          cacheSize += await _calculateDirectorySize(entity.path);
          continue;
        }

        final size = await _calculateDirectorySize(entity.path);
        totalSize += size;

        subdirectories.add(DirectoryInfo(
          name: entity.path.split(Platform.pathSeparator).last,
          path: entity.path,
          size: size,
        ));
      } else if (entity is File) {
        totalSize += await entity.length();
        fileCount++;
      }
    }
  }

  // 获取目标存储空间（100GB）
  const targetSize = 100 * 1024 * 1024 * 1024;
  final usagePercentage = (totalSize / targetSize) * 100;
  return StorageInfo(
    path: basePath,
    totalSize: targetSize,
    usedSize: totalSize,
    usagePercentage: usagePercentage,
    workCount: workCount,
    characterCount: characterCount,
    libraryCount: libraryCount,
    fileCount: fileCount,
    cacheSize: cacheSize,
    subdirectories: subdirectories,
    workSize: 0, // You may want to calculate this value appropriately
    characterSize: 0, // You may want to calculate this value appropriately
    librarySize: 0, // You may want to calculate this value appropriately
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
  });
}
