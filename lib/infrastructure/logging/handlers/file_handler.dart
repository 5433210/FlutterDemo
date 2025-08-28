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
  final int maxSizeBytes;
  final int maxFiles;

  File? _currentFile;
  IOSink? _sink;
  bool _isWriting = false;
  final List<LogEntry> _pendingLogs = [];
  final Object _writeLock = Object();

  FileLogHandler({
    required this.filePath,
    this.maxSizeBytes = 10 * 1024 * 1024, // 默认10MB
    this.maxFiles = 5, // 默认保留5个文件
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
    // 添加到待处理队列并同步写入
    synchronized(_writeLock, () async {
      _pendingLogs.add(entry);
      await _processLogs();
    });
  }

  Future<void> init() async {
    // 确保日志目录存在
    final directory = Directory(path.dirname(filePath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await _openLogFile();
  }

  Future<void> _checkRotation() async {
    final currentSize = await _currentFile?.length() ?? 0;
    if (currentSize > maxSizeBytes) {
      await _rotateLogFile();
    }
  }

  Future<void> _deleteOldLogFiles() async {
    try {
      final directory = Directory(path.dirname(filePath));
      final baseFileName = path.basenameWithoutExtension(filePath);
      final extension = path.extension(filePath);

      // 获取所有日志文件（包括回滚的文件）
      final files = await directory
          .list()
          .where((entity) =>
              entity is File &&
              path.basename(entity.path).startsWith('${baseFileName}_') &&
              path.basename(entity.path).endsWith(extension))
          .cast<File>()
          .toList();

      if (files.length >= maxFiles) {
        // 按修改时间排序（旧的先）
        files.sort((a, b) {
          try {
            return a.statSync().modified.compareTo(b.statSync().modified);
          } catch (e) {
            // 如果无法获取文件状态，按文件名排序
            return a.path.compareTo(b.path);
          }
        });

        // 删除最旧的文件，保持文件数量不超过maxFiles
        final filesToDelete = files.length - maxFiles + 1;
        for (var i = 0; i < filesToDelete; i++) {
          try {
            await files[i].delete();
            debugPrint('删除旧日志文件: ${files[i].path}');
          } catch (e) {
            debugPrint('删除旧日志文件失败: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('清理旧日志文件时发生错误: $e');
    }
  }

  // 格式化日志条目
  String _formatLogEntry(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String().replaceAll('T', ' ').substring(0, 19);
    final level = entry.level.name.toUpperCase().padRight(7);
    final tag = entry.tag != null ? '[${entry.tag}] ' : '';
    
    String formatted = '$timestamp [$level] $tag${entry.message}';
    
    // 添加数据信息
    if (entry.data != null && entry.data!.isNotEmpty) {
      formatted += ' | Data: ${entry.data}';
    }
    
    return formatted;
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

        if (_sink == null) {
          await _openLogFile();
        }

        try {
          _sink?.writeln(formattedLog);
          
          // 写入错误信息
          if (entry.error != null) {
            _sink?.writeln('  Error: ${entry.error}');
          }
          
          // 写入堆栈跟踪
          if (entry.stackTrace != null) {
            _sink?.writeln('  Stack Trace:');
            final stackLines = entry.stackTrace.toString().split('\n');
            for (final line in stackLines) {
              if (line.trim().isNotEmpty) {
                _sink?.writeln('    $line');
              }
            }
          }
          
          await _sink?.flush();
        } catch (e) {
          debugPrint('Error writing to log file (sink): $e');
        }

        await _checkRotation();
      }
    } catch (e) {
      debugPrint('Error writing to log file: $e');
    } finally {
      _isWriting = false;
      if (_pendingLogs.isNotEmpty) {
        await _processLogs();
      }
    }
  }

  Future<void> _rotateLogFile() async {
    try {
      // 关闭当前文件
      await _sink?.flush();
      await _sink?.close();
      _sink = null;

      // 创建带时间戳的回滚文件名
      final baseFileName = path.basenameWithoutExtension(filePath);
      final extension = path.extension(filePath);
      final timestamp = DateTime.now().toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('T', '_')
          .substring(0, 19); // 格式: 2024-01-01_12-30-45
      
      final rotatedPath = path.join(
        path.dirname(filePath),
        '${baseFileName}_$timestamp$extension'
      );

      // 重命名当前文件
      if (await _currentFile!.exists()) {
        try {
          await _currentFile!.rename(rotatedPath);
          debugPrint('日志文件已回滚: $rotatedPath');
        } catch (e) {
          // 如果重命名失败，尝试复制然后删除
          try {
            await _currentFile!.copy(rotatedPath);
            await _currentFile!.delete();
            debugPrint('日志文件已复制并回滚: $rotatedPath');
          } catch (e) {
            debugPrint('回滚日志文件失败: $e');
          }
        }
      }

      // 打开新的日志文件
      await _openLogFile();

      // 删除旧文件（异步执行，不阻塞日志写入）
      Future.microtask(() => _deleteOldLogFiles());
    } catch (e) {
      debugPrint('日志文件回滚过程中发生错误: $e');
    }
  }
}
