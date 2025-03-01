import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/services/image_service.dart';
import '../../infrastructure/providers/repository_providers.dart';
import '../../infrastructure/services/state_restoration_service.dart';
import '../services/character/character_service.dart';
import '../services/practice/practice_service.dart';
import '../services/work/work_image_service.dart';
import '../services/work/work_image_service_impl.dart';
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

/// 共享首选项提供器
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('需要在 ProviderScope 的 overrides 中重写这个 provider');
});

// 新增：状态恢复服务提供器
final stateRestorationServiceProvider =
    Provider<StateRestorationService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StateRestorationService(prefs);
});

// 添加 WorkImageService 提供器
final workImageServiceProvider = Provider<WorkImageService>((ref) {
  final imageService = ref.watch(imageServiceProvider);
  return WorkImageServiceImpl(imageService);
});

final workServiceProvider = Provider<WorkService>((ref) {
  final workRepository = ref.watch(workRepositoryProvider);
  final imageService = ref.watch(imageServiceProvider);
  return WorkService(workRepository, imageService);
});
