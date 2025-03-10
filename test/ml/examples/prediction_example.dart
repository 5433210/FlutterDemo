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

  // 创建预测模型
  final predictor = PredictionModel(
    analyzer: analyzer,
    config: PredictionConfig(
      predictionWindow: const Duration(hours: 2),
      minDataPoints: 24,
      confidenceThreshold: 0.6,
    ),
  );

  // 定义测试指标
  analyzer.defineMetric(const Metric(
    name: 'cpu_usage',
    unit: '%',
    description: 'CPU使用率',
  ));

  // 生成训练数据
  final random = Random();
  final now = DateTime.now();

  // 基本模式: 日周期 + 趋势 + 噪声
  for (var i = 0; i < 72; i++) {
    // 3天数据
    final hour = i % 24;
    final value = 50.0 // 基准值
        +
        20 * sin(hour * pi / 12) // 日周期
        +
        i * 0.1 // 上升趋势
        +
        random.nextDouble() * 5; // 随机噪声

    analyzer.addDataPoint(
      'cpu_usage',
      value,
      now.subtract(Duration(hours: 72 - i)),
    );
  }

  // 进行预测
  final predictions = predictor.predict(
    'cpu_usage',
    window: const Duration(hours: 4),
    steps: 24,
  );

  // 打印结果
  print('\nCPU使用率预测:');
  print('=' * 50);
  print(
      '模型准确度: ${(predictor.getAccuracy('cpu_usage') * 100).toStringAsFixed(1)}%');
  print('-' * 50);

  for (final prediction in predictions) {
    print(prediction);
    print('影响因素:');
    prediction.factors.forEach((key, value) {
      print('  $key: ${value is double ? value.toStringAsFixed(3) : value}');
    });
    print('-' * 50);
  }
}

/// 预测配置
class PredictionConfig {
  final Duration predictionWindow;
  final int minDataPoints;
  final double confidenceThreshold;
  final bool enableSeasonality;

  PredictionConfig({
    this.predictionWindow = const Duration(hours: 1),
    this.minDataPoints = 30,
    this.confidenceThreshold = 0.7,
    this.enableSeasonality = true,
  });
}

/// 预测模型
class PredictionModel {
  final MonitorAnalyzer analyzer;
  final PredictionConfig config;
  final _models = <String, _TimeSeriesModel>{};

  PredictionModel({
    required this.analyzer,
    PredictionConfig? config,
  }) : config = config ?? PredictionConfig();

  /// 获取预测准确度
  double getAccuracy(String metric) {
    final model = _models[metric];
    if (model == null) return 0.0;
    return model.accuracy;
  }

  /// 预测未来值
  List<PredictionResult> predict(
    String metric, {
    Duration? window,
    int steps = 12,
  }) {
    final history = analyzer.getMetricHistory(metric);
    if (history.length < config.minDataPoints) {
      return [];
    }

    final model = _models[metric] ??= _TimeSeriesModel();
    model.train(history);

    final results = <PredictionResult>[];
    var currentTime = DateTime.now();
    final stepSize = (window ?? config.predictionWindow).inMinutes ~/ steps;

    for (var i = 1; i <= steps; i++) {
      final predictTime = currentTime.add(Duration(minutes: i * stepSize));
      final prediction = model.predict(predictTime);

      if (prediction.confidence >= config.confidenceThreshold) {
        results.add(prediction);
      }
    }

    return results;
  }
}

/// 预测结果
class PredictionResult {
  final String metric;
  final DateTime timestamp;
  final double value;
  final double confidence;
  final Map<String, dynamic> factors;

  PredictionResult({
    required this.metric,
    required this.timestamp,
    required this.value,
    required this.confidence,
    this.factors = const {},
  });

  @override
  String toString() =>
      'Prediction($metric): $value at $timestamp (confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// 时间序列模型
class _TimeSeriesModel {
  double _slope = 0.0;
  double _intercept = 0.0;
  List<double> _seasonalFactors = [];
  double _accuracy = 0.0;

  double get accuracy => _accuracy;

  PredictionResult predict(DateTime time) {
    final timeIndex = time.difference(DateTime.now()).inMinutes.toDouble();
    final value = _predict(timeIndex, time);

    // 计算预测置信度
    final confidence = max(0.0, min(1.0, _accuracy * exp(-timeIndex / 1440)));

    return PredictionResult(
      metric: 'predicted',
      timestamp: time,
      value: value,
      confidence: confidence,
      factors: {
        'trend': _slope,
        'baseline': _intercept,
        'seasonal_factor':
            _seasonalFactors.isEmpty ? 1.0 : _seasonalFactors[time.hour],
        'model_accuracy': _accuracy,
      },
    );
  }

  void train(List<MapEntry<DateTime, double>> history) {
    if (history.length < 2) return;

    // 线性回归
    final x = List.generate(history.length, (i) => i.toDouble());
    final y = history.map((e) => e.value).toList();
    _fitLinearRegression(x, y);

    // 季节性分析
    if (history.length >= 24) {
      _fitSeasonality(history);
    }

    // 计算准确度
    _calculateAccuracy(history);
  }

  void _calculateAccuracy(List<MapEntry<DateTime, double>> history) {
    var sumSquaredError = 0.0;
    var sumSquaredTotal = 0.0;
    final mean =
        history.map((e) => e.value).reduce((a, b) => a + b) / history.length;

    for (var i = 0; i < history.length; i++) {
      final actual = history[i].value;
      final predicted = _predict(i.toDouble(), history[i].key);
      final error = actual - predicted;
      final total = actual - mean;
      sumSquaredError += error * error;
      sumSquaredTotal += total * total;
    }

    _accuracy = 1 - (sumSquaredError / (sumSquaredTotal + 1e-10));
  }

  void _fitLinearRegression(List<double> x, List<double> y) {
    final n = x.length;
    final xMean = x.reduce((a, b) => a + b) / n;
    final yMean = y.reduce((a, b) => a + b) / n;

    var xxSum = 0.0;
    var xySum = 0.0;
    for (var i = 0; i < n; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;
      xxSum += xDiff * xDiff;
      xySum += xDiff * yDiff;
    }

    _slope = xySum / xxSum;
    _intercept = yMean - _slope * xMean;
  }

  void _fitSeasonality(List<MapEntry<DateTime, double>> history) {
    final hourlyValues = List<List<double>>.generate(24, (_) => []);

    for (final point in history) {
      hourlyValues[point.key.hour].add(point.value);
    }

    _seasonalFactors = hourlyValues.map((values) {
      if (values.isEmpty) return 1.0;
      return values.reduce((a, b) => a + b) / values.length;
    }).toList();

    // 标准化季节因子
    final seasonalMean = _seasonalFactors.reduce((a, b) => a + b) / 24;
    for (var i = 0; i < 24; i++) {
      _seasonalFactors[i] /= seasonalMean;
    }
  }

  double _predict(double x, DateTime time) {
    var prediction = _slope * x + _intercept;
    if (_seasonalFactors.isNotEmpty) {
      prediction *= _seasonalFactors[time.hour];
    }
    return prediction;
  }
}
