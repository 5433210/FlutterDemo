import 'package:sqflite/sqflite.dart';

import '../../logging/logger.dart';

class DatabaseError implements Exception {
  final String message;
  final String operation;
  final dynamic originalError;
  final StackTrace stackTrace;

  DatabaseError(
    this.message,
    this.operation,
    this.originalError,
    this.stackTrace,
  );

  @override
  String toString() => 'DatabaseError: $message (operation: $operation)';
}

/// 数据库错误处理器
class DatabaseErrorHandler {
  /// 安全执行数据库操作
  static Future<T> execute<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return await action();
    } on DatabaseException catch (e, stack) {
      final error = DatabaseError(
        e.toString(),
        operation,
        e,
        stack,
      );

      AppLogger.error(
        'Database operation failed',
        tag: 'Database',
        error: error,
        stackTrace: stack,
        data: {'operation': operation},
      );
      throw error;
    } catch (e, stack) {
      final error = DatabaseError(
        'Unexpected database error',
        operation,
        e,
        stack,
      );

      AppLogger.error(
        'Unexpected database error',
        tag: 'Database',
        error: error,
        stackTrace: stack,
        data: {'operation': operation},
      );
      throw error;
    }
  }
}
