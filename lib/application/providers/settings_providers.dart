import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/settings_repository.dart';
import '../../infrastructure/providers/database_providers.dart';
import '../commands/migration_commands.dart';
import '../repositories/settings_repository_impl.dart';

final languageProvider =
    StateNotifierProvider<LanguageNotifier, Locale?>((ref) {
  return LanguageNotifier();
});

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

class LanguageNotifier extends StateNotifier<Locale?> {
  LanguageNotifier() : super(null) {
    _loadSavedLanguage();
  }

  Future<void> setLanguage(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null) {
      await prefs.remove('languageCode');
      state = null;
    } else {
      await prefs.setString('languageCode', languageCode);
      state = Locale(languageCode);
    }
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }
}
