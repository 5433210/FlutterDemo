import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/practice/practice_entity.dart';
import '../../domain/models/practice/practice_filter.dart';
import '../../domain/repositories/practice_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../presentation/widgets/practice/property_panels/image/practice_image_data_integration.dart';
import '../../utils/date_time_helper.dart';
import '../../utils/image_path_converter.dart';

/// 字帖练习仓库实现
class PracticeRepositoryImpl
    with PracticeImageDataIntegration
    implements PracticeRepository {
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
      id: newId ?? const Uuid().v4(),
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
      final processedData = await _processDbData(data);

      // 从实体创建对象
      final entity = PracticeEntity.fromJson(processedData);

      return entity;
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
          final processedItem = await _processDbData(item);

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
          final processedItem = await _processDbData(item);

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

              // 🔥 集成智能图像数据管理策略 - 加载后恢复
              try {
                debugPrint('loadPractice: 准备应用智能图像数据管理恢复');

                final restoredPagesData = restorePracticeDataFromSave({
                  'id': practice['id'],
                  'elements': pages, // 传入页面数组，不是元素数组
                });

                final restoredPages =
                    restoredPagesData['elements'] as List<dynamic>;

                // 替换原来的页面数据
                pages.clear();
                pages.addAll(restoredPages.cast<Map<String, dynamic>>());

                debugPrint(
                    'loadPractice: 已应用智能图像数据管理恢复，处理了 ${pages.length} 个页面');
              } catch (restoreError) {
                debugPrint('loadPractice: 智能图像恢复失败: $restoreError，使用原始数据');
                // 继续使用已解析的数据
              }
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

      // 从文件系统加载缩略图
      // final thumbnail = await _loadThumbnailFromFile(practice['id']);

      // 返回包含解析后页面数据的字帖信息
      return {
        'id': practice['id'],
        'title': practice['title'],
        'pages': pages,
        'tags': practice['tags'],
        'createTime': practice['createTime'],
        'updateTime': practice['updateTime'],
        // 'thumbnail': thumbnail, // 从文件系统加载的缩略图
      };
    } catch (e) {
      debugPrint('加载字帖失败: $e');
      return null;
    }
  }

  @override
  Future<List<PracticeEntity>> query(PracticeFilter filter) async {
    try {
      debugPrint(
          '查询字帖: filter.isFavorite=${filter.isFavorite}, keyword=${filter.keyword}');
      final queryParams = _buildQuery(filter);
      debugPrint('生成查询参数: $queryParams');

      final list = await _db.query(_table, queryParams);
      debugPrint('查询结果数量: ${list.length}');

      // 如果没有结果，检查所有数据的数量以确定是否有任何记录
      if (list.isEmpty) {
        final totalCount = await _db.count(_table);
        debugPrint('数据库中总共有 $totalCount 条练习记录');
        if (totalCount == 0) {
          debugPrint('⚠️ 警告: 数据库中没有任何练习记录，请先创建练习');
        } else {
          debugPrint('⚠️ 警告: 数据库中有记录，但当前过滤条件没有匹配的结果');
        }
      }

      final result = <PracticeEntity>[];

      for (final item in list) {
        try {
          // 处理数据，确保pages字段格式正确
          final processedItem = await _processDbData(item);

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

  /// 修复现有字帖的pageCount字段（一次性数据迁移）
  @override
  Future<void> fixPageCountForAllPractices() async {
    try {
      debugPrint('开始修复所有字帖的pageCount字段...');

      // 查询所有pageCount为0或null的字帖
      final practices = await _db.rawQuery('''
        SELECT id, pages 
        FROM $_table 
        WHERE pageCount IS NULL OR pageCount = 0
      ''');

      debugPrint('找到需要修复的字帖数量: ${practices.length}');

      int fixedCount = 0;
      for (final practice in practices) {
        try {
          final id = practice['id'] as String;
          final pagesJson = practice['pages'] as String?;

          // 解析pages来计算实际页数
          int actualPageCount = 0;
          if (pagesJson != null && pagesJson.isNotEmpty) {
            try {
              final pagesList = jsonDecode(pagesJson);
              if (pagesList is List) {
                actualPageCount = pagesList.length;
              }
            } catch (e) {
              debugPrint('解析字帖页面数据失败，ID: $id, 错误: $e');
              actualPageCount = 0;
            }
          }

          // 更新数据库中的pageCount字段
          await _db.rawUpdate(
            'UPDATE $_table SET pageCount = ? WHERE id = ?',
            [actualPageCount, id],
          );

          fixedCount++;
          debugPrint('已修复字帖 ID: $id, pageCount: $actualPageCount');
        } catch (e) {
          debugPrint('修复单个字帖失败: $e');
        }
      }

      debugPrint('pageCount字段修复完成，共修复: $fixedCount 个字帖');
    } catch (e) {
      debugPrint('修复pageCount字段失败: $e');
    }
  }

  @override
  Future<List<PracticeEntity>> queryList(PracticeFilter filter) async {
    try {
      debugPrint(
          '查询字帖列表（不包含pages）: filter.isFavorite=${filter.isFavorite}, keyword=${filter.keyword}');
      final queryParams = _buildQuery(filter);
      debugPrint('生成查询参数: $queryParams');

      // 使用原生SQL查询，排除pages字段
      final whereClause = _buildWhereClause(queryParams);
      final whereArgs = _buildWhereArgs(queryParams);

      final sql = '''
        SELECT id, title, tags, createTime, updateTime, isFavorite, 
               COALESCE(pageCount, 0) as pageCount, metadata, thumbnail
        FROM $_table 
        ${whereClause.isNotEmpty ? 'WHERE $whereClause' : ''}
        ORDER BY updateTime DESC
      ''';

      final list = await _db.rawQuery(sql, whereArgs);
      debugPrint('查询结果数量: ${list.length}');

      final result = <PracticeEntity>[];
      for (final item in list) {
        try {
          // 创建不包含pages的PracticeEntity对象
          final practiceData = Map<String, dynamic>.from(item);
          practiceData['pages'] = <Map<String, dynamic>>[]; // 设置空pages数组

          // 处理数据，确保格式正确
          final processedItem = await _processDbDataForList(practiceData);

          // 创建PracticeEntity对象
          final practice = PracticeEntity.fromJson(processedItem);
          result.add(practice);
        } catch (e) {
          debugPrint('处理单个练习实体失败: $e');
          // 跳过这个有问题的记录，但继续处理其他记录
        }
      }

      debugPrint('成功解析练习列表：${result.length} 个');
      return result;
    } catch (e) {
      debugPrint('查询字帖列表失败: $e');
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
    try {
      debugPrint('=== PracticeRepositoryImpl.save 开始 === [ID=${practice.id}]');
      debugPrint('调用堆栈: ${StackTrace.current}');

      // 转换practice对象为JSON
      final json = practice.toJson();
      debugPrint('转换为JSON成功, JSON包含 ${json.length} 个字段');
      debugPrint(
          '标题: ${json['title']}, 页面数: ${json['pages'] is List ? (json['pages'] as List).length : '非列表格式'}');

      // 准备保存数据：处理复杂数据类型和类型转换
      final preparedData = _prepareForSave(json);
      debugPrint('数据准备完成，字段: ${preparedData.keys.join(', ')}');

      debugPrint('开始调用 _db.save($_table, ${practice.id}, ...)');
      await _db.save(_table, practice.id, preparedData);
      debugPrint('调用 _db.save 成功');

      // 验证保存是否成功
      final savedData = await _db.get(_table, practice.id);
      if (savedData == null) {
        final error = '严重错误: 数据库中没有找到刚刚保存的记录 [ID=${practice.id}]';
        debugPrint(error);
        throw Exception(error);
      }
      debugPrint('验证成功，数据已保存到数据库: ${savedData['title']}');

      debugPrint('=== PracticeRepositoryImpl.save 完成 === [ID=${practice.id}]');
      return practice;
    } catch (e) {
      debugPrint('错误: 保存实体失败: $e');
      debugPrint('错误堆栈: ${e is Error ? e.stackTrace : ''}');
      rethrow;
    }
  }

  @override
  Future<List<PracticeEntity>> saveMany(List<PracticeEntity> practices) async {
    try {
      debugPrint('saveMany: 开始保存 ${practices.length} 个实体');
      final map = <String, Map<String, dynamic>>{};

      // 为每个实体准备数据
      for (var p in practices) {
        debugPrint('saveMany: 处理ID=${p.id}的实体');
        map[p.id] = _prepareForSave(p.toJson());
      }

      await _db.saveMany(_table, map);
      debugPrint('saveMany: 批量保存成功');
      return practices;
    } catch (e) {
      debugPrint('saveMany失败: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> savePracticeRaw({
    String? id,
    required String title,
    required List<Map<String, dynamic>> pages,
    Map<String, dynamic>? metadata,
    Uint8List? thumbnail,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final practiceId = id ?? _uuid.v4();

      // 🔥 集成智能图像数据管理策略 - 保存前优化
      String pagesJson;
      try {
        debugPrint('savePracticeRaw: 准备优化 ${pages.length} 个页面');
        for (int i = 0; i < pages.length; i++) {
          final page = pages[i];
          debugPrint(
              'savePracticeRaw: 页面 $i 包含 ${(page['elements'] as List?)?.length ?? 0} 个元素');
          if (page['elements'] is List) {
            final elements = page['elements'] as List;
            for (int j = 0; j < elements.length; j++) {
              final element = elements[j];
              if (element is Map<String, dynamic> &&
                  element['type'] == 'image') {
                final content = element['content'] as Map<String, dynamic>?;
                debugPrint(
                    'savePracticeRaw: 页面 $i 元素 $j (图像) 原始内容键: ${content?.keys.toList()}');
              }
            }
          }
        }

        final practiceData = {'id': practiceId, 'elements': pages};
        final optimizedElements = preparePracticeDataForSave(practiceData);

        debugPrint(
            'savePracticeRaw: 优化后得到 ${optimizedElements['elements'].length} 个页面');
        final optimizedPages = optimizedElements['elements'] as List;
        for (int i = 0; i < optimizedPages.length; i++) {
          final page = optimizedPages[i];
          debugPrint(
              'savePracticeRaw: 优化页面 $i 包含 ${(page['elements'] as List?)?.length ?? 0} 个元素');
          if (page['elements'] is List) {
            final elements = page['elements'] as List;
            for (int j = 0; j < elements.length; j++) {
              final element = elements[j];
              if (element is Map<String, dynamic> &&
                  element['type'] == 'image') {
                final content = element['content'] as Map<String, dynamic>?;
                debugPrint(
                    'savePracticeRaw: 优化页面 $i 元素 $j (图像) 优化内容键: ${content?.keys.toList()}');
              }
            }
          }
        }

        pagesJson = jsonEncode(optimizedElements['elements']);
        debugPrint('savePracticeRaw: 已应用智能图像数据管理优化');
      } catch (optimizeError) {
        debugPrint('savePracticeRaw: 智能图像优化失败: $optimizeError，使用原始数据');
        pagesJson = jsonEncode(pages);
      }

      // 准备要保存的数据
      final data = {
        'id': practiceId,
        'title': title,
        'pages': pagesJson,
        'pageCount': pages.length, // 根据传入的pages数组计算页数
        'metadata': metadata != null ? jsonEncode(metadata) : '{}', // 元数据
        'updateTime': now,
      };

      debugPrint(
          '保存数据: 标题=$title, 页数=${pages.length}, 元数据=${metadata != null ? '已设置' : '默认空对象'}, 缩略图=${thumbnail != null ? '已生成' : '无缩略图'}');

      // 如果是新建的字帖，添加创建时间
      if (id == null) {
        data['createTime'] = now;
        debugPrint('新建字帖，设置 createTime=$now');
      } else {
        // 对于现有记录，需要获取原有的createTime
        debugPrint('现有字帖，尝试获取原有 createTime...');
        final existingPractice = await _db.get(_table, id);
        if (existingPractice == null) {
          debugPrint('警告: 无法获取现有字帖数据 [ID=$id]');
        }

        if (existingPractice != null &&
            existingPractice['createTime'] != null) {
          data['createTime'] = existingPractice['createTime'];
          debugPrint('使用原有的 createTime: ${existingPractice['createTime']}');
        } else {
          // 如果无法获取原有createTime，使用当前时间作为fallback
          data['createTime'] = now;
          debugPrint('无法获取原有createTime，使用当前时间作为fallback: $now');
        }
      }

      // 保存到数据库
      debugPrint('=== savePracticeRaw 开始调用 _db.set 方法 ===');
      debugPrint('参数: _table=$_table, practiceId=$practiceId');
      debugPrint('数据内容: ${data.keys.join(', ')}');
      try {
        await _db.set(_table, practiceId, data);
        debugPrint('_db.set 调用成功');
      } catch (e) {
        debugPrint('错误: _db.set 调用失败: $e');
        debugPrint('错误堆栈: ${e is Error ? e.stackTrace : ''}');
        rethrow;
      }
      debugPrint('savePracticeRaw: 已保存数据到数据库，ID=$practiceId');

      // 验证数据是否已保存
      debugPrint('开始验证数据是否已保存...');
      final savedData = await _db.get(_table, practiceId);
      if (savedData == null) {
        final error = '严重错误: 数据保存后立即查询返回null，ID=$practiceId';
        debugPrint(error);
        throw Exception('数据保存失败，无法在数据库中找到记录: $practiceId');
      }
      debugPrint('数据保存验证成功: ${savedData['title']}');

      // 注意: 缩略图处理已移至 PracticeStorageService
      // 这里不再处理缩略图

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

  /// 只更新收藏状态
  Future<bool> updateFavoriteStatus(String id, bool isFavorite) async {
    try {
      debugPrint('updateFavoriteStatus: id=$id, isFavorite=$isFavorite');

      // 获取当前记录
      final practice = await get(id);
      if (practice == null) {
        debugPrint('updateFavoriteStatus: 找不到ID=$id的记录');
        return false;
      }

      // 准备更新数据
      final data = {
        'id': id,
        'isFavorite': isFavorite ? 1 : 0,
      };

      // 更新数据库
      await _db.save(_table, id, data);
      debugPrint('updateFavoriteStatus: 成功更新收藏状态');
      return true;
    } catch (e) {
      debugPrint('updateFavoriteStatus失败: $e');
      return false;
    }
  }

  /// 构建查询条件
  Map<String, dynamic> _buildQuery(PracticeFilter filter) {
    final query = <String, dynamic>{};

    // 初始化conditions数组
    final conditions = <Map<String, dynamic>>[];

    // 添加标题关键词查询
    if (filter.keyword?.isNotEmpty == true) {
      conditions
          .add({'field': 'title', 'op': 'LIKE', 'val': '%${filter.keyword}%'});
      debugPrint('添加关键词筛选条件: title LIKE %${filter.keyword}%');
    }

    // 添加标签查询
    if (filter.tags.isNotEmpty) {
      // 为每个标签构建一个包含查询
      for (final tag in filter.tags) {
        conditions.add({'field': 'tags', 'op': 'LIKE', 'val': '%$tag%'});
        debugPrint('添加标签筛选条件: tags LIKE %$tag%');
      }
    }

    // 添加状态查询
    if (filter.status?.isNotEmpty == true) {
      conditions.add({'field': 'status', 'op': '=', 'val': filter.status});
      debugPrint('添加状态筛选条件: status=${filter.status}');
    }

    // 添加创建时间查询
    if (filter.startTime != null) {
      conditions.add({
        'field': 'createTime',
        'op': '>=',
        'val': DateTimeHelper.toStorageFormat(filter.startTime!)
      });
      debugPrint(
          '添加开始时间筛选条件: createTime>=${DateTimeHelper.toStorageFormat(filter.startTime!)}');
    }

    if (filter.endTime != null) {
      conditions.add({
        'field': 'createTime',
        'op': '<=',
        'val': DateTimeHelper.toStorageFormat(filter.endTime!)
      });
      debugPrint(
          '添加结束时间筛选条件: createTime<=${DateTimeHelper.toStorageFormat(filter.endTime!)}');
    } // 添加收藏过滤
    if (filter.isFavorite) {
      conditions.add({'field': 'isFavorite', 'op': '=', 'val': 1});
      debugPrint('添加收藏筛选条件: isFavorite=1 (使用条件格式)');
      debugPrint('⚠️ 注意: 如果没有收藏的练习，带有isFavorite=1条件的查询将不返回结果');
    }

    // 如果有条件，将它们添加到查询对象中
    if (conditions.isNotEmpty) {
      query['conditions'] = conditions;
    }

    // 设置排序字段
    final dbSortField = _convertFieldNameToDb(filter.sortField);
    query['orderBy'] = '$dbSortField ${filter.sortOrder}';
    debugPrint('设置排序: ${query['orderBy']}');

    // 设置分页参数
    query['limit'] = filter.limit;
    query['offset'] = filter.offset;

    // 添加整体查询调试日志
    debugPrint('最终查询参数: $query');

    return query;
  }

  /// 将驼峰命名的字段名转换为数据库中的实际字段名
  String _convertFieldNameToDb(String fieldName) {
    // 根据数据库迁移脚本，practices 表中的字段名是 createTime 和 updateTime
    // 不需要转换为下划线命名
    return fieldName;
  }

  Map<String, dynamic> _prepareForSave(Map<String, dynamic> json) {
    debugPrint('_prepareForSave: 开始处理JSON数据，共 ${json.length} 个字段');
    // 创建一个新的Map来避免修改原始数据
    final result = Map<String, dynamic>.from(json);

    // 移除数据库中不存在的status字段
    if (result.containsKey('status')) {
      debugPrint('_prepareForSave: 移除status字段，数据库中不存在该列');
      result.remove('status');
    }

    // 确保isFavorite字段被转换为SQLite兼容的整数值
    if (result.containsKey('isFavorite')) {
      result['isFavorite'] = result['isFavorite'] == true ? 1 : 0;
      debugPrint('_prepareForSave: isFavorite=${result['isFavorite']}');
    } else {
      // 如果不存在，设置默认值
      result['isFavorite'] = 0;
      debugPrint('_prepareForSave: isFavorite字段不存在，设为默认值0');
    }

    // 处理tags字段，将List<String>转换为JSON字符串
    if (result.containsKey('tags') && result['tags'] != null) {
      try {
        if (result['tags'] is List) {
          debugPrint(
              '_prepareForSave: 将tags字段转换为JSON字符串，tags数量: ${result['tags'].length}');
          result['tags'] = jsonEncode(result['tags']);
        } else if (result['tags'] is String) {
          // 如果已经是字符串，不需要处理
          debugPrint('_prepareForSave: tags字段已经是字符串');
        } else {
          // 如果是其他类型，设置为空字符串
          debugPrint('_prepareForSave: tags字段类型未知，设为空字符串');
          result['tags'] = '[]';
        }
      } catch (e) {
        debugPrint('_prepareForSave: 转换tags字段失败: $e，设为空字符串');
        result['tags'] = '[]';
      }
    } else {
      // 如果不存在，设置为空列表的JSON字符串
      result['tags'] = '[]';
      debugPrint('_prepareForSave: tags字段不存在，设为空列表');
    }

    // 处理pages字段，将复杂的List<Map>结构转换为JSON字符串
    if (result.containsKey('pages') && result['pages'] != null) {
      try {
        if (result['pages'] is List) {
          debugPrint(
              '_prepareForSave: 将pages字段转换为JSON字符串，pages数量: ${result['pages'].length}');

          // 🔥 集成智能图像数据管理策略 - 保存前优化
          try {
            final practiceData = {
              'id': result['id'] ?? 'temp-id',
              'elements': result['pages']
            };
            final optimizedElements = preparePracticeDataForSave(practiceData);
            result['pages'] = jsonEncode(optimizedElements['elements']);
            debugPrint('_prepareForSave: 已应用智能图像数据管理优化');
          } catch (optimizeError) {
            debugPrint('_prepareForSave: 智能图像优化失败: $optimizeError，使用原始数据');
            result['pages'] = jsonEncode(result['pages']);
          }
        } else if (result['pages'] is String) {
          // 如果已经是字符串，不需要处理
          debugPrint('_prepareForSave: pages字段已经是字符串');
        } else {
          // 如果是其他类型，设置为空字符串
          debugPrint('_prepareForSave: pages字段类型未知，设为空字符串');
          result['pages'] = '[]';
        }
      } catch (e) {
        debugPrint('_prepareForSave: 转换pages字段失败: $e，设为空字符串');
        result['pages'] = '[]';
      }
    } else {
      // 如果不存在，设置为空列表的JSON字符串
      result['pages'] = '[]';
      debugPrint('_prepareForSave: pages字段不存在，设为空列表');
    }

    // 处理pageCount字段，确保与pages字段保持同步
    // 无论是否已有pageCount字段，都根据当前pages字段重新计算
    int calculatedPageCount = 0;
    if (result['pages'] != null) {
      if (result['pages'] is List) {
        calculatedPageCount = (result['pages'] as List).length;
        debugPrint(
            '_prepareForSave: 根据当前pages数组计算pageCount: $calculatedPageCount');
      } else if (result['pages'] is String) {
        try {
          final pagesData = jsonDecode(result['pages'] as String);
          if (pagesData is List) {
            calculatedPageCount = pagesData.length;
            debugPrint(
                '_prepareForSave: 根据pages JSON计算pageCount: $calculatedPageCount');
          }
        } catch (e) {
          debugPrint('_prepareForSave: 无法解析pages JSON计算pageCount: $e');
          calculatedPageCount = 0;
        }
      }
    }
    result['pageCount'] = calculatedPageCount;
    debugPrint('_prepareForSave: 设置pageCount为: $calculatedPageCount');

    // 处理metadata字段，将Map结构转换为JSON字符串
    if (result.containsKey('metadata') && result['metadata'] != null) {
      try {
        if (result['metadata'] is Map) {
          debugPrint('_prepareForSave: 将metadata字段转换为JSON字符串');
          result['metadata'] = jsonEncode(result['metadata']);
        } else if (result['metadata'] is String) {
          // 如果已经是字符串，验证是否为有效JSON
          debugPrint('_prepareForSave: metadata字段已经是字符串，验证JSON格式');
          try {
            jsonDecode(result['metadata'] as String);
            debugPrint('_prepareForSave: metadata字段JSON格式有效');
          } catch (e) {
            debugPrint('_prepareForSave: metadata字段JSON格式无效，设为空对象: $e');
            result['metadata'] = '{}';
          }
        } else {
          // 如果是其他类型，设置为空JSON对象
          debugPrint('_prepareForSave: metadata字段类型未知，设为空对象');
          result['metadata'] = '{}';
        }
      } catch (e) {
        debugPrint('_prepareForSave: 转换metadata字段失败: $e，设为空对象');
        result['metadata'] = '{}';
      }
    } else {
      // 如果不存在，设置为空JSON对象
      result['metadata'] = '{}';
      debugPrint('_prepareForSave: metadata字段不存在，设为空对象');
    }

    // 处理thumbnail字段，确保SQLite兼容的BLOB类型
    if (result.containsKey('thumbnail') && result['thumbnail'] != null) {
      try {
        if (result['thumbnail'] is List<int>) {
          // JSON序列化后的Uint8List变成List<int>，需要转换回Uint8List
          final thumbnailList = result['thumbnail'] as List<int>;
          result['thumbnail'] = Uint8List.fromList(thumbnailList);
          debugPrint(
              '_prepareForSave: 将thumbnail从List<int>转换为Uint8List，大小: ${thumbnailList.length} 字节');
        } else if (result['thumbnail'] is Uint8List) {
          // 已经是Uint8List，不需要处理
          debugPrint('_prepareForSave: thumbnail字段已经是Uint8List');
        } else {
          // 如果是其他类型，移除该字段
          debugPrint(
              '_prepareForSave: thumbnail字段类型未知，移除该字段: ${result['thumbnail'].runtimeType}');
          result.remove('thumbnail');
        }
      } catch (e) {
        debugPrint('_prepareForSave: 转换thumbnail字段失败: $e，移除该字段');
        result.remove('thumbnail');
      }
    } else if (result.containsKey('thumbnail')) {
      // 如果thumbnail字段存在但为null，移除该字段以避免数据库错误
      result.remove('thumbnail');
      debugPrint('_prepareForSave: thumbnail字段为null，已移除');
    }

    return result;
  }

  /// 处理从数据库获取的数据，确保pages和tags字段格式正确
  Future<Map<String, dynamic>> _processDbData(Map<String, dynamic> data) async {
    // 创建一个新的Map来存储处理后的数据
    final processedData = Map<String, dynamic>.from(data);

    // 处理tags字段，如果是字符串，则解析为JSON
    if (processedData['tags'] is String) {
      final tagsJson = processedData['tags'] as String;
      if (tagsJson.isNotEmpty) {
        try {
          // 解析JSON字符串
          final decodedTags = jsonDecode(tagsJson);

          // 如果解析结果是列表，则直接使用
          if (decodedTags is List) {
            processedData['tags'] = decodedTags;
          } else {
            // 如果不是列表，则使用空列表
            processedData['tags'] = [];
          }
        } catch (e) {
          debugPrint('解析tags字段失败: $e');
          processedData['tags'] = []; // 解析失败时使用空列表
        }
      } else {
        processedData['tags'] = []; // 空字符串时使用空列表
      }
    } else if (processedData['tags'] == null) {
      processedData['tags'] = []; // null时使用空列表
    }

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

            // 🔥 集成智能图像数据管理策略 - 加载后恢复
            try {
              final savedElements = List<Map<String, dynamic>>.from(
                  decodedPages.cast<Map<String, dynamic>>());
              final restoredElements = restorePracticeDataFromSave({
                'id': processedData['id'],
                'elements': savedElements,
              });
              processedData['pages'] = restoredElements['elements'];
              debugPrint('_processDbData: 已应用智能图像数据管理恢复');

              // 🔄 路径转换：将相对路径转换为绝对路径（用于渲染）
              await _convertImagePathsToAbsolute(processedData['pages']);
              debugPrint('_processDbData: 已转换图像路径为绝对路径');
            } catch (restoreError) {
              debugPrint('_processDbData: 智能图像恢复失败: $restoreError，使用原始数据');
              // 继续使用已解析的数据
            }
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
    } // 处理isFavorite字段，确保是布尔类型
    if (processedData.containsKey('isFavorite')) {
      // SQLite中0表示false，1表示true
      processedData['isFavorite'] = processedData['isFavorite'] == 1;
      debugPrint(
          '_processDbData: 从数据库读取 isFavorite=${processedData['isFavorite']}');
    } else {
      // 如果不存在，设置为默认值false
      processedData['isFavorite'] = false;
      debugPrint('_processDbData: isFavorite字段不存在，设为默认值false');
    }

    // 处理pageCount字段，确保是整数类型
    if (processedData.containsKey('pageCount')) {
      // 确保pageCount是整数类型
      if (processedData['pageCount'] is int) {
        debugPrint(
            '_processDbData: 从数据库读取 pageCount=${processedData['pageCount']}');
      } else {
        // 尝试转换为整数
        try {
          processedData['pageCount'] =
              int.tryParse(processedData['pageCount'].toString()) ?? 0;
          debugPrint(
              '_processDbData: 转换 pageCount=${processedData['pageCount']}');
        } catch (e) {
          processedData['pageCount'] = 0;
          debugPrint('_processDbData: pageCount转换失败，设为0');
        }
      }
    } else {
      // 如果数据库中没有pageCount字段，根据pages计算
      int calculatedPageCount = 0;
      if (processedData['pages'] is List) {
        calculatedPageCount = (processedData['pages'] as List).length;
      }
      processedData['pageCount'] = calculatedPageCount;
      debugPrint(
          '_processDbData: pageCount字段不存在，根据pages计算得到: $calculatedPageCount');
    }

    // 处理metadata字段，将JSON字符串解析为Map
    if (processedData.containsKey('metadata') &&
        processedData['metadata'] != null) {
      if (processedData['metadata'] is String) {
        final metadataJson = processedData['metadata'] as String;
        if (metadataJson.isNotEmpty) {
          try {
            final decodedMetadata = jsonDecode(metadataJson);
            if (decodedMetadata is Map<String, dynamic>) {
              processedData['metadata'] = decodedMetadata;
              debugPrint('_processDbData: 成功解析metadata JSON');
            } else {
              processedData['metadata'] = <String, dynamic>{};
              debugPrint('_processDbData: metadata解析结果不是Map，使用空对象');
            }
          } catch (e) {
            debugPrint('_processDbData: 解析metadata JSON失败: $e，使用空对象');
            processedData['metadata'] = <String, dynamic>{};
          }
        } else {
          processedData['metadata'] = <String, dynamic>{};
          debugPrint('_processDbData: metadata字段为空字符串，使用空对象');
        }
      } else if (processedData['metadata'] is Map) {
        debugPrint('_processDbData: metadata字段已经是Map类型');
      } else {
        processedData['metadata'] = <String, dynamic>{};
        debugPrint('_processDbData: metadata字段类型未知，使用空对象');
      }
    } else {
      processedData['metadata'] = <String, dynamic>{};
      debugPrint('_processDbData: metadata字段不存在，使用空对象');
    }

    // 处理status字段，数据库表中不存在但实体模型中需要
    if (!processedData.containsKey('status')) {
      processedData['status'] = 'active'; // 使用默认值
      debugPrint('_processDbData: status字段不存在于数据库，设为默认值active');
    }

    // 移除数据库中的旧thumbnail字段，现在缩略图从文件系统加载
    if (processedData.containsKey('thumbnail')) {
      processedData.remove('thumbnail');
    }

    return processedData;
  }

  /// 将pages中的图像路径从相对路径转换为绝对路径
  Future<void> _convertImagePathsToAbsolute(List<dynamic> pages) async {
    if (pages.isEmpty) return;

    for (final page in pages) {
      if (page is! List) continue;

      for (final element in page) {
        if (element is! Map<String, dynamic>) continue;

        final elementType = element['type'] as String?;
        if (elementType != 'image') continue;

        final content = element['content'];
        if (content is! Map<String, dynamic>) continue;

        final imageUrl = content['imageUrl'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) continue;

        // 如果是相对路径，转换为绝对路径
        if (ImagePathConverter.isRelativePath(imageUrl)) {
          try {
            content['imageUrl'] =
                await ImagePathConverter.toAbsolutePath(imageUrl);
          } catch (e) {
            debugPrint('路径转换失败，保持原路径: $imageUrl, 错误: $e');
          }
        }
      }
    }
  }

  /// 迁移数据库中的绝对路径到相对路径
  ///
  /// 扫描所有Practice记录，将其中的绝对图像路径转换为相对路径
  Future<PathMigrationResult> migrateImagePathsToRelative({
    void Function(int processed, int total)? onProgress,
  }) async {
    try {
      AppLogger.info('开始迁移数据库中的图像路径', tag: 'PracticeRepository');

      // 获取所有practice记录
      final allPractices = await _db.query(_table, {});
      final totalCount = allPractices.length;
      int processedCount = 0;
      final failedPaths = <String>[];

      AppLogger.info('找到 $totalCount 个练习记录需要检查', tag: 'PracticeRepository');

      for (final practice in allPractices) {
        try {
          // 解析pages字段
          if (practice['pages'] is String) {
            final pagesJson = practice['pages'] as String;
            if (pagesJson.isNotEmpty) {
              final decodedPages = jsonDecode(pagesJson);
              if (decodedPages is List) {
                // 检查并转换图像路径
                final convertedPages = await _convertImagePathsInPages(
                    decodedPages,
                    toRelative: true);
                if (convertedPages != decodedPages) {
                  // 更新数据库记录
                  final updateData = {
                    'pages': jsonEncode(convertedPages),
                    'updateTime':
                        DateTimeHelper.toStorageFormat(DateTime.now()),
                  };

                  await _db.save(_table, practice['id'] as String, updateData);
                  AppLogger.debug('已更新练习记录的图像路径',
                      tag: 'PracticeRepository',
                      data: {'practiceId': practice['id']});
                }
              }
            }
          }

          processedCount++;
          onProgress?.call(processedCount, totalCount);
        } catch (e) {
          final practiceId = practice['id']?.toString() ?? 'unknown';
          AppLogger.error('迁移练习记录失败',
              error: e,
              tag: 'PracticeRepository',
              data: {'practiceId': practiceId});
          failedPaths.add(practiceId);
        }
      }

      AppLogger.info('图像路径迁移完成', tag: 'PracticeRepository', data: {
        'totalCount': totalCount,
        'processedCount': processedCount,
        'failedCount': failedPaths.length,
      });

      return PathMigrationResult.success(
        processedCount: processedCount,
        totalCount: totalCount,
        failedPaths: failedPaths,
      );
    } catch (e) {
      AppLogger.error('图像路径迁移失败', error: e, tag: 'PracticeRepository');
      return PathMigrationResult.failure(errorMessage: e.toString());
    }
  }

  /// 转换pages中的图像路径
  ///
  /// [toRelative] 如果为true，将绝对路径转换为相对路径；如果为false，将相对路径转换为绝对路径
  Future<List<dynamic>> _convertImagePathsInPages(List<dynamic> pages,
      {required bool toRelative}) async {
    final convertedPages = <dynamic>[];

    for (final page in pages) {
      if (page is! List) {
        convertedPages.add(page);
        continue;
      }

      final convertedElements = <dynamic>[];

      for (final element in page) {
        if (element is! Map<String, dynamic>) {
          convertedElements.add(element);
          continue;
        }

        final convertedElement = Map<String, dynamic>.from(element);
        final elementType = convertedElement['type'] as String?;

        if (elementType == 'image') {
          final content = convertedElement['content'];
          if (content is Map<String, dynamic>) {
            final imageUrl = content['imageUrl'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              if (toRelative) {
                // 转换为相对路径（保存时使用）
                if (!ImagePathConverter.isRelativePath(imageUrl)) {
                  // 只转换绝对路径
                  final convertedContent = Map<String, dynamic>.from(content);
                  convertedContent['imageUrl'] =
                      ImagePathConverter.toRelativePath(imageUrl);
                  convertedElement['content'] = convertedContent;

                  AppLogger.debug('转换绝对路径为相对路径',
                      tag: 'PracticeRepository',
                      data: {
                        'original': imageUrl,
                        'converted': convertedContent['imageUrl'],
                      });
                }
              } else {
                // 转换为绝对路径（加载时使用）
                if (ImagePathConverter.isRelativePath(imageUrl)) {
                  try {
                    final convertedContent = Map<String, dynamic>.from(content);
                    convertedContent['imageUrl'] =
                        await ImagePathConverter.toAbsolutePath(imageUrl);
                    convertedElement['content'] = convertedContent;
                  } catch (e) {
                    AppLogger.warning('路径转换失败，保持原路径',
                        error: e,
                        tag: 'PracticeRepository',
                        data: {'path': imageUrl});
                  }
                }
              }
            }
          }
        }

        convertedElements.add(convertedElement);
      }

      convertedPages.add(convertedElements);
    }

    return convertedPages;
  }

  /// 构建WHERE子句
  String _buildWhereClause(Map<String, dynamic> queryParams) {
    if (!queryParams.containsKey('conditions')) return '';

    final conditions = queryParams['conditions'] as List;
    final whereClause = conditions.map((condition) {
      final field = condition['field'];
      final op = condition['op'];
      return '$field $op ?';
    }).join(' AND ');

    return whereClause;
  }

  /// 构建WHERE参数
  List<dynamic> _buildWhereArgs(Map<String, dynamic> queryParams) {
    if (!queryParams.containsKey('conditions')) return [];

    final conditions = queryParams['conditions'] as List;
    return conditions.map((condition) => condition['val']).toList();
  }

  /// 处理从数据库获取的数据（列表专用，不包含pages字段）
  Future<Map<String, dynamic>> _processDbDataForList(
      Map<String, dynamic> data) async {
    // 创建一个新的Map来存储处理后的数据
    final processedData = Map<String, dynamic>.from(data);

    // 处理tags字段，如果是字符串，则解析为JSON
    if (processedData['tags'] is String) {
      final tagsJson = processedData['tags'] as String;
      if (tagsJson.isNotEmpty) {
        try {
          // 解析JSON字符串
          final decodedTags = jsonDecode(tagsJson);

          // 如果解析结果是列表，则直接使用
          if (decodedTags is List) {
            processedData['tags'] = decodedTags;
          } else {
            // 如果不是列表，则使用空列表
            processedData['tags'] = [];
          }
        } catch (e) {
          debugPrint('解析tags字段失败: $e');
          processedData['tags'] = []; // 解析失败时使用空列表
        }
      } else {
        processedData['tags'] = []; // 空字符串时使用空列表
      }
    } else if (processedData['tags'] == null) {
      processedData['tags'] = []; // null时使用空列表
    }

    // 处理isFavorite字段，确保是布尔类型
    if (processedData.containsKey('isFavorite')) {
      // SQLite中0表示false，1表示true
      processedData['isFavorite'] = processedData['isFavorite'] == 1;
      debugPrint(
          '_processDbDataForList: 从数据库读取 isFavorite=${processedData['isFavorite']}');
    } else {
      // 如果不存在，设置为默认值false
      processedData['isFavorite'] = false;
      debugPrint('_processDbDataForList: isFavorite字段不存在，设为默认值false');
    }

    // 处理pageCount字段，确保是整数类型
    if (processedData.containsKey('pageCount')) {
      // 确保pageCount是整数类型
      if (processedData['pageCount'] is int) {
        debugPrint(
            '_processDbDataForList: 从数据库读取 pageCount=${processedData['pageCount']}');
      } else {
        // 尝试转换为整数
        try {
          processedData['pageCount'] =
              int.tryParse(processedData['pageCount'].toString()) ?? 0;
          debugPrint(
              '_processDbDataForList: 转换 pageCount=${processedData['pageCount']}');
        } catch (e) {
          processedData['pageCount'] = 0;
          debugPrint('_processDbDataForList: pageCount转换失败，设为0');
        }
      }
    } else {
      // 如果数据库中没有pageCount字段，设为默认值0
      processedData['pageCount'] = 0;
      debugPrint('_processDbDataForList: pageCount字段不存在，设为默认值0');
    }

    // 处理metadata字段（列表查询时保持为JSON字符串，不解析以提高性能）
    if (processedData.containsKey('metadata') &&
        processedData['metadata'] != null) {
      if (processedData['metadata'] is String) {
        // 验证JSON格式但不解析，保持字符串格式以提高列表查询性能
        final metadataJson = processedData['metadata'] as String;
        if (metadataJson.isEmpty) {
          processedData['metadata'] = <String, dynamic>{};
          debugPrint('_processDbDataForList: metadata为空字符串，使用空对象');
        } else {
          try {
            jsonDecode(metadataJson); // 仅验证格式，不使用结果
            // 对于列表查询，我们将JSON字符串转换为空对象以节省内存
            processedData['metadata'] = <String, dynamic>{};
            debugPrint('_processDbDataForList: metadata JSON格式有效，使用空对象');
          } catch (e) {
            processedData['metadata'] = <String, dynamic>{};
            debugPrint('_processDbDataForList: metadata JSON格式无效，使用空对象');
          }
        }
      } else {
        processedData['metadata'] = <String, dynamic>{};
        debugPrint('_processDbDataForList: metadata字段类型非字符串，使用空对象');
      }
    } else {
      processedData['metadata'] = <String, dynamic>{};
      debugPrint('_processDbDataForList: metadata字段不存在，使用空对象');
    }

    // 处理status字段，数据库表中不存在但实体模型中需要
    if (!processedData.containsKey('status')) {
      processedData['status'] = 'active'; // 使用默认值
      debugPrint('_processDbDataForList: status字段不存在于数据库，设为默认值active');
    }

    // 保留thumbnail字段（从数据库获取）
    if (processedData['thumbnail'] != null) {
      debugPrint('_processDbDataForList: 保留缩略图数据');
    }

    return processedData;
  }
}
