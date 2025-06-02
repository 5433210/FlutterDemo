/// Canvas渲染系统 - 渲染缓存 (Phase 2.5)
///
/// 职责:
/// 1. 管理渲染缓存
/// 2. 提供LRU缓存策略
/// 3. 控制缓存大小和内存使用
/// 4. 提供缓存统计和诊断
library;

import 'dart:collection';
import 'dart:ui' as ui;

/// 缓存条目
class CacheEntry {
  final ui.Picture picture;
  final DateTime createdAt;

  CacheEntry(this.picture, this.createdAt);
}

/// 渲染缓存管理器
///
/// 按照设计文档实现的缓存机制，用于优化重复渲染
class RenderCache {
  final int _maxCacheSize;
  final LinkedHashMap<String, CacheEntry> _cache = LinkedHashMap();
  int _currentSize = 0;

  // 统计信息
  int _hitCount = 0;
  int _missCount = 0;

  RenderCache({int maxCacheSize = 100}) : _maxCacheSize = maxCacheSize;

  /// 缓存渲染结果
  void cacheElement(String elementId, int version, ui.Picture picture) {
    final key = '$elementId:$version';
    final entry = CacheEntry(picture, DateTime.now());

    // 如果已存在，移除旧的
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _currentSize--;
    }

    // 检查缓存大小限制
    while (_currentSize >= _maxCacheSize && _cache.isNotEmpty) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
      _currentSize--;
    }

    // 添加新条目
    _cache[key] = entry;
    _currentSize++;
  }

  /// 清理过期缓存
  void cleanup() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cache.entries) {
      if (now.difference(entry.value.createdAt).inMinutes > 30) {
        // 30分钟过期
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
      _currentSize--;
    }
  }

  /// 清除所有缓存
  void clear() {
    _cache.clear();
    _currentSize = 0;
  }

  /// 获取缓存的渲染结果
  ui.Picture? getRenderedElement(String elementId, int version) {
    final key = '$elementId:$version';
    final entry = _cache[key];

    if (entry != null) {
      _hitCount++;
      // 更新访问时间（LRU）
      _cache.remove(key);
      _cache[key] = entry;
      return entry.picture;
    }

    _missCount++;
    return null;
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getStats() {
    final totalRequests = _hitCount + _missCount;
    final hitRate = totalRequests > 0 ? _hitCount / totalRequests : 0.0;

    return {
      'hitCount': _hitCount,
      'missCount': _missCount,
      'hitRate': hitRate,
      'cacheSize': _currentSize,
      'maxCacheSize': _maxCacheSize,
    };
  }

  /// 清除特定元素的缓存
  void invalidateElement(String elementId) {
    final keysToRemove =
        _cache.keys.where((key) => key.startsWith('$elementId:')).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _currentSize--;
    }
  }
}
