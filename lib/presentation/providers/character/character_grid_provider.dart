import 'package:demo/application/services/character/character_persistence_service.dart';
import 'package:demo/presentation/providers/work_detail_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../viewmodels/states/character_grid_state.dart';

final characterGridProvider =
    StateNotifierProvider<CharacterGridNotifier, CharacterGridState>((ref) {
  final repository = ref.watch(characterRepositoryProvider);
  final workId = ref.watch(workDetailProvider).work?.id;
  final persistenceService = ref.watch(characterPersistenceServiceProvider);
  return CharacterGridNotifier(repository, workId!, persistenceService);
});

class CharacterGridNotifier extends StateNotifier<CharacterGridState> {
  final CharacterRepository _repository;
  final CharacterPersistenceService _persistenceService;
  final String workId;

  CharacterGridNotifier(this._repository, this.workId, this._persistenceService)
      : super(const CharacterGridState()) {
    // 初始化时加载数据
    loadCharacters();
  }

  // New methods for managing selections
  void clearSelection() {
    final updatedCharacters = state.characters
        .map((c) => c.isSelected ? c.copyWith(isSelected: false) : c)
        .toList();

    state = state.copyWith(
      characters: updatedCharacters,
      filteredCharacters: _filterAndSortCharacters(updatedCharacters),
      selectedIds: {},
    );
  }

  // Get selected character IDs
  List<String> getSelectedCharacterIds() {
    return state.characters
        .where((c) => c.isSelected)
        .map((c) => c.id)
        .toList();
  }

  Future<void> loadCharacters() async {
    try {
      state = state.copyWith(loading: true, error: null);

      // 从仓库加载作品相关的字符
      final characters = await _repository.findByWorkId(workId);

      // 转换为视图模型
      final viewModels = characters
          .map((char) => CharacterViewModel(
                id: char.id,
                pageId: char.pageId,
                character: char.character,
                thumbnailPath: '', // 需通过仓库获取缩略图路径
                createdAt: char.createTime,
                updatedAt: char.updateTime,
                isFavorite: char.isFavorite,
              ))
          .toList();

      // 获取缩略图路径
      for (int i = 0; i < viewModels.length; i++) {
        final vm = viewModels[i];
        final path = await _persistenceService.getThumbnailPath(vm.id);
        viewModels[i] = vm.copyWith(thumbnailPath: path);
      }

      // 计算分页信息（假设每页16项）
      const itemsPerPage = 16;
      final totalPages = (viewModels.length / itemsPerPage).ceil();

      state = state.copyWith(
        characters: viewModels,
        filteredCharacters: viewModels,
        totalPages: totalPages > 0 ? totalPages : 1,
        currentPage: 1,
        loading: false,
      );

      _applyFilters();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  void setPage(int page) {
    if (page < 1 || page > state.totalPages) return;

    state = state.copyWith(currentPage: page);
    _applyFilters();
  }

  void toggleSelection(String id) {
    final updatedCharacters = state.characters.map((c) {
      if (c.id == id) {
        return c.copyWith(isSelected: !c.isSelected);
      }
      return c;
    }).toList();

    // Also keep selectedIds in sync for transition period
    final selectedIds = Set<String>.from(state.selectedIds);
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }

    state = state.copyWith(
      characters: updatedCharacters,
      filteredCharacters: _filterAndSortCharacters(updatedCharacters),
      selectedIds: selectedIds,
    );
  }

  void updateFilter(FilterType type) {
    state = state.copyWith(filterType: type);
    _applyFilters();
  }

  void updateSearch(String term) {
    state = state.copyWith(searchTerm: term);
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = List<CharacterViewModel>.from(state.characters);

    // Apply search filter
    if (state.searchTerm.isNotEmpty) {
      filtered = filtered
          .where((char) => char.character.contains(state.searchTerm))
          .toList();
    }

    // Apply type filter
    switch (state.filterType) {
      case FilterType.all:
        // No additional filtering needed
        break;
      case FilterType.recent:
        // Sort by creation date, newest first
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FilterType.favorite:
        filtered = filtered.where((char) => char.isFavorite).toList();
        break;
    }

    // Update filtered list
    state = state.copyWith(
      filteredCharacters: filtered,
    );
  }

  // New helper method for filtering and sorting
  List<CharacterViewModel> _filterAndSortCharacters(
      List<CharacterViewModel> characters) {
    var filtered = List<CharacterViewModel>.from(characters);

    // Apply current filters
    if (state.searchTerm.isNotEmpty) {
      filtered = filtered
          .where((char) => char.character.contains(state.searchTerm))
          .toList();
    }

    // Apply current sorting
    switch (state.filterType) {
      case FilterType.all:
        // No additional sorting needed
        break;
      case FilterType.recent:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FilterType.favorite:
        filtered = filtered.where((char) => char.isFavorite).toList();
        break;
    }

    return filtered;
  }
}
