import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

import 'alert_notifier.dart';

/// 基准测试配置
class BenchmarkConfig {
  final Duration warmupTime;
  final Duration runTime;
  final int iterations;
  final bool saveResults;
  final String? outputPath;
  final bool verbose;
  final Map<String, dynamic> parameters;

  const BenchmarkConfig({
    this.warmupTime = const Duration(seconds: 5),
    this.runTime = const Duration(seconds: 30),
    this.iterations = 3,
    this.saveResults = true,
    this.outputPath,
    this.verbose = false,
    this.parameters = const {},
  });
}

/// 基准测试结果
class BenchmarkResult {
  final String name;
  final Duration duration;
  final int operations;
  final double opsPerSecond;
  final double avgLatency;
  final double p50Latency;
  final double p95Latency;
  final double p99Latency;
  final Map<String, dynamic>? metrics;

  const BenchmarkResult({
    required this.name,
    required this.duration,
    required this.operations,
    required this.opsPerSecond,
    required this.avgLatency,
    required this.p50Latency,
    required this.p95Latency,
    required this.p99Latency,
    this.metrics,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'duration_ms': duration.inMilliseconds,
        'operations': operations,
        'ops_per_second': opsPerSecond,
        'latency': {
          'avg_ms': avgLatency,
          'p50_ms': p50Latency,
          'p95_ms': p95Latency,
          'p99_ms': p99Latency,
        },
        if (metrics != null) 'metrics': metrics,
      };
}

/// 基准测试运行器
class BenchmarkRunner {
  final AlertNotifier notifier;
  final BenchmarkConfig config;
  final _results = <String, List<BenchmarkResult>>{};
  bool _isRunning = false;

  BenchmarkRunner({
    required this.notifier,
    BenchmarkConfig? config,
  }) : config = config ?? const BenchmarkConfig();

  /// 运行单个基准测试
  Future<BenchmarkResult> runBenchmark(
    String name,
    Future<void> Function() benchmark,
  ) async {
    if (_isRunning) {
      throw StateError('Benchmark runner is already running');
    }
    _isRunning = true;

    try {
      // 预热
      if (config.warmupTime > Duration.zero) {
        await _warmup(name, benchmark);
      }

      final results = <BenchmarkResult>[];

      // 多次迭代
      for (var i = 0; i < config.iterations; i++) {
        final result = await _runIteration(name, benchmark, i + 1);
        results.add(result);

        if (config.verbose) {
          _printResult(result);
        }
      }

      // 计算平均结果
      final avgResult = _calculateAverage(name, results);
      _results[name] = results;

      if (config.saveResults) {
        await _saveResults();
      }

      return avgResult;
    } finally {
      _isRunning = false;
    }
  }

  /// 计算平均结果
  BenchmarkResult _calculateAverage(
      String name, List<BenchmarkResult> results) {
    final avgOps = _mean(results.map((r) => r.opsPerSecond).toList());
    final avgLatency = _mean(results.map((r) => r.avgLatency).toList());
    final avgP50 = _mean(results.map((r) => r.p50Latency).toList());
    final avgP95 = _mean(results.map((r) => r.p95Latency).toList());
    final avgP99 = _mean(results.map((r) => r.p99Latency).toList());

    return BenchmarkResult(
      name: name,
      duration: results.first.duration,
      operations: results.map((r) => r.operations).reduce((a, b) => a + b),
      opsPerSecond: avgOps,
      avgLatency: avgLatency,
      p50Latency: avgP50,
      p95Latency: avgP95,
      p99Latency: avgP99,
    );
  }

  /// 计算平均值
  double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.sum / values.length;
  }

  /// 计算百分位数
  double _percentile(List<double> sortedValues, double percentile) {
    if (sortedValues.isEmpty) return 0;
    final index = (sortedValues.length * percentile).round() - 1;
    return sortedValues[index.clamp(0, sortedValues.length - 1)];
  }

  /// 打印结果
  void _printResult(BenchmarkResult result) {
    print('Benchmark: ${result.name}');
    print('  Duration: ${result.duration.inMilliseconds}ms');
    print('  Operations: ${result.operations}');
    print('  Ops/sec: ${result.opsPerSecond.toStringAsFixed(2)}');
    print('  Latency (ms):');
    print('    Avg: ${result.avgLatency.toStringAsFixed(2)}');
    print('    P50: ${result.p50Latency.toStringAsFixed(2)}');
    print('    P95: ${result.p95Latency.toStringAsFixed(2)}');
    print('    P99: ${result.p99Latency.toStringAsFixed(2)}');
    if (result.metrics != null) {
      print('  Additional Metrics:');
      result.metrics!.forEach((key, value) {
        print('    $key: $value');
      });
    }
    print('');
  }

  /// 运行单次迭代
  Future<BenchmarkResult> _runIteration(
    String name,
    Future<void> Function() benchmark,
    int iteration,
  ) async {
    final latencies = <double>[];
    var operations = 0;

    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < config.runTime) {
      final opStart = stopwatch.elapsedMicroseconds;
      await benchmark();
      final opEnd = stopwatch.elapsedMicroseconds;
      latencies.add((opEnd - opStart) / 1000); // 转换为毫秒
      operations++;
    }
    stopwatch.stop();

    latencies.sort();
    final duration = stopwatch.elapsed;

    return BenchmarkResult(
      name: '$name (iteration $iteration)',
      duration: duration,
      operations: operations,
      opsPerSecond: operations / duration.inSeconds,
      avgLatency: _mean(latencies),
      p50Latency: _percentile(latencies, 0.5),
      p95Latency: _percentile(latencies, 0.95),
      p99Latency: _percentile(latencies, 0.99),
      metrics: {
        'min_latency': latencies.first,
        'max_latency': latencies.last,
        'sample_size': latencies.length,
      },
    );
  }

  /// 保存结果
  Future<void> _saveResults() async {
    if (config.outputPath == null) return;

    const encoder = JsonEncoder.withIndent('  ');
    final json = encoder.convert({
      'timestamp': DateTime.now().toIso8601String(),
      'config': {
        'warmup_time_ms': config.warmupTime.inMilliseconds,
        'run_time_ms': config.runTime.inMilliseconds,
        'iterations': config.iterations,
        'parameters': config.parameters,
      },
      'results': _results.map((name, results) =>
          MapEntry(name, results.map((r) => r.toJson()).toList())),
    });

    final file = File(path.join(
      config.outputPath!,
      'benchmark_${DateTime.now().millisecondsSinceEpoch}.json',
    ));
    await file.parent.create(recursive: true);
    await file.writeAsString(json);
  }

  /// 预热
  Future<void> _warmup(String name, Future<void> Function() benchmark) async {
    if (config.verbose) {
      print('Warming up $name...');
    }

    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < config.warmupTime) {
      await benchmark();
    }
  }
}
