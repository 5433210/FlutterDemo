import 'package:charasgem/domain/entities/library_category.dart';
import 'package:charasgem/domain/entities/library_item.dart';
import 'package:flutter/foundation.dart';

import '../../application/services/library_service.dart';

class LibraryState {
  final List<LibraryItem> items;
  final List<LibraryCategory> categories;
  final List<LibraryCategory> categoryTree;
  final Map<String, int> categoryItemCounts;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final String? selectedCategoryId;
  final String? searchQuery;
  final String? sortBy;
  final bool sortDesc;

  LibraryState({
    this.items = const [],
    this.categories = const [],
    this.categoryTree = const [],
    this.categoryItemCounts = const {},
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.selectedCategoryId,
    this.searchQuery,
    this.sortBy,
    this.sortDesc = false,
  });

  LibraryState copyWith({
    List<LibraryItem>? items,
    List<LibraryCategory>? categories,
    List<LibraryCategory>? categoryTree,
    Map<String, int>? categoryItemCounts,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    String? selectedCategoryId,
    String? searchQuery,
    String? sortBy,
    bool? sortDesc,
  }) {
    return LibraryState(
      items: items ?? this.items,
      categories: categories ?? this.categories,
      categoryTree: categoryTree ?? this.categoryTree,
      categoryItemCounts: categoryItemCounts ?? this.categoryItemCounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDesc: sortDesc ?? this.sortDesc,
    );
  }
}

class LibraryProvider extends ChangeNotifier {
  final LibraryService _service;
  LibraryState _state = LibraryState();

  LibraryProvider({required LibraryService service}) : _service = service;

  LibraryState get state => _state;

  Future<void> loadItems({
    String? type,
    List<String>? tags,
    String? searchQuery,
    int page = 1,
    String? sortBy,
    bool sortDesc = false,
  }) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final result = await _service.getItems(
        type: type,
        tags: tags,
        categories: _state.selectedCategoryId != null
            ? [_state.selectedCategoryId!]
            : null,
        searchQuery: searchQuery ?? _state.searchQuery,
        page: page,
        sortBy: sortBy ?? _state.sortBy,
        sortDesc: sortDesc,
      );

      final totalCount = await _service.getItemCount(
        type: type,
        tags: tags,
        categories: _state.selectedCategoryId != null
            ? [_state.selectedCategoryId!]
            : null,
        searchQuery: searchQuery ?? _state.searchQuery,
      );

      _state = _state.copyWith(
        items: result.items,
        isLoading: false,
        currentPage: page,
        totalPages: (totalCount / 20).ceil(),
        searchQuery: searchQuery,
        sortBy: sortBy,
        sortDesc: sortDesc,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      final categories = await _service.getCategories();
      final categoryTree = await _service.getCategoryTree();
      final categoryItemCounts = await _service.getCategoryItemCounts();

      _state = _state.copyWith(
        categories: categories,
        categoryTree: categoryTree,
        categoryItemCounts: categoryItemCounts,
        isLoading: false,
      );
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
    notifyListeners();
  }

  Future<void> addItem(LibraryItem item, Uint8List data) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _service.addItem(item);
      await loadItems(page: 1);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> updateItem(LibraryItem item) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _service.updateItem(item);
      await loadItems(page: _state.currentPage);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _service.deleteItem(id);
      await loadItems(page: _state.currentPage);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _service.toggleFavorite(id);
      await loadItems(page: _state.currentPage);
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> addCategory(LibraryCategory category) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _service.addCategory(category);
      await loadCategories();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> updateCategory(LibraryCategory category) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _service.updateCategory(category);
      await loadCategories();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      _state = _state.copyWith(isLoading: true, error: null);
      notifyListeners();

      await _service.deleteCategory(id);
      await loadCategories();
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      notifyListeners();
    }
  }

  void selectCategory(String? categoryId) {
    _state = _state.copyWith(
      selectedCategoryId: categoryId,
      currentPage: 1,
    );
    loadItems(page: 1);
  }

  Future<Uint8List?> getItemData(String id) async {
    try {
      return await _service.getItemData(id);
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      return null;
    }
  }

  Future<Uint8List?> getThumbnail(String id) async {
    try {
      return await _service.getThumbnail(id);
    } catch (e) {
      _state = _state.copyWith(error: e.toString());
      notifyListeners();
      return null;
    }
  }
}
