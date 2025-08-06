import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import 'drag_state_manager.dart';
import 'performance_dashboard.dart';

/// Performance monitoring utility for M3Canvas optimization tracking
class PerformanceMonitor extends ChangeNotifier {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  // 🚀 性能优化：节流通知机制
  DateTime _lastNotificationTime = DateTime.now();
  static const Duration _notificationThrottle =
      Duration(milliseconds: 500); // 最多每500ms通知一次

  // Performance thresholds
  static const double _fpsThresholdHigh = 55.0;
  static const double _fpsThresholdMedium = 30.0;
  static const double _fpsThresholdLow = 15.0;
  static const int _frameTimeThresholdMs = 20; // Jank threshold
  static const int _rebuildThresholdPerSecond = 100;

  // Frame rate tracking
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();

  double _currentFPS = 0.0;
  final List<double> _fpsHistory = [];
  final int _maxHistoryLength = 60; // Keep 60 seconds of history
  // Performance metrics
  final List<Duration> _frameTimeHistory = [];
  Duration _averageFrameTime = Duration.zero;

  Duration _maxFrameTime = Duration.zero;
  int _slowFrameCount = 0;

  // Threshold tracking
  DateTime _lastThresholdCheck = DateTime.now();
  int _thresholdViolationCount = 0;
  // Memory tracking
  final List<int> _memoryHistory = [];
  // Widget rebuild tracking
  final Map<String, int> _widgetRebuildCounts = {};
  int _totalRebuilds = 0;

  // Drag performance metrics
  DragStateManager? _dragStateManager;

  // Drag performance tracking
  DateTime? _dragStartTime;
  int _dragStartFrameCount = 0;
  final List<double> _dragFrameTimes = [];
  final List<double> _dragFpsValues = [];
  factory PerformanceMonitor() => _instance;

  PerformanceMonitor._internal();

  /// 🚀 节流通知方法 - 避免性能监控本身影响性能
  void _throttledNotifyListeners({
    required String operation,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _notificationThrottle) {
      _lastNotificationTime = now;

      EditPageLogger.performanceInfo(
        '性能监控通知',
        data: {
          'operation': operation,
          'currentFPS': _currentFPS,
          'totalRebuilds': _totalRebuilds,
          'slowFrameCount': _slowFrameCount,
          'optimization': 'throttled_performance_notification',
          ...?data,
        },
      );

      notifyListeners();
    }
  }

  Duration get averageFrameTime => _averageFrameTime;
  // Getters for current metrics
  double get currentFPS => _currentFPS;

  List<double> get fpsHistory => List.unmodifiable(_fpsHistory);

  /// 是否有拖拽性能数据可用
  bool get hasDragPerformanceData =>
      _dragStateManager != null && _dragStateManager!.isDragging;

  Duration get maxFrameTime => _maxFrameTime;

  int get slowFrameCount => _slowFrameCount;

  int get totalRebuilds => _totalRebuilds;

