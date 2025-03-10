import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'alert_types.dart';

/// 警报统计信息
class AlertStatistics {
  final Map<String, int> _typeCounts = {};
  final Map<AlertLevel, int> _levelCounts = {};
  final Map<String, DateTime> _firstOccurrence = {};
  final Map<String, DateTime> _lastOccurrence = {};
  final Map<String, double> _averageFrequency = {};

  /// 获取最高级别的警报
  AlertLevel? get highestLevel {
    if (_levelCounts.isEmpty) return null;
    return _levelCounts.keys.reduce((a, b) => a.index > b.index ? a : b);
  }

  /// 获取最频繁的警报类型
  String? get mostFrequentType {
    if (_typeCounts.isEmpty) return null;
    return _typeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// 获取总警报数
  int get totalAlerts => _typeCounts.values.fold(0, (a, b) => a + b);

  /// 清除统计
  void clear() {
    _typeCounts.clear();
    _levelCounts.clear();
    _firstOccurrence.clear();
    _lastOccurrence.clear();
    _averageFrequency.clear();
  }

  /// 获取按级别统计
  Map<AlertLevel, int> getLevelStatistics() => Map.unmodifiable(_levelCounts);

  /// 获取警报类型统计
  Map<String, AlertTypeStatistics> getTypeStatistics() {
    final result = <String, AlertTypeStatistics>{};

    for (final type in _typeCounts.keys) {
      result[type] = AlertTypeStatistics(
        count: _typeCounts[type] ?? 0,
        firstOccurrence: _firstOccurrence[type],
        lastOccurrence: _lastOccurrence[type],
        frequency: _averageFrequency[type] ?? 0,
      );
    }

    return result;
  }

  /// 记录警报
  void recordAlert(AlertRecord alert) {
    // 更新类型计数
    _typeCounts[alert.type] = (_typeCounts[alert.type] ?? 0) + 1;

    // 更新级别计数
    _levelCounts[alert.level] = (_levelCounts[alert.level] ?? 0) + 1;

    // 更新首次出现时间
    _firstOccurrence.putIfAbsent(alert.type, () => alert.timestamp);

    // 更新最后出现时间
    _lastOccurrence[alert.type] = alert.timestamp;

    // 更新平均频率
    _updateAverageFrequency(alert.type);
  }

  /// 保存统计信息
  Future<void> save(String directory) async {
    final dir = Directory(directory);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File(path.join(directory, 'alert_stats_$timestamp.json'));

    final data = {
      'totalAlerts': totalAlerts,
      'mostFrequentType': mostFrequentType,
      'highestLevel': highestLevel?.toString(),
      'typeStatistics': getTypeStatistics().map(
        (k, v) => MapEntry(k, v.toJson()),
      ),
      'levelCounts': _levelCounts.map(
        (k, v) => MapEntry(k.toString(), v),
      ),
    };

    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(data),
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('警报统计:\n');

    buffer.writeln('总警报数: $totalAlerts');
    buffer.writeln('最频繁类型: $mostFrequentType');
    buffer.writeln('最高警报级别: $highestLevel\n');

    buffer.writeln('按类型统计:');
    final typeStats = getTypeStatistics();
    for (final entry in typeStats.entries) {
      buffer.writeln('- ${entry.key}:');
      buffer.writeln('  ${entry.value}');
    }

    buffer.writeln('\n按级别统计:');
    for (final entry in _levelCounts.entries) {
      buffer.writeln('- ${entry.key}: ${entry.value}次');
    }

    return buffer.toString();
  }

  /// 更新平均频率
  void _updateAverageFrequency(String type) {
    final firstTime = _firstOccurrence[type];
    final lastTime = _lastOccurrence[type];
    final count = _typeCounts[type];

    if (firstTime != null && lastTime != null && count != null) {
      final duration = lastTime.difference(firstTime);
      if (duration.inSeconds > 0) {
        _averageFrequency[type] = count / duration.inSeconds * 3600; // 每小时
      }
    }
  }
}

/// 警报类型统计信息
class AlertTypeStatistics {
  final int count;
  final DateTime? firstOccurrence;
  final DateTime? lastOccurrence;
  final double frequency;

  AlertTypeStatistics({
    required this.count,
    this.firstOccurrence,
    this.lastOccurrence,
    required this.frequency,
  });

  Map<String, dynamic> toJson() => {
        'count': count,
        'firstOccurrence': firstOccurrence?.toIso8601String(),
        'lastOccurrence': lastOccurrence?.toIso8601String(),
        'frequency': frequency,
      };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('发生次数: $count');
    if (firstOccurrence != null) {
      buffer.writeln('首次出现: $firstOccurrence');
    }
    if (lastOccurrence != null) {
      buffer.writeln('最后出现: $lastOccurrence');
    }
    buffer.write('平均频率: ${frequency.toStringAsFixed(2)}次/小时');
    return buffer.toString();
  }
}
