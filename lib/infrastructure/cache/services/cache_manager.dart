import 'dart:async';

import 'package:flutter/foundation.dart';

import '../interfaces/i_cache.dart';

/// 全局缓存管理器
class CacheManager {
  /// 注册的缓存列表
  final List<ICache> _registeredCaches = [];
  
  /// 定时器
  Timer? _monitoringTimer;
  
  /// 注册缓存
  void registerCache(ICache cache) {
    _registeredCaches.add(cache);
  }
  
  /// 清除所有缓存
  Future<void> clearAll() async {
    for (final cache in _registeredCaches) {
      await cache.clear();
    }
    debugPrint('已清除所有缓存');
  }
  
  /// 监控内存使用
  void startMemoryMonitoring({Duration interval = const Duration(minutes: 5)}) {
    // 停止现有的监控
    stopMemoryMonitoring();
    
    // 启动新的监控
    _monitoringTimer = Timer.periodic(interval, (_) {
      _checkMemoryUsage();
    });
    
    debugPrint('已启动缓存监控，间隔: ${interval.inMinutes}分钟');
  }
  
  /// 停止内存监控
  void stopMemoryMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }
  
  /// 检查内存使用情况
  Future<void> _checkMemoryUsage() async {
    try {
      // 获取总缓存大小
      final totalSize = await getTotalCacheSize();
      debugPrint('当前缓存总大小: ${(totalSize / (1024 * 1024)).toStringAsFixed(2)}MB');
      
      // 如果总缓存大小超过阈值，清理部分缓存
      // 这里使用200MB作为示例阈值，实际应该从配置中获取
      if (totalSize > 200 * 1024 * 1024) { // 200MB
        debugPrint('缓存大小超过阈值，开始清理');
        await _trimCaches();
      }
    } catch (e) {
      debugPrint('检查内存使用失败: $e');
    }
  }
  
  /// 裁剪缓存大小
  Future<void> _trimCaches() async {
    // 这里可以实现更复杂的裁剪策略
    // 目前简单地清理一半的缓存
    for (final cache in _registeredCaches) {
      try {
        // 获取当前缓存大小
        final cacheSize = await cache.size();
        
        // 如果是内存缓存，可以考虑清理一部分
        // 这里简单地清空，实际应该有更精细的策略
        if (cacheSize > 0) {
          await cache.clear();
          debugPrint('已清理缓存: $cache');
        }
      } catch (e) {
        debugPrint('清理缓存失败: $e');
      }
    }
  }
  
  /// 获取总缓存大小
  Future<int> getTotalCacheSize() async {
    int total = 0;
    for (final cache in _registeredCaches) {
      try {
        total += await cache.size();
      } catch (e) {
        debugPrint('获取缓存大小失败: $e');
      }
    }
    return total;
  }
  
  /// 析构函数
  void dispose() {
    stopMemoryMonitoring();
  }
}
