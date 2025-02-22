import 'package:flutter/material.dart';

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
    };
  }
}

enum DateRangeType {
  preset, // 预设快捷选项
  beforeDate, // 某日期之前
  afterDate, // 某日期之后
  between // 日期范围之间
}

class DateRangeFilter {
  final DateTime? start;
  final DateTime? end;
  final DateRangePreset? preset;

  const DateRangeFilter({
    this.start,
    this.end,
    this.preset,
  });

  bool get isEmpty => start == null && end == null && preset == null;

  DateTimeRange? get effectiveRange {
    if (isEmpty) return null;
    if (preset != null) return preset!.getRange();
    return DateTimeRange(
      start: start ?? DateTime(1900),
      end: end ?? DateTime.now(),
    );
  }

  bool contains(DateTime date) {
    final range = effectiveRange;
    if (range == null) return true;
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  Map<String, dynamic> toJson() => {
    'start': start?.toIso8601String(),
    'end': end?.toIso8601String(),
    'preset': preset?.name,
  };

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) {
    return DateRangeFilter(
      start: json['start'] != null ? DateTime.parse(json['start']) : null,
      end: json['end'] != null ? DateTime.parse(json['end']) : null,
      preset: json['preset'] != null 
          ? DateRangePreset.values.byName(json['preset']) 
          : null,
    );
  }

  DateRangeFilter copyWith({
    DateTime? Function()? start,
    DateTime? Function()? end,
    DateRangePreset? Function()? preset,
  }) {
    return DateRangeFilter(
      start: start != null ? start() : this.start,
      end: end != null ? end() : this.end,
      preset: preset != null ? preset() : this.preset,
    );
  }
}
