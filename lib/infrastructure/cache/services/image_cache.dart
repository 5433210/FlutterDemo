import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../interfaces/i_cache.dart';
import '../../logging/logger.dart';

/// 图片缓存
class ImageCache implements ICache<String, Uint8List> {
  /// 内存缓存
  final Map<String, Uint8List> _memoryCache = {};

  /// 缓存目录
  late final Directory _cacheDir;

  /// 最大内存缓存大小（默认 100MB）
  final int maxMemoryCacheSize;

  /// 当前内存缓存大小
  int _currentMemoryCacheSize = 0;

  /// 构造函数
  ImageCache({this.maxMemoryCacheSize = 100 * 1024 * 1024}) {
    _initCacheDir();
  }

  /// 初始化缓存目录
  Future<void> _initCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(path.join(appDir.path, 'cache', 'images'));
    
    AppLogger.info('ImageCache初始化缓存目录', 
        tag: 'PathTrace', 
        data: {
          'appDocumentsDir': appDir.path,
          'cacheDir': _cacheDir.path,
          'service': 'ImageCache',
          'pathProvider': 'getApplicationDocumentsDirectory'
        });
    
    if (!await _cacheDir.exists()) {
      await _cacheDir.create(recursive: true);
      AppLogger.info('ImageCache创建缓存目录', 
          tag: 'PathTrace', 
          data: {
            'createdPath': _cacheDir.path
          });
    }
  }

  @override
  Future<Uint8List?> get(String key) async {
    // 先从内存缓存获取
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // 从文件缓存获取
    final file = File(path.join(_cacheDir.path, key));
    if (await file.exists()) {
      final data = await file.readAsBytes();
      // 如果内存缓存未满，则加入内存缓存
      if (_currentMemoryCacheSize + data.length <= maxMemoryCacheSize) {
        _memoryCache[key] = data;
        _currentMemoryCacheSize += data.length;
      }
      return data;
    }

    return null;
  }

  @override
  Future<void> put(String key, Uint8List value) async {
    // 写入文件缓存
    final file = File(path.join(_cacheDir.path, key));
    await file.writeAsBytes(value);

    // 如果加入内存缓存后会超出限制，先清理一些旧的缓存
    while (_currentMemoryCacheSize + value.length > maxMemoryCacheSize &&
        _memoryCache.isNotEmpty) {
      final oldestKey = _memoryCache.keys.first;
      _currentMemoryCacheSize -= _memoryCache[oldestKey]!.length;
      _memoryCache.remove(oldestKey);
    }

    // 如果还有空间，加入内存缓存
    if (_currentMemoryCacheSize + value.length <= maxMemoryCacheSize) {
      _memoryCache[key] = value;
      _currentMemoryCacheSize += value.length;
    }
  }

  @override
  Future<void> invalidate(String key) async {
    // 从内存缓存移除
    if (_memoryCache.containsKey(key)) {
      _currentMemoryCacheSize -= _memoryCache[key]!.length;
      _memoryCache.remove(key);
    }

    // 从文件缓存移除
    final file = File(path.join(_cacheDir.path, key));
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clear() async {
    // 清空内存缓存
    _memoryCache.clear();
    _currentMemoryCacheSize = 0;

    // 清空文件缓存
    if (await _cacheDir.exists()) {
      await _cacheDir.delete(recursive: true);
      await _cacheDir.create(recursive: true);
    }
  }

  @override
  Future<int> size() async {
    int totalSize = _currentMemoryCacheSize;

    // 计算文件缓存大小
    if (await _cacheDir.exists()) {
      await for (final file in _cacheDir.list(recursive: true)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    }

    return totalSize;
  }

  @override
  Future<bool> containsKey(String key) async {
    // 检查内存缓存
    if (_memoryCache.containsKey(key)) {
      return true;
    }

    // 检查文件缓存
    final file = File(path.join(_cacheDir.path, key));
    return await file.exists();
  }

  @override
  Future<void> remove(String key) async {
    // 实现与invalidate相同的功能，以满足接口要求
    await invalidate(key);
  }

  @override
  Future<void> evict(String key) async {
    // evict与remove行为相同
    await remove(key);
  }
}
