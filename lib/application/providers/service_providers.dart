import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/image_processor_providers.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../services/storage/storage_service.dart';
import '../services/work/work_image_service.dart';
import '../services/work/work_service.dart';

/// Service Providers

/// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(
    storage: ref.watch(storageProvider),
    workImageStorage: ref.watch(workImageStorageProvider),
  );
});

/// Work Image Service Provider
final workImageServiceProvider = Provider<WorkImageService>((ref) {
  return WorkImageService(
    storage: ref.watch(storageProvider),
    workImageStorage: ref.watch(workImageStorageProvider),
    processor: ref.watch(workImageProcessorProvider),
  );
});

/// Work Service Provider
final workServiceProvider = Provider<WorkService>((ref) {
  return WorkService(
    repository: ref.watch(workRepositoryProvider),
    imageService: ref.watch(workImageServiceProvider),
    storage: ref.watch(storageProvider),
    workImageStorage: ref.watch(workImageStorageProvider),
    workImageRepository: ref.watch(workImageRepositoryProvider),
  );
});
