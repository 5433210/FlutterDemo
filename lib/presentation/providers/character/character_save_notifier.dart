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

  void finishSaving() {
    state = state.copyWith(
      isSaving: false,
      lastSaved: DateTime.now(),
    );
  }

  void setError(String message) {
    state = state.copyWith(
      isSaving: false,
      error: message,
    );
  }

  void startSaving() {
    state = state.copyWith(isSaving: true, progress: 0.0);
  }

  void updateProgress(double progress) {
    if (state.isSaving) {
      state = state.copyWith(progress: progress.clamp(0.0, 1.0));
    }
  }
}

/// State class for character save operations
class SaveState {
  final bool isSaving;
  final String? error;
  final DateTime? lastSaved;
  final double? progress; // 保存进度 0.0 - 1.0

  const SaveState({
    this.isSaving = false,
    this.error,
    this.lastSaved,
    this.progress,
  });

  SaveState copyWith({
    bool? isSaving,
    String? error,
    DateTime? lastSaved,
    double? progress,
  }) {
    return SaveState(
      isSaving: isSaving ?? this.isSaving,
      error: error, // Pass null to clear error
      lastSaved: lastSaved ?? this.lastSaved,
      progress:
          isSaving == false ? null : (progress ?? this.progress), // 当结束保存时清除进度
    );
  }
}
