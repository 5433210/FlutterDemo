import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/services/character/character_service.dart';
import '../../../domain/models/character/character_filter.dart';
import '../../../domain/repositories/character/character_view_repository.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../viewmodels/states/character_management_state.dart';

/// Provider for character management state
final characterManagementProvider = StateNotifierProvider<
    CharacterManagementNotifier, CharacterManagementState>(
  (ref) => CharacterManagementNotifier(
    characterService: ref.watch(characterServiceProvider),
    characterViewRepository: ref.watch(characterViewRepositoryProvider),
  ),
);

/// Character management state notifier
class CharacterManagementNotifier
    extends StateNotifier<CharacterManagementState> {
  final CharacterService _characterService;
  final CharacterViewRepository _characterViewRepository;

  CharacterManagementNotifier({
    required CharacterService characterService,
    required CharacterViewRepository characterViewRepository,
  })  : _characterService = characterService,
        _characterViewRepository = characterViewRepository,
        super(CharacterManagementState.initial());

  /// Change current page
  Future<void> changePage(int newPage) async {
    if (newPage == state.currentPage ||
        newPage < 1 ||
        newPage > ((state.totalCount - 1) / state.pageSize).ceil() + 1) {
      return;
    }

    state = state.copyWith(currentPage: newPage);
    await loadCharacters();
  }

  /// Clear all selections
  void clearAllSelections() {
    state = state.copyWith(selectedCharacters: {});
  }

  /// Clear all selected characters
  void clearSelection() {
    if (!state.isBatchMode) return;

    state = state.copyWith(selectedCharacters: {});
  }

  /// Close detail panel
  void closeDetailPanel() {
    state = state.copyWith(isDetailOpen: false);
  }

  /// 复制选中的字符ID到剪贴板
  /// 如果是批量模式下选择了多个字符，则复制所有选中的字符ID
  /// 如果不是批量模式，则复制当前选中的字符ID
  Future<void> copySelectedCharactersToClipboard() async {
    try {
      List<String> characterIds = [];

      // 批量模式下，复制所有选中的字符ID
      if (state.isBatchMode && state.selectedCharacters.isNotEmpty) {
        characterIds = state.selectedCharacters.toList();
      }
      // 非批量模式下，复制当前选中的字符ID（如果有）
      else if (state.selectedCharacterId != null) {
        characterIds = [state.selectedCharacterId!];
      }

      // 如果没有选中的字符，直接返回
      if (characterIds.isEmpty) return;

      // 将字符ID列表转换为JSON格式并写入剪贴板
      final Map<String, dynamic> clipboardData = {
        'type': 'characters',
        'count': characterIds.length,
        'characterIds': characterIds,
      };

      final String jsonData = jsonEncode(clipboardData);
      await Clipboard.setData(ClipboardData(text: jsonData));

      // 提示用户复制成功（这里不改变状态，由UI层处理提示）
      AppLogger.info('Copied ${characterIds.length} character(s) to clipboard');
    } catch (e) {
      AppLogger.error('Failed to copy characters to clipboard: $e');
      state = state.copyWith(
          errorMessage: 'Failed to copy characters to clipboard');
    }
  }

  /// Delete a single character
  Future<void> deleteCharacter(String characterId) async {
    try {
      state = state.copyWith(isLoading: true);

      // Use character service to delete the character
      await _characterService.deleteCharacter(characterId);

      // If the deleted character was selected for detail view, clear selection
      if (state.selectedCharacterId == characterId) {
        state = state.copyWith(
          selectedCharacterId: null,
          isDetailOpen: false,
        );
      }

      state = state.copyWith(isLoading: false);
      await loadCharacters();
    } catch (e) {
      AppLogger.error('Failed to delete character', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: '删除字符失败：${e.toString()}',
      );
    }
  }

  /// Delete selected characters
  Future<void> deleteSelectedCharacters() async {
    if (state.selectedCharacters.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true);

      // Use character service to delete characters
      await _characterService
          .deleteBatchCharacters(state.selectedCharacters.toList());

      // Clear selection and reload
      state = state.copyWith(
        selectedCharacters: {},
        isLoading: false,
      );

      await loadCharacters();
    } catch (e) {
      AppLogger.error('Failed to delete characters', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: '删除字符失败：${e.toString()}',
      );
    }
  }

  /// Load all available tags
  Future<void> loadAllTags() async {
    try {
      final tags = await _characterViewRepository.getAllTags();
      state = state.copyWith(allTags: tags);
    } catch (e) {
      AppLogger.error('Failed to load tags', error: e);
    }
  }

  /// Reload character data
  Future<void> loadCharacters() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final result = await _characterViewRepository.getCharacters(
        filter: state.filter,
        page: state.currentPage,
        pageSize: state.pageSize,
      );

      state = state.copyWith(
        characters: result.items,
        totalCount: result.totalCount,
        currentPage: result.currentPage,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to load characters', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: '加载字符数据失败：${e.toString()}',
      );
    }
  }

  /// Load initial data
  Future<void> loadInitialData() async {
    await loadCharacters();
    await loadAllTags();
  }

  /// Select all characters on current page
  void selectAllOnPage() {
    if (!state.isBatchMode) return;

    final selectedCharacters = Set<String>.from(state.selectedCharacters);
    for (final character in state.characters) {
      selectedCharacters.add(character.id);
    }

    state = state.copyWith(selectedCharacters: selectedCharacters);
  }

  /// Select character for detail view
  void selectCharacter(String characterId) {
    state = state.copyWith(
      selectedCharacterId: characterId,
      isDetailOpen: true,
    );
  }

  /// Set view mode directly
  void setViewMode(ViewMode mode) {
    if (state.viewMode != mode) {
      state = state.copyWith(viewMode: mode);
    }
  }

  /// Toggle batch selection mode
  void toggleBatchMode() {
    final newBatchMode = !state.isBatchMode;
    state = state.copyWith(
      isBatchMode: newBatchMode,
      selectedCharacters: newBatchMode ? state.selectedCharacters : {},
    );
  }

  /// Toggle character selection in batch mode
  void toggleCharacterSelection(String characterId) {
    if (!state.isBatchMode) return;

    final selectedCharacters = Set<String>.from(state.selectedCharacters);
    if (selectedCharacters.contains(characterId)) {
      selectedCharacters.remove(characterId);
    } else {
      selectedCharacters.add(characterId);
    }

    state = state.copyWith(selectedCharacters: selectedCharacters);
  }

  /// Toggle detail panel visibility
  void toggleDetailPanel() {
    state = state.copyWith(isDetailOpen: !state.isDetailOpen);
  }

  /// Toggle favorite status for a character
  Future<void> toggleFavorite(String characterId) async {
    try {
      // Call character service to toggle favorite status
      final success = await _characterService.toggleFavorite(characterId);
      if (success) {
        // Update the character in the list
        final updatedCharacters = state.characters.map((character) {
          if (character.id == characterId) {
            return character.copyWith(isFavorite: !character.isFavorite);
          }
          return character;
        }).toList();

        state = state.copyWith(characters: updatedCharacters);
      }
    } catch (e) {
      AppLogger.error('Failed to toggle favorite', error: e);
    }
  }

  /// Toggle view mode between grid and list
  void toggleViewMode() {
    final newMode =
        state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    state = state.copyWith(viewMode: newMode);
  }

  /// Update filter and reload data
  Future<void> updateFilter(CharacterFilter filter) async {
    state = state.copyWith(filter: filter, currentPage: 1);
    await loadCharacters();
  }

  /// Update page size
  Future<void> updatePageSize(int newSize) async {
    if (newSize == state.pageSize) return;

    state = state.copyWith(pageSize: newSize, currentPage: 1);
    await loadCharacters();
  }
}
