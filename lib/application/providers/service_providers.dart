import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/repository_providers.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../services/storage/work_storage_service.dart';
import '../services/work/work_image_service.dart';
import '../services/work/work_service.dart';
import 'storage_providers.dart';

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
    storage: ref.watch(storageProvider),
    workImageRepository: ref.watch(workImageRepositoryProvider),
  );
});

final workStorageProvider = Provider<WorkStorageService>((ref) {
  return WorkStorageService(
    storage: ref.watch(storageProvider),
  );
});
