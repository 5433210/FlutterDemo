import 'dart:ui' as ui;

import '../../../infrastructure/logging/edit_page_logger_extension.dart';

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
      EditPageLogger.performanceWarning(
        '尝试缓存空键',
        data: {'operation': 'put', 'key': 'empty'},
      );
      return;
    }

    if (image.width <= 0 || image.height <= 0) {
      EditPageLogger.performanceWarning(
        '尝试缓存无效图像',
        data: {
          'key': key,
          'width': image.width,
          'height': image.height,
          'operation': 'put',
        },
      );
      return;
    }

    _cache[key] = image;
    _accessCount[key] = 0;

    EditPageLogger.performanceInfo(
      '图像缓存添加成功',
      data: {
        'key': key,
        'imageWidth': image.width,
        'imageHeight': image.height,
        'cacheSize': _cache.length,
        'operation': 'put',
      },
    );
  }

  /// 检查缓存中是否包含指定的键
  static bool contains(String key) {
    bool result = _cache.containsKey(key);
    EditPageLogger.performanceInfo(
      '缓存键检查',
      data: {
        'key': key,
        'exists': result,
        'operation': 'contains',
        'cacheSize': _cache.length,
      },
    );
    return result;
  }

  /// 获取缓存中的图像
  static ui.Image? get(String key) {
    ui.Image? image = _cache[key];

    if (image != null) {
      // 更新访问计数
      _accessCount[key] = (_accessCount[key] ?? 0) + 1;

      EditPageLogger.performanceInfo(
        '图像缓存命中',
        data: {
          'key': key,
          'imageWidth': image.width,
          'imageHeight': image.height,
          'accessCount': _accessCount[key],
          'operation': 'get',
          'cacheHit': true,
        },
      );
    } else {
      EditPageLogger.performanceWarning(
        '图像缓存未命中',
        data: {
          'key': key,
          'operation': 'get',
          'cacheHit': false,
          'availableKeys': _cache.keys.toList(),
          'cacheSize': _cache.length,
        },
      );
    }

    return image;
  }

  /// 清除缓存
  static void clear() {
    int count = _cache.length;
    _cache.clear();
    _accessCount.clear();
    EditPageLogger.performanceInfo(
      '图像缓存清除完成',
      data: {
        'clearedCount': count,
        'operation': 'clear',
      },
    );
  }

  /// 从缓存中移除特定项
  static void remove(String key) {
    bool existed = _cache.containsKey(key);
    _cache.remove(key);
    _accessCount.remove(key);
    if (existed) {
      EditPageLogger.performanceInfo(
        '移除图像缓存项',
        data: {
          'key': key,
          'existed': existed,
          'operation': 'remove',
          'newCacheSize': _cache.length,
        },
      );
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
        buffer.writeln(
            '    * $key (${image.width}x${image.height}, 访问次数: $accessCount)');
      });
    }

    return buffer.toString();
  }

  /// 尝试根据前缀查找缓存项
  static ui.Image? getByPrefix(String prefix) {
    if (prefix.isEmpty) return null;

    for (String key in _cache.keys) {
      if (key.startsWith(prefix)) {
        EditPageLogger.performanceInfo(
          '前缀匹配图像缓存命中',
          data: {
            'matchedKey': key,
            'prefix': prefix,
            'operation': 'getByPrefix',
            'cacheHit': true,
          },
        );
        return _cache[key];
      }
    }

    EditPageLogger.performanceWarning(
      '前缀匹配图像缓存未命中',
      data: {
        'prefix': prefix,
        'operation': 'getByPrefix',
        'cacheHit': false,
        'availableKeys': _cache.keys.toList(),
        'cacheSize': _cache.length,
      },
    );
    return null;
  }
}
