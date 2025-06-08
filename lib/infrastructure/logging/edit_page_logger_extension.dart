import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../../utils/config/edit_page_logging_config.dart';
import 'log_level.dart';
import 'logger.dart';

/// AppLogger 扩展 - 字帖编辑页专用日志方法
/// 提供条件日志输出，优化性能
extension EditPageLogger on AppLogger {
  
  // ============ 编辑页面日志 ============
  
  static void editPageDebug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableEditPageLogging && 
        _shouldLog(LogLevel.debug, EditPageLoggingConfig.editPageMinLevel)) {
      AppLogger.debug(message, tag: tag ?? EditPageLoggingConfig.TAG_EDIT_PAGE, data: data);
    }
  }

  static void editPageInfo(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableEditPageLogging && 
        _shouldLog(LogLevel.info, EditPageLoggingConfig.editPageMinLevel)) {
      AppLogger.info(message, tag: tag ?? EditPageLoggingConfig.TAG_EDIT_PAGE, data: data);
    }
  }

  static void editPageWarning(String message, {String? tag, Map<String, dynamic>? data, Object? error}) {
    if (EditPageLoggingConfig.enableEditPageLogging && 
        _shouldLog(LogLevel.warning, EditPageLoggingConfig.editPageMinLevel)) {
      AppLogger.warning(message, tag: tag ?? EditPageLoggingConfig.TAG_EDIT_PAGE, data: data, error: error);
    }
  }

  static void editPageError(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableEditPageLogging && 
        _shouldLog(LogLevel.error, EditPageLoggingConfig.editPageMinLevel)) {
      AppLogger.error(message, tag: tag ?? EditPageLoggingConfig.TAG_EDIT_PAGE, error: error, stackTrace: stackTrace, data: data);
    }
  }

  // ============ 画布日志 ============
  
  static void canvasDebug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableCanvasLogging && 
        _shouldLog(LogLevel.debug, EditPageLoggingConfig.canvasMinLevel)) {
      AppLogger.debug(message, tag: tag ?? EditPageLoggingConfig.TAG_CANVAS, data: data);
    }
  }

  static void canvasError(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableCanvasLogging && 
        _shouldLog(LogLevel.error, EditPageLoggingConfig.canvasMinLevel)) {
      AppLogger.error(message, tag: tag ?? EditPageLoggingConfig.TAG_CANVAS, error: error, stackTrace: stackTrace, data: data);
    }
  }

  // ============ 控制器日志 ============
  
  static void controllerDebug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableControllerLogging && 
        _shouldLog(LogLevel.debug, EditPageLoggingConfig.controllerMinLevel)) {
      AppLogger.debug(message, tag: tag ?? EditPageLoggingConfig.TAG_CONTROLLER, data: data);
    }
  }

  static void controllerInfo(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableControllerLogging && 
        _shouldLog(LogLevel.info, EditPageLoggingConfig.controllerMinLevel)) {
      AppLogger.info(message, tag: tag ?? EditPageLoggingConfig.TAG_CONTROLLER, data: data);
    }
  }

  static void controllerWarning(String message, {String? tag, Map<String, dynamic>? data, Object? error}) {
    if (EditPageLoggingConfig.enableControllerLogging && 
        _shouldLog(LogLevel.warning, EditPageLoggingConfig.controllerMinLevel)) {
      AppLogger.warning(message, tag: tag ?? EditPageLoggingConfig.TAG_CONTROLLER, data: data, error: error);
    }
  }

  static void controllerError(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableControllerLogging && 
        _shouldLog(LogLevel.error, EditPageLoggingConfig.controllerMinLevel)) {
      AppLogger.error(message, tag: tag ?? EditPageLoggingConfig.TAG_CONTROLLER, error: error, stackTrace: stackTrace, data: data);
    }
  }

  // ============ 属性面板日志 ============
  
  static void propertyPanelDebug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enablePropertyPanelLogging && 
        _shouldLog(LogLevel.debug, EditPageLoggingConfig.propertyPanelMinLevel)) {
      AppLogger.debug(message, tag: tag ?? EditPageLoggingConfig.TAG_TEXT_PANEL, data: data);
    }
  }

  static void propertyPanelError(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enablePropertyPanelLogging && 
        _shouldLog(LogLevel.error, EditPageLoggingConfig.propertyPanelMinLevel)) {
      AppLogger.error(message, tag: tag ?? EditPageLoggingConfig.TAG_TEXT_PANEL, error: error, stackTrace: stackTrace, data: data);
    }
  }

  // ============ 渲染器日志 ============
  
  static void rendererDebug(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableRendererLogging && 
        _shouldLog(LogLevel.debug, EditPageLoggingConfig.rendererMinLevel)) {
      AppLogger.debug(message, tag: tag ?? EditPageLoggingConfig.TAG_RENDERER, data: data);
    }
  }

  static void rendererError(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableRendererLogging && 
        _shouldLog(LogLevel.error, EditPageLoggingConfig.rendererMinLevel)) {
      AppLogger.error(message, tag: tag ?? EditPageLoggingConfig.TAG_RENDERER, error: error, stackTrace: stackTrace, data: data);
    }
  }

  // ============ 文件操作日志 ============
  
  static void fileOpsInfo(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableFileOpsLogging && 
        _shouldLog(LogLevel.info, EditPageLoggingConfig.fileOpsMinLevel)) {
      AppLogger.info(message, tag: tag ?? EditPageLoggingConfig.TAG_FILE_OPS, data: data);
    }
  }

  static void fileOpsError(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enableFileOpsLogging && 
        _shouldLog(LogLevel.error, EditPageLoggingConfig.fileOpsMinLevel)) {
      AppLogger.error(message, tag: tag ?? EditPageLoggingConfig.TAG_FILE_OPS, error: error, stackTrace: stackTrace, data: data);
    }
  }

  // ============ 性能监控日志 ============
  
  static void performanceInfo(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enablePerformanceLogging && 
        _shouldLog(LogLevel.info, EditPageLoggingConfig.performanceMinLevel)) {
      AppLogger.info(message, tag: tag ?? EditPageLoggingConfig.TAG_PERFORMANCE, data: data);
    }
  }

  static void performanceWarning(String message, {String? tag, Map<String, dynamic>? data}) {
    if (EditPageLoggingConfig.enablePerformanceLogging && 
        _shouldLog(LogLevel.warning, EditPageLoggingConfig.performanceMinLevel)) {
      AppLogger.warning(message, tag: tag ?? EditPageLoggingConfig.TAG_PERFORMANCE, data: data);
    }
  }

  /// 性能计时日志
  static void logPerformance(String operation, int elapsedMs, {
    String? tag, 
    int? customThreshold,
    Map<String, dynamic>? additionalData
  }) {
    if (!EditPageLoggingConfig.enablePerformanceLogging) return;

    final threshold = customThreshold ?? EditPageLoggingConfig.operationPerformanceThreshold;
    final data = {
      'operation': operation,
      'elapsed_ms': elapsedMs,
      'threshold_ms': threshold,
      if (additionalData != null) ...additionalData,
    };

    if (elapsedMs > threshold) {
      performanceWarning('性能警告: $operation 耗时 ${elapsedMs}ms', tag: tag, data: data);
    } else if (_shouldLog(LogLevel.debug, EditPageLoggingConfig.performanceMinLevel)) {
      performanceInfo('性能监控: $operation 耗时 ${elapsedMs}ms', tag: tag, data: data);
    }
  }

  /// 渲染性能日志 - 专门用于渲染操作
  static void logRenderPerformance(String operation, int elapsedMs, {String? tag, Map<String, dynamic>? additionalData}) {
    logPerformance(operation, elapsedMs, 
        tag: tag ?? EditPageLoggingConfig.TAG_RENDERER,
        customThreshold: EditPageLoggingConfig.renderPerformanceThreshold,
        additionalData: additionalData);
  }

  /// 文件操作性能日志
  static void logFileOperationPerformance(String operation, int elapsedMs, {String? tag, Map<String, dynamic>? additionalData}) {
    logPerformance(operation, elapsedMs, 
        tag: tag ?? EditPageLoggingConfig.TAG_FILE_OPS,
        customThreshold: EditPageLoggingConfig.fileOperationPerformanceThreshold,
        additionalData: additionalData);
  }

  // ============ 辅助方法 ============
  
  static bool _shouldLog(LogLevel logLevel, LogLevel minLevel) {
    return logLevel.index >= minLevel.index;
  }
}

