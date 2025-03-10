import 'dart:collection';
import 'dart:math' as math;

/// 监控指标
class Metric {
  final String name;
  final String? unit;
  final String? description;
  final bool isUpperBound;

  const Metric({
    required this.name,
    this.unit,
    this.description,
    this.isUpperBound = true,
  });
}

/// 监控分析器
class MonitorAnalyzer {
  final MonitorConfig config;
  final _metrics = <String, SplayTreeMap<DateTime, double>>{};
  final _thresholds = <String, ThresholdConfig>{};
  final _metricConfigs = <String, Metric>{};

  MonitorAnalyzer({
    MonitorConfig? config,
  }) : config = config ?? const MonitorConfig();

  /// 添加监控数据点
  void addDataPoint(String metric, double value, [DateTime? timestamp]) {
    final ts = timestamp ?? DateTime.now();
    final points = _metrics.putIfAbsent(
      metric,
      () => SplayTreeMap<DateTime, double>(),
    );

    points[ts] = value;

    // 清理旧数据
    while (points.length > config.maxHistorySize) {
      points.remove(points.firstKey());
    }

    final cutoff = DateTime.now().subtract(config.windowSize);
    points.removeWhere((ts, _) => ts.isBefore(cutoff));
  }

  /// 分析趋势
  TrendAnalysis analyzeTrend(String metric) {
    final points = _metrics[metric];
    if (points == null || points.length < 2) {
      return const TrendAnalysis(
        slope: 0,
        correlation: 0,
        confidence: 0,
      );
    }

    final values = points.values.toList();
    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;

    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;

    var xxSum = 0.0;
    var xySum = 0.0;
    var yySum = 0.0;

    for (var i = 0; i < n; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;
      xxSum += xDiff * xDiff;
      xySum += xDiff * yDiff;
      yySum += yDiff * yDiff;
    }

    final slope = xySum / xxSum;
    final correlation = xySum / math.sqrt(xxSum * yySum);
    final confidence = _calculateConfidence(correlation, n);

    return TrendAnalysis(
      slope: slope,
      correlation: correlation,
      confidence: confidence,
      context: {
        'sample_size': n,
        'time_span': points.lastKey()!.difference(points.firstKey()!).inSeconds,
        'value_range': {
          'min': values.reduce(math.min),
          'max': values.reduce(math.max),
        },
      },
    );
  }

  /// 计算统计信息
  Map<String, double> calculateStats(String metric) {
    final points = _metrics[metric];
    if (points == null || points.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'avg': 0.0,
        'std': 0.0,
        'median': 0.0,
      };
    }

    final values = points.values.toList();
    values.sort();

    final min = values.first;
    final max = values.last;
    final sum = values.reduce((a, b) => a + b);
    final avg = sum / values.length;
    final median = values.length.isOdd
        ? values[values.length ~/ 2]
        : (values[values.length ~/ 2 - 1] + values[values.length ~/ 2]) / 2;

    var sumSquaredDiff = 0.0;
    for (final value in values) {
      final diff = value - avg;
      sumSquaredDiff += diff * diff;
    }
    final std = math.sqrt(sumSquaredDiff / values.length);

