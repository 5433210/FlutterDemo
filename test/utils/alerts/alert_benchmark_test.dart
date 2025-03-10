import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../check_logger.dart';
import 'alert_config.dart';
import 'alert_filter.dart';
import 'alert_notifier.dart';
import 'alert_statistics.dart';
import 'alert_types.dart';

void main() {
  late Directory tempDir;
  late AlertConfig config;
  late AlertNotifier notifier;
  late AlertStatistics stats;
  late AlertFilter filter;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('benchmark_test_');
    config = AlertConfig(
      suppressionTimeMinutes: 1,
      enableDesktopNotifications: false,
      alertsPath: path.join(tempDir.path, 'alerts'),
      maxHistorySize: 100000,
    );
    notifier = AlertNotifier(
      config: config,
      logger: CheckLogger.instance,
    );
    stats = AlertStatistics();
    filter = AlertFilter();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
    notifier.dispose();
  });

  Future<BenchmarkResult> runBenchmark({
    required String name,
    required Future<void> Function() operation,
    required int iterations,
  }) async {
    // 预热
    for (var i = 0; i < 100; i++) {
      await operation();
    }

    // 清理
    notifier.dispose();
    stats.clear();
    filter.clearFilters();

    // 开始测量
    final startMemory = ProcessInfo.currentRss;
    final stopwatch = Stopwatch()..start();

    for (var i = 0; i < iterations; i++) {
      await operation();
    }

    stopwatch.stop();
    final endMemory = ProcessInfo.currentRss;

    return BenchmarkResult(
      name: name,
      duration: stopwatch.elapsed,
      operations: iterations,
      memoryUsage: endMemory - startMemory,
    );
  }

  test('警报发送性能', () async {
    final result = await runBenchmark(
      name: 'Alert Emission',
      iterations: 10000,
      operation: () => notifier.alert(
        type: 'benchmark',
        message: 'Benchmark test message',
        level: AlertLevel.info,
      ),
    );
    print(result);
    expect(result.opsPerSecond, greaterThan(100));
  });

  test('警报过滤性能', () async {
    // 准备数据
    final records = List.generate(
      10000,
      (i) => AlertRecord(
        timestamp: DateTime.now(),
        type: 'type${i % 10}',
        message: 'Message $i',
        level: AlertLevel.values[i % 4],
      ),
    );

    // 添加过滤条件
    filter.addFilter(const AlertFilterCriteria(
      types: {'type1', 'type2', 'type3'},
      levels: {AlertLevel.warning, AlertLevel.error},
    ));

    final result = await runBenchmark(
      name: 'Alert Filtering',
      iterations: 100,
      operation: () {
        filter.apply(records);
        return Future.value();
      },
    );
    print(result);
    expect(result.opsPerSecond, greaterThan(10));
  });

  test('警报统计性能', () async {
    final result = await runBenchmark(
      name: 'Alert Statistics',
      iterations: 10000,
      operation: () {
        stats.recordAlert(AlertRecord(
          timestamp: DateTime.now(),
          type: 'benchmark',
          message: 'Benchmark message',
          level: AlertLevel.info,
        ));
        return Future.value();
      },
    );
    print(result);
    expect(result.opsPerSecond, greaterThan(1000));
  });

  test('文件I/O性能', () async {
    final result = await runBenchmark(
      name: 'File I/O',
      iterations: 1000,
      operation: () async {
        final alert = AlertRecord(
          timestamp: DateTime.now(),
          type: 'io_test',
          message: 'I/O benchmark message',
          level: AlertLevel.info,
          details: {'benchmark': true},
        );

        final file = File(path.join(
          config.alertsPath,
          'benchmark_${DateTime.now().millisecondsSinceEpoch}.json',
        ));

        await file.writeAsString(alert.toJson().toString());
      },
    );
    print(result);
    expect(result.opsPerSecond, greaterThan(50));
  });

  test('并发警报处理性能', () async {
    final result = await runBenchmark(
      name: 'Concurrent Processing',
      iterations: 100,
      operation: () async {
        final futures = List.generate(
          100,
          (i) => notifier.alert(
            type: 'concurrent_test',
            message: 'Concurrent test $i',
            level: AlertLevel.info,
          ),
        );
        await Future.wait(futures);
      },
    );
    print(result);
    expect(result.opsPerSecond, greaterThan(5));
  });
}

class BenchmarkResult {
  final String name;
  final Duration duration;
  final int operations;
  final double opsPerSecond;
  final int memoryUsage;

  BenchmarkResult({
    required this.name,
    required this.duration,
    required this.operations,
    required this.memoryUsage,
  }) : opsPerSecond = operations / duration.inSeconds;

  @override
  String toString() {
    return '''
Benchmark: $name
- Duration: ${duration.inMilliseconds}ms
- Operations: $operations
- Throughput: ${opsPerSecond.toStringAsFixed(2)} ops/sec
- Memory Usage: ${(memoryUsage / 1024 / 1024).toStringAsFixed(2)}MB
''';
  }
}
