import 'dart:async';
import 'dart:math';

import '../utils/monitor_analyzer.dart';
import '../utils/monitor_server.dart';

void main() async {
  final analyzer = MonitorAnalyzer(
    config: const MonitorConfig(
      windowSize: Duration(minutes: 5),
      enableTrending: true,
    ),
  );

  final server = MonitorServer(
    analyzer: analyzer,
    config: const ServerConfig(
      host: 'localhost',
      port: 8080,
      enableCors: true,
      refreshInterval: Duration(milliseconds: 100),
    ),
  );

  try {
    // 启动服务器
    await server.start();

    // 运行基准测试
    print('开始基准测试...\n');

    final results = await Future.wait([
      _runDataPointBenchmark(analyzer),
      _runTrendAnalysisBenchmark(analyzer),
      _runThresholdCheckBenchmark(analyzer),
    ]);

    print('\n基准测试结果:');
    print('=' * 50);
    for (final result in results) {
      print(result);
      print('=' * 50);
    }
  } finally {
    await server.stop();
  }
}

/// 数据点添加基准测试
Future<BenchmarkResult> _runDataPointBenchmark(MonitorAnalyzer analyzer) async {
  analyzer.defineMetric(const Metric(
    name: 'benchmark_metric',
    unit: 'ops',
    description: '基准测试指标',
  ));

  final random = Random();
  const operations = 10000;
  final startTime = DateTime.now();

  for (var i = 0; i < operations; i++) {
    analyzer.addDataPoint(
      'benchmark_metric',
      random.nextDouble() * 100,
      DateTime.now(),
    );
  }

  final duration = DateTime.now().difference(startTime);
  final stats = analyzer.calculateStats('benchmark_metric');

  return BenchmarkResult(
    name: 'Data Point Insertion',
    duration: duration,
    operations: operations,
    metrics: stats,
  );
}

/// 阈值检查基准测试
Future<BenchmarkResult> _runThresholdCheckBenchmark(
    MonitorAnalyzer analyzer) async {
  analyzer.defineMetric(const Metric(
    name: 'threshold_metric',
    unit: 'value',
    description: '阈值测试指标',
  ));

  analyzer.setThreshold(
    'threshold_metric',
    warning: 70,
    error: 90,
  );

  const operations = 5000;
  final random = Random();
  final startTime = DateTime.now();
  var checkTime = Duration.zero;
  var violations = 0;

  for (var i = 0; i < operations; i++) {
    // 生成随机值，有20%概率超过阈值
    final value =
        random.nextDouble() * 100 + (random.nextDouble() < 0.2 ? 50 : 0);

    analyzer.addDataPoint(
      'threshold_metric',
      value,
      DateTime.now(),
    );

    final checkStart = DateTime.now();
    final checks = analyzer.checkThresholds('threshold_metric');
    checkTime += DateTime.now().difference(checkStart);

    violations += checks.length;
  }

  final duration = DateTime.now().difference(startTime);

  return BenchmarkResult(
    name: 'Threshold Checking',
    duration: duration,
    operations: operations,
    metrics: {
      'total_time_ms': duration.inMilliseconds.toDouble(),
      'check_time_ms': checkTime.inMilliseconds.toDouble(),
      'avg_check_ms': checkTime.inMilliseconds / operations,
      'violations': violations.toDouble(),
      'violation_rate': violations / operations * 100,
    },
  );
}

/// 趋势分析基准测试
Future<BenchmarkResult> _runTrendAnalysisBenchmark(
    MonitorAnalyzer analyzer) async {
  analyzer.defineMetric(const Metric(
    name: 'trend_metric',
    unit: 'value',
    description: '趋势测试指标',
  ));

  const operations = 1000;
  final startTime = DateTime.now();
  var analysisTime = Duration.zero;

  // 添加具有明显趋势的数据
  for (var i = 0; i < operations; i++) {
    final value = i * 0.1 + sin(i * pi / 100) * 10;
    analyzer.addDataPoint(
      'trend_metric',
      value,
      DateTime.now().subtract(Duration(minutes: operations - i)),
    );

    final analysisStart = DateTime.now();
    final trend = analyzer.analyzeTrend('trend_metric');
    analysisTime += DateTime.now().difference(analysisStart);

    // 验证趋势分析结果
    if (i > 100) {
      assert(trend.confidence > 0.5, '趋势置信度应该较高');
      assert(trend.slope > 0, '应该检测到上升趋势');
    }
  }

  final duration = DateTime.now().difference(startTime);

  return BenchmarkResult(
    name: 'Trend Analysis',
    duration: duration,
    operations: operations,
    metrics: {
      'total_time_ms': duration.inMilliseconds.toDouble(),
      'analysis_time_ms': analysisTime.inMilliseconds.toDouble(),
      'avg_analysis_ms': analysisTime.inMilliseconds / operations,
    },
  );
}

class BenchmarkResult {
  final String name;
  final Duration duration;
  final int operations;
  final Map<String, double> metrics;

  BenchmarkResult({
    required this.name,
    required this.duration,
    required this.operations,
    required this.metrics,
  });

  double get opsPerSecond => operations / duration.inSeconds;

  @override
  String toString() {
    final buf = StringBuffer()
      ..writeln('Benchmark: $name')
      ..writeln('Duration: ${duration.inSeconds}s')
      ..writeln('Operations: $operations')
      ..writeln('Ops/sec: ${opsPerSecond.toStringAsFixed(2)}')
      ..writeln('\nMetrics:');

    metrics.forEach((key, value) {
      buf.writeln('  $key: ${value.toStringAsFixed(2)}');
    });

    return buf.toString();
  }
}
