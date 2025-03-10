import 'dart:async';
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

  // 创建自适应监控器
  final monitor = AdaptiveMonitor(
    analyzer: analyzer,
    config: AdaptiveConfig(
      adaptationInterval: const Duration(minutes: 1),
      learningRate: 0.2,
      historyWindow: 30,
      adaptationThreshold: 0.1,
    ),
  );

  // 注册自适应指标
  monitor.registerMetric(AdaptiveMetric(
    name: 'response_time',
    unit: 'ms',
    description: '响应时间',
    initialWarning: 100,
    initialError: 200,
    minThreshold: 50,
    maxThreshold: 500,
  ));

  // 生成模拟数据
  final random = Random();
  var baseValue = 80.0;
  var trend = 0.5;

  print('开始自适应监控...\n');

  // 运行10分钟
  for (var minute = 0; minute < 10; minute++) {
    print('\n分钟 $minute:');

    // 每分钟生成6个数据点
    for (var i = 0; i < 6; i++) {
      // 模拟逐渐变化的基准值
      baseValue += trend;
      if (baseValue > 200) trend = -0.5;
      if (baseValue < 50) trend = 0.5;

      // 添加随机波动
      final value = baseValue + random.nextDouble() * 20 - 10;

      analyzer.addDataPoint(
        'response_time',
        value,
        DateTime.now(),
      );

      // 检查当前阈值
      final thresholds = analyzer.getThresholds()['response_time'];
      if (thresholds != null) {
        print('当前值: ${value.toStringAsFixed(1)} ms');
        print('警告阈值: ${thresholds.warning.toStringAsFixed(1)} ms');
        print('错误阈值: ${thresholds.error.toStringAsFixed(1)} ms');
      }
    }

    // 等待适应
    await Future.delayed(const Duration(seconds: 1));
  }

  // 打印适应历史
  print('\n阈值调整历史:');
  print('=' * 50);
  for (final adjustment in monitor.getHistory('response_time')) {
    print(adjustment);
    print('上下文:');
    adjustment.context.forEach((key, value) {
      print('  $key: ${value is double ? value.toStringAsFixed(3) : value}');
    });
    print('-' * 50);
  }

  // 清理资源
  monitor.dispose();
}

/// 自适应配置
class AdaptiveConfig {
  final Duration adaptationInterval;
  final double learningRate;
  final int historyWindow;
  final double adaptationThreshold;

  AdaptiveConfig({
    this.adaptationInterval = const Duration(minutes: 5),
    this.learningRate = 0.1,
    this.historyWindow = 100,
    this.adaptationThreshold = 0.2,
  });
}

/// 适应性指标
class AdaptiveMetric {
  final String name;
  final String unit;
  final String description;
  final double initialWarning;
  final double initialError;
  final double minThreshold;
  final double maxThreshold;

  AdaptiveMetric({
    required this.name,
    required this.unit,
    required this.description,
    required this.initialWarning,
    required this.initialError,
    required this.minThreshold,
    required this.maxThreshold,
  });
}

/// 自适应监控器
class AdaptiveMonitor {
  final MonitorAnalyzer analyzer;
  final AdaptiveConfig config;
  final _metrics = <String, AdaptiveMetric>{};
  final _adaptationHistory = <String, List<ThresholdAdjustment>>{};
  Timer? _adaptationTimer;
  bool _disposed = false;

  AdaptiveMonitor({
    required this.analyzer,
    AdaptiveConfig? config,
  }) : config = config ?? AdaptiveConfig() {
    _startAdaptation();
  }

  /// 销毁监控器
  void dispose() {
    if (!_disposed) {
      _adaptationTimer?.cancel();
      _disposed = true;
    }
  }

  /// 获取适应历史
  List<ThresholdAdjustment> getHistory(String metric) =>
      List.unmodifiable(_adaptationHistory[metric] ?? []);

