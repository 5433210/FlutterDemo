import '../../../infrastructure/logging/logger.dart';

/// 错误处理Mixin
mixin WorkServiceErrorHandler {
  /// 统一处理服务操作
  Future<T> handleOperation<T>(
    String operation,
    Future<T> Function() action, {
    Map<String, dynamic>? data,
    bool rethrowError = true,
    String? tag,
  }) async {
    try {
      return await action();
    } catch (e, stack) {
      AppLogger.error(
        'Operation failed: $operation',
        tag: tag ?? runtimeType.toString(),
        error: e,
        stackTrace: stack,
        data: data,
      );

      if (rethrowError) {
        if (e is ArgumentError) {
          rethrow; // 参数错误直接抛出
        }
        throw WorkServiceException(operation, e.toString());
      }

      return Future.value(); // 如果不重新抛出，返回默认值
    }
  }

  /// 统一处理同步操作
  T handleSync<T>(
    String operation,
    T Function() action, {
    Map<String, dynamic>? data,
    bool rethrowError = true,
    String? tag,
  }) {
    try {
      return action();
    } catch (e, stack) {
      AppLogger.error(
        'Operation failed: $operation',
        tag: tag ?? runtimeType.toString(),
        error: e,
        stackTrace: stack,
        data: data,
      );

      if (rethrowError) {
        if (e is ArgumentError) {
          rethrow;
        }
        throw WorkServiceException(operation, e.toString());
      }

      return null as T; // 如果不重新抛出，返回null
    }
  }
}

/// 作品服务异常类
class WorkServiceException implements Exception {
  final String operation;
  final String message;

  WorkServiceException(this.operation, this.message);

  @override
  String toString() => 'WorkServiceException: $operation - $message';
}
