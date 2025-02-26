import 'package:flutter/foundation.dart';

import 'handlers/console_handler.dart';
import 'handlers/file_handler.dart';
import 'handlers/log_handler.dart';
import 'log_entry.dart';
import 'log_level.dart';

class AppLogger {
  static LogLevel _minLevel = LogLevel.debug;
  static final List<LogHandler> _handlers = [];

  // 便利方法
  static void debug(dynamic message,
      {String? tag, Map<String, dynamic>? data}) {
    log(LogLevel.debug, message, tag: tag, data: data);
  }

  static void error(
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      LogLevel.error,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void fatal(
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      LogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void info(dynamic message, {String? tag, Map<String, dynamic>? data}) {
    log(LogLevel.info, message, tag: tag, data: data);
  }

  // 初始化方法
  static Future<void> init({
    LogLevel minLevel = LogLevel.debug,
    bool enableConsole = true,
    bool enableFile = false,
    String? filePath,
    int? maxFileSizeBytes,
    int? maxFiles,
  }) async {
    _minLevel = minLevel;

    if (enableConsole) {
      _handlers.add(ConsoleLogHandler());
    }

    if (enableFile && filePath != null) {
      final fileHandler = FileLogHandler(
        filePath: filePath,
        maxSizeBytes: maxFileSizeBytes,
        maxFiles: maxFiles,
      );
      await fileHandler.init();
      _handlers.add(fileHandler);
    }
  }

  // 日志记录方法
  static void log(
    LogLevel level,
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (level.index < _minLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message.toString(),
      timestamp: DateTime.now(),
      tag: tag ?? _getCallerTag(),
      error: error,
      stackTrace: stackTrace ?? (error != null ? StackTrace.current : null),
      data: data,
    );

    for (final handler in _handlers) {
      handler.handle(entry);
    }
  }

  static void warning(
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    log(
      LogLevel.warning,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  // 辅助方法
  static String? _getCallerTag() {
    try {
      final frames = StackTrace.current.toString().split('\n');
      if (frames.length > 3) {
        final frame = frames[3].trim();
        final classMethodPattern = RegExp(r'#\d+\s+(.+)\s+\(');
        final match = classMethodPattern.firstMatch(frame);
        if (match != null && match.groupCount >= 1) {
          return match.group(1)?.split('.').first;
        }
      }
    } catch (_) {}
    return null;
  }
}
