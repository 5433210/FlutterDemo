import 'dart:async';
import 'dart:math';

import '../system_health.dart';

Future<void> main() async {
  print('启动系统健康评估示例...\n');

  final manager = SystemHealthManager(
    config: const HealthConfig(
      weights: [
        MetricWeight(
          metric: 'cpu_usage',
          weight: 0.3,
          correlations: {
            'memory_usage': CorrelationType.positive,
            'response_time': CorrelationType.positive,
          },
        ),
        MetricWeight(
          metric: 'memory_usage',
          weight: 0.25,
          correlations: {
            'disk_io': CorrelationType.positive,
          },
        ),
        MetricWeight(
          metric: 'response_time',
          weight: 0.2,
          correlations: {
            'request_count': CorrelationType.positive,
          },
        ),
        MetricWeight(
          metric: 'error_rate',
          weight: 0.15,
          correlations: {
            'response_time': CorrelationType.positive,
          },
        ),
        MetricWeight(
          metric: 'disk_io',
          weight: 0.1,
        ),
      ],
      thresholds: {
        'cpu_usage': 80.0, // %
        'memory_usage': 85.0, // %
        'response_time': 500.0, // ms
        'error_rate': 0.02, // 2%
        'disk_io': 70.0, // %
      },
      windowSize: Duration(minutes: 30),
      updateInterval: Duration(minutes: 1),
    ),
  );

  // 1. 生成正常数据
  print('1. 生成正常运行数据...\n');
  await _generateNormalData(manager);
  await _printHealthStatus(manager);

  // 2. 模拟负载增加
  print('\n2. 模拟负载增加...\n');
  await _generateHighLoadData(manager);
  await _printHealthStatus(manager);

  // 3. 模拟系统问题
  print('\n3. 模拟系统问题...\n');
  await _generateProblemData(manager);
  await _printHealthStatus(manager);

  // 4. 模拟恢复过程
  print('\n4. 模拟系统恢复...\n');
  await _generateRecoveryData(manager);
  await _printHealthStatus(manager);

  // 5. 分析相关性
  print('\n5. 分析指标相关性:');
  final correlations = manager.analyzeCorrelations();
  _printCorrelations(correlations);

  // 6. 健康度趋势
  print('\n6. 健康度趋势分析:');
  final history = manager.getHealthHistory(
    start: DateTime.now().subtract(const Duration(minutes: 30)),
  );
  _printHealthTrend(history);

  // 7. 异常指标分析
  print('\n7. 异常指标分析:');
  final anomalies = manager.getAnomalousMetrics();
  _printAnomalies(anomalies);

  manager.dispose();
  print('\n示例完成!\n');
}

/// 生成高负载数据
Future<void> _generateHighLoadData(SystemHealthManager manager) async {
  final random = Random();

  for (var i = 0; i < 10; i++) {
    manager.addMetric('cpu_usage', 75.0 + random.nextDouble() * 15.0);
    manager.addMetric('memory_usage', 80.0 + random.nextDouble() * 10.0);
    manager.addMetric('response_time', 400.0 + random.nextDouble() * 100.0);
    manager.addMetric('error_rate', 0.01 + random.nextDouble() * 0.01);
    manager.addMetric('disk_io', 60.0 + random.nextDouble() * 15.0);

    await Future.delayed(const Duration(seconds: 1));
  }
}

/// 生成正常运行数据
Future<void> _generateNormalData(SystemHealthManager manager) async {
  final random = Random();

  for (var i = 0; i < 10; i++) {
    manager.addMetric('cpu_usage', 50.0 + random.nextDouble() * 10.0);
    manager.addMetric('memory_usage', 60.0 + random.nextDouble() * 10.0);
    manager.addMetric('response_time', 200.0 + random.nextDouble() * 50.0);
    manager.addMetric('error_rate', 0.005 + random.nextDouble() * 0.005);
    manager.addMetric('disk_io', 40.0 + random.nextDouble() * 10.0);

    await Future.delayed(const Duration(seconds: 1));
  }
}

