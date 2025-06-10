import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/logging/logger.dart';

/// Enhanced performance tracker with detailed metrics collection
/// Implements Task 5.1: Enhanced frame time tracking, detailed logging, and regression detection
class EnhancedPerformanceTracker extends ChangeNotifier {
  static final EnhancedPerformanceTracker _instance =
      EnhancedPerformanceTracker._internal();

  // Performance thresholds
  // Target FPS is 60, used to define various thresholds in the calculations
  static const double _regressionThreshold =
      0.85; // 15% degradation triggers regression

  // 🚀 性能优化：节流通知机制
  DateTime _lastNotificationTime = DateTime.now();
  static const Duration _notificationThrottle = Duration(milliseconds: 500); // 最多每500ms通知一次

  // Frame timing detailed tracking
  final List<FrameTimingData> _frameTimingHistory = [];
  final int _maxFrameHistory = 1000; // Keep last 1000 frames

  // Performance regression detection
  final List<PerformanceBaseline> _performanceBaselines = [];
  PerformanceBaseline? _currentBaseline;

  // Detailed performance logging
  final List<PerformanceEvent> _performanceEvents = [];
  late File _logFile;
  bool _loggingEnabled = false;

  // Flag to handle callback removal
  bool _isDisposed = false;

  // Enhanced metrics
  final Queue<double> _fpsQueue = Queue<double>();
  final Queue<Duration> _frameTimeQueue = Queue<Duration>();
  final Map<String, OperationMetrics> _operationMetrics = {};
  factory EnhancedPerformanceTracker() => _instance;
  EnhancedPerformanceTracker._internal();

  // Getters for enhanced metrics
  PerformanceBaseline? get currentBaseline => _currentBaseline;
  List<FrameTimingData> get frameTimingHistory =>
      List.unmodifiable(_frameTimingHistory);
  bool get isLoggingEnabled => _loggingEnabled;
  List<PerformanceEvent> get performanceEvents =>
      List.unmodifiable(_performanceEvents);

  /// Create a performance baseline for regression detection
  void createPerformanceBaseline(String name, {String? description}) {
    if (_frameTimingHistory.length < 60) {
      EditPageLogger.performanceWarning(
        '无足够帧数据创建基准线',
        data: {
          'currentFrameCount': _frameTimingHistory.length,
          'requiredFrameCount': 60,
          'operation': 'createPerformanceBaseline',
        },
      );
      return;
    }

    final recentFrames = _frameTimingHistory.length <= 60
        ? _frameTimingHistory
        : _frameTimingHistory.sublist(_frameTimingHistory.length - 60);
    final avgFps = recentFrames.map((f) => f.fps).reduce((a, b) => a + b) /
        recentFrames.length;
    final avgFrameTime = Duration(
      microseconds: recentFrames
              .map((f) => f.frameTime.inMicroseconds)
              .reduce((a, b) => a + b) ~/
          recentFrames.length,
    );
    final jankPercentage =
        recentFrames.where((f) => f.jank).length / recentFrames.length * 100;

    final baseline = PerformanceBaseline(
      name: name,
      description: description,
      timestamp: DateTime.now(),
      averageFps: avgFps,
      averageFrameTime: avgFrameTime,
      jankPercentage: jankPercentage,
      sampleSize: recentFrames.length,
    );

    _performanceBaselines.add(baseline);
    _currentBaseline = baseline;

    _logPerformanceEvent(PerformanceEvent(
      timestamp: DateTime.now(),
      type: PerformanceEventType.baselineCreated,
      data: {
        'baselineName': name,
        'averageFps': avgFps,
        'jankPercentage': jankPercentage,
      },
      severity: PerformanceSeverity.info,
    ));

    EditPageLogger.performanceInfo(
      '性能基准线创建完成',
      data: {
        'baselineName': name,
        'description': description,
        'averageFps': double.parse(avgFps.toStringAsFixed(1)),
        'averageFrameTime_ms': avgFrameTime.inMilliseconds,
        'jankPercentage': double.parse(jankPercentage.toStringAsFixed(2)),
        'sampleSize': recentFrames.length,
      },
    );
  }

  /// Dispose of the tracker
  @override
  void dispose() {
    // Since there's no direct removeFrameCallback method in SchedulerBinding,
    // we'll use a flag to ignore callbacks after disposal
    _isDisposed = true;
    super.dispose();
  }

