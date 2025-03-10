import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../utils/monitor_analyzer.dart';
import '../utils/monitor_exporter.dart';
import '../utils/monitor_server.dart';

void main() {
  group('监控系统集成测试', () {
    late MonitorAnalyzer analyzer;
    late MonitorServer server;
    late Directory tempDir;

    setUp(() async {
      analyzer = MonitorAnalyzer(
        config: const MonitorConfig(
          windowSize: Duration(minutes: 30),
          enableTrending: true,
        ),
      );

      server = MonitorServer(
        analyzer: analyzer,
        config: const ServerConfig(
          host: 'localhost',
          port: 0, // 随机端口
          enableCors: true,
          refreshInterval: Duration(seconds: 1),
        ),
      );

      tempDir = await Directory.systemTemp.createTemp('monitor_test_');
    });

    tearDown(() async {
      await server.stop();
      await tempDir.delete(recursive: true);
    });

    test('基本监控功能', () async {
      // 定义指标
      analyzer.defineMetric(const Metric(
        name: 'test_metric',
        unit: 'count',
        description: '测试指标',
      ));

      // 设置阈值
      analyzer.setThreshold(
        'test_metric',
        warning: 80,
        error: 90,
      );

      // 添加数据点
      final now = DateTime.now();
      for (var i = 0; i < 10; i++) {
        analyzer.addDataPoint(
          'test_metric',
          50.0 + i * 5,
          now.add(Duration(minutes: i)),
        );
      }

      // 验证数据添加
      expect(analyzer.getMetrics(), contains('test_metric'));
      expect(analyzer.getLastValue('test_metric'), equals(95.0));

      // 验证趋势分析
      final trend = analyzer.analyzeTrend('test_metric');
      expect(trend.slope, greaterThan(0));
      expect(trend.confidence, greaterThan(0.9));

      // 验证统计计算
      final stats = analyzer.calculateStats('test_metric');
      expect(stats['min'], equals(50.0));
      expect(stats['max'], equals(95.0));
    });

    test('服务器API', () async {
      // 启动服务器
      await server.start();
      final port = server.config.port;

      // 添加测试数据
      analyzer.defineMetric(const Metric(
        name: 'api_test',
        unit: 'ms',
        description: 'API响应时间',
      ));

      analyzer.addDataPoint('api_test', 100.0);

      // 测试JSON端点
      final jsonResponse = await _getContent(
        'http://localhost:$port/metrics?format=json',
      );
      final jsonData = jsonDecode(jsonResponse) as Map<String, dynamic>;
      expect(jsonData, contains('api_test'));

      // 测试Prometheus端点
      final prometheusResponse = await _getContent(
        'http://localhost:$port/metrics?format=prometheus',
      );
      expect(prometheusResponse, contains('api_test'));

      // 测试健康检查
      final healthResponse = await _getContent(
        'http://localhost:$port/health',
      );
      final health = jsonDecode(healthResponse) as Map<String, dynamic>;
      expect(health['status'], equals('healthy'));
    });

    test('数据导出', () async {
      // 添加测试数据
      analyzer.defineMetric(const Metric(
        name: 'export_test',
        unit: 'count',
        description: '导出测试',
      ));

      final now = DateTime.now();
      for (var i = 0; i < 5; i++) {
        analyzer.addDataPoint(
          'export_test',
          i * 10.0,
          now.add(Duration(minutes: i)),
        );
      }

      // JSON导出
      final jsonExporter = MonitorExporter(
        analyzer: analyzer,
        config: ExportConfig(
          format: ExportFormat.json,
          outputPath: '${tempDir.path}/metrics.json',
        ),
      );
      await jsonExporter.export();

      // CSV导出
      final csvExporter = MonitorExporter(
        analyzer: analyzer,
        config: ExportConfig(
          format: ExportFormat.csv,
          outputPath: '${tempDir.path}/metrics.csv',
        ),
      );
      await csvExporter.export();

      // Prometheus导出
      final prometheusExporter = MonitorExporter(
        analyzer: analyzer,
        config: ExportConfig(
          format: ExportFormat.prometheus,
          outputPath: '${tempDir.path}/metrics',
          labels: {'job': 'test'},
        ),
      );
      await prometheusExporter.export();

      // 验证文件存在
      expect(File('${tempDir.path}/metrics.json').existsSync(), isTrue);
      expect(File('${tempDir.path}/metrics.csv').existsSync(), isTrue);
      expect(File('${tempDir.path}/metrics').existsSync(), isTrue);
    });
  });
}

/// 获取HTTP响应内容
Future<String> _getContent(String url) async {
  final uri = Uri.parse(url);
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to load $url: ${response.statusCode}',
      );
    }

    return await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}
