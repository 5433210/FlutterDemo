import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/cache/character_image_cache_service.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../../infrastructure/services/character_image_service.dart';
import '../providers/service_providers.dart';

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
