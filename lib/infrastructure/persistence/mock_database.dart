import './database_interface.dart';

/// Mock database implementation for testing
class MockDatabase implements DatabaseInterface {
  final Map<String, Map<String, Map<String, dynamic>>> _data = {};

  @override
  Future<void> clear(String table) async {
    _data.remove(table);
  }

  @override
  Future<void> close() async {}

  @override
  Future<int> count(String table, [Map<String, dynamic>? filter]) async {
    return _data[table]?.length ?? 0;
  }

  @override
  Future<void> delete(String table, String id) async {
    _data[table]?.remove(id);
  }

  @override
  Future<void> deleteMany(String table, List<String> ids) async {
    for (final id in ids) {
      _data[table]?.remove(id);
    }
  }

  @override
  Future<Map<String, dynamic>?> get(String table, String id) async {
    return _data[table]?[id];
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    return _data[table]?.values.toList() ?? [];
  }

  @override
  Future<void> initialize() async {
    // Nothing to initialize in mock
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table,
    Map<String, dynamic> filter,
  ) async {
    return _data[table]?.values.toList() ?? [];
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    // Return empty list for mock
    return [];
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? args]) async {
    // Return 0 for mock
    return 0;
  }

  @override
  Future<void> save(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    _data.putIfAbsent(table, () => {});
    _data[table]![id] = Map.from(data);
  }

  @override
  Future<void> saveMany(
    String table,
    Map<String, Map<String, dynamic>> items,
  ) async {
    _data.putIfAbsent(table, () => {});
    _data[table]!.addAll(Map.from(items));
  }

  @override
  Future<void> set(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    _data.putIfAbsent(table, () => {});
    _data[table]![id] = Map.from(data);
  }

  @override
  Future<void> setMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async {
    _data.putIfAbsent(table, () => {});
    _data[table]!.addAll(Map.from(data));
  }
}