/// 性能计时工具类
class PerformanceTimer {
  final String operation;
  final String? tag;
  final Stopwatch _stopwatch = Stopwatch();
  final Map<String, dynamic>? additionalData;

  PerformanceTimer(this.operation, {this.tag, this.additionalData}) {
    _stopwatch.start();
  }

  /// 完成计时并记录日志
  void finish() {
    _stopwatch.stop();
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    EditPageLogger.logPerformance(operation, elapsedMs, 
        tag: tag, additionalData: additionalData);
  }

  /// 完成渲染计时并记录日志
  void finishRender() {
    _stopwatch.stop();
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    EditPageLogger.logRenderPerformance(operation, elapsedMs, 
        tag: tag, additionalData: additionalData);
  }

  /// 完成文件操作计时并记录日志
  void finishFileOperation() {
    _stopwatch.stop();
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    EditPageLogger.logFileOperationPerformance(operation, elapsedMs, 
        tag: tag, additionalData: additionalData);
  }

  /// 获取当前耗时（不停止计时）
  int get elapsedMilliseconds => _stopwatch.elapsedMilliseconds;
}

/// 批量日志处理器
class BatchLogger {
  static final Map<String, List<_BatchLogEntry>> _batches = {};
  static final Map<String, Timer> _timers = {};
  static const int _batchDelay = 100; // 100ms延迟

  static void addToBatch(String batchKey, LogLevel level, String message, {String? tag, Map<String, dynamic>? data}) {
    _batches.putIfAbsent(batchKey, () => []);
    _batches[batchKey]!.add(_BatchLogEntry(level, message, tag, data));

    // 重置定时器
    _timers[batchKey]?.cancel();
    _timers[batchKey] = Timer(Duration(milliseconds: _batchDelay), () => _flushBatch(batchKey));
  }

  static void _flushBatch(String batchKey) {
    final batch = _batches[batchKey];
    if (batch == null || batch.isEmpty) return;

    final summary = {
      'batch_key': batchKey,
      'count': batch.length,
      'entries': batch.map((e) => e.toMap()).toList(),
    };

    AppLogger.debug('批量日志: $batchKey (${batch.length}条)', 
        tag: 'BatchLogger', data: summary);

    batch.clear();
    _timers.remove(batchKey);
  }

  /// 立即刷新所有批量日志
  static void flushAll() {
    for (final key in _batches.keys.toList()) {
      _flushBatch(key);
    }
  }
}

class _BatchLogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? data;

  const _BatchLogEntry(this.level, this.message, this.tag, this.data);

  Map<String, dynamic> toMap() => {
    'level': level.name,
    'message': message,
    if (tag != null) 'tag': tag,
    if (data != null) 'data': data,
  };
} 