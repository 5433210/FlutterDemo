import 'dart:async';

import 'alert_notifier.dart';

/// 测试用例
class TestCase {
  final String name;
  final Future<void> Function() testFn;
  int failures = 0;

  TestCase({
    required this.name,
    required this.testFn,
  });
}

/// 测试监控器
class TestMonitor {
  final AlertNotifier notifier;
  final TestMonitorConfig config;
  final Map<String, TestCase> _tests = {};
  Timer? _checkTimer;
  bool _running = false;

  TestMonitor({
    required this.notifier,
    TestMonitorConfig? config,
  }) : config = config ?? const TestMonitorConfig();

  /// 添加测试用例
  void addTest(String name, Future<void> Function() test) {
    if (_running) {
      throw StateError('Cannot add tests while monitor is running');
    }
    _tests[name] = TestCase(name: name, testFn: test);
  }

  /// 清理资源
  void dispose() {
    stop();
    _tests.clear();
  }

  /// 获取测试状态
  Map<String, dynamic> getStatus() {
    return {
      'running': _running,
      'test_count': _tests.length,
      'failures': _tests.values
          .where((test) => test.failures > 0)
          .map((test) => {
                'name': test.name,
                'failures': test.failures,
              })
          .toList(),
    };
  }

  /// 启动监控
  Future<void> start() async {
    if (_running) return;
    _running = true;

    notifier.notify(AlertBuilder()
        .message('测试监控启动')
        .level(AlertLevel.info)
        .addData('test_count', _tests.length)
        .build());

    _startChecks();
  }

  /// 停止监控
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _checkTimer?.cancel();

    notifier.notify(
        AlertBuilder().message('测试监控停止').level(AlertLevel.info).build());
  }

  /// 运行检查
  Future<void> _runChecks() async {
    for (final test in _tests.values) {
      if (!_running) break;
      await _runTest(test);
    }
  }

  /// 运行单个测试
  Future<void> _runTest(TestCase test) async {
    try {
      await test.testFn();

      if (test.failures > 0) {
        notifier.notify(AlertBuilder()
            .message('测试恢复: ${test.name}')
            .level(AlertLevel.info)
            .addData('previous_failures', test.failures)
            .build());
        test.failures = 0;
      }
    } catch (error, stack) {
      test.failures++;

      final level = test.failures >= config.maxFailures
          ? config.errorLevel
          : config.warningLevel;

      notifier.notify(AlertBuilder()
          .message('测试失败: ${test.name}')
          .level(level)
          .addData('error', error.toString())
          .addData('stack_trace', stack.toString())
          .addData('failure_count', test.failures)
          .build());
    }
  }

  /// 开始定期检查
  void _startChecks() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(config.checkInterval, (_) => _runChecks());
  }
}

/// 测试监控器配置
class TestMonitorConfig {
  final Duration checkInterval;
  final int maxFailures;
  final AlertLevel warningLevel;
  final AlertLevel errorLevel;

  const TestMonitorConfig({
    this.checkInterval = const Duration(seconds: 1),
    this.maxFailures = 3,
    this.warningLevel = AlertLevel.warning,
    this.errorLevel = AlertLevel.error,
  });
}
