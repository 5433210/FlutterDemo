import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/character/character_region.dart';
import '../../../domain/models/character/processing_result.dart';
import '../../../infrastructure/logging/logger.dart';
import 'character_collection_provider.dart';
import 'erase_providers.dart';

/// Save state notifier for managing character save operations
final characterSaveNotifierProvider =
    StateNotifierProvider<CharacterSaveNotifier, SaveState>(
  (ref) => CharacterSaveNotifier(ref),
);

class CharacterSaveNotifier extends StateNotifier<SaveState> {
  final Ref _ref;

  CharacterSaveNotifier(this._ref) : super(const SaveState());

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Save character information and optional image data
  Future<String?> saveCharacter({
    required CharacterRegion region,
    required String character,
    required ProcessingResult? imageData,
  }) async {
    try {
      state = state.copyWith(isSaving: true, error: null);

      final collectionNotifier =
          _ref.read(characterCollectionProvider.notifier);

      // First, update the selected region with the new character
      final updatedRegion = region.copyWith(character: character);
      collectionNotifier.updateSelectedRegion(updatedRegion);

      // Save the character
      await collectionNotifier.saveCurrentRegion(imageData: imageData);

      // Get the saved region to access its updated character ID
      final savedRegion = _ref.read(characterCollectionProvider).selectedRegion;

      // Important: After save, ensure erasePaths are reloaded with the new character ID
      if (savedRegion != null &&
          region.characterId == null &&
          savedRegion.characterId != null) {
        // This was the first save (new region becoming a character)
        // Reload the erase data with the new character ID
        AppLogger.debug('First save detected - refreshing erase state', data: {
          'oldId': region.id,
          'newCharacterId': savedRegion.characterId,
          'hasEraseData': savedRegion.eraseData != null,
          'eraseDataCount': savedRegion.eraseData?.length ?? 0
        });

        // Reload erase paths if they exist
        if (savedRegion.eraseData != null &&
            savedRegion.eraseData!.isNotEmpty) {
          _ref
              .read(eraseStateProvider.notifier)
              .initializeWithSavedPaths(savedRegion.eraseData!);
        }
      }

      state = state.copyWith(isSaving: false, lastSaved: DateTime.now());
      return savedRegion?.characterId;
    } catch (e) {
      AppLogger.error('保存失败', error: e);
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return null;
    }
  }
}

/// State class for character save operations
class SaveState {
  final bool isSaving;
  final String? error;
  final DateTime? lastSaved;

  const SaveState({
    this.isSaving = false,
    this.error,
    this.lastSaved,
  });

  SaveState copyWith({
    bool? isSaving,
    String? error,
    DateTime? lastSaved,
  }) {
    return SaveState(
      isSaving: isSaving ?? this.isSaving,
      error: error, // Pass null to clear error
      lastSaved: lastSaved ?? this.lastSaved,
    );
  }
}
