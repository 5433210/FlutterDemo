import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/image/image_processor.dart';
import '../../infrastructure/image/image_processor_impl.dart';
import '../../infrastructure/providers/cache_providers.dart' as cache;
import '../../infrastructure/providers/shared_preferences_provider.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../../infrastructure/services/character_image_service.dart';
import '../../infrastructure/services/character_image_service_impl.dart';
import '../../infrastructure/storage/library_storage.dart';
import '../../infrastructure/storage/library_storage_service.dart';
import '../repositories/library_repository_impl.dart';
import '../services/library_import_service.dart';
import '../services/library_service.dart';
import '../services/practice/practice_service.dart';
import '../services/restoration/state_restoration_service.dart';
import '../services/storage/character_storage_service.dart';
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
