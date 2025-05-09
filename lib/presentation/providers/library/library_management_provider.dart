import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../application/services/library_service.dart';
import '../../../domain/entities/library_item.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../viewmodels/states/library_management_state.dart';

/// 图库管理状态提供者
final libraryManagementProvider =
    StateNotifierProvider<LibraryManagementNotifier, LibraryManagementState>(
  (ref) => LibraryManagementNotifier(
    service: ref.watch(libraryServiceProvider),
  ),
);

/// 图库管理状态通知器
class LibraryManagementNotifier extends StateNotifier<LibraryManagementState> {
  final LibraryService _service;

  LibraryManagementNotifier({
    required LibraryService service,
  })  : _service = service,
        super(const LibraryManagementState());

  /// 切换页面
  void changePage(int page) {
    state = state.copyWith(currentPage: page);
    loadData();
  }

  /// 关闭详情面板
  void closeDetailPanel() {
    state = state.copyWith(
      isDetailOpen: false,
      selectedItem: null,
    );
  }

  /// 删除项目
  Future<void> deleteItem(String itemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _service.deleteItem(itemId);
      await loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 删除选中的项目
  Future<void> deleteSelectedItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      for (final itemId in state.selectedItems) {
        await _service.deleteItem(itemId);
      }
      state = state.copyWith(
        selectedItems: {},
        isBatchMode: false,
      );
      await loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 加载数据
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _service.getItems(
        categories: state.selectedCategoryId != null
            ? [state.selectedCategoryId!]
            : null,
        searchQuery: state.searchQuery,
        page: state.currentPage,
        pageSize: state.pageSize,
        sortBy: state.sortBy,
        sortDesc: state.sortDesc,
      );

      final totalCount = await _service.getItemCount(
        categories: state.selectedCategoryId != null
            ? [state.selectedCategoryId!]
            : null,
        searchQuery: state.searchQuery,
      );

      final categoryTree = await _service.getCategoryTree();

      state = state.copyWith(
        items: result.items,
        totalCount: totalCount,
        categoryTree: categoryTree,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 选择分类
  void selectCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      currentPage: 1,
    );
    loadData();
  }

  /// 选择项目
  void selectItem(String itemId) {
    final item = state.items.firstWhere((item) => item.id == itemId);
    state = state.copyWith(
      selectedItem: item,
      isDetailOpen: true,
    );
  }

  /// 切换批量选择模式
  void toggleBatchMode() {
    state = state.copyWith(
      isBatchMode: !state.isBatchMode,
      selectedItems: {},
    );
  }

  /// 切换项目选择状态
  void toggleItemSelection(String itemId) {
    final selectedItems = Set<String>.from(state.selectedItems);
    if (selectedItems.contains(itemId)) {
      selectedItems.remove(itemId);
    } else {
      selectedItems.add(itemId);
    }
    state = state.copyWith(selectedItems: selectedItems);
  }

  /// 切换视图模式
  void toggleViewMode() {
    state = state.copyWith(
      viewMode: state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid,
    );
  }

  /// 更新项目
  Future<void> updateItem(LibraryItem item) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _service.updateItem(item);

      // If this is the current selected item, update it in the state
      if (state.selectedItem?.id == item.id) {
        state = state.copyWith(selectedItem: item);
      }

      // Update the item in the items list
      final updatedItems =
          state.items.map((i) => i.id == item.id ? item : i).toList();

      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('Failed to update item', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// 更新每页数量
  void updatePageSize(int pageSize) {
    state = state.copyWith(
      pageSize: pageSize,
      currentPage: 1,
    );
    loadData();
  }

  /// 更新搜索关键词
  void updateSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
    );
    loadData();
  }

  /// 更新排序
  void updateSorting(String sortBy, bool sortDesc) {
    state = state.copyWith(
      sortBy: sortBy,
      sortDesc: sortDesc,
      currentPage: 1,
    );
    loadData();
  }
}
