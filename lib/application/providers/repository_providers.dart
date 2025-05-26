import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/character/character_view_repository.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_image_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../infrastructure/providers/cache_providers.dart' as cache;
import '../../infrastructure/providers/database_providers.dart';
import '../repositories/character/character_view_repository_impl.dart';
import '../repositories/character_repository_impl.dart';
import '../repositories/library_repository_impl.dart';
import '../repositories/practice_repository_impl.dart';
import '../repositories/work_image_repository_impl.dart';
import '../repositories/work_repository_impl.dart';

/// Character Repository Provider
final characterRepositoryProvider =
    FutureProvider<CharacterRepository>((ref) async {
  final database = await _getInitializedDatabase(ref);
  return CharacterRepositoryImpl(database);
});

/// Provider for CharacterViewRepository
final characterViewRepositoryProvider =
    FutureProvider<CharacterViewRepository>((ref) async {
  final characterRepository =
      await ref.watch(characterRepositoryProvider.future);
  final database = await _getInitializedDatabase(ref);
  return CharacterViewRepositoryImpl(database, characterRepository);
});

/// 图库仓库提供者
final libraryRepositoryProvider =
    FutureProvider<ILibraryRepository>((ref) async {
  final database = await _getInitializedDatabase(ref);
  return LibraryRepositoryImpl(
    database,
    ref.watch(cache.imageCacheServiceProvider),
  );
});

/// Practice Repository Provider
final practiceRepositoryProvider =
    FutureProvider<PracticeRepository>((ref) async {
  final database = await _getInitializedDatabase(ref);
  return PracticeRepositoryImpl(database);
});

/// WorkImageRepository Provider
final workImageRepositoryProvider =
    FutureProvider<WorkImageRepository>((ref) async {
  final database = await _getInitializedDatabase(ref);
  return WorkImageRepositoryImpl(database);
});

/// Work Repository Provider
final workRepositoryProvider = FutureProvider<WorkRepository>((ref) async {
  final database = await _getInitializedDatabase(ref);
  return WorkRepositoryImpl(database);
});

/// 提供初始化完成的数据库实例
Future<DatabaseInterface> _getInitializedDatabase(Ref ref) async {
  AppLogger.debug('Repository requesting database instance',
      tag: 'RepositoryProvider');

  final database = await ref.watch(initializedDatabaseProvider.future);

  AppLogger.info('Repository received database instance',
      tag: 'RepositoryProvider', data: {'instanceId': database.hashCode});

  return database;
}
