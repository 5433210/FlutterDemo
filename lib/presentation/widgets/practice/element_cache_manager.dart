import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  /// 创建一个新的元素缓存管理器
  ElementCacheManager({
    CacheStrategy strategy = CacheStrategy.leastRecentlyUsed,
    int? maxSize,
    int? memoryThreshold,
  })  : _strategy = strategy,
        _maxSize = maxSize ?? _defaultMaxSize,
        _memoryThreshold = memoryThreshold ?? _defaultMemoryThreshold {
    if (kDebugMode) {
      print(
          '🧠 ElementCacheManager: Created with strategy=$strategy, maxSize=$_maxSize, memoryThreshold=${_formatBytes(_memoryThreshold)}');
    }
  }

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

    if (kDebugMode) {
      print(
          '🧹 ElementCacheManager: Starting cache cleanup. Current size: ${_cache.length}, Memory: ${_formatBytes(_metrics.currentMemoryUsage)}');
    }

    // 创建条目列表，排除固定项
    final entries =
        _cache.entries.where((entry) => !entry.value.isPinned).toList();

    // 如果没有可清理项，直接返回
    if (entries.isEmpty) {
      if (kDebugMode) {
        print(
            '⚠️ ElementCacheManager: No non-pinned entries to clean up. Pinned items: ${_pinnedElements.length}');
      }
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

    if (kDebugMode) {
      print(
          '🧹 ElementCacheManager: Cleanup completed in ${duration.inMilliseconds}ms.');
      print(
          '   Removed $removedCount items, freed ${_formatBytes(freedMemory)}.');
      print(
          '   New cache size: ${_cache.length}, Memory: ${_formatBytes(_metrics.currentMemoryUsage)}');
    }

    // 如果还是超过阈值，执行更激进的清理
    if (force && _metrics.currentMemoryUsage > _memoryThreshold) {
      if (kDebugMode) {
        print(
            '⚠️ ElementCacheManager: Still over memory threshold after cleanup. Performing aggressive cleanup.');
      }
      // 清除所有非固定缓存
      _cache.removeWhere((id, entry) => !entry.isPinned);

      // 重新计算内存使用量
      int newMemoryUsage = 0;
      for (final entry in _cache.values) {
        newMemoryUsage += entry.estimatedSize;
      }

      _metrics.currentSize = _cache.length;
      _metrics.updateMemoryUsage(newMemoryUsage);

      if (kDebugMode) {
        print('🧹 ElementCacheManager: Aggressive cleanup completed.');
        print(
            '   New cache size: ${_cache.length}, Memory: ${_formatBytes(_metrics.currentMemoryUsage)}');
      }
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
    }

    // 更新访问时间和计数
    cacheEntry.access();
    _metrics.recordHit(elementId, elementType);

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

    if (kDebugMode) {
      print(
          '🔄 ElementCacheManager: Marked all ${_elementsNeedingUpdate.length} elements for update');
    }

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

    if (kDebugMode) {
      print('🔄 ElementCacheManager: Marked element $elementId for update');
    }

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

    if (kDebugMode && elementIds.isNotEmpty) {
      print(
          '🔄 ElementCacheManager: Marked ${elementIds.length} elements for update');
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

    if (kDebugMode) {
      print('🧹 ElementCacheManager: Cache reset');
    }

    notifyListeners();
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
        _metrics.currentMemoryUsage - oldSize + estimatedSize);

    // 从更新列表中移除
    _elementsNeedingUpdate.remove(elementId);

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

  /// 格式化字节数为可读字符串
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
