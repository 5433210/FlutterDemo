import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../persistence/sqlite/sqlite_database.dart';
import '../repositories/character_repository_impl.dart';
import '../repositories/practice_repository_impl.dart';
import '../repositories/work_repository_impl.dart';

/// Provider for character repository
final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  return CharacterRepositoryImpl(ref.watch(databaseProvider));
});

/// Provider for database instance
final databaseProvider = Provider<SqliteDatabase>((ref) {
  final db = SqliteDatabase();
  ref.onDispose(() {
    db.close();
  });
  return db;
});

/// Provider for practice repository
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  return PracticeRepositoryImpl(ref.watch(databaseProvider));
});

/// Provider for work repository
final workRepositoryProvider = Provider<WorkRepository>((ref) {
  return WorkRepositoryImpl(ref.watch(databaseProvider));
});
