import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database_interface.dart';
import '../persistence/sqlite/migrations.dart';
import '../persistence/sqlite/sqlite_database.dart';
import 'storage_providers.dart';

/// 数据库Provider
final databaseProvider = FutureProvider<DatabaseInterface>((ref) async {
  final basePath = await ref.watch(storageProvider.future).then((storage) {
    return storage.getAppDataPath();
  });
  return SQLiteDatabase.create(
    name: 'app.db',
    directory: '$basePath/database',
    migrations: migrations,
  );
});

/// 数据库初始化Provider
final initializedDatabaseProvider = Provider<DatabaseInterface>((ref) {
  final databaseState = ref.watch(databaseProvider);
  return databaseState.when(
    data: (database) => database,
    loading: () => throw StateError('Database service not initialized'),
    error: (err, stack) =>
        throw StateError('Database initialization failed: $err'),
  );
});
