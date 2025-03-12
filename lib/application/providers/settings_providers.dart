import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/providers/database_providers.dart';
import '../commands/migration_commands.dart';
import '../repositories/settings_repository_impl.dart';

/// Migration Commands Provider
final migrationCommandsProvider =
    Provider.autoDispose<AsyncValue<MigrationCommands>>((ref) {
  final settingsRepoAsync = ref.watch(settingsRepositoryProvider);
  return settingsRepoAsync.when(
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
    data: (repo) => AsyncData(MigrationCommands(repo)),
  );
});

/// Settings Repository Provider
final settingsRepositoryProvider =
    Provider.autoDispose<AsyncValue<SettingsRepository>>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    loading: () => const AsyncLoading(),
    error: (err, stack) => AsyncError(err, stack),
    data: (db) => AsyncData(SettingsRepositoryImpl(db)),
  );
});
