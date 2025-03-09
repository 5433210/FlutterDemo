import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/repository_providers.dart';
import '../services/character/character_service.dart';
import '../services/practice/practice_service.dart';
import '../services/work/work_image_service.dart';
import '../services/work/work_service.dart';

final characterServiceProvider = Provider<CharacterService>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  return CharacterService(repository: repository);
});

/// Practice Service Provider
final practiceServiceProvider = Provider<PracticeService>((ref) {
  final repository = ref.watch(practiceRepositoryProvider);
  return PracticeService(repository: repository);
});

/// Work Service Provider
final workServiceProvider = Provider<WorkService>((ref) {
  final repository = ref.watch(workRepositoryProvider);
  final imageService = ref.watch(workImageServiceProvider);
  return WorkService(
    repository: repository,
    imageService: imageService,
  );
});
