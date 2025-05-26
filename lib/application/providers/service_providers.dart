import 'package:flutter/foundation.dart';
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
final libraryServiceProvider = FutureProvider<LibraryService>((ref) async {
  final repository = await ref.watch(libraryRepositoryProvider.future);
  return LibraryService(
    repository: repository,
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

final practiceServiceProvider = FutureProvider<PracticeService>((ref) async {
  final repository = await ref.watch(practiceRepositoryProvider.future);
  final storageService = ref.watch(practiceStorageServiceProvider);

  // 确保 storageService 已正确初始化
  debugPrint('正在创建 PracticeService 实例');

  return PracticeService(
    repository: repository,
    storageService: storageService,
  );
});

/// Practice Storage Service Provider
final practiceStorageServiceProvider = Provider<PracticeStorageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  debugPrint('正在创建 PracticeStorageService 实例...');
  final service = PracticeStorageService(storage: storage);
  debugPrint('PracticeStorageService 实例创建成功');
  return service;
});

final stateRestorationServiceProvider = Provider<StateRestorationService>(
  (ref) => StateRestorationService(ref.watch(sharedPreferencesProvider)),
);

/// Work Image Service Provider
final workImageServiceProvider = FutureProvider<WorkImageService>((ref) async {
  final repository = await ref.watch(workImageRepositoryProvider.future);
  return WorkImageService(
    storage: ref.watch(workStorageProvider),
    processor: ref.watch(imageProcessorProvider),
    repository: repository,
  );
});

/// Work Service Provider
final workServiceProvider = FutureProvider<WorkService>((ref) async {
  final repository = await ref.watch(workRepositoryProvider.future);
  final imageService = await ref.watch(workImageServiceProvider.future);
  final workImageRepository =
      await ref.watch(workImageRepositoryProvider.future);
  final characterRepository =
      await ref.watch(characterRepositoryProvider.future);

  return WorkService(
    repository: repository,
    imageService: imageService,
    storage: ref.watch(initializedStorageProvider),
    workImageRepository: workImageRepository,
    characterRepository: characterRepository,
  );
});

/// Work Storage Service Provider
final workStorageProvider = Provider<WorkStorageService>((ref) {
  final storage = ref.watch(initializedStorageProvider);
  return WorkStorageService(storage: storage);
});
