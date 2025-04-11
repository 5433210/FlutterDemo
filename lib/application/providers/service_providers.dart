import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/image/image_processor.dart';
import '../../infrastructure/image/image_processor_impl.dart';
import '../../infrastructure/providers/shared_preferences_provider.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../services/character/character_persistence_service.dart';
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
final characterPersistenceServiceProvider =
    Provider<CharacterPersistenceService>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  final storageService = ref.watch(characterStorageServiceProvider);
  final cacheManager = ref.watch(cacheManagerProvider);

  return CharacterPersistenceService(
    repository: repository,
    storageService: storageService,
    cacheManager: cacheManager,
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
