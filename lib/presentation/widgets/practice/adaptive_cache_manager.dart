import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'element_cache_manager.dart';
import 'memory_manager.dart';

/// Adaptive cache manager that optimizes cache sizes based on available memory
class AdaptiveCacheManager extends ChangeNotifier {
  static const int _defaultBaseMemoryLimit = 64 * 1024 * 1024; // 64MB base
  static const int _maxMemoryLimit = 512 * 1024 * 1024; // 512MB max
  static const double _memoryPressureThreshold = 0.75; // 75% memory usage
  static const double _criticalMemoryThreshold = 0.9; // 90% memory usage

  static const int _maxPerformanceHistory = 20;
  final MemoryManager _memoryManager;

  final ElementCacheManager _elementCacheManager;
  int _currentMemoryLimit = _defaultBaseMemoryLimit;
  int _availableSystemMemory = 0;

  Timer? _adaptationTimer;

  /// Memory adaptation strategies
  CacheAdaptationStrategy _currentStrategy = CacheAdaptationStrategy.balanced;

  /// Performance metrics for adaptation decisions
  final List<PerformanceSnapshot> _performanceHistory = [];

  AdaptiveCacheManager({
    required MemoryManager memoryManager,
    required ElementCacheManager elementCacheManager,
  })  : _memoryManager = memoryManager,
        _elementCacheManager = elementCacheManager {
    _initializeAdaptiveManagement();
  }

  /// Current memory configuration
  MemoryConfiguration get currentConfiguration => MemoryConfiguration(
        elementCacheLimit: _elementCacheManager.maxCacheSize,
        imageMemoryLimit: _memoryManager.maxMemoryBytes,
        totalMemoryLimit: _currentMemoryLimit,
        adaptationStrategy: _currentStrategy,
        systemMemoryAvailable: _availableSystemMemory,
      );

  @override
  void dispose() {
    _adaptationTimer?.cancel();
    _memoryManager.removeListener(_onMemoryStateChanged);
    super.dispose();
  }

  /// Get optimization recommendations
  OptimizationRecommendations getOptimizationRecommendations() {
    final memoryStats = _memoryManager.memoryStats;
    final cacheMetrics = _elementCacheManager.metrics;

    final recommendations = <String>[];
    final warnings = <String>[];

    // Memory analysis
    if (memoryStats.pressureRatio > _criticalMemoryThreshold) {
      warnings.add(
          'Critical memory usage: ${(memoryStats.pressureRatio * 100).toStringAsFixed(1)}%');
      recommendations
          .add('Consider reducing cache sizes or clearing unused elements');
    } else if (memoryStats.pressureRatio > _memoryPressureThreshold) {
      warnings.add(
          'High memory usage: ${(memoryStats.pressureRatio * 100).toStringAsFixed(1)}%');
      recommendations.add('Monitor memory usage and consider cleanup');
    }

    // Cache performance analysis
    if (cacheMetrics.hitRate < 0.6) {
      warnings.add(
          'Low cache hit rate: ${(cacheMetrics.hitRate * 100).toStringAsFixed(1)}%');
      recommendations
          .add('Consider increasing cache size or improving element reuse');
    }

    // Large element analysis
    if (memoryStats.largeElementCount > 10) {
      warnings.add('Many large elements: ${memoryStats.largeElementCount}');
      recommendations
          .add('Consider lazy loading or memory-efficient representations');
    }

    return OptimizationRecommendations(
      currentStrategy: _currentStrategy,
      memoryEfficiency: _calculateMemoryEfficiency(memoryStats, cacheMetrics),
      cacheEfficiency: cacheMetrics.hitRate,
      recommendations: recommendations,
      warnings: warnings,
    );
  }