  /// 注册自适应指标
  void registerMetric(AdaptiveMetric metric) {
    _metrics[metric.name] = metric;

    analyzer.defineMetric(Metric(
      name: metric.name,
      unit: metric.unit,
      description: metric.description,
    ));

    analyzer.setThreshold(
      metric.name,
      warning: metric.initialWarning,
      error: metric.initialError,
    );

    _adaptationHistory[metric.name] = [];
  }

  /// 调整阈值
  Future<void> _adaptThresholds() async {
    for (final metric in _metrics.entries) {
      final adjustment = await _calculateAdjustment(metric.value);
      if (adjustment != null) {
        _applyAdjustment(adjustment);
        _adaptationHistory[metric.key]?.add(adjustment);
      }
    }
  }

  /// 应用阈值调整
  void _applyAdjustment(ThresholdAdjustment adjustment) {
    analyzer.setThreshold(
      adjustment.metric,
      warning: adjustment.newWarning,
      error: adjustment.newError,
    );
  }

  /// 计算阈值调整
  Future<ThresholdAdjustment?> _calculateAdjustment(
    AdaptiveMetric metric,
  ) async {
    final history = analyzer.getMetricHistory(metric.name);
    if (history.length < config.historyWindow) return null;

    final currentThresholds = analyzer.getThresholds()[metric.name];
    if (currentThresholds == null) return null;

    final stats = analyzer.calculateStats(metric.name);
    final trend = analyzer.analyzeTrend(metric.name);

    // 计算新阈值
    var newWarning = currentThresholds.warning;
    var newError = currentThresholds.error;
    String reason;

    if (trend.confidence > 0.8) {
      // 基于趋势调整
      final adjustment = trend.slope * config.adaptationInterval.inMinutes;
      newWarning += adjustment * config.learningRate;
      newError += adjustment * config.learningRate;
      reason = 'Trend-based adjustment';
    } else {
      // 基于统计分布调整
      final mean = stats['avg'] ?? 0.0;
      final std = stats['std'] ?? 0.0;

      newWarning = mean + 2 * std;
      newError = mean + 3 * std;
      reason = 'Distribution-based adjustment';
    }

    // 确保在允许范围内
    newWarning = newWarning.clamp(metric.minThreshold, metric.maxThreshold);
    newError = newError.clamp(metric.minThreshold, metric.maxThreshold);

    // 检查变化是否足够大
    final warningChange = (newWarning - currentThresholds.warning).abs();
    final errorChange = (newError - currentThresholds.error).abs();

    if (warningChange / currentThresholds.warning <
            config.adaptationThreshold &&
        errorChange / currentThresholds.error < config.adaptationThreshold) {
      return null;
    }

    return ThresholdAdjustment(
      metric: metric.name,
      oldWarning: currentThresholds.warning,
      oldError: currentThresholds.error,
      newWarning: newWarning,
      newError: newError,
      reason: reason,
      context: {
        'trend_confidence': trend.confidence,
        'trend_slope': trend.slope,
        'mean': stats['avg'],
        'std': stats['std'],
      },
    );
  }

  /// 启动自适应过程
  void _startAdaptation() {
    if (_disposed) return;

    _adaptationTimer = Timer.periodic(
      config.adaptationInterval,
      (_) => _adaptThresholds(),
    );
  }
}

/// 阈值调整结果
class ThresholdAdjustment {
  final String metric;
  final double oldWarning;
  final double oldError;
  final double newWarning;
  final double newError;
  final String reason;
  final Map<String, dynamic> context;

  ThresholdAdjustment({
    required this.metric,
    required this.oldWarning,
    required this.oldError,
    required this.newWarning,
    required this.newError,
    required this.reason,
    this.context = const {},
  });

  @override
  String toString() => '''
Threshold Adjustment for $metric:
  Warning: $oldWarning -> $newWarning
  Error: $oldError -> $newError
  Reason: $reason
''';
}
