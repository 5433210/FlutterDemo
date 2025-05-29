import 'dart:async';

import '../interfaces/i_cache.dart';

/// 基于LRU算法的内存缓存实现
class MemoryCache<K, V> implements ICache<K, V> {
  /// 缓存容量
  final int _capacity;
  
  /// 缓存数据
  final Map<K, V> _cache = {};
  
  /// 缓存键的访问顺序
  final List<K> _keys = [];
  
  /// 构造函数
  /// 
  /// [capacity] 缓存的最大容量
  MemoryCache({required int capacity}) : _capacity = capacity;
  
  @override
  Future<V?> get(K key) async {
    if (!_cache.containsKey(key)) return null;
    
    // 更新访问顺序（将访问的键移到列表末尾，表示最近使用）
    _keys.remove(key);
    _keys.add(key);
    
    return _cache[key];
  }
  
  @override
  Future<void> put(K key, V value) async {
    if (_cache.containsKey(key)) {
      // 键已存在，更新值并更新访问顺序
      _keys.remove(key);
    } else if (_keys.length >= _capacity) {
      // 缓存已满，移除最近最少使用的项（列表开头的键）
      final oldestKey = _keys.removeAt(0);
      _cache.remove(oldestKey);
    }
    
    // 添加新值并更新访问顺序
    _cache[key] = value;
    _keys.add(key);
  }
  
  @override
  Future<void> invalidate(K key) async {
    _cache.remove(key);
    _keys.remove(key);
  }
  
  @override
  Future<void> clear() async {
    _cache.clear();
    _keys.clear();
  }
  
  @override
  Future<int> size() async {
    return _cache.length;
  }
  
  @override
  Future<bool> containsKey(K key) async {
    return _cache.containsKey(key);
  }
  
  @override
  Future<void> remove(K key) async {
    _cache.remove(key);
    _keys.remove(key);
  }
  
  /// 获取所有缓存键
  Set<K> get keys => _cache.keys.toSet();
  
  /// 获取当前缓存项数量
  int get length => _cache.length;
}