  /// 结束拖拽性能跟踪并生成报告
  Map<String, dynamic> endTrackingDragPerformance() {
    if (_dragStateManager == null || _dragStartTime == null) {
      return {};
    }

    final now = DateTime.now();
    final duration = now.difference(_dragStartTime!);
    final frameCount = _frameCount - _dragStartFrameCount;

    // 计算平均帧率
    double avgFps = 0;
    if (_dragFpsValues.isNotEmpty) {
      avgFps = _dragFpsValues.reduce((a, b) => a + b) / _dragFpsValues.length;
    }

    // 计算帧时间统计
    final Map<String, dynamic> frameTimeStats = {};
    if (_dragFrameTimes.isNotEmpty) {
      final avgFrameTime =
          _dragFrameTimes.reduce((a, b) => a + b) / _dragFrameTimes.length;
      final maxFrameTime = _dragFrameTimes.reduce((a, b) => a > b ? a : b);
      final minFrameTime = _dragFrameTimes.reduce((a, b) => a < b ? a : b);

      frameTimeStats['avg'] = avgFrameTime;
      frameTimeStats['max'] = maxFrameTime;
      frameTimeStats['min'] = minFrameTime;

      // 计算jank帧数量 (超过16.7ms的帧)
      final jankFrames = _dragFrameTimes.where((t) => t > 16.7).length;
      frameTimeStats['jankFrames'] = jankFrames;
      frameTimeStats['jankPercentage'] =
          jankFrames / _dragFrameTimes.length * 100;
    }

    // 生成性能报告
    final report = {
      'duration': duration.inMilliseconds,
      'frameCount': frameCount,
      'fps': {
        'avg': avgFps,
        'values': _dragFpsValues,
      },
      'frameTimes': frameTimeStats,
      'dragElementCount': _dragStateManager?.draggingElementIds.length ?? 0,
      'dragStateManagerReport': _dragStateManager?.getPerformanceReport() ?? {},
      'optimizationConfig':
          _dragStateManager?.getPerformanceOptimizationConfig() ?? {},
    };

    EditPageLogger.performanceInfo(
      '拖拽性能报告生成完成',
      data: {
        'duration_ms': duration.inMilliseconds,
        'frameCount': frameCount,
        'avgFps': double.parse(avgFps.toStringAsFixed(1)),
        'avgFrameTime_ms': frameTimeStats.isNotEmpty
            ? double.parse(frameTimeStats['avg'].toStringAsFixed(2))
            : 0.0,
        'maxFrameTime_ms': frameTimeStats.isNotEmpty
            ? double.parse(frameTimeStats['max'].toStringAsFixed(2))
            : 0.0,
        'jankPercentage': frameTimeStats.isNotEmpty
            ? double.parse(frameTimeStats['jankPercentage'].toStringAsFixed(1))
            : 0.0,
        'dragElementCount': _dragStateManager?.draggingElementIds.length ?? 0,
      },
    );

    // 重置状态
    _dragStartTime = null;

    return report;
  }

  /// 获取拖拽性能数据
  Map<String, dynamic>? getDragPerformanceData() {
    if (_dragStateManager == null || !_dragStateManager!.isDragging) {
      return null;
    }

    return _dragStateManager!.getPerformanceReport();
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final Map<String, dynamic> summary = {
      'currentFPS': _currentFPS,
      'averageFrameTime': '${_averageFrameTime.inMilliseconds}ms',
      'maxFrameTime': '${_maxFrameTime.inMilliseconds}ms',
      'slowFrameCount': _slowFrameCount,
      'totalRebuilds': _totalRebuilds,
      'topRebuildWidgets': _getTopRebuildWidgets(),
    };

    // 添加拖拽性能数据（如果可用）
    final dragData = getDragPerformanceData();
    if (dragData != null) {
      summary['dragPerformance'] = dragData;
    }

    return summary;
  }

  /// Print detailed performance report
  void printPerformanceReport() {
    final Map<String, dynamic> reportData = {
      'currentFPS': double.parse(_currentFPS.toStringAsFixed(1)),
      'avgFrameTime_ms': _averageFrameTime.inMilliseconds,
      'maxFrameTime_ms': _maxFrameTime.inMilliseconds,
      'slowFrameCount': _slowFrameCount,
      'totalRebuilds': _totalRebuilds,
    };

    if (_widgetRebuildCounts.isNotEmpty) {
      final top = _getTopRebuildWidgets();
      reportData['topRebuildWidgets'] =
          top.map((w) => '${w['widget']}: ${w['rebuilds']} rebuilds').toList();
    }

    if (_fpsHistory.isNotEmpty) {
      final avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      reportData['historicalAvgFPS'] = double.parse(avgFPS.toStringAsFixed(1));
      reportData['historyLength'] = _fpsHistory.length;
    }

    EditPageLogger.performanceInfo(
      '详细性能报告',
      data: reportData,
    );

    // 检查并报告性能阈值违规
    _checkPerformanceThresholds();
  }