/// 生成问题数据
Future<void> _generateProblemData(SystemHealthManager manager) async {
  final random = Random();

  for (var i = 0; i < 10; i++) {
    manager.addMetric('cpu_usage', 90.0 + random.nextDouble() * 10.0);
    manager.addMetric('memory_usage', 95.0 + random.nextDouble() * 5.0);
    manager.addMetric('response_time', 800.0 + random.nextDouble() * 200.0);
    manager.addMetric('error_rate', 0.05 + random.nextDouble() * 0.05);
    manager.addMetric('disk_io', 85.0 + random.nextDouble() * 15.0);

    await Future.delayed(const Duration(seconds: 1));
  }
}

/// 生成恢复数据
Future<void> _generateRecoveryData(SystemHealthManager manager) async {
  final random = Random();

  for (var i = 0; i < 10; i++) {
    manager.addMetric('cpu_usage', 60.0 + random.nextDouble() * 10.0);
    manager.addMetric('memory_usage', 70.0 + random.nextDouble() * 10.0);
    manager.addMetric('response_time', 300.0 + random.nextDouble() * 50.0);
    manager.addMetric('error_rate', 0.008 + random.nextDouble() * 0.005);
    manager.addMetric('disk_io', 50.0 + random.nextDouble() * 10.0);

    await Future.delayed(const Duration(seconds: 1));
  }
}

/// 生成趋势图
String _generateTrendGraph(List<double> scores) {
  if (scores.isEmpty) return '';

  const width = 50;
  const height = 10;
  final min = scores.reduce((a, b) => a < b ? a : b);
  final max = scores.reduce((a, b) => a > b ? a : b);
  final range = max - min;

  final graph = List.generate(height, (_) => List.filled(width, ' '));

  for (var i = 0; i < scores.length && i < width; i++) {
    final normalizedValue = (scores[i] - min) / range;
    final y = ((height - 1) * (1 - normalizedValue)).round();
    graph[y][i] = '*';
  }

  return graph.map((row) => row.join('')).join('\n');
}

/// 打印异常指标
void _printAnomalies(Map<String, List<String>> anomalies) {
  if (anomalies.isEmpty) {
    print('当前无异常指标');
    return;
  }

  for (final entry in anomalies.entries) {
    print('''
${entry.key}:
${entry.value.map((i) => '- $i').join('\n')}
''');
  }
}

/// 打印相关性分析
void _printCorrelations(List<CorrelationAnalysis> correlations) {
  for (final correlation in correlations.where((c) => c.significance > 0.5)) {
    print('''
${correlation.metric1} <-> ${correlation.metric2}:
- 类型: ${correlation.type}
- 系数: ${correlation.coefficient.toStringAsFixed(2)}
- 显著性: ${(correlation.significance * 100).toStringAsFixed(2)}%
''');
  }
}

/// 打印健康状态
Future<void> _printHealthStatus(SystemHealthManager manager) async {
  final assessment = manager.calculateHealth();

  print('''
当前系统状态:
- 健康分数: ${assessment.score.toStringAsFixed(2)}
- 健康等级: ${assessment.level}
- 数据点数: ${assessment.metadata['totalMetrics']}

指标得分:
${assessment.metricScores.entries.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(2)}').join('\n')}

${assessment.issues.isNotEmpty ? '问题:\n${assessment.issues.map((i) => '- $i').join('\n')}' : '无重大问题'}
''');
}

/// 打印健康度趋势
void _printHealthTrend(List<HealthAssessment> history) {
  if (history.isEmpty) {
    print('暂无历史数据');
    return;
  }

  final scores = history.map((h) => h.score).toList();
  final avg = scores.reduce((a, b) => a + b) / scores.length;
  final min = scores.reduce((a, b) => a < b ? a : b);
  final max = scores.reduce((a, b) => a > b ? a : b);

  print('''
趋势统计:
- 平均分: ${avg.toStringAsFixed(2)}
- 最低分: ${min.toStringAsFixed(2)}
- 最高分: ${max.toStringAsFixed(2)}
- 样本数: ${history.length}

健康度变化:
${_generateTrendGraph(scores)}
''');
}
