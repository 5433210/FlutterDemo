import 'dart:io';
import 'dart:isolate';

/// Isolate 日志辅助类
class IsolateLogger {
  /// 日志发送端口
  static SendPort? _sendPort;

  /// 调试日志
  static void debug(String message, {Map<String, dynamic>? data}) {
    _sendLog('debug', message, data: data);
  }

  /// 错误日志
  static void error(String message,
      {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _sendLog('error', message, data: data, stackTrace: stackTrace);
  }

  /// 致命错误日志
  static void fatal(String message,
      {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    _sendLog('fatal', message, data: data, stackTrace: stackTrace);
  }

  /// 信息日志
  static void info(String message, {Map<String, dynamic>? data}) {
    _sendLog('info', message, data: data);
  }

  /// 初始化 SendPort
  static void initialize(SendPort sendPort) {
    _sendPort = sendPort;
  }

  /// 警告日志
  static void warning(String message, {Map<String, dynamic>? data}) {
    _sendLog('warning', message, data: data);
  }

  /// 向本地文件写入简单日志，用于 Isolate 调试
  static void writeToFile(String message) {
    try {
      final file = File('/storage/emulated/0/Download/flutter_isolate_log.txt');
      final now = DateTime.now().toIso8601String();
      file.writeAsStringSync('[$now] $message\n', mode: FileMode.append);
    } catch (e) {
      // 忽略文件写入错误
    }
  }

  /// 发送日志到主 Isolate
  static void _sendLog(String level, String message,
      {Map<String, dynamic>? data, StackTrace? stackTrace}) {
    if (_sendPort != null) {
      _sendPort!.send(LogMessage(
        level: level,
        message: message,
        data: data,
        stackTrace: stackTrace,
      ));
    }
  }
}

/// Isolate 日志传递消息
class LogMessage {
  final String level;
  final String message;
  final Map<String, dynamic>? data;
  final StackTrace? stackTrace;

  LogMessage({
    required this.level,
    required this.message,
    this.data,
    this.stackTrace,
  });
}
