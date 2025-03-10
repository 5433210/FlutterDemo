import 'dart:async';

import '../slo_analyzer.dart';

Future<void> main() async {
  print('启动SLO监控示例...\n');

  final analyzer = SLOAnalyzer(
    config: const SLOConfig(
      objectives: {
        'api_availability': 0.995,
        'api_latency': 0.99,
        'database_availability': 0.9999,
        'cache_hit_rate': 0.95,
      },
      windows: {
        'api_availability': Duration(hours: 24),
        'api_latency': Duration(minutes: 5),
        'database_availability': Duration(hours: 1),
        'cache_hit_rate': Duration(minutes: 15),
      },
      weights: {
        SLOType.availability: 1.0,
        SLOType.latency: 0.8,
        SLOType.throughput: 0.7,
        SLOType.errorRate: 0.9,
        SLOType.saturation: 0.6,
      },
      windowType: WindowType.sliding,
      updateInterval: Duration(minutes: 1),
      errorBudget: 1000,
    ),
  );

  // 1. 记录API可用性数据
  print('1. 记录API可用性:');
  analyzer.recordEvent(SLOEvent(
    serviceId: 'api-gateway',
    type: SLOType.availability,
    value: 1.0,
    success: true,
    metadata: {
      'endpoint': '/users',
      'method': 'GET',
    },
    timestamp: DateTime.now(),
  ));

  // 2. 记录数据库延迟
  print('\n2. 记录数据库延迟:');
  analyzer.recordEvent(SLOEvent(
    serviceId: 'main-database',
    type: SLOType.latency,
    value: 150.0,
    success: true,
    metadata: {
      'query_type': 'select',
      'table': 'users',
    },
    timestamp: DateTime.now(),
  ));

  // 3. 记录缓存命中
  print('\n3. 记录缓存命中:');
  analyzer.recordEvent(SLOEvent(
    serviceId: 'redis-cache',
    type: SLOType.throughput,
    value: 0.92,
    success: true,
    metadata: {
      'operation': 'get',
      'key_pattern': 'user:*',
    },
    timestamp: DateTime.now(),
  ));

  // 4. 评估服务SLO
  print('\n4. 评估API网关SLO:');
  final assessment = await analyzer.assessService('api-gateway');

  print('''
评估结果:
- 状态: ${assessment.status}
- 达成率:
${assessment.compliance.entries.map((e) => '  ${e.key}: ${(e.value * 100).toStringAsFixed(2)}%').join('\n')}
- 剩余预算: ${assessment.remainingBudget}
- 指标:
${assessment.metrics.entries.map((e) => '  ${e.key}: ${e.value}').join('\n')}
''');

  // 5. 模拟延迟问题
  print('\n5. 模拟延迟问题:');
  for (var i = 0; i < 5; i++) {
    analyzer.recordEvent(SLOEvent(
      serviceId: 'api-gateway',
      type: SLOType.latency,
      value: 200.0 + i * 100,
      success: i < 3,
      metadata: {
        'endpoint': '/orders',
        'method': 'POST',
        'error': i >= 3 ? 'timeout' : null,
      },
      timestamp: DateTime.now(),
    ));

    await Future.delayed(const Duration(seconds: 1));
  }

  // 6. 预测违约风险
  print('\n6. 预测违约风险:');
  final alerts = await analyzer.predictBurnRate('api-gateway');

  if (alerts.isEmpty) {
    print('未发现显著风险');
  } else {
    print('发现 ${alerts.length} 个风险:');
    for (final alert in alerts) {
      print('''
类型: ${alert.type}
- 当前消耗率: ${(alert.currentRate * 100).toStringAsFixed(2)}%
- 预测消耗率: ${(alert.predictedRate * 100).toStringAsFixed(2)}%
- 预计耗尽时间: ${alert.timeToExhaustion.inHours}小时
- 建议:
${alert.recommendations.map((r) => '  - $r').join('\n')}
''');
    }
  }

  // 7. 查看历史评估
  print('\n7. 查看历史评估:');
  final history = analyzer.getAssessmentHistory(
    'api-gateway',
    start: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  print('找到 ${history.length} 条历史评估:');
  for (final assessment in history) {
    print('''
时间: ${assessment.timestamp}
状态: ${assessment.status}
达成率: ${assessment.compliance.entries.map((e) => '${e.key}: ${(e.value * 100).toStringAsFixed(2)}%').join(', ')}
''');
  }

  // 8. 模拟多服务场景
  print('\n8. 模拟多服务场景:');
  final services = {
    'api-gateway': SLOType.availability,
    'main-database': SLOType.latency,
    'redis-cache': SLOType.throughput,
    'auth-service': SLOType.errorRate,
    'file-storage': SLOType.saturation,
  };

  for (final entry in services.entries) {
    final serviceId = entry.key;
    final type = entry.value;

    // 记录正常事件
    analyzer.recordEvent(SLOEvent(
      serviceId: serviceId,
      type: type,
      value: 0.95,
      success: true,
      metadata: {'scenario': 'normal'},
      timestamp: DateTime.now(),
    ));

    // 记录异常事件
    analyzer.recordEvent(SLOEvent(
      serviceId: serviceId,
      type: type,
      value: 0.7,
      success: false,
      metadata: {'scenario': 'degraded'},
      timestamp: DateTime.now(),
    ));

    final assessment = await analyzer.assessService(serviceId);
    print('''
$serviceId:
- 状态: ${assessment.status}
- 达成率: ${assessment.compliance[type] ?? 0.0}
- 违规: ${assessment.violations[type]?.join(', ') ?? '无'}
''');
  }

  // 9. 模拟长期趋势
  print('\n9. 模拟数据库性能趋势:');
  final now = DateTime.now();

  for (var i = 0; i < 10; i++) {
    final timestamp = now.subtract(Duration(minutes: 10 - i));
    final deteriorating = i > 5; // 后半段性能下降

    analyzer.recordEvent(SLOEvent(
      serviceId: 'main-database',
      type: SLOType.latency, // Changed from performance to latency
      value: deteriorating ? 200.0 + i * 50 : 150.0,
      success: !deteriorating,
      metadata: {
        'trend': deteriorating ? 'deteriorating' : 'stable',
        'load': 'normal',
      },
      timestamp: timestamp,
    ));
  }

  final burnAlerts = await analyzer.predictBurnRate('main-database');
  print('\n性能趋势分析:');
  for (final alert in burnAlerts) {
    print('''
预警:
- 当前消耗率: ${(alert.currentRate * 100).toStringAsFixed(2)}%
- 预测消耗率: ${(alert.predictedRate * 100).toStringAsFixed(2)}%
- 建议处理时间: ${alert.timeToExhaustion.inHours}小时
- 建议:
${alert.recommendations.map((r) => '  - $r').join('\n')}
''');
  }

  analyzer.dispose();
  print('\n示例完成!\n');
}
