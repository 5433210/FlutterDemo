import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/logging/practice_edit_logger.dart';
import 'memory_manager.dart';
import 'performance_monitor.dart';

/// 设备性能检测器
/// 提供更复杂的设备性能检测功能
class DevicePerformanceDetector {
  /// 检测设备性能等级
  static Future<DevicePerformanceLevel> detectDevicePerformance() async {
    EditPageLogger.performanceInfo('开始设备性能检测');
    
    final timer = PerformanceTimer('设备性能检测');
    
    // 渲染测试：评估设备的图形性能
    final renderPerformance = await _testRenderPerformance();

    // 计算测试：评估设备的CPU性能
    final computePerformance = await _testComputePerformance();

    // 内存测试：评估设备的内存容量和访问速度
    final memoryPerformance = await _testMemoryPerformance();

    // 综合评分
    final totalScore =
        renderPerformance + computePerformance + memoryPerformance;

    // 基于总分确定性能等级
    DevicePerformanceLevel level;
    if (totalScore > 80) {
      level = DevicePerformanceLevel.high;
    } else if (totalScore > 50) {
      level = DevicePerformanceLevel.medium;
    } else {
      level = DevicePerformanceLevel.low;
    }

      EditPageLogger.performanceInfo(
      '设备性能检测完成',
      data: {
        'renderScore': renderPerformance,
        'computeScore': computePerformance,
        'memoryScore': memoryPerformance,
        'totalScore': totalScore,
        'performanceLevel': level.name,
        'detectionTimeMs': timer.elapsedMilliseconds,
      },
    );
    
    // 检查性能阈值并发出警告
    if (totalScore < 30) {
      EditPageLogger.performanceWarning(
        '设备性能低于推荐阈值',
        data: {
          'totalScore': totalScore,
          'recommendedMinScore': 30,
          'performanceLevel': level.name,
          'suggestion': '建议启用低性能模式以提升用户体验',
        },
      );
    }
    
    timer.finish();

    return level;
  }

  /// 测试计算性能
  static Future<double> _testComputePerformance() async {
    // 模拟计算密集型操作
    final stopwatch = Stopwatch()..start();

    int result = 0;
    for (int i = 0; i < 1000000; i++) {
      result += (i * i) % 1000;
    }

    final elapsedMs = stopwatch.elapsedMilliseconds;

    // Use the result variable to prevent optimization
    if (result < 0) {
      if (kDebugMode) print('Unexpected result value: $result');
    }

    // 分数计算：越快越高分
    return 100.0 * (2000.0 / (elapsedMs + 1000.0));
  }

  /// 测试内存性能
  static Future<double> _testMemoryPerformance() async {
    // 在Flutter中，我们无法直接访问内存细节
    // 这里可以使用一些间接方法评估内存

    // 例如：分配大量临时对象并测量时间
    final stopwatch = Stopwatch()..start();

    List<List<int>> memoryChunks = [];
    for (int i = 0; i < 100; i++) {
      memoryChunks.add(List<int>.filled(10000, i));
    }

    final elapsedMs = stopwatch.elapsedMilliseconds;

    // 确保GC能回收这些内存
    memoryChunks = [];

    // 分数计算
    return 100.0 * (500.0 / (elapsedMs + 300.0));
  }

  /// 测试渲染性能
  static Future<double> _testRenderPerformance() async {
    // 简化的渲染性能测试
    // 实际应用中，这里可能会测试帧率、复杂场景渲染等
    return 70.0; // 示例分数
  }
}

/// 设备性能等级
enum DevicePerformanceLevel {
  /// 低性能设备
  low,

  /// 中等性能设备
  medium,

  /// 高性能设备
  high,
}

/// Memory pressure levels for performance optimization
enum MemoryPressureLevel {
  /// Normal - memory usage in safe range
  normal,

  /// Mild pressure - memory usage approaching threshold
  mild,

