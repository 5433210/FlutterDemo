import 'dart:typed_data';
import '../../domain/entities/library_item.dart';
import '../../domain/entities/library_category.dart';
import '../../domain/repositories/library_repository.dart';
import '../../infrastructure/cache/services/image_cache_service.dart';

/// 图库服务
class LibraryService {
  final ILibraryRepository _repository;
  final ImageCacheService _imageCache;

  /// 构造函数
  LibraryService({
    required ILibraryRepository repository,
    required ImageCacheService imageCache,
  })  : _repository = repository,
        _imageCache = imageCache;

  /// 获取所有项目
  Future<LibraryQueryResult> getItems({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool sortDesc = false,
  }) async {
    return await _repository.getAll(
      type: type,
      tags: tags,
      categories: categories,
      searchQuery: searchQuery,
      page: page,
      pageSize: pageSize,
      sortBy: sortBy,
      sortDesc: sortDesc,
    );
  }

  /// 获取项目
  Future<LibraryItem?> getItem(String id) async {
    return await _repository.getById(id);
  }

  /// 添加项目
  Future<void> addItem(LibraryItem item) async {
    // 生成缩略图
    if (item.thumbnail == null) {
      final data = await _repository.getItemData(item.id);
      if (data != null) {
        final thumbnail = await _repository.generateThumbnail(data);
        if (thumbnail != null) {
          item = item.copyWith(thumbnail: thumbnail);
        }
      }
    }

    await _repository.add(item);
  }

  /// 更新项目
  Future<void> updateItem(LibraryItem item) async {
    await _repository.update(item);
  }

  /// 删除项目
  Future<void> deleteItem(String id) async {
    await _repository.delete(id);
    await _imageCache.clearAll();
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String id) async {
    await _repository.toggleFavorite(id);
  }

  /// 获取所有标签
  Future<List<String>> getAllTags() async {
    return await _repository.getAllTags();
  }

  /// 获取所有分类
  Future<List<LibraryCategory>> getCategories() async {
    return await _repository.getCategories();
  }

  /// 获取分类树
  Future<List<LibraryCategory>> getCategoryTree() async {
    return await _repository.getCategoryTree();
  }

  /// 添加分类
  Future<void> addCategory(LibraryCategory category) async {
    await _repository.addCategory(category);
  }

  /// 更新分类
  Future<void> updateCategory(LibraryCategory category) async {
    await _repository.updateCategory(category);
  }

  /// 删除分类
  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
  }

  /// 获取项目数据
  Future<Uint8List?> getItemData(String id) async {
    return await _repository.getItemData(id);
  }

  /// 获取缩略图
  Future<Uint8List?> getThumbnail(String id) async {
    return await _repository.getThumbnail(id);
  }

  /// 生成缩略图
  Future<Uint8List?> generateThumbnail(Uint8List data) async {
    return await _repository.generateThumbnail(data);
  }

  /// 获取项目数量
  Future<int> getItemCount({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
  }) async {
    return await _repository.getItemCount(
      type: type,
      tags: tags,
      categories: categories,
      searchQuery: searchQuery,
    );
  }

  /// 获取分类项目数量
  Future<Map<String, int>> getCategoryItemCounts() async {
    return await _repository.getCategoryItemCounts();
  }
}
