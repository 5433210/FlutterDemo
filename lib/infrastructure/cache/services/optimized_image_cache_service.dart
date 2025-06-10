import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../logging/logger.dart';
import '../../monitoring/performance_monitor.dart';

/// 🚀 优化的图像缓存服务
/// 提供智能缓存管理、请求去重、批量处理等优化功能
class OptimizedImageCacheService {
  final PerformanceMonitor _performanceMonitor;
  
  // 🔧 缓存存储
  final Map<String, ui.Image> _imageCache = {};
  final Map<String, Uint8List> _binaryCache = {};
  
  // 🔧 请求去重 - 防止同一图像的并发加载
  final Map<String, Future<ui.Image?>> _pendingImageRequests = {};
  final Map<String, Future<Uint8List?>> _pendingBinaryRequests = {};
  
  // 🔧 访问频率统计 - 用于智能预加载
  final Map<String, int> _accessCount = {};
  final Map<String, DateTime> _lastAccess = {};
  
  // 🔧 批量处理队列
  final Queue<_CacheRequest> _requestQueue = Queue();
  Timer? _batchTimer;
  
  // 🔧 配置参数
  static const int _maxCacheSize = 200;
  static const int _maxBinarySize = 100;
  static const Duration _batchDelay = Duration(milliseconds: 100);
  static const int _hotThreshold = 5; // 访问5次以上视为热点图像

  OptimizedImageCacheService(this._performanceMonitor);

  /// 🚀 获取UI图像（带智能缓存）
  Future<ui.Image?> getUiImage(String key) async {
    final startTime = DateTime.now();
    
    try {
      // 更新访问统计
      _updateAccessStats(key);
      
      // 检查缓存
      if (_imageCache.containsKey(key)) {
        _performanceMonitor.recordCacheOperation('ui_image', true, null);
        return _imageCache[key];
      }
      
      // 检查是否有正在进行的请求
      if (_pendingImageRequests.containsKey(key)) {
        return await _pendingImageRequests[key];
      }
      
      _performanceMonitor.recordCacheOperation('ui_image', false, null);
      return null;
      
    } finally {
      final duration = DateTime.now().difference(startTime);
      _performanceMonitor.recordOperation('get_ui_image', duration);
    }
  }

  /// 🚀 缓存UI图像
  Future<void> cacheUiImage(String key, ui.Image image) async {
    final startTime = DateTime.now();
    
    try {
      // 检查缓存大小，必要时清理
      if (_imageCache.length >= _maxCacheSize) {
        _evictLeastRecentlyUsed();
      }
      
      _imageCache[key] = image;
      _updateAccessStats(key);
      
      AppLogger.debug(
        '缓存UI图像',
        tag: 'OptimizedImageCache',
        data: {
          'key': key,
          'cacheSize': _imageCache.length,
          'imageSize': '${image.width}x${image.height}',
        },
      );
      
    } finally {
      final duration = DateTime.now().difference(startTime);
      _performanceMonitor.recordOperation('cache_ui_image', duration);
    }
  }

  /// 🚀 获取二进制图像数据
  Future<Uint8List?> getBinaryImage(String key) async {
    final startTime = DateTime.now();
    
    try {
      _updateAccessStats(key);
      
      if (_binaryCache.containsKey(key)) {
        _performanceMonitor.recordCacheOperation('binary_image', true, null);
        return _binaryCache[key];
      }
      
      if (_pendingBinaryRequests.containsKey(key)) {
        return await _pendingBinaryRequests[key];
      }
      
      _performanceMonitor.recordCacheOperation('binary_image', false, null);
      return null;
      
    } finally {
      final duration = DateTime.now().difference(startTime);
      _performanceMonitor.recordOperation('get_binary_image', duration);
    }
  }

  /// 🚀 缓存二进制图像数据
  Future<void> cacheBinaryImage(String key, Uint8List data) async {
    final startTime = DateTime.now();
    
    try {
      if (_binaryCache.length >= _maxBinarySize) {
        _evictLeastRecentlyUsedBinary();
      }
      
      _binaryCache[key] = data;
      _updateAccessStats(key);
      
    } finally {
      final duration = DateTime.now().difference(startTime);
      _performanceMonitor.recordOperation('cache_binary_image', duration);
    }
  }

