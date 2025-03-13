import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/repository_providers.dart';
import '../../domain/models/character/character_filter.dart';
import '../../domain/repositories/character_repository.dart';
import '../viewmodels/states/character_collection_state.dart';

/// 提供CharacterCollectionState状态管理
final characterCollectionProvider = StateNotifierProvider<
    CharacterCollectionNotifier, CharacterCollectionState>(
  (ref) => CharacterCollectionNotifier(
    characterRepository: ref.watch(characterRepositoryProvider),
  ),
);

/// 提供CharacterRepository实例

class CharacterCollectionNotifier
    extends StateNotifier<CharacterCollectionState> {
  final CharacterRepository _characterRepository;

  CharacterCollectionNotifier({
    required CharacterRepository characterRepository,
  })  : _characterRepository = characterRepository,
        super(const CharacterCollectionState());

  Future<void> deleteSelected() async {
    if (state.selectedCharacters.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      await _characterRepository.deleteMany(
        state.selectedCharacters.toList(),
      );

      state = state.copyWith(
        selectedCharacters: {},
        batchMode: false,
        isLoading: false,
      );

      await loadCharacters(forceRefresh: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadCharacters({bool forceRefresh = false}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final characters = await _characterRepository.query(
        state.filter,
      );

      state = state.copyWith(
        characters: characters,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadStats() async {}

  void selectCharacter(String? characterId) {
    if (!state.batchMode) {
      state = state.copyWith(selectedCharacterId: characterId);
    }
  }

  void setSearchQuery(String query) {
    final newFilter = state.filter.copyWith(searchQuery: query);
    state = state.copyWith(filter: newFilter);
    loadCharacters();
  }

  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void toggleBatchMode() {
    final newBatchMode = !state.batchMode;
    state = state.copyWith(
      batchMode: newBatchMode,
      // 退出批量模式时清空选择
      selectedCharacters: newBatchMode ? state.selectedCharacters : {},
    );
  }

  void toggleSelection(String characterId) {
    if (!state.batchMode) return;

    final selectedCharacters = Set<String>.from(state.selectedCharacters);
    if (selectedCharacters.contains(characterId)) {
      selectedCharacters.remove(characterId);
    } else {
      selectedCharacters.add(characterId);
    }

    state = state.copyWith(selectedCharacters: selectedCharacters);
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarOpen: !state.isSidebarOpen);
  }

  void updateFilter(CharacterFilter filter) {
    state = state.copyWith(filter: filter);
    loadCharacters();
  }
}
