import 'dart:typed_data';
import '../entities/library_item.dart';
import '../entities/library_category.dart';

/// 图库查询结果
class LibraryQueryResult {
  /// 项目列表
  final List<LibraryItem> items;

  /// 总数量
  final int totalCount;

  /// 当前页码
  final int currentPage;

  /// 构造函数
  const LibraryQueryResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
  });
}

/// 图库仓库接口
abstract class ILibraryRepository {
  /// 获取所有项目
  Future<LibraryQueryResult> getAll({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool sortDesc = false,
  });

  /// 根据ID获取项目
  Future<LibraryItem?> getById(String id);

  /// 添加项目
  Future<void> add(LibraryItem item);

  /// 更新项目
  Future<void> update(LibraryItem item);

  /// 删除项目
  Future<void> delete(String id);

  /// 切换收藏状态
  Future<void> toggleFavorite(String id);

  /// 获取所有标签
  Future<List<String>> getAllTags();

  /// 获取所有分类
  Future<List<LibraryCategory>> getCategories();

  /// 获取分类树
  Future<List<LibraryCategory>> getCategoryTree();

  /// 添加分类
  Future<void> addCategory(LibraryCategory category);

  /// 更新分类
  Future<void> updateCategory(LibraryCategory category);

  /// 删除分类
  Future<void> deleteCategory(String id);

  /// 获取项目数据
  Future<Uint8List?> getItemData(String id);

  /// 获取缩略图
  Future<Uint8List?> getThumbnail(String id);

  /// 生成缩略图
  Future<Uint8List?> generateThumbnail(Uint8List data);

  /// 获取项目数量
  Future<int> getItemCount({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
  });

  /// 获取分类项目数量
  Future<Map<String, int>> getCategoryItemCounts();
}
