import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/character_service.dart';
import '../../application/services/image_service.dart';
import '../../application/services/work_service.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../../infrastructure/providers/storage_providers.dart';

final characterServiceProvider = Provider<CharacterService>((ref) {
  final characterRepository = ref.watch(characterRepositoryProvider);
  final workRepository = ref.watch(workRepositoryProvider);
  return CharacterService(characterRepository, workRepository);
});

// 服务 Providers
final imageServiceProvider = Provider<ImageService>((ref) {
  final paths = ref.watch(storagePathsProvider);
  return ImageService(paths);
});

final workServiceProvider = Provider<WorkService>((ref) {
  final workRepository = ref.watch(workRepositoryProvider);
  final imageService = ref.watch(imageServiceProvider);
  final paths = ref.watch(storagePathsProvider);
  return WorkService(workRepository, imageService, paths);
});
