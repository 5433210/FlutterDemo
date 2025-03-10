import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../utils/monitor_analyzer.dart';
import '../utils/monitor_server.dart';

void main() async {
  // 创建分析器
  final analyzer = MonitorAnalyzer(
    config: const MonitorConfig(
      windowSize: Duration(hours: 24),
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
      refreshInterval: Duration(seconds: 5),
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

    analyzer.defineMetric(const Metric(
      name: 'network_in',
      unit: 'KB/s',
      description: '网络入流量',
    ));

    analyzer.defineMetric(const Metric(
      name: 'network_out',
      unit: 'KB/s',
      description: '网络出流量',
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

/// 添加模拟数据
void _addSampleData(MonitorAnalyzer analyzer) {
  final now = DateTime.now();
  final random = Random();

  // CPU使用率波动 (20-90%)
  analyzer.addDataPoint(
    'cpu_usage',
    20.0 + random.nextDouble() * 70.0,
    now,
  );

  // 内存使用量缓慢增长
  const baseMemory = 2048.0;
  final memoryUsage = baseMemory +
      (now.millisecondsSinceEpoch % 3600000) / 3600000.0 * 4096.0 +
      random.nextDouble() * 512.0;

  analyzer.addDataPoint(
    'memory_usage',
    memoryUsage,
    now,
  );

  // 磁盘使用量线性增长
  const baseDisk = 200.0;
  final timeOffset = now.difference(DateTime(2025)).inHours;
  final diskUsage = baseDisk + timeOffset * 0.1 + random.nextDouble() * 5.0;

  analyzer.addDataPoint(
    'disk_usage',
    diskUsage,
    now,
  );

  // 网络流量周期性波动
  final timeOfDay = now.hour + now.minute / 60.0;
  final dayFactor = sin(timeOfDay * pi / 12.0); // 12小时周期

  analyzer.addDataPoint(
    'network_in',
    500.0 + 300.0 * dayFactor + random.nextDouble() * 100.0,
    now,
  );

  analyzer.addDataPoint(
    'network_out',
    300.0 + 200.0 * dayFactor + random.nextDouble() * 50.0,
    now,
  );
}
