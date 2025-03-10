import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../utils/monitor_analyzer.dart';
import '../utils/monitor_server.dart';

void main() async {
  // 创建集群节点
  final nodes = <ClusterNode>[];

  for (var i = 0; i < 3; i++) {
    final node = ClusterNode(
      id: 'node-${i + 1}',
      host: 'localhost',
      port: 8080 + i,
    );
    nodes.add(node);

    // 定义监控指标
    node.analyzer.defineMetric(const Metric(
      name: 'cpu_usage',
      unit: '%',
      description: 'CPU使用率',
    ));

    node.analyzer.defineMetric(const Metric(
      name: 'memory_usage',
      unit: 'MB',
      description: '内存使用量',
    ));

    node.analyzer.defineMetric(const Metric(
      name: 'network_io',
      unit: 'KB/s',
      description: '网络IO',
    ));

    // 设置阈值
    node.analyzer.setThreshold(
      'cpu_usage',
      warning: 70,
      error: 90,
    );

    node.analyzer.setThreshold(
      'memory_usage',
      warning: 4096, // 4GB
      error: 7168, // 7GB
    );

    node.analyzer.setThreshold(
      'network_io',
      warning: 5000, // 5MB/s
      error: 8000, // 8MB/s
    );
  }

  try {
    // 启动所有节点
    print('启动集群节点...');
    await Future.wait(nodes.map((node) => node.start()));

    // 定期添加模拟数据
    Timer.periodic(const Duration(seconds: 5), (_) {
      for (final node in nodes) {
        _addNodeMetrics(node);
      }
    });

    // 打印访问信息
    print('\n节点监控端点:');
    for (final node in nodes) {
      print('\n节点 ${node.id}:');
      print('- 指标: http://${node.host}:${node.port}/metrics');
      print('- 健康: http://${node.host}:${node.port}/health');
    }

    print('\n按 Enter 键停止集群...');
    await stdin.first;
  } finally {
    // 停止所有节点
    await Future.wait(nodes.map((node) => node.stop()));
  }
}

/// 添加节点指标
void _addNodeMetrics(ClusterNode node) {
  final random = Random();
  final now = DateTime.now();
  final baseLoad = random.nextDouble() * 0.3; // 基础负载差异

  // CPU使用率 (20-90%)
  node.analyzer.addDataPoint(
    'cpu_usage',
    30.0 + baseLoad * 60.0 + random.nextDouble() * 30.0,
    now,
  );

  // 内存使用量 (2-6GB)
  node.analyzer.addDataPoint(
    'memory_usage',
    2048.0 + baseLoad * 4096.0 + random.nextDouble() * 1024.0,
    now,
  );

  // 网络IO (100-8000 KB/s)
  node.analyzer.addDataPoint(
    'network_io',
    100.0 + baseLoad * 7000.0 + random.nextDouble() * 1000.0,
    now,
  );
}

/// 集群节点
class ClusterNode {
  final String id;
  final String host;
  final int port;
  final MonitorAnalyzer analyzer;
  final MonitorServer server;

  /// 创建新的集群节点
  factory ClusterNode({
    required String id,
    required String host,
    required int port,
  }) {
    final analyzer = MonitorAnalyzer(
      config: const MonitorConfig(
        windowSize: Duration(hours: 1),
        enableTrending: true,
      ),
    );

    final server = MonitorServer(
      analyzer: analyzer,
      config: ServerConfig(
        host: host,
        port: port,
        enableCors: true,
        refreshInterval: const Duration(seconds: 5),
      ),
    );

    return ClusterNode._(
      id: id,
      host: host,
      port: port,
      analyzer: analyzer,
      server: server,
    );
  }

  ClusterNode._({
    required this.id,
    required this.host,
    required this.port,
    required this.analyzer,
    required this.server,
  });

  Future<void> start() => server.start();
  Future<void> stop() => server.stop();
}
