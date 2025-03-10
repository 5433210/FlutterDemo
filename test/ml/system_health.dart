import 'dart:async';
import 'dart:math';

import '../utils/check_logger.dart';

/// 相关性分析结果
class CorrelationAnalysis {
  final String metric1;
  final String metric2;
  final CorrelationType type;
  final double coefficient;
  final double significance;
  final Map<String, dynamic> details;

  CorrelationAnalysis({
    required this.metric1,
    required this.metric2,
    required this.type,
    required this.coefficient,
    required this.significance,
    this.details = const {},
  });

  Map<String, dynamic> toJson() => {
        'metric1': metric1,
        'metric2': metric2,
        'type': type.toString(),
        'coefficient': coefficient,
        'significance': significance,
        'details': details,
      };
}

/// 指标关联类型
enum CorrelationType {
  positive, // 正相关
  negative, // 负相关
  nonlinear, // 非线性相关
  none, // 无相关
}

/// 健康度评估
class HealthAssessment {
  final DateTime timestamp;
  final double score;
  final HealthLevel level;
  final Map<String, double> metricScores;
  final List<String> issues;
  final Map<String, dynamic> metadata;

  HealthAssessment({
    required this.timestamp,
    required this.score,
    required this.level,
    required this.metricScores,
    this.issues = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'score': score,
        'level': level.toString(),
        'metricScores': metricScores,
        'issues': issues,
        'metadata': metadata,
      };
}

/// 健康度配置
class HealthConfig {
  final List<MetricWeight> weights;
  final Duration windowSize;
  final Duration updateInterval;
  final Map<String, double> thresholds;
  final bool autoAdjust;

  const HealthConfig({
    this.weights = const [],
    this.windowSize = const Duration(minutes: 30),
    this.updateInterval = const Duration(minutes: 1),
    this.thresholds = const {},
    this.autoAdjust = true,
  });
}

/// 健康度等级
enum HealthLevel {
  excellent, // 90-100
  good, // 75-89
  fair, // 60-74
  poor, // 40-59
  critical, // 0-39
}

/// 指标权重配置
class MetricWeight {
  final String metric;
  final double weight;
  final Map<String, CorrelationType> correlations;

  const MetricWeight({
    required this.metric,
    required this.weight,
    this.correlations = const {},
  });
}

/// 系统健康管理器
class SystemHealthManager {
  final CheckLogger logger;
  final HealthConfig config;
  final _metricData = <String, List<double>>{};
  final _timestamps = <String, List<DateTime>>{};
  final _assessments = <HealthAssessment>[];
  final _correlations = <CorrelationAnalysis>[];
  Timer? _updateTimer;

  SystemHealthManager({
    required this.config,
    CheckLogger? logger,
  }) : logger = logger ?? CheckLogger.instance {
    _startUpdateTimer();
  }

  /// 添加指标数据
  void addMetric(String metric, double value, {DateTime? timestamp}) {
    timestamp ??= DateTime.now();

    _metricData.putIfAbsent(metric, () => []).add(value);
    _timestamps.putIfAbsent(metric, () => []).add(timestamp);

    _cleanOldData();
  }

  /// 分析指标相关性
  List<CorrelationAnalysis> analyzeCorrelations() {
    _correlations.clear();
    final metrics = _metricData.keys.toList();

    for (var i = 0; i < metrics.length; i++) {
      for (var j = i + 1; j < metrics.length; j++) {
        final m1 = metrics[i];
        final m2 = metrics[j];

        final correlation = _calculateCorrelation(m1, m2);
        if (correlation != null) {
          _correlations.add(correlation);
        }
      }
    }

    return List.from(_correlations);
  }

  /// 计算当前健康度
  HealthAssessment calculateHealth() {
    var totalScore = 0.0;
    var totalWeight = 0.0;
    final metricScores = <String, double>{};
    final issues = <String>[];

    // 计算加权分数
    for (final weight in config.weights) {
      final values = _metricData[weight.metric];
      if (values == null || values.isEmpty) continue;

      final score = _calculateMetricScore(
        weight.metric,
        values.last,
      );

      metricScores[weight.metric] = score;
      totalScore += score * weight.weight;
      totalWeight += weight.weight;

      if (score < 60) {
        issues
            .add('${weight.metric} score is low: ${score.toStringAsFixed(2)}');
      }
    }

    // 归一化分数
    final normalizedScore = totalWeight > 0 ? totalScore / totalWeight : 0.0;

    // 确定健康等级
    final level = _determineHealthLevel(normalizedScore);

    return HealthAssessment(
      timestamp: DateTime.now(),
      score: normalizedScore,
      level: level,
      metricScores: metricScores,
      issues: issues,
      metadata: {
        'totalMetrics': metricScores.length,
        'dataPoints': _getTotalDataPoints(),
      },
    );
  }

