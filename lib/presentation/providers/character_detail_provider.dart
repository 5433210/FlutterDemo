import 'package:demo/domain/models/character/character_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/service_providers.dart';
import '../../infrastructure/logging/logger.dart';

/// Provider for character detail
final characterDetailProvider = StateNotifierProvider.autoDispose<
    CharacterDetailNotifier, AsyncValue<CharacterEntity?>>((ref) {
  return CharacterDetailNotifier(ref);
});

/// Character detail notifier
class CharacterDetailNotifier
    extends StateNotifier<AsyncValue<CharacterEntity?>> {
  final Ref ref;

  CharacterDetailNotifier(this.ref) : super(const AsyncValue.loading());

  /// Delete character
  Future<void> deleteCharacter(String id) async {
    try {
      await ref.read(characterServiceProvider).deleteCharacter(id);
      state = const AsyncValue.data(null);
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
  Future<CharacterEntity?> getCharacter(String id) async {
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
