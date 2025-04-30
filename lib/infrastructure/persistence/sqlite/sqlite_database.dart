import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../logging/logger.dart';
import '../database_interface.dart';
import '../models/database_query.dart';

/// SQLite数据库实现
class SQLiteDatabase implements DatabaseInterface {
  final Database _db;

  const SQLiteDatabase._(this._db);

  @override
  Future<void> clear(String table) async {
    await _db.delete(table);
  }

  @override
  Future<void> close() async {
    await _db.close();
  }

  @override
  Future<int> count(String table, [Map<String, dynamic>? filter]) async {
    if (filter == null || filter.isEmpty) {
      final result = await _db.rawQuery('SELECT COUNT(*) as count FROM $table');
      return Sqflite.firstIntValue(result) ?? 0;
    }

    final query = DatabaseQuery.fromJson(filter);
    final queryResult = _buildCountSql(table, query);

    try {
      final result = await _db.rawQuery(queryResult.sql, queryResult.args);
      final count = Sqflite.firstIntValue(result) ?? 0;

      // AppLogger.debug(
      //   '统计查询完成',
      //   tag: 'SQLiteDatabase',
      //   data: {
      //     'count': count,
      //     'sql': queryResult.sql,
      //     'args': queryResult.args,
      //   },
      // );

      return count;
    } catch (e) {
      AppLogger.error(
        '统计查询失败',
        tag: 'SQLiteDatabase',
        error: e,
        data: {
          'sql': queryResult.sql,
          'args': queryResult.args,
        },
      );
      debugPrint('统计查询失败: $e');
      return 0; // 出错时返回0
    }
  }

