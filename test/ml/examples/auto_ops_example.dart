import 'dart:async';

import '../auto_ops.dart';

Future<void> main() async {
  print('启动自动运维示例...\n');

  final manager = AutoOpsManager(
    config: OperationConfig(
      actionTemplates: {
        '${OperationType.scale}_app': [
          'kubectl scale deployment {name} --replicas={replicas}',
          'kubectl rollout status deployment {name}',
        ],
        '${OperationType.optimize}_database': [
          'pg_reload_conf {instance}',
          'analyze verbose {database}',
          'vacuum analyze {tables}',
        ],
        '${OperationType.restart}_service': [
          'systemctl stop {service}',
          'sleep {delay}',
          'systemctl start {service}',
          'systemctl status {service}',
        ],
        '${OperationType.repair}_storage': [
          'umount {device}',
          'fsck -y {device}',
          'mount {device} {mountpoint}',
        ],
      },
      thresholds: {
        'cpu_usage': 80.0,
        'memory_usage': 85.0,
        'disk_usage': 90.0,
        'error_rate': 0.05,
      },
      cooldown: const Duration(minutes: 5),
      dryRun: true,
    ),
  );

  // 1. 创建扩容操作
  print('1. 创建扩容操作:');
  final scaleId = manager.createOperation(
    type: OperationType.scale,
    priority: OperationPriority.high,
    target: 'app',
    parameters: {
      'name': 'web-frontend',
      'replicas': '5',
    },
  );

  // 2. 创建数据库优化操作
  print('\n2. 创建数据库优化操作:');
  final optimizeId = manager.createOperation(
    type: OperationType.optimize,
    priority: OperationPriority.medium,
    target: 'database',
    parameters: {
      'instance': 'main-db',
      'database': 'production',
      'tables': 'users,orders,products',
    },
  );

  // 3. 创建服务重启操作
  print('\n3. 创建服务重启操作:');
  final restartId = manager.createOperation(
    type: OperationType.restart,
    priority: OperationPriority.critical,
    target: 'service',
    parameters: {
      'service': 'api-gateway',
      'delay': '5',
    },
  );

  // 4. 创建存储修复操作
  print('\n4. 创建存储修复操作:');
  final repairId = manager.createOperation(
    type: OperationType.repair,
    priority: OperationPriority.low,
    target: 'storage',
    parameters: {
      'device': '/dev/sda1',
      'mountpoint': '/data',
    },
  );

  // 查看操作队列
  print('\n5. 当前操作队列:');
  final queue = manager.getQueue();
  _printQueue(queue);

  // 取消一个操作
  print('\n6. 取消数据库优化操作:');
  final cancelled = manager.cancelOperation(optimizeId);
  print('取消${cancelled ? '成功' : '失败'}');

  // 执行操作
  print('\n7. 开始执行操作:');

  while (true) {
    final executed = await manager.executeNext();
    if (!executed) break;

    print('\n剩余操作:');
    _printQueue(manager.getQueue());

    await Future.delayed(const Duration(seconds: 1));
  }

  // 查看历史记录
  print('\n8. 执行历史:');
  final history = manager.getHistory();
  _printHistory(history);

  // 分析执行结果
  print('\n9. 执行结果分析:');
  _analyzeResults(history);

  print('\n示例完成!\n');
}

/// 分析执行结果
void _analyzeResults(List<Operation> history) {
  // 计算成功率
  final total = history.length;
  final successful =
      history.where((op) => op.status == OperationStatus.succeeded).length;
  final successRate = total > 0 ? successful / total * 100 : 0;

  // 统计各类操作
  final typeStats = <OperationType, int>{};
  for (final op in history) {
    typeStats[op.type] = (typeStats[op.type] ?? 0) + 1;
  }

  // 统计优先级分布
  final priorityStats = <OperationPriority, int>{};
  for (final op in history) {
    priorityStats[op.priority] = (priorityStats[op.priority] ?? 0) + 1;
  }

  print('''
统计信息:
- 总操作数: $total
- 成功操作: $successful
- 成功率: ${successRate.toStringAsFixed(2)}%

操作类型分布:
${typeStats.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

优先级分布:
${priorityStats.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}
''');

  // 分析失败操作
  final failures = history
      .where(
        (op) => op.status == OperationStatus.failed,
      )
      .toList();

  if (failures.isNotEmpty) {
    print('\n失败操作分析:');
    for (final op in failures) {
      print('''
${op.id}:
- 类型: ${op.type}
- 目标: ${op.target}
- 原因: ${op.result}
''');
    }
  }
}

/// 打印历史记录
void _printHistory(List<Operation> history) {
  if (history.isEmpty) {
    print('暂无历史记录');
    return;
  }

  for (final op in history) {
    print('''
操作 ${op.id}:
- 类型: ${op.type}
- 目标: ${op.target}
- 状态: ${op.status}
- 结果: ${op.result ?? '无'}
- 日志:
${op.logs.map((log) => '  $log').join('\n')}
''');
  }
}

/// 打印操作队列
void _printQueue(List<Operation> queue) {
  if (queue.isEmpty) {
    print('队列为空');
    return;
  }

  for (final op in queue) {
    print('''
- ID: ${op.id}
  类型: ${op.type}
  优先级: ${op.priority}
  目标: ${op.target}
  状态: ${op.status}
  动作数: ${op.actions.length}
''');
  }
}
