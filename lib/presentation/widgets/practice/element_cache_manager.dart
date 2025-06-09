import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../infrastructure/logging/edit_page_logger_extension.dart';
import '../../../infrastructure/logging/logger.dart';
import 'memory_manager.dart';

/// 元素缓存性能指标
class CacheMetrics {
  int _totalRequests = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _evictions = 0;
  final Map<String, int> _typeHits = {};
  final Map<String, int> _typeMisses = {};

  /// 当前缓存大小（条目数）
  int currentSize = 0;

  /// 当前估计内存使用量（字节）
  int currentMemoryUsage = 0;

  /// 最大记录内存使用量
  int peakMemoryUsage = 0;

  /// 缓存命中率 (0.0 - 1.0)
  double get hitRate => _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0;

  /// 获取缓存指标报告
  Map<String, dynamic> getReport() {
    final typeStats = <String, Map<String, dynamic>>{};

    final allTypes = {..._typeHits.keys, ..._typeMisses.keys};
    for (final type in allTypes) {
      final hits = _typeHits[type] ?? 0;
      final misses = _typeMisses[type] ?? 0;
      final total = hits + misses;

      typeStats[type] = {
        'hits': hits,
        'misses': misses,
        'total': total,
        'hitRate': total > 0 ? hits / total : 0.0,
      };
    }

    return {
      'totalRequests': _totalRequests,
      'hits': _cacheHits,
      'misses': _cacheMisses,
      'hitRate': hitRate,
      'evictions': _evictions,
      'currentSize': currentSize,
      'memoryUsage': {
        'current': currentMemoryUsage,
        'peak': peakMemoryUsage,
        'readableSize': _formatBytes(currentMemoryUsage),
        'readablePeak': _formatBytes(peakMemoryUsage),
      },
      'byType': typeStats,
    };
  }

  /// 记录缓存清理
  void recordEviction() {
    _evictions++;
  }

  /// 记录缓存命中
  void recordHit(String elementId, String elementType) {
    _totalRequests++;
    _cacheHits++;
    _typeHits[elementType] = (_typeHits[elementType] ?? 0) + 1;
  }

  /// 记录缓存未命中
  void recordMiss(String elementId, String elementType) {
    _totalRequests++;
    _cacheMisses++;
    _typeMisses[elementType] = (_typeMisses[elementType] ?? 0) + 1;
  }

  /// 重置指标
  void reset() {
    _totalRequests = 0;
    _cacheHits = 0;
    _cacheMisses = 0;
    _evictions = 0;
    _typeHits.clear();
    _typeMisses.clear();
    // 保留当前大小和内存使用情况
  }

  /// 更新内存使用统计
  void updateMemoryUsage(int newUsage) {
    currentMemoryUsage = newUsage;
    if (newUsage > peakMemoryUsage) {
      peakMemoryUsage = newUsage;
    }
  }

  /// 格式化字节数为可读字符串
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// 缓存条目优先级
enum CachePriority {
  /// 低优先级 - 可能很快被丢弃
  low,

  /// 中等优先级 - 标准缓存项
  medium,

  /// 高优先级 - 尽量保留在缓存中
  high,

  /// 固定项 - 除非明确移除，否则不会被自动清除
  pinned,
}

/// 缓存策略类型
enum CacheStrategy {
  /// 基于时间的缓存策略 - 移除最近最少使用的项
  leastRecentlyUsed,

  /// 基于访问频率的缓存策略 - 移除最少访问的项
  leastFrequentlyUsed,

  /// 基于大小和优先级的缓存策略
  priorityBased,
}

/// Configuration for element cache
class ElementCacheConfiguration {
  final int maxCacheSize;
  final int maxMemoryUsage;
  final double cleanupThreshold;
  final bool enableAggressiveCleanup;

  ElementCacheConfiguration({
    required this.maxCacheSize,
    required this.maxMemoryUsage,
    required this.cleanupThreshold,
    required this.enableAggressiveCleanup,
  });
}

/// 元素缓存条目，存储渲染的Widget和相关元数据
class ElementCacheEntry {
  /// 缓存的Widget
  final Widget widget;

  /// 上次访问时间
  DateTime lastAccess;

