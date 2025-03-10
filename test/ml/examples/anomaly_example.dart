import 'dart:math';

import '../../utils/monitor_analyzer.dart';

void main() async {
  // 创建监控分析器
  final analyzer = MonitorAnalyzer(
    config: const MonitorConfig(
      windowSize: Duration(hours: 24),
      enableTrending: true,
    ),
  );

  // 创建异常检测器
  final detector = AnomalyDetector(
    analyzer: analyzer,
    config: AnomalyConfig(
      zScoreThreshold: 2.5,
      seasonalityThreshold: 0.6,
      changePointThreshold: 0.8,
    ),
  );

  // 定义测试指标
  analyzer.defineMetric(const Metric(
    name: 'test_metric',
    unit: 'value',
    description: '测试指标',
  ));

  analyzer.setThreshold(
    'test_metric',
    warning: 150,
    error: 200,
  );

  // 生成测试数据
  final random = Random();
  final now = DateTime.now();

  // 基本模式：日周期 + 趋势 + 噪声
  for (var i = 0; i < 72; i++) {
    // 3天的数据
    final hour = i % 24;
    final baseValue = 100.0 // 基准值
        +
        30 * sin(hour * pi / 12) // 日周期
        +
        i * 0.5 // 上升趋势
        +
        random.nextDouble() * 10; // 随机噪声

    // 注入异常
    final value = i == 50
        ? baseValue * 2
        : // 突发峰值
        (i > 60 ? baseValue * 1.5 : baseValue); // 持续异常

    analyzer.addDataPoint(
      'test_metric',
      value,
      now.subtract(Duration(hours: 72 - i)),
    );
  }

  // 检测异常
  final anomalies = detector.detect('test_metric');

  // 打印结果
  print('\n检测到的异常:');
  print('=' * 50);
  for (final anomaly in anomalies) {
    print(anomaly);
    print('上下文: ${anomaly.context}');
    print('-' * 50);
  }

  // 分析结果
  print('\n异常统计:');
  final typeCount = <String, int>{};
  for (final anomaly in anomalies) {
    typeCount[anomaly.type] = (typeCount[anomaly.type] ?? 0) + 1;
  }

  typeCount.forEach((type, count) {
    print('$type: $count');
  });
}

/// 异常检测配置
class AnomalyConfig {
  final double zScoreThreshold;
  final Duration windowSize;
  final double seasonalityThreshold;
  final double changePointThreshold;

  AnomalyConfig({
    this.zScoreThreshold = 3.0,
    this.windowSize = const Duration(hours: 1),
    this.seasonalityThreshold = 0.7,
    this.changePointThreshold = 0.9,
  });
}

/// 异常检测器
class AnomalyDetector {
  final MonitorAnalyzer analyzer;
  final AnomalyConfig config;
  final _anomalies = <String, List<AnomalyResult>>{};

  AnomalyDetector({
    required this.analyzer,
    AnomalyConfig? config,
  }) : config = config ?? AnomalyConfig();

  /// 检测异常
  List<AnomalyResult> detect(String metric) {
    final results = <AnomalyResult>[];
    final history = analyzer.getMetricHistory(metric);
    if (history.isEmpty) return results;

    // Z-Score 检测
    results.addAll(_detectZScoreAnomalies(metric, history));

    // 趋势变化检测
    results.addAll(_detectTrendChangeAnomalies(metric));

    // 季节性异常检测
    results.addAll(_detectSeasonalAnomalies(metric, history));

    _anomalies[metric] = results;
    return results;
  }

  /// 获取指定指标的异常
  List<AnomalyResult> getAnomalies(String metric) =>
      List.unmodifiable(_anomalies[metric] ?? []);

