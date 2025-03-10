import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../utils/monitor_analyzer.dart';
import '../utils/monitor_server.dart';

void main() async {
  // 创建分析器
  final analyzer = MonitorAnalyzer(
    config: const MonitorConfig(
      windowSize: Duration(hours: 1),
      enableTrending: true,
    ),
  );

  // 创建服务器
  final server = MonitorServer(
    analyzer: analyzer,
    config: const ServerConfig(
      host: 'localhost',
      port: 8080,
      enableCors: true,
      refreshInterval: Duration(seconds: 10),
      headers: {
        'Server': 'MonitorServer/1.0',
        'X-Powered-By': 'Dart',
      },
    ),
  );

  try {
    // 定义监控指标
    analyzer.defineMetric(const Metric(
      name: 'cpu_usage',
      unit: '%',
      description: 'CPU使用率',
    ));

    analyzer.defineMetric(const Metric(
      name: 'memory_usage',
      unit: 'MB',
      description: '内存使用量',
    ));

    analyzer.defineMetric(const Metric(
      name: 'disk_usage',
      unit: 'GB',
      description: '磁盘使用量',
    ));

    // 设置阈值
    analyzer.setThreshold(
      'cpu_usage',
      warning: 70,
      error: 90,
    );

    analyzer.setThreshold(
      'memory_usage',
      warning: 4096, // 4GB
      error: 7168, // 7GB
    );

    analyzer.setThreshold(
      'disk_usage',
      warning: 400, // 400GB
      error: 450, // 450GB
    );

    // 定期添加模拟数据
    Timer.periodic(const Duration(seconds: 5), (_) {
      _addSampleData(analyzer);
    });

    // 启动服务器
    print('启动监控服务器...');
    await server.start();

    // 打印访问说明
    print('\n监控端点:');
    print('- 指标数据: http://localhost:8080/metrics');
    print('- JSON格式: http://localhost:8080/metrics?format=json');
    print('- Prometheus格式: http://localhost:8080/metrics?format=prometheus');
    print('- 健康检查: http://localhost:8080/health');

    print('\n按 Enter 键停止服务器...');
    await stdin.first;
  } finally {
    await server.stop();
  }
}

/// 添加示例数据
void _addSampleData(MonitorAnalyzer analyzer) {
  final now = DateTime.now();
  final random = Random();

  // CPU使用率 (40-100%)
  analyzer.addDataPoint(
    'cpu_usage',
    40 + random.nextDouble() * 60,
    now,
  );

  // 内存使用量 (2-8GB)
  analyzer.addDataPoint(
    'memory_usage',
    2048 + random.nextDouble() * 6144,
    now,
  );

  // 磁盘使用量 (300-500GB)
  analyzer.addDataPoint(
    'disk_usage',
    300 + random.nextDouble() * 200,
    now,
  );
}

/// 格式化指标值
String _formatMetric(String metric, double value) {
  switch (metric) {
    case 'cpu_usage':
      return '${value.toStringAsFixed(1)}%';
    case 'memory_usage':
      return '${value.toStringAsFixed(0)} MB';
    case 'disk_usage':
      return '${value.toStringAsFixed(1)} GB';
    default:
      return value.toString();
  }
}
