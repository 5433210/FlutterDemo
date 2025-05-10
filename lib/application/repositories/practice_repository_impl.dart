import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/practice/practice_entity.dart';
import '../../domain/models/practice/practice_filter.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../utils/date_time_helper.dart';

/// 字帖练习仓库实现
class PracticeRepositoryImpl implements PracticeRepository {
  static const _table = 'practices';
  final DatabaseInterface _db;
  final Uuid _uuid = const Uuid();

  PracticeRepositoryImpl(this._db);

  @override
  Future<void> close() => _db.close();

  @override
  Future<int> count(PracticeFilter? filter) async {
    if (filter == null) {
      return _db.count(_table);
    }
    final query = _buildQuery(filter);
    return _db.count(_table, query);
  }

  @override
  Future<PracticeEntity> create(PracticeEntity practice) async {
    await _db.save(_table, practice.id, practice.toJson());
    return practice;
  }

  @override
  Future<void> delete(String id) => _db.delete(_table, id);

  @override
  Future<void> deleteMany(List<String> ids) => _db.deleteMany(_table, ids);

  @override
  Future<PracticeEntity> duplicate(String id, {String? newId}) async {
    final practice = await get(id);
    if (practice == null) {
      throw ArgumentError('练习不存在');
    }

    final now = DateTime.now();
    final copy = practice.copyWith(
      id: newId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: '${practice.title} (副本)',
      createTime: now,
      updateTime: now,
    );

    await create(copy);
    return copy;
  }

  @override
  Future<PracticeEntity?> get(String id) async {
    try {
      final data = await _db.get(_table, id);
      if (data == null) return null;

      // 处理数据，确保pages字段格式正确
      final processedData = _processDbData(data);

      return PracticeEntity.fromJson(processedData);
    } catch (e) {
      debugPrint('获取练习失败: $e');
      return null; // 出错时返回null
    }
  }

  @override
  Future<List<PracticeEntity>> getAll() async {
    try {
      final list = await _db.getAll(_table);
      final result = <PracticeEntity>[];

      for (final item in list) {
        try {
          // 处理数据，确保pages字段格式正确
          final processedItem = _processDbData(item);

          // 创建PracticeEntity对象
          final practice = PracticeEntity.fromJson(processedItem);
          result.add(practice);
        } catch (e) {
          debugPrint('处理单个练习实体失败: $e');
          // 继续处理下一个实体
        }
      }

      return result;
    } catch (e) {
      debugPrint('获取所有练习失败: $e');
      return []; // 出错时返回空列表
    }
  }

  @override
  Future<Set<String>> getAllTags() async {
    try {
      final list = await _db.getAll(_table);
      final tags = <String>{};

      for (final item in list) {
        try {
          // 处理数据，确保pages字段格式正确
          final processedItem = _processDbData(item);

          // 创建PracticeEntity对象
          final practice = PracticeEntity.fromJson(processedItem);
          tags.addAll(practice.tags);
        } catch (e) {
          debugPrint('处理单个练习实体标签失败: $e');
          // 继续处理下一个实体
        }
      }

      return tags;
    } catch (e) {
      debugPrint('获取所有标签失败: $e');
      return {}; // 出错时返回空集合
    }
  }

  @override
  Future<List<PracticeEntity>> getByTags(Set<String> tags) async {
    if (tags.isEmpty) return [];

    final filter = PracticeFilter(tags: tags.toList());
    return query(filter);
  }

