import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// 告警构建器
class AlertBuilder {
  String? _message;
  AlertLevel _level = AlertLevel.info;
  DateTime? _timestamp;
  String? _source;
  String? _category;
  final _data = <String, dynamic>{};

  AlertBuilder addData(String key, dynamic value) {
    _data[key] = value;
    return this;
  }

  AlertData build() {
    if (_message == null) {
      throw StateError('Alert message is required');
    }

    return AlertData(
      message: _message!,
      level: _level,
      timestamp: _timestamp,
      source: _source,
      category: _category,
      data: Map.unmodifiable(_data),
    );
  }

  AlertBuilder category(String value) {
    _category = value;
    return this;
  }

  AlertBuilder level(AlertLevel value) {
    _level = value;
    return this;
  }

  AlertBuilder message(String value) {
    _message = value;
    return this;
  }

  AlertBuilder source(String value) {
    _source = value;
    return this;
  }

  AlertBuilder timestamp(DateTime value) {
    _timestamp = value;
    return this;
  }
}

/// 告警配置
class AlertConfig {
  final int maxAlerts;
  final bool enableNotifications;
  final Duration checkInterval;
  final Map<AlertLevel, Duration> throttling;
  final Set<AlertLevel> enabledLevels;
  final bool persistAlerts;
  final String? outputPath;

  AlertConfig({
    this.maxAlerts = 1000,
    this.enableNotifications = true,
    this.checkInterval = const Duration(seconds: 1),
    this.throttling = const {},
    Set<AlertLevel>? enabledLevels,
    this.persistAlerts = false,
    this.outputPath,
  }) : enabledLevels = enabledLevels ?? AlertLevel.values.toSet();

  /// 创建禁用的配置
  static AlertConfig disabled() => AlertConfig(
        enableNotifications: false,
        enabledLevels: {},
      );

  /// 创建测试配置
  static AlertConfig forTest() => AlertConfig(
        maxAlerts: 10,
        checkInterval: const Duration(milliseconds: 100),
        persistAlerts: false,
      );
}

/// 告警数据
class AlertData {
  final String message;
  final AlertLevel level;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final String? source;
  final String? category;

  AlertData({
    required this.message,
    required this.level,
    DateTime? timestamp,
    this.data = const {},
    this.source,
    this.category,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'message': message,
        'level': level.name,
        'timestamp': timestamp.toIso8601String(),
        'data': data,
        if (source != null) 'source': source,
        if (category != null) 'category': category,
      };

  @override
  String toString() {
    final buf = StringBuffer()
      ..write('$level')
      ..write(' [${timestamp.toIso8601String()}]');

    if (source != null) buf.write(' ($source)');
    if (category != null) buf.write(' [$category]');

    buf.write(': $message');

    if (data.isNotEmpty) {
      buf.write('\nData: $data');
    }

    return buf.toString();
  }
}

/// 告警级别
enum AlertLevel { info, warning, error, critical }

/// 告警通知器
class AlertNotifier {
  final AlertConfig config;
  final _alerts = <AlertData>[];
  final _lastAlerts = <AlertLevel, DateTime>{};
  final _controller = StreamController<AlertData>.broadcast();
  Timer? _checkTimer;
  bool _disposed = false;

  AlertNotifier({
    required this.config,
  }) {
    if (config.enableNotifications) {
      _checkTimer = Timer.periodic(config.checkInterval, _checkAlerts);
    }
  }

  /// 告警流
  Stream<AlertData> get alertStream => _controller.stream;

  /// 检查是否已销毁
  bool get isDisposed => _disposed;

  /// 清除告警
  void clearAlerts([AlertLevel? level]) {
    if (level != null) {
      _alerts.removeWhere((a) => a.level == level);
      _lastAlerts.remove(level);
    } else {
      _alerts.clear();
      _lastAlerts.clear();
    }
  }

  /// 销毁通知器
  void dispose() {
    if (!_disposed) {
      _checkTimer?.cancel();
      _controller.close();
      clearAlerts();
      _disposed = true;
    }
  }

  /// 获取告警历史
  List<AlertData> getAlerts([AlertLevel? level]) {
    if (level != null) {
      return List.unmodifiable(
        _alerts.where((a) => a.level == level),
      );
    }
    return List.unmodifiable(_alerts);
  }

  /// 获取最近告警时间
  DateTime? getLastAlertTime([AlertLevel? level]) {
    if (level != null) {
      return _lastAlerts[level];
    }
    return _lastAlerts.values.fold<DateTime?>(
      null,
      (a, b) => a == null || b.isAfter(a) ? b : a,
    );
  }

  /// 发送告警
  void notify(AlertData alert) {
    if (_disposed) {
      throw StateError('AlertNotifier has been disposed');
    }

    if (!config.enableNotifications ||
        !config.enabledLevels.contains(alert.level)) {
      return;
    }

    // 检查节流
    final lastAlert = _lastAlerts[alert.level];
    final throttle = config.throttling[alert.level];
    if (lastAlert != null && throttle != null) {
      final elapsed = DateTime.now().difference(lastAlert);
      if (elapsed < throttle) return;
    }

    _alerts.add(alert);
    _lastAlerts[alert.level] = alert.timestamp;
    _controller.add(alert);

    // 限制告警数量
    while (_alerts.length > config.maxAlerts) {
      _alerts.removeAt(0);
    }

    // 持久化告警
    if (config.persistAlerts && config.outputPath != null) {
      _persistAlert(alert);
    }
  }

  /// 检查告警
  void _checkAlerts([Timer? timer]) {
    // 子类可以重写此方法实现自定义检查逻辑
  }

  /// 持久化告警
  Future<void> _persistAlert(AlertData alert) async {
    try {
      final file = File('${config.outputPath}/alerts.jsonl');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        '${jsonEncode(alert.toJson())}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // 忽略持久化错误
    }
  }
}
