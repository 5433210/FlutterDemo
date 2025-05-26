import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../application/providers/service_providers.dart';
import '../../../application/services/storage/character_storage_service.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../viewmodels/states/character_grid_state.dart';

final characterGridProvider = StateNotifierProvider.family<
    CharacterGridNotifier, CharacterGridState, String>((ref, workId) {
  final repository = ref.watch(characterRepositoryProvider);
  final storageService = ref.watch(characterStorageServiceProvider);

  return repository.when(
    data: (repo) => CharacterGridNotifier(repo, workId, storageService),
    loading: () => throw Exception('Character repository is loading'),
    error: (error, stack) =>
        throw Exception('Character repository error: $error'),
  );
});

class CharacterGridNotifier extends StateNotifier<CharacterGridState> {
  final CharacterRepository _repository;
  final CharacterStorageService _storageService;
  final String workId;

  CharacterGridNotifier(this._repository, this.workId, this._storageService)
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
    // 使用 Future 延迟执行，避免在构建过程中修改状态
    Future(() async {
      try {
        state = state.copyWith(loading: true, error: null);

        // 如果 workId 为空，返回空列表
        if (workId.isEmpty) {
          state = state.copyWith(
            characters: [],
            filteredCharacters: [],
            totalPages: 1,
            currentPage: 1,
            loading: false,
            isInitialLoad: false, // workId为空时，也将初始加载标志设置为false
          );
          return;
        }

        // 从仓库加载作品相关的字符
        final characters = await _repository.findByWorkId(workId);

        // 转换为视图模型
        final viewModels = characters
            .map((char) => CharacterViewModel(
                  id: char.id,
                  pageId: char.pageId,
                  character: char.character,
                  thumbnailPath: '', // 需通过仓库获取缩略图路径
                  createdAt: char.createTime ?? DateTime.now(),
                  updatedAt: char.updateTime ?? DateTime.now(),
                  isFavorite: char.isFavorite,
                ))
            .toList();

        // 获取缩略图路径
        for (int i = 0; i < viewModels.length; i++) {
          final vm = viewModels[i];
          final path = await _storageService.getThumbnailPath(vm.id);
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
          isInitialLoad: false, // 加载完成后，将初始加载标志设置为false
        );

        _applyFilters();
      } catch (e) {
        state = state.copyWith(
          loading: false,
          error: e.toString(),
          isInitialLoad: false, // 即使出错，也将初始加载标志设置为false
        );
      }
    });
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

    // Calculate pagination
    const itemsPerPage = 16;
    final totalPages = (filtered.length / itemsPerPage).ceil();
    final validCurrentPage = state.currentPage > totalPages
        ? (totalPages > 0 ? totalPages : 1)
        : state.currentPage;

    // Apply pagination to limit items shown
    final startIndex = (validCurrentPage - 1) * itemsPerPage;
    final endIndex = startIndex + itemsPerPage;

    // Create paged list - but ensure we don't exceed the bounds
    final pagedList = startIndex < filtered.length
        ? filtered.sublist(
            startIndex, endIndex > filtered.length ? filtered.length : endIndex)
        : <CharacterViewModel>[];

    // Update filtered list with paginated results
    state = state.copyWith(
      filteredCharacters: pagedList,
      totalPages: totalPages > 0 ? totalPages : 1,
      currentPage: validCurrentPage,
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
