import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../utils/monitor_analyzer.dart';
import '../utils/monitor_exporter.dart';

void main() async {
  // 创建监控分析器
  final analyzer = MonitorAnalyzer(
    config: const MonitorConfig(
      windowSize: Duration(hours: 24),
      enableTrending: true,
    ),
  );

  // 定义一些测试指标
  analyzer.defineMetric(const Metric(
    name: 'test_metric1',
    unit: 'count',
    description: '测试指标1',
  ));

  analyzer.defineMetric(const Metric(
    name: 'test_metric2',
    unit: 'ms',
    description: '测试指标2',
  ));

  // 添加一些测试数据
  final now = DateTime.now();
  for (var i = 0; i < 100; i++) {
    analyzer.addDataPoint(
      'test_metric1',
      i.toDouble(),
      now.add(Duration(minutes: i)),
    );
    analyzer.addDataPoint(
      'test_metric2',
      100.0 + i * 0.5,
      now.add(Duration(minutes: i)),
    );
  }

  // 创建临时备份目录
  final tempDir = await Directory.systemTemp.createTemp('backup_test_');

  try {
    // 创建备份管理器
    final backupManager = BackupManager(
      analyzer: analyzer,
      config: BackupConfig(
        basePath: tempDir.path,
        interval: const Duration(minutes: 1),
        maxBackups: 5,
        formats: [
          ExportFormat.json,
          ExportFormat.csv,
          ExportFormat.prometheus,
        ],
      ),
    );

    // 执行立即备份
    print('执行备份...');
    await backupManager.backup();

    // 检查备份文件
    final backupDir = Directory(tempDir.path)
        .listSync()
        .firstWhere((e) => e is Directory) as Directory;

    print('\n备份目录: ${backupDir.path}');
    print('\n备份文件:');
    for (final file in backupDir.listSync()) {
      print('- ${file.path}');
      if (file.path.endsWith('manifest.json')) {
        final content = await File(file.path).readAsString();
        print('\n清单内容:');
        print(content);
      }
    }

    // 清理资源
    backupManager.dispose();
  } finally {
    // 清理临时目录
    await tempDir.delete(recursive: true);
  }
}

/// 备份配置
class BackupConfig {
  final String basePath;
  final Duration interval;
  final int maxBackups;
  final List<ExportFormat> formats;

  BackupConfig({
    required this.basePath,
    this.interval = const Duration(hours: 1),
    this.maxBackups = 24,
    this.formats = const [ExportFormat.json, ExportFormat.csv],
  });
}

/// 备份管理器
class BackupManager {
  final MonitorAnalyzer analyzer;
  final BackupConfig config;
  Timer? _backupTimer;
  bool _disposed = false;

  BackupManager({
    required this.analyzer,
    required this.config,
  });

  /// 执行备份
  Future<void> backup() async {
    if (_disposed) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupDir = Directory('${config.basePath}/backup_$timestamp');

    try {
      await backupDir.create(recursive: true);

      // 为每种格式创建备份
      for (final format in config.formats) {
        final fileName = _getFileName(format, timestamp);
        final exporter = MonitorExporter(
          analyzer: analyzer,
          config: ExportConfig(
            format: format,
            outputPath: '${backupDir.path}/$fileName',
            includeMetadata: true,
            labels: {
              'backup_time': timestamp,
              'version': '1.0',
            },
          ),
        );

        await exporter.export();
      }

      // 创建备份清单
      await _createManifest(backupDir, timestamp);

      // 清理旧备份
      await _cleanOldBackups();
    } catch (e) {
      print('备份失败: $e');
      await backupDir.delete(recursive: true);
      rethrow;
    }
  }

  /// 销毁管理器
  void dispose() {
    if (!_disposed) {
      _backupTimer?.cancel();
      _disposed = true;
    }
  }

  /// 启动自动备份
  void start() {
    if (_disposed) {
      throw StateError('BackupManager has been disposed');
    }

    _backupTimer = Timer.periodic(config.interval, (_) => backup());
  }

  /// 清理旧备份
  Future<void> _cleanOldBackups() async {
    final baseDir = Directory(config.basePath);
    if (!await baseDir.exists()) return;

    final backupDirs = await baseDir
        .list()
        .where((e) => e is Directory && e.path.contains('backup_'))
        .toList();

    if (backupDirs.length <= config.maxBackups) return;

    // 按时间排序
    backupDirs.sort((a, b) => b.path.compareTo(a.path));

    // 删除多余的备份
    for (var i = config.maxBackups; i < backupDirs.length; i++) {
      await (backupDirs[i] as Directory).delete(recursive: true);
    }
  }

  /// 创建备份清单
  Future<void> _createManifest(Directory backupDir, String timestamp) async {
    final manifest = {
      'timestamp': timestamp,
      'formats': config.formats.map((f) => f.toString()).toList(),
      'metrics': analyzer.getMetrics().toList(),
      'thresholds': analyzer.getThresholds().map(
            (key, value) => MapEntry(key, {
              'warning': value.warning,
              'error': value.error,
            }),
          ),
    };

    await File('${backupDir.path}/manifest.json')
        .writeAsString(const JsonEncoder.withIndent('  ').convert(manifest));
  }

  /// 获取备份文件名
  String _getFileName(ExportFormat format, String timestamp) {
    switch (format) {
      case ExportFormat.json:
        return 'metrics.json';
      case ExportFormat.csv:
        return 'metrics.csv';
      case ExportFormat.jsonl:
        return 'metrics.jsonl';
      case ExportFormat.prometheus:
        return 'metrics';
      default:
        throw ArgumentError('不支持的导出格式: $format');
    }
  }
}
