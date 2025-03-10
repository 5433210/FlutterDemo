import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/config/app_config.dart';
import '../persistence/database_factory.dart';
import '../persistence/database_interface.dart';
import '../persistence/sqlite/migrations.dart';

/// 数据库配置提供者
final databaseConfigProvider = FutureProvider<DatabaseConfig>((ref) async {
  return DatabaseConfig(
    name: 'app.db',
    directory: AppConfig.dataPath,
    migrations: migrations, // 从 migrations.dart 导入的迁移脚本列表
  );
});

/// 数据库提供者
final databaseProvider = FutureProvider<DatabaseInterface>((ref) async {
  final config = await ref.watch(databaseConfigProvider.future);

  // 使用工厂创建数据库实例
  final database = await DatabaseFactory.create(config);

  // 注册数据库关闭回调
  ref.onDispose(() async {
    await database.close();
  });

  await database.initialize();
  return database;
});
