import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_providers.dart';
import '../../domain/repositories/work_repository.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/practice_repository.dart';
import '../repositories/work_repository_impl.dart';
import '../repositories/character_repository_impl.dart';
import '../repositories/practice_repository_impl.dart';

final workRepositoryProvider = Provider<WorkRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkRepositoryImpl(db);
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CharacterRepositoryImpl(db);
});

final practiceRepositoryProvider = Provider<PracticeRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PracticeRepositoryImpl(db);
});