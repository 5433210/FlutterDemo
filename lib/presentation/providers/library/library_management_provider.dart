import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/service_providers.dart';
import '../../../application/services/library_service.dart';
import '../../../domain/entities/library_category.dart';
import '../../../domain/entities/library_item.dart';
import '../../../infrastructure/cache/services/image_cache_service.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../infrastructure/providers/cache_providers.dart' as cache;
import '../../../infrastructure/services/character_image_service.dart';
import '../../viewmodels/states/library_management_state.dart';

/// 图库管理状态提供者
final libraryManagementProvider =
    StateNotifierProvider<LibraryManagementNotifier, LibraryManagementState>(
  (ref) => LibraryManagementNotifier(
    service: ref.watch(libraryServiceProvider),
    characterImageService: ref.watch(characterImageServiceProvider),
    imageCacheService: ref.watch(cache.imageCacheServiceProvider),
  ),
);

/// 图库管理状态通知器
class LibraryManagementNotifier extends StateNotifier<LibraryManagementState> {
  final LibraryService _service;
  final CharacterImageService _characterImageService;
  final ImageCacheService _imageCacheService;

  // 添加一个分类计数的本地变量
  Map<String, int> _categoryItemCounts = {};

  LibraryManagementNotifier({
    required LibraryService service,
    required CharacterImageService characterImageService,
    required ImageCacheService imageCacheService,
  })  : _service = service,
        _characterImageService = characterImageService,
        _imageCacheService = imageCacheService,
        super(const LibraryManagementState()) {
    // 初始化时加载分类数据
    _initializeData();
  }
  // 提供一个getter方法来获取分类计数
  Map<String, int> get categoryItemCounts => _categoryItemCounts;