  /// 释放资源
  void dispose() {
    _updateTimer?.cancel();
    _metricData.clear();
    _timestamps.clear();
    _assessments.clear();
    _correlations.clear();
  }

  /// 获取异常指标
  Map<String, List<String>> getAnomalousMetrics() {
    final anomalies = <String, List<String>>{};

    for (final entry in _metricData.entries) {
      final metric = entry.key;
      final values = entry.value;
      if (values.isEmpty) continue;

      final issues = <String>[];
      final threshold = config.thresholds[metric];

      if (threshold != null && values.last > threshold) {
        issues.add(
            'Above threshold: ${values.last.toStringAsFixed(2)} > $threshold');
      }

      if (issues.isNotEmpty) {
        anomalies[metric] = issues;
      }
    }

    return anomalies;
  }

  /// 获取健康度历史
  List<HealthAssessment> getHealthHistory({
    DateTime? start,
    DateTime? end,
  }) {
    return _assessments.where((a) {
      if (start != null && a.timestamp.isBefore(start)) return false;
      if (end != null && a.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// 计算相关性
  CorrelationAnalysis? _calculateCorrelation(
    String metric1,
    String metric2,
  ) {
    final values1 = _metricData[metric1];
    final values2 = _metricData[metric2];

    if (values1 == null || values2 == null) return null;
    if (values1.isEmpty || values2.isEmpty) return null;

    // 取共同时间窗口的数据
    final length = min(values1.length, values2.length);
    final x = values1.sublist(values1.length - length);
    final y = values2.sublist(values2.length - length);

    // 计算皮尔逊相关系数
    final xMean = x.reduce((a, b) => a + b) / length;
    final yMean = y.reduce((a, b) => a + b) / length;

    var numerator = 0.0;
    var denominator1 = 0.0;
    var denominator2 = 0.0;

    for (var i = 0; i < length; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;
      numerator += xDiff * yDiff;
      denominator1 += xDiff * xDiff;
      denominator2 += yDiff * yDiff;
    }

    final coefficient = numerator / sqrt(denominator1 * denominator2);

    // 确定相关类型
    final type = _determineCorrelationType(coefficient);

    // 计算显著性
    final significance = _calculateSignificance(coefficient, length);

    return CorrelationAnalysis(
      metric1: metric1,
      metric2: metric2,
      type: type,
      coefficient: coefficient,
      significance: significance,
      details: {
        'sampleSize': length,
        'timeWindow': config.windowSize.inMinutes,
      },
    );
  }

  /// 计算指标分数
  double _calculateMetricScore(String metric, double value) {
    final threshold = config.thresholds[metric];
    if (threshold == null) return 100.0;

    final ratio = value / threshold;
    if (ratio <= 0.6) return 100.0;
    if (ratio <= 0.7) return 90.0;
    if (ratio <= 0.8) return 80.0;
    if (ratio <= 0.9) return 70.0;
    if (ratio <= 1.0) return 60.0;
    if (ratio <= 1.1) return 50.0;
    if (ratio <= 1.2) return 40.0;
    if (ratio <= 1.3) return 30.0;
    if (ratio <= 1.4) return 20.0;
    return 10.0;
  }

  /// 计算显著性
  double _calculateSignificance(double coefficient, int sampleSize) {
    // 简化的显著性计算
    final t =
        coefficient * sqrt((sampleSize - 2) / (1 - coefficient * coefficient));
    return 1.0 - (1.0 / (1.0 + t * t));
  }

  /// 清理旧数据
  void _cleanOldData() {
    final cutoff = DateTime.now().subtract(config.windowSize);

    for (final metric in _metricData.keys) {
      final timestamps = _timestamps[metric]!;
      final values = _metricData[metric]!;

      while (timestamps.isNotEmpty && timestamps.first.isBefore(cutoff)) {
        timestamps.removeAt(0);
        values.removeAt(0);
      }
    }
  }

  /// 确定相关类型
  CorrelationType _determineCorrelationType(double coefficient) {
    final abs = coefficient.abs();
    if (abs < 0.3) return CorrelationType.none;
    if (abs >= 0.7) {
      return coefficient > 0
          ? CorrelationType.positive
          : CorrelationType.negative;
    }
    return CorrelationType.nonlinear;
  }

  /// 确定健康等级
  HealthLevel _determineHealthLevel(double score) {
    if (score >= 90) return HealthLevel.excellent;
    if (score >= 75) return HealthLevel.good;
    if (score >= 60) return HealthLevel.fair;
    if (score >= 40) return HealthLevel.poor;
    return HealthLevel.critical;
  }

  /// 获取总数据点数
  int _getTotalDataPoints() {
    return _metricData.values
        .map((list) => list.length)
        .reduce((a, b) => a + b);
  }

  /// 启动更新定时器
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(config.updateInterval, (_) {
      final assessment = calculateHealth();
      _assessments.add(assessment);
    });
  }
}