  /// 访问计数
  int accessCount;

  /// 创建时间
  final DateTime creationTime;

  /// 元素属性
  final Map<String, dynamic> properties;

  /// 元素大小估计（字节）
  final int estimatedSize;

  /// 缓存优先级
  CachePriority priority;

  ElementCacheEntry({
    required this.widget,
    required this.properties,
    this.estimatedSize = 0,
    this.priority = CachePriority.medium,
    DateTime? lastAccess,
    int? accessCount,
  })  : lastAccess = lastAccess ?? DateTime.now(),
        creationTime = DateTime.now(),
        accessCount = accessCount ?? 0;

  /// 是否固定在缓存中
  bool get isPinned => priority == CachePriority.pinned;

  /// 访问此缓存条目，更新访问时间和计数
  void access() {
    lastAccess = DateTime.now();
    accessCount++;
  }

  /// 获取该条目的缓存得分（用于缓存清理决策）
  /// 分数越高，越应该保留在缓存中
  double getCacheScore() {
    final now = DateTime.now();
    final accessRecency = now.difference(lastAccess).inMilliseconds;
    final age = now.difference(creationTime).inMilliseconds;

    // 优先级权重
    final priorityWeight = switch (priority) {
      CachePriority.low => 1.0,
      CachePriority.medium => 5.0,
      CachePriority.high => 10.0,
      CachePriority.pinned => 100.0,
    };

    // 基本分数 = 优先级权重 × 访问次数 ÷ (访问时间间隔 × 元素大小)
    // 访问越频繁、越近访问过、体积越小的元素得分越高
    double score = priorityWeight *
        accessCount /
        (accessRecency * (estimatedSize > 0 ? estimatedSize : 1));

    // 防止新创建但未访问的元素立即被清除
    if (accessCount == 0 && age < 10000) {
      score = priorityWeight * 0.5; // 给新元素一个适中的基础分数
    }

    return score;
  }
}

/// 元素缓存管理器 - 负责存储和管理元素渲染的缓存
class ElementCacheManager extends ChangeNotifier {
  /// 默认最大缓存大小
  static const int _defaultMaxSize = 300;

  /// 默认内存使用阈值（30MB）
  static const int _defaultMemoryThreshold = 30 * 1024 * 1024;

  /// 缓存策略
  final CacheStrategy _strategy;

  /// 最大缓存条目数
  final int _maxSize;

  /// 内存使用阈值（字节）
  final int _memoryThreshold;

  /// 缓存项存储
  final Map<String, ElementCacheEntry> _cache = {};

  /// 缓存性能指标
  final CacheMetrics _metrics = CacheMetrics();

  /// 需要更新的元素ID集合
  final Set<String> _elementsNeedingUpdate = <String>{};

  /// 固定在缓存中的元素ID集合
  final Set<String> _pinnedElements = <String>{};

  /// Memory manager for comprehensive resource tracking
  MemoryManager? _memoryManager;

  /// 创建一个新的元素缓存管理器
  ElementCacheManager({
    CacheStrategy strategy = CacheStrategy.leastRecentlyUsed,
    int? maxSize,
    int? memoryThreshold,
    MemoryManager? memoryManager,
  })  : _strategy = strategy,
        _maxSize = maxSize ?? _defaultMaxSize,
        _memoryThreshold = memoryThreshold ?? _defaultMemoryThreshold,
        _memoryManager = memoryManager {
    EditPageLogger.performanceInfo(
      '元素缓存管理器创建完成',
      data: {
        'strategy': strategy.toString(),
        'maxSize': _maxSize,
        'memoryThreshold': _memoryThreshold,
        'memoryThresholdReadable': _formatBytes(_memoryThreshold),
      },
    );

    // Set up memory manager callbacks if provided
    if (_memoryManager != null) {
      _memoryManager!.onMemoryPressure = _handleMemoryPressure;
      _memoryManager!.onLowMemory = _handleLowMemory;
    }
  }

  /// Get max cache size
  int get maxCacheSize => _maxSize;

  /// 获取缓存指标
  CacheMetrics get metrics => _metrics;

