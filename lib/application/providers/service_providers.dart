import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/cache/services/optimized_image_cache_service.dart';
import '../../infrastructure/image/image_processor.dart';
import '../../infrastructure/image/image_processor_impl.dart';
import '../../infrastructure/monitoring/performance_monitor.dart';
import '../../infrastructure/providers/cache_providers.dart' as cache;
import '../../infrastructure/providers/shared_preferences_provider.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../../infrastructure/services/character_image_service.dart';
import '../../infrastructure/services/character_image_service_impl.dart';
import '../../infrastructure/storage/library_storage.dart';
import '../../infrastructure/storage/library_storage_service.dart';
import '../../presentation/services/practice_list_refresh_service.dart';
import '../../presentation/widgets/practice/collection_element_renderer_optimized.dart';
import '../repositories/library_repository_impl.dart';
import '../services/character/character_service.dart';
import '../services/library_import_service.dart';
import '../services/library_service.dart';
import '../services/practice/practice_service.dart';
import '../services/restoration/state_restoration_service.dart';
import '../services/storage/character_storage_service.dart';
import '../services/storage/practice_storage_service.dart';
import '../services/storage/work_storage_service.dart';
import '../services/work/work_image_service.dart';
import '../services/work/work_service.dart';
import 'repository_providers.dart';

/// 集字图片服务提供者
final characterImageServiceProvider = Provider<CharacterImageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  final imageCacheService = ref.watch(cache.imageCacheServiceProvider);
  final imageProcessor = ref.watch(imageProcessorProvider);

  return CharacterImageServiceImpl(
    storage: storage,
    imageCacheService: imageCacheService,
    imageProcessor: imageProcessor,
  );
});

final characterStorageServiceProvider =
    Provider<CharacterStorageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return CharacterStorageService(storage);
});

/// Image Processor Provider
final imageProcessorProvider = Provider<ImageProcessor>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return ImageProcessorImpl(
      cachePath: path.join(storage.getAppDataPath(), 'cache'));
});

/// 图库导入服务提供者
final libraryImportServiceProvider = Provider<LibraryImportService>((ref) {
  final repository =
      ref.watch(libraryRepositoryProvider) as LibraryRepositoryImpl;
  final storageService = ref.watch(libraryStorageServiceProvider);
  return LibraryImportService(repository, storageService);
});

/// 图库服务提供者
final libraryServiceProvider = Provider<LibraryService>((ref) {
  return LibraryService(
    repository: ref.watch(libraryRepositoryProvider),
    imageCache: ref.watch(cache.imageCacheServiceProvider),
    storage: ref.watch(libraryStorageServiceProvider),
  );
});

/// 图库存储提供者
final libraryStorageProvider = Provider<LibraryStorage>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return LibraryStorage(storage);
});

/// 图库存储服务提供者
final libraryStorageServiceProvider = Provider<LibraryStorageService>((ref) {
  final storage = ref.watch(libraryStorageProvider);
  final imageCache = ref.watch(cache.imageCacheServiceProvider);
  return LibraryStorageService(storage: storage, imageCache: imageCache);
});

/// Practice Storage Service Provider
final practiceStorageServiceProvider = Provider<PracticeStorageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  debugPrint('正在创建 PracticeStorageService 实例...');
  final service = PracticeStorageService(storage: storage);
  debugPrint('PracticeStorageService 实例创建成功');
  return service;
});

/// Practice List Refresh Service Provider
final practiceListRefreshServiceProvider =
    Provider<PracticeListRefreshService>((ref) {
  return PracticeListRefreshService();
});

final practiceServiceProvider = Provider<PracticeService>((ref) {
  final repository = ref.watch(practiceRepositoryProvider);
  final storageService = ref.watch(practiceStorageServiceProvider);

  // 确保 storageService 已正确初始化
  debugPrint('正在创建 PracticeService 实例');

  return PracticeService(
    repository: repository,
    storageService: storageService,
  );
});

final stateRestorationServiceProvider = Provider<StateRestorationService>(
  (ref) => StateRestorationService(ref.watch(sharedPreferencesProvider)),
);

/// Work Image Service Provider
final workImageServiceProvider = Provider<WorkImageService>((ref) {
  return WorkImageService(
    storage: ref.watch(workStorageProvider),
    processor: ref.watch(imageProcessorProvider),
    repository: ref.watch(workImageRepositoryProvider),
  );
});

/// Work Service Provider
final workServiceProvider = Provider<WorkService>((ref) {
  return WorkService(
    repository: ref.watch(workRepositoryProvider),
    imageService: ref.watch(workImageServiceProvider),
    characterService: ref.watch(characterServiceProvider),
    workImageRepository: ref.watch(workImageRepositoryProvider),
    characterRepository: ref.watch(characterRepositoryProvider),
  );
});

/// Work Storage Service Provider
final workStorageProvider = Provider<WorkStorageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return WorkStorageService(storage: storage);
});

/// 🚀 性能监控器Provider
final performanceMonitorProvider = Provider<PerformanceMonitor>((ref) {
  return PerformanceMonitor();
});

/// 🚀 优化的图像缓存服务Provider
final optimizedImageCacheServiceProvider =
    Provider<OptimizedImageCacheService>((ref) {
  final performanceMonitor = ref.watch(performanceMonitorProvider);
  return OptimizedImageCacheService(performanceMonitor);
});

/// 🚀 优化的集字渲染器Provider
final optimizedCollectionRendererProvider =
    Provider<OptimizedCollectionElementRenderer>((ref) {
  final characterImageService = ref.watch(characterImageServiceProvider);
  final optimizedCache = ref.watch(optimizedImageCacheServiceProvider);

  return OptimizedCollectionElementRenderer(
    characterImageService,
    optimizedCache,
  );
});
