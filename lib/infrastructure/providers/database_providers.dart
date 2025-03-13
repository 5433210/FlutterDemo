import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/storage_providers.dart';
import '../persistence/database_interface.dart';
import '../persistence/sqlite/migrations.dart';
import '../persistence/sqlite/sqlite_database.dart';

/// 数据库初始化Provider
final databaseInitializationProvider =
    FutureProvider.autoDispose<void>((ref) async {
  final stateNotifier = ref.watch(databaseStateProvider.notifier);

  try {
    final db = await ref.watch(databaseProvider.future);
    await stateNotifier.initialize(db);
  } catch (e) {
    stateNotifier.setError();
    rethrow;
  }
});

/// 数据库Provider
final databaseProvider = FutureProvider<DatabaseInterface>((ref) async {
  final basePath = await ref.watch(appRootDirectoryProvider.future);
  return SQLiteDatabase.create(
    name: 'app.db',
    directory: basePath ?? '',
    migrations: migrations,
  );
});

/// 数据库状态Provider
final databaseStateProvider =
    StateNotifierProvider<DatabaseStateNotifier, DatabaseState>(
  (ref) => DatabaseStateNotifier(),
);

/// 数据库状态
class DatabaseState {
  final DatabaseInterface? database;
  final String version;
  final DatabaseStatus status;

  factory DatabaseState.error() => DatabaseState._(
        version: '0.0.0',
        status: DatabaseStatus.error,
      );

  factory DatabaseState.initialized(DatabaseInterface database) =>
      DatabaseState._(
        database: database,
        version: '1.0.0',
        status: DatabaseStatus.initialized,
      );

  factory DatabaseState.initializing() => DatabaseState._(
        version: '0.0.0',
        status: DatabaseStatus.initializing,
      );

  factory DatabaseState.uninitialized() => DatabaseState._(
        version: '0.0.0',
        status: DatabaseStatus.uninitialized,
      );

  DatabaseState._({
    this.database,
    required this.version,
    required this.status,
  });

  String get error => status == DatabaseStatus.error ? '初始化失败' : '';

  bool get isInitialized =>
      status == DatabaseStatus.initialized && database != null;

  @override
  String toString() => status.toString();
}

/// 数据库状态通知器
class DatabaseStateNotifier extends StateNotifier<DatabaseState> {
  DatabaseStateNotifier() : super(DatabaseState.uninitialized());

  Future<void> initialize(DatabaseInterface database) async {
    state = DatabaseState.initializing();
    await database.initialize();
    state = DatabaseState.initialized(database);
  }

  void setError() {
    state = DatabaseState.error();
  }
}

/// 数据库状态枚举
enum DatabaseStatus {
  uninitialized,
  initializing,
  initialized,
  error;

  @override
  String toString() {
    return switch (this) {
      DatabaseStatus.uninitialized => '未初始化',
      DatabaseStatus.initializing => '初始化中',
      DatabaseStatus.initialized => '已初始化',
      DatabaseStatus.error => '错误',
    };
  }
}
