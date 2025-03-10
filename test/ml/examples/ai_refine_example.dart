import 'dart:async';

import '../ai_knowledge_refiner.dart';

Future<void> main() async {
  print('启动AI知识提炼示例...\n');

  final refiner = AIKnowledgeRefiner(
    config: const AIConfig(
      provider: AIProvider.openAI,
      modelName: 'gpt-4',
      apiKey: 'your-api-key',
      parameters: {
        'temperature': 0.7,
        'max_tokens': 1000,
      },
    ),
  );

  // 1. 提炼单条知识
  print('1. 提炼运维知识:');
  final result = await refiner.refineKnowledge(
    content: '''
在Kubernetes集群中处理Pod崩溃:
1. 检查pod状态和日志
2. 分析容器退出码
3. 查看节点状态
4. 调整资源限制
''',
    task: AITaskType.enhance,
    context: {
      'environment': 'production',
      'priority': 'high',
    },
  );

  print('''
提炼结果:
${result.refinedContent}

改进:
${result.improvements.map((i) => '- $i').join('\n')}

建议:
${result.suggestions.map((s) => '- $s').join('\n')}

质量评分:
${result.scores.entries.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(2)}').join('\n')}
''');

  // 2. 批量提炼
  print('\n2. 批量提炼知识:');
  final contents = [
    '''
MySQL性能优化步骤:
1. 优化查询语句
2. 添加合适索引
3. 调整配置参数
''',
    '''
Redis缓存策略:
1. 设置过期时间
2. 使用LRU策略
3. 预热缓存
''',
    '''
Nginx负载均衡配置:
1. 选择算法
2. 设置权重
3. 健康检查
''',
  ];

  final batchResults = await refiner.refineBatch(
    contents: contents,
    task: AITaskType.enhance,
    parallel: true,
  );

  print('\n批量处理结果:');
  for (var i = 0; i < batchResults.length; i++) {
    final r = batchResults[i];
    print('''
知识 ${i + 1}:
${r.refinedContent}
改进数: ${r.improvements.length}
建议数: ${r.suggestions.length}
平均分: ${_calculateAverageScore(r.scores)}
''');
  }

  // 3. 持续优化
  print('\n3. 启动持续优化:');
  final controller = StreamController<String>();

  refiner.startContinuousRefinement(
    contentStream: controller.stream,
    task: AITaskType.enhance,
    interval: const Duration(seconds: 10),
    batchSize: 2,
  );

  // 模拟新知识流入
  print('模拟知识流入...\n');

  await Future.delayed(const Duration(seconds: 1));
  controller.add('''
Docker容器故障排查:
1. 检查容器状态
2. 查看容器日志
3. 分析资源使用
''');

  await Future.delayed(const Duration(seconds: 2));
  controller.add('''
服务网格配置:
1. 部署控制平面
2. 注入Sidecar
3. 配置路由规则
''');

  await Future.delayed(const Duration(seconds: 15));

  // 4. 不同任务类型
  print('\n4. 测试不同任务类型:');

  final tasks = [
    AITaskType.summarize,
    AITaskType.validate,
    AITaskType.recommend,
    AITaskType.categorize,
  ];

  const content = '''
Elasticsearch集群运维:
1. 节点角色规划
2. 索引生命周期
3. 快照备份策略
4. 监控告警配置
5. 性能优化方案
''';

  print('\n原始内容:\n$content\n');

  for (final task in tasks) {
    print('执行任务: $task');
    final r = await refiner.refineKnowledge(
      content: content,
      task: task,
    );

    print('''
结果:
${r.refinedContent}
改进: ${r.improvements.length}个
建议: ${r.suggestions.length}个
分数: ${_calculateAverageScore(r.scores)}
''');
  }

  // 清理资源
  await controller.close();
  refiner.dispose();
  print('\n示例完成!\n');
}

/// 计算平均分数
double _calculateAverageScore(Map<String, double> scores) {
  if (scores.isEmpty) return 0.0;
  return scores.values.reduce((a, b) => a + b) / scores.length;
}
