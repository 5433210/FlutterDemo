import 'dart:ui' as ui;

/// 全局图像缓存 - 统一管理UI图像资源
class GlobalImageCache {
  // 图像缓存，使用静态Map便于全局访问
  static final Map<String, ui.Image> _cache = {};

  /// 添加图像到缓存
  static void put(String key, ui.Image image) {
    _cache[key] = image;
  }

  /// 检查缓存中是否包含指定的键
  static bool contains(String key) {
    return _cache.containsKey(key);
  }

  /// 获取缓存中的图像
  static ui.Image? get(String key) {
    return _cache[key];
  }

  /// 清除缓存
  static void clear() {
    _cache.clear();
  }

  /// 从缓存中移除特定项
  static void remove(String key) {
    _cache.remove(key);
  }
  
  /// 获取缓存大小
  static int get size => _cache.length;
}