  /// End tracking a specific operation and return metrics
  OperationMetrics? endOperationTracking(String operationName) {
    final metrics = _operationMetrics.remove(operationName);
    if (metrics == null) return null;

    final now = DateTime.now();
    final duration = now.difference(metrics.startTime);
    final frameCount = _frameTimingHistory.length - metrics.startFrameCount;

    // Calculate operation-specific metrics
    final operationFrames = _frameTimingHistory
        .skip(metrics.startFrameCount)
        .take(frameCount)
        .toList();

    final avgFps = operationFrames.isEmpty
        ? 0.0
        : operationFrames.map((f) => f.fps).reduce((a, b) => a + b) /
            operationFrames.length;

    final jankFrames = operationFrames.where((f) => f.jank).length;
    final jankPercentage = operationFrames.isEmpty
        ? 0.0
        : jankFrames / operationFrames.length * 100;

    final completedMetrics = metrics.copyWith(
      endTime: now,
      duration: duration,
      frameCount: frameCount,
      averageFps: avgFps,
      jankPercentage: jankPercentage,
    );

    _logPerformanceEvent(PerformanceEvent(
      timestamp: now,
      type: PerformanceEventType.operationEnd,
      data: {
        'operation': operationName,
        'duration': duration.inMilliseconds,
        'averageFps': avgFps,
        'jankPercentage': jankPercentage,
      },
      severity: avgFps < 45.0
          ? PerformanceSeverity.warning
          : PerformanceSeverity.info,
    ));

    return completedMetrics;
  }

  /// Export performance data to JSON
  Future<String> exportPerformanceData() async {
    final data = {
      'exportTimestamp': DateTime.now().toIso8601String(),
      'frameTimingHistory':
          _frameTimingHistory.map((frame) => frame.toJson()).toList(),
      'performanceEvents':
          _performanceEvents.map((event) => event.toJson()).toList(),
      'baselines':
          _performanceBaselines.map((baseline) => baseline.toJson()).toList(),
      'currentReport': generatePerformanceReport().toJson(),
    };

    return jsonEncode(data);
  }

  /// Get comprehensive performance report
  PerformanceReport generatePerformanceReport() {
    if (_frameTimingHistory.isEmpty) {
      return PerformanceReport.empty();
    }

    final recentFrames = _frameTimingHistory.length <= 300
        ? _frameTimingHistory
        : _frameTimingHistory.sublist(
            _frameTimingHistory.length - 300); // Last 5 seconds at 60fps
    final avgFps = recentFrames.map((f) => f.fps).reduce((a, b) => a + b) /
        recentFrames.length;
    final minFps =
        recentFrames.map((f) => f.fps).reduce((a, b) => a < b ? a : b);
    final maxFps =
        recentFrames.map((f) => f.fps).reduce((a, b) => a > b ? a : b);

    final avgFrameTime = Duration(
      microseconds: recentFrames
              .map((f) => f.frameTime.inMicroseconds)
              .reduce((a, b) => a + b) ~/
          recentFrames.length,
    );

    final jankFrames = recentFrames.where((f) => f.jank).length;
    final jankPercentage = jankFrames / recentFrames.length * 100;

    final criticalEvents = _performanceEvents
        .where((e) => e.severity == PerformanceSeverity.critical)
        .length;

    return PerformanceReport(
      timestamp: DateTime.now(),
      sampleDuration: const Duration(seconds: 5),
      averageFps: avgFps,
      minFps: minFps,
      maxFps: maxFps,
      averageFrameTime: avgFrameTime,
      jankPercentage: jankPercentage,
      totalFrames: recentFrames.length,
      jankFrames: jankFrames,
      criticalEvents: criticalEvents,
      baseline: _currentBaseline,
      performanceGrade: _calculatePerformanceGrade(avgFps, jankPercentage),
    );
  }

  /// Initialize enhanced performance tracking
  Future<void> initialize() async {
    await _initializeLogging();
    _startDetailedTracking();

    EditPageLogger.performanceInfo(
      '增强性能追踪器初始化完成',
      data: {
        'loggingEnabled': _loggingEnabled,
        'maxFrameHistory': _maxFrameHistory,
        'operation': 'initialize',
      },
    );
  }

