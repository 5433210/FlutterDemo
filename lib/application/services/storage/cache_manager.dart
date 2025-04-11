import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CacheManager {
  // 内存缓存，用于快速访问
  late final LruCache<String, Uint8List> _memoryCache;

  // 缓存目录
  late String _cachePath;

  // 是否已初始化
  bool _initialized = false;

  // 缓存大小上限（字节）
  final int _maxCacheSize = 100 * 1024 * 1024; // 100MB

  // 当前缓存大小
  int _currentCacheSize = 0;

  CacheManager() {
    _memoryCache = LruCache<String, Uint8List>(capacity: 20); // 最多20个项目
    _init();
  }

  // 清空所有缓存
  Future<void> clear() async {
    await _ensureInitialized();

    // 清空内存缓存
    _memoryCache.clear();

    // 清空文件缓存
    try {
      final dir = Directory(_cachePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create();
      }

      // 重置缓存大小
      _currentCacheSize = 0;
    } catch (e) {
      print('清空缓存失败: $e');
    }
  }

  // 获取缓存项
  Future<Uint8List?> get(String key) async {
    await _ensureInitialized();

    // 先尝试从内存缓存获取
    final memCached = _memoryCache.get(key);
    if (memCached != null) {
      return memCached;
    }

    // 从文件缓存获取
    try {
      final hashedKey = _hashKey(key);
      final cacheFile = File(path.join(_cachePath, hashedKey));

      if (await cacheFile.exists()) {
        final data = await cacheFile.readAsBytes();

        // 更新内存缓存
        _memoryCache.put(key, data);

        return data;
      }
    } catch (e) {
      print('从缓存获取数据失败: $e');
    }

    return null;
  }

  // 获取当前缓存大小（MB）
  Future<double> getCacheSizeMB() async {
    await _ensureInitialized();
    return _currentCacheSize / (1024 * 1024);
  }

  // 移除缓存项
  Future<void> invalidate(String key) async {
    try {
      // 移除内存缓存
      _memoryCache.remove(key);

      // 记录缓存失效
      print('缓存条目已失效: $key');

      // 从文件缓存移除
      final hashedKey = _hashKey(key);
      final cacheFile = File(path.join(_cachePath, hashedKey));

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        print('磁盘缓存条目已删除: $key, 路径: ${cacheFile.path}');
      }
    } catch (e) {
      print('使缓存条目失效时出错: $e, 键: $key');
    }
  }

  // 存储缓存项
  Future<void> put(String key, Uint8List data) async {
    await _ensureInitialized();

    // 更新内存缓存
    _memoryCache.put(key, data);

    // 更新文件缓存
    try {
      final hashedKey = _hashKey(key);
      final cacheFile = File(path.join(_cachePath, hashedKey));

      await cacheFile.writeAsBytes(data);

      // 更新缓存大小
      _currentCacheSize += data.length;

      // 检查是否需要清理缓存
      if (_currentCacheSize > _maxCacheSize) {
        await _trimCache();
      }
    } catch (e) {
      print('缓存数据失败: $e');
    }
  }

  // 计算当前缓存大小
  Future<void> _calculateCacheSize() async {
    _currentCacheSize = 0;
    final dir = Directory(_cachePath);
    if (await dir.exists()) {
      await for (final file in dir.list(recursive: true, followLinks: false)) {
        if (file is File) {
          final stat = await file.stat();
          _currentCacheSize += stat.size;
        }
      }
    }
  }

  // 确保初始化完成
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }

  // 对缓存键进行哈希处理，避免无效的文件名
  String _hashKey(String key) {
    final bytes = utf8.encode(key);
    final digest = crypto.md5.convert(bytes);
    return digest.toString();
  }

  // 异步初始化
  Future<void> _init() async {
    if (_initialized) return;

    try {
      final cacheDir = await getTemporaryDirectory();
      _cachePath = path.join(cacheDir.path, 'character_cache');

      // 确保缓存目录存在
      final dir = Directory(_cachePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 计算当前缓存大小
      await _calculateCacheSize();

      _initialized = true;
    } catch (e) {
      print('初始化缓存管理器失败: $e');
    }
  }

  // 裁剪缓存，删除最旧的文件直到大小合适
  Future<void> _trimCache() async {
    try {
      final dir = Directory(_cachePath);
      if (!await dir.exists()) return;

      // 获取所有缓存文件并按修改时间排序
      final files = await dir.list().where((entity) => entity is File).toList();

      // 先收集文件信息再排序
      final fileInfos = <MapEntry<File, FileStat>>[];
      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          fileInfos.add(MapEntry(entity, stat));
        }
      }

      // 按修改时间排序
      fileInfos.sort((a, b) => a.value.modified.compareTo(b.value.modified));

      // 删除文件直到缓存大小在限制范围内
      for (final entity in files) {
        if (_currentCacheSize <= _maxCacheSize * 0.8) {
          // 如果缓存大小已减少到上限的80%，则停止删除
          break;
        }

        if (entity is File) {
          final stat = await entity.stat();
          await entity.delete();
          _currentCacheSize -= stat.size;
        }
      }
    } catch (e) {
      print('裁剪缓存失败: $e');
    }
  }
}

// LRU缓存辅助类
class LruCache<K, V> {
  final int capacity;
  final Map<K, V> _cache = {};
  final List<K> _keys = [];

  LruCache({required this.capacity});

  // 获取所有键
  Set<K> get keys => _cache.keys.toSet();

  // 获取缓存大小
  int get size => _cache.length;

  // 清空缓存
  void clear() {
    _cache.clear();
    _keys.clear();
  }

  // 获取缓存项
  V? get(K key) {
    if (!_cache.containsKey(key)) return null;

    // 更新访问顺序
    _keys.remove(key);
    _keys.add(key);

    return _cache[key];
  }

  // 存储缓存项
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _keys.remove(key);
    } else if (_keys.length >= capacity) {
      // 移除最近最少使用的项
      final oldestKey = _keys.removeAt(0);
      _cache.remove(oldestKey);
    }

    _cache[key] = value;
    _keys.add(key);
  }

  // 移除缓存项
  void remove(K key) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
      _keys.remove(key);
    }
  }
}
