import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'logger.dart';

/// 全局错误处理器
class AppErrorHandler {
  static bool _initialized = false;

  /// 初始化错误处理
  static void initialize() {
    if (_initialized) return;
    _initialized = true;

    // 处理 Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      AppLogger.error(
        '发生Flutter框架错误',
        error: details.exception,
        stackTrace: details.stack,
        tag: 'ErrorHandler',
      );
    };

    // 处理未捕获的异步错误
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error(
        '发生未捕获的平台错误',
        error: error,
        stackTrace: stack,
        tag: 'ErrorHandler',
      );
      return true;
    };

    // 处理Zone内未捕获的错误
    runZonedGuarded(
      () {},
      (Object error, StackTrace stack) {
        AppLogger.error(
          '发生未捕获的Zone错误',
          error: error,
          stackTrace: stack,
          tag: 'ErrorHandler',
        );
      },
    );

    // 处理Isolate错误
    Isolate.current.addErrorListener(RawReceivePort((pair) {
      final List<dynamic> errorAndStacktrace = pair as List<dynamic>;
      AppLogger.error(
        '发生Isolate错误',
        error: errorAndStacktrace.first,
        stackTrace: errorAndStacktrace.last as StackTrace,
        tag: 'ErrorHandler',
      );
    }).sendPort);
  }
}
