import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/cache/character_image_cache_service.dart';
import '../../infrastructure/image/image_processor.dart';
import '../../infrastructure/image/image_processor_impl.dart';
import '../../infrastructure/providers/shared_preferences_provider.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../../infrastructure/services/character_image_service.dart';
import '../services/practice/practice_service.dart';
import '../services/restoration/state_restoration_service.dart';
import '../services/storage/cache_manager.dart';
import '../services/storage/character_storage_service.dart';
import '../services/storage/work_storage_service.dart';
import '../services/work/work_image_service.dart';
import '../services/work/work_service.dart';
import 'repository_providers.dart';

final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager();
});

/// 集字图片缓存服务提供者
final characterImageCacheServiceProvider =
    Provider<CharacterImageCacheService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return CharacterImageCacheService(storage: storage);
});

/// 集字图片服务提供者
final characterImageServiceProvider = Provider<CharacterImageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  final cacheService = ref.watch(characterImageCacheServiceProvider);
  final imageProcessor = ref.watch(imageProcessorProvider);

  return CharacterImageService(
    storage: storage,
    cacheService: cacheService,
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

final practiceServiceProvider = Provider<PracticeService>((ref) {
  // 使用仓库层版本的构造函数
  return PracticeService(
    repository: ref.watch(practiceRepositoryProvider),
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
    storage: ref.watch(initializedStorageProvider),
    workImageRepository: ref.watch(workImageRepositoryProvider),
  );
});

/// Work Storage Service Provider
final workStorageProvider = Provider<WorkStorageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return WorkStorageService(storage: storage);
});
