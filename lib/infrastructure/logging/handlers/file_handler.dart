import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../log_entry.dart';
import 'log_handler.dart';

class FileLogHandler implements LogHandler {
  final String filePath;
  final int? maxSizeBytes;
  final int? maxFiles;
  File? _currentFile;
  IOSink? _sink;

  FileLogHandler({
    required this.filePath,
    this.maxSizeBytes,
    this.maxFiles,
  });

  @override
  void handle(LogEntry entry) async {
    if (_sink == null) return;

    try {
      // Format entry for file output (more compact than console output)
      final formattedEntry =
          '${entry.timestamp.toIso8601String()} [${entry.level.name}]${entry.tag != null ? ' [${entry.tag}]' : ''} ${entry.message}';
      _sink!.writeln(formattedEntry);

      // Add error and stack trace if applicable
      if (entry.error != null) {
        _sink!.writeln('Error: ${entry.error}');
      }

      if (entry.stackTrace != null) {
        _sink!.writeln('Stack Trace:');
        _sink!.writeln(entry.stackTrace);
      }

      // Periodically check file size and rotate if needed
      if (maxSizeBytes != null) {
        final size = await _currentFile!.length();
        if (size > maxSizeBytes!) {
          await _rotateLogFile();
        }
      }
    } catch (e) {
      // Fall back to console if file logging fails
      debugPrint('Error writing to log file: $e');
    }
  }

  Future<void> init() async {
    final directory = Directory(path.dirname(filePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final baseFileName = path.basenameWithoutExtension(filePath);
    final extension = path.extension(filePath);
    final today = DateTime.now().toIso8601String().split('T').first;

    _currentFile =
        File('${path.dirname(filePath)}/${baseFileName}_$today$extension');
    _sink = _currentFile!.openWrite(mode: FileMode.append);
  }

  Future<void> _rotateLogFile() async {
    // Close current file
    await _sink?.flush();
    await _sink?.close();

    // Create new file with timestamp
    final baseFileName = path.basenameWithoutExtension(filePath);
    final extension = path.extension(filePath);
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    _currentFile =
        File('${path.dirname(filePath)}/${baseFileName}_$timestamp$extension');
    _sink = _currentFile!.openWrite(mode: FileMode.append);

    // Delete old files if maxFiles is set
    if (maxFiles != null) {
      final directory = Directory(path.dirname(filePath));
      final logFiles = await directory
          .list()
          .where((entity) =>
              entity is File &&
              path.basename(entity.path).startsWith(baseFileName) &&
              path.basename(entity.path).endsWith(extension))
          .toList();

      if (logFiles.length > maxFiles!) {
        // Sort by modification time, oldest first
        logFiles.sort(
            (a, b) => a.statSync().modified.compareTo(b.statSync().modified));

        // Delete oldest files
        for (var i = 0; i < logFiles.length - maxFiles!; i++) {
          await (logFiles[i] as File).delete();
        }
      }
    }
  }
}