  /// Moderate pressure - memory usage at threshold
  moderate,

  /// Severe pressure - memory usage exceeding threshold, immediate cleanup needed
  severe,
}

/// 性能优化配置
class PerformanceOptimizationConfig {
  /// 是否启用自适应性能优化
  final bool enableAdaptiveOptimization;

  /// 最大帧率限制 (默认为60)
  final double maxFrameRate;

  /// 动画节流阈值 (默认为50ms)
  final Duration animationThrottleThreshold;

  /// 拖拽节流阈值 (默认为16ms)
  final Duration dragThrottleThreshold;

  /// 最大可见元素数量 (null表示不限制)
  final int? maxVisibleElements;

  /// 渲染质量 (0.0-1.0)
  final double renderQuality;

  /// 是否使用低质量渲染模式
  final bool useLowQualityMode;

  /// 缓存限制 (元素数量)
  final int cacheLimit;

  /// 是否启用视口剔除
  final bool enableViewportCulling;

  /// 视口剔除边距
  final double viewportCullingMargin;

  const PerformanceOptimizationConfig({
    this.enableAdaptiveOptimization = true,
    this.maxFrameRate = 60,
    this.animationThrottleThreshold = const Duration(milliseconds: 50),
    this.dragThrottleThreshold = const Duration(milliseconds: 16),
    this.maxVisibleElements,
    this.renderQuality = 1.0,
    this.useLowQualityMode = false,
    this.cacheLimit = 500,
    this.enableViewportCulling = true,
    this.viewportCullingMargin = 100.0,
  });

  /// 创建高性能设备的配置
  factory PerformanceOptimizationConfig.forHighPerformance() {
    return const PerformanceOptimizationConfig(
      maxFrameRate: 60,
      animationThrottleThreshold: Duration(milliseconds: 33),
      dragThrottleThreshold: Duration(milliseconds: 8),
      maxVisibleElements: null, // 不限制
      renderQuality: 1.0,
      useLowQualityMode: false,
      cacheLimit: 500,
      viewportCullingMargin: 150.0,
    );
  }

  /// 创建低性能设备的配置
  factory PerformanceOptimizationConfig.forLowPerformance() {
    return const PerformanceOptimizationConfig(
      maxFrameRate: 30,
      animationThrottleThreshold: Duration(milliseconds: 100),
      dragThrottleThreshold: Duration(milliseconds: 32),
      maxVisibleElements: 100,
      renderQuality: 0.7,
      useLowQualityMode: true,
      cacheLimit: 200,
      viewportCullingMargin: 50.0,
    );
  }

  /// 创建中等性能设备的配置
  factory PerformanceOptimizationConfig.forMediumPerformance() {
    return const PerformanceOptimizationConfig(
      maxFrameRate: 60,
      animationThrottleThreshold: Duration(milliseconds: 50),
      dragThrottleThreshold: Duration(milliseconds: 16),
      maxVisibleElements: 200,
      renderQuality: 0.9,
      useLowQualityMode: false,
      cacheLimit: 350,
      viewportCullingMargin: 100.0,
    );
  }

  /// 创建基于当前配置的新配置，但应用部分更改
  PerformanceOptimizationConfig copyWith({
    bool? enableAdaptiveOptimization,
    double? maxFrameRate,
    Duration? animationThrottleThreshold,
    Duration? dragThrottleThreshold,
    int? maxVisibleElements,
    double? renderQuality,
    bool? useLowQualityMode,
    int? cacheLimit,
    bool? enableViewportCulling,
    double? viewportCullingMargin,
  }) {
    return PerformanceOptimizationConfig(
      enableAdaptiveOptimization:
          enableAdaptiveOptimization ?? this.enableAdaptiveOptimization,
      maxFrameRate: maxFrameRate ?? this.maxFrameRate,
      animationThrottleThreshold:
          animationThrottleThreshold ?? this.animationThrottleThreshold,
      dragThrottleThreshold:
          dragThrottleThreshold ?? this.dragThrottleThreshold,
      maxVisibleElements: maxVisibleElements ?? this.maxVisibleElements,
      renderQuality: renderQuality ?? this.renderQuality,
      useLowQualityMode: useLowQualityMode ?? this.useLowQualityMode,
      cacheLimit: cacheLimit ?? this.cacheLimit,
      enableViewportCulling:
          enableViewportCulling ?? this.enableViewportCulling,
      viewportCullingMargin:
          viewportCullingMargin ?? this.viewportCullingMargin,
    );
  }

