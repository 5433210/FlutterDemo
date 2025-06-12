import 'dart:collection';

import 'guideline_types.dart';

/// 参考线缓存项
class GuidelineCacheEntry {
  final List<Guideline> guidelines;
  final DateTime timestamp;
  final String cacheKey;
  final int accessCount;

  const GuidelineCacheEntry({
    required this.guidelines,
    required this.timestamp,
    required this.cacheKey,
    this.accessCount = 1,
  });

  GuidelineCacheEntry copyWith({
    List<Guideline>? guidelines,
    DateTime? timestamp,
    String? cacheKey,
    int? accessCount,
  }) {
    return GuidelineCacheEntry(
      guidelines: guidelines ?? this.guidelines,
      timestamp: timestamp ?? this.timestamp,
      cacheKey: cacheKey ?? this.cacheKey,
      accessCount: accessCount ?? this.accessCount,
    );
  }
}

/// 参考线缓存管理器
class GuidelineCacheManager {
  static const int _defaultMaxCacheSize = 100;
  static const Duration _defaultCacheExpiry = Duration(minutes: 5);

  final int maxCacheSize;
  final Duration cacheExpiry;
  final LinkedHashMap<String, GuidelineCacheEntry> _cache;

  GuidelineCacheManager({
    this.maxCacheSize = _defaultMaxCacheSize,
    this.cacheExpiry = _defaultCacheExpiry,
  }) : _cache = LinkedHashMap<String, GuidelineCacheEntry>();

  /// 缓存参考线
  void cacheGuidelines({
    required String elementId,
    required double x,
    required double y,
    required double width,
    required double height,
    required List<String> targetElementIds,
    required List<Guideline> guidelines,
  }) {
    final cacheKey = _generateCacheKey(
      elementId: elementId,
      x: x,
      y: y,
      width: width,
      height: height,
      targetElementIds: targetElementIds,
    );

    // 如果缓存已满，移除最少使用的项
    if (_cache.length >= maxCacheSize) {
      _evictLeastUsed();
    }

    final entry = GuidelineCacheEntry(
      guidelines: List<Guideline>.from(guidelines),
      timestamp: DateTime.now(),
      cacheKey: cacheKey,
    );

    _cache[cacheKey] = entry;
  }

  /// 清理过期的缓存项
  void cleanupExpiredEntries() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.timestamp) > cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }
  }

  /// 清空缓存
  void clearCache() {
    _cache.clear();
  }

  /// 获取缓存的参考线
  List<Guideline>? getCachedGuidelines({
    required String elementId,
    required double x,
    required double y,
    required double width,
    required double height,
    required List<String> targetElementIds,
  }) {
    final cacheKey = _generateCacheKey(
      elementId: elementId,
      x: x,
      y: y,
      width: width,
      height: height,
      targetElementIds: targetElementIds,
    );

    final entry = _cache[cacheKey];
    if (entry == null) {
      return null;
    }

    // 检查是否过期
    if (DateTime.now().difference(entry.timestamp) > cacheExpiry) {
      _cache.remove(cacheKey);
      return null;
    }

    // 更新访问计数并移动到末尾（LRU）
    _cache.remove(cacheKey);
    _cache[cacheKey] = entry.copyWith(
      accessCount: entry.accessCount + 1,
    );

    return entry.guidelines;
  }

  /// 获取缓存统计信息
  GuidelineCacheStats getCacheStats() {
    int totalAccess = 0;
    for (final entry in _cache.values) {
      totalAccess += entry.accessCount;
    }

    return GuidelineCacheStats(
      cacheSize: _cache.length,
      maxCacheSize: maxCacheSize,
      totalAccessCount: totalAccess,
      hitRate: totalAccess > 0 ? _cache.length / totalAccess : 0.0,
    );
  }

  /// 无效化特定元素的缓存
  void invalidateElementCache(String elementId) {
    final keysToRemove = <String>[];

    for (final key in _cache.keys) {
      if (key.startsWith('${elementId}_')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }
  }

  /// 无效化多个元素的缓存
  void invalidateElementsCache(List<String> elementIds) {
    for (final elementId in elementIds) {
      invalidateElementCache(elementId);
    }
  }

  /// 移除最少使用的缓存项
  void _evictLeastUsed() {
    if (_cache.isEmpty) return;

    // 找到访问次数最少的项
    GuidelineCacheEntry? leastUsedEntry;
    String? leastUsedKey;

    for (final entry in _cache.entries) {
      if (leastUsedEntry == null ||
          entry.value.accessCount < leastUsedEntry.accessCount) {
        leastUsedEntry = entry.value;
        leastUsedKey = entry.key;
      }
    }

    if (leastUsedKey != null) {
      _cache.remove(leastUsedKey);
    }
  }

  /// 生成缓存键
  String _generateCacheKey({
    required String elementId,
    required double x,
    required double y,
    required double width,
    required double height,
    required List<String> targetElementIds,
  }) {
    final sortedTargets = List<String>.from(targetElementIds)..sort();
    return '${elementId}_${x.toStringAsFixed(1)}_${y.toStringAsFixed(1)}_${width.toStringAsFixed(1)}_${height.toStringAsFixed(1)}_${sortedTargets.join(',')}';
  }
}

/// 缓存统计信息
class GuidelineCacheStats {
  final int cacheSize;
  final int maxCacheSize;
  final int totalAccessCount;
  final double hitRate;

  const GuidelineCacheStats({
    required this.cacheSize,
    required this.maxCacheSize,
    required this.totalAccessCount,
    required this.hitRate,
  });

  double get utilizationRate => cacheSize / maxCacheSize;

  @override
  String toString() {
    return 'GuidelineCacheStats(size: $cacheSize/$maxCacheSize, '
        'hitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
        'utilization: ${(utilizationRate * 100).toStringAsFixed(1)}%)';
  }
}