  /// 分析日周期模式
  _SeasonalPattern _analyzeDailyPattern(
    List<MapEntry<DateTime, double>> history,
  ) {
    final hourlyBuckets = List<List<double>>.generate(24, (_) => []);

    // 按小时分组数据
    for (final point in history) {
      final hour = point.key.hour;
      hourlyBuckets[hour].add(point.value);
    }

    // 计算每小时的均值和标准差
    final hourlyStats = hourlyBuckets.map((values) {
      if (values.isEmpty) return _HourStats(mean: 0, std: 0);
      final mean = values.reduce((a, b) => a + b) / values.length;
      var sumSquaredDiff = 0.0;
      for (final v in values) {
        final diff = v - mean;
        sumSquaredDiff += diff * diff;
      }
      final std = sqrt(sumSquaredDiff / values.length);
      return _HourStats(mean: mean, std: std);
    }).toList();

    // 计算模式的置信度
    var totalVariance = 0.0;
    var explainedVariance = 0.0;
    final overallMean =
        hourlyStats.map((s) => s.mean).reduce((a, b) => a + b) / 24;

    for (var i = 0; i < 24; i++) {
      final stats = hourlyStats[i];
      final values = hourlyBuckets[i];
      if (values.isEmpty) continue;

      for (final value in values) {
        final totalDiff = value - overallMean;
        final explainedDiff = stats.mean - overallMean;
        totalVariance += totalDiff * totalDiff;
        explainedVariance += explainedDiff * explainedDiff;
      }
    }

    final confidence = explainedVariance / (totalVariance + 1e-10);
    final threshold =
        hourlyStats.map((s) => s.std).reduce((a, b) => a + b) / 24 * 3;

    return _SeasonalPattern(
      hourlyStats: hourlyStats,
      confidence: confidence,
      threshold: threshold,
    );
  }

  /// 季节性异常检测
  List<AnomalyResult> _detectSeasonalAnomalies(
    String metric,
    List<MapEntry<DateTime, double>> history,
  ) {
    final results = <AnomalyResult>[];
    if (history.length < 24) return results; // 需要足够的数据点

    // 检测日周期模式
    final dailyPattern = _analyzeDailyPattern(history);
    if (dailyPattern.confidence > config.seasonalityThreshold) {
      final lastPoint = history.last;
      final expectedValue = dailyPattern.predict(lastPoint.key);
      final deviation = (lastPoint.value - expectedValue).abs();

      if (deviation > dailyPattern.threshold) {
        results.add(AnomalyResult(
          metric: metric,
          timestamp: lastPoint.key,
          value: lastPoint.value,
          type: 'seasonal',
          score: deviation / dailyPattern.threshold,
          context: {
            'expected': expectedValue,
            'deviation': deviation,
            'pattern': 'daily',
            'confidence': dailyPattern.confidence,
          },
        ));
      }
    }

    return results;
  }

  /// 趋势变化检测
  List<AnomalyResult> _detectTrendChangeAnomalies(String metric) {
    final results = <AnomalyResult>[];
    final trend = analyzer.analyzeTrend(metric);

    if (trend.confidence > config.changePointThreshold) {
      final lastValue = analyzer.getLastValue(metric);
      if (lastValue != null) {
        results.add(AnomalyResult(
          metric: metric,
          timestamp: DateTime.now(),
          value: lastValue,
          type: 'trend_change',
          score: trend.confidence,
          context: {
            'slope': trend.slope,
            'correlation': trend.correlation,
            'confidence': trend.confidence,
          },
        ));
      }
    }

    return results;
  }

  /// 基于Z-Score的异常检测
  List<AnomalyResult> _detectZScoreAnomalies(
    String metric,
    List<MapEntry<DateTime, double>> history,
  ) {
    final results = <AnomalyResult>[];
    final stats = analyzer.calculateStats(metric);
    final mean = stats['avg'] ?? 0.0;
    final std = stats['std'] ?? 1.0;

    for (final point in history) {
      final zScore = (point.value - mean) / std;
      if (zScore.abs() > config.zScoreThreshold) {
        results.add(AnomalyResult(
          metric: metric,
          timestamp: point.key,
          value: point.value,
          type: 'z_score',
          score: zScore.abs(),
          context: {
            'z_score': zScore,
            'mean': mean,
            'std': std,
          },
        ));
      }
    }

    return results;
  }
}

/// 异常检测结果
class AnomalyResult {
  final String metric;
  final DateTime timestamp;
  final double value;
  final String type;
  final double score;
  final Map<String, dynamic> context;

  AnomalyResult({
    required this.metric,
    required this.timestamp,
    required this.value,
    required this.type,
    required this.score,
    this.context = const {},
  });

  @override
  String toString() =>
      'Anomaly($metric): $value at $timestamp (type: $type, score: ${score.toStringAsFixed(3)})';
}

/// 每小时统计
class _HourStats {
  final double mean;
  final double std;

  _HourStats({required this.mean, required this.std});
}

/// 季节性模式
class _SeasonalPattern {
  final List<_HourStats> hourlyStats;
  final double confidence;
  final double threshold;

  _SeasonalPattern({
    required this.hourlyStats,
    required this.confidence,
    required this.threshold,
  });

  /// 预测特定时间点的值
  double predict(DateTime time) {
    final hour = time.hour;
    return hourlyStats[hour].mean;
  }
}
