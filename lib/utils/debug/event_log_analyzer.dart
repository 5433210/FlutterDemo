/// 事件日志分析工具 - 帮助追踪和分析事件流
class EventLogAnalyzer {
  static const int maxLogs = 100;
  static final List<EventLogEntry> _eventLogs = [];
  static bool enabled = true;

  /// 分析最近的事件序列，寻找问题
  static void analyzeEventSequence() {
    if (!enabled || _eventLogs.isEmpty) return;

    print('===== 事件序列分析 =====');

    // 检查鼠标事件序列
    bool foundStartWithoutEnd = false;
    bool foundUpdateWithoutStart = false;
    bool foundInvalidSequence = false;

    String? lastEventType;
    for (final log in _eventLogs) {
      if (log.eventType == 'pointerDown') {
        if (lastEventType == 'pointerDown') {
          print('⚠️ 检测到连续的pointerDown事件，可能缺少pointerUp');
          foundInvalidSequence = true;
        }
        lastEventType = 'pointerDown';
      } else if (log.eventType == 'pointerMove') {
        if (lastEventType == null) {
          print('⚠️ 检测到pointerMove没有前置pointerDown');
          foundUpdateWithoutStart = true;
        }
      } else if (log.eventType == 'pointerUp') {
        if (lastEventType == null) {
          print('⚠️ 检测到pointerUp没有前置pointerDown');
          foundInvalidSequence = true;
        }
        lastEventType = null;
      }
    }

    // 分析事件延迟
    if (_eventLogs.length >= 2) {
      final delays = <Duration>[];
      for (int i = 1; i < _eventLogs.length; i++) {
        delays.add(
            _eventLogs[i].timestamp.difference(_eventLogs[i - 1].timestamp));
      }

      final avgDelay = delays.fold<Duration>(
              Duration.zero,
              (a, b) => Duration(
                  microseconds: a.inMicroseconds + b.inMicroseconds)) ~/
          delays.length;

      print('平均事件间隔: ${avgDelay.inMilliseconds}ms');
      if (avgDelay.inMilliseconds > 20) {
        print('⚠️ 事件间隔过长，可能影响响应性');
      }
    }

    print('======== 分析结束 ========');
  }

  /// 清空日志
  static void clearLogs() {
    _eventLogs.clear();
  }

  /// 获取事件日志
  static List<EventLogEntry> getLogs() {
    return List.from(_eventLogs);
  }

  /// 添加事件日志
  static void logEvent(String eventType, Map<String, dynamic> data) {
    if (!enabled) return;

    final log = EventLogEntry(
      timestamp: DateTime.now(),
      eventType: eventType,
      data: Map.from(data),
    );

    _eventLogs.add(log);
    if (_eventLogs.length > maxLogs) {
      _eventLogs.removeAt(0);
    }

    print('📝 事件: $eventType, 数据: ${data.toString()}');
  }
}

/// 事件日志条目
class EventLogEntry {
  final DateTime timestamp;
  final String eventType;
  final Map<String, dynamic> data;

  const EventLogEntry({
    required this.timestamp,
    required this.eventType,
    required this.data,
  });

  @override
  String toString() {
    return '[${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}] $eventType: $data';
  }
}
