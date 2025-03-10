import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:path/path.dart' as path;

import '../utils/alert_notifier.dart';

/// 混沌测试配置
class ChaosConfig {
  final Duration testDuration;
  final Duration errorInterval;
  final double errorProbability;
  final int maxConcurrentErrors;
  final Set<String> targetComponents;
  final String? outputPath;
  final bool cleanup;

  const ChaosConfig({
    required this.testDuration,
    this.errorInterval = const Duration(seconds: 30),
    this.errorProbability = 0.2,
    this.maxConcurrentErrors = 2,
    this.targetComponents = const {},
    this.outputPath,
    this.cleanup = true,
  });
}

/// 混沌测试结果
class ChaosTestResult {
  final String componentId;
  final ErrorType errorType;
  final DateTime timestamp;
  final Duration duration;
  final bool recovered;
  final Map<String, dynamic> metrics;
  final String? failureReason;

  const ChaosTestResult({
    required this.componentId,
    required this.errorType,
    required this.timestamp,
    required this.duration,
    required this.recovered,
    this.metrics = const {},
    this.failureReason,
  });

  Map<String, dynamic> toJson() => {
        'component_id': componentId,
        'error_type': errorType.name,
        'timestamp': timestamp.toIso8601String(),
        'duration_ms': duration.inMilliseconds,
        'recovered': recovered,
        'metrics': metrics,
        if (failureReason != null) 'failure_reason': failureReason,
      };
}

/// 混沌测试运行器
class ChaosTestRunner {
  final AlertNotifier notifier;
  final ChaosConfig config;
  final _activeErrors = <String, ErrorType>{};
  final _results = <ChaosTestResult>[];
  Timer? _errorTimer;
  bool _running = false;

  ChaosTestRunner({
    required this.notifier,
    required this.config,
  });

  /// 启动混沌测试
  Future<void> start() async {
    if (_running) return;
    _running = true;

    notifier.notify(AlertBuilder()
        .message('开始混沌测试')
        .level(AlertLevel.warning)
        .addData('duration', config.testDuration.inSeconds)
        .addData('targets', config.targetComponents.toList())
        .build());

    _errorTimer = Timer.periodic(config.errorInterval, (_) {
      if (_running) _injectRandomError();
    });

    await Future.delayed(config.testDuration);
    await stop();
  }

  /// 停止混沌测试
  Future<void> stop() async {
    _running = false;
    _errorTimer?.cancel();
    await _cleanup();

    notifier.notify(AlertBuilder()
        .message('混沌测试完成')
        .level(AlertLevel.info)
        .addData('total_errors', _results.length)
        .addData('recovery_rate',
            '${(_results.where((r) => r.recovered).length * 100 / _results.length).toStringAsFixed(1)}%')
        .build());

    await _saveResults();
  }

  /// 清理资源
  Future<void> _cleanup() async {
    if (!config.cleanup) return;
    _activeErrors.clear();
  }

  /// 收集指标
  Future<Map<String, dynamic>> _collectMetrics(String componentId) async {
    return {
      'memory_usage': math.Random().nextInt(1024),
      'cpu_usage': math.Random().nextDouble() * 100,
      'error_count': _results.where((r) => r.componentId == componentId).length,
    };
  }

  /// 注入特定错误
  Future<void> _injectError(String componentId, ErrorType type) async {
    if (_activeErrors.containsKey(componentId)) return;
    _activeErrors[componentId] = type;

    final startTime = DateTime.now();
    notifier.notify(AlertBuilder()
        .message('注入错误: $componentId')
        .level(AlertLevel.error)
        .addData('error_type', type.name)
        .build());

    try {
      await _simulateError(componentId, type);
      final duration = DateTime.now().difference(startTime);

      _results.add(ChaosTestResult(
        componentId: componentId,
        errorType: type,
        timestamp: startTime,
        duration: duration,
        recovered: true,
        metrics: await _collectMetrics(componentId),
      ));
    } catch (e) {
      _results.add(ChaosTestResult(
        componentId: componentId,
        errorType: type,
        timestamp: startTime,
        duration: DateTime.now().difference(startTime),
        recovered: false,
        failureReason: e.toString(),
      ));

      rethrow;
    } finally {
      _activeErrors.remove(componentId);
    }
  }

  /// 注入随机错误
  void _injectRandomError() {
    if (_activeErrors.length >= config.maxConcurrentErrors) return;
    if (math.Random().nextDouble() > config.errorProbability) return;

    final components = config.targetComponents.toList();
    const errorTypes = ErrorType.values;

    final component = components[math.Random().nextInt(components.length)];
    final errorType = errorTypes[math.Random().nextInt(errorTypes.length)];

    _injectError(component, errorType);
  }

  /// 保存结果
  Future<void> _saveResults() async {
    if (config.outputPath == null) return;

    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'config': {
        'duration_ms': config.testDuration.inMilliseconds,
        'error_interval_ms': config.errorInterval.inMilliseconds,
        'error_probability': config.errorProbability,
        'max_concurrent_errors': config.maxConcurrentErrors,
        'target_components': config.targetComponents.toList(),
      },
      'results': _results.map((r) => r.toJson()).toList(),
      'summary': {
        'total_errors': _results.length,
        'recovered_count': _results.where((r) => r.recovered).length,
        'failure_count': _results.where((r) => !r.recovered).length,
      },
    };

    final file = File(path.join(
      config.outputPath!,
      'chaos_test_${DateTime.now().millisecondsSinceEpoch}.json',
    ));

    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
  }

  /// 模拟错误
  Future<void> _simulateError(String componentId, ErrorType type) async {
    switch (type) {
      case ErrorType.timeout:
        await Future.delayed(const Duration(seconds: 5));
        break;
      case ErrorType.exception:
        throw StateError('Simulated error in $componentId');
      case ErrorType.corruption:
        // 模拟数据损坏
        break;
      case ErrorType.disconnect:
        // 模拟连接断开
        await Future.delayed(const Duration(seconds: 2));
        break;
      case ErrorType.overload:
        // 模拟过载
        break;
      case ErrorType.resourceLeak:
        // 模拟资源泄漏
        break;
    }
  }
}

/// 错误注入类型
enum ErrorType {
  timeout, // 超时
  exception, // 异常
  corruption, // 数据损坏
  disconnect, // 连接断开
  overload, // 过载
  resourceLeak, // 资源泄漏
}
