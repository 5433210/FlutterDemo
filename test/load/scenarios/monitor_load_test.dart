import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';

import '../../utils/monitor_analyzer.dart';
import '../../utils/monitor_server.dart';

void main() {
  group('负载测试', () {
    late MonitorAnalyzer analyzer;
    late MonitorServer server;
    final random = Random();
    late List<HttpClient> clients;
    late Timer loadTimer;

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
          refreshInterval: Duration(milliseconds: 100),
        ),
      );

      // 定义指标
      analyzer.defineMetric(const Metric(
        name: 'response_time',
        unit: 'ms',
        description: '响应时间',
      ));

      analyzer.defineMetric(const Metric(
        name: 'requests_per_second',
        unit: 'req/s',
        description: '每秒请求数',
      ));

      analyzer.defineMetric(const Metric(
        name: 'active_connections',
        unit: 'count',
        description: '活跃连接数',
      ));

      // 设置阈值
      analyzer.setThreshold(
        'response_time',
        warning: 200,
        error: 500,
      );

      analyzer.setThreshold(
        'requests_per_second',
        warning: 1000,
        error: 2000,
      );

      analyzer.setThreshold(
        'active_connections',
        warning: 500,
        error: 1000,
      );

      await server.start();
      clients = [];
    });

    tearDown(() async {
      loadTimer.cancel();
      for (final client in clients) {
        client.close();
      }
      await server.stop();
    });

    Future<void> simulateLoad({
      required int concurrentUsers,
      required Duration duration,
      int requestsPerUser = 10,
    }) async {
      final startTime = DateTime.now();
      var totalRequests = 0;
      var activeConnections = 0;

      loadTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        analyzer.addDataPoint(
          'requests_per_second',
          totalRequests / duration.inSeconds,
        );
        analyzer.addDataPoint(
          'active_connections',
          activeConnections.toDouble(),
        );
      });

      await Future.wait(
        List.generate(concurrentUsers, (userId) async {
          final client = HttpClient();
          clients.add(client);

          while (DateTime.now().difference(startTime) < duration) {
            try {
              activeConnections++;
              final requestStart = DateTime.now();

              final response = await _makeRequest(
                client,
                server.config.port,
                userId,
              );

              final requestDuration = DateTime.now().difference(requestStart);
              analyzer.addDataPoint(
                'response_time',
                requestDuration.inMilliseconds.toDouble(),
              );

              expect(response.statusCode, equals(200));
              totalRequests++;

              activeConnections--;

              // 随机延迟模拟用户行为
              await Future.delayed(
                Duration(milliseconds: random.nextInt(500)),
              );
            } catch (e) {
              print('请求错误: $e');
            }
          }
        }),
      );
    }

    test('并发用户负载测试', () async {
      const users = 50;
      const duration = Duration(seconds: 30);

      print('\n开始负载测试:');
      print('并发用户数: $users');
      print('测试时长: ${duration.inSeconds} 秒');

      await simulateLoad(
        concurrentUsers: users,
        duration: duration,
      );

      final stats = analyzer.calculateStats('response_time');
      print('\n测试结果:');
      print('响应时间 (ms):');
      print('- 最小: ${stats['min']?.toStringAsFixed(2)}');
      print('- 最大: ${stats['max']?.toStringAsFixed(2)}');
      print('- 平均: ${stats['avg']?.toStringAsFixed(2)}');
      print('- 标准差: ${stats['std']?.toStringAsFixed(2)}');

      final rps = analyzer.getLastValue('requests_per_second');
      print('\n每秒请求数: ${rps?.toStringAsFixed(2)}');

      // 验证性能指标
      expect(stats['avg'], lessThan(200)); // 平均响应时间应小于200ms
      expect(stats['std'], lessThan(100)); // 响应时间波动应较小
      expect(rps, greaterThan(50)); // RPS应大于50
    });

    test('突发流量测试', () async {
      // 先建立基准负载
      final normalLoadFuture = simulateLoad(
        concurrentUsers: 10,
        duration: const Duration(seconds: 10),
      );

      // 5秒后注入突发流量
      await Future.delayed(const Duration(seconds: 5));
      final spikeLoadFuture = simulateLoad(
        concurrentUsers: 100,
        duration: const Duration(seconds: 5),
      );

      await Future.wait([normalLoadFuture, spikeLoadFuture]);

      // 验证系统在突发流量下的表现
      final trend = analyzer.analyzeTrend('response_time');
      expect(trend.slope, greaterThan(0)); // 响应时间应该有所增加
      expect(trend.confidence, greaterThan(0.7)); // 趋势应该明显

      final loadTrend = analyzer.analyzeTrend('active_connections');
      expect(loadTrend.slope, greaterThan(0)); // 连接数应该增加
    });
  });
}

/// 发送测试请求
Future<HttpClientResponse> _makeRequest(
  HttpClient client,
  int port,
  int userId,
) async {
  final request = await client.getUrl(
    Uri.parse('http://localhost:$port/metrics'),
  );
  request.headers.add('X-Test-User', userId.toString());
  return await request.close();
}
