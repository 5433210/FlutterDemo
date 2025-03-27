import 'package:demo/application/services/character/character_persistence_service.dart';
import 'package:demo/presentation/providers/work_detail_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/repository_providers.dart';
import '../../../domain/repositories/character_repository.dart';
import '../../viewmodels/states/character_grid_state.dart';
import '../../widgets/character_collection/filter_type.dart';

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

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  Future<void> deleteSelected() async {
    try {
      state = state.copyWith(loading: true, error: null);

      // 删除所选字符
      await _repository.deleteBatch(state.selectedIds.toList());

      // 重新加载数据
      await loadCharacters();

      // 清除选择
      clearSelection();
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> exportSelected() async {
    // 导出功能实现
    // 这里需要调用导出服务
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
    final selectedIds = Set<String>.from(state.selectedIds);
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }

    state = state.copyWith(selectedIds: selectedIds);
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

    // 应用搜索条件
    if (state.searchTerm.isNotEmpty) {
      filtered = filtered
          .where((char) => char.character.contains(state.searchTerm))
          .toList();
    }

    // 应用筛选类型
    switch (state.filterType) {
      case FilterType.recent:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case FilterType.modified:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case FilterType.favorite:
        filtered = filtered.where((char) => char.isFavorite).toList();
        break;
      case FilterType.byStroke:
        // 这里需要调用笔画排序服务
        break;
      case FilterType.custom:
        // 自定义排序
        break;
      case FilterType.all:
      default:
        // 默认排序
        break;
    }

    // 计算分页
    const itemsPerPage = 16;
    final totalPages = (filtered.length / itemsPerPage).ceil();

    // 应用分页
    final startIndex = (state.currentPage - 1) * itemsPerPage;
    if (startIndex < filtered.length) {
      final endIndex = startIndex + itemsPerPage < filtered.length
          ? startIndex + itemsPerPage
          : filtered.length;
      filtered = filtered.sublist(startIndex, endIndex);
    } else {
      filtered = [];
    }

    state = state.copyWith(
      filteredCharacters: filtered,
      totalPages: totalPages > 0 ? totalPages : 1,
      currentPage: state.currentPage > totalPages ? 1 : state.currentPage,
    );
  }
}
