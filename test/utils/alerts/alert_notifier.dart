import "dart:async";
import "dart:convert";
import "dart:io";

import "package:path/path.dart" as path;

import "../check_logger.dart";
import "alert_config.dart";
import "alert_types.dart";

/// 警报通知器
class AlertNotifier {
  final CheckLogger logger;
  final AlertConfig config;
  final List<AlertRecord> _history = [];
  final Map<String, DateTime> _suppressedAlerts = {};
  Timer? _processingTimer;

  AlertNotifier({
    CheckLogger? logger,
    AlertConfig? config,
  })  : logger = logger ?? CheckLogger.instance,
        config = config ?? const AlertConfig() {
    // 确保警报目录存在
    if (this.config.enableFileLogging) {
      final dir = Directory(this.config.alertsPath);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
    }
  }

  /// 发送警报
  Future<void> alert({
    required String type,
    required String message,
    required AlertLevel level,
    Map<String, dynamic>? details,
  }) async {
    final record = AlertRecord(
      timestamp: DateTime.now(),
      type: type,
      message: message,
      level: level,
      details: details,
    );

    // 检查是否被抑制
    if (_isAlertSuppressed(type)) {
      logger.debug("警报已被抑制: $type");
      return;
    }

    // 更新抑制时间戳
    _suppressedAlerts[type] = DateTime.now();

    // 添加到历史记录并处理警报
    _addToHistory(record);
    await _processAlert(record);
  }

  /// 清理
  void dispose() {
    _processingTimer?.cancel();
    _processingTimer = null;
    _history.clear();
    _suppressedAlerts.clear();
  }

  /// 获取警报历史
  List<AlertRecord> getHistory() {
    return List.unmodifiable(_history);
  }

  /// 抑制警报
  void suppressAlert(String type) {
    _suppressedAlerts[type] = DateTime.now();
  }

  /// 取消抑制
  void unsuppressAlert(String type) {
    _suppressedAlerts.remove(type);
  }

  /// 添加到历史记录
  void _addToHistory(AlertRecord record) {
    _history.add(record);

    // 按警报级别排序
    _history.sort((a, b) {
      // 同级别的警报保持时间顺序
      if (a.level == b.level) {
        return a.timestamp.compareTo(b.timestamp);
      }
      // 不同级别按优先级排序
      return b.level.index.compareTo(a.level.index);
    });

    // 维持历史记录大小限制，移除最旧的记录
    while (_history.length > config.maxHistorySize) {
      _history.removeAt(0);
    }
  }

  /// 检查警报是否被抑制
  bool _isAlertSuppressed(String type) {
    final lastSuppress = _suppressedAlerts[type];
    if (lastSuppress == null) return false;

    final now = DateTime.now();
    final suppressDuration = Duration(minutes: config.suppressionTimeMinutes);
    final suppressEndTime = lastSuppress.add(suppressDuration);

    return now.isBefore(suppressEndTime);
  }

  /// 处理警报
  Future<void> _processAlert(AlertRecord alert) async {
    if (config.enableConsoleOutput) {
      switch (alert.level) {
        case AlertLevel.info:
          logger.info("${alert.type}: ${alert.message}");
          break;
        case AlertLevel.warning:
          logger.warning("${alert.type}: ${alert.message}");
          break;
        case AlertLevel.error:
        case AlertLevel.critical:
          logger.error("${alert.type}: ${alert.message}");
          break;
      }
    }

    if (config.enableFileLogging) {
      await _writeAlertToFile(alert);
    }
  }

  /// 写入警报文件
  Future<void> _writeAlertToFile(AlertRecord alert) async {
    final file = File(path.join(
      config.alertsPath,
      "alerts.json",
    ));

    List<Map<String, dynamic>> alerts = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      alerts = List<Map<String, dynamic>>.from(jsonDecode(content) as List);
    }

    alerts.add(alert.toJson());
    await file.writeAsString(jsonEncode(alerts));
  }
}