  /// Adapt cache limits to system memory
  void _adaptToSystemMemory() {
    // Use 10-25% of available system memory for our caches
    final recommendedLimit = (_availableSystemMemory * 0.15).toInt();
    _currentMemoryLimit = math.min(
        math.max(recommendedLimit, _defaultBaseMemoryLimit), _maxMemoryLimit);

    if (kDebugMode) {
      print(
          '🧠 AdaptiveCacheManager: Detected ${_formatBytes(_availableSystemMemory)} system memory, '
          'setting cache limit to ${_formatBytes(_currentMemoryLimit)}');
    }
  }

  /// Apply balanced optimization strategy
  Future<void> _applyBalancedStrategy() async {
    // Balanced approach between memory and performance
    final newCacheSize =
        math.max(50, math.min(150, _elementCacheManager.maxCacheSize));

    _elementCacheManager.updateConfiguration(ElementCacheConfiguration(
      maxCacheSize: newCacheSize,
      maxMemoryUsage: (_currentMemoryLimit * 0.5).toInt(),
      cleanupThreshold: 0.8,
      enableAggressiveCleanup: false,
    ));

    _memoryManager.updateMemoryLimits(
      maxMemoryBytes: (_currentMemoryLimit * 0.6).toInt(),
      enableAggressiveCleanup: false,
    );

    if (kDebugMode) {
      print(
          '⚖️ AdaptiveCacheManager: Applied balanced strategy (cache: $newCacheSize elements)');
    }
  }

  /// Apply memory-first optimization strategy
  Future<void> _applyMemoryFirstStrategy() async {
    // Reduce cache sizes aggressively
    final newCacheSize =
        math.max(20, (_elementCacheManager.maxCacheSize * 0.6).toInt());
    _elementCacheManager.updateConfiguration(ElementCacheConfiguration(
      maxCacheSize: newCacheSize,
      maxMemoryUsage: (_currentMemoryLimit * 0.3).toInt(),
      cleanupThreshold: 0.7,
      enableAggressiveCleanup: true,
    ));

    // Reduce memory manager limits
    _memoryManager.updateMemoryLimits(
      maxMemoryBytes: (_currentMemoryLimit * 0.4).toInt(),
      enableAggressiveCleanup: true,
    );

    if (kDebugMode) {
      print(
          '🛡️ AdaptiveCacheManager: Applied memory-first strategy (cache: $newCacheSize elements)');
    }
  }

  /// Apply performance-first optimization strategy
  Future<void> _applyPerformanceFirstStrategy() async {
    // Increase cache sizes for better performance
    final systemMemoryRatio = _currentMemoryLimit / _availableSystemMemory;
    final newCacheSize =
        math.min(200, (_elementCacheManager.maxCacheSize * 1.5).toInt());

    _elementCacheManager.updateConfiguration(ElementCacheConfiguration(
      maxCacheSize: newCacheSize,
      maxMemoryUsage: (_currentMemoryLimit * 0.7).toInt(),
      cleanupThreshold: 0.9,
      enableAggressiveCleanup: false,
    ));

    // Increase memory manager limits if system allows
    if (systemMemoryRatio < 0.3) {
      _memoryManager.updateMemoryLimits(
        maxMemoryBytes: (_currentMemoryLimit * 0.8).toInt(),
        enableAggressiveCleanup: false,
      );
    }

    if (kDebugMode) {
      print(
          '🚀 AdaptiveCacheManager: Applied performance-first strategy (cache: $newCacheSize elements)');
    }
  }

  /// Apply adaptation strategy
  Future<void> _applyStrategy(CacheAdaptationStrategy strategy) async {
    switch (strategy) {
      case CacheAdaptationStrategy.memoryFirst:
        await _applyMemoryFirstStrategy();
        break;
      case CacheAdaptationStrategy.performanceFirst:
        await _applyPerformanceFirstStrategy();
        break;
      case CacheAdaptationStrategy.balanced:
        await _applyBalancedStrategy();
        break;
    }
  }

  /// Calculate overall memory efficiency score
  double _calculateMemoryEfficiency(
      MemoryStats memoryStats, CacheMetrics cacheMetrics) {
    final memoryScore = 1.0 - memoryStats.pressureRatio;
    final cacheScore = cacheMetrics.hitRate;
    final largeElementPenalty =
        math.min(1.0, memoryStats.largeElementCount / 20.0) * 0.1;

    return math.max(
        0.0, (memoryScore + cacheScore) / 2.0 - largeElementPenalty);
  }