  /// Reset all performance tracking data
  void reset() {
    _frameTimingHistory.clear();
    _performanceEvents.clear();
    _fpsQueue.clear();
    _frameTimeQueue.clear();
    _operationMetrics.clear();
    
    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'reset',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    EditPageLogger.performanceInfo(
      '性能追踪器重置完成',
      data: {
        'clearedFrameHistory': _frameTimingHistory.length,
        'clearedEvents': _performanceEvents.length,
        'clearedOperations': _operationMetrics.length,
      },
    );
  }

  /// Start tracking a specific operation
  void startOperationTracking(String operationName) {
    final now = DateTime.now();
    _operationMetrics[operationName] = OperationMetrics(
      operationName: operationName,
      startTime: now,
      startFrameCount: _frameTimingHistory.length,
    );

    _logPerformanceEvent(PerformanceEvent(
      timestamp: now,
      type: PerformanceEventType.operationStart,
      data: {'operation': operationName},
      severity: PerformanceSeverity.info,
    ));
  }

  /// Calculate performance grade based on metrics
  PerformanceGrade _calculatePerformanceGrade(
      double avgFps, double jankPercentage) {
    if (avgFps >= 58.0 && jankPercentage <= 2.0) {
      return PerformanceGrade.excellent;
    } else if (avgFps >= 50.0 && jankPercentage <= 5.0) {
      return PerformanceGrade.good;
    } else if (avgFps >= 40.0 && jankPercentage <= 10.0) {
      return PerformanceGrade.acceptable;
    } else if (avgFps >= 30.0) {
      return PerformanceGrade.poor;
    } else {
      return PerformanceGrade.critical;
    }
  }

  /// Check for performance regression against current baseline
  void _checkPerformanceRegression(FrameTimingData frameData) {
    if (_currentBaseline == null || _fpsQueue.length < 60) return;

    final currentAvgFps = _fpsQueue.reduce((a, b) => a + b) / _fpsQueue.length;
    final baselineFps = _currentBaseline!.averageFps;

    // Check if current performance is significantly worse than baseline
    if (currentAvgFps < baselineFps * _regressionThreshold) {
      final regressionPercentage =
          ((baselineFps - currentAvgFps) / baselineFps * 100);

      _logPerformanceEvent(PerformanceEvent(
        timestamp: DateTime.now(),
        type: PerformanceEventType.performanceRegression,
        data: {
          'baselineFps': baselineFps,
          'currentFps': currentAvgFps,
          'regressionPercentage': regressionPercentage,
          'baselineName': _currentBaseline!.name,
        },
        severity: regressionPercentage > 25.0
            ? PerformanceSeverity.critical
            : PerformanceSeverity.warning,
      ));

      EditPageLogger.performanceWarning(
        '检测到性能回归',
        data: {
          'currentFps': double.parse(currentAvgFps.toStringAsFixed(1)),
          'baselineFps': double.parse(baselineFps.toStringAsFixed(1)),
          'degradationPercentage': double.parse(regressionPercentage.toStringAsFixed(1)),
          'baselineName': _currentBaseline!.name,
          'regressionThreshold': _regressionThreshold,
        },
      );
    }
  }

  /// Initialize performance logging to file
  Future<void> _initializeLogging() async {
    try {
      final directory = Directory('logs/performance');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      _logFile = File('logs/performance/performance_log_$timestamp.json');
      _loggingEnabled = true;

      EditPageLogger.performanceInfo(
        '性能日志记录初始化完成',
        data: {
          'logFilePath': _logFile.path,
          'loggingEnabled': true,
        },
      );
    } catch (e) {
      EditPageLogger.performanceWarning(
        '性能日志记录初始化失败',
        data: {
          'error': e.toString(),
          'loggingEnabled': false,
        },
      );
      _loggingEnabled = false;
    }
  }

  /// Log a performance event
  void _logPerformanceEvent(PerformanceEvent event) {
    _performanceEvents.add(event);

    // Maintain event history (keep last 1000 events)
    if (_performanceEvents.length > 1000) {
      _performanceEvents.removeAt(0);
    }

    // Write to log file
    if (_loggingEnabled) {
      _writeEventToFile(event);
    }

    // Debug output for critical events
    if (event.severity == PerformanceSeverity.critical) {
      EditPageLogger.performanceWarning(
        '关键性能事件',
        data: {
          'eventType': event.type.toString(),
          'eventData': event.data,
          'severity': 'critical',
          'timestamp': event.timestamp.toIso8601String(),
        },
      );
    }
  }