  @override
  Future<bool> isTitleExists(String title, {String? excludeId}) async {
    try {
      debugPrint('检查标题是否存在: $title, 排除ID: $excludeId');

      final results = await queryByField('title', '=', title);

      // 如果提供了排除ID，则排除该ID的记录
      if (excludeId != null && results.isNotEmpty) {
        final filteredResults =
            results.where((item) => item['id'] != excludeId).toList();
        return filteredResults.isNotEmpty;
      }

      final exists = results.isNotEmpty;
      debugPrint('标题 "$title" ${exists ? "已存在" : "不存在"}');

      return exists;
    } catch (e) {
      debugPrint('检查标题是否存在失败: $e');
      // 出错时返回false，避免阻止保存
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> loadPractice(String id) async {
    try {
      final practice = await _db.get(_table, id);
      if (practice == null) return null;

      // 准备页面数据列表
      List<Map<String, dynamic>> pages = [];

      // 检查pages字段的格式
      if (practice['pages'] is String) {
        // pages是JSON字符串
        final pagesJson = practice['pages'] as String;

        if (pagesJson.isNotEmpty) {
          try {
            final decodedData = jsonDecode(pagesJson);

            // 检查解码后的数据类型
            if (decodedData is List) {
              // 将解码后的数据转换为页面列表
              pages = List<Map<String, dynamic>>.from(
                decodedData.map((item) {
                  if (item is Map) {
                    return Map<String, dynamic>.from(item);
                  } else {
                    // 如果不是Map，则创建一个空页面
                    return <String, dynamic>{
                      'id': _uuid.v4(),
                      'name': 'Page',
                      'index': pages.length,
                    };
                  }
                }),
              );
              debugPrint('成功解析页面数据：${pages.length} 个页面');
            } else {
              debugPrint('解析pages字段失败：不是有效的列表');
            }
          } catch (e) {
            debugPrint('解析pages字段失败: $e');
          }
        }
      } else if (practice['pages'] is List) {
        // 直接是页面列表
        final pagesList = practice['pages'] as List;

        // 将列表转换为页面数据
        pages = List<Map<String, dynamic>>.from(
          pagesList.map((item) {
            if (item is Map) {
              return Map<String, dynamic>.from(item);
            } else {
              // 如果不是Map，则创建一个空页面
              return <String, dynamic>{
                'id': _uuid.v4(),
                'name': 'Page',
                'index': pages.length,
              };
            }
          }),
        );
        debugPrint('成功解析页面数据：${pages.length} 个页面');
      }

      // 确保每个页面都有ID
      for (final page in pages) {
        if (!page.containsKey('id') || page['id'] == null) {
          page['id'] = _uuid.v4();
        }
      }

      // 返回包含解析后页面数据的字帖信息
      return {
        'id': practice['id'],
        'title': practice['title'],
        'pages': pages,
        'tags': practice['tags'],
        'createTime': practice['createTime'],
        'updateTime': practice['updateTime'],
        'thumbnail': practice['thumbnail'],
      };
    } catch (e) {
      debugPrint('加载字帖失败: $e');
      return null;
    }
  }

  @override
  Future<List<PracticeEntity>> query(PracticeFilter filter) async {
    try {
      final queryParams = _buildQuery(filter);
      final list = await _db.query(_table, queryParams);
      final result = <PracticeEntity>[];

      for (final item in list) {
        try {
          // 处理数据，确保pages字段格式正确
          final processedItem = _processDbData(item);

          // 创建PracticeEntity对象
          final practice = PracticeEntity.fromJson(processedItem);
          result.add(practice);
        } catch (e) {
          debugPrint('处理查询结果中的单个练习实体失败: $e');
          // 继续处理下一个实体
        }
      }

      return result;
    } catch (e) {
      debugPrint('查询练习失败: $e');
      return []; // 出错时返回空列表
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryByField(
    String field,
    String operator,
    dynamic value,
  ) async {
    try {
      debugPrint('查询字帖: $field $operator $value');

      final filter = {
        'conditions': [
          {
            'field': field,
            'operator': operator,
            'value': value,
          },
        ],
      };

      final results = await _db.query(_table, filter);

      debugPrint('查询结果: ${results.length} 条记录');

      return results;
    } catch (e) {
      debugPrint('查询字帖失败: $e');
      // 返回空列表而不是抛出异常，使调用者能够更好地处理错误
      return [];
    }
  }

  @override
  Future<PracticeEntity> save(PracticeEntity practice) async {
    await _db.save(_table, practice.id, practice.toJson());
    return practice;
  }

  @override
  Future<List<PracticeEntity>> saveMany(List<PracticeEntity> practices) async {
    final map = {
      for (var p in practices) p.id: p.toJson(),
    };
    await _db.saveMany(_table, map);
    return practices;
  }

  @override
  Future<Map<String, dynamic>> savePracticeRaw({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
    Uint8List? thumbnail,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final practiceId = id ?? _uuid.v4();

      // 将页面列表转换为JSON字符串
      final pagesJson = jsonEncode(pages);

      // 准备要保存的数据
      final data = {
        'id': practiceId,
        'title': title,
        'pages': pagesJson,
        'updateTime': now,
        'thumbnail': thumbnail != null ? base64Encode(thumbnail) : null,
      };

      debugPrint('缩略图数据: ${thumbnail != null ? '已生成' : '无缩略图'}');

      // 如果是新建的字帖，添加创建时间
      if (id == null) {
        data['createTime'] = now;
      } else {
        // 对于现有记录，需要获取原有的createTime
        final existingPractice = await _db.get(_table, id);
        if (existingPractice != null &&
            existingPractice['createTime'] != null) {
          data['createTime'] = existingPractice['createTime'];
        } else {
          // 如果无法获取原有createTime，使用当前时间作为fallback
          data['createTime'] = now;
        }
      }

      // 保存到数据库
      await _db.set(_table, practiceId, data);

      // 返回保存结果
      return {
        'id': practiceId,
        'title': title,
        'createTime': data['createTime'],
        'updateTime': now,
      };
    } catch (e) {
      debugPrint('保存字帖失败: $e');
      rethrow;
    }
  }

  @override
  Future<List<PracticeEntity>> search(String query, {int? limit}) async {
    final filter = PracticeFilter(
      keyword: query,
      limit: limit ?? 20,
    );
    return this.query(filter);
  }

  @override
  Future<List<String>> suggestTags(String prefix, {int limit = 10}) async {
    final allTags = await getAllTags();
    return allTags
        .where((tag) => tag.toLowerCase().startsWith(prefix.toLowerCase()))
        .take(limit)
        .toList();
  }

  /// 构建查询条件
  Map<String, dynamic> _buildQuery(PracticeFilter filter) {
    final query = <String, dynamic>{};

    if (filter.keyword?.isNotEmpty == true) {
      query['title'] = {'contains': filter.keyword};
    }

    if (filter.tags.isNotEmpty) {
      query['tags'] = {'contains': filter.tags};
    }

    if (filter.status?.isNotEmpty == true) {
      query['status'] = filter.status;
    }

    if (filter.startTime != null) {
      query['createTime'] = {
        'gte': DateTimeHelper.toStorageFormat(filter.startTime!),
      };
    }

    if (filter.endTime != null) {
      query['createTime'] ??= {};
      query['createTime']['lte'] =
          DateTimeHelper.toStorageFormat(filter.endTime!);
    }

    // 设置排序字段，将驼峰命名转换为下划线命名
    final dbSortField = _convertFieldNameToDb(filter.sortField);
    query['orderBy'] = '$dbSortField ${filter.sortOrder}';

    // 添加调试日志
    debugPrint(
        '构建查询参数: sortField=${filter.sortField}, dbSortField=$dbSortField, sortOrder=${filter.sortOrder}');
    debugPrint('排序字段: ${query['orderBy']}');

    // 设置分页参数
    query['limit'] = filter.limit;
    query['offset'] = filter.offset;

    return query;
  }

  /// 将驼峰命名的字段名转换为数据库中的实际字段名
  String _convertFieldNameToDb(String fieldName) {
    // 根据数据库迁移脚本，practices 表中的字段名是 createTime 和 updateTime
    // 不需要转换为下划线命名
    return fieldName;
  }

  /// 处理从数据库获取的数据，确保pages字段格式正确
  Map<String, dynamic> _processDbData(Map<String, dynamic> data) {
    // 创建一个新的Map来存储处理后的数据
    final processedData = Map<String, dynamic>.from(data);

    // 处理pages字段，如果是字符串，则解析为JSON
    if (processedData['pages'] is String) {
      final pagesJson = processedData['pages'] as String;
      if (pagesJson.isNotEmpty) {
        try {
          // 解析JSON字符串
          final decodedPages = jsonDecode(pagesJson);

          // 如果解析结果是列表，则直接使用
          if (decodedPages is List) {
            processedData['pages'] = decodedPages;
          } else {
            // 如果不是列表，则使用空列表
            processedData['pages'] = [];
          }
        } catch (e) {
          debugPrint('解析pages字段失败: $e');
          processedData['pages'] = []; // 解析失败时使用空列表
        }
      } else {
        processedData['pages'] = []; // 空字符串时使用空列表
      }
    } else if (processedData['pages'] == null) {
      processedData['pages'] = []; // null时使用空列表
    }

    return processedData;
  }
}
