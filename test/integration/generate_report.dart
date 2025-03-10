import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

void main() async {
  final report = StringBuffer();
  report.writeln('Integration Test Report');
  report.writeln('=====================\n');

  try {
    // 收集测试结果
    final results = await _collectTestResults();
    final stats = _calculateStats(results);

    // 生成摘要
    report.writeln('Summary');
    report.writeln('-------');
    report.writeln('Total Tests: ${stats.total}');
    report.writeln('Passed: ${stats.passed}');
    report.writeln('Failed: ${stats.failed}');
    report.writeln('Skipped: ${stats.skipped}');
    report.writeln('Success Rate: ${stats.successRate.toStringAsFixed(2)}%');
    report.writeln('Total Duration: ${stats.totalDuration.inSeconds}s\n');

    // 详细测试结果
    report.writeln('Test Details');
    report.writeln('-----------');
    for (final result in results) {
      report.writeln('${result.suite} - ${result.name}');
      report.writeln('Status: ${result.passed ? "PASSED" : "FAILED"}');
      report.writeln('Duration: ${result.duration.inMilliseconds}ms');

      if (result.error != null) {
        report.writeln('Error: ${result.error}');
      }

      if (result.metadata != null) {
        report.writeln('Metadata:');
        result.metadata!.forEach((key, value) {
          report.writeln('  $key: $value');
        });
      }
      report.writeln('');
    }

    // 失败测试摘要
    final failures = results.where((r) => !r.passed).toList();
    if (failures.isNotEmpty) {
      report.writeln('Failed Tests');
      report.writeln('-----------');
      for (final failure in failures) {
        report.writeln('${failure.suite} - ${failure.name}');
        report.writeln('Error: ${failure.error}\n');
      }
    }

    // 保存报告
    final reportDir = Directory('test/reports');
    if (!reportDir.existsSync()) {
      reportDir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final reportFile = File(path.join(
      reportDir.path,
      'integration_test_report_$timestamp.txt',
    ));

    await reportFile.writeAsString(report.toString());

    // 保存JSON格式的结果
    final jsonReport = {
      'stats': stats.toJson(),
      'results': results.map((r) => r.toJson()).toList(),
      'timestamp': timestamp,
    };

    final jsonFile = File(path.join(
      reportDir.path,
      'integration_test_report_$timestamp.json',
    ));

    await jsonFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(jsonReport),
    );

    // 检查是否有失败的测试
    if (stats.failed > 0) {
      exit(1);
    }
  } catch (e, stack) {
    report.writeln('\nError generating report:');
    report.writeln(e);
    report.writeln(stack);
    exit(1);
  }
}

TestStats _calculateStats(List<TestResult> results) {
  final stats = TestStats();

  for (final result in results) {
    stats.total++;
    if (result.passed) {
      stats.passed++;
    } else {
      stats.failed++;
    }
    stats.totalDuration += result.duration;
  }

  return stats;
}

Future<List<TestResult>> _collectTestResults() async {
  final results = <TestResult>[];
  final resultDir = Directory('test/integration/results');

  if (!resultDir.existsSync()) {
    return results;
  }

  for (final file in resultDir.listSync()) {
    if (file is File && file.path.endsWith('.json')) {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      results.add(TestResult(
        name: json['name'] as String,
        suite: json['suite'] as String,
        passed: json['passed'] as bool,
        error: json['error'] as String?,
        duration: Duration(milliseconds: json['durationMs'] as int),
        metadata: json['metadata'] as Map<String, dynamic>?,
      ));
    }
  }

  return results;
}

class TestResult {
  final String name;
  final String suite;
  final bool passed;
  final String? error;
  final Duration duration;
  final Map<String, dynamic>? metadata;

  TestResult({
    required this.name,
    required this.suite,
    required this.passed,
    this.error,
    required this.duration,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'suite': suite,
        'passed': passed,
        'error': error,
        'durationMs': duration.inMilliseconds,
        'metadata': metadata,
      };
}

class TestStats {
  int total = 0;
  int passed = 0;
  int failed = 0;
  int skipped = 0;
  Duration totalDuration = Duration.zero;

  double get successRate => total == 0 ? 0 : (passed / total * 100);

  Map<String, dynamic> toJson() => {
        'total': total,
        'passed': passed,
        'failed': failed,
        'skipped': skipped,
        'successRate': successRate,
        'totalDurationMs': totalDuration.inMilliseconds,
      };
}
