import 'dart:math' as math;

import '../utils/alert_notifier.dart';

/// 预测结果
class PredictionResult {
  final ResourceType type;
  final String resource;
  final double predictedValue;
  final double confidence;
  final Duration predictionWindow;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  const PredictionResult({
    required this.type,
    required this.resource,
    required this.predictedValue,
    required this.confidence,
    required this.predictionWindow,
    required this.timestamp,
    this.context = const {},
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'resource': resource,
        'predicted_value': predictedValue,
        'confidence': confidence,
        'prediction_window_minutes': predictionWindow.inMinutes,
        'timestamp': timestamp.toIso8601String(),
        'context': context,
      };
}

/// 资源预测配置
class PredictorConfig {
  final int historyWindow;
  final Duration predictionInterval;
  final double confidenceThreshold;
  final Duration minPredictionWindow;
  final Duration maxPredictionWindow;
  final AlertLevel warningLevel;
  final AlertLevel errorLevel;

  const PredictorConfig({
    this.historyWindow = 100,
    this.predictionInterval = const Duration(minutes: 15),
    this.confidenceThreshold = 0.8,
    this.minPredictionWindow = const Duration(hours: 1),
    this.maxPredictionWindow = const Duration(days: 7),
    this.warningLevel = AlertLevel.warning,
    this.errorLevel = AlertLevel.error,
  });
}

/// 资源预测器
class ResourcePredictor {
  final AlertNotifier notifier;
  final PredictorConfig config;
  final _history = <String, List<ResourceUsage>>{};
  final _predictions = <String, PredictionResult>{};

  ResourcePredictor({
    required this.notifier,
    PredictorConfig? config,
  }) : config = config ?? const PredictorConfig();

  /// 添加资源使用记录
  void addUsage(ResourceUsage usage) {
    final history = _history.putIfAbsent(usage.resource, () => []);
    history.add(usage);

    while (history.length > config.historyWindow) {
      history.removeAt(0);
    }

    _updatePrediction(usage.type, usage.resource);
  }

  /// 获取所有预测
  Map<String, PredictionResult> getAllPredictions() =>
      Map.unmodifiable(_predictions);

  /// 获取预测结果
  PredictionResult? getPrediction(String resource) => _predictions[resource];

  /// 重置所有数据
  void reset() {
    _history.clear();
    _predictions.clear();
  }

  /// 重置特定资源
  void resetResource(String resource) {
    _history.remove(resource);
    _predictions.remove(resource);
  }

  /// 计算自相关
  List<double> _calculateAutoCorrelation(List<double> values) {
    final n = values.length;
    final mean = values.reduce((a, b) => a + b) / n;
    final variance =
        values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / n;

    if (variance == 0) return List.filled(n ~/ 2, 0);

    final result = List<double>.filled(n ~/ 2, 0);

    for (var lag = 0; lag < n ~/ 2; lag++) {
      var sum = 0.0;
      for (var i = 0; i < n - lag; i++) {
        sum += (values[i] - mean) * (values[i + lag] - mean);
      }
      result[lag] = sum / ((n - lag) * variance);
    }

    return result;
  }

  /// 计算置信度
  double _calculateConfidence({
    required List<double> values,
    required double trend,
    required Map<String, dynamic> seasonal,
  }) {
    final volatility = _calculateVolatility(values);
    final seasonalStrength = seasonal['strength'] as double;

    final baseConfidence = math.exp(-volatility);
    final trendFactor = trend.abs() < 0.01 ? 1.0 : math.exp(-trend.abs());
    final seasonalFactor = seasonalStrength > 0.5 ? 1.2 : 1.0;

    return math.min(1.0, baseConfidence * trendFactor * seasonalFactor);
  }

  /// 计算预测窗口
  Duration _calculatePredictionWindow(
    double trend,
    Map<String, dynamic> seasonal,
  ) {
    final trendStrength = trend.abs();
    final seasonalStrength = seasonal['strength'] as double;

    if (trendStrength < 0.001 && seasonalStrength < 0.3) {
      return config.minPredictionWindow;
    }

    final baseMinutes = config.minPredictionWindow.inMinutes;
    final maxMinutes = config.maxPredictionWindow.inMinutes;
    final factor = math.min(1.0, math.max(trendStrength, seasonalStrength));

    final additionalMinutes = ((maxMinutes - baseMinutes) * factor).round();
    return Duration(minutes: baseMinutes + additionalMinutes);
  }

