import 'dart:async';
import 'dart:math';

import '../utils/check_logger.dart';

/// 消耗预警
class BurnAlert {
  final String serviceId;
  final SLOType type;
  final double currentRate;
  final double predictedRate;
  final Duration timeToExhaustion;
  final List<String> recommendations;
  final DateTime timestamp;

  const BurnAlert({
    required this.serviceId,
    required this.type,
    required this.currentRate,
    required this.predictedRate,
    required this.timeToExhaustion,
    this.recommendations = const [],
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'type': type.toString(),
        'currentRate': currentRate,
        'predictedRate': predictedRate,
        'timeToExhaustion': timeToExhaustion.inSeconds,
        'recommendations': recommendations,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// SLO分析器
class SLOAnalyzer {
  final CheckLogger logger;
  final SLOConfig config;
  final _events = <String, List<SLOEvent>>{};
  final _assessments = <String, List<SLOAssessment>>{};
  Timer? _analysisTimer;

  SLOAnalyzer({
    required this.config,
    CheckLogger? logger,
  }) : logger = logger ?? CheckLogger.instance {
    _startAnalysisTimer();
  }

  /// 评估服务SLO
  Future<SLOAssessment> assessService(String serviceId) async {
    final events = _events[serviceId] ?? [];
    if (events.isEmpty) {
      return SLOAssessment(
        serviceId: serviceId,
        compliance: {},
        remainingBudget: config.errorBudget,
        status: SLOStatus.healthy,
        timestamp: DateTime.now(),
      );
    }

    // 计算合规状况
    final compliance = <SLOType, double>{};
    final violations = <SLOType, List<String>>{};

    for (final type in SLOType.values) {
      final typeEvents = events.where((e) => e.type == type).toList();
      if (typeEvents.isNotEmpty) {
        final successRate =
            typeEvents.where((e) => e.success).length / typeEvents.length;
        compliance[type] = successRate;

        // 检查违规
        final objective = config.objectives['${serviceId}_$type'] ?? 0.99;
        if (successRate < objective) {
          violations[type] = [
            '成功率 ${(successRate * 100).toStringAsFixed(2)}% 低于目标值 ${(objective * 100).toStringAsFixed(2)}%'
          ];
        }
      }
    }

    // 计算剩余错误预算
    final errors = events.where((e) => !e.success).length;
    final remainingBudget = max(0, config.errorBudget - errors);

    // 确定状态
    final status = _determineStatus(compliance, remainingBudget);

    // 收集指标
    final metrics = _collectMetrics(events);

    final assessment = SLOAssessment(
      serviceId: serviceId,
      compliance: compliance,
      violations: violations,
      remainingBudget: remainingBudget,
      status: status,
      metrics: metrics,
      timestamp: DateTime.now(),
    );

    _assessments.putIfAbsent(serviceId, () => []).add(assessment);

    return assessment;
  }

  /// 释放资源
  void dispose() {
    _analysisTimer?.cancel();
    _events.clear();
    _assessments.clear();
  }

  /// 获取历史评估
  List<SLOAssessment> getAssessmentHistory(
    String serviceId, {
    DateTime? start,
    DateTime? end,
  }) {
    final assessments = _assessments[serviceId] ?? [];
    return assessments.where((a) {
      if (start != null && a.timestamp.isBefore(start)) return false;
      if (end != null && a.timestamp.isAfter(end)) return false;
      return true;
    }).toList();
  }

  /// 预测违约风险
  Future<List<BurnAlert>> predictBurnRate(String serviceId) async {
    final events = _events[serviceId] ?? [];
    if (events.isEmpty) return [];

    final alerts = <BurnAlert>[];
    final now = DateTime.now();
    const window = Duration(hours: 1);
    final recentTime = now.subtract(window);

    for (final type in SLOType.values) {
      // 获取最近事件
      final recentEvents = events
          .where((e) => e.type == type && e.timestamp.isAfter(recentTime))
          .toList();

      if (recentEvents.isEmpty) continue;

      // 计算当前错误率
      final currentErrors = recentEvents.where((e) => !e.success).length;
      final currentRate = currentErrors / recentEvents.length;

      // 预测未来错误率
      final predictedRate = await _predictErrorRate(
        events.where((e) => e.type == type).toList(),
        window,
      );

      // 如果预测率正常，跳过
      if (predictedRate <= currentRate) continue;

      // 计算预算耗尽时间
      final budgetPerHour = events.length /
          events.last.timestamp.difference(events.first.timestamp).inHours;

      final remainingBudget =
          config.errorBudget - events.where((e) => !e.success).length;

      final timeToExhaustion = Duration(
          hours: (remainingBudget / (predictedRate * budgetPerHour)).round());

      // 生成建议
      final recommendations = _generateRecommendations(
        type,
        currentRate,
        predictedRate,
        timeToExhaustion,
      );

      alerts.add(BurnAlert(
        serviceId: serviceId,
        type: type,
        currentRate: currentRate,
        predictedRate: predictedRate,
        timeToExhaustion: timeToExhaustion,
        recommendations: recommendations,
        timestamp: now,
      ));
    }

    return alerts;
  }

  /// 记录SLO事件
  void recordEvent(SLOEvent event) {
    _events.putIfAbsent(event.serviceId, () => []).add(event);
    _cleanHistory(event.serviceId);

    logger.info('''
记录SLO事件:
- 服务: ${event.serviceId}
- 类型: ${event.type}
- 值: ${event.value}
- 成功: ${event.success}
''');
  }

  /// 清理历史数据
  void _cleanHistory(String serviceId) {
    final events = _events[serviceId] ?? [];
    final assessments = _assessments[serviceId] ?? [];

    // 获取最大窗口
    final maxWindow = config.windows.values
        .fold<Duration>(Duration.zero, (a, b) => a > b ? a : b);

    final cutoff = DateTime.now().subtract(maxWindow);

    // 清理过期数据
    _events[serviceId] = events
        .where(
          (e) => e.timestamp.isAfter(cutoff),
        )
        .toList();

    _assessments[serviceId] = assessments
        .where(
          (a) => a.timestamp.isAfter(cutoff),
        )
        .toList();
  }

  /// 收集指标
  Map<String, dynamic> _collectMetrics(List<SLOEvent> events) {
    if (events.isEmpty) return {};

    return {
      'total_count': events.length,
      'success_count': events.where((e) => e.success).length,
      'error_count': events.where((e) => !e.success).length,
      'types': events.map((e) => e.type).toSet().length,
      'last_timestamp': events.last.timestamp.toIso8601String(),
    };
  }

  /// 确定状态
  SLOStatus _determineStatus(
    Map<SLOType, double> compliance,
    int remainingBudget,
  ) {
    if (compliance.isEmpty) return SLOStatus.healthy;

    // 计算加权平均值
    var total = 0.0;
    var weight = 0.0;

    for (final entry in compliance.entries) {
      final w = config.weights[entry.key] ?? 1.0;
      total += entry.value * w;
      weight += w;
    }

    final avgCompliance = total / weight;

    // 基于合规率和预算确定状态
    if (avgCompliance < 0.9 || remainingBudget < config.errorBudget * 0.1) {
      return SLOStatus.critical;
    } else if (avgCompliance < 0.95 ||
        remainingBudget < config.errorBudget * 0.3) {
      return SLOStatus.breaching;
    } else if (avgCompliance < 0.98 ||
        remainingBudget < config.errorBudget * 0.5) {
      return SLOStatus.warning;
    } else {
      return SLOStatus.healthy;
    }
  }

  /// 生成建议
  List<String> _generateRecommendations(
    SLOType type,
    double currentRate,
    double predictedRate,
    Duration timeToExhaustion,
  ) {
    final recommendations = <String>[];

    // 基于类型的建议
    switch (type) {
      case SLOType.availability:
        recommendations.addAll([
          '检查系统健康状态',
          '评估自动恢复机制',
          '考虑增加冗余部署',
        ]);
      case SLOType.latency:
        recommendations.addAll([
          '分析性能瓶颈',
          '优化关键路径',
          '考虑资源扩容',
        ]);
      case SLOType.throughput:
        recommendations.addAll([
          '评估系统容量',
          '检查限流策略',
          '优化资源利用',
        ]);
      case SLOType.errorRate:
        recommendations.addAll([
          '分析错误模式',
          '增强错误处理',
          '实施熔断机制',
        ]);
      case SLOType.saturation:
        recommendations.addAll([
          '监控资源使用',
          '评估扩容需求',
          '优化资源配置',
        ]);
    }

    // 基于紧急程度的建议
    if (timeToExhaustion.inHours < 24) {
      recommendations.addAll([
        '触发应急响应',
        '准备降级方案',
        '评估故障域',
      ]);
    }

    // 基于趋势的建议
    if (predictedRate > currentRate * 1.5) {
      recommendations.addAll([
        '深入分析增长趋势',
        '评估长期解决方案',
        '考虑架构优化',
      ]);
    }

    return recommendations;
  }

  /// 预测错误率
  Future<double> _predictErrorRate(
    List<SLOEvent> events,
    Duration window,
  ) async {
    if (events.isEmpty) return 0.0;

    // 简单线性回归
    final x = List.generate(events.length, (i) => i.toDouble());
    final y = events.map((e) => e.success ? 0.0 : 1.0).toList();

    final xMean = x.reduce((a, b) => a + b) / x.length;
    final yMean = y.reduce((a, b) => a + b) / y.length;

    var numerator = 0.0;
    var denominator = 0.0;

    for (var i = 0; i < events.length; i++) {
      final xDiff = x[i] - xMean;
      final yDiff = y[i] - yMean;
      numerator += xDiff * yDiff;
      denominator += xDiff * xDiff;
    }

    if (denominator == 0) return yMean;

    final slope = numerator / denominator;
    final intercept = yMean - slope * xMean;

    // 预测未来错误率
    final futureX = x.length + window.inMinutes / 60;
    final predicted = slope * futureX + intercept;

    return max(0.0, min(1.0, predicted));
  }

  /// 启动分析定时器
  void _startAnalysisTimer() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(
      config.updateInterval,
      (_) async {
        for (final serviceId in _events.keys) {
          try {
            await assessService(serviceId);
            await predictBurnRate(serviceId);
          } catch (e) {
            logger.error('定时评估失败: $serviceId', e);
          }
        }
      },
    );
  }
}

/// SLO评估结果
class SLOAssessment {
  final String serviceId;
  final Map<SLOType, double> compliance;
  final Map<SLOType, List<String>> violations;
  final int remainingBudget;
  final SLOStatus status;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;

  const SLOAssessment({
    required this.serviceId,
    required this.compliance,
    this.violations = const {},
    required this.remainingBudget,
    required this.status,
    this.metrics = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'compliance': Map.fromEntries(
            compliance.entries.map((e) => MapEntry(e.key.toString(), e.value))),
        'violations': Map.fromEntries(
            violations.entries.map((e) => MapEntry(e.key.toString(), e.value))),
        'remainingBudget': remainingBudget,
        'status': status.toString(),
        'metrics': metrics,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// SLO配置
class SLOConfig {
  final Map<String, double> objectives;
  final Map<String, Duration> windows;
  final Map<SLOType, double> weights;
  final WindowType windowType;
  final Duration updateInterval;
  final int errorBudget;

  const SLOConfig({
    this.objectives = const {},
    this.windows = const {},
    this.weights = const {},
    this.windowType = WindowType.sliding,
    this.updateInterval = const Duration(minutes: 1),
    this.errorBudget = 1000,
  });
}

/// SLO事件
class SLOEvent {
  final String serviceId;
  final SLOType type;
  final double value;
  final bool success;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  const SLOEvent({
    required this.serviceId,
    required this.type,
    required this.value,
    required this.success,
    this.metadata = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'type': type.toString(),
        'value': value,
        'success': success,
        'metadata': metadata,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// 状态级别
enum SLOStatus {
  healthy, // 健康
  warning, // 警告
  breaching, // 违约
  critical, // 严重
}

/// SLO类型
enum SLOType {
  availability, // 可用性
  latency, // 延迟
  throughput, // 吞吐量
  errorRate, // 错误率
  saturation, // 饱和度
}

/// 统计窗口类型
enum WindowType {
  rolling, // 滚动窗口
  sliding, // 滑动窗口
  tumbling, // 翻转窗口
}
