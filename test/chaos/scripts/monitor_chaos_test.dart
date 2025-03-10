import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';

import '../../utils/monitor_analyzer.dart';
import '../../utils/monitor_exporter.dart';
import '../../utils/monitor_server.dart';

void main() {
  group('混沌测试', () {
    late MonitorAnalyzer analyzer;
    late MonitorServer server;
    late Directory tempDir;
    late Timer dataTimer;
    final random = Random();

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

      tempDir = await Directory.systemTemp.createTemp('chaos_test_');

      // 定义测试指标
      analyzer.defineMetric(const Metric(
        name: 'test_service',
        unit: 'ms',
        description: '服务响应时间',
      ));

      analyzer.defineMetric(const Metric(
        name: 'test_errors',
        unit: 'count',
        description: '错误计数',
      ));

      analyzer.defineMetric(const Metric(
        name: 'test_load',
        unit: '%',
        description: '负载',
      ));

      // 设置阈值
      analyzer.setThreshold(
        'test_service',
        warning: 100,
        error: 200,
      );

      analyzer.setThreshold(
        'test_errors',
        warning: 10,
        error: 20,
      );

      analyzer.setThreshold(
        'test_load',
        warning: 80,
        error: 90,
      );

      await server.start();

      // 开始生成混沌数据
      dataTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        _generateChaosData(analyzer, random);
      });
    });

    tearDown(() async {
      dataTimer.cancel();
      await server.stop();
      await tempDir.delete(recursive: true);
    });

    test('服务中断测试', () async {
      // 模拟服务中断
      for (var i = 0; i < 10; i++) {
        analyzer.addDataPoint(
          'test_service',
          500.0 + random.nextDouble() * 500.0,
        );
        analyzer.addDataPoint(
          'test_errors',
          20.0 + random.nextDouble() * 10.0,
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final results = await _getMetrics(server.config.port);
      expect(results['test_service']['alerts'], isNotEmpty);
      expect(results['test_errors']['alerts'], isNotEmpty);
    });

    test('负载波动测试', () async {
      // 模拟负载波动
      for (var i = 0; i < 20; i++) {
        analyzer.addDataPoint(
          'test_load',
          70.0 + sin(i * pi / 10) * 30.0 + random.nextDouble() * 10.0,
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final trend = analyzer.analyzeTrend('test_load');
      expect(trend.confidence, greaterThan(0.5));
    });

    test('数据导出恢复测试', () async {
      // 生成一些数据
      for (var i = 0; i < 5; i++) {
        analyzer.addDataPoint(
          'test_service',
          50.0 + random.nextDouble() * 50.0,
        );
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // 导出数据
      final exporter = MonitorExporter(
        analyzer: analyzer,
        config: ExportConfig(
          format: ExportFormat.json,
          outputPath: '${tempDir.path}/backup.json',
        ),
      );
      await exporter.export();

      // 验证导出文件
      final file = File('${tempDir.path}/backup.json');
      expect(await file.exists(), isTrue);

      final content = await file.readAsString();
      expect(content, contains('test_service'));
    });
  });
}

/// 生成混沌测试数据
void _generateChaosData(MonitorAnalyzer analyzer, Random random) {
  final now = DateTime.now();

  // 随机服务响应时间 (正常 20-100ms，偶尔出现尖峰)
  final spikeProbability = random.nextDouble();
  final responseTime = spikeProbability > 0.95
      ? 200.0 + random.nextDouble() * 800.0 // 尖峰
      : 20.0 + random.nextDouble() * 80.0; // 正常

  analyzer.addDataPoint('test_service', responseTime, now);

  // 随机错误计数 (正常 0-5，偶尔出现突增)
  final errorSpike = random.nextDouble();
  final errors = errorSpike > 0.98
      ? 20.0 + random.nextDouble() * 10.0 // 突增
      : random.nextDouble() * 5.0; // 正常

  analyzer.addDataPoint('test_errors', errors, now);

  // 负载波动 (正常 40-70%，周期性变化)
  final timeOfDay = now.hour + now.minute / 60.0;
  final baseLoad = 55.0 + sin(timeOfDay * pi / 12.0) * 15.0;
  final load = baseLoad + random.nextDouble() * 10.0;

  analyzer.addDataPoint('test_load', load, now);
}

/// 获取监控指标数据
Future<Map<String, dynamic>> _getMetrics(int port) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('http://localhost:$port/metrics?format=json'),
    );
    final response = await request.close();
    final content = await response.transform(utf8.decoder).join();
    return jsonDecode(content) as Map<String, dynamic>;
  } finally {
    client.close();
  }
}