    return {
      'min': min,
      'max': max,
      'avg': avg,
      'std': std,
      'median': median,
    };
  }

  /// 检查阈值
  List<ThresholdCheck> checkThresholds([String? metric]) {
    final results = <ThresholdCheck>[];
    final metrics = metric != null ? [metric] : _metrics.keys;

    for (final m in metrics) {
      final value = getLastValue(m);
      final config = _thresholds[m];
      if (value == null || config == null) continue;

      final now = DateTime.now();

      if (config.isUpperBound) {
        if (value >= config.error) {
          results.add(ThresholdCheck(
            metric: m,
            value: value,
            threshold: config.error,
            exceeded: true,
            timestamp: now,
            level: 'error',
          ));
        } else if (value >= config.warning) {
          results.add(ThresholdCheck(
            metric: m,
            value: value,
            threshold: config.warning,
            exceeded: true,
            timestamp: now,
            level: 'warning',
          ));
        }
      } else {
        if (value <= config.error) {
          results.add(ThresholdCheck(
            metric: m,
            value: value,
            threshold: config.error,
            exceeded: true,
            timestamp: now,
            level: 'error',
          ));
        } else if (value <= config.warning) {
          results.add(ThresholdCheck(
            metric: m,
            value: value,
            threshold: config.warning,
            exceeded: true,
            timestamp: now,
            level: 'warning',
          ));
        }
      }
    }

    return results;
  }

  /// 清除所有数据
  void clearAll() {
    _metrics.clear();
    _thresholds.clear();
    _metricConfigs.clear();
  }

  /// 清除指定指标的数据
  void clearMetric(String metric) {
    _metrics.remove(metric);
    _thresholds.remove(metric);
    _metricConfigs.remove(metric);
  }

  /// 设置指标定义
  void defineMetric(Metric metric) {
    _metricConfigs[metric.name] = metric;
  }

  /// 生成报告
  Map<String, dynamic> generateReport([Set<String>? metrics]) {
    final targetMetrics = metrics ?? getMetrics();
    final report = <String, dynamic>{};

    for (final metric in targetMetrics) {
      final points = _metrics[metric];
      if (points == null || points.isEmpty) continue;

      final stats = calculateStats(metric);
      final result = {
        'current': points.values.last,
        ...stats,
        'count': points.length,
        'first_ts': points.firstKey()!.toIso8601String(),
        'last_ts': points.lastKey()!.toIso8601String(),
      };

      if (config.enableTrending) {
        result['trend'] = analyzeTrend(metric).toJson();
      }

      final threshold = _thresholds[metric];
      if (threshold != null) {
        result['thresholds'] = {
          'warning': threshold.warning,
          'error': threshold.error,
          'is_upper_bound': threshold.isUpperBound,
        };
      }

      report[metric] = result;
    }

    return report;
  }

  /// 获取最新的值
  double? getLastValue(String metric) {
    final points = _metrics[metric];
    if (points == null || points.isEmpty) return null;
    return points.values.last;
  }

  /// 获取指定时间范围的数据
  List<MapEntry<DateTime, double>> getMetricHistory(
    String metric, {
    DateTime? start,
    DateTime? end,
  }) {
    final points = _metrics[metric];
    if (points == null) return [];

    var entries = points.entries.toList();
    if (start != null) {
      entries = entries.where((e) => e.key.isAfter(start)).toList();
    }
    if (end != null) {
      entries = entries.where((e) => e.key.isBefore(end)).toList();
    }

    return entries;
  }

  /// 获取所有已定义的指标
  Set<String> getMetrics() => Set.unmodifiable(_metricConfigs.keys);

  /// 获取所有阈值配置
  Map<String, ThresholdConfig> getThresholds() => Map.unmodifiable(_thresholds);

  /// 设置阈值
  void setThreshold(
    String metric, {
    required double warning,
    required double error,
    bool? isUpperBound,
    Duration? interval,
  }) {
    _thresholds[metric] = ThresholdConfig(
      warning: warning,
      error: error,
      isUpperBound:
          isUpperBound ?? _metricConfigs[metric]?.isUpperBound ?? true,
      interval: interval,
    );
  }

  /// 计算置信度
  double _calculateConfidence(double correlation, int sampleSize) {
    final t = correlation *
        math.sqrt((sampleSize - 2) / (1 - correlation * correlation));
    return 1 - _studentTDistribution(t.abs(), sampleSize - 2);
  }

  /// Student's t-distribution approximation
  double _studentTDistribution(double t, int df) {
    final x = df / (df + t * t);
    var result = 1.0;
    var term = 1.0;

    for (var i = 0; i < 10; i++) {
      term *= (2 * i + 1) * x / (2 * i + 2);
      result += term;
    }

    return 0.5 * (1 - result * math.sqrt(x));
  }
}

/// 监控配置
class MonitorConfig {
  final int maxHistorySize;
  final Duration windowSize;
  final Duration? checkInterval;
  final bool enableTrending;

  const MonitorConfig({
    this.maxHistorySize = 1000,
    this.windowSize = const Duration(hours: 24),
    this.checkInterval,
    this.enableTrending = true,
  });
}

/// 阈值检查结果
class ThresholdCheck {
  final String metric;
  final double value;
  final double threshold;
  final bool exceeded;
  final DateTime timestamp;
  final String level;

  const ThresholdCheck({
    required this.metric,
    required this.value,
    required this.threshold,
    required this.exceeded,
    required this.timestamp,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
        'metric': metric,
        'value': value,
        'threshold': threshold,
        'exceeded': exceeded,
        'timestamp': timestamp.toIso8601String(),
        'level': level,
      };
}

/// 阈值配置
class ThresholdConfig {
  final double warning;
  final double error;
  final bool isUpperBound;
  final Duration? interval;

  const ThresholdConfig({
    required this.warning,
    required this.error,
    this.isUpperBound = true,
    this.interval,
  });
}

/// 趋势分析结果
class TrendAnalysis {
  final double slope;
  final double correlation;
  final double confidence;
  final Map<String, dynamic> context;

  const TrendAnalysis({
    required this.slope,
    required this.correlation,
    required this.confidence,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
        'slope': slope,
        'correlation': correlation,
        'confidence': confidence,
        'context': context,
      };
}
