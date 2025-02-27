import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../../utils/path_helper.dart';

/// Provider for storage information
final storageInfoProvider =
    StateNotifierProvider<StorageInfoNotifier, StorageInfo>((ref) {
  return StorageInfoNotifier(ref);
});

/// Storage information model
class StorageInfo {
  final int totalSize;
  final int cacheSize;
  final int workCount;
  final int characterCount;
  final int practiceCount;
  final int fileCount;

  const StorageInfo({
    this.totalSize = 0,
    this.cacheSize = 0,
    this.workCount = 0,
    this.characterCount = 0,
    this.practiceCount = 0,
    this.fileCount = 0,
  });
}

class StorageInfoNotifier extends StateNotifier<StorageInfo> {
  final Ref ref;

  StorageInfoNotifier(this.ref) : super(const StorageInfo()) {
    refresh();
  }

  Future<void> clearCache() async {
    try {
      final appDataPath = await PathHelper.getAppDataPath();
      final cacheDir = Directory(path.join(appDataPath, 'cache'));

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }

      await refresh();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to clear cache',
        tag: 'StorageInfoNotifier',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      // Get work, character, and practice counts from repositories
      final workCount = await ref.read(workRepositoryProvider).getWorksCount();
      final characterCount = 0;
      final practiceCount =
          0; // await ref.read(practiceRepositoryProvider).getPracticesCount();

      // Calculate storage sizes
      final appDataPath = await PathHelper.getAppDataPath();
      final appDataDir = Directory(appDataPath);

      int totalSize = 0;
      int cacheSize = 0;
      int fileCount = 0;

      if (await appDataDir.exists()) {
        // Get all files and calculate sizes
        await for (final entity in appDataDir.list(recursive: true)) {
          if (entity is File) {
            final fileSize = await entity.length();
            totalSize += fileSize;
            fileCount++;

            // Check if this is a cache file
            if (path.basename(entity.path).contains('cache') ||
                path.dirname(entity.path).contains('cache')) {
              cacheSize += fileSize;
            }
          }
        }
      }

      // Update state
      state = StorageInfo(
        totalSize: totalSize,
        cacheSize: cacheSize,
        workCount: workCount,
        characterCount: characterCount,
        practiceCount: practiceCount,
        fileCount: fileCount,
      );
    } catch (e, stack) {
      AppLogger.error(
        'Failed to refresh storage info',
        tag: 'StorageInfoNotifier',
        error: e,
        stackTrace: stack,
      );
    }
  }
}
