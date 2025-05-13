import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// 全局图像缓存 - 增强版，统一管理UI图像资源
class GlobalImageCache {
  // 图像缓存，使用静态Map便于全局访问
  static final Map<String, ui.Image> _cache = {};
  
  // 缓存访问记录
  static final Map<String, int> _accessCount = {};
  
  // 调试模式
  static bool debugMode = true;

  /// 添加图像到缓存
  static void put(String key, ui.Image image) {
    if (key.isEmpty) {
      if (debugMode) debugPrint('❌ GlobalImageCache: 尝试缓存空键');
      return;
    }
    
    if (image.width <= 0 || image.height <= 0) {
      if (debugMode) debugPrint('❌ GlobalImageCache: 尝试缓存无效图像: $key');
      return;
    }
    
    _cache[key] = image;
    _accessCount[key] = 0;
    
    if (debugMode) {
      debugPrint('✅ GlobalImageCache: 成功缓存图像: $key (${image.width}x${image.height})');
      debugPrint('ℹ️ GlobalImageCache: 当前缓存大小: ${_cache.length} 项');
    }
  }

  /// 检查缓存中是否包含指定的键
  static bool contains(String key) {
    bool result = _cache.containsKey(key);
    if (debugMode) {
      if (result) {
        debugPrint('✅ GlobalImageCache: 缓存中存在键: $key');
      } else {
        debugPrint('⚠️ GlobalImageCache: 缓存中不存在键: $key');
      }
    }
    return result;
  }

  /// 获取缓存中的图像
  static ui.Image? get(String key) {
    ui.Image? image = _cache[key];
    
    if (image != null) {
      // 更新访问计数
      _accessCount[key] = (_accessCount[key] ?? 0) + 1;
      
      if (debugMode) {
        debugPrint('✅ GlobalImageCache: 成功获取图像: $key (${image.width}x${image.height})');
        debugPrint('ℹ️ GlobalImageCache: 访问计数: ${_accessCount[key]}');
      }
    } else if (debugMode) {
      debugPrint('❌ GlobalImageCache: 未找到图像: $key');
      debugPrint('ℹ️ GlobalImageCache: 当前缓存键列表:');
      _cache.keys.toList().forEach((k) => debugPrint('   - $k'));
    }
    
    return image;
  }

  /// 清除缓存
  static void clear() {
    int count = _cache.length;
    _cache.clear();
    _accessCount.clear();
    if (debugMode) debugPrint('ℹ️ GlobalImageCache: 清除了 $count 项缓存');
  }

  /// 从缓存中移除特定项
  static void remove(String key) {
    bool existed = _cache.containsKey(key);
    _cache.remove(key);
    _accessCount.remove(key);
    if (debugMode && existed) {
      debugPrint('ℹ️ GlobalImageCache: 移除缓存项: $key');
    }
  }
  
  /// 获取缓存大小
  static int get size => _cache.length;
  
  /// 获取所有缓存键
  static List<String> get keys => _cache.keys.toList();
  
  /// 获取缓存信息摘要
  static String getSummary() {
    StringBuffer buffer = StringBuffer();
    buffer.writeln('ℹ️ GlobalImageCache 摘要:');
    buffer.writeln('  - 缓存项数: ${_cache.length}');
    
    if (_cache.isNotEmpty) {
      buffer.writeln('  - 缓存项列表:');
      _cache.forEach((key, image) {
        int accessCount = _accessCount[key] ?? 0;
        buffer.writeln('    * $key (${image.width}x${image.height}, 访问次数: $accessCount)');
      });
    }
    
    return buffer.toString();
  }
  
  /// 尝试根据前缀查找缓存项
  static ui.Image? getByPrefix(String prefix) {
    if (prefix.isEmpty) return null;
    
    for (String key in _cache.keys) {
      if (key.startsWith(prefix)) {
        if (debugMode) {
          debugPrint('✅ GlobalImageCache: 根据前缀找到图像: $key (前缀: $prefix)');
        }
        return _cache[key];
      }
    }
    
    if (debugMode) {
      debugPrint('❌ GlobalImageCache: 根据前缀未找到图像: $prefix');
    }
    return null;
  }
}
