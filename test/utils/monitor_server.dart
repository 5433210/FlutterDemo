import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'monitor_analyzer.dart';

/// 监控服务器
class MonitorServer {
  final MonitorAnalyzer analyzer;
  final ServerConfig config;
  HttpServer? _server;
  Timer? _refreshTimer;
  bool _disposed = false;

  /// 服务器启动时间
  final _startTime = DateTime.now();

  MonitorServer({
    required this.analyzer,
    required this.config,
  });

  /// 检查是否已销毁
  bool get isDisposed => _disposed;

  /// 启动服务器
  Future<void> start() async {
    if (_disposed) {
      throw StateError('Server has been disposed');
    }

    _server = await HttpServer.bind(
      config.host,
      config.port,
      shared: true,
    );

    print('Monitor server started on ${config.host}:${config.port}');

    if (config.refreshInterval != null) {
      _refreshTimer = Timer.periodic(
        config.refreshInterval!,
        (_) => _refreshData(),
      );
    }

    await _handleRequests();
  }

  /// 停止服务器
  Future<void> stop() async {
    if (!_disposed) {
      _disposed = true;
      _refreshTimer?.cancel();
      await _server?.close();
      _server = null;
    }
  }

  /// 格式化Prometheus指标
  String _formatPrometheusMetrics(Set<String> metrics) {
    final lines = <String>[];

    for (final metric in metrics) {
      final value = analyzer.getLastValue(metric);
      if (value == null) continue;

      lines.add('# HELP $metric ${_getMetricHelp(metric)}');
      lines.add('# TYPE $metric gauge');
      lines.add('$metric ${value.toString()}');

      final stats = analyzer.calculateStats(metric);
      for (final entry in stats.entries) {
        lines.add('${metric}_${entry.key} ${entry.value}');
      }
    }

    return lines.join('\n');
  }

  /// 获取指标说明
  String _getMetricHelp(String metric) {
    // TODO: 从Metric定义中获取description
    return 'Monitored metric: $metric';
  }

  /// 处理健康检查
  Future<void> _handleHealthCheck(HttpRequest request) async {
    final uptime = DateTime.now().difference(_startTime);
    final response = {
      'status': 'healthy',
      'uptime_seconds': uptime.inSeconds,
      'metrics_count': analyzer.getMetrics().length,
    };

    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(response));
    await request.response.close();
  }

  /// 处理指标请求
  Future<void> _handleMetricsRequest(HttpRequest request) async {
    final format = request.uri.queryParameters['format'] ?? 'json';
    final response = request.response;
    final metrics = analyzer.getMetrics();

    Map<String, dynamic> data;
    String contentType;

    switch (format) {
      case 'json':
        data = _prepareJsonMetrics(metrics);
        contentType = 'application/json';
        break;

      case 'prometheus':
        final text = _formatPrometheusMetrics(metrics);
        response.headers.contentType = ContentType('text', 'plain');
        response.write(text);
        await response.close();
        return;

      default:
        _sendError(response, 400, 'Unsupported format: $format');
        return;
    }

    response.headers.contentType = ContentType.parse(contentType);
    response.write(jsonEncode(data));
    await response.close();
  }

  /// 处理请求
  Future<void> _handleRequests() async {
    await for (final request in _server!) {
      if (_disposed) break;

      if (config.enableCors) {
        _setCorsHeaders(request.response);
      }

      try {
        await _routeRequest(request);
      } catch (e) {
        _sendError(request.response, 500, 'Internal server error: $e');
      }
    }
  }

  /// 准备JSON格式的指标
  Map<String, dynamic> _prepareJsonMetrics(Set<String> metrics) {
    final result = <String, dynamic>{};

    for (final metric in metrics) {
      final value = analyzer.getLastValue(metric);
      if (value == null) continue;

      final stats = analyzer.calculateStats(metric);
      final trend = analyzer.analyzeTrend(metric);
      final threshold = analyzer.getThresholds()[metric];

      result[metric] = {
        'current': value,
        'statistics': stats,
        'trend': trend.toJson(),
        if (threshold != null)
          'thresholds': {
            'warning': threshold.warning,
            'error': threshold.error,
            'is_upper_bound': threshold.isUpperBound,
          },
      };
    }

    return result;
  }

  /// 刷新数据
  void _refreshData() {
    // TODO: 实现数据刷新逻辑
  }

  /// 路由请求
  Future<void> _routeRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    switch (path) {
      case '/metrics':
        if (method == 'GET') {
          await _handleMetricsRequest(request);
        } else {
          _sendError(request.response, 405, 'Method not allowed');
        }
        break;

      case '/health':
        await _handleHealthCheck(request);
        break;

      default:
        _sendError(request.response, 404, 'Not found');
    }
  }

  /// 发送错误响应
  void _sendError(HttpResponse response, int code, String message) {
    response.statusCode = code;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({
      'error': message,
      'code': code,
    }));
    response.close();
  }

  /// 设置CORS头
  void _setCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers.add('Access-Control-Allow-Methods', 'GET, OPTIONS');
    response.headers
        .add('Access-Control-Allow-Headers', 'Origin, Content-Type');
  }
}

/// 服务器配置
class ServerConfig {
  final String host;
  final int port;
  final bool enableCors;
  final Duration? refreshInterval;
  final Map<String, String> headers;
  final bool enableMetrics;

  const ServerConfig({
    this.host = 'localhost',
    this.port = 8080,
    this.enableCors = true,
    this.refreshInterval,
    this.headers = const {},
    this.enableMetrics = true,
  });
}
