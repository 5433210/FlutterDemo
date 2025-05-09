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
      // 构建查询参数
      String? type = state.typeFilter;
      List<String>? categories =
          state.selectedCategoryId != null ? [state.selectedCategoryId!] : null;

      // 处理标签过滤
      List<String>? tags;

      // 处理收藏状态
      // 注意：这里需要修改库存储库以支持收藏过滤
      // 目前先通过内存筛选实现

      final result = await _service.getItems(
        type: type,
        categories: categories,
        tags: tags,
        searchQuery: state.searchQuery,
        page: state.currentPage,
        pageSize: state.pageSize,
        sortBy: state.sortBy,
        sortDesc: state.sortDesc,
      );

      // 如果选择了只显示收藏，在内存中筛选
      List<LibraryItem> filteredItems = result.items;
      if (state.showFavoritesOnly) {
        filteredItems = filteredItems.where((item) => item.isFavorite).toList();
      }

      // 应用格式过滤
      if (state.formatFilter != null && state.formatFilter!.isNotEmpty) {
        filteredItems = filteredItems
            .where((item) =>
                item.format.toLowerCase() == state.formatFilter!.toLowerCase())
            .toList();
      }

      // 应用尺寸过滤
      if (state.minWidth != null) {
        filteredItems = filteredItems
            .where((item) => item.width >= state.minWidth!)
            .toList();
      }
      if (state.maxWidth != null) {
        filteredItems = filteredItems
            .where((item) => item.width <= state.maxWidth!)
            .toList();
      }
      if (state.minHeight != null) {
        filteredItems = filteredItems
            .where((item) => item.height >= state.minHeight!)
            .toList();
      }
      if (state.maxHeight != null) {
        filteredItems = filteredItems
            .where((item) => item.height <= state.maxHeight!)
            .toList();
      }

      // 应用文件大小过滤
      if (state.minSize != null) {
        filteredItems =
            filteredItems.where((item) => item.size >= state.minSize!).toList();
      }
      if (state.maxSize != null) {
        filteredItems =
            filteredItems.where((item) => item.size <= state.maxSize!).toList();
      }

      // 应用日期过滤
      if (state.createStartDate != null) {
        filteredItems = filteredItems
            .where((item) =>
                item.createdAt.isAfter(state.createStartDate!) ||
                item.createdAt.isAtSameMomentAs(state.createStartDate!))
            .toList();
      }
      if (state.createEndDate != null) {
        final endDate = DateTime(state.createEndDate!.year,
            state.createEndDate!.month, state.createEndDate!.day, 23, 59, 59);
        filteredItems = filteredItems
            .where((item) =>
                item.createdAt.isBefore(endDate) ||
                item.createdAt.isAtSameMomentAs(endDate))
            .toList();
      }
      if (state.updateStartDate != null) {
        filteredItems = filteredItems
            .where((item) =>
                item.updatedAt.isAfter(state.updateStartDate!) ||
                item.updatedAt.isAtSameMomentAs(state.updateStartDate!))
            .toList();
      }
      if (state.updateEndDate != null) {
        final endDate = DateTime(state.updateEndDate!.year,
            state.updateEndDate!.month, state.updateEndDate!.day, 23, 59, 59);
        filteredItems = filteredItems
            .where((item) =>
                item.updatedAt.isBefore(endDate) ||
                item.updatedAt.isAtSameMomentAs(endDate))
            .toList();
      }

      final totalCount = await _service.getItemCount(
        categories: categories,
        searchQuery: state.searchQuery,
      );

      final categoryTree = await _service.getCategoryTree();

      state = state.copyWith(
        items: filteredItems,
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

  /// 重置所有筛选条件
  void resetAllFilters() {
    state = state.copyWith(
      typeFilter: null,
      showFavoritesOnly: false,
      formatFilter: null,
      minWidth: null,
      maxWidth: null,
      minHeight: null,
      maxHeight: null,
      minSize: null,
      maxSize: null,
      createStartDate: null,
      createEndDate: null,
      updateStartDate: null,
      updateEndDate: null,
      currentPage: 1,
    );
    loadData();
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

  /// 设置创建时间范围
  void setCreateTimeRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      createStartDate: startDate,
      createEndDate: endDate,
      currentPage: 1,
    );
    loadData();
  }

  /// 设置图片格式筛选
  void setFormatFilter(String? format) {
    state = state.copyWith(formatFilter: format, currentPage: 1);
    loadData();
  }

  /// 设置高度范围
  void setHeightRange(int? minHeight, int? maxHeight) {
    state = state.copyWith(
      minHeight: minHeight,
      maxHeight: maxHeight,
      currentPage: 1,
    );
    loadData();
  }

  /// 设置文件大小范围
  void setSizeRange(int? minSize, int? maxSize) {
    state = state.copyWith(
      minSize: minSize,
      maxSize: maxSize,
      currentPage: 1,
    );
    loadData();
  }

  /// 设置类型筛选
  void setTypeFilter(String? type) {
    state = state.copyWith(typeFilter: type, currentPage: 1);
    loadData();
  }

  /// 设置更新时间范围
  void setUpdateTimeRange(DateTime? startDate, DateTime? endDate) {
    state = state.copyWith(
      updateStartDate: startDate,
      updateEndDate: endDate,
      currentPage: 1,
    );
    loadData();
  }

  /// 设置宽度范围
  void setWidthRange(int? minWidth, int? maxWidth) {
    state = state.copyWith(
      minWidth: minWidth,
      maxWidth: maxWidth,
      currentPage: 1,
    );
    loadData();
  }

  /// 切换批量选择模式
  void toggleBatchMode() {
    state = state.copyWith(
      isBatchMode: !state.isBatchMode,
      selectedItems: {},
    );
  }

  /// 切换是否只显示收藏
  void toggleFavoritesOnly() {
    state = state.copyWith(
        showFavoritesOnly: !state.showFavoritesOnly, currentPage: 1);
    loadData();
  }

  /// 切换筛选面板显示状态
  void toggleFilterPanel() {
    state = state.copyWith(showFilterPanel: !state.showFilterPanel);
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