  /// 创建当内存压力高时的优化配置
  PerformanceOptimizationConfig forHighMemoryPressure() {
    return copyWith(
      maxVisibleElements: maxVisibleElements != null
          ? (maxVisibleElements! * 0.7).round()
          : 100,
      renderQuality: renderQuality * 0.8,
      useLowQualityMode: true,
      cacheLimit: (cacheLimit * 0.6).round(),
      viewportCullingMargin: viewportCullingMargin * 0.7,
    );
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    return {
      'enableAdaptiveOptimization': enableAdaptiveOptimization,
      'maxFrameRate': maxFrameRate,
      'animationThrottleThreshold': animationThrottleThreshold.inMilliseconds,
      'dragThrottleThreshold': dragThrottleThreshold.inMilliseconds,
      'maxVisibleElements': maxVisibleElements,
      'renderQuality': renderQuality,
      'useLowQualityMode': useLowQualityMode,
      'cacheLimit': cacheLimit,
      'enableViewportCulling': enableViewportCulling,
      'viewportCullingMargin': viewportCullingMargin,
    };
  }
}

/// 性能优化器工厂
/// 用于创建和获取性能优化器实例
class PerformanceOptimizerFactory {
  static SelfAdaptivePerformanceOptimizer? _instance;

  /// 获取性能优化器实例
  static SelfAdaptivePerformanceOptimizer? get instance => _instance;

  /// 创建性能优化器实例
  static SelfAdaptivePerformanceOptimizer create({
    required MemoryManager memoryManager,
    required PerformanceMonitor performanceMonitor,
    PerformanceOptimizationConfig? initialConfig,
    DevicePerformanceLevel? detectedPerformanceLevel,
    TickerProvider? vsync,
  }) {
    _instance = SelfAdaptivePerformanceOptimizer(
      memoryManager: memoryManager,
      performanceMonitor: performanceMonitor,
    );
    return _instance!;
  }
}

/// 自适应性能优化器
/// 根据设备性能和当前运行状态自动调整性能配置
class SelfAdaptivePerformanceOptimizer extends ChangeNotifier {
  final PerformanceMonitor _performanceMonitor;
  final MemoryManager _memoryManager;

  // 🚀 性能优化：节流通知机制
  DateTime _lastNotificationTime = DateTime.now();
  static const Duration _notificationThrottle = Duration(milliseconds: 1000); // 最多每1秒通知一次

  // 性能配置
  PerformanceOptimizationConfig _config =
      const PerformanceOptimizationConfig();

  // 设备性能等级
  DevicePerformanceLevel _devicePerformanceLevel = DevicePerformanceLevel.medium;

  // 性能监控状态
  int _performancePressureCount = 0;
  bool _memoryPressureOptimizationApplied = false;
  DateTime _lastAdaptationTime = DateTime.now();
  MemoryPressureLevel _lastMemoryPressureLevel = MemoryPressureLevel.normal;

  // 性能历史记录
  final List<Map<String, dynamic>> _performanceHistory = [];

  // 帧率限制相关
  Ticker? _ticker;
  bool _frameRateLimitEnabled = false;

