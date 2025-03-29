import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/image/default_image_processor.dart';
import '../services/character/character_service.dart';
import '../services/image/character_image_processor.dart';
import '../services/storage/cache_manager.dart';

/// 底层图像处理器Provider
final baseImageProcessorProvider = Provider<DefaultImageProcessor>((ref) {
  return DefaultImageProcessor();
});

/// 缓存管理器Provider
final cacheManagerProvider = Provider<CacheManager>((ref) {
  return CacheManager();
});

/// 字符图像处理器Provider
final characterImageProcessorProvider =
    Provider<CharacterImageProcessor>((ref) {
  final processor = ref.watch(baseImageProcessorProvider);
  final cacheManager = ref.watch(cacheManagerProvider);
  return CharacterImageProcessor(processor, cacheManager);
});

/// 字符服务Provider
final characterProvider = Provider<CharacterService>((ref) {
  return ref.watch(characterServiceProvider);
});