  /// Detect available system memory
  void _detectSystemMemory() {
    // In a real implementation, this would query the system for available memory
    // For now, we'll estimate based on platform and provide reasonable defaults

    if (kIsWeb) {
      _availableSystemMemory = 2 * 1024 * 1024 * 1024; // 2GB estimate for web
    } else {
      // For mobile/desktop, we'll use more conservative estimates
      _availableSystemMemory = 4 * 1024 * 1024 * 1024; // 4GB estimate
    }

    // Adjust our limits based on available memory
    _adaptToSystemMemory();
  }

  /// Determine optimal adaptation strategy
  CacheAdaptationStrategy _determineOptimalStrategy(
      MemoryStats memoryStats, CacheMetrics cacheMetrics) {
    final memoryPressure = memoryStats.pressureRatio;
    final hitRate = cacheMetrics.hitRate;

    // Critical memory situation - aggressive cleanup
    if (memoryPressure > _criticalMemoryThreshold) {
      return CacheAdaptationStrategy.memoryFirst;
    }

    // High memory pressure but good cache performance
    if (memoryPressure > _memoryPressureThreshold && hitRate > 0.8) {
      return CacheAdaptationStrategy.balanced;
    }

    // Low memory pressure but poor cache performance
    if (memoryPressure < 0.5 && hitRate < 0.6) {
      return CacheAdaptationStrategy.performanceFirst;
    }

    // Analyze performance trends
    if (_performanceHistory.length >= 5) {
      final recentPerformance = _performanceHistory
          .sublist(math.max(0, _performanceHistory.length - 5));
      final avgHitRate =
          recentPerformance.map((s) => s.cacheHitRate).reduce((a, b) => a + b) /
              recentPerformance.length;
      final avgMemoryPressure = recentPerformance
              .map((s) => s.memoryPressure)
              .reduce((a, b) => a + b) /
          recentPerformance.length;

      if (avgMemoryPressure > 0.8 && avgHitRate < 0.7) {
        return CacheAdaptationStrategy.memoryFirst;
      }

      if (avgMemoryPressure < 0.4 && avgHitRate > 0.9) {
        return CacheAdaptationStrategy.performanceFirst;
      }
    }

    return CacheAdaptationStrategy.balanced;
  }

  /// Format bytes for display
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Initialize adaptive memory management
  void _initializeAdaptiveManagement() {
    _detectSystemMemory();
    _startAdaptationMonitoring();

    // Listen to memory manager changes
    _memoryManager.addListener(_onMemoryStateChanged);
  }

  /// React to memory state changes
  void _onMemoryStateChanged() {
    final memoryStats = _memoryManager.memoryStats;

    // Record performance snapshot
    _recordPerformanceSnapshot(memoryStats);

    // Trigger immediate adaptation if under pressure
    if (memoryStats.pressureRatio > _memoryPressureThreshold) {
      _performAdaptation();
    }
  }

  /// Fine-tune cache sizes based on performance metrics
  void _optimizeCacheSizes(MemoryStats memoryStats, CacheMetrics cacheMetrics) {
    // Calculate optimal cache size based on hit rate and memory usage
    final currentHitRate = cacheMetrics.hitRate;
    final memoryEfficiency = memoryStats.currentUsage > 0
        ? (cacheMetrics.currentSize /
            (memoryStats.currentUsage / (1024 * 1024)))
        : 0.0;

    // Adjust cache size if hit rate is consistently low or high
    final recentHitRates = _performanceHistory
        .sublist(math.max(0, _performanceHistory.length - 3))
        .map((s) => s.cacheHitRate)
        .toList();
    final avgHitRate =
        recentHitRates.reduce((a, b) => a + b) / recentHitRates.length;

    if (avgHitRate < 0.6 && memoryStats.pressureRatio < 0.7) {
      // Low hit rate with available memory - increase cache
      final newSize =
          math.min(200, (_elementCacheManager.maxCacheSize * 1.2).toInt());
      _elementCacheManager.updateMaxCacheSize(newSize);
    } else if (avgHitRate > 0.95 && memoryStats.pressureRatio > 0.6) {
      // Very high hit rate with memory pressure - reduce cache slightly
      final newSize =
          math.max(30, (_elementCacheManager.maxCacheSize * 0.9).toInt());
      _elementCacheManager.updateMaxCacheSize(newSize);
    }
  }