  /// Frame callback for detailed timing analysis
  void _onFrameCallback(Duration timeStamp) {
    // Skip if disposed
    if (_isDisposed) return;

    final now = DateTime.now();

    // Calculate frame timing
    if (_frameTimingHistory.isNotEmpty) {
      final lastFrame = _frameTimingHistory.last;
      final frameTime = now.difference(lastFrame.timestamp);
      final fps = 1000.0 / frameTime.inMilliseconds;

      final frameData = FrameTimingData(
        timestamp: now,
        frameTime: frameTime,
        fps: fps,
        jank: frameTime.inMilliseconds > 16.7,
        cpuTime: Duration.zero, // Would need platform channel for real CPU time
        gpuTime: Duration.zero, // Would need platform channel for real GPU time
      );

      _recordFrameTiming(frameData);
      _updateRollingMetrics(frameData);
      _checkPerformanceRegression(frameData);
    } else {
      // First frame
      final frameData = FrameTimingData(
        timestamp: now,
        frameTime: Duration.zero,
        fps: 60.0,
        jank: false,
        cpuTime: Duration.zero,
        gpuTime: Duration.zero,
      );
      _recordFrameTiming(frameData);
    }
  }

  /// Record detailed frame timing data
  void _recordFrameTiming(FrameTimingData frameData) {
    _frameTimingHistory.add(frameData);

    // Maintain rolling window
    if (_frameTimingHistory.length > _maxFrameHistory) {
      _frameTimingHistory.removeAt(0);
    }

    // Log performance events
    if (frameData.jank) {
      _logPerformanceEvent(PerformanceEvent(
        timestamp: frameData.timestamp,
        type: PerformanceEventType.frameJank,
        data: {
          'frameTime': frameData.frameTime.inMilliseconds,
          'fps': frameData.fps,
        },
        severity: frameData.frameTime.inMilliseconds > 33.0
            ? PerformanceSeverity.critical
            : PerformanceSeverity.warning,
      ));
    }

    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'record_frame_timing',
      data: {
        'frameTime_ms': frameData.frameTime.inMilliseconds,
        'fps': frameData.fps,
        'jank': frameData.jank,
      },
    );
  }

  /// Start detailed performance tracking
  void _startDetailedTracking() {
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrameCallback);
  }

  /// Update rolling metrics for performance analysis
  void _updateRollingMetrics(FrameTimingData frameData) {
    _fpsQueue.add(frameData.fps);
    _frameTimeQueue.add(frameData.frameTime);

    // Maintain rolling window of 60 frames (1 second at 60fps)
    while (_fpsQueue.length > 60) {
      _fpsQueue.removeFirst();
      _frameTimeQueue.removeFirst();
    }
  }

  /// Write performance event to log file
  Future<void> _writeEventToFile(PerformanceEvent event) async {
    if (!_loggingEnabled) return;

    try {
      final eventJson = {
        'timestamp': event.timestamp.toIso8601String(),
        'type': event.type.toString(),
        'severity': event.severity.toString(),
        'data': event.data,
      };

      await _logFile.writeAsString(
        '${jsonEncode(eventJson)}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      EditPageLogger.performanceWarning(
        '写入性能事件到文件失败',
        data: {
          'error': e.toString(),
          'loggingEnabled': _loggingEnabled,
          'eventType': event.type.toString(),
        },
      );
    }
  }

  /// 🚀 节流通知方法 - 避免性能跟踪本身影响性能
  void _throttledNotifyListeners({
    required String operation,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _notificationThrottle) {
      _lastNotificationTime = now;
      
      EditPageLogger.performanceInfo(
        '增强性能跟踪器通知',
        data: {
          'operation': operation,
          'frameHistoryCount': _frameTimingHistory.length,
          'performanceEventsCount': _performanceEvents.length,
          'operationMetricsCount': _operationMetrics.length,
          'optimization': 'throttled_enhanced_tracker_notification',
          ...?data,
        },
      );
      
      notifyListeners();
    }
  }
}

/// Detailed frame timing data
class FrameTimingData {
  final DateTime timestamp;
  final Duration frameTime;
  final double fps;
  final bool jank;
  final Duration cpuTime;
  final Duration gpuTime;

