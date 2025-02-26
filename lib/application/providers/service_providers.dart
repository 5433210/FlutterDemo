import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/providers/database_providers.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../../infrastructure/providers/storage_providers.dart';
import '../services/character_service.dart';
import '../services/image_service.dart';
import '../services/practice_service.dart';
import '../services/settings_service.dart';
import '../services/work_service.dart';

final characterServiceProvider = Provider<CharacterService>((ref) {
  final charRepo = ref.watch(characterRepositoryProvider);
  final workRepo = ref.watch(workRepositoryProvider);
  return CharacterService(charRepo, workRepo);
});

final imageServiceProvider = Provider<ImageService>((ref) {
  final paths = ref.watch(storagePathsProvider);
  return ImageService(paths);
});

final practiceServiceProvider = Provider<PracticeService>((ref) {
  final practiceRepo = ref.watch(practiceRepositoryProvider);
  final charRepo = ref.watch(characterRepositoryProvider);
  return PracticeService(practiceRepo, charRepo);
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final database = ref.watch(databaseProvider);
  return SettingsService(database);
});

final workServiceProvider = Provider<WorkService>((ref) {
  final repository = ref.watch(workRepositoryProvider);
  final imageService = ref.watch(imageServiceProvider);
  final paths = ref.watch(storagePathsProvider);
  return WorkService(repository, imageService, paths);
});
