import 'dart:async';

import '../ops_knowledge.dart';

Future<void> main() async {
  print('启动运维知识库示例...\n');

  final kb = OpsKnowledgeBase(
    config: const KnowledgeConfig(
      learningWindow: Duration(days: 7),
      minSamplesForLearning: 5,
      minEffectivenessThreshold: 0.8,
      autoLearn: true,
    ),
  );

  // 1. 添加最佳实践
  print('1. 添加最佳实践知识:');
  final bestPracticeId = kb.addKnowledge(
    type: KnowledgeType.bestPractice,
    title: 'Kubernetes Pod 资源配置最佳实践',
    description: '''
为保证服务稳定性，建议:
1. 始终设置资源限制 (resources.limits)
2. 合理设置资源请求 (resources.requests)
3. 设置合适的健康检查
4. 使用 Pod 反亲和性避免单点
''',
    tags: ['kubernetes', 'pod', 'resources', 'configuration'],
    confidence: ConfidenceLevel.proven,
  );

  // 2. 添加故障诊断
  print('\n2. 添加故障诊断知识:');
  final diagnosticId = kb.addKnowledge(
    type: KnowledgeType.diagnostic,
    title: 'MySQL 慢查询诊断方法',
    description: '''
诊断步骤:
1. 检查 slow_query_log
2. 使用 EXPLAIN 分析执行计划
3. 检查索引使用情况
4. 验证连接池配置
5. 监控 InnoDB 指标
''',
    tags: ['mysql', 'performance', 'slow-query', 'troubleshooting'],
    confidence: ConfidenceLevel.reliable,
  );

  // 3. 添加优化建议
  print('\n3. 添加性能优化建议:');
  final optimizationId = kb.addKnowledge(
    type: KnowledgeType.optimization,
    title: 'Redis 性能优化指南',
    description: '''
优化建议:
1. 使用适当的数据结构
2. 设置合理的过期时间
3. 避免大键值对
4. 使用管道批量操作
5. 监控内存碎片
''',
    tags: ['redis', 'performance', 'optimization', 'memory'],
    confidence: ConfidenceLevel.proven,
  );

  // 4. 添加预防措施
  print('\n4. 添加预防措施:');
  final preventionId = kb.addKnowledge(
    type: KnowledgeType.prevention,
    title: '防止服务雪崩策略',
    description: '''
预防措施:
1. 实现熔断机制
2. 使用降级策略
3. 设置请求超时
4. 使用舱壁模式
5. 实施限流措施
''',
    tags: ['reliability', 'circuit-breaker', 'fallback', 'timeout'],
    confidence: ConfidenceLevel.reliable,
  );

  // 5. 记录使用情况
  print('\n5. 记录知识应用情况:');

  kb.recordUsage(
    bestPracticeId,
    effective: true,
    feedback: '成功优化了资源利用率',
  );

  kb.recordUsage(
    diagnosticId,
    effective: true,
    feedback: '快速定位了性能问题',
  );

  kb.recordUsage(
    optimizationId,
    effective: true,
    feedback: '缓存命中率提升了30%',
  );

  kb.recordUsage(
    preventionId,
    effective: true,
    feedback: '成功预防了连锁故障',
  );

  // 6. 搜索相关知识
  print('\n6. 搜索性能相关知识:');
  final results = kb.findKnowledge(
    query: 'performance',
    minConfidence: ConfidenceLevel.reliable,
  );

  print('\n找到 ${results.length} 条相关知识:');
  for (final item in results) {
    print('''
- ${item.title}
  类型: ${item.type}
  可信度: ${item.confidence}
  使用次数: ${item.usageCount}
''');
  }

  // 7. 获取相关知识
  print('\n7. 获取相关知识:');
  final related = kb.getRelatedKnowledge(diagnosticId);

  print('\n找到 ${related.length} 条相关知识:');
  for (final item in related) {
    print('- ${item.title} (${item.type})');
  }

  // 8. 分析知识库
  print('\n8. 知识库分析:');
  final analysis = kb.analyzeKnowledge();

  print('''
统计信息:
- 总条目: ${analysis['totalItems']}
- 总使用次数: ${analysis['totalUsage']}
- 有效条目数: ${analysis['effectiveCount']}
- 有效率: ${(analysis['effectiveRate'] * 100).toStringAsFixed(2)}%

知识类型分布:
${(analysis['typeStats'] as Map<String, int>).entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

可信度分布:
${(analysis['confidenceStats'] as Map<String, int>).entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

热门标签:
${(analysis['topTags'] as List).map((e) => '- ${e.key}: ${e.value}次').join('\n')}
''');

  // 9. 更新知识
  print('\n9. 更新知识:');
  final updated = kb.updateKnowledge(
    optimizationId,
    description: '''
优化建议:
1. 使用适当的数据结构
2. 设置合理的过期时间
3. 避免大键值对
4. 使用管道批量操作
5. 监控内存碎片
6. 【新增】使用Redis集群分担负载
7. 【新增】定期清理过期键
''',
    confidence: ConfidenceLevel.proven,
  );

  print('更新${updated ? '成功' : '失败'}');

  // 10. 删除知识
  print('\n10. 删除过时知识:');
  final deleted = kb.deleteKnowledge('old-knowledge-id');
  print('删除${deleted ? '成功' : '失败'}');

  kb.dispose();
  print('\n示例完成!\n');
}
