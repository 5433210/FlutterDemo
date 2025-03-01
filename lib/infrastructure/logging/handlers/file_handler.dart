import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../log_entry.dart';
import 'log_handler.dart';

// 同步操作的辅助函数
Future<T> synchronized<T>(Object lock, Future<T> Function() computation) async {
  try {
    return await computation();
  } catch (e) {
    rethrow;
  }
}

class FileLogHandler implements LogHandler {
  final String filePath;
  final int? maxSizeBytes;
  final int? maxFiles;

  File? _currentFile;
  IOSink? _sink;
  bool _isWriting = false;
  final List<LogEntry> _pendingLogs = [];
  final Object _writeLock = Object();

  FileLogHandler({
    required this.filePath,
    this.maxSizeBytes,
    this.maxFiles,
  });

  // 清理资源
  Future<void> dispose() async {
    await _sink?.flush();
    await _sink?.close();
    _sink = null;
    _pendingLogs.clear();
  }

  @override
  void handle(LogEntry entry) {
    // 不再直接写入，而是添加到待处理队列
    synchronized(_writeLock, () async {
      _pendingLogs.add(entry);
      return _processLogs();
    });
  }

  Future<void> init() async {
    await _openLogFile();
  }

  Future<void> _checkRotation() async {
    final currentSize = await _currentFile?.length() ?? 0;
    if (maxSizeBytes != null && currentSize > maxSizeBytes!) {
      await _rotateLogFile();
    }
  }

  Future<void> _deleteOldLogFiles() async {
    final directory = Directory(path.dirname(filePath));
    final baseFileName = path.basenameWithoutExtension(filePath);
    final extension = path.extension(filePath);

    final files = await directory
        .list()
        .where((entity) =>
            entity is File &&
            path.basename(entity.path).startsWith(baseFileName) &&
            path.basename(entity.path).endsWith(extension) &&
            entity.path != filePath)
        .toList();

    if (files.length > maxFiles! - 1) {
      // 按修改时间排序（旧的先）
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });

      // 删除最旧的文件
      for (var i = 0; i < files.length - maxFiles! + 1; i++) {
        try {
          await (files[i] as File).delete();
        } catch (e) {
          debugPrint('Failed to delete old log file: $e');
        }
      }
    }
  }

  // 格式化日志条目
  String _formatLogEntry(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String();
    final level = entry.level.name.padRight(7);
    final tag = entry.tag != null ? '[${entry.tag}] ' : '';

    return '$timestamp [$level] $tag${entry.message}';
  }

  Future<void> _openLogFile() async {
    try {
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      _currentFile = File(filePath);
      // 关键修复：避免重用相同的 StreamSink
      await _sink?.close();
      _sink = _currentFile!.openWrite(mode: FileMode.append);
    } catch (e) {
      debugPrint('Error opening log file: $e');
    }
  }

  // 安全地处理日志队列
  Future<void> _processLogs() async {
    if (_isWriting || _pendingLogs.isEmpty) return;

    _isWriting = true;

    try {
      while (_pendingLogs.isNotEmpty) {
        final entry = _pendingLogs.removeAt(0);
        final formattedLog = _formatLogEntry(entry);

        // 创建新的 IOSink 以避免 StreamSink 重用问题
        if (_sink == null) {
          await _openLogFile();
        }

        // 安全写入
        _sink?.writeln(formattedLog);
        await _sink?.flush(); // 立即刷新确保写入

        // 添加错误和堆栈跟踪（如果有）
        if (entry.error != null) {
          _sink?.writeln('Error: ${entry.error}');
        }
        if (entry.stackTrace != null) {
          _sink?.writeln('Stack Trace:');
          _sink?.writeln(entry.stackTrace);
        }

        // 检查是否需要轮换日志文件
        await _checkRotation();
      }
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    } finally {
      _isWriting = false;

      // 检查是否还有更多日志待处理
      if (_pendingLogs.isNotEmpty) {
        _processLogs();
      }
    }
  }

  Future<void> _rotateLogFile() async {
    // 关闭当前文件
    await _sink?.flush();
    await _sink?.close();
    _sink = null;

    // 创建新文件并重命名旧文件
    final baseFileName = path.basenameWithoutExtension(filePath);
    final extension = path.extension(filePath);
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final rotatedPath =
        '${path.dirname(filePath)}/${baseFileName}_$timestamp$extension';

    try {
      await _currentFile?.rename(rotatedPath);
    } catch (e) {
      // 如果重命名失败，尝试复制然后删除
      try {
        await _currentFile?.copy(rotatedPath);
        await _currentFile?.delete();
      } catch (e) {
        debugPrint('Failed to rotate log file: $e');
      }
    }

    // 打开新的日志文件
    await _openLogFile();

    // 删除旧文件（如果需要）
    if (maxFiles != null) {
      await _deleteOldLogFiles();
    }
  }
}
