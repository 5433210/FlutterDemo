import 'package:flutter/foundation.dart';

import '../log_entry.dart';
import '../log_level.dart';
import 'log_handler.dart';

class ConsoleLogHandler implements LogHandler {
  @override
  void handle(LogEntry entry) {
    final message = entry.toConsoleString();

    switch (entry.level) {
      case LogLevel.debug:
        debugPrint(message);
        break;
      case LogLevel.info:
        debugPrint('\x1B[34m$message\x1B[0m'); // Blue
        break;
      case LogLevel.warning:
        debugPrint('\x1B[33m$message\x1B[0m'); // Yellow
        break;
      case LogLevel.error:
      case LogLevel.fatal:
        debugPrint('\x1B[31m$message\x1B[0m'); // Red
        break;
    }
  }
}
