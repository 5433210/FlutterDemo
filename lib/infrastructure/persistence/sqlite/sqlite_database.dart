import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../logging/logger.dart';
import '../database_interface.dart';
import '../models/database_query.dart';
import 'database_restore_handler_v2.dart';

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
    debugPrint('SQLiteDatabase.save: 开始保存数据到 $table, id=$id');

    try {
      // 首先尝试查询该ID是否存在
      final exists = await _db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (exists.isNotEmpty) {
        // 如果记录存在，更新它
        debugPrint('SQLiteDatabase.save: 记录已存在，执行更新');
        final updateCount = await _db.update(
          table,
          data,
          where: 'id = ?',
          whereArgs: [id],
        );
        debugPrint('SQLiteDatabase.save: 更新完成，影响行数: $updateCount');
      } else {
        // 如果记录不存在，插入新记录
        debugPrint('SQLiteDatabase.save: 记录不存在，执行插入');
        await _db.insert(
          table,
          {'id': id, ...data},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        debugPrint('SQLiteDatabase.save: 插入完成');
      }

      // 验证数据是否已保存
      final saved = await _db.query(
        table,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (saved.isEmpty) {
        throw Exception('SQLiteDatabase.save: 保存后无法验证数据，记录不存在: $id');
      }
      debugPrint('SQLiteDatabase.save: 数据保存成功，已验证 $table.$id');
    } catch (e) {
      debugPrint('SQLiteDatabase.save: 保存失败: $e');
      rethrow;
    }
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
      // Handle special GROUP operator for nested conditions
      if (condition.operator == 'GROUP' &&
          condition.value is DatabaseQueryGroup) {
        final group = condition.value as DatabaseQueryGroup;
        final groupWheres = <String>[];
        for (final groupCondition in group.conditions) {
          groupWheres
              .add('${groupCondition.field} ${groupCondition.operator} ?');
          whereArgs.add(groupCondition.value);
        }
        if (groupWheres.isNotEmpty) {
          final groupOperator = group.type == 'AND' ? ' AND ' : ' OR ';
          where.add('(${groupWheres.join(groupOperator)})');
        }
      } else {
        where.add('${condition.field} ${condition.operator} ?');
        whereArgs.add(condition.value);
      }
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
    final dbFullPath = path.join(directory, name);
    AppLogger.info(
      '数据库配置信息:\n'
      '  - 数据库类型: SQLite3\n'
      '  - 数据库名称: $name\n'
      '  - 数据库目录: $directory\n'
      '  - 完整路径: $dbFullPath\n'
      '  - 数据库版本: ${migrations.length}\n'
      '  - 迁移脚本数量: ${migrations.length}',
      tag: 'Database',
    );

    // 在Windows、MacOS、Linux平台初始化sqflite_ffi
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      try {
        AppLogger.info('初始化sqflite_ffi...', tag: 'Database');
        sqfliteFfiInit();

        AppLogger.info('在${Platform.operatingSystem}平台上使用标准数据库工厂',
            tag: 'Database');
        databaseFactory = databaseFactoryFfi;

        AppLogger.info('SQLite FFI初始化成功', tag: 'Database');
      } catch (e) {
        AppLogger.error('SQLite FFI初始化失败', tag: 'Database', error: e);
        rethrow;
      }
    }

    // 检查是否有待恢复的数据库
    AppLogger.info('检查是否有待恢复的数据库',
        tag: 'Database', data: {'directory': directory});
    try {
      // 使用新的数据库恢复处理器
      final restored =
          await DatabaseRestoreHandlerV2.checkAndRestoreDatabase(directory);
      if (restored) {
        AppLogger.info('数据库已从备份恢复', tag: 'Database');

        // 如果数据库已恢复，等待一段时间确保文件系统操作完成
        await Future.delayed(const Duration(milliseconds: 500));

        // 确保文件系统缓存已刷新
        try {
          final dbPath = path.join(directory, name);
          final dbFile = File(dbPath);
          if (await dbFile.exists()) {
            // 尝试打开并立即关闭数据库，确保文件系统操作已完成
            final testDb = await openDatabase(dbPath);
            await testDb.close();
            AppLogger.info('数据库文件可正常访问', tag: 'Database');
          }
        } catch (e) {
          AppLogger.warning('测试恢复后的数据库访问失败，将继续尝试正常打开',
              tag: 'Database', error: e);
        }

        // 检查是否存在自动重启标记文件
        final autoRestartMarkerPath =
            path.join(path.dirname(directory), 'auto_restart_pending');
        final autoRestartMarkerFile = File(autoRestartMarkerPath);
        if (await autoRestartMarkerFile.exists()) {
          AppLogger.info('发现自动重启标记文件，应用将在数据库初始化完成后自动重启',
              tag: 'Database', data: {'path': autoRestartMarkerPath});

          // 删除自动重启标记文件
          try {
            await autoRestartMarkerFile.delete();
            AppLogger.info('已删除自动重启标记文件', tag: 'Database');
          } catch (e) {
            AppLogger.warning('删除自动重启标记文件失败', tag: 'Database', error: e);
          }
        }
      } else {
        AppLogger.info('没有待恢复的数据库', tag: 'Database');
      }
    } catch (e, stack) {
      AppLogger.error('检查待恢复数据库失败',
          error: e, stackTrace: stack, tag: 'Database');
    }
    // 重用之前定义的dbFullPath变量
    AppLogger.info(
      '数据库配置信息:\n'
      '  - 数据库类型: SQLite3\n'
      '  - 数据库名称: $name\n'
      '  - 数据库目录: $directory\n'
      '  - 完整路径: $dbFullPath\n'
      '  - 数据库版本: ${migrations.length}\n'
      '  - 迁移脚本数量: ${migrations.length}',
      tag: 'Database',
    );

    try {
      final db = await openDatabase(
        dbFullPath,
        version: migrations.length,
        onCreate: (db, version) async {
          AppLogger.info(
            '首次创建数据库，执行初始化...\n'
            '合并执行所有迁移脚本 (v1-v$version)',
            tag: 'Database',
          );
          
          // 将所有迁移脚本合并成一个脚本
          final combinedSql = _combineMigrationScripts(migrations, 0, migrations.length);
          
          AppLogger.debug(
            '执行合并SQL脚本 (${combinedSql.length} 字符)',
            tag: 'Database',
          );
          
          try {
            // 使用事务执行合并后的脚本
            await db.transaction((txn) async {
              // 分割SQL语句并执行
              final statements = _splitSqlStatements(combinedSql);
              for (int i = 0; i < statements.length; i++) {
                final statement = statements[i].trim();
                if (statement.isNotEmpty) {
                  try {
                    await txn.execute(statement);
                  } catch (e) {
                    AppLogger.error('执行SQL语句失败', tag: 'Database', error: e, data: {
                      'statement_index': i,
                      'statement': statement.length > 200 ? '${statement.substring(0, 200)}...' : statement,
                    });
                    rethrow;
                  }
                }
              }
            });
            
            AppLogger.info('数据库初始化完成', tag: 'Database');
          } catch (e) {
            AppLogger.error('执行合并迁移脚本失败', tag: 'Database', error: e, data: {
              'version': version,
              'sql_length': combinedSql.length,
            });
            rethrow;
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          AppLogger.info(
            '升级数据库:\n'
            '  - 当前版本: v$oldVersion\n'
            '  - 目标版本: v$newVersion\n'
            '  - 合并执行迁移脚本',
            tag: 'Database',
          );
          
          // 将需要的迁移脚本合并成一个脚本
          final combinedSql = _combineMigrationScripts(migrations, oldVersion, newVersion);
          
          AppLogger.debug(
            '执行合并升级脚本 (${combinedSql.length} 字符)',
            tag: 'Database',
          );
          
          try {
            // 使用事务执行合并后的脚本
            await db.transaction((txn) async {
              // 分割SQL语句并执行
              final statements = _splitSqlStatements(combinedSql);
              for (int i = 0; i < statements.length; i++) {
                final statement = statements[i].trim();
                if (statement.isNotEmpty) {
                  try {
                    await txn.execute(statement);
                  } catch (e) {
                    AppLogger.error('执行SQL语句失败', tag: 'Database', error: e, data: {
                      'statement_index': i,
                      'statement': statement.length > 200 ? '${statement.substring(0, 200)}...' : statement,
                    });
                    rethrow;
                  }
                }
              }
            });
            
            AppLogger.info('数据库升级完成', tag: 'Database');
          } catch (e) {
            AppLogger.error(
              '数据库升级失败',
              tag: 'Database',
              error: e,
              data: {
                'oldVersion': oldVersion,
                'newVersion': newVersion,
                'sql_length': combinedSql.length,
              },
            );
            rethrow;
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

      AppLogger.info('数据库初始化成功', tag: 'Database');
      return SQLiteDatabase._(db);
    } catch (e, stack) {
      AppLogger.error(
        '数据库初始化失败',
        tag: 'Database',
        error: e,
        stackTrace: stack,
        data: {'path': dbFullPath},
      );

      // 重新抛出异常，让调用者知道初始化失败
      rethrow;
    }
  }

  /// 合併遷移腳本
  static String _combineMigrationScripts(List<String> migrations, int startIndex, int endIndex) {
    final buffer = StringBuffer();
    
    for (int i = startIndex; i < endIndex; i++) {
      final script = migrations[i].trim();
      if (script.isNotEmpty) {
        buffer.writeln('-- Migration ${i + 1}');
        buffer.writeln(script);
        buffer.writeln();
      }
    }
    
    return buffer.toString();
  }

  /// 分割SQL語句
  static List<String> _splitSqlStatements(String sql) {
    final statements = <String>[];
    final buffer = StringBuffer();
    final lines = sql.split('\n');
    
    bool inMultiLineComment = false;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      
      // 跳過空行和單行註釋
      if (trimmedLine.isEmpty || trimmedLine.startsWith('--')) {
        continue;
      }
      
      // 處理多行註釋
      if (trimmedLine.startsWith('/*')) {
        inMultiLineComment = true;
        continue;
      }
      if (trimmedLine.endsWith('*/')) {
        inMultiLineComment = false;
        continue;
      }
      if (inMultiLineComment) {
        continue;
      }
      
      buffer.writeln(line);
      
      // 如果行以分號結尾，則認為是一個完整的語句
      if (trimmedLine.endsWith(';')) {
        final statement = buffer.toString().trim();
        if (statement.isNotEmpty && !statement.startsWith('--')) {
          statements.add(statement);
        }
        buffer.clear();
      }
    }
    
    // 處理最後一個沒有分號結尾的語句
    final lastStatement = buffer.toString().trim();
    if (lastStatement.isNotEmpty && !lastStatement.startsWith('--')) {
      statements.add(lastStatement);
    }
    
    return statements;
  }
}