  /// 清理过期缓存项
  void cleanupCache({bool force = false}) {
    final startTime = DateTime.now();

    if (_cache.isEmpty) return;

    // 检查是否需要清理
    final needsCleanup = force ||
        _cache.length > _maxSize ||
        _metrics.currentMemoryUsage > _memoryThreshold;

    if (!needsCleanup) return;

    EditPageLogger.performanceInfo(
      '开始缓存清理',
      data: {
        'currentCacheSize': _cache.length,
        'currentMemoryUsage': _metrics.currentMemoryUsage,
        'memoryUsageReadable': _formatBytes(_metrics.currentMemoryUsage),
        'memoryThreshold': _memoryThreshold,
        'force': force,
      },
    );

    // 创建条目列表，排除固定项
    final entries =
        _cache.entries.where((entry) => !entry.value.isPinned).toList();

    // 如果没有可清理项，直接返回
    if (entries.isEmpty) {
      EditPageLogger.performanceWarning(
        '无可清理的非固定条目',
        data: {
          'pinnedItemsCount': _pinnedElements.length,
          'totalCacheSize': _cache.length,
        },
      );
      return;
    }

    // 根据策略排序
    entries.sort((a, b) {
      switch (_strategy) {
        case CacheStrategy.leastRecentlyUsed:
          return a.value.lastAccess.compareTo(b.value.lastAccess);
        case CacheStrategy.leastFrequentlyUsed:
          return a.value.accessCount.compareTo(b.value.accessCount);
        case CacheStrategy.priorityBased:
          return a.value.getCacheScore().compareTo(b.value.getCacheScore());
      }
    });

    // 计算需要移除的条目数
    var targetRemovalCount = 0;
    if (_cache.length > _maxSize) {
      targetRemovalCount = (_cache.length - _maxSize * 0.8).ceil(); // 减少到80%容量
    }

    // 至少移除一个项，如果需要清理
    targetRemovalCount = math.max(1, targetRemovalCount);

    // 移除低分条目
    int removedCount = 0;
    int freedMemory = 0;

    for (var i = 0; i < math.min(targetRemovalCount, entries.length); i++) {
      final entry = entries[i];
      final id = entry.key;
      final cacheEntry = entry.value;

      if (_cache.remove(id) != null) {
        removedCount++;
        freedMemory += cacheEntry.estimatedSize;
        _metrics.recordEviction();
      }
    }

    // 更新指标
    _metrics.currentSize = _cache.length;
    _metrics.updateMemoryUsage(_metrics.currentMemoryUsage - freedMemory);

    final duration = DateTime.now().difference(startTime);

    EditPageLogger.performanceInfo(
      '缓存清理完成',
      data: {
        'duration_ms': duration.inMilliseconds,
        'removedCount': removedCount,
        'freedMemory': freedMemory,
        'freedMemoryReadable': _formatBytes(freedMemory),
        'newCacheSize': _cache.length,
        'newMemoryUsage': _metrics.currentMemoryUsage,
        'newMemoryUsageReadable': _formatBytes(_metrics.currentMemoryUsage),
      },
    );

    // 如果还是超过阈值，执行更激进的清理
    if (force && _metrics.currentMemoryUsage > _memoryThreshold) {
      EditPageLogger.performanceWarning(
        '缓存清理后仍超过内存阈值，执行激进清理',
        data: {
          'currentMemoryUsage': _metrics.currentMemoryUsage,
          'memoryThreshold': _memoryThreshold,
          'currentCacheSize': _cache.length,
        },
      );
      // 清除所有非固定缓存
      _cache.removeWhere((id, entry) => !entry.isPinned);

      // 重新计算内存使用量
      int newMemoryUsage = 0;
      for (final entry in _cache.values) {
        newMemoryUsage += entry.estimatedSize;
      }

      _metrics.currentSize = _cache.length;
      _metrics.updateMemoryUsage(newMemoryUsage);

      EditPageLogger.performanceInfo(
        '激进缓存清理完成',
        data: {
          'newCacheSize': _cache.length,
          'newMemoryUsage': _metrics.currentMemoryUsage,
          'newMemoryUsageReadable': _formatBytes(_metrics.currentMemoryUsage),
          'removedAllNonPinned': true,
        },
      );
    }

    notifyListeners();
  }