  const FrameTimingData({
    required this.timestamp,
    required this.frameTime,
    required this.fps,
    required this.jank,
    required this.cpuTime,
    required this.gpuTime,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'frameTime': frameTime.inMicroseconds,
        'fps': fps,
        'jank': jank,
        'cpuTime': cpuTime.inMicroseconds,
        'gpuTime': gpuTime.inMicroseconds,
      };
}

/// Operation-specific metrics
class OperationMetrics {
  final String operationName;
  final DateTime startTime;
  final int startFrameCount;
  final DateTime? endTime;
  final Duration? duration;
  final int? frameCount;
  final double? averageFps;
  final double? jankPercentage;

  const OperationMetrics({
    required this.operationName,
    required this.startTime,
    required this.startFrameCount,
    this.endTime,
    this.duration,
    this.frameCount,
    this.averageFps,
    this.jankPercentage,
  });

  OperationMetrics copyWith({
    DateTime? endTime,
    Duration? duration,
    int? frameCount,
    double? averageFps,
    double? jankPercentage,
  }) {
    return OperationMetrics(
      operationName: operationName,
      startTime: startTime,
      startFrameCount: startFrameCount,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      frameCount: frameCount ?? this.frameCount,
      averageFps: averageFps ?? this.averageFps,
      jankPercentage: jankPercentage ?? this.jankPercentage,
    );
  }
}

/// Performance baseline for regression detection
class PerformanceBaseline {
  final String name;
  final String? description;
  final DateTime timestamp;
  final double averageFps;
  final Duration averageFrameTime;
  final double jankPercentage;
  final int sampleSize;

  const PerformanceBaseline({
    required this.name,
    this.description,
    required this.timestamp,
    required this.averageFps,
    required this.averageFrameTime,
    required this.jankPercentage,
    required this.sampleSize,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'timestamp': timestamp.toIso8601String(),
        'averageFps': averageFps,
        'averageFrameTime': averageFrameTime.inMicroseconds,
        'jankPercentage': jankPercentage,
        'sampleSize': sampleSize,
      };
}

/// Performance event for detailed logging
class PerformanceEvent {
  final DateTime timestamp;
  final PerformanceEventType type;
  final Map<String, dynamic> data;
  final PerformanceSeverity severity;

  const PerformanceEvent({
    required this.timestamp,
    required this.type,
    required this.data,
    required this.severity,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type.toString(),
        'data': data,
        'severity': severity.toString(),
      };
}

/// Types of performance events
enum PerformanceEventType {
  frameJank,
  operationStart,
  operationEnd,
  baselineCreated,
  performanceRegression,
  memoryWarning,
  cpuSpike,
}

/// Performance grade categories
enum PerformanceGrade {
  excellent,
  good,
  acceptable,
  poor,
  critical,
  unknown,
}

/// Comprehensive performance report
class PerformanceReport {
  final DateTime timestamp;
  final Duration sampleDuration;
  final double averageFps;
  final double minFps;
  final double maxFps;
  final Duration averageFrameTime;
  final double jankPercentage;
  final int totalFrames;
  final int jankFrames;
  final int criticalEvents;
  final PerformanceBaseline? baseline;
  final PerformanceGrade performanceGrade;

  const PerformanceReport({
    required this.timestamp,
    required this.sampleDuration,
    required this.averageFps,
    required this.minFps,
    required this.maxFps,
    required this.averageFrameTime,
    required this.jankPercentage,
    required this.totalFrames,
    required this.jankFrames,
    required this.criticalEvents,
    this.baseline,
    required this.performanceGrade,
  });

  factory PerformanceReport.empty() {
    return PerformanceReport(
      timestamp: DateTime.now(),
      sampleDuration: Duration.zero,
      averageFps: 0.0,
      minFps: 0.0,
      maxFps: 0.0,
      averageFrameTime: Duration.zero,
      jankPercentage: 0.0,
      totalFrames: 0,
      jankFrames: 0,
      criticalEvents: 0,
      performanceGrade: PerformanceGrade.unknown,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'sampleDuration': sampleDuration.inMilliseconds,
        'averageFps': averageFps,
        'minFps': minFps,
        'maxFps': maxFps,
        'averageFrameTime': averageFrameTime.inMicroseconds,
        'jankPercentage': jankPercentage,
        'totalFrames': totalFrames,
        'jankFrames': jankFrames,
        'criticalEvents': criticalEvents,
        'baseline': baseline?.toJson(),
        'performanceGrade': performanceGrade.toString(),
      };
}

/// Performance event severity levels
enum PerformanceSeverity {
  info,
  warning,
  critical,
}
