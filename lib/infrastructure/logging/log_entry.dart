import 'log_level.dart';

class LogEntry {
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final String? tag;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;

  const LogEntry({
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
    this.error,
    this.stackTrace,
    this.data,
  });

  String toConsoleString() {
    final buffer = StringBuffer();
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    buffer.write('${level.emoji} ');
    buffer.write('[$timeStr] ');
    buffer.write('[${level.name}] ');
    if (tag != null) buffer.write('[$tag] ');
    buffer.write(message);

    if (error != null) {
      buffer.write('\nError: $error');
    }

    if (stackTrace != null) {
      buffer.write('\nStack Trace:\n$stackTrace');
    }

    if (data != null && data!.isNotEmpty) {
      buffer.write('\nData: ${data.toString()}');
    }

    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      if (tag != null) 'tag': tag,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      if (data != null) 'data': data,
    };
  }
}
