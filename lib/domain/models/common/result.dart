/// 业务错误
class BusinessError implements Exception {
  final String message;
  BusinessError(this.message);

  @override
  String toString() => message;
}

/// 通用结果类，用于包装操作结果
class Result<T> {
  final bool isSuccess;
  final T? data;
  final Object? error;

  const Result._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  /// 创建失败结果
  static Result<T> failure<T>(Object error) {
    return Result._(
      isSuccess: false,
      error: error,
    );
  }

  /// 创建成功结果
  static Result<T> success<T>(T data) {
    return Result._(
      isSuccess: true,
      data: data,
    );
  }
}

/// 存储错误
class StorageError implements Exception {
  final String message;
  StorageError(this.message);

  @override
  String toString() => message;
}

/// 验证错误
class ValidationError implements Exception {
  final String message;
  ValidationError(this.message);

  @override
  String toString() => message;
}
