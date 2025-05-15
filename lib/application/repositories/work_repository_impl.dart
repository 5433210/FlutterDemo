import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_filter.dart';
import '../../domain/repositories/work_repository.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/persistence/database_interface.dart';
import '../../infrastructure/persistence/models/database_query.dart';
import '../../utils/date_time_helper.dart';

/// 作品仓库实现
class WorkRepositoryImpl implements WorkRepository {
  final DatabaseInterface _db;
  final String _table = 'works';

  WorkRepositoryImpl(this._db);

  @override
  Future<void> close() async {
    await _db.close();
  }

  @override
  Future<int> count(WorkFilter? filter) async {
    final query = _buildQuery(filter);
    return _db.count(_table, query);
  }

  @override
  Future<WorkEntity> create(WorkEntity work) async {
    await _db.set(_table, work.id, _toTableJson(work));
    return work;
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, id);
  }

  @override
  Future<void> deleteMany(List<String> ids) async {
    await _db.deleteMany(_table, ids);
  }

  @override
  Future<WorkEntity> duplicate(String id, {String? newId}) async {
    final work = await get(id);
    if (work == null) {
      throw Exception('Work not found: $id');
    }

    final now = DateTime.now();
    final duplicated = work.copyWith(
      id: newId ?? '${work.id}_copy',
      createTime: now,
      updateTime: now,
    );

    await _db.set(_table, duplicated.id, _toTableJson(duplicated));
    return duplicated;
  }

  @override
  Future<WorkEntity?> get(String id) async {
    final data = await _db.get(_table, id);
    if (data == null) return null;
    return WorkEntity.fromJson(_convertDates(data));
  }

  @override
  Future<List<WorkEntity>> getAll() async {
    final data = await _db.getAll(_table);
    return data.map((e) => WorkEntity.fromJson(_convertDates(e))).toList();
  }

  @override
  Future<Set<String>> getAllTags() async {
    final works = await getAll();
    return works.expand((work) => work.tags).toSet();
  }

  @override
  Future<List<WorkEntity>> getByTags(Set<String> tags) async {
    if (tags.isEmpty) return [];

    final query = DatabaseQuery(conditions: [
      DatabaseQueryCondition(
        field: 'tags',
        operator: 'contains',
        value: tags.toList(),
      ),
    ]);

    final data = await _db.query(_table, query.toJson());
    return data.map((e) => WorkEntity.fromJson(_convertDates(e))).toList();
  }

  @override
  Future<List<WorkEntity>> query(WorkFilter filter) async {
    final query = _buildQuery(filter);
    final data = await _db.query(_table, query);
    return data.map((e) => WorkEntity.fromJson(_convertDates(e))).toList();
  }

  @override
  Future<WorkEntity> save(WorkEntity work) async {
    final now = DateTime.now();
    final updated = work.copyWith(updateTime: now);
    await _db.save(_table, work.id, _toTableJson(updated));
    return updated;
  }

  @override
  Future<List<WorkEntity>> saveMany(List<WorkEntity> works) async {
    final now = DateTime.now();
    final updates = {
      for (final work in works)
        work.id: _toTableJson(work.copyWith(updateTime: now))
    };

    await _db.saveMany(_table, updates);
    return works.map((w) => w.copyWith(updateTime: now)).toList();
  }

  @override
  Future<List<WorkEntity>> search(String query, {int? limit}) async {
    // 创建一个只包含搜索条件的过滤器
    final filter = WorkFilter(keyword: query);
    final results = await this.query(filter);

    if (limit != null && results.length > limit) {
      return results.take(limit).toList();
    }
    return results;
  }

  @override
  Future<List<String>> suggestTags(String prefix, {int limit = 10}) async {
    final allTags = await getAllTags();
    return allTags
        .where((tag) => tag.toLowerCase().startsWith(prefix.toLowerCase()))
        .take(limit)
        .toList();
  }

  /// 构建数据库查询
  Map<String, dynamic> _buildQuery(WorkFilter? filter) {
    AppLogger.debug(
      '开始构建查询条件',
      tag: 'WorkRepositoryImpl',
      data: {
        'hasFilter': filter != null,
        'style': filter?.style?.name,
        'tool': filter?.tool?.name,
        'tagsCount': filter?.tags.length ?? 0,
        'hasKeyword': filter?.keyword?.isNotEmpty ?? false,
      },
    );

    if (filter == null) return {};

    final conditions = <DatabaseQueryCondition>[];
    final groups = <DatabaseQueryGroup>[];

    // 基本过滤
    if (filter.style != null) {
      conditions.add(DatabaseQueryCondition(
        field: 'style',
        operator: '=',
        value: filter.style?.name,
      ));
    }

    if (filter.tool != null) {
      conditions.add(DatabaseQueryCondition(
        field: 'tool',
        operator: '=',
        value: filter.tool?.name,
      ));
    }

    if (filter.tags.isNotEmpty) {
      conditions.add(DatabaseQueryCondition(
        field: 'tags',
        operator: 'contains',
        value: filter.tags,
      ));
    } // 搜索关键字
    if (filter.keyword?.isNotEmpty == true) {
      groups.add(
        DatabaseQueryGroup.or([
          DatabaseQueryCondition(
            field: 'title',
            operator: 'like',
            value: '%${filter.keyword}%',
          ),
          DatabaseQueryCondition(
            field: 'author',
            operator: 'like',
            value: '%${filter.keyword}%',
          ),
          DatabaseQueryCondition(
            field: 'remark',
            operator: 'like',
            value: '%${filter.keyword}%',
          ),
          // 添加标签模糊搜索
          DatabaseQueryCondition(
            field: 'tags',
            operator: 'like',
            value: '%${filter.keyword}%',
          ),
        ]),
      );
    }

    // 日期范围过滤
    if (filter.dateRange != null) {
      final start = filter.dateRange?.start;
      final end = filter.dateRange?.end;
      if (start != null && end != null) {
        conditions.add(DatabaseQueryCondition(
          field: 'creationDate',
          operator: '>=',
          value: DateTimeHelper.toStorageFormat(start),
        ));

        conditions.add(DatabaseQueryCondition(
          field: 'creationDate',
          operator: '<=',
          value: DateTimeHelper.toStorageFormat(end),
        ));
      }
    }

    // 创建时间过滤
    if (filter.createTimeRange != null) {
      final start = filter.createTimeRange?.start;
      final end = filter.createTimeRange?.end;
      if (start != null && end != null) {
        conditions.add(DatabaseQueryCondition(
          field: 'createTime',
          operator: '>=',
          value: DateTimeHelper.toStorageFormat(start),
        ));

        conditions.add(DatabaseQueryCondition(
          field: 'createTime',
          operator: '<=',
          value: DateTimeHelper.toStorageFormat(end),
        ));
      }
    }

    // 更新时间过滤
    if (filter.updateTimeRange != null) {
      final start = filter.updateTimeRange?.start;
      final end = filter.updateTimeRange?.end;
      if (start != null && end != null) {
        conditions.add(DatabaseQueryCondition(
          field: 'updateTime',
          operator: '>=',
          value: DateTimeHelper.toStorageFormat(start),
        ));

        conditions.add(DatabaseQueryCondition(
          field: 'updateTime',
          operator: '<=',
          value: DateTimeHelper.toStorageFormat(end),
        ));
      }
    }

    final query = DatabaseQuery(
      conditions: conditions,
      groups: groups.isEmpty ? null : groups,
      orderBy: filter.sortOption.field != null
          ? '${filter.sortOption.field.name} ${filter.sortOption.descending ? 'DESC' : 'ASC'}'
          : null,
      limit: filter.limit,
      offset: filter.offset,
    );
    // AppLogger.debug(
    //   '查询条件构建完成',
    //   tag: 'WorkRepositoryImpl',
    //   data: {
    //     'conditions': conditions.length,
    //     'groups': groups.length,
    //     'hasOrderBy': filter.sortOption.field != null,
    //     'orderBy': filter.sortOption.field.name,
    //     'isDescending': filter.sortOption.descending,
    //   },
    // );

    return query.toJson();
  }

  /// 将数据库中的时间戳转换为ISO8601字符串
  Map<String, dynamic> _convertDates(Map<String, dynamic> data) {
    return {
      ...data,
      'tags': data['tags']
              ?.toString()
              .split(',')
              .where((tag) => tag.isNotEmpty)
              .toList() ??
          const [],
      'creationDate': data['creationDate'],
      'createTime': data['createTime'],
      'updateTime': data['updateTime'],
      'lastImageUpdateTime': data['lastImageUpdateTime'],
    };
  }

  /// 将时间字段转换为ISO8601字符串
  String? _convertToIso8601String(dynamic value) {
    if (value == null) {
      return null;
    }

    // 如果已经是字符串格式，检查是否为ISO8601格式
    if (value is String && value.contains('T')) {
      return value;
    }

    // 否则作为时间戳处理
    return DateTime.fromMillisecondsSinceEpoch(value as int).toIso8601String();
  }

  /// 将WorkEntity转换为数据库表字段
  Map<String, dynamic> _toTableJson(WorkEntity work) {
    return {
      'id': work.id,
      'title': work.title,
      'author': work.author,
      'style': work.style.value,
      'tool': work.tool.value,
      'remark': work.remark,
      'creationDate': DateTimeHelper.toStorageFormat(work.creationDate),
      'createTime': DateTimeHelper.toStorageFormat(work.createTime),
      'updateTime': DateTimeHelper.toStorageFormat(work.updateTime),
      'lastImageUpdateTime':
          DateTimeHelper.toStorageFormat(work.lastImageUpdateTime),
      'status': work.status.name,
      'firstImageId': work.firstImageId,
      'tags': work.tags.join(','),
      'imageCount': work.imageCount
    };
  }
}