  /// Perform adaptive cache optimization
  Future<void> _performAdaptation() async {
    final memoryStats = _memoryManager.memoryStats;
    final cacheMetrics = _elementCacheManager.metrics;

    // Determine optimal strategy based on current conditions
    final newStrategy = _determineOptimalStrategy(memoryStats, cacheMetrics);

    if (newStrategy != _currentStrategy) {
      if (kDebugMode) {
        print(
            '🔄 AdaptiveCacheManager: Switching strategy from $_currentStrategy to $newStrategy');
      }

      _currentStrategy = newStrategy;
      await _applyStrategy(newStrategy);
      notifyListeners();
    }

    // Fine-tune cache sizes based on performance
    _optimizeCacheSizes(memoryStats, cacheMetrics);
  }

  /// Record performance metrics for adaptation decisions
  void _recordPerformanceSnapshot(MemoryStats memoryStats) {
    final snapshot = PerformanceSnapshot(
      timestamp: DateTime.now(),
      memoryUsage: memoryStats.currentUsage,
      memoryPressure: memoryStats.pressureRatio,
      cacheHitRate: _elementCacheManager.metrics.hitRate,
      totalElements: memoryStats.trackedElementCount,
      largeElements: memoryStats.largeElementCount,
    );

    _performanceHistory.add(snapshot);
    if (_performanceHistory.length > _maxPerformanceHistory) {
      _performanceHistory.removeAt(0);
    }
  }

  /// Start monitoring for adaptive adjustments
  void _startAdaptationMonitoring() {
    _adaptationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _performAdaptation();
    });
  }
}

/// Cache adaptation strategies
enum CacheAdaptationStrategy {
  memoryFirst, // Prioritize memory conservation
  performanceFirst, // Prioritize cache performance
  balanced, // Balance memory and performance
}

/// Reference to ElementCacheConfiguration from element_cache_manager.dart
// This class is defined in element_cache_manager.dart and should be imported from there
// Using the same definition here causes a type conflict

/// Memory configuration data
class MemoryConfiguration {
  final int elementCacheLimit;
  final int imageMemoryLimit;
  final int totalMemoryLimit;
  final CacheAdaptationStrategy adaptationStrategy;
  final int systemMemoryAvailable;

  MemoryConfiguration({
    required this.elementCacheLimit,
    required this.imageMemoryLimit,
    required this.totalMemoryLimit,
    required this.adaptationStrategy,
    required this.systemMemoryAvailable,
  });
}

/// Optimization recommendations
class OptimizationRecommendations {
  final CacheAdaptationStrategy currentStrategy;
  final double memoryEfficiency;
  final double cacheEfficiency;
  final List<String> recommendations;
  final List<String> warnings;

  OptimizationRecommendations({
    required this.currentStrategy,
    required this.memoryEfficiency,
    required this.cacheEfficiency,
    required this.recommendations,
    required this.warnings,
  });
}

/// Performance snapshot for analysis
class PerformanceSnapshot {
  final DateTime timestamp;
  final int memoryUsage;
  final double memoryPressure;
  final double cacheHitRate;
  final int totalElements;
  final int largeElements;

  PerformanceSnapshot({
    required this.timestamp,
    required this.memoryUsage,
    required this.memoryPressure,
    required this.cacheHitRate,
    required this.totalElements,
    required this.largeElements,
  });
}
