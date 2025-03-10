import 'dart:async';
import 'dart:math';

import '../utils/check_logger.dart';

/// 季节分析结果
class SeasonalAnalysis {
  final List<SeasonalPattern> detectedPatterns;
  final Map<SeasonalPattern, double> significance;
  final Map<DateTime, Map<SeasonalPattern, double>> factors;
  final Map<TimeCharacteristic, TimeRange> timeRanges;
  final DateTime timestamp;

  const SeasonalAnalysis({
    required this.detectedPatterns,
    required this.significance,
    required this.factors,
    required this.timeRanges,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'patterns': detectedPatterns.map((p) => p.toString()).toList(),
        'significance': Map.fromEntries(significance.entries
            .map((e) => MapEntry(e.key.toString(), e.value))),
        'factors': factors.map((k, v) => MapEntry(
            k.toIso8601String(),
            Map.fromEntries(
                v.entries.map((e) => MapEntry(e.key.toString(), e.value))))),
        'timeRanges':
            timeRanges.map((k, v) => MapEntry(k.toString(), v.toJson())),
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 季节分析器
class SeasonalAnalyzer {
  final CheckLogger logger;
  final SeasonalConfig config;
  final _data = <DateTime, double>{};
  final _analyses = <SeasonalAnalysis>[];
  Timer? _analysisTimer;

  SeasonalAnalyzer({
    required this.config,
    CheckLogger? logger,
  }) : logger = logger ?? CheckLogger.instance {
    _startAnalysisTimer();
  }

  /// 应用季节调整
  double adjustValue(
    double value,
    DateTime time,
    SeasonalAnalysis analysis,
  ) {
    var adjustedValue = value;

    // 应用每个模式的调整
    for (final pattern in analysis.detectedPatterns) {
      final significance = analysis.significance[pattern] ?? 0;
      if (significance < config.significanceThreshold) continue;

      final factor = analysis.factors[time]?[pattern] ?? 1.0;
      adjustedValue /= factor; // 消除季节影响
    }

    return adjustedValue;
  }

  /// 分析季节性
  Future<SeasonalAnalysis> analyze({
    DateTime? start,
    DateTime? end,
  }) async {
    start ??= DateTime.now().subtract(config.minAnalysisPeriod);
    end ??= DateTime.now();

    // 筛选数据
    final data = Map.fromEntries(_data.entries
        .where((e) => e.key.isAfter(start!) && e.key.isBefore(end!)));

    if (data.isEmpty) {
      return SeasonalAnalysis(
        detectedPatterns: [],
        significance: {},
        factors: {},
        timeRanges: {},
        timestamp: DateTime.now(),
      );
    }

    // 检测模式
    final patterns = config.autoDetect
        ? await _detectPatterns(data)
        : config.factors.map((f) => f.pattern).toList();

    // 计算显著性
    final significance = await _calculateSignificance(
      patterns,
      data,
    );

    // 计算因子
    final factors = await _calculateFactors(
      patterns,
      data,
    );

    // 识别时间范围
    final timeRanges = _identifyTimeRanges(data);

    final analysis = SeasonalAnalysis(
      detectedPatterns: patterns,
      significance: significance,
      factors: factors,
      timeRanges: timeRanges,
      timestamp: DateTime.now(),
    );

    _analyses.add(analysis);
    return analysis;
  }

  /// 释放资源
  void dispose() {
    _analysisTimer?.cancel();
    _data.clear();
    _analyses.clear();
  }

  /// 记录数据点
  void recordDataPoint(DateTime time, double value) {
    _data[time] = value;
    _cleanHistory();

    logger.info('''
记录数据点:
- 时间: $time
- 值: $value
''');
  }

  /// 应用模式因子
  Map<DateTime, double> _applyPatternFactors(
    Map<DateTime, double> data,
    Map<int, double> factors,
  ) {
    return Map.fromEntries(
      data.entries.map((entry) {
        final value = entry.value;
        final factor = factors[entry.key.hour] ?? 1.0;
        return MapEntry(entry.key, value / factor);
      }),
    );
  }

  /// 计算季节因子
  Future<Map<DateTime, Map<SeasonalPattern, double>>> _calculateFactors(
    List<SeasonalPattern> patterns,
    Map<DateTime, double> data,
  ) async {
    final factors = <DateTime, Map<SeasonalPattern, double>>{};

    for (final time in data.keys) {
      factors[time] = {};

      for (final pattern in patterns) {
        final patternFactors = await _calculatePatternFactors(pattern, data);
        factors[time]![pattern] = _getPatternFactor(time, patternFactors);
      }
    }

    return factors;
  }

  /// 计算模式因子
  Future<Map<int, double>> _calculatePatternFactors(
    SeasonalPattern pattern,
    Map<DateTime, double> data,
  ) async {
    final groups = <int, List<double>>{};

    // 按模式分组
    for (final entry in data.entries) {
      final index = switch (pattern) {
        SeasonalPattern.hourly => entry.key.hour,
        SeasonalPattern.daily => entry.key.day,
        SeasonalPattern.weekly => entry.key.weekday,
        SeasonalPattern.monthly => entry.key.month,
        SeasonalPattern.custom => 0,
      };

      groups.putIfAbsent(index, () => []).add(entry.value);
    }

    // 计算每组的平均值
    final factors = <int, double>{};
    final overallMean = data.values.reduce((a, b) => a + b) / data.length;

    for (final entry in groups.entries) {
      final mean = entry.value.reduce((a, b) => a + b) / entry.value.length;
      factors[entry.key] = mean / overallMean;
    }

    return factors;
  }

  /// 计算模式显著性
  Future<Map<SeasonalPattern, double>> _calculateSignificance(
    List<SeasonalPattern> patterns,
    Map<DateTime, double> data,
  ) async {
    final significance = <SeasonalPattern, double>{};

    for (final pattern in patterns) {
      // 计算模式解释的方差比例
      final factors = await _calculatePatternFactors(pattern, data);
      final adjustedData = _applyPatternFactors(data, factors);

      final originalVariance = _calculateVariance(data.values.toList());
      final adjustedVariance = _calculateVariance(adjustedData.values.toList());

      // 显著性 = 解释的方差比例
      significance[pattern] =
          (originalVariance - adjustedVariance) / originalVariance;
    }

    return significance;
  }

  /// 计算方差
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;

    final mean = values.reduce((a, b) => a + b) / values.length;
    return values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        values.length;
  }

  /// 清理历史数据
  void _cleanHistory() {
    final cutoff = DateTime.now().subtract(config.maxAnalysisPeriod);

    _data.removeWhere((time, _) => time.isBefore(cutoff));
    _analyses.removeWhere((a) => a.timestamp.isBefore(cutoff));
  }

  /// 创建时间范围
  TimeRange _createTimeRange(List<int> hours) {
    hours.sort();

    return TimeRange(
      start: TimeOfDay(hour: hours.first, minute: 0),
      end: TimeOfDay(hour: hours.last + 1, minute: 0),
    );
  }

  /// 检测季节模式
  Future<List<SeasonalPattern>> _detectPatterns(
    Map<DateTime, double> data,
  ) async {
    final patterns = <SeasonalPattern>[];

    // 检测小时模式
    if (await _hasHourlyPattern(data)) {
      patterns.add(SeasonalPattern.hourly);
    }

    // 检测日模式
    if (await _hasDailyPattern(data)) {
      patterns.add(SeasonalPattern.daily);
    }

    // 检测周模式
    if (await _hasWeeklyPattern(data)) {
      patterns.add(SeasonalPattern.weekly);
    }

    // 检测月模式
    if (await _hasMonthlyPattern(data)) {
      patterns.add(SeasonalPattern.monthly);
    }

    return patterns;
  }

  /// 获取模式因子
  double _getPatternFactor(
    DateTime time,
    Map<int, double> factors,
  ) {
    final index = time.hour; // 使用小时作为默认
    return factors[index] ?? 1.0;
  }

  /// 检测日模式
  Future<bool> _hasDailyPattern(Map<DateTime, double> data) async {
    final dailyAverages = <int, List<double>>{};

    // 按日分组数据
    for (final entry in data.entries) {
      final day = entry.key.day;
      dailyAverages.putIfAbsent(day, () => []).add(entry.value);
    }

    // 分析日间变化
    final averages = dailyAverages.values
        .map((values) => values.reduce((a, b) => a + b) / values.length)
        .toList();

    if (averages.length < 2) return false;

    // 计算日间变异系数
    final mean = averages.reduce((a, b) => a + b) / averages.length;
    final variance =
        averages.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            (averages.length - 1);
    final stdDev = sqrt(variance);
    final cv = stdDev / mean;

    return cv < 0.3; // 日间变化相对稳定
  }

  /// 检测小时模式
  Future<bool> _hasHourlyPattern(Map<DateTime, double> data) async {
    final hourlyAverages = <int, List<double>>{};

    // 按小时分组数据
    for (final entry in data.entries) {
      final hour = entry.key.hour;
      hourlyAverages.putIfAbsent(hour, () => []).add(entry.value);
    }

    // 计算每小时的变异系数
    final cvs = <double>[];
    for (final values in hourlyAverages.values) {
      if (values.length < 2) continue;

      final mean = values.reduce((a, b) => a + b) / values.length;
      final variance =
          values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
              (values.length - 1);
      final stdDev = sqrt(variance);
      final cv = stdDev / mean;
      cvs.add(cv);
    }

    // 如果变异系数较小，说明存在小时模式
    return cvs.isNotEmpty && cvs.reduce((a, b) => a + b) / cvs.length < 0.5;
  }

  /// 检测月模式
  Future<bool> _hasMonthlyPattern(Map<DateTime, double> data) async {
    final monthlyAverages = <int, List<double>>{};

    // 按月分组数据
    for (final entry in data.entries) {
      final month = entry.key.month;
      monthlyAverages.putIfAbsent(month, () => []).add(entry.value);
    }

    // 检查是否有足够的数据
    if (monthlyAverages.length < 2) return false;

    // 计算月平均值
    final averages = monthlyAverages.values
        .map((values) => values.reduce((a, b) => a + b) / values.length)
        .toList();

    // 计算变异系数
    final mean = averages.reduce((a, b) => a + b) / averages.length;
    final variance =
        averages.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            (averages.length - 1);
    final stdDev = sqrt(variance);
    final cv = stdDev / mean;

    return cv > 0.15; // 月间变化显著
  }

  /// 检测周模式
  Future<bool> _hasWeeklyPattern(Map<DateTime, double> data) async {
    final weekdayAverages = <int, List<double>>{};

    // 按星期几分组数据
    for (final entry in data.entries) {
      final weekday = entry.key.weekday;
      weekdayAverages.putIfAbsent(weekday, () => []).add(entry.value);
    }

    // 检查是否有足够的数据
    if (weekdayAverages.length < 7) return false;

    // 分析工作日和周末的差异
    final workdayValues = <double>[];
    final weekendValues = <double>[];

    for (final entry in weekdayAverages.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (entry.key <= 5) {
        workdayValues.add(avg);
      } else {
        weekendValues.add(avg);
      }
    }

    if (workdayValues.isEmpty || weekendValues.isEmpty) return false;

    // 计算工作日和周末的均值
    final workdayMean =
        workdayValues.reduce((a, b) => a + b) / workdayValues.length;
    final weekendMean =
        weekendValues.reduce((a, b) => a + b) / weekendValues.length;

    // 如果差异显著，说明存在周模式
    return (workdayMean - weekendMean).abs() / workdayMean > 0.2;
  }

  /// 识别时间范围
  Map<TimeCharacteristic, TimeRange> _identifyTimeRanges(
    Map<DateTime, double> data,
  ) {
    final ranges = <TimeCharacteristic, TimeRange>{};

    // 按小时统计值
    final hourlyStats = <int, List<double>>{};
    for (final entry in data.entries) {
      final hour = entry.key.hour;
      hourlyStats.putIfAbsent(hour, () => []).add(entry.value);
    }

    // 计算每小时的平均值
    final hourlyAverages = <int, double>{};
    for (final entry in hourlyStats.entries) {
      hourlyAverages[entry.key] =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // 确定阈值
    final values = hourlyAverages.values.toList();
    final mean = values.reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length);

    final highThreshold = mean + stdDev;
    final lowThreshold = mean - stdDev;

    // 识别特征时段
    final peakHours = <int>[];
    final quietHours = <int>[];
    final normalHours = <int>[];

    for (final entry in hourlyAverages.entries) {
      if (entry.value > highThreshold) {
        peakHours.add(entry.key);
      } else if (entry.value < lowThreshold) {
        quietHours.add(entry.key);
      } else {
        normalHours.add(entry.key);
      }
    }

    // 创建时间范围
    if (peakHours.isNotEmpty) {
      ranges[TimeCharacteristic.peak] = _createTimeRange(peakHours);
    }
    if (quietHours.isNotEmpty) {
      ranges[TimeCharacteristic.quiet] = _createTimeRange(quietHours);
    }
    if (normalHours.isNotEmpty) {
      ranges[TimeCharacteristic.normal] = _createTimeRange(normalHours);
    }

    // 添加维护时段（通常在负载最低时）
    if (quietHours.isNotEmpty) {
      final maintenanceHour = quietHours[quietHours.length ~/ 2];
      ranges[TimeCharacteristic.maintenance] = TimeRange(
        start: TimeOfDay(hour: maintenanceHour, minute: 0),
        end: TimeOfDay(hour: maintenanceHour + 1, minute: 0),
      );
    }

    return ranges;
  }

  /// 启动分析定时器
  void _startAnalysisTimer() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) async {
        try {
          await analyze();
        } catch (e) {
          logger.error('定时分析失败', e);
        }
      },
    );
  }
}

