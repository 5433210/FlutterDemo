import 'dart:async';

import 'package:flutter/foundation.dart';
import 'logger.dart';

/// 编辑页面日志扩展工具
/// 提供专门的组件日志方法，具有智能防重复功能
class EditPageLogger {
  static final Map<String, DateTime> _lastLogTimes = {};
  static final Map<String, dynamic> _lastLogData = {};
  
  // 🚀 批量性能日志系统
  static final Map<String, _PerformanceBatch> _performanceBatches = {};
  static Timer? _batchFlushTimer;
  static const Duration _batchFlushInterval = Duration(seconds: 5);
  static const int _maxBatchSize = 10;
  
  // 🚀 里程碑式日志记录
  static final Map<String, _MilestoneTracker> _milestoneTrackers = {};
  
  /// 画布调试日志（自动防重复）
  static void canvasDebug(String message, {Map<String, dynamic>? data}) {
    _logWithDeduplication('canvas', message, data, const Duration(milliseconds: 50));
  }
  
  /// 属性面板调试日志（自动防重复）
  static void propertyPanelDebug(String message, {Map<String, dynamic>? data, String? tag}) {
    _logWithDeduplication('property_panel', message, data, const Duration(milliseconds: 200));
  }
  
  /// 剪贴板状态日志（自动防重复）
  static void clipboardState(String state, {Map<String, dynamic>? data}) {
    _logWithDeduplication('clipboard', '剪贴板状态: $state', data, const Duration(seconds: 2));
  }
  
  /// 编辑页面信息日志
  static void editPageInfo(String message, {Map<String, dynamic>? data, String? tag}) {
    if (kDebugMode) {
      AppLogger.info(
        message,
        tag: tag ?? 'EditPage',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
      );
    }
  }
  
