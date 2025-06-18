import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'log_level.dart';
import 'logger.dart';

/// 异步日志处理器
/// 提供高性能的日志批量处理和过滤功能
class AsyncLogger {
  static final AsyncLogger _instance = AsyncLogger._internal();
  factory AsyncLogger() => _instance;
  AsyncLogger._internal();

  // 日志队列和处理控制
  final Queue<LogEntry> _logQueue = Queue<LogEntry>();
  Timer? _batchTimer;
  bool _isProcessing = false;

  // 配置参数
  static const int _maxBatchSize = 100;
  static const int _batchIntervalMs = 1000;
  static const int _maxQueueSize = 1000;
  static const int _highFrequencyThresholdMs = 100;

  // 高频日志过滤
  final Map<String, DateTime> _lastLogTimes = {};
  final Map<String, int> _logCounts = {};

  // 性能统计
  int _totalProcessed = 0;
  int _droppedLogs = 0;
  int _filteredLogs = 0;

  /// 初始化异步日志处理器
  void initialize() {
    // 启动批量处理定时器
    _batchTimer = Timer.periodic(
      const Duration(milliseconds: _batchIntervalMs),
      (_) => _processBatch(),
    );
  }

  /// 添加日志条目到队列
  void addLog(LogEntry entry) {
    // 高频日志过滤
    if (_shouldFilterHighFrequency(entry)) {
      _filteredLogs++;
      return;
    }

    // 队列满时丢弃最旧的日志
    if (_logQueue.length >= _maxQueueSize) {
      _logQueue.removeFirst();
      _droppedLogs++;
    }

    _logQueue.add(entry);

    // 如果队列达到批量大小，立即处理
    if (_logQueue.length >= _maxBatchSize) {
      _processBatch();
    }
  }

  /// 检查是否应该过滤高频日志
  bool _shouldFilterHighFrequency(LogEntry entry) {
    final key = '${entry.level}:${entry.message}';
    final now = DateTime.now();

    final lastTime = _lastLogTimes[key];
    if (lastTime != null) {
      final timeDiff = now.difference(lastTime).inMilliseconds;
      if (timeDiff < _highFrequencyThresholdMs) {
        // 增加计数并过滤
        _logCounts[key] = (_logCounts[key] ?? 0) + 1;
        return true;
      }
    }

    _lastLogTimes[key] = now;

    // 如果之前有被过滤的日志，添加汇总信息
    final count = _logCounts[key];
    if (count != null && count > 0) {
      entry.data ??= {};
      entry.data!['filteredCount'] = count;
      _logCounts[key] = 0;
    }

    return false;
  }

  /// 批量处理日志
  void _processBatch() {
    if (_isProcessing || _logQueue.isEmpty) {
      return;
    }

    _isProcessing = true;

    try {
      final batch = <LogEntry>[];

      // 收集当前批次的日志
      while (batch.length < _maxBatchSize && _logQueue.isNotEmpty) {
        batch.add(_logQueue.removeFirst());
      }

      if (batch.isNotEmpty) {
        _processBatchSync(batch);
        _totalProcessed += batch.length;
      }
    } catch (error) {
      // 错误处理 - 直接输出到调试控制台
      if (kDebugMode) {
        print('AsyncLogger batch processing error: $error');
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// 同步处理批次日志
  void _processBatchSync(List<LogEntry> batch) {
    for (final entry in batch) {
      try {
        // 使用原有的 AppLogger 输出
        switch (entry.level) {
          case LogLevel.debug:
            AppLogger.debug(entry.message,
                data: entry.data, tag: entry.tags?.first);
            break;
          case LogLevel.info:
            AppLogger.info(entry.message,
                data: entry.data, tag: entry.tags?.first);
            break;
          case LogLevel.warning:
            AppLogger.warning(entry.message,
                data: entry.data,
                error: entry.error,
                stackTrace: entry.stackTrace);
            break;
          case LogLevel.error:
            AppLogger.error(entry.message,
                data: entry.data,
                error: entry.error,
                stackTrace: entry.stackTrace,
                tag: entry.tags?.first);
            break;
          case LogLevel.fatal:
            AppLogger.fatal(entry.message,
                data: entry.data,
                error: entry.error,
                stackTrace: entry.stackTrace,
                tag: entry.tags?.first);
            break;
        }
      } catch (error) {
        // 单个日志处理错误不影响其他日志
        if (kDebugMode) {
          print('Error processing log entry: $error');
        }
      }
    }
  }

  /// 强制处理所有待处理的日志
  void flush() {
    while (_logQueue.isNotEmpty) {
      _processBatch();
    }
  }

  /// 获取统计信息
  Map<String, dynamic> getStats() {
    return {
      'totalProcessed': _totalProcessed,
      'droppedLogs': _droppedLogs,
      'filteredLogs': _filteredLogs,
      'queueSize': _logQueue.length,
      'isProcessing': _isProcessing,
      'highFrequencyKeys': _logCounts.length,
    };
  }

  /// 重置统计信息
  void resetStats() {
    _totalProcessed = 0;
    _droppedLogs = 0;
    _filteredLogs = 0;
    _lastLogTimes.clear();
    _logCounts.clear();
  }

  /// 关闭异步日志处理器
  void dispose() {
    _batchTimer?.cancel();
    flush(); // 处理剩余日志
  }
}

/// 日志条目数据结构
class LogEntry {
  final LogLevel level;
  final String message;
  Map<String, dynamic>? data;
  final List<String>? tags;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  LogEntry({
    required this.level,
    required this.message,
    this.data,
    this.tags,
    this.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();
}
