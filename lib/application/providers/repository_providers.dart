import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/character/character_view_repository.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../infrastructure/providers/database_providers.dart';
import '../repositories/character/character_view_repository_impl.dart';
import '../repositories/character_repository_impl.dart';
import '../repositories/practice_repository_impl.dart';
import '../repositories/work_image_repository_impl.dart';
import '../repositories/work_repository_impl.dart';

/// Character Repository Provider
final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepositoryImpl(_getInitializedDatabase(ref));
});

/// Provider for CharacterViewRepository
final characterViewRepositoryProvider =
    Provider<CharacterViewRepository>((ref) {
  final characterRepository = ref.watch(characterRepositoryProvider);
  return CharacterViewRepositoryImpl(
      _getInitializedDatabase(ref), characterRepository);
});

/// Practice Repository Provider
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepositoryImpl(_getInitializedDatabase(ref));
});

/// WorkImageRepository Provider
final workImageRepositoryProvider = Provider<WorkImageRepository>((ref) {
  return WorkImageRepositoryImpl(_getInitializedDatabase(ref));
});

/// Work Repository Provider
final workRepositoryProvider = Provider<WorkRepository>((ref) {
  return WorkRepositoryImpl(_getInitializedDatabase(ref));
});

/// 提供初始化完成的数据库实例
DatabaseInterface _getInitializedDatabase(Ref ref) {
  return ref.watch(initializedDatabaseProvider);
}
