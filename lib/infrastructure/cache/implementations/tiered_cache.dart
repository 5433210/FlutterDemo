import 'dart:async';

import '../interfaces/i_cache.dart';

/// 多级缓存实现
/// 
/// 组合内存缓存和磁盘缓存，提供两级缓存机制
class TieredCache<K, V> implements ICache<K, V> {
  /// 主缓存（通常是内存缓存）
  final ICache<K, V> _primaryCache;
  
  /// 次级缓存（通常是磁盘缓存）
  final ICache<K, V> _secondaryCache;
  
  /// 构造函数
  /// 
  /// [primaryCache] 主缓存，通常是内存缓存
  /// [secondaryCache] 次级缓存，通常是磁盘缓存
  TieredCache({
    required ICache<K, V> primaryCache,
    required ICache<K, V> secondaryCache,
  }) : _primaryCache = primaryCache,
       _secondaryCache = secondaryCache;
  
  @override
  Future<V?> get(K key) async {
    // 先从主缓存获取
    final primaryResult = await _primaryCache.get(key);
    if (primaryResult != null) {
      return primaryResult;
    }
    
    // 如果主缓存没有，从次级缓存获取
    final secondaryResult = await _secondaryCache.get(key);
    if (secondaryResult != null) {
      // 将次级缓存的结果更新到主缓存
      await _primaryCache.put(key, secondaryResult);
      return secondaryResult;
    }
    
    return null;
  }
  
  @override
  Future<void> put(K key, V value) async {
    // 同时更新主缓存和次级缓存
    await _primaryCache.put(key, value);
    await _secondaryCache.put(key, value);
  }
  
  @override
  Future<void> invalidate(K key) async {
    // 同时从主缓存和次级缓存移除
    await _primaryCache.invalidate(key);
    await _secondaryCache.invalidate(key);
  }
  
  @override
  Future<void> clear() async {
    // 清空所有缓存
    await _primaryCache.clear();
    await _secondaryCache.clear();
  }
  
  @override
  Future<int> size() async {
    // 返回次级缓存大小（通常是磁盘缓存，更能反映总体大小）
    return await _secondaryCache.size();
  }
  
  @override
  Future<bool> containsKey(K key) async {
    // 检查任一缓存是否包含键
    return await _primaryCache.containsKey(key) || 
           await _secondaryCache.containsKey(key);
  }
  
  @override
  Future<void> remove(K key) async {
    // 同时从主缓存和次级缓存移除
    await _primaryCache.remove(key);
    await _secondaryCache.remove(key);
  }
  
  @override
  Future<void> evict(K key) async {
    // evict与remove行为相同
    await remove(key);
  }
}
