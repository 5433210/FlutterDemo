import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../domain/entities/character.dart';
import '../../infrastructure/logging/logger.dart';

/// Provider for character detail
final characterDetailProvider = StateNotifierProvider.autoDispose<
    CharacterDetailNotifier, AsyncValue<Character?>>((ref) {
  return CharacterDetailNotifier(ref);
});

/// Character detail notifier
class CharacterDetailNotifier extends StateNotifier<AsyncValue<Character?>> {
  final Ref ref;

  CharacterDetailNotifier(this.ref) : super(const AsyncValue.loading());

  /// Delete character
  Future<bool> deleteCharacter(String id) async {
    try {
      final success =
          await ref.read(characterServiceProvider).deleteCharacter(id);
      if (success) {
        state = const AsyncValue.data(null);
      }
      return success;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to delete character',
        tag: 'CharacterDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'id': id},
      );
      rethrow;
    }
  }

  /// Get character by ID
  Future<Character?> getCharacter(String id) async {
    try {
      state = const AsyncValue.loading();

      final character =
          await ref.read(characterServiceProvider).getCharacter(id);

      state = AsyncValue.data(character);
      return character;
    } catch (e, stack) {
      AppLogger.error(
        'Failed to get character',
        tag: 'CharacterDetailNotifier',
        error: e,
        stackTrace: stack,
        data: {'id': id},
      );
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