  /// 检查元素是否需要更新
  bool doesElementNeedUpdate(String elementId) {
    return _elementsNeedingUpdate.contains(elementId);
  }

  /// 从缓存中获取元素
  Widget? getElementWidget(String elementId, String elementType) {
    // 如果元素需要更新，返回null以强制重建
    if (_elementsNeedingUpdate.contains(elementId)) {
      _metrics.recordMiss(elementId, elementType);
      return null;
    }

    // 尝试从缓存获取
    final cacheEntry = _cache[elementId];
    if (cacheEntry == null) {
      _metrics.recordMiss(elementId, elementType);
      return null;
    } // 更新访问时间和计数
    cacheEntry.access();
    _metrics.recordHit(elementId, elementType);

    // Mark element accessed in memory manager
    if (_memoryManager != null) {
      _memoryManager!.markElementAccessed(elementId);
    }

    return cacheEntry.widget;
  }

  /// 标记所有元素需要更新
  void markAllElementsForUpdate(List<Map<String, dynamic>> elements) {
    _elementsNeedingUpdate.clear();
    _elementsNeedingUpdate.addAll(elements.map((e) => e['id'] as String));

    // 可选：完全清空缓存
    // _cache.clear();
    // _metrics.currentSize = 0;
    // _metrics.updateMemoryUsage(0);

    EditPageLogger.performanceInfo(
      '标记所有元素需要更新',
      data: {
        'elementCount': _elementsNeedingUpdate.length,
        'operation': 'markAllElementsForUpdate',
      },
    );

    notifyListeners();
  }

  /// 标记指定元素需要更新
  void markElementForUpdate(String elementId) {
    _elementsNeedingUpdate.add(elementId);

    // 从缓存中移除
    final removedEntry = _cache.remove(elementId);
    if (removedEntry != null) {
      _metrics.currentSize = _cache.length;
      _metrics.updateMemoryUsage(
          _metrics.currentMemoryUsage - removedEntry.estimatedSize);
    }

    EditPageLogger.performanceInfo(
      '标记元素需要更新',
      data: {
        'elementId': elementId,
        'wasInCache': removedEntry != null,
        'operation': 'markElementForUpdate',
      },
    );

    notifyListeners();
  }

  /// 标记多个元素需要更新
  void markElementsForUpdate(List<String> elementIds) {
    int removedMemory = 0;

    for (final id in elementIds) {
      _elementsNeedingUpdate.add(id);

      // 从缓存中移除
      final removedEntry = _cache.remove(id);
      if (removedEntry != null) {
        removedMemory += removedEntry.estimatedSize;
      }
    }

    if (removedMemory > 0) {
      _metrics.currentSize = _cache.length;
      _metrics.updateMemoryUsage(_metrics.currentMemoryUsage - removedMemory);
    }

    if (elementIds.isNotEmpty) {
      EditPageLogger.performanceInfo(
        '批量标记元素需要更新',
        data: {
          'elementCount': elementIds.length,
          'removedMemory': removedMemory,
          'operation': 'markElementsForUpdate',
        },
      );
    }

    if (elementIds.isNotEmpty) {
      notifyListeners();
    }
  }

  /// 固定元素到缓存中（防止被自动清理）
  void pinElement(String elementId) {
    final entry = _cache[elementId];
    if (entry != null) {
      entry.priority = CachePriority.pinned;
      _pinnedElements.add(elementId);
    }
  }

  /// 重置缓存状态
  void reset() {
    _cache.clear();
    _elementsNeedingUpdate.clear();
    _pinnedElements.clear();
    _metrics.reset();
    _metrics.currentSize = 0;
    _metrics.updateMemoryUsage(0);

    EditPageLogger.performanceInfo(
      '缓存重置完成',
      data: {
        'clearedCacheSize': _cache.length,
        'clearedUpdateElements': _elementsNeedingUpdate.length,
        'clearedPinnedElements': _pinnedElements.length,
        'operation': 'reset',
      },
    );

    notifyListeners();
  }

  /// Set memory manager for resource tracking
  void setMemoryManager(MemoryManager memoryManager) {
    _memoryManager = memoryManager;
    _memoryManager!.onMemoryPressure = _handleMemoryPressure;
    _memoryManager!.onLowMemory = _handleLowMemory;
  }

