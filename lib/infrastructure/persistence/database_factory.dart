import 'package:path_provider/path_provider.dart';

import 'database_interface.dart';
import 'sqlite/sqlite_database.dart';

/// 数据库配置
class DatabaseConfig {
  /// 数据库名称
  final String name;

  /// 数据库目录
  final String? directory;

  /// 数据库迁移脚本
  final List<String> migrations;

  const DatabaseConfig({
    required this.name,
    this.directory,
    this.migrations = const [],
  });
}

/// 数据库工厂
class DatabaseFactory {
  /// 创建SQLite数据库实例
  static Future<DatabaseInterface> create(DatabaseConfig config) async {
    final directory =
        config.directory ?? (await getApplicationDocumentsDirectory()).path;

    return SQLiteDatabase.create(
      name: config.name,
      directory: directory,
      migrations: config.migrations,
    );
  }
}
