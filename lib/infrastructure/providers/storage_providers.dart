import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../application/providers/unified_path_provider.dart' as unified;
import '../../application/services/storage/library_storage.dart';
import '../../application/services/storage/library_storage_interface.dart';
import '../../application/services/storage/library_storage_service.dart';
import '../../infrastructure/cache/interfaces/i_cache.dart';
import '../../infrastructure/cache/services/image_cache.dart';
import '../../infrastructure/cache/services/image_cache_service.dart';
import '../../infrastructure/cache/services/ui_image_cache.dart';
import '../../infrastructure/storage/storage_interface.dart';
import '../logging/logger.dart';
import '../storage/local_storage.dart';

/// 图像缓存提供者
final imageCacheProvider = Provider<ICache<String, Uint8List>>((ref) {
  return ImageCache();
});

/// 图像缓存服务提供者
final imageCacheServiceProvider = Provider<ImageCacheService>((ref) {
  final binaryCache = ref.watch(imageCacheProvider);
  return ImageCacheService(
    binaryCache: binaryCache,
    uiImageCache: ref.watch(uiImageCacheProvider),
  );
});

/// 获取已初始化的存储实例
final initializedStorageProvider = Provider<IStorage>((ref) {
  final storageState = ref.watch(storageProvider);
  return storageState.when(
    data: (storage) => storage,
    loading: () => throw StateError('Storage service not initialized'),
    error: (err, stack) =>
        throw StateError('Storage initialization failed: $err'),
  );
});

/// 图库存储服务提供者
final libraryStorageProvider = Provider<ILibraryStorage>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return LibraryStorage(storage);
});

/// 图库存储服务提供者
final libraryStorageServiceProvider = Provider<LibraryStorageService>((ref) {
  return LibraryStorageService(
    storage: ref.watch(libraryStorageProvider),
    imageCache: ref.watch(imageCacheServiceProvider),
  );
});

/// 存储服务 Provider
/// 提供应用的存储服务实例，负责初始化和管理存储资源
final storageProvider = FutureProvider<IStorage>((ref) async {
  AppLogger.debug('初始化存储服务', tag: 'Storage');

  try {
    // 1. 获取实际数据路径（考虑用户自定义路径）
    final actualDataPath =
        await ref.watch(unified.actualDataPathProvider.future);
    final storagePath = path.join(actualDataPath, 'storage');

    // 2. 创建存储服务实例
    final storage = LocalStorage(basePath: storagePath);

    // 3. 初始化目录结构
    await _initializeStorageStructure(storage);

    AppLogger.info('存储服务初始化完成，数据路径: $storagePath', tag: 'Storage');
    return storage;
  } catch (e, stack) {
    AppLogger.error('存储服务初始化失败', error: e, stackTrace: stack, tag: 'Storage');
    rethrow;
  }
});

/// UI图像缓存提供者
final uiImageCacheProvider = Provider<ICache<String, ui.Image>>((ref) {
  return UIImageCache();
});

/// 创建存储服务所需的基础目录结构
Future<void> _initializeStorageStructure(IStorage storage) async {
  final appDataDir = storage.getAppDataPath();
  final tempDir = await storage.createTempDirectory();

  // 创建所需的目录结构
  await Future.wait([
    storage.ensureDirectoryExists(appDataDir),
    storage.ensureDirectoryExists(path.join(appDataDir, 'works')),
    storage.ensureDirectoryExists(path.join(appDataDir, 'cache')),
    storage.ensureDirectoryExists(path.join(appDataDir, 'config')),
    storage.ensureDirectoryExists(path.join(appDataDir, 'temp')),
    storage.ensureDirectoryExists(tempDir.path),
    // 添加图库目录
    storage.ensureDirectoryExists(path.join(appDataDir, 'library')),
  ]);

  AppLogger.debug('存储目录结构创建完成', tag: 'Storage');
}
