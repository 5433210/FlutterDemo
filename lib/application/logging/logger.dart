/// 应用日志接口
abstract class AppLogger {
  /// 清理日志
  Future<void> clear();

  /// 关闭日志
  Future<void> close();

  /// 调试日志
  void debug(String message, {Object? error, StackTrace? stackTrace});

  /// 错误日志
  void error(String message, {Object? error, StackTrace? stackTrace});

  /// 信息日志
  void info(String message, {Object? error, StackTrace? stackTrace});

  /// 写入日志
  void log(LogLevel level, String message,
      {Object? error, StackTrace? stackTrace});

  /// 获取日志内容
  Future<List<String>> read({int? limit});

  /// 警告日志
  void warning(String message, {Object? error, StackTrace? stackTrace});
}

/// 控制台日志实现
class ConsoleLogger implements AppLogger {
  @override
  Future<void> clear() async {}

  @override
  Future<void> close() async {}

  @override
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.debug, message, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.info, message, error: error, stackTrace: stackTrace);
  }

  @override
  void log(LogLevel level, String message,
      {Object? error, StackTrace? stackTrace}) {
    final time = DateTime.now().toIso8601String();
    final prefix = '[${level.name.toUpperCase()}][$time]';
    print('$prefix $message');
    if (error != null) print('$prefix Error: $error');
    if (stackTrace != null) print('$prefix Stack trace:\n$stackTrace');
  }

  @override
  Future<List<String>> read({int? limit}) async {
    return [];
  }

  @override
  void warning(String message, {Object? error, StackTrace? stackTrace}) {
    log(LogLevel.warning, message, error: error, stackTrace: stackTrace);
  }
}

/// 日志级别
enum LogLevel {
  debug,
  info,
  warning,
  error,
}
