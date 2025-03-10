import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'monitor_analyzer.dart';

/// 导出配置
class ExportConfig {
  final ExportFormat format;
  final String outputPath;
  final Duration? interval;
  final bool appendMode;
  final bool includeMetadata;
  final Map<String, String> labels;

  const ExportConfig({
    this.format = ExportFormat.json,
    required this.outputPath,
    this.interval,
    this.appendMode = false,
    this.includeMetadata = true,
    this.labels = const {},
  });
}

/// 导出格式
enum ExportFormat { json, csv, jsonl, prometheus }

/// 度量导出器
class MonitorExporter {
  final MonitorAnalyzer analyzer;
  final ExportConfig config;
  Timer? _exportTimer;
  bool _disposed = false;

  MonitorExporter({
    required this.analyzer,
    required this.config,
  }) {
    if (config.interval != null) {
      _exportTimer = Timer.periodic(config.interval!, (_) => export());
    }
  }

  /// 检查是否已销毁
  bool get isDisposed => _disposed;

  /// 销毁导出器
  void dispose() {
    if (!_disposed) {
      _exportTimer?.cancel();
      _disposed = true;
    }
  }

  /// 执行导出
  Future<void> export() async {
    if (_disposed) return;

    final metrics = analyzer.getMetrics();
    if (metrics.isEmpty) return;

    final data = _prepareData(metrics);
    final content = _formatData(data);

    await _writeToFile(content);
  }

  /// CSV格式化
  String _formatCsv(Map<String, Map<String, dynamic>> data) {
    final buffer = StringBuffer();
    final headers = ['metric', 'value', 'timestamp'];

    // 写入表头
    buffer.writeln(headers.join(','));

    // 写入数据行
    for (final entry in data.entries) {
      final metric = entry.key;
      final values = entry.value;
      buffer.writeln([
        metric,
        values['value'],
        values['timestamp'],
      ].join(','));
    }

    return buffer.toString();
  }

  /// 格式化数据
  String _formatData(Map<String, Map<String, dynamic>> data) {
    switch (config.format) {
      case ExportFormat.json:
        return _formatJson(data);
      case ExportFormat.csv:
        return _formatCsv(data);
      case ExportFormat.jsonl:
        return _formatJsonl(data);
      case ExportFormat.prometheus:
        return _formatPrometheus(data);
      default:
        throw UnsupportedError('未支持的导出格式: ${config.format}');
    }
  }

  /// JSON格式化
  String _formatJson(Map<String, Map<String, dynamic>> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// JSONL格式化
  String _formatJsonl(Map<String, Map<String, dynamic>> data) {
    return data.entries.map((e) => jsonEncode({e.key: e.value})).join('\n');
  }

  /// 格式化标签
  String _formatLabels(Map<String, String>? labels) {
    if (labels == null || labels.isEmpty) return '';

    final formattedLabels =
        labels.entries.map((e) => '${e.key}="${e.value}"').join(',');

    return '{$formattedLabels}';
  }

  /// Prometheus格式化
  String _formatPrometheus(Map<String, Map<String, dynamic>> data) {
    final buffer = StringBuffer();

    for (final entry in data.entries) {
      final metric = entry.key;
      final values = entry.value;
      final labels = _formatLabels(values['labels'] as Map<String, String>?);

      buffer.writeln('# HELP $metric Metric exported from MonitorAnalyzer');
      buffer.writeln('# TYPE $metric gauge');
      buffer.writeln('$metric$labels ${values['value']}');
    }

    return buffer.toString();
  }

  /// 准备导出数据
  Map<String, Map<String, dynamic>> _prepareData(Set<String> metrics) {
    final result = <String, Map<String, dynamic>>{};

    for (final metric in metrics) {
      final metricData = <String, dynamic>{};
      final metricConfig = analyzer.getThresholds()[metric];

      // 基础数据
      final stats = analyzer.calculateStats(metric);
      final currentValue = analyzer.getLastValue(metric);

      if (currentValue != null) {
        metricData['value'] = currentValue;
        metricData['statistics'] = stats;

        // 阈值信息
        if (metricConfig != null) {
          metricData['thresholds'] = {
            'warning': metricConfig.warning,
            'error': metricConfig.error,
            'is_upper_bound': metricConfig.isUpperBound,
          };
        }

        // 趋势分析
        final trend = analyzer.analyzeTrend(metric);
        metricData['trend'] = trend.toJson();

        // 时间信息
        metricData['timestamp'] = DateTime.now().toIso8601String();

        // 标签信息
        if (config.labels.isNotEmpty) {
          metricData['labels'] = config.labels;
        }

        result[metric] = metricData;
      }
    }

    return result;
  }

  /// 写入文件
  Future<void> _writeToFile(String content) async {
    final file = File(config.outputPath);
    final mode = config.appendMode ? FileMode.append : FileMode.write;

    try {
      await file.parent.create(recursive: true);
      await file.writeAsString(content, mode: mode);
    } catch (e) {
      print('导出失败: $e');
    }
  }
}
