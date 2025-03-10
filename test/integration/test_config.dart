import 'package:demo/infrastructure/logging/log_level.dart';
import 'package:demo/infrastructure/logging/logger.dart';

/// 测试配置
class TestConfig {
  /// CI环境中的超时时间（通常需要更长）
  static const ciTimeoutDuration = Duration(seconds: 30);

  /// 本地测试的超时时间
  static const localTimeoutDuration = Duration(seconds: 5);

  /// 是否在CI环境中运行
  static bool get isInCI =>
      const bool.fromEnvironment('CI', defaultValue: false);

  /// 获取适当的超时时间
  static Duration get timeoutDuration =>
      isInCI ? ciTimeoutDuration : localTimeoutDuration;

  /// 配置测试环境
  static void configureTestEnv() {
    // 配置日志
    AppLogger.init(
      minLevel: LogLevel.debug,
      enableConsole: true,
      enableFile: false,
    );
  }
}

/// 测试日志记录器
class TestLogger {
  static void logTestEnd(String description) {
    AppLogger.info('测试完成: $description', tag: 'TEST');
  }

  static void logTestError(String error,
      {Object? exception, StackTrace? stackTrace}) {
    AppLogger.error(
      error,
      tag: 'TEST',
      error: exception,
      stackTrace: stackTrace,
    );
  }

  static void logTestStart(String description) {
    AppLogger.info('开始测试: $description', tag: 'TEST');
  }

  static void logTestStep(String step) {
    AppLogger.debug(step, tag: 'TEST');
  }
}