  /// 🚀 批量缓存图像（减少I/O操作）
  void batchCacheImages(List<String> keys) {
    for (final key in keys) {
      _requestQueue.add(_CacheRequest(key: key, type: _RequestType.preload));
    }
    
    _scheduleBatchProcessing();
  }

  /// 🚀 智能预加载热点图像
  void preloadHotImages() {
    final hotImages = _getHotImages();
    
    AppLogger.info(
      '开始预加载热点图像',
      tag: 'OptimizedImageCache',
      data: {
        'hotImageCount': hotImages.length,
        'threshold': _hotThreshold,
      },
    );
    
    batchCacheImages(hotImages);
  }

  /// 🚀 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    final totalMemory = _calculateMemoryUsage();
    
    return {
      'uiImageCount': _imageCache.length,
      'binaryImageCount': _binaryCache.length,
      'totalMemoryMB': (totalMemory / 1024 / 1024).toStringAsFixed(2),
      'hotImageCount': _getHotImages().length,
      'pendingRequests': _pendingImageRequests.length + _pendingBinaryRequests.length,
      'queueSize': _requestQueue.length,
    };
  }

  /// 🚀 清理过期缓存
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _lastAccess.forEach((key, lastAccess) {
      if (now.difference(lastAccess).inMinutes > 30) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _imageCache.remove(key);
      _binaryCache.remove(key);
      _accessCount.remove(key);
      _lastAccess.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      AppLogger.info(
        '清理过期缓存',
        tag: 'OptimizedImageCache',
        data: {
          'expiredCount': expiredKeys.length,
          'remainingImages': _imageCache.length,
        },
      );
    }
  }

  /// 更新访问统计
  void _updateAccessStats(String key) {
    _accessCount[key] = (_accessCount[key] ?? 0) + 1;
    _lastAccess[key] = DateTime.now();
  }

  /// 获取热点图像列表
  List<String> _getHotImages() {
    return _accessCount.entries
        .where((entry) => entry.value >= _hotThreshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// 驱逐最近最少使用的UI图像
  void _evictLeastRecentlyUsed() {
    if (_lastAccess.isEmpty) return;
    
    final oldestKey = _lastAccess.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
    
    _imageCache.remove(oldestKey);
    _accessCount.remove(oldestKey);
    _lastAccess.remove(oldestKey);
  }

  /// 驱逐最近最少使用的二进制图像
  void _evictLeastRecentlyUsedBinary() {
    if (_lastAccess.isEmpty) return;
    
    final oldestKey = _lastAccess.entries
        .where((entry) => _binaryCache.containsKey(entry.key))
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;
    
    _binaryCache.remove(oldestKey);
  }

  /// 调度批量处理
  void _scheduleBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = Timer(_batchDelay, _processBatchRequests);
  }

  /// 处理批量请求
  void _processBatchRequests() {
    if (_requestQueue.isEmpty) return;
    
    final batch = <_CacheRequest>[];
    while (_requestQueue.isNotEmpty && batch.length < 10) {
      batch.add(_requestQueue.removeFirst());
    }
    
    AppLogger.debug(
      '处理批量缓存请求',
      tag: 'OptimizedImageCache',
      data: {
        'batchSize': batch.length,
        'remainingQueue': _requestQueue.length,
      },
    );
    
    // 这里可以实现具体的批量加载逻辑
    // 目前只是记录，实际实现需要根据具体需求
  }

  /// 计算内存使用量
  int _calculateMemoryUsage() {
    int total = 0;
    
    // UI图像内存使用（估算）
    for (final image in _imageCache.values) {
      total += image.width * image.height * 4; // RGBA
    }
    
    // 二进制数据内存使用
    for (final data in _binaryCache.values) {
      total += data.length;
    }
    
    return total;
  }

  /// 释放资源
  void dispose() {
    _batchTimer?.cancel();
    _imageCache.clear();
    _binaryCache.clear();
    _accessCount.clear();
    _lastAccess.clear();
    _pendingImageRequests.clear();
    _pendingBinaryRequests.clear();
    _requestQueue.clear();
  }
}

/// 缓存请求类型
enum _RequestType {
  preload,
  demand,
}

/// 缓存请求
class _CacheRequest {
  final String key;
  final _RequestType type;
  final DateTime timestamp;
  
  _CacheRequest({
    required this.key,
    required this.type,
  }) : timestamp = DateTime.now();
} 