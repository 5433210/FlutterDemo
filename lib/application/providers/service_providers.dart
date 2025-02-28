import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/services/image_service.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../services/character/character_service.dart';
import '../services/practice/practice_service.dart';
import '../services/work/work_service.dart';

final characterServiceProvider = Provider<CharacterService>((ref) {
  final characterRepository = ref.watch(characterRepositoryProvider);
  final workRepository = ref.watch(workRepositoryProvider);
  return CharacterService(characterRepository, workRepository);
});

// 服务 Providers
final imageServiceProvider = Provider<ImageService>((ref) {
  return ImageService();
});

final practiceServiceProvider = Provider<PracticeService>((ref) {
  final practiceRepository = ref.watch(practiceRepositoryProvider);
  return PracticeService(practiceRepository);
});

final workServiceProvider = Provider<WorkService>((ref) {
  final workRepository = ref.watch(workRepositoryProvider);
  final imageService = ref.watch(imageServiceProvider);
  return WorkService(workRepository, imageService);
});
