import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

import '../cache/config/cache_config.dart';
import '../cache/implementations/disk_cache.dart';
import '../cache/implementations/memory_cache.dart';
import '../cache/implementations/tiered_cache.dart';
import '../cache/interfaces/i_cache.dart';
import '../cache/services/cache_manager.dart';
import '../cache/services/image_cache_service.dart';
import 'shared_preferences_provider.dart';
import 'storage_providers.dart';

/// 缓存配置提供者
final cacheConfigProvider = Provider<CacheConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  
  // 从SharedPreferences加载配置
  // 如果没有保存的配置，使用默认值
  final jsonString = prefs.getString('cache_config');
  if (jsonString != null) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CacheConfig.fromJson(json);
    } catch (e) {
      // 解析失败，使用默认配置
    }
  }
  
  return const CacheConfig();
});

/// 内存图像缓存提供者
final memoryImageCacheProvider = Provider<ICache<String, Uint8List>>((ref) {
  final config = ref.watch(cacheConfigProvider);
  return MemoryCache<String, Uint8List>(capacity: config.memoryImageCacheCapacity);
});

/// 内存UI图像缓存提供者
final memoryUiImageCacheProvider = Provider<ICache<String, ui.Image>>((ref) {
  final config = ref.watch(cacheConfigProvider);
  return MemoryCache<String, ui.Image>(capacity: config.memoryImageCacheCapacity);
});

/// 磁盘图像缓存提供者
final diskImageCacheProvider = Provider<ICache<String, Uint8List>>((ref) {
  final config = ref.watch(cacheConfigProvider);
  final storage = ref.watch(initializedStorageProvider);
  
  return DiskCache<String, Uint8List>(
    cachePath: path.join(storage.getAppDataPath(), 'cache', 'images'),
    maxSize: config.maxDiskCacheSize,
    maxAge: config.diskCacheTtl,
    encoder: (data) async => data,
    decoder: (data) async => Uint8List.fromList(data),
    keyHasher: (key) => md5.convert(utf8.encode(key)).toString(),
  );
});

/// 多级图像缓存提供者
final tieredImageCacheProvider = Provider<ICache<String, Uint8List>>((ref) {
  final memoryCache = ref.watch(memoryImageCacheProvider);
  final diskCache = ref.watch(diskImageCacheProvider);
  
  return TieredCache<String, Uint8List>(
    primaryCache: memoryCache,
    secondaryCache: diskCache,
  );
});

/// 图像缓存服务提供者
final imageCacheServiceProvider = Provider<ImageCacheService>((ref) {
  final binaryCache = ref.watch(tieredImageCacheProvider);
  final uiImageCache = ref.watch(memoryUiImageCacheProvider);
  
  return ImageCacheService(
    binaryCache: binaryCache,
    uiImageCache: uiImageCache,
  );
});

/// 全局缓存管理器提供者
final cacheManagerProvider = Provider<CacheManager>((ref) {
  final manager = CacheManager();
  final config = ref.watch(cacheConfigProvider);
  
  // 注册所有缓存
  manager.registerCache(ref.read(memoryImageCacheProvider));
  manager.registerCache(ref.read(diskImageCacheProvider));
  manager.registerCache(ref.read(memoryUiImageCacheProvider));
  
  // 启动内存监控
  if (config.autoCleanupEnabled) {
    manager.startMemoryMonitoring(interval: config.autoCleanupInterval);
  }
  
  // 当提供者被销毁时，释放资源
  ref.onDispose(() {
    manager.dispose();
  });
  
  return manager;
});
