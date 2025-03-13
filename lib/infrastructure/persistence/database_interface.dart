/// 数据库接口
abstract class DatabaseInterface {
  /// 清空表
  Future<void> clear(String table);

  /// 关闭数据库
  Future<void> close();

  /// 获取记录数
  Future<int> count(String table, [Map<String, dynamic>? filter]);

  /// 删除记录
  Future<void> delete(String table, String id);

  /// 批量删除记录
  Future<void> deleteMany(String table, List<String> ids);

  /// 获取单个记录
  Future<Map<String, dynamic>?> get(String table, String id);

  /// 获取多个记录
  Future<List<Map<String, dynamic>>> getAll(String table);

  /// 执行初始化
  Future<void> initialize();

  /// 结构化查询
  Future<List<Map<String, dynamic>>> query(
      String table, Map<String, dynamic> filter);

  /// 执行原生删除
  Future<int> rawDelete(String sql, [List<Object?>? args]);

  /// 执行原生查询
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<Object?>? args]);

  /// 执行原生更新
  Future<int> rawUpdate(String sql, [List<Object?>? args]);

  /// 保存/更新记录
  Future<void> save(String table, String id, Map<String, dynamic> data);

  /// 批量保存/更新记录
  Future<void> saveMany(String table, Map<String, Map<String, dynamic>> data);

  /// 设置记录(覆盖)
  Future<void> set(String table, String id, Map<String, dynamic> data);

  /// 批量设置记录(覆盖)
  Future<void> setMany(String table, Map<String, Map<String, dynamic>> data);
}
