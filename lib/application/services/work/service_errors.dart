import '../../../infrastructure/logging/logger.dart';

/// 作品服务异常基类
abstract class ServiceException implements Exception {
  final String operation;
  final String message;
  final Map<String, dynamic>? data;

  ServiceException(this.operation, this.message, [this.data]);

  @override
  String toString() => '$runtimeType: $operation - $message';
}

/// 图片服务错误处理Mixin
mixin WorkImageErrorHandler {
  /// 处理图片操作
  Future<T> handleImageOperation<T>(
    String operation,
    Future<T> Function() action, {
    Map<String, dynamic>? data,
    bool rethrowError = true,
  }) async {
    try {
      return await action();
    } catch (e, stack) {
      // 记录错误
      AppLogger.error(
        'Image operation failed: $operation',
        tag: runtimeType.toString(),
        error: e,
        stackTrace: stack,
        data: data,
      );

      if (rethrowError) {
        if (e is ArgumentError) {
          rethrow;
        }
        throw WorkImageException(
          operation,
          e.toString(),
          data,
        );
      }

      return Future.value(); // 如果不重新抛出，返回null
    }
  }

  /// 处理同步图片操作
  T handleImageSync<T>(
    String operation,
    T Function() action, {
    Map<String, dynamic>? data,
    bool rethrowError = true,
  }) {
    try {
      return action();
    } catch (e, stack) {
      // 记录错误
      AppLogger.error(
        'Image operation failed: $operation',
        tag: runtimeType.toString(),
        error: e,
        stackTrace: stack,
        data: data,
      );

      if (rethrowError) {
        if (e is ArgumentError) {
          rethrow;
        }
        throw WorkImageException(
          operation,
          e.toString(),
          data,
        );
      }

      return null as T; // 如果不重新抛出，返回null
    }
  }
}

/// 图片服务异常
class WorkImageException extends ServiceException {
  WorkImageException(String operation, String message,
      [Map<String, dynamic>? data])
      : super(operation, message, data);
}

/// 作品服务错误处理Mixin
mixin WorkServiceErrorHandler {
  /// 处理服务操作
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
      // 记录错误
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
        throw WorkServiceException(
          operation,
          e.toString(),
          data,
        );
      }

      return Future.value(); // 如果不重新抛出，返回null
    }
  }

  /// 处理同步操作
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
      // 记录错误
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
        throw WorkServiceException(
          operation,
          e.toString(),
          data,
        );
      }

      return null as T; // 如果不重新抛出，返回null
    }
  }
}

/// 作品服务业务异常
class WorkServiceException extends ServiceException {
  WorkServiceException(String operation, String message,
      [Map<String, dynamic>? data])
      : super(operation, message, data);
}
