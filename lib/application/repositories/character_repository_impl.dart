import 'dart:convert';

import '../../domain/models/character/character_entity.dart';
import '../../domain/models/character/character_region.dart';
import '../../domain/repositories/character_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../infrastructure/persistence/models/database_query.dart';

/// 字符仓库实现
class CharacterRepositoryImpl implements CharacterRepository {
  static const String _table = 'characters';
  final DatabaseInterface _db;

  CharacterRepositoryImpl(this._db);

  @override
  Future<int> count(CharacterFilter? filter) async {
    try {
      final query = _buildFilterQuery(filter).toJson();
      final result = await _db.count(_table, query);
      return result;
    } catch (e) {
      AppLogger.error('Failed to count characters',
          tag: 'CharacterRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<CharacterEntity> create(CharacterEntity character) async {
    await _db.set(_table, character.id, _toDbMap(character));
    return character;
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, id);
  }

  @override
  Future<void> deleteBatch(List<String> ids) => deleteMany(ids);

  @override
  Future<void> deleteMany(List<String> ids) async {
    await _db.deleteMany(_table, ids);
  }

  @override
  Future<CharacterEntity?> findById(String id) => get(id);

  @override
  Future<List<CharacterEntity>> findByWorkId(String workId) =>
      getByWorkId(workId);

  @override
  Future<CharacterEntity?> get(String id) async {
    final data = await _db.get(_table, id);
    if (data == null) return null;
    return _fromDbMap(data);
  }

  @override
  Future<List<CharacterEntity>> getAll() async {
    final data = await _db.getAll(_table);
    return data.map((e) => _fromDbMap(e)).toList();
  }

  @override
  Future<List<CharacterEntity>> getByWorkId(String workId) async {
    final query = DatabaseQuery(conditions: [
      DatabaseQueryCondition(field: 'workId', operator: '=', value: workId)
    ]);
    final results = await _db.query(_table, query.toJson());
    return results.map((map) => _fromDbMap(map)).toList();
  }

  @override
  Future<List<CharacterRegion>> getRegionsByPageId(String pageId) async {
    try {
      final query = DatabaseQuery(conditions: [
        DatabaseQueryCondition(field: 'pageId', operator: '=', value: pageId)
      ]);
      final results = await _db.query(_table, query.toJson());

      return results.map((map) => _fromDbMap(map).region).toList();
    } catch (e) {
      AppLogger.error('Failed to get regions by page id',
          tag: 'CharacterRepository', error: e, data: {'pageId': pageId});
      rethrow;
    }
  }

  @override
  Future<List<CharacterRegion>> getRegionsByWorkId(String workId) async {
    try {
      final query = DatabaseQuery(conditions: [
        DatabaseQueryCondition(field: 'workId', operator: '=', value: workId)
      ]);
      final results = await _db.query(_table, query.toJson());

      return results.map((map) => _fromDbMap(map).region).toList();
    } catch (e) {
      AppLogger.error('Failed to get regions by work id',
          tag: 'CharacterRepository', error: e, data: {'workId': workId});
      rethrow;
    }
  }

  @override
  Future<List<CharacterEntity>> query(CharacterFilter filter) async {
    try {
      final query = _buildFilterQuery(filter);

      final results = await _db.query(_table, query.toJson());
      return results.map((map) => _fromDbMap(map)).toList();
    } catch (e) {
      AppLogger.error('Failed to query characters',
          tag: 'CharacterRepository', error: e);
      rethrow;
    }
  }

  @override
  Future<CharacterEntity> save(CharacterEntity character) async {
    final now = DateTime.now();
    final updated = character.copyWith(updateTime: now);
    await _db.save(_table, updated.id, _toDbMap(updated));
    return updated;
  }

  @override
  Future<List<CharacterEntity>> saveMany(
      List<CharacterEntity> characters) async {
    final now = DateTime.now();
    final updates = {
      for (final character in characters)
        character.id: _toDbMap(character.copyWith(updateTime: now))
    };

    await _db.saveMany(_table, updates);
    return characters.map((c) => c.copyWith(updateTime: now)).toList();
  }

  @override
  Future<List<CharacterEntity>> search(String query, {int? limit}) async {
    // 参数验证
    if (query.trim().isEmpty) return [];
    if (limit != null && limit <= 0) {
      throw ArgumentError('Limit must be a positive number');
    }

    try {
      // 构建搜索查询
      final searchQuery = DatabaseQuery(conditions: [
        DatabaseQueryCondition(
            field: 'character', operator: 'LIKE', value: '%${query.trim()}%')
      ], limit: limit, orderBy: 'character ASC');

      // 执行优化后的查询
      final results = await _db.query(_table, searchQuery.toJson());

      // 转换结果
      return results.map((map) => _fromDbMap(map)).toList();
    } catch (e) {
      AppLogger.error('Failed to search characters',
          tag: 'CharacterRepository',
          error: e,
          data: {
            'query': query,
            'limit': limit,
          });
      rethrow;
    }
  }

  @override
  Future<void> updateRegion(CharacterRegion region) async {
    try {
      final character = await findById(region.characterId ?? region.id);
      if (character == null) {
        throw Exception('Character not found: ${region.id}');
      }

      final updated = character.copyWith(
        region: region,
        updateTime: DateTime.now(),
      );

      await save(updated);
    } catch (e) {
      AppLogger.error('Failed to update region',
          tag: 'CharacterRepository', error: e, data: {'id': region.id});
      rethrow;
    }
  }

  // Helper methods
  DatabaseQuery _buildFilterQuery(CharacterFilter? filter) {
    final conditions = <DatabaseQueryCondition>[];

    if (filter == null) {
      return const DatabaseQuery();
    }

    // 工作ID过滤
    if (filter.workId != null) {
      conditions.add(DatabaseQueryCondition(
        field: 'workId',
        operator: '=',
        value: filter.workId,
      ));
    }

    // 页面ID过滤
    if (filter.pageId != null) {
      conditions.add(DatabaseQueryCondition(
        field: 'pageId',
        operator: '=',
        value: filter.pageId,
      ));
    }

    // 文本搜索过滤
    if (filter.searchText != null && filter.searchText!.isNotEmpty) {
      conditions.add(DatabaseQueryCondition(
        field: 'character',
        operator: 'LIKE',
        value: '%${filter.searchText}%',
      ));
    }

    // 收藏状态过滤
    if (filter.isFavorite != null) {
      conditions.add(DatabaseQueryCondition(
        field: 'isFavorite',
        operator: '=',
        value: filter.isFavorite! ? 1 : 0,
      ));
    }

    // 标签过滤
    if (filter.tags != null && filter.tags!.isNotEmpty) {
      final tagConditions = filter.tags!.map((tag) {
        return DatabaseQueryCondition(
          field: 'tags',
          operator: 'LIKE',
          value: '%$tag%',
        );
      }).toList();

      if (tagConditions.length == 1) {
        conditions.add(tagConditions.first);
      } else if (tagConditions.isNotEmpty) {
        conditions.add(DatabaseQueryCondition(
          field: 'tags',
          operator: 'ALL',
          value: filter.tags,
        ));
      }
    }

    // 时间范围过滤
    if (filter.fromDate != null) {
      conditions.add(DatabaseQueryCondition(
        field: 'createTime',
        operator: '>=',
        value: filter.fromDate!.toIso8601String(),
      ));
    }

    if (filter.toDate != null) {
      conditions.add(DatabaseQueryCondition(
        field: 'createTime',
        operator: '<=',
        value: filter.toDate!.toIso8601String(),
      ));
    }

    // 构建排序子句
    String? orderBy;
    if (filter.sortBy != null) {
      final field = _getSortField(filter.sortBy!);
      final direction =
          filter.sortDirection == SortDirection.descending ? 'DESC' : 'ASC';
      orderBy = '$field $direction';
    }

    // 构建最终查询
    return DatabaseQuery(
      conditions: conditions,
      orderBy: orderBy,
      limit: filter.limit,
      offset: filter.offset,
    );
  }

  CharacterEntity _fromDbMap(Map<String, dynamic> map) {
    // Parse region field
    final regionJson = jsonDecode(map['region'] as String);
    final region = CharacterRegion.fromJson(regionJson).copyWith(
      characterId: map['id'] as String,
    );

    // Parse tags field
    final tagsJson = map['tags'] as String?;
    final tags = tagsJson != null && tagsJson.isNotEmpty
        ? (jsonDecode(tagsJson) as List<dynamic>).cast<String>()
        : <String>[];

    return CharacterEntity(
      id: map['id'] as String,
      workId: map['workId'] as String,
      pageId: map['pageId'] as String,
      character: map['character'] as String,
      region: region,
      createTime: DateTime.parse(map['createTime'] as String),
      updateTime: DateTime.parse(map['updateTime'] as String),
      isFavorite: (map['isFavorite'] as int) == 1,
      tags: tags,
      note: map['note'] as String?,
    );
  }

  String _getSortField(SortField field) {
    switch (field) {
      case SortField.character:
        return 'character';
      case SortField.createTime:
        return 'createTime';
      case SortField.updateTime:
        return 'updateTime';
    }
  }

  Map<String, dynamic> _toDbMap(CharacterEntity entity) {
    return {
      'id': entity.id,
      'workId': entity.workId,
      'pageId': entity.pageId,
      'character': entity.character,
      'region': jsonEncode(entity.region.toJson()),
      'createTime': entity.createTime.toIso8601String(),
      'updateTime': entity.updateTime.toIso8601String(),
      'isFavorite': entity.isFavorite ? 1 : 0,
      'tags': entity.tags.join(','),
      'note': entity.note,
    };
  }
}
