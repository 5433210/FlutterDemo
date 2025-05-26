import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../logging/logger.dart';
import '../persistence/database_interface.dart';
import '../persistence/sqlite/migrations.dart';
import '../persistence/sqlite/sqlite_database.dart';
import 'storage_providers.dart';

/// 数据库Provider
final databaseProvider = FutureProvider<DatabaseInterface>((ref) async {
  AppLogger.info('Creating database provider instance',
      tag: 'DatabaseProvider');

  final basePath = await ref.watch(storageProvider.future).then((storage) {
    return storage.getAppDataPath();
  });

  final dbPath = '$basePath/database';
  AppLogger.info('Database path determined',
      tag: 'DatabaseProvider', data: {'path': dbPath});

  final database = await SQLiteDatabase.create(
    name: 'app.db',
    directory: dbPath,
    migrations: migrations,
  );

  AppLogger.info('Database instance created successfully',
      tag: 'DatabaseProvider', data: {'instanceId': database.hashCode});

  return database;
});

/// 数据库初始化Provider - 保持数据库实例存活
final initializedDatabaseProvider =
    FutureProvider<DatabaseInterface>((ref) async {
  AppLogger.debug('Accessing initializedDatabaseProvider',
      tag: 'DatabaseProvider');

  // Keep the database provider alive to prevent disposal
  ref.keepAlive();

  // Wait for the database to be fully initialized
  final database = await ref.watch(databaseProvider.future);

  AppLogger.info('Database ready for use',
      tag: 'DatabaseProvider', data: {'instanceId': database.hashCode});

  return database;
});
