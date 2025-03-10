import 'dart:math' as math;

import '../utils/monitor_analyzer.dart';

void main() async {
  // 创建分析器
  final analyzer = MonitorAnalyzer(
    config: const MonitorConfig(
      windowSize: Duration(hours: 1),
      enableTrending: true,
    ),
  );

  // 定义指标
  analyzer.defineMetric(const Metric(
    name: 'response_time',
    unit: 'ms',
    description: '请求响应时间',
  ));

  analyzer.defineMetric(const Metric(
    name: 'error_rate',
    unit: '%',
    description: '错误率',
  ));

  analyzer.defineMetric(const Metric(
    name: 'qps',
    unit: 'req/s',
    description: '每秒请求数',
  ));

  // 设置阈值
  analyzer.setThreshold(
    'response_time',
    warning: 200,
    error: 500,
    isUpperBound: true,
  );

  analyzer.setThreshold(
    'error_rate',
    warning: 5,
    error: 10,
    isUpperBound: true,
  );

  analyzer.setThreshold(
    'qps',
    warning: 1000,
    error: 2000,
    isUpperBound: true,
  );

  // 添加示例数据
  final now = DateTime.now();

  // 响应时间逐渐增加的场景
  for (var i = 0; i < 60; i++) {
    analyzer.addDataPoint(
      'response_time',
      100 + i * 5.0,
      now.add(Duration(minutes: i)),
    );
  }

  // 错误率突增的场景
  for (var i = 0; i < 60; i++) {
    final value = i >= 45 ? 15.0 : 2.0;
    analyzer.addDataPoint(
      'error_rate',
      value,
      now.add(Duration(minutes: i)),
    );
  }

  // QPS 波动的场景
  for (var i = 0; i < 60; i++) {
    const baseQps = 800.0;
    final timeOfDay = (i % 24);
    // 12小时周期的正弦波动
    final variation = 200.0 * math.sin(timeOfDay * math.pi / 12);
    analyzer.addDataPoint(
      'qps',
      baseQps + variation,
      now.add(Duration(minutes: i)),
    );
  }

  // 分析趋势
  final responseTrend = analyzer.analyzeTrend('response_time');
  print('\n响应时间趋势分析:');
  print('斜率: ${responseTrend.slope.toStringAsFixed(3)} ms/min');
  print('相关性: ${responseTrend.correlation.toStringAsFixed(3)}');
  print('置信度: ${(responseTrend.confidence * 100).toStringAsFixed(1)}%');
  print('上下文: ${responseTrend.context}');

  final errorTrend = analyzer.analyzeTrend('error_rate');
  print('\n错误率趋势分析:');
  print('斜率: ${errorTrend.slope.toStringAsFixed(3)} %/min');
  print('相关性: ${errorTrend.correlation.toStringAsFixed(3)}');
  print('置信度: ${(errorTrend.confidence * 100).toStringAsFixed(1)}%');
  print('上下文: ${errorTrend.context}');

  // 检查阈值违规
  final violations = analyzer.checkThresholds();
  if (violations.isNotEmpty) {
    print('\n检测到阈值违规:');
    for (final check in violations) {
      print('${check.metric}: '
          '${check.value.toStringAsFixed(1)} '
          '(${check.level} 阈值: ${check.threshold})');
    }
  }

  // 生成统计报告
  print('\n统计分析:');
  for (final metric in analyzer.getMetrics()) {
    final stats = analyzer.calculateStats(metric);
    print('\n$metric:');
    stats.forEach((key, value) {
      print('$key: ${value.toStringAsFixed(2)}');
    });
  }

  // 查看历史数据
  print('\n历史数据示例:');
  for (final metric in analyzer.getMetrics()) {
    final history = analyzer.getMetricHistory(
      metric,
      start: now.subtract(const Duration(minutes: 10)),
    );

    print('\n$metric 最近10分钟数据点:');
    for (final point in history) {
      print('${point.key}: ${point.value.toStringAsFixed(1)}');
    }
  }
}