  /// 检查性能阈值
  void _checkPerformanceThresholds() {
    final now = DateTime.now();

    // 每5秒检查一次阈值
    if (now.difference(_lastThresholdCheck).inSeconds < 5) {
      return;
    }

    _lastThresholdCheck = now;
    bool hasViolation = false;

    // 检查帧率阈值
    if (_currentFPS < _fpsThresholdLow) {
      hasViolation = true;
      EditPageLogger.performanceWarning(
        '帧率严重低于阈值',
        data: {
          'currentFPS': _currentFPS,
          'threshold': _fpsThresholdLow,
          'severity': 'critical',
          'suggestion': '建议减少画布元素数量或启用性能优化模式',
        },
      );
    } else if (_currentFPS < _fpsThresholdMedium) {
      hasViolation = true;
      EditPageLogger.performanceWarning(
        '帧率低于正常阈值',
        data: {
          'currentFPS': _currentFPS,
          'threshold': _fpsThresholdMedium,
          'severity': 'moderate',
          'suggestion': '建议优化渲染性能',
        },
      );
    }

    // 检查帧时间阈值
    if (_maxFrameTime.inMilliseconds > _frameTimeThresholdMs) {
      hasViolation = true;
      EditPageLogger.performanceWarning(
        '检测到卡顿帧',
        data: {
          'maxFrameTime_ms': _maxFrameTime.inMilliseconds,
          'threshold_ms': _frameTimeThresholdMs,
          'slowFrameCount': _slowFrameCount,
          'severity': 'moderate',
          'suggestion': '存在界面卡顿，建议检查渲染逻辑',
        },
      );
    }

    // 🚀 优化：提高重建频率检查阈值，减少警告噪音
    if (_totalRebuilds > 0) {
      final secondsSinceStart = now.difference(_lastFrameTime).inSeconds;
      if (secondsSinceStart > 0) {
        final rebuildsPerSecond = _totalRebuilds / secondsSinceStart;
        if (rebuildsPerSecond > (_rebuildThresholdPerSecond * 2)) {
          // 阈值加倍
          hasViolation = true;
          EditPageLogger.performanceWarning(
            '组件重建频率过高',
            data: {
              'rebuildsPerSecond': rebuildsPerSecond.toStringAsFixed(1),
              'threshold': _rebuildThresholdPerSecond * 2,
              'severity': 'high',
              'suggestion': '建议优化状态管理以减少不必要的重建',
            },
          );
        }
      }
    }

    if (hasViolation) {
      _thresholdViolationCount++;
      EditPageLogger.performanceInfo(
        '性能阈值违规统计',
        data: {
          'violationCount': _thresholdViolationCount,
          'checkTime': now.toIso8601String(),
        },
      );
    }
  }

  /// 获取性能阈值状态
  Map<String, dynamic> getThresholdStatus() {
    return {
      'fpsStatus': _getFpsStatus(),
      'frameTimeStatus': _getFrameTimeStatus(),
      'rebuildStatus': _getRebuildStatus(),
      'violationCount': _thresholdViolationCount,
      'lastCheckTime': _lastThresholdCheck.toIso8601String(),
    };
  }

  String _getFpsStatus() {
    if (_currentFPS >= _fpsThresholdHigh) return 'excellent';
    if (_currentFPS >= _fpsThresholdMedium) return 'good';
    if (_currentFPS >= _fpsThresholdLow) return 'poor';
    return 'critical';
  }

  String _getFrameTimeStatus() {
    if (_maxFrameTime.inMilliseconds <= _frameTimeThresholdMs) return 'good';
    return 'poor';
  }

  String _getRebuildStatus() {
    final now = DateTime.now();
    final secondsSinceStart = now.difference(_lastFrameTime).inSeconds;
    if (secondsSinceStart > 0) {
      final rebuildsPerSecond = _totalRebuilds / secondsSinceStart;
      if (rebuildsPerSecond <= _rebuildThresholdPerSecond) return 'good';
    }
    return 'poor';
  }

