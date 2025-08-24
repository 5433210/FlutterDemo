import 'dart:ui' as ui;

import '../../logging/logger.dart';
import '../interfaces/i_cache.dart';

/// UI图像缓存实现
class UIImageCache implements ICache<String, ui.Image> {
  final Map<String, ui.Image> _cache = {};

  @override
  Future<void> clear() async {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    AppLogger.debug('UI图像缓存已清除');
  }

  @override
  Future<bool> containsKey(String key) async {
    return _cache.containsKey(key);
  }

  @override
  Future<ui.Image?> get(String key) async {
    return _cache[key];
  }

  @override
  Future<void> invalidate(String key) async {
    // 实现与remove相同的逻辑
    await remove(key);
  }

  @override
  Future<void> put(String key, ui.Image value) async {
    // 如果已有同样的键，先释放旧图像
    if (_cache.containsKey(key)) {
      _cache[key]!.dispose();
    }
    _cache[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    if (_cache.containsKey(key)) {
      _cache[key]!.dispose();
      _cache.remove(key);
    }
  }

  @override
  Future<void> evict(String key) async {
    // evict与remove行为相同
    await remove(key);
  }

  @override
  Future<int> size() async {
    return _cache.length;
  }
}
