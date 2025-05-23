import 'package:flutter/material.dart';

class DateRangeFilter {
  final DateRangePreset? preset;
  final DateTime? start; // Match these parameter names
  final DateTime? end; // with the ones used in constructor

  const DateRangeFilter({
    this.preset,
    this.start,
    this.end,
  });

  // 创建一个空过滤器的工厂方法
  factory DateRangeFilter.empty() => const DateRangeFilter();

  // 创建一个"从某天开始"的工厂方法
  factory DateRangeFilter.fromDate(DateTime startDate) {
    return DateRangeFilter(start: startDate);
  }

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) {
    return DateRangeFilter(
      start: json['start'] != null ? DateTime.parse(json['start']) : null,
      end: json['end'] != null ? DateTime.parse(json['end']) : null,
      preset: json['preset'] != null
          ? DateRangePreset.values.byName(json['preset'])
          : null,
    );
  }

  factory DateRangeFilter.preset(DateRangePreset preset) {
    return DateRangeFilter(preset: preset);
  }

  // 创建一个"截止到今天"的工厂方法
  factory DateRangeFilter.untilToday() {
    return DateRangeFilter(end: DateTime.now());
  }

  // 添加日期区间长度计算
  int? get dayCount {
    final range = effectiveRange;
    if (range == null) return null;
    return range.duration.inDays + 1;
  }

  // 添加格式化显示文本
  String get displayText {
    if (preset != null) {
      return preset!.label;
    }

    if (start != null && end != null) {
      return '${_formatDate(start!)} 至 ${_formatDate(end!)}';
    } else if (start != null) {
      return '${_formatDate(start!)} 之后';
    } else if (end != null) {
      return '${_formatDate(end!)} 之前';
    }

    return '全部时间';
  }

  DateTimeRange? get effectiveRange {
    if (preset != null && preset != DateRangePreset.custom) {
      // 对于非自定义预设，使用预设的时间范围
      return preset!.getRange();
    }

    // 对于自定义预设或直接设置了start/end，使用实际的时间范围
    if (start != null || end != null) {
      final now = DateTime.now();
      return DateTimeRange(
        start: start ?? DateTime(1900),
        // 如果结束日期存在，将其设置为当天的23:59:59
        end: end != null
            ? DateTime(end!.year, end!.month, end!.day, 23, 59, 59, 999)
            : DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
      );
    }

    return null;
  }

  @override
  int get hashCode => Object.hash(preset, start, end);

  bool get isEmpty => start == null && end == null && preset == null;

  // 添加日期校验
  bool get isValid {
    if (preset != null) return true;
    if (start != null && end != null) {
      return !start!.isAfter(end!);
    }
    return true;
  }

  // 添加相等性比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRangeFilter &&
        other.preset == preset &&
        other.start == start &&
        other.end == end;
  }

  bool contains(DateTime date) {
    final range = effectiveRange;
    if (range == null) return true;
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  DateRangeFilter copyWith({
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    DateRangePreset? Function()? preset,
  }) {
    return DateRangeFilter(
      start: startDate != null ? startDate() : start,
      end: endDate != null ? endDate() : end,
      preset: preset != null ? preset() : this.preset,
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start?.toIso8601String(),
        'end': end?.toIso8601String(),
        'preset': preset?.name,
      };

  // 辅助方法：格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}

enum DateRangePreset {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  thisYear,
  lastYear,
  last7Days,
  last30Days,
  last90Days,
  last365Days,
  all,
  custom,
}

extension DateRangePresetX on DateRangePreset {
  String get label => switch (this) {
        DateRangePreset.today => '今天',
        DateRangePreset.yesterday => '昨天',
        DateRangePreset.last7Days => '最近7天',
        DateRangePreset.last30Days => '最近30天',
        DateRangePreset.last90Days => '最近90天',
        DateRangePreset.last365Days => '最近一年',
        DateRangePreset.thisMonth => '本月',
        DateRangePreset.lastMonth => '上月',
        DateRangePreset.thisYear => '今年',
        DateRangePreset.lastYear => '去年',
        DateRangePreset.thisWeek => '本周',
        DateRangePreset.lastWeek => '上周',
        DateRangePreset.all => '全部时间',
        DateRangePreset.custom => '自定义',
      };

  DateTimeRange getRange() {
    final now = DateTime.now();
    return switch (this) {
      DateRangePreset.today => DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        ),
      DateRangePreset.yesterday => DateTimeRange(
          start: DateTime(now.year, now.month, now.day - 1),
          end: DateTime(now.year, now.month, now.day),
        ),
      DateRangePreset.thisWeek => DateTimeRange(
          start: DateTime(now.year, now.month, now.day - now.weekday + 1),
          end: now,
        ),
      DateRangePreset.lastWeek => DateTimeRange(
          start: DateTime(now.year, now.month, now.day - now.weekday - 6),
          end: DateTime(now.year, now.month, now.day - now.weekday),
        ),
      DateRangePreset.thisMonth => DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        ),
      DateRangePreset.lastMonth => DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        ),
      DateRangePreset.thisYear => DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: now,
        ),
      DateRangePreset.lastYear => DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year - 1, 12, 31),
        ),
      DateRangePreset.last7Days => DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        ),
      DateRangePreset.last30Days => DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        ),
      DateRangePreset.last90Days => DateTimeRange(
          start: now.subtract(const Duration(days: 90)),
          end: now,
        ),
      DateRangePreset.last365Days => DateTimeRange(
          start: now.subtract(const Duration(days: 365)),
          end: now,
        ),
      DateRangePreset.all => DateTimeRange(
          start: DateTime(1900),
          end: now,
        ),
      DateRangePreset.custom => DateTimeRange(
          // 对于自定义模式，返回一个默认的全时间范围
          // 实际使用时应该由 DateRangeFilter.effectiveRange 决定真正的范围
          start: DateTime(1900),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        ),
    };
  }
}
