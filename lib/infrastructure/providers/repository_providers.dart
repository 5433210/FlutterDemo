import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../persistence/database_interface.dart';
import '../repositories/character_repository_impl.dart';
import '../repositories/practice_repository_impl.dart';
import '../repositories/sqlite/work_image_repository_impl.dart';
import '../repositories/work_repository_impl.dart';
import 'initialization_providers.dart';

/// Character Repository Provider
final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepositoryImpl(_getInitializedDatabase(ref));
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
  final dbState = ref.watch(databaseStateProvider);
  if (!dbState.isInitialized || dbState.database == null) {
    throw StateError('数据库未初始化');
  }
  return dbState.database!;
}