/// 季节配置
class SeasonalConfig {
  final List<SeasonalFactor> factors;
  final Duration minAnalysisPeriod;
  final Duration maxAnalysisPeriod;
  final bool autoDetect;
  final double significanceThreshold;

  const SeasonalConfig({
    this.factors = const [],
    this.minAnalysisPeriod = const Duration(hours: 24),
    this.maxAnalysisPeriod = const Duration(days: 30),
    this.autoDetect = true,
    this.significanceThreshold = 0.1,
  });
}

/// 季节因子
class SeasonalFactor {
  final SeasonalPattern pattern;
  final Duration period;
  final Map<DateTime, double> factors;
  final Map<TimeCharacteristic, List<TimeOfDay>> timeSlots;

  const SeasonalFactor({
    required this.pattern,
    required this.period,
    required this.factors,
    required this.timeSlots,
  });

  /// 获取季节因子
  double getFactor(DateTime time) {
    return factors[time] ?? 1.0;
  }

  /// 查找时段特征
  TimeCharacteristic getTimeCharacteristic(DateTime time) {
    final timeOfDay = TimeOfDay.fromDateTime(time);

    for (final entry in timeSlots.entries) {
      if (entry.value.any((slot) =>
          slot.hour == timeOfDay.hour && slot.minute == timeOfDay.minute)) {
        return entry.key;
      }
    }

    return TimeCharacteristic.normal;
  }
}

/// 季节性模式
enum SeasonalPattern {
  hourly, // 小时模式
  daily, // 日模式
  weekly, // 周模式
  monthly, // 月模式
  custom, // 自定义模式
}

/// 时段特征
enum TimeCharacteristic {
  peak, // 高峰期
  normal, // 正常期
  quiet, // 静默期
  maintenance, // 维护期
}

/// 时间
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({
    required this.hour,
    required this.minute,
  });

  factory TimeOfDay.fromDateTime(DateTime time) {
    return TimeOfDay(
      hour: time.hour,
      minute: time.minute,
    );
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }
}

/// 时间范围
class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;
  final Set<int> daysOfWeek;
  final Set<int> daysOfMonth;
  final Set<int> months;

  const TimeRange({
    required this.start,
    required this.end,
    this.daysOfWeek = const {},
    this.daysOfMonth = const {},
    this.months = const {},
  });

  Map<String, dynamic> toJson() => {
        'start': '${start.hour}:${start.minute}',
        'end': '${end.hour}:${end.minute}',
        'daysOfWeek': daysOfWeek.toList(),
        'daysOfMonth': daysOfMonth.toList(),
        'months': months.toList(),
      };
}
