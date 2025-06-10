import 'dart:async';
import 'dart:collection';

import '../logging/logger.dart';

/// 🚀 性能监控器
/// 统计和分析应用性能指标，提供优化建议
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  // 🔧 性能指标统计
  final Map<String, _PerformanceMetric> _metrics = {};
  final Queue<_PerformanceEvent> _recentEvents = Queue();
  
  // 🔧 配置参数
  static const int _maxRecentEvents = 1000;
  static const Duration _reportInterval = Duration(minutes: 5);
  
  Timer? _reportTimer;
  bool _isMonitoring = false;

  /// 开始性能监控
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _reportTimer = Timer.periodic(_reportInterval, (_) => _generateReport());
    
    AppLogger.info(
      '性能监控已启动',
      tag: 'PerformanceMonitor',
      data: {
        'reportInterval': _reportInterval.inMinutes,
        'maxEvents': _maxRecentEvents,
      },
    );
  }

  /// 停止性能监控
  void stopMonitoring() {
    _isMonitoring = false;
    _reportTimer?.cancel();
    _reportTimer = null;
    
    AppLogger.info('性能监控已停止', tag: 'PerformanceMonitor');
  }

  /// 🚀 记录操作性能
  void recordOperation(String operation, Duration duration, {
    Map<String, dynamic>? metadata,
    bool isSuccess = true,
  }) {
    if (!_isMonitoring) return;

    // 更新指标统计
    final metric = _metrics.putIfAbsent(operation, () => _PerformanceMetric(operation));
    metric.addSample(duration, isSuccess);

    // 添加到最近事件
    final event = _PerformanceEvent(
      operation: operation,
      duration: duration,
      timestamp: DateTime.now(),
      isSuccess: isSuccess,
      metadata: metadata,
    );
    
    _recentEvents.add(event);
    
    // 保持队列大小
    while (_recentEvents.length > _maxRecentEvents) {
      _recentEvents.removeFirst();
    }

    // 检查是否需要警告
    _checkPerformanceWarnings(metric, duration);
  }

  /// 🚀 记录缓存性能
  void recordCacheOperation(String cacheType, bool isHit, Duration? duration) {
    final operation = '${cacheType}_cache';
    final metric = _metrics.putIfAbsent(operation, () => _PerformanceMetric(operation));
    
    if (isHit) {
      metric.cacheHits++;
    } else {
      metric.cacheMisses++;
    }
    
    if (duration != null) {
      metric.addSample(duration, true);
    }
  }

  /// 🚀 记录内存使用
  void recordMemoryUsage(String component, int memoryBytes) {
    final operation = '${component}_memory';
    final metric = _metrics.putIfAbsent(operation, () => _PerformanceMetric(operation));
    metric.memoryUsage = memoryBytes;
  }

  /// 🚀 获取性能统计
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};
    
    _metrics.forEach((operation, metric) {
      stats[operation] = {
        'totalOperations': metric.totalOperations,
        'successRate': metric.getSuccessRate(),
        'averageDuration': metric.getAverageDuration()?.inMilliseconds,
        'maxDuration': metric.maxDuration?.inMilliseconds,
        'minDuration': metric.minDuration?.inMilliseconds,
        'cacheHitRate': metric.getCacheHitRate(),
        'memoryUsage': metric.memoryUsage,
      };
    });
    
    return {
      'metrics': stats,
      'recentEventsCount': _recentEvents.length,
      'monitoringDuration': _isMonitoring ? DateTime.now().difference(_getStartTime()).inMinutes : 0,
    };
  }

  /// 🚀 获取性能建议
  List<String> getPerformanceRecommendations() {
    final recommendations = <String>[];
    
    _metrics.forEach((operation, metric) {
      // 检查成功率
      if (metric.getSuccessRate() < 0.95) {
        recommendations.add('$operation 操作成功率较低 (${(metric.getSuccessRate() * 100).toStringAsFixed(1)}%)，建议检查错误处理');
      }
      
      // 检查平均响应时间
      final avgDuration = metric.getAverageDuration();
      if (avgDuration != null && avgDuration.inMilliseconds > 1000) {
        recommendations.add('$operation 操作平均耗时较长 (${avgDuration.inMilliseconds}ms)，建议优化性能');
      }
      
      // 检查缓存命中率
      if (operation.contains('cache')) {
        final hitRate = metric.getCacheHitRate();
        if (hitRate < 0.8) {
          recommendations.add('$operation 缓存命中率较低 (${(hitRate * 100).toStringAsFixed(1)}%)，建议优化缓存策略');
        }
      }
      
      // 检查内存使用
      if (metric.memoryUsage > 100 * 1024 * 1024) { // 100MB
        recommendations.add('$operation 内存使用较高 (${(metric.memoryUsage / 1024 / 1024).toStringAsFixed(1)}MB)，建议检查内存泄漏');
      }
    });
    
    return recommendations;
  }

  /// 检查性能警告
  void _checkPerformanceWarnings(_PerformanceMetric metric, Duration duration) {
    // 检查是否超过警告阈值
    if (duration.inMilliseconds > 2000) {
      AppLogger.warning(
        '操作耗时过长',
        tag: 'PerformanceMonitor',
        data: {
          'operation': metric.operation,
          'duration': duration.inMilliseconds,
          'threshold': 2000,
        },
      );
    }
    
    // 检查是否连续失败
    if (metric.recentFailures >= 5) {
      AppLogger.warning(
        '操作连续失败',
        tag: 'PerformanceMonitor',
        data: {
          'operation': metric.operation,
          'recentFailures': metric.recentFailures,
        },
      );
    }
  }

  /// 生成性能报告
  void _generateReport() {
    final stats = getPerformanceStats();
    final recommendations = getPerformanceRecommendations();
    
    AppLogger.info(
      '性能监控报告',
      tag: 'PerformanceMonitor',
      data: {
        'totalMetrics': _metrics.length,
        'recentEvents': _recentEvents.length,
        'recommendations': recommendations.length,
        'topOperations': _getTopOperations(),
      },
    );
    
    if (recommendations.isNotEmpty) {
      AppLogger.warning(
        '性能优化建议',
        tag: 'PerformanceMonitor',
        data: {
          'recommendations': recommendations,
        },
      );
    }
  }

  /// 获取最频繁的操作
  List<String> _getTopOperations() {
    final sorted = _metrics.entries.toList()
      ..sort((a, b) => b.value.totalOperations.compareTo(a.value.totalOperations));
    
    return sorted.take(5).map((e) => '${e.key}(${e.value.totalOperations})').toList();
  }

  /// 获取监控开始时间
  DateTime _getStartTime() {
    // 简化实现，实际应该记录真实的开始时间
    return DateTime.now().subtract(const Duration(minutes: 5));
  }

  /// 释放资源
  void dispose() {
    stopMonitoring();
    _metrics.clear();
    _recentEvents.clear();
  }
}

