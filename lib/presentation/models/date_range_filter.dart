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
  final DateRangePreset? preset;
  final DateTime? startDate;  // Match these parameter names
  final DateTime? endDate;    // with the ones used in constructor

  const DateRangeFilter({
    this.preset,
    this.startDate,
    this.endDate,
  });

  factory DateRangeFilter.preset(DateRangePreset preset) {
    return DateRangeFilter(preset: preset);
  }

  DateTimeRange? get effectiveRange {
    if (preset != null) {
      return preset!.getRange();
    }
    
    if (startDate != null || endDate != null) {
      return DateTimeRange(
        start: startDate ?? DateTime(1900),
        end: endDate ?? DateTime.now(),
      );
    }
    
    return null;
  }

  bool get isEmpty => startDate == null && endDate == null && preset == null;

  bool contains(DateTime date) {
    final range = effectiveRange;
    if (range == null) return true;
    return !date.isBefore(range.start) && !date.isAfter(range.end);
  }

  Map<String, dynamic> toJson() => {
    'start': startDate?.toIso8601String(),
    'end': endDate?.toIso8601String(),
    'preset': preset?.name,
  };

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) {
    return DateRangeFilter(
      startDate: json['start'] != null ? DateTime.parse(json['start']) : null,
      endDate: json['end'] != null ? DateTime.parse(json['end']) : null,
      preset: json['preset'] != null 
          ? DateRangePreset.values.byName(json['preset']) 
          : null,
    );
  }

  DateRangeFilter copyWith({
    DateTime? Function()? startDate,
    DateTime? Function()? endDate,
    DateRangePreset? Function()? preset,
  }) {
    return DateRangeFilter(
      startDate: startDate != null ? startDate() : this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      preset: preset != null ? preset() : this.preset,
    );
  }

  // 添加格式化显示文本
  String get displayText {
    if (preset != null) {
      return preset!.label;
    }
    
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate!)} 至 ${_formatDate(endDate!)}';
    } else if (startDate != null) {
      return '${_formatDate(startDate!)} 之后';
    } else if (endDate != null) {
      return '${_formatDate(endDate!)} 之前';
    }
    
    return '全部时间';
  }

  // 添加日期校验
  bool get isValid {
    if (preset != null) return true;
    if (startDate != null && endDate != null) {
      return !startDate!.isAfter(endDate!);
    }
    return true;
  }

  // 添加日期区间长度计算
  int? get dayCount {
    final range = effectiveRange;
    if (range == null) return null;
    return range.duration.inDays + 1;
  }

  // 添加相等性比较
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateRangeFilter &&
        other.preset == preset &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(preset, startDate, endDate);

  // 辅助方法：格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }

  // 创建一个空过滤器的工厂方法
  factory DateRangeFilter.empty() => const DateRangeFilter();

  // 创建一个"截止到今天"的工厂方法
  factory DateRangeFilter.untilToday() {
    return DateRangeFilter(endDate: DateTime.now());
  }

  // 创建一个"从某天开始"的工厂方法
  factory DateRangeFilter.fromDate(DateTime startDate) {
    return DateRangeFilter(startDate: startDate);
  }
}
