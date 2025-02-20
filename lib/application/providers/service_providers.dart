import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/providers/database_providers.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../services/work_service.dart';
import '../services/character_service.dart';
import '../services/practice_service.dart';
import '../services/settings_service.dart';

final workServiceProvider = Provider<WorkService>((ref) {
  final repository = ref.watch(workRepositoryProvider);
  return WorkService(repository);
});

final characterServiceProvider = Provider<CharacterService>((ref) {
  final charRepo = ref.watch(characterRepositoryProvider);
  final workRepo = ref.watch(workRepositoryProvider);
  return CharacterService(charRepo, workRepo);
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