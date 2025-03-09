import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../domain/repositories/work_repository.dart';
import '../persistence/database_interface.dart';
import '../persistence/mock_database.dart';
import '../repositories/character_repository_impl.dart';
import '../repositories/practice_repository_impl.dart';
import '../repositories/work_repository_impl.dart';

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CharacterRepositoryImpl(db);
});

/// Database Provider
final databaseProvider = Provider<DatabaseInterface>((ref) {
  // Initialize mock database
  final db = MockDatabase();
  db.initialize();
  return db;
});

/// Practice Repository Provider
final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PracticeRepositoryImpl(db);
});

/// Work Repository Provider
final workRepositoryProvider = Provider<WorkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkRepositoryImpl(db);
});