  /// 计算趋势
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;

    final n = values.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = values;

    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((x) => x * x).reduce((a, b) => a + b);

    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  /// 计算波动性
  double _calculateVolatility(List<double> values) {
    if (values.length < 2) return 0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return double.infinity;

    final variance =
        values.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) /
            (values.length - 1);

    return math.sqrt(variance) / mean;
  }

  /// 检查预警条件
  void _checkWarningConditions(PredictionResult prediction) {
    if (prediction.confidence < config.confidenceThreshold) {
      notifier.notify(AlertBuilder()
          .message('资源预测置信度过低')
          .level(config.warningLevel)
          .addData('resource', prediction.resource)
          .addData('confidence', prediction.confidence)
          .addData('threshold', config.confidenceThreshold)
          .build());
      return;
    }

    final history = _history[prediction.resource];
    if (history == null || history.isEmpty) return;

    final currentValue = history.last.value;
    final ratio = prediction.predictedValue / currentValue;

    if (ratio > 2.0) {
      notifier.notify(AlertBuilder()
          .message('预测资源使用量显著增加')
          .level(config.errorLevel)
          .addData('resource', prediction.resource)
          .addData('current', currentValue)
          .addData('predicted', prediction.predictedValue)
          .addData('window', prediction.predictionWindow.inMinutes)
          .build());
    }
  }

  /// 检测季节性
  Map<String, dynamic> _detectSeasonality(
    List<double> values,
    List<DateTime> timestamps,
  ) {
    final autoCorr = _calculateAutoCorrelation(values);
    final period = _findPeriod(autoCorr);

    return {
      'period': period,
      'strength': period > 0 ? autoCorr[period] : 0,
    };
  }

  /// 查找周期
  int _findPeriod(List<double> autoCorr) {
    if (autoCorr.length < 3) return 0;

    var maxCorr = 0.0;
    var period = 0;

    for (var i = 2; i < autoCorr.length; i++) {
      if (autoCorr[i] > maxCorr && autoCorr[i] > 0.5) {
        maxCorr = autoCorr[i];
        period = i;
      }
    }

    return period;
  }

  /// 生成预测
  PredictionResult _generatePrediction({
    required ResourceType type,
    required String resource,
    required List<double> values,
    required List<DateTime> timestamps,
    required double trend,
    required Map<String, dynamic> seasonal,
    required Duration window,
  }) {
    final lastValue = values.last;
    final prediction = lastValue + trend * window.inMinutes;

    final confidence = _calculateConfidence(
      values: values,
      trend: trend,
      seasonal: seasonal,
    );

    return PredictionResult(
      type: type,
      resource: resource,
      predictedValue: prediction,
      confidence: confidence,
      predictionWindow: window,
      timestamp: DateTime.now(),
      context: {
        'trend': trend,
        'seasonal_period': seasonal['period'],
        'seasonal_strength': seasonal['strength'],
        'sample_size': values.length,
      },
    );
  }

  /// 更新预测
  void _updatePrediction(ResourceType type, String resource) {
    final history = _history[resource];
    if (history == null || history.length < 10) return;

    final now = DateTime.now();
    final values = history.map((u) => u.value).toList();
    final timestamps = history.map((u) => u.timestamp).toList();

    final trend = _calculateTrend(values);
    final seasonal = _detectSeasonality(values, timestamps);
    final predictionWindow = _calculatePredictionWindow(trend, seasonal);

    final prediction = _generatePrediction(
      type: type,
      resource: resource,
      values: values,
      timestamps: timestamps,
      trend: trend,
      seasonal: seasonal,
      window: predictionWindow,
    );

    _predictions[resource] = prediction;
    _checkWarningConditions(prediction);
  }
}

/// 资源类型
enum ResourceType { cpu, memory, disk, network, custom }

/// 资源使用记录
class ResourceUsage {
  final ResourceType type;
  final String resource;
  final double value;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ResourceUsage({
    required this.type,
    required this.resource,
    required this.value,
    required this.timestamp,
    this.metadata = const {},
  });
}
