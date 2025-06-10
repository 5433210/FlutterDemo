import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';

/// 🚀 优化效果监控收集器
/// 用于量化Canvas性能优化的实际效果
class OptimizationMetricsCollector {
  static final OptimizationMetricsCollector _instance = OptimizationMetricsCollector._internal();
  factory OptimizationMetricsCollector() => _instance;
  OptimizationMetricsCollector._internal();

  // 🔧 性能指标收集
  final Queue<FrameMetrics> _frameMetrics = Queue<FrameMetrics>();
  final Queue<NotificationMetrics> _notificationMetrics = Queue<NotificationMetrics>();
  final Queue<RebuildMetrics> _rebuildMetrics = Queue<RebuildMetrics>();
  
  // 🔧 统计数据
  int _totalNotifications = 0;
  int _throttledNotifications = 0;
  int _intelligentDispatches = 0;
  int _fallbackNotifications = 0;
  
  // 🔧 时间窗口统计
  DateTime _sessionStartTime = DateTime.now();
  Timer? _reportTimer;
  
  // 🔧 性能阈值
  static const double _targetFPS = 60.0;
  static const Duration _maxFrameTime = Duration(milliseconds: 16); // 60 FPS
  static const int _maxMetricsHistory = 1000;

  /// 开始监控会话
  void startMonitoring() {
    _sessionStartTime = DateTime.now();
    _clearMetrics();
    
    // 每30秒生成一次性能报告
    _reportTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      generatePerformanceReport();
    });
    
    EditPageLogger.performanceInfo(
      '开始优化效果监控',
      data: {
        'sessionStartTime': _sessionStartTime.toIso8601String(),
        'operation': 'start_monitoring',
      },
    );
  }

  /// 停止监控会话
  void stopMonitoring() {
    _reportTimer?.cancel();
    generateFinalReport();
    
    EditPageLogger.performanceInfo(
      '停止优化效果监控',
      data: {
        'sessionDuration': DateTime.now().difference(_sessionStartTime).inSeconds,
        'operation': 'stop_monitoring',
      },
    );
  }

  /// 记录帧性能指标
  void recordFrameMetrics({
    required Duration frameTime,
    required double fps,
    required bool isJanky,
    String? operation,
  }) {
    final metrics = FrameMetrics(
      timestamp: DateTime.now(),
      frameTime: frameTime,
      fps: fps,
      isJanky: isJanky,
      operation: operation,
    );
    
    _frameMetrics.add(metrics);
    if (_frameMetrics.length > _maxMetricsHistory) {
      _frameMetrics.removeFirst();
    }
  }

  /// 记录通知性能指标
  void recordNotificationMetrics({
    required NotificationType type,
    required Duration processingTime,
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    final metrics = NotificationMetrics(
      timestamp: DateTime.now(),
      type: type,
      processingTime: processingTime,
      operation: operation,
      metadata: metadata,
    );
    
    _notificationMetrics.add(metrics);
    if (_notificationMetrics.length > _maxMetricsHistory) {
      _notificationMetrics.removeFirst();
    }
    
    // 更新统计计数
    _totalNotifications++;
    switch (type) {
      case NotificationType.throttled:
        _throttledNotifications++;
        break;
      case NotificationType.intelligent:
        _intelligentDispatches++;
        break;
      case NotificationType.fallback:
        _fallbackNotifications++;
        break;
      case NotificationType.direct:
        break;
    }
  }

  /// 记录重建性能指标
  void recordRebuildMetrics({
    required String componentType,
    required Duration rebuildTime,
    required bool wasOptimized,
    String? operation,
  }) {
    final metrics = RebuildMetrics(
      timestamp: DateTime.now(),
      componentType: componentType,
      rebuildTime: rebuildTime,
      wasOptimized: wasOptimized,
      operation: operation,
    );
    
    _rebuildMetrics.add(metrics);
    if (_rebuildMetrics.length > _maxMetricsHistory) {
      _rebuildMetrics.removeFirst();
    }
  }

  /// 生成性能报告
  void generatePerformanceReport() {
    final now = DateTime.now();
    final sessionDuration = now.difference(_sessionStartTime);
    
    final report = _calculateMetrics(sessionDuration);
    
    EditPageLogger.performanceInfo(
      '📊 优化效果性能报告',
      data: {
        'sessionDuration_minutes': sessionDuration.inMinutes,
        'frameMetrics': report['frameMetrics'],
        'notificationMetrics': report['notificationMetrics'],
        'rebuildMetrics': report['rebuildMetrics'],
        'optimizationEfficiency': report['optimizationEfficiency'],
        'operation': 'performance_report',
      },
    );
    
    // 在调试模式下打印详细报告
    if (kDebugMode) {
      _printDetailedReport(report, sessionDuration);
    }
  }

  /// 生成最终报告
  void generateFinalReport() {
    final sessionDuration = DateTime.now().difference(_sessionStartTime);
    final report = _calculateMetrics(sessionDuration);
    
    EditPageLogger.performanceInfo(
      '🎯 优化效果最终报告',
      data: {
        'totalSessionDuration_minutes': sessionDuration.inMinutes,
        'finalMetrics': report,
        'operation': 'final_report',
      },
    );
    
    if (kDebugMode) {
      print('\n' + '='*60);
      print('🎯 Canvas性能优化效果最终报告');
      print('='*60);
      _printDetailedReport(report, sessionDuration);
      print('='*60 + '\n');
    }
  }

  /// 计算性能指标
  Map<String, dynamic> _calculateMetrics(Duration sessionDuration) {
    // 帧性能指标
    final frameMetrics = _calculateFrameMetrics();
    
    // 通知性能指标
    final notificationMetrics = _calculateNotificationMetrics();
    
    // 重建性能指标
    final rebuildMetrics = _calculateRebuildMetrics();
    
    // 优化效率指标
    final optimizationEfficiency = _calculateOptimizationEfficiency();
    
    return {
      'frameMetrics': frameMetrics,
      'notificationMetrics': notificationMetrics,
      'rebuildMetrics': rebuildMetrics,
      'optimizationEfficiency': optimizationEfficiency,
      'sessionInfo': {
        'duration_minutes': sessionDuration.inMinutes,
        'startTime': _sessionStartTime.toIso8601String(),
        'endTime': DateTime.now().toIso8601String(),
      },
    };
  }

  /// 计算帧性能指标
  Map<String, dynamic> _calculateFrameMetrics() {
    if (_frameMetrics.isEmpty) {
      return {
        'averageFPS': 0.0,
        'averageFrameTime_ms': 0.0,
        'jankRate': 0.0,
        'frameCount': 0,
      };
    }
    
    final totalFPS = _frameMetrics.fold(0.0, (sum, m) => sum + m.fps);
    final totalFrameTime = _frameMetrics.fold(0, (sum, m) => sum + m.frameTime.inMicroseconds);
    final jankCount = _frameMetrics.where((m) => m.isJanky).length;
    
    return {
      'averageFPS': totalFPS / _frameMetrics.length,
      'averageFrameTime_ms': (totalFrameTime / _frameMetrics.length) / 1000,
      'jankRate': (jankCount / _frameMetrics.length) * 100,
      'frameCount': _frameMetrics.length,
      'targetFPS': _targetFPS,
      'fpsEfficiency': ((totalFPS / _frameMetrics.length) / _targetFPS) * 100,
    };
  }

  /// 计算通知性能指标
  Map<String, dynamic> _calculateNotificationMetrics() {
    if (_notificationMetrics.isEmpty) {
      return {
        'totalNotifications': _totalNotifications,
        'throttledRate': 0.0,
        'intelligentRate': 0.0,
        'fallbackRate': 0.0,
      };
    }
    
    final avgProcessingTime = _notificationMetrics.fold(0, (sum, m) => sum + m.processingTime.inMicroseconds) / _notificationMetrics.length;
    
    return {
      'totalNotifications': _totalNotifications,
      'throttledNotifications': _throttledNotifications,
      'intelligentDispatches': _intelligentDispatches,
      'fallbackNotifications': _fallbackNotifications,
      'throttledRate': (_throttledNotifications / _totalNotifications) * 100,
      'intelligentRate': (_intelligentDispatches / _totalNotifications) * 100,
      'fallbackRate': (_fallbackNotifications / _totalNotifications) * 100,
      'averageProcessingTime_us': avgProcessingTime,
    };
  }

  /// 计算重建性能指标
  Map<String, dynamic> _calculateRebuildMetrics() {
    if (_rebuildMetrics.isEmpty) {
      return {
        'totalRebuilds': 0,
        'optimizedRate': 0.0,
        'averageRebuildTime_ms': 0.0,
      };
    }
    
    final optimizedCount = _rebuildMetrics.where((m) => m.wasOptimized).length;
    final avgRebuildTime = _rebuildMetrics.fold(0, (sum, m) => sum + m.rebuildTime.inMicroseconds) / _rebuildMetrics.length;
    
    return {
      'totalRebuilds': _rebuildMetrics.length,
      'optimizedRebuilds': optimizedCount,
      'optimizedRate': (optimizedCount / _rebuildMetrics.length) * 100,
      'averageRebuildTime_ms': avgRebuildTime / 1000,
    };
  }

  /// 计算优化效率
  Map<String, dynamic> _calculateOptimizationEfficiency() {
    final frameEfficiency = _frameMetrics.isNotEmpty 
        ? (_frameMetrics.fold(0.0, (sum, m) => sum + m.fps) / _frameMetrics.length) / _targetFPS
        : 0.0;
    
    final notificationEfficiency = _totalNotifications > 0
        ? (_throttledNotifications + _intelligentDispatches) / _totalNotifications
        : 0.0;
    
    final rebuildEfficiency = _rebuildMetrics.isNotEmpty
        ? _rebuildMetrics.where((m) => m.wasOptimized).length / _rebuildMetrics.length
        : 0.0;
    
    final overallEfficiency = (frameEfficiency + notificationEfficiency + rebuildEfficiency) / 3;
    
    return {
      'frameEfficiency': frameEfficiency * 100,
      'notificationEfficiency': notificationEfficiency * 100,
      'rebuildEfficiency': rebuildEfficiency * 100,
      'overallEfficiency': overallEfficiency * 100,
      'grade': _getEfficiencyGrade(overallEfficiency),
    };
  }

  /// 获取效率等级
  String _getEfficiencyGrade(double efficiency) {
    if (efficiency >= 0.9) return 'A+ (优秀)';
    if (efficiency >= 0.8) return 'A (良好)';
    if (efficiency >= 0.7) return 'B (一般)';
    if (efficiency >= 0.6) return 'C (需改进)';
    return 'D (需优化)';
  }

  /// 打印详细报告
  void _printDetailedReport(Map<String, dynamic> report, Duration sessionDuration) {
    final frame = report['frameMetrics'] as Map<String, dynamic>;
    final notification = report['notificationMetrics'] as Map<String, dynamic>;
    final rebuild = report['rebuildMetrics'] as Map<String, dynamic>;
    final efficiency = report['optimizationEfficiency'] as Map<String, dynamic>;
    
    print('📊 会话时长: ${sessionDuration.inMinutes}分${sessionDuration.inSeconds % 60}秒');
    print('');
    
    print('🎯 帧性能指标:');
    print('   平均FPS: ${frame['averageFPS'].toStringAsFixed(1)} (目标: ${frame['targetFPS']})');
    print('   平均帧时间: ${frame['averageFrameTime_ms'].toStringAsFixed(2)}ms');
    print('   卡顿率: ${frame['jankRate'].toStringAsFixed(1)}%');
    print('   FPS效率: ${frame['fpsEfficiency'].toStringAsFixed(1)}%');
    print('');
    
    print('🔔 通知性能指标:');
    print('   总通知数: ${notification['totalNotifications']}');
    print('   节流通知率: ${notification['throttledRate'].toStringAsFixed(1)}%');
    print('   智能分发率: ${notification['intelligentRate'].toStringAsFixed(1)}%');
    print('   回退通知率: ${notification['fallbackRate'].toStringAsFixed(1)}%');
    print('   平均处理时间: ${notification['averageProcessingTime_us'].toStringAsFixed(0)}μs');
    print('');
    
    print('🔄 重建性能指标:');
    print('   总重建数: ${rebuild['totalRebuilds']}');
    print('   优化重建率: ${rebuild['optimizedRate'].toStringAsFixed(1)}%');
    print('   平均重建时间: ${rebuild['averageRebuildTime_ms'].toStringAsFixed(2)}ms');
    print('');
    
    print('⭐ 优化效率总评:');
    print('   帧效率: ${efficiency['frameEfficiency'].toStringAsFixed(1)}%');
    print('   通知效率: ${efficiency['notificationEfficiency'].toStringAsFixed(1)}%');
    print('   重建效率: ${efficiency['rebuildEfficiency'].toStringAsFixed(1)}%');
    print('   综合评分: ${efficiency['overallEfficiency'].toStringAsFixed(1)}% - ${efficiency['grade']}');
  }

  /// 清空指标数据
  void _clearMetrics() {
    _frameMetrics.clear();
    _notificationMetrics.clear();
    _rebuildMetrics.clear();
    _totalNotifications = 0;
    _throttledNotifications = 0;
    _intelligentDispatches = 0;
    _fallbackNotifications = 0;
  }

  /// 获取实时统计
  Map<String, dynamic> getRealTimeStats() {
    return {
      'frameCount': _frameMetrics.length,
      'notificationCount': _notificationMetrics.length,
      'rebuildCount': _rebuildMetrics.length,
      'sessionDuration': DateTime.now().difference(_sessionStartTime).inSeconds,
    };
  }
}

/// 帧性能指标
class FrameMetrics {
  final DateTime timestamp;
  final Duration frameTime;
  final double fps;
  final bool isJanky;
  final String? operation;

  FrameMetrics({
    required this.timestamp,
    required this.frameTime,
    required this.fps,
    required this.isJanky,
    this.operation,
  });
}

/// 通知类型
enum NotificationType {
  direct,      // 直接通知
  throttled,   // 节流通知
  intelligent, // 智能分发
  fallback,    // 回退通知
}

/// 通知性能指标
class NotificationMetrics {
  final DateTime timestamp;
  final NotificationType type;
  final Duration processingTime;
  final String? operation;
  final Map<String, dynamic>? metadata;

  NotificationMetrics({
    required this.timestamp,
    required this.type,
    required this.processingTime,
    this.operation,
    this.metadata,
  });
}

/// 重建性能指标
class RebuildMetrics {
  final DateTime timestamp;
  final String componentType;
  final Duration rebuildTime;
  final bool wasOptimized;
  final String? operation;

  RebuildMetrics({
    required this.timestamp,
    required this.componentType,
    required this.rebuildTime,
    required this.wasOptimized,
    this.operation,
  });
} 