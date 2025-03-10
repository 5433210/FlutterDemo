import 'dart:math' as math;

import '../utils/alert_notifier.dart';

/// 自适应阈值配置
class AdaptiveConfig {
  final int historySize;
  final double baseMultiplier;
  final double noiseReduction;
  final Duration updateInterval;
  final bool useMedianFiltering;
  final AlertLevel warningLevel;
  final AlertLevel errorLevel;

  const AdaptiveConfig({
    this.historySize = 100,
    this.baseMultiplier = 2.0,
    this.noiseReduction = 0.1,
    this.updateInterval = const Duration(minutes: 1),
    this.useMedianFiltering = true,
    this.warningLevel = AlertLevel.warning,
    this.errorLevel = AlertLevel.error,
  });
}

/// 自适应阈值检测器
class AdaptiveThreshold {
  final AlertNotifier notifier;
  final AdaptiveConfig config;
  final _metricHistory = <String, List<double>>{};
  final _thresholds = <String, ThresholdState>{};
  final _medianBuffer = <String, List<double>>{};

  AdaptiveThreshold({
    required this.notifier,
    AdaptiveConfig? config,
  }) : config = config ?? const AdaptiveConfig();

  /// 添加度量值
  void addMetric(String metric, double value, [DateTime? timestamp]) {
    final ts = timestamp ?? DateTime.now();

    // 更新历史
    _metricHistory.putIfAbsent(metric, () => []).add(value);
    while (_metricHistory[metric]!.length > config.historySize) {
      _metricHistory[metric]!.removeAt(0);
    }

    // 更新中位数缓冲区
    if (config.useMedianFiltering) {
      _updateMedianBuffer(metric, value);
    }

    // 检查阈值
    _checkThresholds(metric, value, ts);
  }

  /// 获取所有阈值状态
  Map<String, ThresholdState> getAllThresholds() =>
      Map.unmodifiable(_thresholds);

  /// 获取当前阈值状态
  ThresholdState? getThresholdState(String metric) => _thresholds[metric];

  /// 重置所有数据
  void reset() {
    _metricHistory.clear();
    _thresholds.clear();
    _medianBuffer.clear();
  }

  /// 重置特定指标
  void resetMetric(String metric) {
    _metricHistory.remove(metric);
    _thresholds.remove(metric);
    _medianBuffer.remove(metric);
  }

  /// 计算基准值
  double _calculateBaseline(String metric) {
    final values = _metricHistory[metric]!;
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// 计算偏差
  double _calculateDeviation(String metric, double baseline) {
    final values = _metricHistory[metric]!;
    if (values.length < 2) return 0;

    final sumSquares = values.fold<double>(
      0,
      (sum, value) => sum + math.pow(value - baseline, 2),
    );

    return math.sqrt(sumSquares / (values.length - 1));
  }

  /// 计算噪声水平
  double _calculateNoiseLevel(String metric) {
    final values = _metricHistory[metric]!;
    if (values.length < 3) return 0;

    var changes = 0;
    for (var i = 1; i < values.length; i++) {
      if ((values[i] - values[i - 1]).abs() > config.noiseReduction) {
        changes++;
      }
    }

    return changes / (values.length - 1);
  }

  /// 检查阈值
  void _checkThresholds(String metric, double value, DateTime timestamp) {
    if (_metricHistory[metric]!.length < 10) return;

    final filteredValue = _getFilteredValue(metric, value);
    final baseline = _calculateBaseline(metric);
    final deviation = _calculateDeviation(metric, baseline);

    final upper = baseline + (deviation * config.baseMultiplier);
    final lower = baseline - (deviation * config.baseMultiplier);

    final state = ThresholdState(
      metric: metric,
      currentValue: filteredValue,
      baselineValue: baseline,
      upperThreshold: upper,
      lowerThreshold: lower,
      timestamp: timestamp,
      context: {
        'deviation': deviation,
        'noise_level': _calculateNoiseLevel(metric),
        'sample_size': _metricHistory[metric]!.length,
      },
    );

    _thresholds[metric] = state;

    // 检查违规
    if (filteredValue > upper || filteredValue < lower) {
      final level = _determineAlertLevel(filteredValue, baseline, deviation);
      notifier.notify(AlertBuilder()
          .message('检测到阈值违规: $metric')
          .level(level)
          .addData('value', filteredValue)
          .addData('baseline', baseline)
          .addData('threshold', filteredValue > upper ? upper : lower)
          .addData('deviation', deviation)
          .build());
    }
  }

  /// 确定告警级别
  AlertLevel _determineAlertLevel(
    double value,
    double baseline,
    double deviation,
  ) {
    final normalizedDiff = (value - baseline).abs() / deviation;

    if (normalizedDiff > 3 * config.baseMultiplier) {
      return config.errorLevel;
    }
    return config.warningLevel;
  }

  /// 获取滤波值
  double _getFilteredValue(String metric, double value) {
    if (!config.useMedianFiltering) return value;

    final buffer = _medianBuffer[metric];
    if (buffer == null || buffer.isEmpty) return value;

    final sorted = List<double>.from(buffer)..sort();
    return sorted[sorted.length ~/ 2];
  }

  /// 更新中位数缓冲区
  void _updateMedianBuffer(String metric, double value) {
    final buffer = _medianBuffer.putIfAbsent(metric, () => []);
    buffer.add(value);
    if (buffer.length > 5) buffer.removeAt(0);
  }
}

/// 阈值状态
class ThresholdState {
  final String metric;
  final double currentValue;
  final double baselineValue;
  final double upperThreshold;
  final double lowerThreshold;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  const ThresholdState({
    required this.metric,
    required this.currentValue,
    required this.baselineValue,
    required this.upperThreshold,
    required this.lowerThreshold,
    required this.timestamp,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'current_value': currentValue,
        'baseline_value': baselineValue,
        'upper_threshold': upperThreshold,
        'lower_threshold': lowerThreshold,
        'timestamp': timestamp.toIso8601String(),
        'context': context,
      };
}
