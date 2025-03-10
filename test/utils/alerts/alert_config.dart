import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// 警报配置
class AlertConfig {
  final int suppressionTimeMinutes;
  final bool enableDesktopNotifications;
  final bool enableConsoleOutput;
  final bool enableFileLogging;
  final String alertsPath;
  final int maxHistorySize;
  final Map<String, int> thresholds;
  final bool enableAlertAggregation;

  const AlertConfig({
    this.suppressionTimeMinutes = 30,
    this.enableDesktopNotifications = true,
    this.enableConsoleOutput = true,
    this.enableFileLogging = true,
    this.alertsPath = 'test/alerts',
    this.maxHistorySize = 1000,
    this.thresholds = const {
      'disk': 1024, // MB
      'memory': 512, // MB
      'cpu': 80, // %
    },
    this.enableAlertAggregation = true,
  });

  /// 检查阈值
  bool checkThreshold(String type, num value) {
    final threshold = thresholds[type];
    if (threshold == null) return true;
    return value < threshold;
  }

  /// 获取阈值
  int? getThreshold(String type) => thresholds[type];

  /// 保存到配置文件
  Future<void> save([String? configPath]) async {
    configPath ??= path.join('test', 'config', 'alert_config.json');
    final file = File(configPath);

    final dir = file.parent;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final json = {
      'suppressionTimeMinutes': suppressionTimeMinutes,
      'enableDesktopNotifications': enableDesktopNotifications,
      'enableConsoleOutput': enableConsoleOutput,
      'enableFileLogging': enableFileLogging,
      'alertsPath': alertsPath,
      'maxHistorySize': maxHistorySize,
      'thresholds': thresholds,
      'enableAlertAggregation': enableAlertAggregation,
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  /// 设置阈值
  void setThreshold(String type, int value) {
    thresholds[type] = value;
  }

  /// 从配置文件加载
  static Future<AlertConfig> load([String? configPath]) async {
    configPath ??= path.join('test', 'config', 'alert_config.json');
    final file = File(configPath);

    if (!file.existsSync()) {
      return const AlertConfig();
    }

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      return AlertConfig(
        suppressionTimeMinutes: json['suppressionTimeMinutes'] ?? 30,
        enableDesktopNotifications: json['enableDesktopNotifications'] ?? true,
        enableConsoleOutput: json['enableConsoleOutput'] ?? true,
        enableFileLogging: json['enableFileLogging'] ?? true,
        alertsPath: json['alertsPath'] ?? 'test/alerts',
        maxHistorySize: json['maxHistorySize'] ?? 1000,
        thresholds: Map<String, int>.from(json['thresholds'] ?? {}),
        enableAlertAggregation: json['enableAlertAggregation'] ?? true,
      );
    } catch (e) {
      print('警告: 无法加载警报配置: $e');
      return const AlertConfig();
    }
  }
}
