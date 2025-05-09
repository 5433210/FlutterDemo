import 'dart:typed_data';

import '../../domain/entities/library_category.dart';
import '../../domain/entities/library_item.dart';
import '../../domain/repositories/library_repository.dart';
import '../../infrastructure/cache/services/image_cache_service.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../infrastructure/persistence/models/database_query.dart';

/// 图库仓库实现
class LibraryRepositoryImpl implements ILibraryRepository {
  final DatabaseInterface _db;
  final ImageCacheService _imageCache;
  final String _table = 'library_items';
  final String _categoryTable = 'library_categories';

  /// 构造函数
  LibraryRepositoryImpl(this._db, this._imageCache);
  @override
  Future<void> add(LibraryItem item) async {
    try {
      // Convert the item to JSON and process complex types
      final Map<String, dynamic> itemData = item.toJson();

      // Convert List<String> to JSON string
      if (itemData.containsKey('tags')) {
        itemData['tags'] =
            itemData['tags'].isNotEmpty ? item.tags.join(',') : null;
      }

      if (itemData.containsKey('categories')) {
        itemData['categories'] = itemData['categories'].isNotEmpty
            ? item.categories.join(',')
            : null;
      }

      // Convert Map<String, dynamic> to JSON string
      if (itemData.containsKey('metadata')) {
        itemData['metadata'] = itemData['metadata'].isNotEmpty
            ? _mapToJsonString(item.metadata)
            : null;
      }

      // Convert boolean to integer (0/1)
      if (itemData.containsKey('isFavorite')) {
        itemData['isFavorite'] = item.isFavorite ? 1 : 0;
      }

      // Add timestamps if not present
      if (!itemData.containsKey('createTime')) {
        itemData['createTime'] = DateTime.now().toIso8601String();
      }

      if (!itemData.containsKey('updateTime')) {
        itemData['updateTime'] = DateTime.now().toIso8601String();
      }

      await _db.set(_table, item.id, itemData);
      AppLogger.debug('添加图库项目成功', data: {'itemId': item.id});
    } catch (e, stackTrace) {
      AppLogger.error('添加图库项目失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addCategory(LibraryCategory category) async {
    try {
      // Convert the category to JSON and ensure dates are set
      final Map<String, dynamic> categoryData = category.toJson();

      // Add timestamps if not present
      if (!categoryData.containsKey('createTime')) {
        categoryData['createTime'] = DateTime.now().toIso8601String();
      }

      if (!categoryData.containsKey('updateTime')) {
        categoryData['updateTime'] = DateTime.now().toIso8601String();
      }

      await _db.set(_categoryTable, category.id, categoryData);
      AppLogger.debug('添加图库分类成功', data: {'categoryId': category.id});
    } catch (e, stackTrace) {
      AppLogger.error('添加图库分类失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _db.delete(_table, id);
      AppLogger.debug('删除图库项目成功', data: {'itemId': id});
    } catch (e, stackTrace) {
      AppLogger.error('删除图库项目失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _db.delete(_categoryTable, id);
      AppLogger.debug('删除图库分类成功', data: {'categoryId': id});
    } catch (e, stackTrace) {
      AppLogger.error('删除图库分类失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Uint8List?> generateThumbnail(Uint8List data) async {
    try {
      // 使用 ImageCacheService 生成缩略图
      final thumbnail = await _imageCache.generateThumbnail(data);
      if (thumbnail != null) {
        AppLogger.debug('生成缩略图成功');
      } else {
        AppLogger.warning('生成缩略图失败');
      }
      return thumbnail;
    } catch (e, stackTrace) {
      AppLogger.error('生成缩略图失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<LibraryQueryResult> getAll({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool sortDesc = false,
  }) async {
    try {
      final conditions = <DatabaseQueryCondition>[];

      if (type != null) {
        conditions.add(DatabaseQueryCondition(
          field: 'type',
          operator: '=',
          value: type,
        ));
      }
      if (tags != null && tags.isNotEmpty) {
        conditions.add(DatabaseQueryCondition(
          field: 'tags',
          operator: '@>',
          value: tags,
        ));
      }
      if (categories != null && categories.isNotEmpty) {
        conditions.add(DatabaseQueryCondition(
          field: 'categories',
          operator: '@>',
          value: categories,
        ));
      }

      // 创建基本查询对象
      DatabaseQuery query;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // 创建一个OR条件组，实现同时搜索名称和标签
        final searchConditions = [
          // 搜索名称
          DatabaseQueryCondition(
            field: 'name',
            operator: 'LIKE',
            value: '%$searchQuery%',
          ),
          // 搜索标签
          DatabaseQueryCondition(
            field: 'tags',
            operator: 'LIKE',
            value: '%$searchQuery%',
          ),
        ];

        // 使用条件和OR条件组
        final groups = [DatabaseQueryGroup.or(searchConditions)];

        query = DatabaseQuery(
          conditions: conditions,
          groups: groups,
          orderBy:
              sortBy != null ? '$sortBy ${sortDesc ? 'DESC' : 'ASC'}' : null,
          limit: pageSize,
          offset: (page - 1) * pageSize,
        );
      } else {
        // 如果没有搜索查询，使用普通的查询
        query = DatabaseQuery(
          conditions: conditions,
          orderBy:
              sortBy != null ? '$sortBy ${sortDesc ? 'DESC' : 'ASC'}' : null,
          limit: pageSize,
          offset: (page - 1) * pageSize,
        );
      }

      // 获取总数
      final totalCount = await _db.count(_table, query.toJson());

      // 获取分页数据
      final result = await _db.query(_table, query.toJson());

      // Convert database results to LibraryItem objects
      final items = result.map((Map<String, dynamic> row) {
        // 创建一个新的可修改Map
        final Map<String, dynamic> mutableRow = Map<String, dynamic>.from(row);

        // Process tags from comma-separated string to List<String>
        if (mutableRow.containsKey('tags') && mutableRow['tags'] != null) {
          mutableRow['tags'] = mutableRow['tags']
              .toString()
              .split(',')
              .where((tag) => tag.isNotEmpty)
              .toList();
        } else {
          mutableRow['tags'] = <String>[];
        }

        // Process categories from comma-separated string to List<String>
        if (mutableRow.containsKey('categories') &&
            mutableRow['categories'] != null) {
          mutableRow['categories'] = mutableRow['categories']
              .toString()
              .split(',')
              .where((cat) => cat.isNotEmpty)
              .toList();
        } else {
          mutableRow['categories'] = <String>[];
        }

        // Process metadata from string to Map<String, dynamic>
        if (mutableRow.containsKey('metadata') &&
            mutableRow['metadata'] != null) {
          mutableRow['metadata'] =
              _jsonStringToMap(mutableRow['metadata'].toString());
        } else {
          mutableRow['metadata'] = <String, dynamic>{};
        }

        // Process isFavorite from integer to boolean
        if (mutableRow.containsKey('isFavorite')) {
          mutableRow['isFavorite'] = mutableRow['isFavorite'] == 1;
        }
        return LibraryItem.fromJson(mutableRow);
      }).toList();

      return LibraryQueryResult(
        items: items,
        totalCount: totalCount,
        currentPage: page,
      );
    } catch (e, stackTrace) {
      AppLogger.error('获取图库项目列表失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<String>> getAllTags() async {
    try {
      const query = DatabaseQuery(
        conditions: [],
        orderBy: 'tags',
      );
      final result = await _db.query(_table, query.toJson());

      final tags = <String>{};
      for (final row in result) {
        final itemTags = (row['tags'] as List<dynamic>).cast<String>();
        tags.addAll(itemTags);
      }

      return tags.toList()..sort();
    } catch (e, stackTrace) {
      AppLogger.error('获取所有标签失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<LibraryItem?> getById(String id) async {
    try {
      final data = await _db.get(_table, id);
      if (data == null) return null;

      // 创建一个新的可修改Map
      final Map<String, dynamic> mutableData = Map<String, dynamic>.from(data);

      // Process numeric fields
      if (mutableData.containsKey('width')) {
        mutableData['width'] = int.parse(mutableData['width'].toString());
      }
      if (mutableData.containsKey('height')) {
        mutableData['height'] = int.parse(mutableData['height'].toString());
      }
      if (mutableData.containsKey('size')) {
        mutableData['size'] = int.parse(mutableData['size'].toString());
      }

      // Process tags from comma-separated string to List<String>
      if (mutableData.containsKey('tags') && mutableData['tags'] != null) {
        mutableData['tags'] = mutableData['tags']
            .toString()
            .split(',')
            .where((tag) => tag.isNotEmpty)
            .toList();
      } else {
        mutableData['tags'] = <String>[];
      }

      // Process categories from comma-separated string to List<String>
      if (mutableData.containsKey('categories') &&
          mutableData['categories'] != null) {
        mutableData['categories'] = mutableData['categories']
            .toString()
            .split(',')
            .where((cat) => cat.isNotEmpty)
            .toList();
      } else {
        mutableData['categories'] = <String>[];
      }

      // Process metadata from string to Map<String, dynamic>
      if (mutableData.containsKey('metadata') &&
          mutableData['metadata'] != null) {
        mutableData['metadata'] =
            _jsonStringToMap(mutableData['metadata'].toString());
      } else {
        mutableData['metadata'] = <String, dynamic>{};
      }

      // Process isFavorite from integer to boolean
      if (mutableData.containsKey('isFavorite')) {
        mutableData['isFavorite'] = mutableData['isFavorite'] == 1;
      }

      return LibraryItem.fromJson(mutableData);
    } catch (e, stackTrace) {
      AppLogger.error('获取图库项目失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<LibraryCategory>> getCategories() async {
    try {
      final result = await _db.getAll(_categoryTable);
      return result.map((e) => LibraryCategory.fromJson(e)).toList();
    } catch (e, stackTrace) {
      AppLogger.error('获取所有分类失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getCategoryItemCounts() async {
    try {
      final categories = await getCategories();
      final counts = <String, int>{};

      for (final category in categories) {
        final query = DatabaseQuery(
          conditions: [
            DatabaseQueryCondition(
              field: 'categories',
              operator: '@>',
              value: [category.id],
            ),
          ],
        );
        final count = await _db.count(_table, query.toJson());
        counts[category.id] = count;
      }

      return counts;
    } catch (e, stackTrace) {
      AppLogger.error('获取分类项目数量失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<List<LibraryCategory>> getCategoryTree() async {
    try {
      final categories = await getCategories();
      final tree = <LibraryCategory>[];
      final map = <String, LibraryCategory>{};

      // 构建映射
      for (final category in categories) {
        map[category.id] = category;
      }

      // 构建树
      for (final category in categories) {
        if (category.parentId == null) {
          tree.add(category);
        } else {
          final parent = map[category.parentId];
          if (parent != null) {
            parent.children.add(category);
          }
        }
      }

      return tree;
    } catch (e, stackTrace) {
      AppLogger.error('获取分类树失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<int> getItemCount({
    String? type,
    List<String>? tags,
    List<String>? categories,
    String? searchQuery,
  }) async {
    try {
      final conditions = <DatabaseQueryCondition>[];

      if (type != null) {
        conditions.add(DatabaseQueryCondition(
          field: 'type',
          operator: '=',
          value: type,
        ));
      }

      if (tags != null && tags.isNotEmpty) {
        conditions.add(DatabaseQueryCondition(
          field: 'tags',
          operator: '@>',
          value: tags,
        ));
      }

      if (categories != null && categories.isNotEmpty) {
        conditions.add(DatabaseQueryCondition(
          field: 'categories',
          operator: '@>',
          value: categories,
        ));
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // 创建一个OR条件组，实现同时搜索名称和标签
        final searchConditions = [
          // 搜索名称
          DatabaseQueryCondition(
            field: 'name',
            operator: 'LIKE',
            value: '%$searchQuery%',
          ),
          // 搜索标签
          DatabaseQueryCondition(
            field: 'tags',
            operator: 'LIKE',
            value: '%$searchQuery%',
          ),
        ];

        // 创建查询，添加条件和OR条件组
        final groups = [DatabaseQueryGroup.or(searchConditions)];
        final query = DatabaseQuery(
          conditions: conditions,
          groups: groups,
        );
        return _db.count(_table, query.toJson());
      }

      final query = DatabaseQuery(conditions: conditions);
      return _db.count(_table, query.toJson());
    } catch (e, stackTrace) {
      AppLogger.error('获取图库项目数量失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Uint8List?> getItemData(String id) async {
    try {
      final data = await _db.get(_table, id);
      if (data == null) return null;
      return data['data'] as Uint8List?;
    } catch (e, stackTrace) {
      AppLogger.error('获取图库项目数据失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Uint8List?> getThumbnail(String id) async {
    try {
      final data = await _db.get(_table, id);
      if (data == null) return null;
      return data['thumbnail'] as Uint8List?;
    } catch (e, stackTrace) {
      AppLogger.error('获取图库项目缩略图失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> toggleFavorite(String id) async {
    try {
      final item = await getById(id);
      if (item == null) return;

      await update(item.copyWith(isFavorite: !item.isFavorite));
      AppLogger.debug('切换收藏状态成功', data: {'itemId': id});
    } catch (e, stackTrace) {
      AppLogger.error('切换收藏状态失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> update(LibraryItem item) async {
    try {
      // Convert the item to JSON and process complex types
      final Map<String, dynamic> itemData = item.toJson();

      // Convert List<String> to JSON string
      if (itemData.containsKey('tags')) {
        itemData['tags'] =
            itemData['tags'].isNotEmpty ? item.tags.join(',') : null;
      }

      if (itemData.containsKey('categories')) {
        itemData['categories'] = itemData['categories'].isNotEmpty
            ? item.categories.join(',')
            : null;
      }

      // Convert Map<String, dynamic> to JSON string
      if (itemData.containsKey('metadata')) {
        itemData['metadata'] = itemData['metadata'].isNotEmpty
            ? _mapToJsonString(item.metadata)
            : null;
      }

      // Convert boolean to integer (0/1)
      if (itemData.containsKey('isFavorite')) {
        itemData['isFavorite'] = item.isFavorite ? 1 : 0;
      }

      // Ensure updateTime is set
      itemData['updateTime'] = DateTime.now().toIso8601String();

      await _db.save(_table, item.id, itemData);
      AppLogger.debug('更新图库项目成功', data: {'itemId': item.id});
    } catch (e, stackTrace) {
      AppLogger.error('更新图库项目失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(LibraryCategory category) async {
    try {
      // Convert the category to JSON and ensure dates are set
      final Map<String, dynamic> categoryData = category.toJson();

      // Update timestamp
      categoryData['updateTime'] = DateTime.now().toIso8601String();

      await _db.save(_categoryTable, category.id, categoryData);
      AppLogger.debug('更新图库分类成功', data: {'categoryId': category.id});
    } catch (e, stackTrace) {
      AppLogger.error('更新图库分类失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 将JSON字符串转换回Map
  Map<String, dynamic> _jsonStringToMap(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return {};
    }

    final Map<String, dynamic> result = {};
    final List<String> pairs = jsonString.split(',');

    for (final pair in pairs) {
      final parts = pair.split(':');
      if (parts.length == 2) {
        String key = parts[0].trim();
        String value = parts[1].trim();

        // 处理带引号的值
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }

        // 尝试将数值字符串转换为整数或浮点数
        if (int.tryParse(value) != null) {
          result[key] = int.parse(value);
        } else if (double.tryParse(value) != null) {
          result[key] = double.parse(value);
        } else {
          result[key] = value;
        }
      }
    }

    return result;
  }

  /// 将Map转换为JSON字符串
  String _mapToJsonString(Map<String, dynamic> map) {
    // 构建一个简单的键值对字符串，避免复杂的JSON序列化
    final List<String> pairs = [];
    map.forEach((key, value) {
      // 对值进行简单处理，确保它是字符串
      String valueStr = value.toString();
      // 如果包含逗号或冒号，用引号括起来
      if (valueStr.contains(',') ||
          valueStr.contains(':') ||
          !(value is num || value is bool)) {
        // 只给非数值和非布尔类型加引号
        valueStr = '"$valueStr"';
      }
      pairs.add('$key:$valueStr');
    });
    return pairs.join(',');
  }
}
