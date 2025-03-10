import 'dart:async';
import 'dart:collection';

import 'alert_notifier.dart';

/// 告警聚合配置
class AggregatorConfig {
  final Duration aggregationWindow;
  final int maxAlerts;
  final Duration expiryDuration;
  final bool deduplicateAlerts;
  final bool trackDuration;
  final Map<AlertLevel, Duration> retentionPeriods;

  const AggregatorConfig({
    this.aggregationWindow = const Duration(minutes: 5),
    this.maxAlerts = 1000,
    this.expiryDuration = const Duration(days: 7),
    this.deduplicateAlerts = true,
    this.trackDuration = true,
    this.retentionPeriods = const {
      AlertLevel.info: Duration(days: 1),
      AlertLevel.warning: Duration(days: 3),
      AlertLevel.error: Duration(days: 7),
      AlertLevel.critical: Duration(days: 30),
    },
  });
}

/// 告警聚合器
class AlertAggregator {
  final AlertNotifier notifier;
  final AggregatorConfig config;
  final _activeAlerts = <String, AlertRecord>{};
  final _alertHistory = Queue<AlertRecord>();
  Timer? _cleanupTimer;
  final _controller = StreamController<AlertRecord>.broadcast();

  AlertAggregator({
    required this.notifier,
    AggregatorConfig? config,
  }) : config = config ?? const AggregatorConfig() {
    notifier.alertStream.listen(_handleAlert);
    _startCleanup();
  }

  Stream<AlertRecord> get recordStream => _controller.stream;

  /// 清理资源
  void dispose() {
    _cleanupTimer?.cancel();
    _controller.close();
  }

  /// 获取活跃告警
  List<AlertRecord> getActiveAlerts() =>
      List.unmodifiable(_activeAlerts.values);

  /// 获取告警历史
  List<AlertRecord> getAlertHistory() => List.unmodifiable(_alertHistory);

  /// 获取特定等级的告警
  List<AlertRecord> getAlertsByLevel(AlertLevel level) {
    return _activeAlerts.values
        .where((record) => record.alert.level == level)
        .toList();
  }

  /// 获取告警统计
  Map<String, dynamic> getStatistics() {
    final levelCounts = <String, int>{};
    for (final level in AlertLevel.values) {
      levelCounts[level.name] =
          _activeAlerts.values.where((r) => r.alert.level == level).length;
    }

    final statusCounts = <String, int>{};
    for (final status in AlertStatus.values) {
      statusCounts[status.name] =
          _alertHistory.where((r) => r.status == status).length;
    }

    return {
      'active_count': _activeAlerts.length,
      'history_count': _alertHistory.length,
      'by_level': levelCounts,
      'by_status': statusCounts,
    };
  }

  /// 更新告警状态
  void updateAlertStatus(String alertId, AlertStatus status) {
    final record = _activeAlerts[alertId];
    if (record != null) {
      final updatedRecord = AlertRecord(
        alert: record.alert,
        timestamp: record.timestamp,
        source: record.source,
        count: record.count,
        duration: record.duration,
        status: status,
      );

      if (status != AlertStatus.active) {
        _activeAlerts.remove(alertId);
        _addToHistory(updatedRecord);
      } else {
        _activeAlerts[alertId] = updatedRecord;
      }

      _controller.add(updatedRecord);
    }
  }

  /// 添加到历史记录
  void _addToHistory(AlertRecord record) {
    _alertHistory.addFirst(record);
    _cleanHistory();
  }

  /// 检查过期告警
  void _checkExpiredAlerts() {
    final now = DateTime.now();
    final expiredAlerts = _activeAlerts.entries
        .where((entry) =>
            now.difference(entry.value.timestamp) > config.expiryDuration)
        .toList();

    for (final entry in expiredAlerts) {
      updateAlertStatus(entry.key, AlertStatus.expired);
    }
  }

  /// 清理历史记录
  void _cleanHistory() {
    final now = DateTime.now();
    while (_alertHistory.isNotEmpty) {
      final record = _alertHistory.last;
      final retention =
          config.retentionPeriods[record.alert.level] ?? config.expiryDuration;

      if (now.difference(record.timestamp) > retention) {
        _alertHistory.removeLast();
      } else {
        break;
      }
    }
  }

  /// 生成告警ID
  String _generateAlertId(AlertData alert) {
    final source = alert.data['source'] as String?;
    return '${alert.level.name}:${alert.message}${source != null ? ':$source' : ''}';
  }

  /// 处理新告警
  void _handleAlert(AlertData alert) {
    final alertId = _generateAlertId(alert);
    final now = DateTime.now();

    if (config.deduplicateAlerts && _activeAlerts.containsKey(alertId)) {
      final existing = _activeAlerts[alertId]!;
      final updatedRecord = AlertRecord(
        alert: alert,
        timestamp: existing.timestamp,
        source: alert.data['source'] as String?,
        count: existing.count + 1,
        duration: now.difference(existing.timestamp),
        status: AlertStatus.active,
      );
      _activeAlerts[alertId] = updatedRecord;
      _controller.add(updatedRecord);
    } else {
      final record = AlertRecord(
        alert: alert,
        timestamp: now,
        source: alert.data['source'] as String?,
      );
      _activeAlerts[alertId] = record;
      _controller.add(record);

      if (_activeAlerts.length > config.maxAlerts) {
        final oldest = _activeAlerts.entries.first;
        _activeAlerts.remove(oldest.key);
        _addToHistory(oldest.value);
      }
    }
  }

  /// 开始定期清理
  void _startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(config.aggregationWindow, (_) {
      _cleanHistory();
      _checkExpiredAlerts();
    });
  }
}

/// 告警记录
class AlertRecord {
  final AlertData alert;
  final DateTime timestamp;
  final String? source;
  final int count;
  final Duration? duration;
  final AlertStatus status;

  const AlertRecord({
    required this.alert,
    required this.timestamp,
    this.source,
    this.count = 1,
    this.duration,
    this.status = AlertStatus.active,
  });

  Map<String, dynamic> toJson() => {
        'alert': alert.toJson(),
        'timestamp': timestamp.toIso8601String(),
        'source': source,
        'count': count,
        'duration': duration?.inMilliseconds,
        'status': status.name,
      };
}

/// 告警状态
enum AlertStatus {
  active, // 活跃
  resolved, // 已解决
  ignored, // 已忽略
  expired, // 已过期
}
