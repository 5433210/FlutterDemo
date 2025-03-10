import 'dart:async';
import 'dart:math';

import '../impact_analyzer.dart';

Future<void> main() async {
  print('启动影响分析示例...\n');

  final analyzer = ImpactAnalyzer(
    config: const ImpactConfig(
      componentWeights: {
        'frontend': 0.8,
        'api-gateway': 0.9,
        'auth-service': 1.0,
        'user-service': 0.9,
        'order-service': 0.8,
        'payment-service': 1.0,
        'database': 1.0,
        'cache': 0.8,
        'message-queue': 0.9,
        'storage': 0.7,
      },
      typeWeights: {
        ImpactType.performance: 0.8,
        ImpactType.reliability: 1.0,
        ImpactType.security: 1.0,
        ImpactType.resource: 0.7,
        ImpactType.business: 0.9,
      },
      analysisWindow: Duration(hours: 1),
      propagationThreshold: 0.3,
      maxPropagationDepth: 5,
      enablePrediction: true,
    ),
  );

  // 1. 注册系统依赖关系
  print('1. 注册系统依赖关系:');
  _registerDependencies(analyzer);

  // 2. 记录数据库性能问题
  print('\n2. 记录数据库性能问题:');
  analyzer.recordImpact(ComponentImpact(
    componentId: 'database',
    impacts: {
      ImpactType.performance: 0.8,
      ImpactType.reliability: 0.6,
      ImpactType.resource: 0.7,
    },
    level: ImpactLevel.high,
    metrics: {
      'latency': 500.0,
      'error_rate': 0.05,
      'connection_count': 850,
    },
    timestamp: DateTime.now(),
  ));

  // 3. 分析影响范围
  print('\n3. 分析数据库问题影响:');
  final result = await analyzer.analyzeImpact(
    'database',
    types: {
      ImpactType.performance,
      ImpactType.reliability,
    },
  );

  print('''
分析结果:
- 受影响组件: ${result.impacts.length}
- 传播路径: ${result.propagations.length}
- 缓解建议: ${result.mitigations.length}
''');

  // 4. 检查各组件影响
  print('\n4. 组件影响详情:');
  for (final impact in result.impacts) {
    print('''
${impact.componentId}:
- 级别: ${impact.level}
- 影响:
${impact.impacts.entries.map((e) => '  ${e.key}: ${(e.value * 100).toStringAsFixed(1)}%').join('\n')}
- 特征: ${impact.metrics}
''');
  }

  // 5. 查看传播路径
  print('\n5. 影响传播路径:');
  for (final path in result.propagations) {
    print('''
${path.sourceId} -> ${path.targetId}:
- 方向: ${path.direction}
- 概率: ${(path.probability * 100).toStringAsFixed(1)}%
- 依赖: ${path.dependencies}
''');
  }

  // 6. 查看缓解建议
  print('\n6. 缓解建议:');
  for (final entry in result.mitigations.entries) {
    print('''
${entry.key}:
${entry.value.map((s) => '- $s').join('\n')}
''');
  }

  // 7. 预测消息队列故障影响
  print('\n7. 预测消息队列故障影响:');
  final prediction = await analyzer.predictImpact(
    'message-queue',
    {
      ImpactType.reliability: 0.9,
      ImpactType.performance: 0.7,
      ImpactType.business: 0.8,
    },
  );

  print('''
预测结果:
- 影响范围: ${prediction.impacts.length} 个组件
- 风险评分:
${prediction.risks.entries.map((e) => '  ${e.key}: ${(e.value * 100).toStringAsFixed(1)}%').join('\n')}
''');

  // 8. 查看历史影响
  print('\n8. 数据库历史影响:');
  final history = analyzer.getImpactHistory(
    'database',
    start: DateTime.now().subtract(const Duration(minutes: 30)),
  );

  print('发现 ${history.length} 条历史记录:');
  for (final impact in history) {
    print('''
时间: ${impact.timestamp}
级别: ${impact.level}
影响: ${impact.impacts.length} 个指标
''');
  }

  // 9. 模拟连续影响
  print('\n9. 模拟服务连续故障:');

  for (var i = 0; i < 3; i++) {
    // 记录auth服务异常
    analyzer.recordImpact(ComponentImpact(
      componentId: 'auth-service',
      impacts: {
        ImpactType.reliability: 0.5 + i * 0.2,
        ImpactType.security: 0.3 + i * 0.1,
        ImpactType.business: 0.4 + i * 0.2,
      },
      level: i == 2 ? ImpactLevel.critical : ImpactLevel.high,
      metrics: {
        'error_rate': 0.1 + i * 0.05,
        'latency': 200.0 + i * 100.0,
      },
      timestamp: DateTime.now(),
    ));

    final analysis = await analyzer.analyzeImpact('auth-service');

    print('''
第 ${i + 1} 次分析:
- 影响组件数: ${analysis.impacts.length}
- 最高风险: ${analysis.risks.values.reduce((a, b) => max(a, b))}
- 建议数: ${analysis.mitigations.values.fold(0, (a, b) => a + b.length)}
''');

    await Future.delayed(const Duration(seconds: 1));
  }

  analyzer.dispose();
  print('\n示例完成!\n');
}

/// 注册系统依赖关系
void _registerDependencies(ImpactAnalyzer analyzer) {
  // 前端依赖
  analyzer.registerDependency('frontend', 'api-gateway');

  // API网关依赖
  analyzer.registerDependency('api-gateway', 'auth-service');
  analyzer.registerDependency('api-gateway', 'user-service');
  analyzer.registerDependency('api-gateway', 'order-service');
  analyzer.registerDependency('api-gateway', 'payment-service');

  // 认证服务依赖
  analyzer.registerDependency('auth-service', 'database');
  analyzer.registerDependency('auth-service', 'cache');

  // 用户服务依赖
  analyzer.registerDependency('user-service', 'database');
  analyzer.registerDependency('user-service', 'cache');
  analyzer.registerDependency('user-service', 'storage');

  // 订单服务依赖
  analyzer.registerDependency('order-service', 'database');
  analyzer.registerDependency('order-service', 'message-queue');

  // 支付服务依赖
  analyzer.registerDependency('payment-service', 'database');
  analyzer.registerDependency('payment-service', 'message-queue');

  print('''
注册依赖关系:
- 前端 -> API网关
- API网关 -> [认证服务, 用户服务, 订单服务, 支付服务]
- 认证服务 -> [数据库, 缓存]
- 用户服务 -> [数据库, 缓存, 存储]
- 订单服务 -> [数据库, 消息队列]
- 支付服务 -> [数据库, 消息队列]
''');
}
