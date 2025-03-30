import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 擦除工具性能监控器
/// 用于收集和分析性能数据
class ErasePerformanceMonitor {
  /// 单例实例
  static final ErasePerformanceMonitor _instance =
      ErasePerformanceMonitor._internal();

  /// 是否正在监控
  bool _isMonitoring = false;

  /// 性能数据历史
  final ListQueue<PerformanceDataPoint> _dataPoints =
      ListQueue<PerformanceDataPoint>();

  /// 最大历史记录数
  final int maxDataPoints = 120; // 保存2分钟的数据 (假设60fps)

  /// 当前帧时间 (ms)
  double _currentFrameTime = 0;

  /// 当前帧率
  double _currentFps = 0;

  /// 上一帧时间戳
  Duration? _lastFrameTimestamp;

  /// 性能监听器
  final ValueNotifier<PerformanceDataPoint?> performanceNotifier =
      ValueNotifier(null);

  /// 工厂构造函数
  factory ErasePerformanceMonitor() => _instance;

  /// 内部构造函数
  ErasePerformanceMonitor._internal();

  /// 获取当前帧率
  double get currentFps => _currentFps;

  /// 获取当前帧时间
  double get currentFrameTime => _currentFrameTime;

  /// 获取所有性能数据点
  List<PerformanceDataPoint> get dataPoints => List.unmodifiable(_dataPoints);

  /// 是否正在监控
  bool get isMonitoring => _isMonitoring;

  /// 获取性能统计
  Map<String, double> getPerformanceStats() {
    if (_dataPoints.isEmpty) {
      return {
        'avgFrameTime': 0.0,
        'avgFps': 0.0,
        'minFps': 0.0,
        'maxFps': 0.0,
      };
    }

    double totalFrameTime = 0.0;
    double minFrameTime = double.infinity;
    double maxFrameTime = 0.0;

    for (final point in _dataPoints) {
      totalFrameTime += point.frameTime;
      minFrameTime = math.min(minFrameTime, point.frameTime);
      maxFrameTime = math.max(maxFrameTime, point.frameTime);
    }

    final avgFrameTime = totalFrameTime / _dataPoints.length;
    final avgFps = avgFrameTime > 0 ? 1000 / avgFrameTime : 0.0;
    final maxFps = minFrameTime > 0 ? 1000 / minFrameTime : 0.0;
    final minFps = maxFrameTime > 0 ? 1000 / maxFrameTime : 0.0;

    return {
      'avgFrameTime': avgFrameTime,
      'avgFps': avgFps,
      'minFps': minFps,
      'maxFps': maxFps,
    };
  }

  /// 开始监控
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _dataPoints.clear();
    _lastFrameTimestamp = null;

    SchedulerBinding.instance.addTimingsCallback(_handleTimings);
  }

  /// 停止监控
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _isMonitoring = false;
    SchedulerBinding.instance.removeTimingsCallback(_handleTimings);
  }

  /// 处理帧时间
  void _handleTimings(List<FrameTiming> timings) {
    if (!_isMonitoring || timings.isEmpty) return;

    for (final timing in timings) {
      final buildDuration =
          timing.buildDuration.inMicroseconds / 1000.0; // 转换为毫秒
      final rasterDuration =
          timing.rasterDuration.inMicroseconds / 1000.0; // 转换为毫秒

      // 总帧时间
      final totalFrameTime = buildDuration + rasterDuration;
      _currentFrameTime = totalFrameTime;

      // 计算帧率
      final now = timing.timestampInMicroseconds(FramePhase.rasterStart);
      if (_lastFrameTimestamp != null) {
        final frameDuration = now - _lastFrameTimestamp!.inMicroseconds;
        if (frameDuration > 0) {
          _currentFps = 1000000 / frameDuration; // 微秒转换为帧率
        }
      }
      _lastFrameTimestamp = Duration(microseconds: now);

      // 创建数据点
      final dataPoint = PerformanceDataPoint(
        timestamp: DateTime.now(),
        frameTime: totalFrameTime,
        // 这里可以添加其他性能指标
      );

      // 添加到历史记录
      _dataPoints.add(dataPoint);

      // 限制历史记录大小
      while (_dataPoints.length > maxDataPoints) {
        _dataPoints.removeFirst();
      }

      // 通知监听器
      performanceNotifier.value = dataPoint;
    }
  }
}

/// 性能数据点
class PerformanceDataPoint {
  /// 时间戳
  final DateTime timestamp;

  /// 帧时间 (ms)
  final double frameTime;

  /// CPU使用率 (%)，可选
  final double? cpuUsage;

  /// 内存使用 (MB)，可选
  final double? memoryUsage;

  PerformanceDataPoint({
    required this.timestamp,
    required this.frameTime,
    this.cpuUsage,
    this.memoryUsage,
  });
}