  /// 编辑页面调试日志
  static void editPageDebug(String message, {Map<String, dynamic>? data, String? tag}) {
    if (kDebugMode) {
      AppLogger.debug(
        message,
        tag: tag ?? 'EditPage',
        data: {
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
      );
    }
  }
  
  /// 编辑页面警告日志
  static void editPageWarning(String message, {Map<String, dynamic>? data, String? tag}) {
    AppLogger.warning(
      message,
      tag: tag ?? 'EditPage',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 编辑页面错误日志
  static void editPageError(String message, {dynamic error, dynamic stackTrace, Map<String, dynamic>? data, String? tag}) {
    AppLogger.error(
      message,
      tag: tag ?? 'EditPage',
      error: error is Exception ? error : (error != null ? Exception(error.toString()) : Exception('Unknown error')),
      stackTrace: stackTrace,
      data: {
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 用户操作日志
  static void userAction(String action, {Map<String, dynamic>? data}) {
    AppLogger.info(
      '用户操作: $action',
      tag: 'EditPage',
      data: {
        'userAction': action,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 性能信息日志（智能批量处理）
  static void performanceInfo(String message, {Map<String, dynamic>? data}) {
    // 检查是否为重复性能事件，如果是则进行批量处理
    if (_isRepetitivePerformanceEvent(message, data)) {
      _addToPerformanceBatch(message, data);
      return;
    }
    
    // 非重复事件直接记录
    _logPerformanceInfoDirect(message, data);
  }
  
  /// 直接记录性能信息日志
  static void _logPerformanceInfoDirect(String message, Map<String, dynamic>? data) {
    AppLogger.info(
      '性能信息: $message',
      tag: 'EditPage',
      data: {
        'performance': true,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 性能警告日志
  static void performanceWarning(String message, {Map<String, dynamic>? data}) {
    AppLogger.warning(
      '性能警告: $message',
      tag: 'EditPage',
      data: {
        'performance': true,
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 画布错误日志
  static void canvasError(String message, {dynamic error, dynamic stackTrace, Map<String, dynamic>? data}) {
    AppLogger.error(
      '画布错误: $message',
      tag: 'EditPage',
      error: error is Exception ? error : (error != null ? Exception(error.toString()) : Exception('Canvas error')),
      stackTrace: stackTrace,
      data: {
        'component': 'canvas',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 渲染器调试日志
  static void rendererDebug(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      AppLogger.debug(
        '渲染器: $message',
        tag: 'EditPage',
        data: {
          'component': 'renderer',
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
      );
    }
  }
  
  /// 渲染器错误日志
  static void rendererError(String message, {dynamic error, dynamic stackTrace, Map<String, dynamic>? data}) {
    AppLogger.error(
      '渲染器错误: $message',
      tag: 'EditPage',
      error: error is Exception ? error : (error != null ? Exception(error.toString()) : Exception('Renderer error')),
      stackTrace: stackTrace,
      data: {
        'component': 'renderer',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 控制器调试日志
  static void controllerDebug(String message, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      AppLogger.debug(
        '控制器: $message',
        tag: 'EditPage',
        data: {
          'component': 'controller',
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
      );
    }
  }
  
  /// 控制器信息日志
  static void controllerInfo(String message, {Map<String, dynamic>? data}) {
    AppLogger.info(
      '控制器: $message',
      tag: 'EditPage',
      data: {
        'component': 'controller',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 控制器警告日志
  static void controllerWarning(String message, {Map<String, dynamic>? data}) {
    AppLogger.warning(
      '控制器警告: $message',
      tag: 'EditPage',
      data: {
        'component': 'controller',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 控制器错误日志
  static void controllerError(String message, {dynamic error, dynamic stackTrace, Map<String, dynamic>? data}) {
    AppLogger.error(
      '控制器错误: $message',
      tag: 'EditPage',
      error: error is Exception ? error : (error != null ? Exception(error.toString()) : Exception('Controller error')),
      stackTrace: stackTrace,
      data: {
        'component': 'controller',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 属性面板错误日志
  static void propertyPanelError(String message, {dynamic error, dynamic stackTrace, Map<String, dynamic>? data, String? tag}) {
    AppLogger.error(
      '属性面板错误: $message',
      tag: tag ?? 'EditPage',
      error: error is Exception ? error : (error != null ? Exception(error.toString()) : Exception('Property panel error')),
      stackTrace: stackTrace,
      data: {
        'component': 'property_panel',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 文件操作信息日志
  static void fileOpsInfo(String message, {Map<String, dynamic>? data}) {
    AppLogger.info(
      '文件操作: $message',
      tag: 'EditPage',
      data: {
        'component': 'file_ops',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 文件操作错误日志
  static void fileOpsError(String message, {dynamic error, dynamic stackTrace, Map<String, dynamic>? data}) {
    AppLogger.error(
      '文件操作错误: $message',
      tag: 'EditPage',
      error: error is Exception ? error : (error != null ? Exception(error.toString()) : Exception('File operation error')),
      stackTrace: stackTrace,
      data: {
        'component': 'file_ops',
        'timestamp': DateTime.now().toIso8601String(),
        ...?data,
      },
    );
  }
  
  /// 带防重复功能的日志记录
  static void _logWithDeduplication(String component, String message, Map<String, dynamic>? data, Duration interval) {
    if (!kDebugMode) return;
    
    final key = '$component:$message';
    final now = DateTime.now();
    final lastTime = _lastLogTimes[key];
    final lastData = _lastLogData[key];
    
    // 检查是否在防重复时间间隔内
    if (lastTime != null && now.difference(lastTime) < interval) {
      // 如果数据相同，则跳过
      if (_mapsEqual(lastData, data)) {
        return;
      }
    }
    
    // 记录日志
    AppLogger.debug(
      message,
      tag: 'EditPage',
      data: {
        'component': component,
        'timestamp': now.toIso8601String(),
        ...?data,
      },
    );
    
    // 更新防重复状态
    _lastLogTimes[key] = now;
    _lastLogData[key] = data;
    
    // 清理过期条目
    _cleanupOldEntries();
  }
  
  /// 比较两个Map是否相等
  static bool _mapsEqual(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }
  
  /// 清理过期的防重复条目
  static void _cleanupOldEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    for (final entry in _lastLogTimes.entries) {
      if (now.difference(entry.value) > const Duration(minutes: 5)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final key in expiredKeys) {
      _lastLogTimes.remove(key);
      _lastLogData.remove(key);
    }
  }
  
  /// 刷新所有批量日志
  static void flushAllBatchLogs() {
    // 这里可以实现批量日志的刷新逻辑
    // 目前是简单的清理
    _lastLogTimes.clear();
    _lastLogData.clear();
  }
  
  /// 清理批量日志
  static void cleanupBatchLogs() {
    _cleanupOldEntries();
  }
  
  // 🚀 ===== 批量性能日志系统实现 =====
  
  /// 检查是否为重复性能事件
  static bool _isRepetitivePerformanceEvent(String message, Map<String, dynamic>? data) {
    // 跳过元素重建相关的重复事件
    if (message.contains('跳过元素重建') || 
        message.contains('跳过重复渲染') ||
        message.contains('跳过重复预加载') ||
        (data?['reason'] == 'Cache hit and not dirty') ||
        (data?['optimization'] == 'render_cache_hit')) {
      return true;
    }
    return false;
  }
  
  /// 添加到性能批次中
  static void _addToPerformanceBatch(String message, Map<String, dynamic>? data) {
    final batchKey = _getBatchKey(message, data);
    final now = DateTime.now();
    
    // 获取或创建批次
    _performanceBatches[batchKey] ??= _PerformanceBatch(
      message: message,
      firstOccurrence: now,
      count: 0,
      sampleData: data,
    );
    
    final batch = _performanceBatches[batchKey]!;
    batch.count++;
    batch.lastOccurrence = now;
    
    // 如果批次达到最大大小，立即刷新
    if (batch.count >= _maxBatchSize) {
      _flushPerformanceBatch(batchKey, batch);
      _performanceBatches.remove(batchKey);
    } else {
      // 否则调度延迟刷新
      _scheduleBatchFlush();
    }
  }
  
  /// 获取批次键
  static String _getBatchKey(String message, Map<String, dynamic>? data) {
    final elementId = data?['elementId'] ?? 'unknown';
    final optimization = data?['optimization'] ?? 'general';
    return '$message-$optimization-${elementId.hashCode.abs() % 1000}';
  }
  
  /// 调度批量刷新
  static void _scheduleBatchFlush() {
    _batchFlushTimer?.cancel();
    _batchFlushTimer = Timer(_batchFlushInterval, () {
      _flushAllPerformanceBatches();
    });
  }
  
  /// 刷新所有性能批次
  static void _flushAllPerformanceBatches() {
    final batches = Map.from(_performanceBatches);
    _performanceBatches.clear();
    
    for (final entry in batches.entries) {
      _flushPerformanceBatch(entry.key, entry.value);
    }
  }
  
  /// 刷新单个性能批次
  static void _flushPerformanceBatch(String batchKey, _PerformanceBatch batch) {
    if (batch.count == 1) {
      // 单次事件直接记录
      _logPerformanceInfoDirect(batch.message, batch.sampleData);
    } else {
      // 批量事件记录摘要
      final duration = batch.lastOccurrence.difference(batch.firstOccurrence);
      _logPerformanceInfoDirect(
        '${batch.message}（批量摘要）',
        {
          'batchCount': batch.count,
          'durationMs': duration.inMilliseconds,
          'firstOccurrence': batch.firstOccurrence.toIso8601String(),
          'lastOccurrence': batch.lastOccurrence.toIso8601String(),
          'avgFrequencyPerSec': duration.inMilliseconds > 0 
              ? (batch.count * 1000 / duration.inMilliseconds).toStringAsFixed(2)
              : 'N/A',
          'batchKey': batchKey,
          'sampleData': batch.sampleData,
          'optimization': 'batch_summary',
        },
      );
    }
  }
  
  // 🚀 ===== 里程碑式日志系统 =====
  
  /// 里程碑式性能日志记录
  static void performanceMilestone(String eventType, {Map<String, dynamic>? data}) {
    final tracker = _milestoneTrackers[eventType] ??= _MilestoneTracker();
    tracker.addEvent(data);
    
    // 每隔一定间隔记录里程碑
    if (tracker.shouldLogMilestone()) {
      final summary = tracker.generateSummary();
      _logPerformanceInfoDirect(
        '性能里程碑: $eventType',
        {
          'milestone': true,
          'eventType': eventType,
          ...summary,
        },
      );
      tracker.reset();
    }
  }
  
  /// 强制刷新所有批量日志
  static void forceFlushBatchLogs() {
    _batchFlushTimer?.cancel();
    _flushAllPerformanceBatches();
  }
}

// 🚀 性能批次数据结构
class _PerformanceBatch {
  final String message;
  final DateTime firstOccurrence;
  final Map<String, dynamic>? sampleData;
  
  int count;
  DateTime lastOccurrence;
  
  _PerformanceBatch({
    required this.message,
    required this.firstOccurrence,
    required this.count,
    this.sampleData,
  }) : lastOccurrence = firstOccurrence;
}

// 🚀 里程碑追踪器
class _MilestoneTracker {
  static const int _milestoneInterval = 50; // 每50次事件记录一次里程碑
  
  int _eventCount = 0;
  DateTime? _firstEvent;
  DateTime? _lastEvent;
  final Map<String, int> _eventTypes = {};
  final List<Map<String, dynamic>> _recentEvents = [];
  
  void addEvent(Map<String, dynamic>? data) {
    _eventCount++;
    final now = DateTime.now();
    
    _firstEvent ??= now;
    _lastEvent = now;
    
    // 统计事件类型
    final optimization = data?['optimization']?.toString() ?? 'unknown';
    _eventTypes[optimization] = (_eventTypes[optimization] ?? 0) + 1;
    
    // 保留最近的几个事件样本
    if (_recentEvents.length >= 5) {
      _recentEvents.removeAt(0);
    }
    _recentEvents.add({
      'timestamp': now.toIso8601String(),
      ...?data,
    });
  }
  
  bool shouldLogMilestone() {
    return _eventCount >= _milestoneInterval;
  }
  
  Map<String, dynamic> generateSummary() {
    final duration = _lastEvent?.difference(_firstEvent!) ?? Duration.zero;
    
    return {
      'totalEvents': _eventCount,
      'durationMs': duration.inMilliseconds,
      'avgEventsPerSec': duration.inMilliseconds > 0
          ? (_eventCount * 1000 / duration.inMilliseconds).toStringAsFixed(2)
          : 'N/A',
      'eventTypes': _eventTypes,
      'recentSamples': _recentEvents,
      'firstEvent': _firstEvent?.toIso8601String(),
      'lastEvent': _lastEvent?.toIso8601String(),
    };
  }
  
  void reset() {
    _eventCount = 0;
    _firstEvent = null;
    _lastEvent = null;
    _eventTypes.clear();
    _recentEvents.clear();
  }
}