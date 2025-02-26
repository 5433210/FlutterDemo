import '../log_entry.dart';

abstract class LogHandler {
  void handle(LogEntry entry);
}
