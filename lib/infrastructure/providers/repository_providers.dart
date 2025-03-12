import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/repositories/character_repository_impl.dart';
import '../../application/repositories/practice_repository_impl.dart';
import '../../application/repositories/work_image_repository_impl.dart';
import '../../application/repositories/work_repository_impl.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../persistence/database_interface.dart';
import './database_providers.dart';

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
  if (!dbState.isInitialized) {
    throw StateError('数据库未初始化');
  }
  return dbState.database!;
  // 因为 isInitialized 已经确保 database 不为空
}
