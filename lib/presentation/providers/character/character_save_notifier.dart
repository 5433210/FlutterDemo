import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Save state notifier for managing character save operations
final characterSaveNotifierProvider =
    StateNotifierProvider<CharacterSaveNotifier, SaveState>(
  (ref) => CharacterSaveNotifier(),
);

class CharacterSaveNotifier extends StateNotifier<SaveState> {
  CharacterSaveNotifier() : super(const SaveState());

  void clearError() {
    state = state.copyWith(error: null);
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
