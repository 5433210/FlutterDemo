import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'drag_state_manager.dart';
import 'performance_dashboard.dart';

/// Performance monitoring utility for M3Canvas optimization tracking
class PerformanceMonitor extends ChangeNotifier {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
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

    debugPrint('📊 PerformanceMonitor: 拖拽性能报告生成');
    debugPrint('   持续时间: ${duration.inMilliseconds}ms');
    debugPrint('   总帧数: $frameCount');
    debugPrint('   平均帧率: ${avgFps.toStringAsFixed(1)} FPS');

    if (frameTimeStats.isNotEmpty) {
      debugPrint('   平均帧时间: ${frameTimeStats['avg'].toStringAsFixed(2)}ms');
      debugPrint('   最大帧时间: ${frameTimeStats['max'].toStringAsFixed(2)}ms');
      debugPrint(
          '   jank帧比例: ${frameTimeStats['jankPercentage'].toStringAsFixed(1)}%');
    }

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
    debugPrint('\n📊 ====== Performance Report ======');
    debugPrint('📈 Current FPS: ${_currentFPS.toStringAsFixed(1)}');
    debugPrint('⏱️ Average Frame Time: ${_averageFrameTime.inMilliseconds}ms');
    debugPrint('🐌 Max Frame Time: ${_maxFrameTime.inMilliseconds}ms');
    debugPrint('❌ Slow Frames: $_slowFrameCount');
    debugPrint('🔄 Total Rebuilds: $_totalRebuilds');

    if (_widgetRebuildCounts.isNotEmpty) {
      debugPrint('🏆 Top Rebuild Widgets:');
      final top = _getTopRebuildWidgets();
      for (final widget in top) {
        debugPrint('   ${widget['widget']}: ${widget['rebuilds']} rebuilds');
      }
    }

    if (_fpsHistory.isNotEmpty) {
      final avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      debugPrint(
          '📊 Average FPS (last ${_fpsHistory.length}s): ${avgFPS.toStringAsFixed(1)}');
    }

    debugPrint('================================\n');
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
    notifyListeners();
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

    debugPrint('🔍 PerformanceMonitor: 开始跟踪拖拽性能');
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

    // 每60帧（大约1秒）通知监听器一次，避免过于频繁的更新
    if (_frameCount % 60 == 0) {
      notifyListeners();
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
      debugPrint('🐌 Slow frame detected: ${frameTime.inMilliseconds}ms');
    }
  }

  /// Track widget rebuilds
  void trackWidgetRebuild(String widgetName) {
    _widgetRebuildCounts[widgetName] =
        (_widgetRebuildCounts[widgetName] ?? 0) + 1;
    _totalRebuilds++;

    // Log excessive rebuilds
    final count = _widgetRebuildCounts[widgetName]!;
    if (count % 10 == 0) {
      debugPrint('🔄 Widget $widgetName rebuilt $count times');
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

  // 构建拖拽性能信息
  Widget _buildDragPerformanceInfo() {
    final dragData = _monitor.getDragPerformanceData();
    if (dragData == null) {
      return const SizedBox.shrink();
    }

    final currentFps = dragData['currentFps'] as int;
    final avgFps = dragData['avgFps'] as double;
    final updateCount = dragData['updateCount'] as int;
    final batchUpdateCount = dragData['batchUpdateCount'] as int;
    final avgUpdateTime = dragData['avgUpdateTime'] as double;
    final elementCount = dragData['elementCount'] as int;
    final isPerformanceCritical = dragData['isPerformanceCritical'] as bool;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '拖拽帧率: ${currentFps.toString()} FPS',
          style: TextStyle(
            color: _getFPSColor(currentFps.toDouble()),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '平均帧率: ${avgFps.toStringAsFixed(1)} FPS',
          style: TextStyle(
            color: _getFPSColor(avgFps),
            fontSize: 10,
          ),
        ),
        Text(
          '更新次数: $updateCount (批量: $batchUpdateCount)',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          '平均更新时间: ${avgUpdateTime.toStringAsFixed(2)}ms',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        Text(
          '拖拽元素: $elementCount',
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
        if (isPerformanceCritical)
          const Text(
            '⚠️ 性能警告: 帧率过低',
            style: TextStyle(
                color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildFPSIndicator() {
    final fps = _monitor.currentFPS;
    final color = _getFPSColor(fps);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'FPS: ${fps.toStringAsFixed(1)}',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  } // Build the performance display using the PerformanceDashboard widget

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

  Color _getFPSColor(double fps) {
    if (fps >= 55) {
      return Colors.green;
    } else if (fps >= 30) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  void _onPerformanceUpdate() {
    if (mounted) setState(() {});
  }
}