  /// 将元素存储到缓存中
  void storeElementWidget(
    String elementId,
    Widget widget,
    Map<String, dynamic> properties, {
    int estimatedSize = 0,
    CachePriority priority = CachePriority.medium,
    String elementType = 'unknown',
  }) {
    // 如果已存在，先移除旧条目
    final oldEntry = _cache.remove(elementId);
    int oldSize = 0;
    if (oldEntry != null) {
      oldSize = oldEntry.estimatedSize;
    }

    // 创建新的缓存条目
    final entry = ElementCacheEntry(
      widget: widget,
      properties: Map<String, dynamic>.from(properties),
      estimatedSize: estimatedSize,
      priority: priority,
    );

    // 保存到缓存
    _cache[elementId] = entry;

    // 更新指标
    _metrics.currentSize = _cache.length;
    _metrics.updateMemoryUsage(
        _metrics.currentMemoryUsage - oldSize + estimatedSize); // 从更新列表中移除
    _elementsNeedingUpdate.remove(elementId);

    // Register with memory manager if available
    if (_memoryManager != null) {
      _memoryManager!.registerElementMemory(elementId, properties);
      _memoryManager!.markElementAccessed(elementId);
    }

    // 检查是否需要清理缓存
    if (_cache.length > _maxSize ||
        _metrics.currentMemoryUsage > _memoryThreshold) {
      // 使用Future.microtask延迟清理，避免在构建过程中执行
      Future.microtask(() => cleanupCache());
    }
  }

  /// 取消固定元素
  void unpinElement(String elementId) {
    final entry = _cache[elementId];
    if (entry != null && entry.isPinned) {
      entry.priority = CachePriority.high; // 默认降级为高优先级
      _pinnedElements.remove(elementId);
    }
  }

  /// Update cache configuration
  void updateConfiguration(ElementCacheConfiguration config) {
    // Note: This implementation doesn't change _maxSize as it's final
    // In a real implementation, you might want to make _maxSize mutable
    EditPageLogger.performanceInfo(
      '缓存配置更新',
      data: {
        'newMaxCacheSize': config.maxCacheSize,
        'newMaxMemoryUsage': config.maxMemoryUsage,
        'cleanupThreshold': config.cleanupThreshold,
        'enableAggressiveCleanup': config.enableAggressiveCleanup,
        'currentCacheSize': _cache.length,
      },
    );

    // Apply the cleanup threshold by triggering cleanup if needed
    if (config.enableAggressiveCleanup || _cache.length > config.maxCacheSize) {
      cleanupCache(force: config.enableAggressiveCleanup);
    }
  }

  /// Update max cache size
  void updateMaxCacheSize(int newSize) {
    // Note: Since _maxSize is final, we can't actually change it
    // This method exists for API compatibility
    EditPageLogger.performanceInfo(
      '请求更新最大缓存大小',
      data: {
        'requestedSize': newSize,
        'currentMaxSize': _maxSize,
        'currentCacheSize': _cache.length,
        'note': 'maxSize is final, cannot be changed',
      },
    );

    // Trigger cleanup if current size exceeds new size
    if (_cache.length > newSize) {
      cleanupCache(force: true);
    }
  }

  /// 格式化字节数为可读字符串
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Handle low memory callback from MemoryManager
  void _handleLowMemory() {
    EditPageLogger.performanceWarning(
      '检测到低内存，触发激进清理',
      data: {
        'currentCacheSize': _cache.length,
        'currentMemoryUsage': _metrics.currentMemoryUsage,
        'memoryThreshold': _memoryThreshold,
        'operation': '_handleLowMemory',
      },
    );
    cleanupCache(force: true);
  }

  /// Handle memory pressure callback from MemoryManager
  void _handleMemoryPressure() {
    EditPageLogger.performanceWarning(
      '检测到内存压力，触发清理',
      data: {
        'currentCacheSize': _cache.length,
        'currentMemoryUsage': _metrics.currentMemoryUsage,
        'memoryThreshold': _memoryThreshold,
        'operation': '_handleMemoryPressure',
      },
    );
    cleanupCache(force: false);
  }
}