/// 性能指标
class _PerformanceMetric {
  final String operation;
  int totalOperations = 0;
  int successfulOperations = 0;
  int recentFailures = 0;
  Duration? minDuration;
  Duration? maxDuration;
  Duration _totalDuration = Duration.zero;
  int cacheHits = 0;
  int cacheMisses = 0;
  int memoryUsage = 0;

  _PerformanceMetric(this.operation);

  void addSample(Duration duration, bool isSuccess) {
    totalOperations++;
    _totalDuration += duration;
    
    if (isSuccess) {
      successfulOperations++;
      recentFailures = 0;
    } else {
      recentFailures++;
    }
    
    minDuration = minDuration == null ? duration : 
        (duration < minDuration! ? duration : minDuration!);
    maxDuration = maxDuration == null ? duration : 
        (duration > maxDuration! ? duration : maxDuration!);
  }

  double getSuccessRate() {
    return totalOperations > 0 ? successfulOperations / totalOperations : 0.0;
  }

  Duration? getAverageDuration() {
    return totalOperations > 0 ? 
        Duration(microseconds: _totalDuration.inMicroseconds ~/ totalOperations) : null;
  }

  double getCacheHitRate() {
    final total = cacheHits + cacheMisses;
    return total > 0 ? cacheHits / total : 0.0;
  }
}

/// 性能事件
class _PerformanceEvent {
  final String operation;
  final Duration duration;
  final DateTime timestamp;
  final bool isSuccess;
  final Map<String, dynamic>? metadata;

  _PerformanceEvent({
    required this.operation,
    required this.duration,
    required this.timestamp,
    required this.isSuccess,
    this.metadata,
  });
} 