  /// 添加分类
  Future<void> addCategory(LibraryCategory category) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _service.addCategory(category);
      await _reloadCategories();
      await loadCategoryItemCounts();
    } catch (e) {
      AppLogger.error('添加分类失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 为项目批量添加分类
  Future<void> addCategoryToItems(
      String categoryId, List<String> itemIds) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      for (final itemId in itemIds) {
        // 获取项目
        final item = await _service.getItem(itemId);
        if (item != null) {
          // 如果项目没有此分类，则添加
          if (!item.categories.contains(categoryId)) {
            final updatedCategories = [...item.categories, categoryId];
            final updatedItem = item.copyWith(
              categories: updatedCategories,
              fileUpdatedAt: DateTime.now(),
            );

            // 更新项目
            await _service.updateItem(updatedItem);
          }
        }
      }

      // 刷新数据
      await loadData();
      await loadCategoryItemCounts();
    } catch (e) {
      AppLogger.error('批量添加分类失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 批量将项目添加到分类
  Future<void> addItemsToCategory(
      List<String> itemIds, String categoryId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      for (final itemId in itemIds) {
        // 获取项目
        final item = await _service.getItem(itemId);
        if (item != null && !item.categories.contains(categoryId)) {
          // 添加新分类
          final updatedCategories = [...item.categories, categoryId];
          final updatedItem = item.copyWith(
            categories: updatedCategories,
            fileUpdatedAt: DateTime.now(),
          );

          // 更新项目
          await _service.updateItem(updatedItem);
        }
      }

      // 刷新数据
      await loadData();
      await loadCategoryItemCounts();

      // 成功提示
      AppLogger.info('批量添加项目到分类完成', data: {
        'itemCount': itemIds.length,
        'categoryId': categoryId,
      });
    } catch (e) {
      AppLogger.error('批量添加项目到分类失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 将项目添加到分类
  Future<void> addItemToCategory(String itemId, String categoryId) async {
    try {
      // 获取项目
      final item = await _service.getItem(itemId);
      if (item != null) {
        // 检查项目是否已经在分类中
        if (!item.categories.contains(categoryId)) {
          // 添加新分类
          final updatedCategories = [...item.categories, categoryId];
          final updatedItem = item.copyWith(
            categories: updatedCategories,
            fileUpdatedAt: DateTime.now(),
          );

          // 更新项目
          await _service.updateItem(updatedItem);

          // 如果是当前选中的项目，更新状态
          if (state.selectedItem?.id == itemId) {
            state = state.copyWith(selectedItem: updatedItem);
          }

          // 更新列表中的项目
          final updatedItems =
              state.items.map((i) => i.id == itemId ? updatedItem : i).toList();

          state = state.copyWith(items: updatedItems);
        }
      }

      // 刷新数据
      await loadData();
      await loadCategoryItemCounts();

      // 成功提示
      AppLogger.info('项目已添加到分类', data: {
        'itemId': itemId,
        'categoryId': categoryId,
      });
    } catch (e) {
      AppLogger.error('添加项目到分类失败', error: e);
      state = state.copyWith(
        errorMessage: e.toString(),
      );
    }
  }

  /// 刷新数据（按当前筛选条件重新查询）
  Future<void> refresh() async {
    await loadData();
    await loadCategoryItemCounts();
  }

  /// 切换页面
  void changePage(int page) {
    state = state.copyWith(currentPage: page);
    loadData();
  }

  /// 清除所有选中状态
  void clearSelection() {
    state = state.copyWith(
      selectedItems: {},
      selectedItem: null,
    );
  }

  /// 关闭详情面板
  void closeDetailPanel() {
    state = state.copyWith(
      isDetailOpen: false,
      selectedItem: null,
    );
  }

  /// 复制选中的项目到剪贴板
  /// 如果是批量模式下选择了多个项目，则复制所有选中的项目ID
  /// 如果不是批量模式，则复制当前选中的项目ID
  Future<void> copySelectedItemsToClipboard() async {
    try {
      List<String> itemIds = [];

      // 批量模式下，复制所有选中的项目ID
      if (state.isBatchMode && state.selectedItems.isNotEmpty) {
        itemIds = state.selectedItems.toList();
      }
      // 非批量模式下，复制当前选中的项目ID（如果有）
      else if (state.selectedItem != null) {
        itemIds = [state.selectedItem!.id];
      }

      // 如果没有选中的项目，直接返回
      if (itemIds.isEmpty) return;

      // 查找对应的 LibraryItem 对象
      final selectedItems =
          state.items.where((item) => itemIds.contains(item.id)).toList();

      if (selectedItems.isEmpty) return;

      // 异步预加载相关的字符图像到缓存，不阻塞复制操作
      _preloadLibraryItemImages(selectedItems);

      // 将项目列表转换为 JSON 格式并写入剪贴板
      final Map<String, dynamic> clipboardData = {
        'type': 'library_items',
        'operation': 'copy',
        'count': selectedItems.length,
        'itemIds': itemIds,
      };

      final String jsonData = jsonEncode(clipboardData);
      await Clipboard.setData(ClipboardData(text: jsonData));

      AppLogger.info('Copied ${itemIds.length} library item(s) to clipboard');
    } catch (e) {
      AppLogger.error('Failed to copy library items to clipboard: $e');
      state = state.copyWith(
          errorMessage: 'Failed to copy library items to clipboard');
    }
  }

  /// 剪切选中的项目到剪贴板
  /// 与复制功能类似，但标记为剪切操作
  Future<void> cutSelectedItemsToClipboard() async {
    try {
      List<String> itemIds = [];

      // 批量模式下，复制所有选中的项目ID
      if (state.isBatchMode && state.selectedItems.isNotEmpty) {
        itemIds = state.selectedItems.toList();
      }
      // 非批量模式下，复制当前选中的项目ID（如果有）
      else if (state.selectedItem != null) {
        itemIds = [state.selectedItem!.id];
      }

      // 如果没有选中的项目，直接返回
      if (itemIds.isEmpty) return;

      // 查找对应的 LibraryItem 对象
      final selectedItems =
          state.items.where((item) => itemIds.contains(item.id)).toList();

      if (selectedItems.isEmpty) return;

      // 异步预加载相关的字符图像到缓存，不阻塞剪切操作
      _preloadLibraryItemImages(selectedItems);

      // 将项目列表转换为 JSON 格式并写入剪贴板
      final Map<String, dynamic> clipboardData = {
        'type': 'library_items',
        'operation': 'cut',
        'count': selectedItems.length,
        'itemIds': itemIds,
      };

      final String jsonData = jsonEncode(clipboardData);
      await Clipboard.setData(ClipboardData(text: jsonData));

      AppLogger.info('Cut ${itemIds.length} library item(s) to clipboard');
    } catch (e) {
      AppLogger.error('Failed to cut library items to clipboard: $e');
      state = state.copyWith(
          errorMessage: 'Failed to cut library items to clipboard');
    }
  }

  /// 删除当前筛选条件下的所有项目
  Future<void> deleteAllItemsUnderFilter() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 获取当前筛选条件下的所有项目ID
      final itemsToDelete = state.items;

      // 如果当前详情页项目也会被删除，关闭详情面板
      final selectedItemId = state.selectedItem?.id;
      bool shouldCloseDetailPanel = false;

      if (selectedItemId != null) {
        // 检查当前选中的项目是否在将被删除的列表中
        shouldCloseDetailPanel =
            itemsToDelete.any((item) => item.id == selectedItemId);
      }

      // 删除所有项目
      for (final item in itemsToDelete) {
        await _service.deleteItem(item.id);
      }

      // 更新状态
      if (shouldCloseDetailPanel) {
        state = state.copyWith(
          selectedItems: {},
          isBatchMode: false,
          selectedItem: null,
          isDetailOpen: false,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          selectedItems: {},
          isBatchMode: false,
          isLoading: false,
        );
      }

      // 重新加载数据
      await loadData();
      await loadCategoryItemCounts();

      AppLogger.info('已删除所有筛选条件下的项目', data: {
        'deletedCount': itemsToDelete.length,
      });
    } catch (e) {
      AppLogger.error('删除所有项目失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 删除分类（不删除文件）
  Future<void> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 获取此分类及所有子分类的ID
      final categoryIds = _getAllSubcategoryIds(id);

      // 删除所有分类（先删除子分类，再删除父分类）
      for (final categoryId in categoryIds.reversed) {
        await _service.deleteCategory(categoryId);
      }

      // 如果当前选中的分类被删除，清除选择
      if (categoryIds.contains(state.selectedCategoryId)) {
        state = state.copyWith(selectedCategoryId: null);
      }

      await _reloadCategories();
      await loadCategoryItemCounts();

      // 刷新数据，以更新项目列表
      await loadData();
    } catch (e) {
      AppLogger.error('删除分类失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 删除分类和文件
  Future<void> deleteCategoryWithFiles(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 获取此分类及所有子分类的ID
      final categoryIds = _getAllSubcategoryIds(id);

      // 获取这些分类中的所有文件
      final itemsToDelete = <String>[];
      for (final category in state.items) {
        if (category.categories.any((catId) => categoryIds.contains(catId))) {
          itemsToDelete.add(category.id);
        }
      }

      // 删除所有文件
      for (final itemId in itemsToDelete) {
        await _service.deleteItem(itemId);
      }

      // 删除所有分类（先删除子分类，再删除父分类）
      for (final categoryId in categoryIds.reversed) {
        await _service.deleteCategory(categoryId);
      }

      // 如果当前选中的分类被删除，清除选择
      if (categoryIds.contains(state.selectedCategoryId)) {
        state = state.copyWith(selectedCategoryId: null);
      }

      await _reloadCategories();
      await loadCategoryItemCounts();

      // 刷新数据，以更新项目列表
      await loadData();
    } catch (e) {
      AppLogger.error('删除分类和文件失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 删除项目
  Future<void> deleteItem(String itemId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 如果删除的是当前选中的项目，关闭详情面板
      if (state.selectedItem?.id == itemId) {
        state = state.copyWith(
          selectedItem: null,
          isDetailOpen: false,
        );
      }

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
      final selectedItems = state.selectedItems;
      final selectedItemId = state.selectedItem?.id;

      // 删除选中的项目
      for (final itemId in selectedItems) {
        await _service.deleteItem(itemId);
      }

      // 如果当前选中的项目被删除，关闭详情面板
      if (selectedItemId != null && selectedItems.contains(selectedItemId)) {
        state = state.copyWith(
          selectedItems: {},
          isBatchMode: false,
          selectedItem: null,
          isDetailOpen: false,
        );
      } else {
        state = state.copyWith(
          selectedItems: {},
          isBatchMode: false,
        );
      }

      await loadData();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 加载分类统计数据
  Future<void> loadCategoryItemCounts() async {
    try {
      _categoryItemCounts = await _service.getCategoryItemCounts();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      AppLogger.error('加载分类统计数据失败', error: e);
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
        filteredItems = filteredItems
            .where((item) => item.fileSize >= state.minSize!)
            .toList();
      }
      if (state.maxSize != null) {
        filteredItems = filteredItems
            .where((item) => item.fileSize <= state.maxSize!)
            .toList();
      }

      // 应用日期过滤
      if (state.createStartDate != null) {
        filteredItems = filteredItems
            .where((item) =>
                item.fileCreatedAt.isAfter(state.createStartDate!) ||
                item.fileCreatedAt.isAtSameMomentAs(state.createStartDate!))
            .toList();
      }
      if (state.createEndDate != null) {
        final endDate = DateTime(state.createEndDate!.year,
            state.createEndDate!.month, state.createEndDate!.day, 23, 59, 59);
        filteredItems = filteredItems
            .where((item) =>
                item.fileCreatedAt.isBefore(endDate) ||
                item.fileCreatedAt.isAtSameMomentAs(endDate))
            .toList();
      }
      if (state.updateStartDate != null) {
        filteredItems = filteredItems
            .where((item) =>
                item.fileUpdatedAt.isAfter(state.updateStartDate!) ||
                item.fileUpdatedAt.isAtSameMomentAs(state.updateStartDate!))
            .toList();
      }
      if (state.updateEndDate != null) {
        final endDate = DateTime(state.updateEndDate!.year,
            state.updateEndDate!.month, state.updateEndDate!.day, 23, 59, 59);
        filteredItems = filteredItems
            .where((item) =>
                item.fileUpdatedAt.isBefore(endDate) ||
                item.fileUpdatedAt.isAtSameMomentAs(endDate))
            .toList();
      }
      final totalCount = await _service.getItemCount(
        categories: categories,
        searchQuery: state.searchQuery,
      );

      final categoryTree = await _service.getCategoryTree();

      // 加载分类统计数据
      await loadCategoryItemCounts();

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

  /// 打开详情面板
  void openDetailPanel() {
    // 如果已经选择了项目，确保详情面板打开
    if (state.selectedItem != null) {
      state = state.copyWith(isDetailOpen: true);
    }
  }

  /// 从项目中移除分类
  Future<void> removeCategoryFromItems(
      String categoryId, List<String> itemIds) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      for (final itemId in itemIds) {
        // 获取项目
        final item = await _service.getItem(itemId);
        if (item != null) {
          // 如果项目有此分类，则移除
          if (item.categories.contains(categoryId)) {
            final updatedCategories =
                item.categories.where((id) => id != categoryId).toList();
            final updatedItem = item.copyWith(
              categories: updatedCategories,
              fileUpdatedAt: DateTime.now(),
            );

            // 更新项目
            await _service.updateItem(updatedItem);
          }
        }
      }

      // 刷新数据
      await loadData();
      await loadCategoryItemCounts();
    } catch (e) {
      AppLogger.error('批量移除分类失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 从当前分类中移除选中的项目
  Future<void> removeSelectedItemsFromCategory(String categoryId) async {
    if (state.selectedItems.isEmpty || categoryId.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await removeCategoryFromItems(categoryId, state.selectedItems.toList());

      // 如果当前选中的是将被修改的项目，更新其状态
      if (state.selectedItem != null &&
          state.selectedItems.contains(state.selectedItem!.id)) {
        final updatedItem = await _service.getItem(state.selectedItem!.id);
        if (updatedItem != null) {
          state = state.copyWith(selectedItem: updatedItem);
        }
      }

      AppLogger.info('已从分类中移除选中项目', data: {
        'categoryId': categoryId,
        'itemCount': state.selectedItems.length,
      });
    } catch (e) {
      AppLogger.error('从分类中移除项目失败', error: e);
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

  /// 重置所有筛选器
  Future<void> resetFilters() async {
    state = state.copyWith(
      typeFilter: null,
      formatFilter: null,
      showFavoritesOnly: false,
      selectedCategoryId: null,
      sortBy: 'fileName',
      sortDesc: false,
      isLoading: true,
      errorMessage: null,
    );

    try {
      await loadData();
    } catch (e) {
      AppLogger.error('重置筛选器失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// 搜索分类
  List<LibraryCategory> searchCategories(String query) {
    if (query.isEmpty) {
      return state.categoryTree;
    }

    query = query.toLowerCase();
    List<LibraryCategory> results = [];

    void searchInCategory(LibraryCategory category) {
      if (category.name.toLowerCase().contains(query)) {
        results.add(category);
      }
      for (var child in category.children) {
        searchInCategory(child);
      }
    }

    for (var category in state.categoryTree) {
      searchInCategory(category);
    }

    return results;
  }

  /// 选择当前筛选条件下的所有项目
  void selectAllItems() {
    if (state.items.isEmpty) {
      return;
    }

    // 如果不是批量模式，先进入批量模式
    final newState =
        !state.isBatchMode ? state.copyWith(isBatchMode: true) : state;

    // 将所有当前筛选条件下的项目都添加到选中集合中
    final allItemIds = state.items.map((item) => item.id).toSet();

    state = newState.copyWith(selectedItems: allItemIds);

    AppLogger.info('已选择所有项目', data: {
      'selectedCount': allItemIds.length,
    });
  }

  /// 选择分类
  void selectCategory(String? categoryId) {
    // If in batch mode, clear the selected items when changing category
    if (state.isBatchMode && state.selectedCategoryId != categoryId) {
      state = state.copyWith(
        selectedCategoryId: categoryId,
        currentPage: 1,
        selectedItems: {}, // Clear selected items when changing category in batch mode
      );
    } else {
      state = state.copyWith(
        selectedCategoryId: categoryId,
        currentPage: 1,
      );
    }
    loadData().then((_) => loadCategoryItemCounts());
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

  /// 设置详情面板显示的项目
  void setDetailItem(LibraryItem item) {
    state = state.copyWith(
      selectedItem: item,
      isDetailOpen: true,
    );
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

  /// 设置搜索查询
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query, currentPage: 1);
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

  /// 设置排序
  Future<void> setSortBy(String field, bool descending) async {
    state = state.copyWith(
      sortBy: field,
      sortDesc: descending,
      isLoading: true,
      errorMessage: null,
    );

    try {
      await loadData();
    } catch (e) {
      AppLogger.error('设置排序失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
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
    final newBatchMode = !state.isBatchMode;

    // 如果退出批量模式，清空选择
    final newSelectedItems = newBatchMode ? state.selectedItems : <String>{};

    state = state.copyWith(
      isBatchMode: newBatchMode,
      selectedItems: newSelectedItems,
    );
  }

  /// 切换项目的收藏状态
  Future<void> toggleFavorite(String id) async {
    try {
      // Call library service to toggle favorite status
      await _service.toggleFavorite(id);

      // Update the item in the list
      final updatedItems = state.items.map((item) {
        if (item.id == id) {
          return item.copyWith(isFavorite: !item.isFavorite);
        }
        return item;
      }).toList();

      // If this is the selected item, update it in the state
      final selectedItem = state.selectedItem;
      if (selectedItem != null && selectedItem.id == id) {
        state = state.copyWith(
          items: updatedItems,
          selectedItem:
              selectedItem.copyWith(isFavorite: !selectedItem.isFavorite),
        );
      } else {
        state = state.copyWith(items: updatedItems);
      }
    } catch (e) {
      AppLogger.error('切换收藏状态失败', error: e);
      state = state.copyWith(
        errorMessage: e.toString(),
      );
    }
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

  /// 切换图片预览面板的可见性
  void toggleImagePreviewPanel() {
    // The state now has isImagePreviewOpen properly defined
    state = state.copyWith(
      isImagePreviewOpen: !state.isImagePreviewOpen,
    );
  }

  /// 切换项目选择状态
  void toggleItemSelection(String itemId) {
    final newSelectedItems = Set<String>.from(state.selectedItems);

    if (newSelectedItems.contains(itemId)) {
      newSelectedItems.remove(itemId);
    } else {
      newSelectedItems.add(itemId);
    }

    state = state.copyWith(selectedItems: newSelectedItems);
  }

  /// 切换视图模式
  void toggleViewMode() {
    final newViewMode =
        state.viewMode == ViewMode.grid ? ViewMode.list : ViewMode.grid;

    state = state.copyWith(viewMode: newViewMode);
  }

  /// 更新分类
  Future<void> updateCategory(LibraryCategory category) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _service.updateCategory(category);
      await _reloadCategories();
      await loadCategoryItemCounts();
    } catch (e) {
      AppLogger.error('更新分类失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
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

  /// 更新项目分类列表（完全替换）
  Future<void> updateItemCategories(
      String itemId, List<String> categories) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 获取项目
      final item = await _service.getItem(itemId);
      if (item != null) {
        // 完全替换分类
        final updatedItem = item.copyWith(
          categories: categories,
          fileUpdatedAt: DateTime.now(),
        );

        // 更新项目
        await _service.updateItem(updatedItem);

        // 如果是当前选中的项目，更新状态
        if (state.selectedItem?.id == itemId) {
          state = state.copyWith(selectedItem: updatedItem);
        }

        // 更新列表中的项目
        final updatedItems =
            state.items.map((i) => i.id == itemId ? updatedItem : i).toList();

        state = state.copyWith(items: updatedItems);
      }

      // 刷新数据
      await loadData();
      await loadCategoryItemCounts();

      // 成功提示
      AppLogger.info('更新项目分类', data: {
        'itemId': itemId,
        'categories': categories,
      });
    } catch (e) {
      AppLogger.error('更新项目分类失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
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

  /// 获取指定分类及其所有子分类的ID列表
  List<String> _getAllSubcategoryIds(String categoryId) {
    final result = <String>[categoryId];

    // 查找所有直接子分类
    void findChildren(String parentId) {
      final children = state.categories
          .where((category) => category.parentId == parentId)
          .toList();

      for (final child in children) {
        result.add(child.id);
        findChildren(child.id); // 递归查找子分类的子分类
      }
    }

    findChildren(categoryId);
    return result;
  }

  /// 初始化数据
  Future<void> _initializeData() async {
    await _reloadCategories();
    await loadCategoryItemCounts();
    loadData();
  }

  /// 预加载图像文件
  Future<void> _preloadImageFile(String imagePath) async {
    try {
      final cacheKey = 'file:$imagePath';

      // 尝试通过图像缓存服务预加载文件
      await _imageCacheService.getBinaryImage(cacheKey);
      AppLogger.debug('Preloaded image file: $imagePath');
    } catch (e) {
      AppLogger.debug('Failed to preload image file $imagePath: $e');
    }
  }

  /// 预加载图库项目相关的图像到缓存
  void _preloadLibraryItemImages(List<LibraryItem> items) {
    Future.microtask(() async {
      try {
        AppLogger.info(
            'Starting preload of images for ${items.length} library items');

        final preloadTasks = <Future<void>>[];

        for (final item in items) {
          // 根据不同类型的图库项目预加载相应的图像
          if (item.type == 'character') {
            // 对于字符类型的项目，尝试从metadata中获取字符ID
            final characterId = item.metadata['characterId'] as String?;
            if (characterId != null && characterId.isNotEmpty) {
              preloadTasks.addAll([
                _preloadSingleCharacterImage(
                    characterId, 'square-binary', 'png-binary'),
                _preloadSingleCharacterImage(
                    characterId, 'thumbnail', 'png-binary'),
                _preloadSingleCharacterImage(
                    characterId, 'binary', 'png-binary'),
              ]);
            }
          } else if (item.type == 'image' && item.path.isNotEmpty) {
            // 为图像类型的项目预加载图像文件
            preloadTasks.add(_preloadImageFile(item.path));
          }

          // 预加载缩略图（如果存在）
          if (item.thumbnail != null) {
            preloadTasks.add(_preloadThumbnail(item.id, item.thumbnail!));
          }
        }

        // 并行执行所有预加载任务
        await Future.wait(preloadTasks);

        AppLogger.info('Completed preloading images for library items');
      } catch (e) {
        AppLogger.error('Error preloading library item images: $e');
      }
    });
  }

  /// 预加载单个字符图像
  Future<void> _preloadSingleCharacterImage(
      String characterId, String type, String format) async {
    try {
      // 获取二进制图像数据并缓存
      final imageData = await _characterImageService.getCharacterImage(
          characterId, type, format);

      if (imageData != null) {
        // 生成UI图像缓存键
        final cacheKey = 'char_$characterId'; // 使用默认字体大小

        // 将二进制数据解码为UI图像并缓存
        try {
          final completer = Completer<ui.Image>();
          ui.decodeImageFromList(imageData, completer.complete);
          final uiImage = await completer.future;

          await _imageCacheService.cacheUiImage(cacheKey, uiImage);
          AppLogger.debug(
              'Cached UI image for character $characterId with key $cacheKey');
        } catch (decodeError) {
          AppLogger.debug(
              'Failed to decode UI image for character $characterId: $decodeError');
        }
      }
    } catch (e) {
      AppLogger.debug(
          'Failed to preload image for character $characterId ($type): $e');
    }
  }

  /// 预加载缩略图
  Future<void> _preloadThumbnail(String itemId, Uint8List thumbnailData) async {
    try {
      final cacheKey = 'thumbnail_$itemId';

      // 缓存缩略图的二进制数据
      await _imageCacheService.cacheBinaryImage(cacheKey, thumbnailData);

      // 尝试解码并缓存UI图像
      try {
        final completer = Completer<ui.Image>();
        ui.decodeImageFromList(thumbnailData, completer.complete);
        final uiImage = await completer.future;

        await _imageCacheService.cacheUiImage(cacheKey, uiImage);
        AppLogger.debug('Cached thumbnail UI image for item $itemId');
      } catch (decodeError) {
        AppLogger.debug(
            'Failed to decode thumbnail for item $itemId: $decodeError');
      }
    } catch (e) {
      AppLogger.debug('Failed to preload thumbnail for item $itemId: $e');
    }
  }

  /// 重新加载分类数据
  Future<void> _reloadCategories() async {
    try {
      final categories = await _service.getCategories();
      final categoryTree = await _service.getCategoryTree();

      state = state.copyWith(
        categories: categories,
        categoryTree: categoryTree,
        isLoading: false,
      );
    } catch (e) {
      AppLogger.error('加载分类数据失败', error: e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}