  /// Reset all metrics
  void reset() {
    _frameCount = 0;
    _lastFrameTime = DateTime.now();
    _currentFPS = 0.0;
    _fpsHistory.clear();
    _frameTimeHistory.clear();
    _averageFrameTime = Duration.zero;
    _maxFrameTime = Duration.zero;
    _slowFrameCount = 0;
    _widgetRebuildCounts.clear();
    _totalRebuilds = 0;
    _memoryHistory.clear();

    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'reset_metrics',
      data: {
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// 设置拖拽状态管理器以便监控拖拽性能
  void setDragStateManager(DragStateManager dragStateManager) {
    _dragStateManager = dragStateManager;
  }

  /// Start monitoring mode with frame callbacks
  void startMonitoring() {
    SchedulerBinding.instance.addPostFrameCallback(_onFrameEnd);
  }

  /// 开始跟踪拖拽性能
  void startTrackingDragPerformance() {
    if (_dragStateManager == null || _dragStateManager!.isDragging) {
      return;
    }

    // 重置拖拽性能数据
    _dragStartFrameCount = _frameCount;
    _dragStartTime = DateTime.now();
    _dragFrameTimes.clear();
    _dragFpsValues.clear();

    EditPageLogger.performanceInfo(
      '开始跟踪拖拽性能',
      data: {
        'startTime': _dragStartTime?.toIso8601String(),
        'startFrameCount': _dragStartFrameCount,
        'currentFPS': _currentFPS,
      },
    );
  }

  /// Stop monitoring
  void stopMonitoring() {
    // Note: SchedulerBinding doesn't provide a direct way to remove callbacks
    // The callback will naturally stop when not rescheduled
  }

  /// 跟踪帧渲染性能
  void trackFrame() {
    final now = DateTime.now();

    // 计算自上次帧以来的时间
    final frameTime =
        now.difference(_lastFrameTime).inMicroseconds / 1000.0; // 转换为毫秒
    _frameTimeHistory.add(Duration(microseconds: frameTime.round() * 1000));

    // 限制历史记录长度
    if (_frameTimeHistory.length > 120) {
      // 保留最近两分钟的数据（假设60FPS）
      _frameTimeHistory.removeAt(0);
    }

    // 计算FPS
    if (frameTime > 0) {
      final fps = 1000.0 / frameTime;
      _currentFPS = fps;
      _fpsHistory.add(fps);

      // 限制历史记录长度
      if (_fpsHistory.length > _maxHistoryLength) {
        _fpsHistory.removeAt(0);
      }

      // 检测慢帧
      if (frameTime > 16.7) {
        // 60FPS对应16.7ms每帧
        _slowFrameCount++;
      }
    }

    // 计算平均帧时间
    if (_frameTimeHistory.isNotEmpty) {
      final totalMicros = _frameTimeHistory.fold<int>(
          0, (sum, duration) => sum + duration.inMicroseconds);
      _averageFrameTime =
          Duration(microseconds: totalMicros ~/ _frameTimeHistory.length);

      // 更新最大帧时间
      final maxMicros = _frameTimeHistory.fold<int>(
          0,
          (max, duration) =>
              duration.inMicroseconds > max ? duration.inMicroseconds : max);
      _maxFrameTime = Duration(microseconds: maxMicros);
    }

    // 如果正在拖拽，记录拖拽帧数据
    if (_dragStateManager != null && _dragStateManager!.isDragging) {
      _dragFrameTimes.add(frameTime);
      _dragFpsValues.add(_currentFPS);
    }

    _lastFrameTime = now;
    _frameCount++;

    // 🚀 每60帧（大约1秒）使用节流通知，避免过于频繁的更新
    if (_frameCount % 60 == 0) {
      _throttledNotifyListeners(
        operation: 'track_frame',
        data: {
          'frameCount': _frameCount,
          'frameTime_ms': frameTime,
          'isDragging': _dragStateManager?.isDragging ?? false,
        },
      );
    }
  }

  /// Track frame time for individual frames
  void trackFrameTime(Duration frameTime) {
    _frameTimeHistory.add(frameTime);
    if (_frameTimeHistory.length > 100) {
      _frameTimeHistory.removeAt(0);
    }

    // Calculate average
    if (_frameTimeHistory.isNotEmpty) {
      final total = _frameTimeHistory.fold<Duration>(
        Duration.zero,
        (prev, element) => prev + element,
      );
      _averageFrameTime = Duration(
        microseconds: total.inMicroseconds ~/ _frameTimeHistory.length,
      );
    }

    // Track max frame time
    if (frameTime > _maxFrameTime) {
      _maxFrameTime = frameTime;
    }

    // Count slow frames (> 16.67ms for 60FPS)
    if (frameTime.inMicroseconds > 16670) {
      _slowFrameCount++;
      EditPageLogger.performanceWarning(
        '检测到慢帧',
        data: {
          'frameTime_ms': frameTime.inMilliseconds,
          'slowFrameCount': _slowFrameCount,
          'currentFPS': _currentFPS,
        },
      );
    }
  }

  /// Track widget rebuilds
  void trackWidgetRebuild(String widgetName) {
    _widgetRebuildCounts[widgetName] =
        (_widgetRebuildCounts[widgetName] ?? 0) + 1;
    _totalRebuilds++;

    // 🚀 优化：只在关键阈值时记录过度重建警告
    final count = _widgetRebuildCounts[widgetName]!;
    if (count % 50 == 0 && count >= 50) {
      // 从10次提高到50次
      EditPageLogger.performanceWarning(
        '组件频繁重建警告',
        data: {
          'widgetName': widgetName,
          'rebuildCount': count,
          'severity': count > 200 ? 'high' : 'moderate',
        },
      );
    }
  }

  List<Map<String, dynamic>> _getTopRebuildWidgets() {
    final entries = _widgetRebuildCounts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(5)
        .map((e) => {
              'widget': e.key,
              'rebuilds': e.value,
            })
        .toList();
  }

  void _onFrameEnd(Duration timeStamp) {
    trackFrame();
    // Schedule next frame callback
    SchedulerBinding.instance.addPostFrameCallback(_onFrameEnd);
  }
}

/// Performance overlay widget for development
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

/// Widget wrapper that tracks rebuilds
class PerformanceTrackedWidget extends StatelessWidget {
  final Widget child;
  final String widgetName;
  final PerformanceMonitor? monitor;

  const PerformanceTrackedWidget({
    super.key,
    required this.child,
    required this.widgetName,
    this.monitor,
  });

  @override
  Widget build(BuildContext context) {
    // Track this rebuild
    (monitor ?? PerformanceMonitor()).trackWidgetRebuild(widgetName);
    return child;
  }
}

/// Mixin for tracking widget performance
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  PerformanceMonitor get performanceMonitor => PerformanceMonitor();

  @override
  Widget build(BuildContext context) {
    // Track frame rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      performanceMonitor.trackFrame();
    });

    // Track widget rebuild
    performanceMonitor.trackWidgetRebuild(widget.runtimeType.toString());

    return buildTracked(context);
  }

  /// Override this instead of build()
  Widget buildTracked(BuildContext context);
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  final PerformanceMonitor _monitor = PerformanceMonitor();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && kDebugMode)
          Positioned(
            top: 50,
            right: 16,
            child: _buildPerformanceDisplay(),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _monitor.removeListener(_onPerformanceUpdate);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _monitor.addListener(_onPerformanceUpdate);
  }

  Widget _buildPerformanceDisplay() {
    // Use the PerformanceDashboard widget which provides a complete
    // performance visualization UI
    return const PerformanceDashboard(
      // Use compact mode for the overlay to save screen space
      expanded: false,
      // Adjust the size to fit in the overlay
      width: 300,
      height: 200,
    );
  } // 根据帧率获取颜色

  void _onPerformanceUpdate() {
    if (mounted) setState(() {});
  }
}
