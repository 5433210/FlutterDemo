import 'alert_types.dart';

/// 警报过滤器
class AlertFilter {
  final List<AlertFilterCriteria> _filters = [];

  /// 添加过滤条件
  void addFilter(AlertFilterCriteria criteria) {
    _filters.add(criteria);
  }

  /// 应用过滤器
  List<AlertRecord> apply(Iterable<AlertRecord> alerts) {
    if (_filters.isEmpty) return alerts.toList();

    return alerts.where((alert) {
      return _filters.any((filter) => filter.matches(alert));
    }).toList();
  }

  /// 清除所有过滤条件
  void clearFilters() {
    _filters.clear();
  }

  /// 移除过滤条件
  void removeFilter(AlertFilterCriteria criteria) {
    _filters.remove(criteria);
  }

  static AlertFilterCriteria byLevel(AlertLevel level) {
    return AlertFilterCriteria(
      levels: {level},
    );
  }

  static AlertFilterCriteria byTimeRange(DateTime start, DateTime end) {
    return AlertFilterCriteria(
      startTime: start,
      endTime: end,
    );
  }

  static AlertFilterCriteria byType(String type) {
    return AlertFilterCriteria(
      types: {type},
    );
  }

  static AlertFilterCriteria lastDay() {
    final now = DateTime.now();
    return AlertFilterCriteria(
      startTime: now.subtract(const Duration(days: 1)),
      endTime: now,
    );
  }

  /// 创建常用过滤器
  static AlertFilterCriteria onlyErrors() {
    return const AlertFilterCriteria(
      levels: {AlertLevel.error, AlertLevel.critical},
    );
  }

  static AlertFilterCriteria withPattern(String pattern) {
    return AlertFilterCriteria(
      messagePattern: pattern,
    );
  }
}

/// 过滤器构建器
class AlertFilterBuilder {
  AlertFilterCriteria _criteria = const AlertFilterCriteria();

  AlertFilterCriteria build() => _criteria;

  AlertFilterBuilder withDetails(Map<String, dynamic> details) {
    _criteria = _criteria.copyWith(details: details);
    return this;
  }

  AlertFilterBuilder withLevels(Set<AlertLevel> levels) {
    _criteria = _criteria.copyWith(levels: levels);
    return this;
  }

  AlertFilterBuilder withPattern(String pattern) {
    _criteria = _criteria.copyWith(messagePattern: pattern);
    return this;
  }

  AlertFilterBuilder withSuppressed(bool include) {
    _criteria = _criteria.copyWith(hasSuppressed: include);
    return this;
  }

  AlertFilterBuilder withTimeRange(DateTime start, DateTime end) {
    _criteria = _criteria.copyWith(
      startTime: start,
      endTime: end,
    );
    return this;
  }

  AlertFilterBuilder withTypes(Set<String> types) {
    _criteria = _criteria.copyWith(types: types);
    return this;
  }
}

/// 警报过滤条件
class AlertFilterCriteria {
  final Set<String>? types;
  final Set<AlertLevel>? levels;
  final DateTime? startTime;
  final DateTime? endTime;
  final Map<String, dynamic>? details;
  final String? messagePattern;
  final bool? hasSuppressed;

  const AlertFilterCriteria({
    this.types,
    this.levels,
    this.startTime,
    this.endTime,
    this.details,
    this.messagePattern,
    this.hasSuppressed,
  });

  AlertFilterCriteria copyWith({
    Set<String>? types,
    Set<AlertLevel>? levels,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? details,
    String? messagePattern,
    bool? hasSuppressed,
  }) {
    return AlertFilterCriteria(
      types: types ?? this.types,
      levels: levels ?? this.levels,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      details: details ?? this.details,
      messagePattern: messagePattern ?? this.messagePattern,
      hasSuppressed: hasSuppressed ?? this.hasSuppressed,
    );
  }

  bool matches(AlertRecord alert) {
    // 检查类型
    if (types != null && !types!.contains(alert.type)) {
      return false;
    }

    // 检查级别
    if (levels != null && !levels!.contains(alert.level)) {
      return false;
    }

    // 检查时间范围
    if (startTime != null && alert.timestamp.isBefore(startTime!)) {
      return false;
    }
    if (endTime != null && alert.timestamp.isAfter(endTime!)) {
      return false;
    }

    // 检查详细信息
    if (details != null) {
      if (alert.details == null) return false;
      for (final entry in details!.entries) {
        if (alert.details![entry.key] != entry.value) {
          return false;
        }
      }
    }

    // 检查消息模式
    if (messagePattern != null &&
        !alert.message.contains(RegExp(messagePattern!))) {
      return false;
    }

    return true;
  }
}
