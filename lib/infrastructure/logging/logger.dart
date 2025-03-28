import 'dart:isolate';

import 'package:flutter/widgets.dart';

import 'handlers/console_handler.dart';
import 'handlers/file_handler.dart';
import 'handlers/log_handler.dart';
import 'isolate_logger.dart';
import 'log_entry.dart';
import 'log_level.dart';

// 同步锁辅助函数
Future<T> synchronized<T>(Object lock, T Function() computation) async {
  try {
    return computation();
  } catch (e) {
    rethrow;
  }
}

class AppLogger {
  static LogLevel _minLevel = LogLevel.debug;
  static final List<LogHandler> _handlers = [];
  // 添加同步锁，防止并发写入
  static final _logLock = Object();

  static final _logQueue = <_LogEntry>[];
  static bool _isProcessingLogs = false;

  /// 初始化 Isolate 日志通道
  static ReceivePort? _isolateLogReceiver;

  static bool get hasHandlers => _handlers.isNotEmpty;

  // 便利方法
  static void debug(dynamic message,
      {String? tag, Map<String, dynamic>? data}) {
    _queueLog(LogLevel.debug, message, tag: tag, data: data);
  }

  static void error(
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _queueLog(
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
    _queueLog(
      LogLevel.fatal,
      message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void info(dynamic message, {String? tag, Map<String, dynamic>? data}) {
    _queueLog(LogLevel.info, message, tag: tag, data: data);
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

  /// 启动 Isolate 日志监听
  static ReceivePort startIsolateLogging() {
    _isolateLogReceiver = ReceivePort();
    _isolateLogReceiver!.listen(_handleIsolateLog);
    return _isolateLogReceiver!;
  }

  /// 停止 Isolate 日志监听
  static void stopIsolateLogging() {
    _isolateLogReceiver?.close();
    _isolateLogReceiver = null;
  }

  static void warning(
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _queueLog(
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

  /// 处理来自 Isolate 的日志消息
  static void _handleIsolateLog(dynamic message) {
    if (message is LogMessage) {
      switch (message.level) {
        case 'debug':
          debug('[Isolate] ${message.message}', data: message.data);
          break;
        case 'info':
          info('[Isolate] ${message.message}', data: message.data);
          break;
        case 'warning':
          warning('[Isolate] ${message.message}', data: message.data);
          break;
        case 'error':
          error('[Isolate] ${message.message}',
              data: message.data, stackTrace: message.stackTrace);
          break;
        case 'fatal':
          fatal('[Isolate] ${message.message}',
              data: message.data, stackTrace: message.stackTrace);
          break;
      }
    }
  }

  // 处理日志队列
  static Future<void> _processLogQueue() async {
    if (_logQueue.isEmpty) {
      _isProcessingLogs = false;
      return;
    }

    _isProcessingLogs = true;
    final entry = _logQueue.removeAt(0);

    try {
      // 实际的日志处理
      log(entry.level, entry.message,
          tag: entry.tag,
          error: entry.error,
          stackTrace: entry.stackTrace,
          data: entry.data);
    } catch (e) {
      debugPrint('Error processing log: $e');
    } finally {
      // 继续处理队列中的下一个日志
      _processLogQueue();
    }
  }

  // 使用队列处理日志，避免并发问题
  static void _queueLog(
    LogLevel level,
    dynamic message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final entry = _LogEntry(
      level: level,
      message: message.toString(),
      tag: tag,
      error: error,
      stackTrace: stackTrace,
      data: data,
      timestamp: DateTime.now(),
    );

    synchronized(_logLock, () {
      _logQueue.add(entry);
      if (!_isProcessingLogs) {
        _processLogQueue();
      }
    });
  }
}

// 辅助类表示日志条目
class _LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  _LogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.data,
    required this.timestamp,
  });
}