  @override
  Future<void> delete(String table, String id) async {
    await _db.delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteMany(String table, List<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.delete(
        table,
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<Map<String, dynamic>?> get(String table, String id) async {
    final results = await _db.query(
      table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isEmpty ? null : results.first;
  }

  @override
  Future<List<Map<String, dynamic>>> getAll(String table) async {
    return _db.query(table);
  }

  @override
  Future<void> initialize() async {
    // 数据库已在构造时初始化
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table,
    Map<String, dynamic> filter,
  ) async {
    // AppLogger.debug(
    //   '执行数据库查询',
    //   tag: 'SQLiteDatabase',
    //   data: {
    //     'table': table,
    //     'filter': filter,
    //   },
    // );

    final query = DatabaseQuery.fromJson(filter);
    final queryResult = _buildQuerySql(table, query);

    // AppLogger.debug(
    //   '生成SQL查询语句',
    //   tag: 'SQLiteDatabase',
    //   data: {
    //     'sql': queryResult.sql,
    //     'args': queryResult.args,
    //   },
    // );

    try {
      final results = await _db.rawQuery(queryResult.sql, queryResult.args);

      // AppLogger.debug(
      //   '查询完成',
      //   tag: 'SQLiteDatabase',
      //   data: {
      //     'resultCount': results.length,
      //     'firstResult': results.isNotEmpty ? results.first : null,
      //   },
      // );

      return results;
    } catch (e) {
      AppLogger.error(
        '查询失败',
        tag: 'SQLiteDatabase',
        error: e,
        data: {
          'sql': queryResult.sql,
          'args': queryResult.args,
        },
      );
      debugPrint('查询失败: $e');
      rethrow;
    }
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? args]) async {
    return _db.rawDelete(sql, args);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    return _db.rawQuery(sql, args);
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? args]) async {
    return _db.rawUpdate(sql, args);
  }

  @override
  Future<void> save(String table, String id, Map<String, dynamic> data) async {
    await _db.update(
      table,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> saveMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async {
    final batch = _db.batch();
    for (final entry in data.entries) {
      batch.update(
        table,
        entry.value,
        where: 'id = ?',
        whereArgs: [entry.key],
      );
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> set(String table, String id, Map<String, dynamic> data) async {
    await _db.insert(
      table,
      {'id': id, ...data},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> setMany(
    String table,
    Map<String, Map<String, dynamic>> data,
  ) async {
    final batch = _db.batch();
    for (final entry in data.entries) {
      batch.insert(
        table,
        {'id': entry.key, ...entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// 构建COUNT查询SQL
  ({String sql, List<Object?> args}) _buildCountSql(
      String table, DatabaseQuery query) {
    final where = <String>[];
    final whereArgs = <dynamic>[];

    // 处理普通条件
    for (final condition in query.conditions) {
      where.add('${condition.field} ${condition.operator} ?');
      whereArgs.add(condition.value);
    }

    // 处理条件组
    if (query.groups?.isNotEmpty == true) {
      for (final group in query.groups!) {
        final groupWheres = <String>[];
        for (final condition in group.conditions) {
          groupWheres.add('${condition.field} ${condition.operator} ?');
          whereArgs.add(condition.value);
        }
        if (groupWheres.isNotEmpty) {
          final groupOperator = group.type == 'AND' ? ' AND ' : ' OR ';
          where.add('(${groupWheres.join(groupOperator)})');
        }
      }
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final sql = 'SELECT COUNT(*) as count FROM $table $whereClause';

    // AppLogger.debug(
    //   '构建COUNT SQL查询',
    //   tag: 'SQLiteDatabase',
    //   data: {
    //     'table': table,
    //     'whereClause': whereClause,
    //     'sql': sql,
    //     'args': whereArgs,
    //   },
    // );

    return (sql: sql, args: whereArgs);
  }

  /// 构建查询SQL
  ({String sql, List<Object?> args}) _buildQuerySql(
      String table, DatabaseQuery query) {
    final where = <String>[];
    final whereArgs = <dynamic>[];

    // 处理普通条件
    for (final condition in query.conditions) {
      where.add('${condition.field} ${condition.operator} ?');
      whereArgs.add(condition.value);
    }

    // 处理条件组
    if (query.groups?.isNotEmpty == true) {
      for (final group in query.groups!) {
        final groupWheres = <String>[];
        for (final condition in group.conditions) {
          groupWheres.add('${condition.field} ${condition.operator} ?');
          whereArgs.add(condition.value);
        }
        if (groupWheres.isNotEmpty) {
          final groupOperator = group.type == 'AND' ? ' AND ' : ' OR ';
          where.add('(${groupWheres.join(groupOperator)})');
        }
      }
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final orderClause =
        query.orderBy == null ? '' : 'ORDER BY ${query.orderBy}';
    final limitClause = query.limit == null ? '' : 'LIMIT ${query.limit}';
    final offsetClause = query.offset == null ? '' : 'OFFSET ${query.offset}';

    // AppLogger.debug(
    //   '构建SQL查询参数',
    //   tag: 'SQLiteDatabase',
    //   data: {
    //     'orderBy': query.orderBy,
    //     'limit': query.limit,
    //     'offset': query.offset,
    //     'orderClause': orderClause,
    //     'limitClause': limitClause,
    //     'offsetClause': offsetClause,
    //   },
    // );

    return (
      sql:
          'SELECT * FROM $table $whereClause $orderClause $limitClause $offsetClause',
      args: whereArgs
    );
  }

  /// 创建SQLite数据库实例
  static Future<SQLiteDatabase> create({
    required String name,
    required String directory,
    List<String> migrations = const [],
  }) async {
    // 在 Windows 平台上初始化 sqflite_ffi
    if (defaultTargetPlatform == TargetPlatform.windows) {
      AppLogger.debug('初始化 SQLite FFI', tag: 'App');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = join(directory, name);

    AppLogger.info(
      '数据库配置信息:\n'
      '  - 数据库类型: SQLite3\n'
      '  - 数据库名称: $name\n'
      '  - 数据库目录: $directory\n'
      '  - 完整路径: $path\n'
      '  - 数据库版本: ${migrations.length}\n'
      '  - 迁移脚本数量: ${migrations.length}',
      tag: 'Database',
    );

    final db = await openDatabase(
      path,
      version: migrations.length,
      onCreate: (db, version) async {
        AppLogger.info(
          '首次创建数据库，执行初始化...\n'
          '执行迁移脚本:\n',
          tag: 'Database',
        );
        for (final sql in migrations) {
          AppLogger.info(
            '执行SQL:\n$sql',
            tag: 'Database',
          );
          await db.execute(sql);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLogger.info(
          '升级数据库:\n'
          '  - 当前版本: v$oldVersion\n'
          '  - 目标版本: v$newVersion',
          tag: 'Database',
        );
        for (var i = oldVersion; i < newVersion; i++) {
          AppLogger.debug(
            '执行迁移脚本 ${i + 1}:\n${migrations[i]}',
            tag: 'Database',
          );
          await db.execute(migrations[i]);
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        AppLogger.debug(
          'SQLite配置完成: 已启用外键约束',
          tag: 'Database',
        );
      },
      onDowngrade: (db, oldVersion, newVersion) => {
        AppLogger.warning(
          '数据库降级: 当前版本 v$oldVersion, 目标版本 v$newVersion',
          tag: 'Database',
        ),
        throw Exception('数据库降级不支持'),
      },
    );
    return SQLiteDatabase._(db);
  }
}
