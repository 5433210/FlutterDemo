import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as path;

import '../utils/alert_notifier.dart';

/// 负载测试配置
class LoadTestConfig {
  final Duration duration;
  final int concurrentUsers;
  final int rampUpTime;
  final Duration thinkTime;
  final String? outputPath;
  final Map<String, dynamic> parameters;

  const LoadTestConfig({
    required this.duration,
    required this.concurrentUsers,
    this.rampUpTime = 30,
    this.thinkTime = const Duration(milliseconds: 500),
    this.outputPath,
    this.parameters = const {},
  });
}

/// 负载测试结果
class LoadTestResult {
  final String name;
  final Duration duration;
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final double averageResponseTime;
  final double minResponseTime;
  final double maxResponseTime;
  final double p95ResponseTime;
  final Map<String, int> errorCounts;
  final Map<String, dynamic>? metrics;

  const LoadTestResult({
    required this.name,
    required this.duration,
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.averageResponseTime,
    required this.minResponseTime,
    required this.maxResponseTime,
    required this.p95ResponseTime,
    required this.errorCounts,
    this.metrics,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'duration_ms': duration.inMilliseconds,
        'requests': {
          'total': totalRequests,
          'successful': successfulRequests,
          'failed': failedRequests,
        },
        'response_times': {
          'average_ms': averageResponseTime,
          'min_ms': minResponseTime,
          'max_ms': maxResponseTime,
          'p95_ms': p95ResponseTime,
        },
        'errors': errorCounts,
        if (metrics != null) 'metrics': metrics,
      };
}

/// 负载测试运行器
class LoadTestRunner {
  final AlertNotifier notifier;
  final LoadTestConfig config;
  final _userSessions = <UserSession>{};
  final _results = <String, LoadTestResult>{};
  bool _isRunning = false;

  LoadTestRunner({
    required this.notifier,
    required this.config,
  });

  /// 运行负载测试
  Future<LoadTestResult> runTest(
    String name,
    Future<void> Function() testCase,
  ) async {
    if (_isRunning) {
      throw StateError('Load test is already running');
    }
    _isRunning = true;

    try {
      notifier.notify(AlertBuilder()
          .message('开始负载测试: $name')
          .level(AlertLevel.info)
          .addData('users', config.concurrentUsers)
          .addData('duration', config.duration.inSeconds)
          .build());

      final metrics = <double>[];
      final errors = <String, int>{};
      var successCount = 0;
      var failureCount = 0;

      // 启动用户会话
      final sessionFutures = <Future<void>>[];
      for (var i = 0; i < config.concurrentUsers; i++) {
        final delay = (i * config.rampUpTime) ~/ config.concurrentUsers;
        final session = UserSession(
          id: i,
          thinkTime: config.thinkTime,
        );
        _userSessions.add(session);

        sessionFutures.add(_runUserSession(
          session,
          testCase,
          delay,
          metrics,
          errors,
          () => successCount++,
          () => failureCount++,
        ));
      }

      // 等待所有会话完成
      await Future.wait(sessionFutures);

      // 计算结果
      metrics.sort();
      final result = LoadTestResult(
        name: name,
        duration: config.duration,
        totalRequests: successCount + failureCount,
        successfulRequests: successCount,
        failedRequests: failureCount,
        averageResponseTime: metrics.isEmpty ? 0 : _calculateMean(metrics),
        minResponseTime: metrics.isEmpty ? 0 : metrics.first,
        maxResponseTime: metrics.isEmpty ? 0 : metrics.last,
        p95ResponseTime:
            metrics.isEmpty ? 0 : _calculatePercentile(metrics, 0.95),
        errorCounts: errors,
        metrics: {
          'concurrent_users': config.concurrentUsers,
          'ramp_up_time': config.rampUpTime,
          'think_time_ms': config.thinkTime.inMilliseconds,
        },
      );

      _results[name] = result;
      await _saveResults();

      notifier.notify(AlertBuilder()
          .message('负载测试完成: $name')
          .level(AlertLevel.info)
          .addData('success_rate',
              '${(successCount * 100 / (successCount + failureCount)).toStringAsFixed(2)}%')
          .build());

      return result;
    } finally {
      _isRunning = false;
      _userSessions.clear();
    }
  }

  /// 停止测试
  void stop() {
    _isRunning = false;
  }

  /// 计算平均值
  double _calculateMean(List<double> values) {
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// 计算百分位数
  double _calculatePercentile(List<double> sortedValues, double percentile) {
    final index = (sortedValues.length * percentile).round() - 1;
    return sortedValues[math.max(0, math.min(index, sortedValues.length - 1))];
  }

  /// 运行单个用户会话
  Future<void> _runUserSession(
    UserSession session,
    Future<void> Function() testCase,
    int startDelay,
    List<double> metrics,
    Map<String, int> errors,
    void Function() onSuccess,
    void Function() onFailure,
  ) async {
    await Future.delayed(Duration(seconds: startDelay));

    final endTime = DateTime.now().add(config.duration);
    while (DateTime.now().isBefore(endTime) && _isRunning) {
      try {
        final stopwatch = Stopwatch()..start();
        await testCase();
        stopwatch.stop();

        metrics.add(stopwatch.elapsedMicroseconds / 1000); // 转换为毫秒
        onSuccess();
      } catch (e) {
        onFailure();
        errors.update(
          e.toString(),
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }

      await Future.delayed(session.thinkTime);
    }
  }

  /// 保存结果
  Future<void> _saveResults() async {
    if (config.outputPath == null) return;

    final file = File(path.join(
      config.outputPath!,
      'loadtest_${DateTime.now().millisecondsSinceEpoch}.json',
    ));

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({
        'timestamp': DateTime.now().toIso8601String(),
        'config': {
          'concurrent_users': config.concurrentUsers,
          'duration_ms': config.duration.inMilliseconds,
          'ramp_up_time': config.rampUpTime,
          'think_time_ms': config.thinkTime.inMilliseconds,
          'parameters': config.parameters,
        },
        'results': _results.map((k, v) => MapEntry(k, v.toJson())),
      }),
    );
  }
}

/// 用户会话
class UserSession {
  final int id;
  final Duration thinkTime;

  const UserSession({
    required this.id,
    required this.thinkTime,
  });
}
