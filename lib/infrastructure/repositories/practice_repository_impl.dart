import '../../domain/models/practice/practice_entity.dart';
import '../../domain/models/practice/practice_filter.dart';
import '../../domain/repositories/practice_repository.dart';
import '../persistence/database_interface.dart';

/// 字帖练习仓库实现
class PracticeRepositoryImpl implements PracticeRepository {
  static const _table = 'practices';
  final DatabaseInterface _db;

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
    final data = await _db.get(_table, id);
    if (data == null) return null;
    return PracticeEntity.fromJson(data);
  }

  @override
  Future<List<PracticeEntity>> getAll() async {
    final list = await _db.getAll(_table);
    return list.map((e) => PracticeEntity.fromJson(e)).toList();
  }

  @override
  Future<Set<String>> getAllTags() async {
    final list = await _db.getAll(_table);
    final tags = <String>{};
    for (final item in list) {
      final practice = PracticeEntity.fromJson(item);
      tags.addAll(practice.tags);
    }
    return tags;
  }

  @override
  Future<List<PracticeEntity>> getByTags(Set<String> tags) async {
    if (tags.isEmpty) return [];

    final filter = PracticeFilter(tags: tags.toList());
    return query(filter);
  }

  @override
  Future<List<PracticeEntity>> query(PracticeFilter filter) async {
    final query = _buildQuery(filter);
    final list = await _db.query(_table, query);
    return list.map((e) => PracticeEntity.fromJson(e)).toList();
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
      query['create_time'] = {
        'gte': filter.startTime!.toIso8601String(),
      };
    }

    if (filter.endTime != null) {
      query['create_time'] ??= {};
      query['create_time']['lte'] = filter.endTime!.toIso8601String();
    }

    query['sort'] = {
      filter.sortField: filter.sortOrder,
    };

    query['limit'] = filter.limit;
    query['offset'] = filter.offset;

    return query;
  }
}
