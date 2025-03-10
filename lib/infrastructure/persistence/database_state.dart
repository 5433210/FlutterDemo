import 'database_interface.dart';

/// 数据库状态
class DatabaseState {
  final DatabaseInterface? database;
  final bool isInitialized;
  final Object? error;

  const DatabaseState({
    this.database,
    this.isInitialized = false,
    this.error,
  });

  DatabaseState copyWith({
    DatabaseInterface? database,
    bool? isInitialized,
    Object? error,
  }) {
    return DatabaseState(
      database: database ?? this.database,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
    );
  }
}
