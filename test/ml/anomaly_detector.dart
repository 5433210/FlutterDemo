import 'dart:math' as math;

import '../utils/alert_notifier.dart';

/// 异常检测配置
class AnomalyConfig {
  final double threshold;
  final int windowSize;
  final double sensitivity;
  final bool useAdaptiveThreshold;
  final Duration analysisInterval;
  final AlertLevel alertLevel;

  const AnomalyConfig({
    this.threshold = 2.0,
    this.windowSize = 100,
    this.sensitivity = 1.0,
    this.useAdaptiveThreshold = true,
    this.analysisInterval = const Duration(minutes: 1),
    this.alertLevel = AlertLevel.warning,
  });
}

/// 异常检测器
class AnomalyDetector {
  final AlertNotifier notifier;
  final AnomalyConfig config;
  final _dataPoints = <TimeSeriesPoint>[];
  final _anomalies = <TimeSeriesPoint>[];
  double? _baselineValue;
  double? _adaptiveThreshold;

  AnomalyDetector({
    required this.notifier,
    AnomalyConfig? config,
  }) : config = config ?? const AnomalyConfig();

  /// 添加数据点
  void addPoint(DateTime timestamp, double value) {
    _dataPoints.add(TimeSeriesPoint(timestamp, value));

    // 保持窗口大小
    while (_dataPoints.length > config.windowSize) {
      _dataPoints.removeAt(0);
    }

    // 分析新点
    _analyzePoint(_dataPoints.last);
  }

  /// 获取检测到的异常
  List<TimeSeriesPoint> getAnomalies() => List.unmodifiable(_anomalies);

  /// 获取当前趋势
  Map<String, dynamic> getTrend() {
    if (_dataPoints.length < 2) {
      return {'trend': 'insufficient_data'};
    }

    final slope = _linearRegression(_dataPoints);
    final trend = slope.abs() < 0.001
        ? 'stable'
        : slope > 0
            ? 'increasing'
            : 'decreasing';

    return {
      'trend': trend,
      'slope': slope,
      'confidence': _calculateConfidence(),
    };
  }

  /// 重置检测器
  void reset() {
    _dataPoints.clear();
    _anomalies.clear();
    _baselineValue = null;
    _adaptiveThreshold = null;
  }

  /// 分析数据点
  void _analyzePoint(TimeSeriesPoint point) {
    if (_dataPoints.length < 3) return;

    // 计算基线值
    _updateBaseline();

    // 计算阈值
    final threshold = config.useAdaptiveThreshold
        ? _adaptiveThreshold ?? config.threshold
        : config.threshold;

    // 计算Z分数
    final zScore = _calculateZScore(point.value);

    // 检测异常
    if (zScore.abs() > threshold * config.sensitivity) {
      _anomalies.add(point);
      notifier.notify(AlertBuilder()
          .message('检测到异常值')
          .level(config.alertLevel)
          .addData('value', point.value)
          .addData('z_score', zScore)
          .addData('threshold', threshold)
          .addData('baseline', _baselineValue)
          .build());
    }
  }

  /// 计算置信度
  double _calculateConfidence() {
    if (_dataPoints.length < 5) return 0;

    final values = _dataPoints.map((p) => p.value).toList();
    final mean = _calculateMean(values);
    final stdDev = _calculateStdDev(values, mean);

    // 使用变异系数的倒数作为置信度指标
    if (mean == 0 || stdDev == 0) return 0;
    return math.min(1.0, 1.0 / (stdDev / mean.abs()));
  }

  /// 计算均值
  double _calculateMean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// 计算标准差
  double _calculateStdDev(List<double> values, double mean) {
    if (values.length < 2) return 0;

    final squaredDiffs = values.map((v) => math.pow(v - mean, 2));
    return math
        .sqrt(squaredDiffs.reduce((a, b) => a + b) / (values.length - 1));
  }

  /// 计算Z分数
  double _calculateZScore(double value) {
    if (_baselineValue == null || _dataPoints.length < 2) return 0;

    final stdDev = _calculateStdDev(
      _dataPoints.map((p) => p.value).toList(),
      _baselineValue!,
    );

    if (stdDev == 0) return 0;
    return (value - _baselineValue!) / stdDev;
  }

  /// 执行线性回归
  double _linearRegression(List<TimeSeriesPoint> points) {
    if (points.length < 2) return 0;

    // 将时间转换为相对秒数
    final baseTime = points.first.timestamp.millisecondsSinceEpoch / 1000;
    final x = points
        .map((p) => p.timestamp.millisecondsSinceEpoch / 1000 - baseTime)
        .toList();
    final y = points.map((p) => p.value).toList();

    final n = points.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((x) => x * x).reduce((a, b) => a + b);

    // 计算斜率
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    return slope;
  }

  /// 更新基线值
  void _updateBaseline() {
    final values = _dataPoints.map((p) => p.value).toList();
    _baselineValue = _calculateMean(values);

    if (config.useAdaptiveThreshold) {
      final stdDev = _calculateStdDev(values, _baselineValue!);
      _adaptiveThreshold = stdDev * 2; // 使用2倍标准差作为自适应阈值
    }
  }
}

/// 时间序列点
class TimeSeriesPoint {
  final DateTime timestamp;
  final double value;

  const TimeSeriesPoint(this.timestamp, this.value);
}
