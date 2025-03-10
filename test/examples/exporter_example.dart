import 'dart:async';
import 'dart:io';

import '../utils/monitor_analyzer.dart';
import '../utils/monitor_exporter.dart';

void main() async {
  // 创建分析器
  final analyzer = MonitorAnalyzer(
    config: const MonitorConfig(
      windowSize: Duration(hours: 1),
      enableTrending: true,
    ),
  );

  // 定义监控指标
  analyzer.defineMetric(const Metric(
    name: 'response_time',
    unit: 'ms',
    description: '请求响应时间',
  ));

  analyzer.defineMetric(const Metric(
    name: 'error_rate',
    unit: '%',
    description: '错误率',
  ));

  analyzer.defineMetric(const Metric(
    name: 'throughput',
    unit: 'req/s',
    description: '每秒请求数',
  ));

  // 添加示例数据
  final now = DateTime.now();

  for (var i = 0; i < 60; i++) {
    analyzer.addDataPoint(
      'response_time',
      100 + i * 2.0,
      now.add(Duration(minutes: i)),
    );

    analyzer.addDataPoint(
      'error_rate',
      2.0 + (i > 45 ? 5.0 : 0.0),
      now.add(Duration(minutes: i)),
    );

    analyzer.addDataPoint(
      'throughput',
      1000.0 + (i % 10) * 100,
      now.add(Duration(minutes: i)),
    );
  }

  // 创建临时目录
  final tempDir = await Directory.systemTemp.createTemp('monitor_export_');
  try {
    // 自动导出示例
    final autoExporter = MonitorExporter(
      analyzer: analyzer,
      config: ExportConfig(
        format: ExportFormat.jsonl,
        outputPath: '${tempDir.path}/metrics.jsonl',
        interval: const Duration(seconds: 10),
        appendMode: true,
        includeMetadata: true,
        labels: {
          'environment': 'test',
          'instance': 'example-1',
        },
      ),
    );

    print('自动导出已启动，等待数据积累...');
    await Future.delayed(const Duration(seconds: 30));
    autoExporter.dispose();

    // JSON导出示例
    final jsonExporter = MonitorExporter(
      analyzer: analyzer,
      config: ExportConfig(
        format: ExportFormat.json,
        outputPath: '${tempDir.path}/metrics.json',
        includeMetadata: true,
        labels: {'format': 'json'},
      ),
    );
    await jsonExporter.export();
    print('JSON导出完成: ${tempDir.path}/metrics.json');

    // CSV导出示例
    final csvExporter = MonitorExporter(
      analyzer: analyzer,
      config: ExportConfig(
        format: ExportFormat.csv,
        outputPath: '${tempDir.path}/metrics.csv',
        labels: {'format': 'csv'},
      ),
    );
    await csvExporter.export();
    print('CSV导出完成: ${tempDir.path}/metrics.csv');

    // Prometheus导出示例
    final prometheusExporter = MonitorExporter(
      analyzer: analyzer,
      config: ExportConfig(
        format: ExportFormat.prometheus,
        outputPath: '${tempDir.path}/metrics',
        labels: {
          'job': 'monitor_example',
          'instance': 'example-1',
        },
      ),
    );
    await prometheusExporter.export();
    print('Prometheus导出完成: ${tempDir.path}/metrics');

    // 打印导出的文件内容
    print('\n文件内容预览:');
    for (final file in await tempDir.list().toList()) {
      print('\n${file.path}:');
      print('=' * 50);
      print(await File(file.path).readAsString());
      print('=' * 50);
    }
  } finally {
    // 清理临时目录
    await tempDir.delete(recursive: true);
    print('\n临时文件已清理');
  }
}
