import 'dart:typed_data';

import '../../domain/entities/library_category.dart';
import '../../domain/entities/library_item.dart';
import '../../domain/repositories/library_repository.dart';
import '../../infrastructure/cache/services/image_cache_service.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../infrastructure/persistence/models/database_query.dart';
import '../../utils/path_privacy_helper.dart';

/// 图库仓库实现
class LibraryRepositoryImpl implements ILibraryRepository {
  final DatabaseInterface _db;
  final ImageCacheService _imageCache;
  final String? _storageBasePath;
  final String _table = 'library_items';
  final String _categoryTable = 'library_categories';

  /// 构造函数
  LibraryRepositoryImpl(this._db, this._imageCache, {String? storageBasePath})
      : _storageBasePath = storageBasePath;

  @override
  Future<void> add(LibraryItem item) async {
    try {
      // Convert the item to JSON and process complex types
      final Map<String, dynamic> itemData = item.toJson();
      
      // 转换路径为相对路径存储
      if (itemData.containsKey('path')) {
        itemData['path'] = _toRelativePath(item.path);
      }

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
      
      AppLogger.debug(
        '添加图库项目成功',
        data: {
          'itemId': item.id,
          'path': _sanitizePathForLogging(item.path),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('添加图库项目失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> addCategory(LibraryCategory category) async {
    try {
      AppLogger.debug('正在添加图库分类', data: {'category': category.toJson()});

      // Create base category data with only supported fields
      final now = DateTime.now();
      final Map<String, dynamic> dbData = {
        'id': category.id,
        'name': category.name,
        'parentId': category.parentId,
        'createTime': now.toIso8601String(),
        'updateTime': now.toIso8601String(),
      };

      // Remove null values to avoid database errors
      dbData.removeWhere((key, value) => value == null);

      await _db.set(_categoryTable, category.id, dbData);
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

      // Handle tags using individual LIKE conditions
      if (tags != null && tags.isNotEmpty) {
        for (final tag in tags) {
          final escapedTag = _escapeLikePattern(tag);
          conditions.add(DatabaseQueryCondition(
            field: 'tags',
            operator: 'LIKE',
            value: '%$escapedTag%',
          ));
        }
      }

      // Handle categories using individual LIKE conditions
      if (categories != null && categories.isNotEmpty) {
        for (final category in categories) {
          final escapedCategory = _escapeLikePattern(category);
          conditions.add(DatabaseQueryCondition(
            field: 'categories',
            operator: 'LIKE',
            value: '%$escapedCategory%',
          ));
        }
      }

      // 创建基本查询对象
      DatabaseQuery query;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        // 创建一个OR条件组，实现同时搜索名称和标签
        final escapedQuery = _escapeLikePattern(searchQuery);
        final searchConditions = [
          // 搜索文件名
          DatabaseQueryCondition(
            field: 'fileName',
            operator: 'LIKE',
            value: '%$escapedQuery%',
          ),
          // 搜索标签
          DatabaseQueryCondition(
            field: 'tags',
            operator: 'LIKE',
            value: '%$escapedQuery%',
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

        // 转换相对路径为绝对路径
        if (mutableRow.containsKey('path')) {
          mutableRow['path'] = _toAbsolutePath(mutableRow['path'] as String);
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
      if (mutableData.containsKey('fileSize')) {
        mutableData['fileSize'] = int.parse(mutableData['fileSize'].toString());
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

      // 转换相对路径为绝对路径
      if (mutableData.containsKey('path')) {
        mutableData['path'] = _toAbsolutePath(mutableData['path'] as String);
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
      return result.map((Map<String, dynamic> row) {
        // 创建可修改的数据副本
        final mutableData = Map<String, dynamic>.from(row);

        // 处理可能为 null 的字段
        if (mutableData['parentId'] == null) {
          mutableData.remove('parentId');
        }

        // 解析并转换时间字段
        final createdAt = DateTime.parse(mutableData['createTime'] as String);
        final updatedAt = DateTime.parse(mutableData['updateTime'] as String);

        return LibraryCategory(
          id: mutableData['id'] as String,
          name: mutableData['name'] as String,
          parentId: mutableData['parentId'] as String?,
          sortOrder: 0,
          children: const [],
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      }).toList();
    } catch (e, stackTrace) {
      AppLogger.error('获取所有分类失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<Map<String, int>> getCategoryItemCounts() async {
    try {
      final categories = await getCategories();
      final counts = <String, int>{}; // First get the total count of all items
      final totalCount = await _db.count(_table, {});
      counts['total'] = totalCount;
      counts['all'] = totalCount; // Add 'all' key for compatibility

      for (final category in categories) {
        // Create a query with LIKE operator for comma-separated values
        final escapedCategoryId = _escapeLikePattern(category.id);
        final query = DatabaseQuery(
          conditions: [
            DatabaseQueryCondition(
              field: 'categories',
              operator: 'LIKE',
              value: '%$escapedCategoryId%',
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
      final categoryMap = <String, LibraryCategory>{};
      final rootCategories = <LibraryCategory>[];

      // 第一步：建立初始映射关系
      for (final category in categories) {
        categoryMap[category.id] = category;
      }

      // 第二步：构建父子关系
      for (final category in categories) {
        if (category.parentId == null || category.parentId!.isEmpty) {
          // 这是一个根分类
          rootCategories.add(category);
        } else {
          // 这是一个子分类，将其添加到父分类的children中
          final parent = categoryMap[category.parentId];
          if (parent != null) {
            final parentWithNewChild = parent.copyWith(
              children: [...parent.children, category],
            );
            categoryMap[parent.id] = parentWithNewChild;
          } else {
            // 如果找不到父分类，将其作为根分类
            rootCategories.add(category);
          }
        }
      }

      // 第三步：递归更新所有分类的完整子树
      List<LibraryCategory> buildCategoryTree(
          List<LibraryCategory> categories) {
        return categories.map((category) {
          final updatedChildren = buildCategoryTree(
            categoryMap[category.id]?.children ?? [],
          );
          return category.copyWith(children: updatedChildren);
        }).toList();
      }

      // 构建完整的树结构
      final tree = buildCategoryTree(rootCategories);

      // 按名称对每个层级的分类进行排序
      List<LibraryCategory> sortCategoriesRecursively(
          List<LibraryCategory> categories) {
        return categories.map((category) {
          final sortedChildren = sortCategoriesRecursively(category.children)
            ..sort((a, b) => a.name.compareTo(b.name));
          return category.copyWith(children: sortedChildren);
        }).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
      }

      return sortCategoriesRecursively(tree);
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
        // Handle tags using individual LIKE conditions
        for (final tag in tags) {
          conditions.add(DatabaseQueryCondition(
            field: 'tags',
            operator: 'LIKE',
            value: '%$tag%',
          ));
        }
      }

      if (categories != null && categories.isNotEmpty) {
        // Handle categories using individual LIKE conditions
        for (final category in categories) {
          final escapedCategory = _escapeLikePattern(category);
          conditions.add(DatabaseQueryCondition(
            field: 'categories',
            operator: 'LIKE',
            value: '%$escapedCategory%',
          ));
        }
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        // 创建一个OR条件组，实现同时搜索名称和标签
        final escapedQuery = _escapeLikePattern(searchQuery);
        final searchConditions = [
          // 搜索文件名
          DatabaseQueryCondition(
            field: 'fileName',
            operator: 'LIKE',
            value: '%$escapedQuery%',
          ),
          // 搜索标签
          DatabaseQueryCondition(
            field: 'tags',
            operator: 'LIKE',
            value: '%$escapedQuery%',
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
      
      // 转换路径为相对路径存储
      if (itemData.containsKey('path')) {
        itemData['path'] = _toRelativePath(item.path);
      }

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
      
      AppLogger.debug(
        '更新图库项目成功',
        data: {
          'itemId': item.id,
          'path': _sanitizePathForLogging(item.path),
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('更新图库项目失败', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(LibraryCategory category) async {
    try {
      // Create base category data with only supported fields
      final Map<String, dynamic> dbData = {
        'id': category.id,
        'name': category.name,
        'parentId': category.parentId,
        'createTime': category.createdAt.toIso8601String(),
        'updateTime': DateTime.now().toIso8601String(), // 更新时间总是使用当前时间
      };

      // Remove null values to avoid database errors
      dbData.removeWhere((key, value) => value == null);

      await _db.save(_categoryTable, category.id, dbData);
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

  /// 将绝对路径转换为相对路径存储
  String _toRelativePath(String absolutePath) {
    return PathPrivacyHelper.toRelativePath(absolutePath);
  }

  /// 将相对路径转换为绝对路径
  String _toAbsolutePath(String relativePath) {
    if (_storageBasePath == null) {
      // 如果没有存储基础路径，返回原路径
      return relativePath;
    }
    return PathPrivacyHelper.toAbsolutePath(relativePath, _storageBasePath!);
  }

  /// 清理路径用于日志记录
  String _sanitizePathForLogging(String path) {
    return PathPrivacyHelper.sanitizePathForLogging(path);
  }
  
  /// 转义 LIKE 操作符中的特殊字符
  String _escapeLikePattern(String pattern) {
    // 转义 SQLite LIKE 操作符中的特殊字符
    // % 匹配零个或多个字符
    // _ 匹配单个字符
    // \ 用作转义字符
    return pattern
        .replaceAll('\\', '\\\\')  // 先转义反斜杠
        .replaceAll('%', '\\%')    // 转义百分号
        .replaceAll('_', '\\_');   // 转义下划线
  }
}
