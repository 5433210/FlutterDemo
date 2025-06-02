// filepath: lib/canvas/monitoring/performance_monitor.dart

/// 性能监控器 - 跟踪重构过程中的性能指标
class CanvasPerformanceMonitor {
  static final CanvasPerformanceMonitor _instance =
      CanvasPerformanceMonitor._internal();
  final Map<String, List<Duration>> _renderTimes = {};
  final Map<String, int> _frameDrops = {};

  int _totalFrames = 0;
  bool _isMonitoring = false;
  DateTime? _frameStartTime;

  factory CanvasPerformanceMonitor() => _instance;
  CanvasPerformanceMonitor._internal();

  /// 检查性能是否满足基准要求
  bool checkPerformanceBenchmark() {
    // 基准：平均渲染时间不超过16.67ms（60fps）
    const maxRenderTime = Duration(microseconds: 16670);
    for (final operation in _renderTimes.keys) {
      final avgTime = getAverageRenderTime(operation);
      if (avgTime != null && avgTime > maxRenderTime) {
        // TODO: 实际项目中应该使用日志框架记录性能警告
        // print(
        //     'Performance warning: $operation average time ${avgTime.inMicroseconds}μs exceeds benchmark');
        return false;
      }
    }

    return true;
  }

  /// 停止监控
  void dispose() {
    _isMonitoring = false;
    _frameStartTime = null;
  }

  /// 结束帧渲染
  void endFrame() {
    if (!_isMonitoring || _frameStartTime == null) return;

    final duration = DateTime.now().difference(_frameStartTime!);
    recordRenderTime('frame', duration);
    incrementFrameCount();
    _frameStartTime = null;
  }

  /// 获取平均渲染时间
  Duration? getAverageRenderTime(String operation) {
    final times = _renderTimes[operation];
    if (times == null || times.isEmpty) return null;

    final totalMicroseconds = times.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );

    return Duration(microseconds: totalMicroseconds ~/ times.length);
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    final report = <String, dynamic>{
      'totalFrames': _totalFrames,
      'frameDrops': Map.from(_frameDrops),
      'averageRenderTimes': <String, int>{},
    };

    for (final entry in _renderTimes.entries) {
      final avgTime = getAverageRenderTime(entry.key);
      if (avgTime != null) {
        report['averageRenderTimes'][entry.key] = avgTime.inMicroseconds;
      }
    }

    return report;
  }

  /// 增加总帧数
  void incrementFrameCount() {
    _totalFrames++;
  }

  /// 记录掉帧
  void recordFrameDrop(String reason) {
    _frameDrops[reason] = (_frameDrops[reason] ?? 0) + 1;
  }

  /// 记录渲染时间
  void recordRenderTime(String operation, Duration duration) {
    _renderTimes.putIfAbsent(operation, () => []).add(duration);

    // 保持最近100次记录
    final times = _renderTimes[operation]!;
    if (times.length > 100) {
      times.removeAt(0);
    }
  }

  /// 清除所有数据
  void reset() {
    _renderTimes.clear();
    _frameDrops.clear();
    _totalFrames = 0;
  }

  /// 开始帧渲染
  void startFrame() {
    if (!_isMonitoring) return;
    _frameStartTime = DateTime.now();
  }

  /// 开始监控
  void startMonitoring() {
    _isMonitoring = true;
  }
}
