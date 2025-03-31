import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 性能指标数据
class PerformanceMetric {
  final double value;
  final String label;
  final double threshold;
  final DateTime timestamp;

  PerformanceMetric({
    required this.value,
    required this.label,
    required this.threshold,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isOverThreshold => value > threshold;
}

/// 性能监控显示组件
class PerformanceMonitorWidget extends StatelessWidget {
  final PrototypePerformanceMonitor monitor;
  final bool showDetails;

  const PerformanceMonitorWidget({
    Key? key,
    required this.monitor,
    this.showDetails = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: monitor,
      builder: (context, _) {
        final snapshot = monitor.snapshot;
        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricRow(
                'FPS',
                snapshot.averageFrameTime > 0
                    ? (1000 / snapshot.averageFrameTime).round()
                    : 0,
                suffix: 'fps',
                isWarning: snapshot.averageFrameTime > 16.0,
              ),
              if (showDetails) ...[
                _buildMetricRow(
                  'Frame Time',
                  snapshot.averageFrameTime,
                  suffix: 'ms',
                  isWarning: snapshot.averageFrameTime > 16.0,
                ),
                _buildMetricRow(
                  'Memory',
                  snapshot.averageMemoryUsage,
                  suffix: 'MB',
                  isWarning: snapshot.averageMemoryUsage > 200.0,
                ),
                _buildMetricRow(
                  'Latency',
                  snapshot.averageLatency,
                  suffix: 'ms',
                  isWarning: snapshot.averageLatency > 30.0,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricRow(String label, num value,
      {String? suffix, bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.0,
            ),
          ),
          Text(
            value.toStringAsFixed(1) + (suffix ?? ''),
            style: TextStyle(
              color: isWarning ? Colors.red : Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 性能数据快照
class PerformanceSnapshot {
  final double averageFrameTime;
  final double maxFrameTime;
  final double averageMemoryUsage;
  final double averageLatency;
  final int frameTimeOverThresholdCount;
  final int memoryOverThresholdCount;
  final int latencyOverThresholdCount;

  PerformanceSnapshot({
    required this.averageFrameTime,
    required this.maxFrameTime,
    required this.averageMemoryUsage,
    required this.averageLatency,
    required this.frameTimeOverThresholdCount,
    required this.memoryOverThresholdCount,
    required this.latencyOverThresholdCount,
  });

  Map<String, dynamic> toJson() => {
        'averageFrameTime': averageFrameTime,
        'maxFrameTime': maxFrameTime,
        'averageMemoryUsage': averageMemoryUsage,
        'averageLatency': averageLatency,
        'frameTimeOverThresholdCount': frameTimeOverThresholdCount,
        'memoryOverThresholdCount': memoryOverThresholdCount,
        'latencyOverThresholdCount': latencyOverThresholdCount,
      };
}

/// 性能监控器 - 原型验证版本
class PrototypePerformanceMonitor extends ChangeNotifier {
  /// 性能数据
  final _PerformanceData _data = _PerformanceData();

  /// 是否处于活跃状态
  bool _isActive = false;
  bool get isActive => _isActive;

  /// 获取性能数据快照
  PerformanceSnapshot get snapshot => _data.snapshot;

  /// 清除数据
  void clearData() {
    _data.clear();
    notifyListeners();
  }

  /// 获取性能报告
  Map<String, dynamic> getReport() => _data.generateReport();

  /// 记录帧时间
  void recordFrameTime(double milliseconds) {
    if (!_isActive) return;

    // 使用post-frame回调延迟更新
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _data.addFrameTime(milliseconds);
      if (milliseconds > _PerformanceData.frameTimeThreshold) {
        print('⚠️ 帧时间过长: ${milliseconds.toStringAsFixed(2)}ms');
      }
      notifyListeners();
    });
  }

  /// 记录内存使用
  void recordMemoryUsage(double megabytes) {
    if (!_isActive) return;

    // 使用post-frame回调延迟更新
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _data.addMemoryUsage(megabytes);
      if (megabytes > _PerformanceData.memoryThreshold) {
        print('⚠️ 内存使用过高: ${megabytes.toStringAsFixed(2)}MB');
      }
      notifyListeners();
    });
  }

  /// 记录操作延迟
  void recordOperationLatency(double milliseconds) {
    if (!_isActive) return;

    // 使用post-frame回调延迟更新
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _data.addOperationLatency(milliseconds);
      if (milliseconds > _PerformanceData.latencyThreshold) {
        print('⚠️ 操作延迟过高: ${milliseconds.toStringAsFixed(2)}ms');
      }
      notifyListeners();
    });
  }

  /// 启动监控
  void start() {
    if (_isActive) return;
    _isActive = true;
    _data.clear();
    notifyListeners();
    print('📊 性能监控已启动');
  }

  /// 停止监控
  void stop() {
    if (!_isActive) return;
    _isActive = false;
    notifyListeners();
    print('📊 性能监控已停止');
  }
}

/// 性能数据容器
class _PerformanceData {
  static const int maxRecords = 120; // 保存2分钟的数据（以60fps计）
  static const double frameTimeThreshold = 16.0; // ms
  static const double memoryThreshold = 200.0; // MB
  static const double latencyThreshold = 30.0; // ms

  final Queue<PerformanceMetric> _frameTimes = Queue<PerformanceMetric>();
  final Queue<PerformanceMetric> _memoryUsages = Queue<PerformanceMetric>();
  final Queue<PerformanceMetric> _operationLatencies =
      Queue<PerformanceMetric>();

  PerformanceSnapshot get snapshot => PerformanceSnapshot(
        averageFrameTime: _calculateAverage(_frameTimes),
        maxFrameTime: _calculateMax(_frameTimes),
        averageMemoryUsage: _calculateAverage(_memoryUsages),
        averageLatency: _calculateAverage(_operationLatencies),
        frameTimeOverThresholdCount: _countOverThreshold(_frameTimes),
        memoryOverThresholdCount: _countOverThreshold(_memoryUsages),
        latencyOverThresholdCount: _countOverThreshold(_operationLatencies),
      );

  void addFrameTime(double value) => _addMetric(
        _frameTimes,
        value,
        'Frame Time',
        frameTimeThreshold,
      );

  void addMemoryUsage(double value) => _addMetric(
        _memoryUsages,
        value,
        'Memory Usage',
        memoryThreshold,
      );

  void addOperationLatency(double value) => _addMetric(
        _operationLatencies,
        value,
        'Operation Latency',
        latencyThreshold,
      );

  void clear() {
    _frameTimes.clear();
    _memoryUsages.clear();
    _operationLatencies.clear();
  }

  Map<String, dynamic> generateReport() => {
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': snapshot.toJson(),
        'sampleCounts': {
          'frameTimes': _frameTimes.length,
          'memoryUsages': _memoryUsages.length,
          'operationLatencies': _operationLatencies.length,
        },
      };

  void _addMetric(Queue<PerformanceMetric> queue, double value, String label,
      double threshold) {
    queue.add(PerformanceMetric(
      value: value,
      label: label,
      threshold: threshold,
    ));
    while (queue.length > maxRecords) {
      queue.removeFirst();
    }
  }

  double _calculateAverage(Queue<PerformanceMetric> queue) {
    if (queue.isEmpty) return 0.0;
    final sum = queue.fold<double>(0.0, (sum, metric) => sum + metric.value);
    return sum / queue.length;
  }

  double _calculateMax(Queue<PerformanceMetric> queue) {
    if (queue.isEmpty) return 0.0;
    return queue.fold<double>(
        0.0, (max, metric) => math.max(max, metric.value));
  }

  int _countOverThreshold(Queue<PerformanceMetric> queue) {
    return queue.where((metric) => metric.isOverThreshold).length;
  }
}