  SelfAdaptivePerformanceOptimizer({
    required PerformanceMonitor performanceMonitor,
    required MemoryManager memoryManager,
  })  : _performanceMonitor = performanceMonitor,
        _memoryManager = memoryManager {
    // 初始化时检测设备性能
    _detectDevicePerformance();

    // 创建Ticker用于帧率控制
    _ticker = Ticker((elapsed) {});

    // 开始性能监控
    _startPerformanceMonitoring();
  }

  // Getters
  PerformanceOptimizationConfig get config => _config;
  DevicePerformanceLevel get devicePerformanceLevel => _devicePerformanceLevel;
  List<Map<String, dynamic>> get performanceHistory =>
      List.unmodifiable(_performanceHistory);

  /// 🚀 节流通知方法 - 避免性能优化器本身影响性能
  void _throttledNotifyListeners({
    required String operation,
    Map<String, dynamic>? data,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastNotificationTime) >= _notificationThrottle) {
      _lastNotificationTime = now;
      
      EditPageLogger.performanceInfo(
        '性能优化器通知',
        data: {
          'operation': operation,
          'devicePerformanceLevel': _devicePerformanceLevel.name,
          'currentFps': _performanceMonitor.currentFPS,
          'memoryPressureLevel': _lastMemoryPressureLevel.name,
          'optimization': 'throttled_performance_optimizer_notification',
          ...?data,
        },
      );
      
      notifyListeners();
    }
  }

  /// 应用新的性能优化配置
  void applyConfiguration(PerformanceOptimizationConfig newConfig) {
    _config = newConfig;
    _applyFrameRateLimit(newConfig.maxFrameRate);
    
    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'apply_configuration',
      data: {
        'maxFrameRate': newConfig.maxFrameRate,
        'renderQuality': newConfig.renderQuality,
        'useLowQualityMode': newConfig.useLowQualityMode,
      },
    );

    if (kDebugMode) {
      print('⚙️ SelfAdaptivePerformanceOptimizer: 应用新配置');
      print('   配置详情: ${newConfig.toJson()}');
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  /// 获取当前性能状态报告
  Map<String, dynamic> getPerformanceReport() {
    final memoryStats = _memoryManager.memoryStats;

    return {
      'devicePerformanceLevel': _devicePerformanceLevel.toString(),
      'currentConfig': _config.toJson(),
      'performanceMetrics': {
        'fps': _performanceMonitor.currentFPS,
        'averageFrameTime': _performanceMonitor.averageFrameTime.inMilliseconds,
        'slowFrameCount': _performanceMonitor.slowFrameCount,
        'totalRebuilds': _performanceMonitor.totalRebuilds,
      },
      'memoryMetrics': {
        'currentUsage': memoryStats.currentUsage,
        'maxLimit': memoryStats.maxLimit,
        'pressureRatio': memoryStats.pressureRatio,
        'pressureLevel': _lastMemoryPressureLevel.toString(),
      },
      'adaptationState': {
        'performancePressureCount': _performancePressureCount,
        'memoryPressureOptimizationApplied': _memoryPressureOptimizationApplied,
        'lastAdaptationTime': _lastAdaptationTime.toIso8601String(),
      },
    };
  }

  /// 手动优化内存使用
  void optimizeForMemory() {
    _adaptToMemoryPressure(forceAdaptation: true);
  }

  /// 手动优化性能配置
  void optimizeForPerformance() {
    _adaptToCurrentPerformance(forceAdaptation: true);
  }

  /// 重置为默认配置
  void resetToDefault() {
    // 基于检测到的设备性能选择默认配置
    switch (_devicePerformanceLevel) {
      case DevicePerformanceLevel.low:
        _config = PerformanceOptimizationConfig.forLowPerformance();
        break;
      case DevicePerformanceLevel.medium:
        _config = PerformanceOptimizationConfig.forMediumPerformance();
        break;
      case DevicePerformanceLevel.high:
        _config = PerformanceOptimizationConfig.forHighPerformance();
        break;
    }

    _applyFrameRateLimit(_config.maxFrameRate);
    _performancePressureCount = 0;
    _memoryPressureOptimizationApplied = false;
    
    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'reset_to_default',
      data: {
        'devicePerformanceLevel': _devicePerformanceLevel.name,
        'maxFrameRate': _config.maxFrameRate,
      },
    );

    if (kDebugMode) {
      print('🔄 SelfAdaptivePerformanceOptimizer: 重置为默认配置');
      print('   配置详情: ${_config.toJson()}');
    }
  }

  /// 手动指定设备性能等级并应用相应配置
  void setDevicePerformanceLevel(DevicePerformanceLevel level) {
    _devicePerformanceLevel = level;

    // 应用相应的配置
    switch (level) {
      case DevicePerformanceLevel.low:
        _config = PerformanceOptimizationConfig.forLowPerformance();
        break;
      case DevicePerformanceLevel.medium:
        _config = PerformanceOptimizationConfig.forMediumPerformance();
        break;
      case DevicePerformanceLevel.high:
        _config = PerformanceOptimizationConfig.forHighPerformance();
        break;
    }

    _applyFrameRateLimit(_config.maxFrameRate);
    
    // 🚀 使用节流通知替代直接notifyListeners
    _throttledNotifyListeners(
      operation: 'set_device_performance_level',
      data: {
        'performanceLevel': level.name,
        'maxFrameRate': _config.maxFrameRate,
      },
    );

    if (kDebugMode) {
      print('📱 SelfAdaptivePerformanceOptimizer: 设置设备性能等级为 $level');
      print('   应用配置: ${_config.toJson()}');
    }
  }

  /// 根据当前性能状态调整配置
  void _adaptToCurrentPerformance({bool forceAdaptation = false}) {
    final now = DateTime.now();
    // 避免过于频繁的调整，默认至少间隔5秒
    if (!forceAdaptation && now.difference(_lastAdaptationTime).inSeconds < 5) {
      return;
    }

    final currentFPS = _performanceMonitor.currentFPS;
    final avgFrameTime = _performanceMonitor.averageFrameTime.inMilliseconds;
    final slowFrames = _performanceMonitor.slowFrameCount;

    // 记录性能数据
    _performanceHistory.add({
      'timestamp': now.millisecondsSinceEpoch,
      'fps': currentFPS,
      'frameTime': avgFrameTime,
      'slowFrames': slowFrames,
    });

    // 限制历史记录大小
    if (_performanceHistory.length > 60) {
      _performanceHistory.removeAt(0);
    }

    // 性能压力检测
    bool underPerformancePressure = false;

    // 如果帧率低于目标帧率的80%或平均帧时间超过16.7ms，认为有性能压力
    if (currentFPS < _config.maxFrameRate * 0.8 || avgFrameTime > 16.7) {
      underPerformancePressure = true;
      _performancePressureCount++;
    } else {
      // 如果性能良好，则减少计数器
      _performancePressureCount = math.max(0, _performancePressureCount - 1);
    }

    // 只有在连续检测到性能压力或强制适应时才调整配置
    if (_performancePressureCount >= 3 || forceAdaptation) {
      // 根据设备性能等级和当前性能状况调整配置
      PerformanceOptimizationConfig newConfig;

      if (underPerformancePressure) {
        // 性能压力下，降低配置级别
        switch (_devicePerformanceLevel) {
          case DevicePerformanceLevel.high:
            newConfig = PerformanceOptimizationConfig.forMediumPerformance();
            break;
          case DevicePerformanceLevel.medium:
          case DevicePerformanceLevel.low:
            newConfig = PerformanceOptimizationConfig.forLowPerformance();
            break;
        }

        // 如果帧率仍然很低，进一步降低目标帧率
        if (currentFPS < 30 && newConfig.maxFrameRate > 30) {
          newConfig = newConfig.copyWith(maxFrameRate: 30);
        }

        if (kDebugMode) {
          print('⚠️ SelfAdaptivePerformanceOptimizer: 检测到性能压力，降低配置');
          print(
              '   当前FPS: ${currentFPS.toStringAsFixed(1)}, 帧时间: ${avgFrameTime}ms');
        }
      } else {
        // 性能良好，可以尝试恢复配置
        switch (_devicePerformanceLevel) {
          case DevicePerformanceLevel.high:
            newConfig = PerformanceOptimizationConfig.forHighPerformance();
            break;
          case DevicePerformanceLevel.medium:
            newConfig = PerformanceOptimizationConfig.forMediumPerformance();
            break;
          case DevicePerformanceLevel.low:
            newConfig = PerformanceOptimizationConfig.forLowPerformance();
            break;
        }

        if (kDebugMode) {
          print('✅ SelfAdaptivePerformanceOptimizer: 性能良好，恢复正常配置');
        }
      }

      // 应用新配置
      _config = newConfig;
      _applyFrameRateLimit(newConfig.maxFrameRate);
      _lastAdaptationTime = now;
      _performancePressureCount = 0;
      
      // 🚀 使用节流通知替代直接notifyListeners
      _throttledNotifyListeners(
        operation: 'adapt_to_current_performance',
        data: {
          'currentFps': currentFPS,
          'avgFrameTime_ms': avgFrameTime,
          'underPerformancePressure': underPerformancePressure,
          'newMaxFrameRate': newConfig.maxFrameRate,
        },
      );
    }
  }

  /// 根据内存压力调整配置
  void _adaptToMemoryPressure({bool forceAdaptation = false}) {
    final memoryStats = _memoryManager.memoryStats;
    final memoryPressureLevel =
        _getMemoryPressureLevel(memoryStats.pressureRatio);

    // 如果内存压力级别变化或强制适应
    if (memoryPressureLevel != _lastMemoryPressureLevel || forceAdaptation) {
      _lastMemoryPressureLevel = memoryPressureLevel;

      switch (memoryPressureLevel) {
        case MemoryPressureLevel.normal:
          // 如果之前应用了内存压力优化，现在恢复正常配置
          if (_memoryPressureOptimizationApplied) {
            // 恢复到默认配置
            resetToDefault();
            _memoryPressureOptimizationApplied = false;
            if (kDebugMode) {
              print('✅ SelfAdaptivePerformanceOptimizer: 内存压力恢复正常，恢复配置');
            }
          }
          break;
        case MemoryPressureLevel.mild:
          // 轻微内存压力，可能不需要特别处理
          break;
        case MemoryPressureLevel.moderate:
        case MemoryPressureLevel.severe:
          // 中度或严重内存压力，应用内存优化配置
          final memoryOptimizedConfig = _config.forHighMemoryPressure();
          _config = memoryOptimizedConfig;
          _memoryPressureOptimizationApplied = true;
          _applyFrameRateLimit(_config.maxFrameRate);
          
          // 🚀 使用节流通知替代直接notifyListeners
          _throttledNotifyListeners(
            operation: 'adapt_to_memory_pressure',
            data: {
              'memoryPressureLevel': memoryPressureLevel.name,
              'memoryUsageRatio': memoryStats.pressureRatio,
              'maxFrameRate': _config.maxFrameRate,
            },
          );

          if (kDebugMode) {
            print(
                '⚠️ SelfAdaptivePerformanceOptimizer: 检测到内存压力 ($memoryPressureLevel)，应用内存优化配置');
            print(
                '   内存使用率: ${(memoryStats.pressureRatio * 100).toStringAsFixed(1)}%');
            print('   优化配置: ${memoryOptimizedConfig.toJson()}');
          }
          break;
      }
    }
  }

  /// 应用帧率限制
  void _applyFrameRateLimit(double targetFPS) {
    if (_ticker == null) return;

    if (targetFPS < 60) {
      final interval = (1000 / targetFPS).round();
      // 如果还没有启用帧率限制，则启用它
      if (!_frameRateLimitEnabled) {
        _ticker!.start();
        _frameRateLimitEnabled = true;
      }

      // 设置自定义帧率
      _ticker!.muted = false;
      // 使用定时器调整帧率
      Timer.periodic(Duration(milliseconds: interval), (timer) {
        if (!_frameRateLimitEnabled) {
          timer.cancel();
          return;
        }
        _ticker!.muted = !_ticker!.muted;
      });

      if (kDebugMode) {
        print(
            '⏱️ SelfAdaptivePerformanceOptimizer: 限制帧率为 ${targetFPS.round()} FPS');
      }
    } else {
      // 如果帧率限制已启用但不再需要，则停用它
      if (_frameRateLimitEnabled) {
        _ticker!.stop();
        _frameRateLimitEnabled = false;
        if (kDebugMode) {
          print('⏱️ SelfAdaptivePerformanceOptimizer: 移除帧率限制');
        }
      }
    }
  }

  /// 检测设备性能
  void _detectDevicePerformance() {
    // 创建一个简单的性能测试来评估设备性能
    // 这里只是一个示例实现，实际应用中可能需要更复杂的评估    // 1. 运行一个简单的计算密集型测试
    final stopwatch = Stopwatch()..start();
    int sum = 0;
    for (int i = 0; i < 100000; i++) {
      sum += i * i;
    }
    final computeTime = stopwatch.elapsedMilliseconds;

    // Use the sum variable to prevent optimization
    if (sum < 0) {
      if (kDebugMode) print('Unexpected sum value: $sum');
    }

    // 2. 结合内存信息评估设备性能
    final memoryStats = _memoryManager.memoryStats;
    final availableMemory = memoryStats.maxLimit;

    // 3. 基于测试结果评估设备性能
    DevicePerformanceLevel detectedLevel;

    if (computeTime < 50 && availableMemory > 512 * 1024 * 1024) {
      // 高性能设备：计算快且内存充足
      detectedLevel = DevicePerformanceLevel.high;
    } else if (computeTime < 100 && availableMemory > 256 * 1024 * 1024) {
      // 中等性能设备
      detectedLevel = DevicePerformanceLevel.medium;
    } else {
      // 低性能设备
      detectedLevel = DevicePerformanceLevel.low;
    }

    _devicePerformanceLevel = detectedLevel;

    // 应用相应的默认配置
    switch (detectedLevel) {
      case DevicePerformanceLevel.low:
        _config = PerformanceOptimizationConfig.forLowPerformance();
        break;
      case DevicePerformanceLevel.medium:
        _config = PerformanceOptimizationConfig.forMediumPerformance();
        break;
      case DevicePerformanceLevel.high:
        _config = PerformanceOptimizationConfig.forHighPerformance();
        break;
    }

    if (kDebugMode) {
      print('🔍 SelfAdaptivePerformanceOptimizer: 检测到设备性能等级为 $detectedLevel');
      print(
          '   计算时间: ${computeTime}ms, 可用内存: ${availableMemory ~/ (1024 * 1024)}MB');
      print('   应用配置: ${_config.toJson()}');
    }
  }

  /// 根据内存使用率确定内存压力级别
  MemoryPressureLevel _getMemoryPressureLevel(double memoryRatio) {
    if (memoryRatio > 0.9) {
      return MemoryPressureLevel.severe;
    } else if (memoryRatio > 0.75) {
      return MemoryPressureLevel.moderate;
    } else if (memoryRatio > 0.6) {
      return MemoryPressureLevel.mild;
    } else {
      return MemoryPressureLevel.normal;
    }
  }

  /// 开始性能监控和自适应优化
  void _startPerformanceMonitoring() {
    // 每5秒检查一次性能状态并调整
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_config.enableAdaptiveOptimization) {
        _adaptToCurrentPerformance();
        _adaptToMemoryPressure();
      }
    });
  }
}
