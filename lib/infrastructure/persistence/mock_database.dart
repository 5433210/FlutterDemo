import '../../domain/models/work/work_entity.dart';
import '../../domain/models/work/work_filter.dart';
import 'database_interface.dart';

/// 用于测试的总是失败的数据库
class FailingMockDatabase implements DatabaseInterface {
  @override
  bool get isInitialized => false;

  @override
  Future<void> clear(String table) async => throw UnimplementedError();
  @override
  Future<void> close() async => throw UnimplementedError();
  @override
  Future<int> count(String table, [Map<String, dynamic>? filter]) async =>
      throw UnimplementedError();
  @override
  Future<void> delete(String table, String id) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteMany(String table, List<String> ids) async =>
      throw UnimplementedError();
  @override
  Future<Map<String, dynamic>?> get(String table, String id) async =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> getAll(String table) async =>
      throw UnimplementedError();
  @override
  Future<void> initialize() async {
    throw Exception('模拟数据库初始化失败');
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table,
    Map<String, dynamic> filter,
  ) async =>
      throw UnimplementedError();
  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async =>
      throw UnimplementedError();
  @override
  Future<int> rawUpdate(String sql, [List<Object?>? args]) async =>
      throw UnimplementedError();
  @override
  Future<void> save(String table, String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();
  @override
  Future<void> saveMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async =>
      throw UnimplementedError();
  @override
  Future<void> set(String table, String id, Map<String, dynamic> data) async =>
      throw UnimplementedError();

  @override
  Future<void> setMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async =>
      throw UnimplementedError();
}

/// 用于测试的模拟数据库
class MockDatabase implements DatabaseInterface {
  bool _isInitialized = false;
  final Map<String, Map<String, Map<String, dynamic>>> _storage = {};

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> clear(String table) async {
    _checkInitialized();
    _storage[table]?.clear();
  }

  @override
  Future<void> close() async {
    _storage.clear();
    _isInitialized = false;
  }

  @override
  Future<int> count(String table, [Map<String, dynamic>? filter]) async {
    _checkInitialized();
    return _storage[table]?.length ?? 0;
  }

  @override
  Future<void> delete(String table, String id) async {
    _checkInitialized();
    _storage[table]?.remove(id);
  }

  @override
  Future<void> deleteMany(String table, List<String> ids) async {
    _checkInitialized();
    for (final id in ids) {
      _storage[table]?.remove(id);
    }
  }

  Future<void> deleteWork(String id) async {
    _checkInitialized();
    await delete('works', id);
  }

  @override
  Future<Map<String, dynamic>?> get(String table, String id) async {
    _checkInitialized();
    return _storage[table]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    _checkInitialized();
    if (_storage[table] == null) return [];
    return List<Map<String, dynamic>>.from(_storage[table]!.values);
  }

  Future<WorkEntity?> getWork(String id) async {
    _checkInitialized();
    final map = await get('works', id);
    if (map == null) return null;
    return WorkEntity.fromJson(map);
  }

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(milliseconds: 100)); // 模拟初始化延迟
    _isInitialized = true;
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table,
    Map<String, dynamic> filter,
  ) async {
    _checkInitialized();
    if (_storage[table] == null) return [];
    return List<Map<String, dynamic>>.from(_storage[table]!.values);
  }

  // 额外的工作相关方法
  Future<List<WorkEntity>> queryWorks(WorkFilter filter) async {
    _checkInitialized();
    final maps = await query('works', filter.toJson());
    return maps.map((m) => WorkEntity.fromJson(m)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    _checkInitialized();
    return [];
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? args]) async {
    _checkInitialized();
    return 0;
  }

  @override
  Future<void> save(String table, String id, Map<String, dynamic> data) async {
    _checkInitialized();
    _storage.putIfAbsent(table, () => {});
    _storage[table]![id] = Map<String, dynamic>.from(data);
  }

  @override
  Future<void> saveMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async {
    _checkInitialized();
    _storage.putIfAbsent(table, () => {});
    _storage[table]!.addAll(
      Map<String, Map<String, dynamic>>.from(data),
    );
  }

  Future<void> saveWork(WorkEntity work) async {
    _checkInitialized();
    await save('works', work.id, work.toJson());
  }

  @override
  Future<void> set(String table, String id, Map<String, dynamic> data) async {
    await save(table, id, data);
  }

  @override
  Future<void> setMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async {
    await saveMany(table, data);
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('Database not initialized');
    }
  }
}

/// 用于测试的慢速数据库
class SlowMockDatabase implements DatabaseInterface {
  final Duration delay;
  bool _isInitialized = false;
  final MockDatabase _delegate = MockDatabase();

  SlowMockDatabase({this.delay = const Duration(seconds: 3)});

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<void> clear(String table) async {
    await Future.delayed(delay);
    return _delegate.clear(table);
  }

  @override
  Future<void> close() async {
    await Future.delayed(delay);
    return _delegate.close();
  }

  @override
  Future<int> count(String table, [Map<String, dynamic>? filter]) async {
    await Future.delayed(delay);
    return _delegate.count(table, filter);
  }

  @override
  Future<void> delete(String table, String id) async {
    await Future.delayed(delay);
    return _delegate.delete(table, id);
  }

  @override
  Future<void> deleteMany(String table, List<String> ids) async {
    await Future.delayed(delay);
    return _delegate.deleteMany(table, ids);
  }

  @override
  Future<Map<String, dynamic>?> get(String table, String id) async {
    await Future.delayed(delay);
    return _delegate.get(table, id);
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    await Future.delayed(delay);
    return _delegate.getAll(table);
  }

  @override
  Future<void> initialize() async {
    await Future.delayed(delay);
    await _delegate.initialize();
    _isInitialized = true;
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table,
    Map<String, dynamic> filter,
  ) async {
    await Future.delayed(delay);
    return _delegate.query(table, filter);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    await Future.delayed(delay);
    return _delegate.rawQuery(sql, args);
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? args]) async {
    await Future.delayed(delay);
    return _delegate.rawUpdate(sql, args);
  }

  @override
  Future<void> save(String table, String id, Map<String, dynamic> data) async {
    await Future.delayed(delay);
    return _delegate.save(table, id, data);
  }

  @override
  Future<void> saveMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async {
    await Future.delayed(delay);
    return _delegate.saveMany(table, data);
  }

  @override
  Future<void> set(String table, String id, Map<String, dynamic> data) async {
    await Future.delayed(delay);
    return _delegate.set(table, id, data);
  }

  @override
  Future<void> setMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async {
    await Future.delayed(delay);
    return _delegate.setMany(table, data);
  }
}
