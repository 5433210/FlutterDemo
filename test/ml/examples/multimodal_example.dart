import 'dart:async';
import 'dart:typed_data';

import '../multimodal_analyzer.dart';

Future<void> main() async {
  print('启动多模态分析示例...\n');

  final analyzer = MultiModalAnalyzer(
    config: const MultiModalConfig(
      enabledTypes: {
        DataType.text: true,
        DataType.image: true,
        DataType.metric: true,
        DataType.log: true,
        DataType.trace: true,
      },
      maxSamples: {
        DataType.text: 1000,
        DataType.image: 100,
        DataType.metric: 10000,
        DataType.log: 5000,
        DataType.trace: 1000,
      },
      analysisWindow: Duration(minutes: 30),
      autoCorrelate: true,
    ),
  );

  // 1. 添加文本数据
  print('1. 添加错误日志:');
  analyzer.addSample(DataSample(
    id: 'error_log_1',
    timestamp: DateTime.now(),
    type: DataType.text,
    format: DataFormat.raw,
    data: '''
[ERROR] Connection refused to database
Stack trace:
  at Database.connect (/app/db.js:45)
  at Server.start (/app/server.js:23)
Root cause: Network timeout
''',
    metadata: {
      'service': 'user-api',
      'severity': 'error',
      'component': 'database',
    },
  ));

  // 2. 添加指标数据
  print('\n2. 添加性能指标:');
  analyzer.addSample(DataSample(
    id: 'metrics_1',
    timestamp: DateTime.now(),
    type: DataType.metric,
    format: DataFormat.raw,
    data: {
      'cpu_usage': 85.5,
      'memory_used': 7.2e9,
      'disk_io': 12000.0,
      'network_in': 50.2e6,
      'network_out': 30.1e6,
    },
    metadata: {
      'host': 'prod-db-01',
      'cluster': 'production',
    },
  ));

  // 3. 添加链路数据
  print('\n3. 添加调用链路:');
  analyzer.addSample(DataSample(
    id: 'trace_1',
    timestamp: DateTime.now(),
    type: DataType.trace,
    format: DataFormat.raw,
    data: {
      'trace_id': 'abc123',
      'spans': [
        {
          'id': 'span1',
          'name': 'http.request',
          'duration': 1500,
        },
        {
          'id': 'span2',
          'name': 'db.query',
          'duration': 1000,
          'error': true,
        },
      ],
    },
    metadata: {
      'service': 'user-api',
      'endpoint': '/api/users',
    },
  ));

  // 4. 添加图像数据
  print('\n4. 添加监控截图:');
  analyzer.addSample(DataSample(
    id: 'image_1',
    timestamp: DateTime.now(),
    type: DataType.image,
    format: DataFormat.raw,
    data: Uint8List(1024), // 模拟图像数据
    metadata: {
      'type': 'dashboard',
      'resolution': '1920x1080',
    },
  ));

  // 5. 添加日志数据
  print('\n5. 添加系统日志:');
  analyzer.addSample(DataSample(
    id: 'log_1',
    timestamp: DateTime.now(),
    type: DataType.log,
    format: DataFormat.raw,
    data: '''
[2025-03-10 03:44:20] [INFO] Server started
[2025-03-10 03:44:21] [WARN] High memory usage detected
[2025-03-10 03:44:22] [ERROR] Database connection failed
''',
    metadata: {
      'source': 'system.log',
      'facility': 'syslog',
    },
  ));

  // 6. 执行分析
  print('\n6. 执行多模态分析:');
  final result = await analyzer.analyze();

  // 7. 打印分析结果
  print('''
分析结果:
- 样本数: ${result.samples.length}
- 关联数: ${result.correlations.length}
- 洞察数: ${result.insights.length}

评分:
${result.scores.entries.map((e) => '- ${e.key}: ${e.value.toStringAsFixed(2)}').join('\n')}

关联发现:''');

  for (final correlation in result.correlations) {
    print('''
- 类型: ${correlation.type}
  强度: ${correlation.strength.toStringAsFixed(2)}
  样本数: ${correlation.samples.length}
  证据: ${correlation.evidence}
''');
  }

  print('\n发现的洞察:');
  for (final entry in result.insights.entries) {
    print('''
${entry.key}:
${entry.value.map((i) => '- $i').join('\n')}
''');
  }

  // 8. 模拟实时数据流
  print('\n8. 模拟实时数据流:');

  for (var i = 0; i < 5; i++) {
    // 添加实时指标
    analyzer.addSample(DataSample(
      id: 'metric_rt_$i',
      timestamp: DateTime.now(),
      type: DataType.metric,
      format: DataFormat.raw,
      data: {
        'cpu_usage': 70.0 + i * 5,
        'memory_used': 6.5e9 + i * 1e8,
        'response_time': 200.0 + i * 50,
      },
      metadata: {'real_time': true},
    ));

    // 添加实时日志
    analyzer.addSample(DataSample(
      id: 'log_rt_$i',
      timestamp: DateTime.now(),
      type: DataType.log,
      format: DataFormat.raw,
      data: '[INFO] Processing batch $i',
      metadata: {'real_time': true},
    ));

    await Future.delayed(const Duration(seconds: 1));
  }

  // 9. 最终分析
  print('\n9. 执行最终分析:');
  final finalResult = await analyzer.analyze();

  print('''
最终结果:
- 总样本数: ${finalResult.samples.length}
- 发现关联: ${finalResult.correlations.length}
- 生成洞察: ${finalResult.insights.length}
- 覆盖率: ${(finalResult.scores['coverage'] ?? 0.0 * 100).toStringAsFixed(2)}%
- 置信度: ${(finalResult.scores['confidence'] ?? 0.0 * 100).toStringAsFixed(2)}%
''');

  analyzer.dispose();
  print('\n示例完成!\n');
}
