import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../interfaces/i_cache.dart';

/// 值编码器函数类型
typedef ValueEncoder<V> = Future<List<int>> Function(V value);

/// 值解码器函数类型
typedef ValueDecoder<V> = Future<V> Function(List<int> data);

/// 键哈希器函数类型
typedef KeyHasher<K> = String Function(K key);

/// 基于文件系统的磁盘缓存实现
class DiskCache<K, V> implements ICache<K, V> {
  /// 缓存目录路径
  final String _cachePath;
  
  /// 缓存最大大小（字节）
  final int _maxSize;
  
  /// 缓存项最大存活时间
  final Duration _maxAge;
  
  /// 值编码器
  final ValueEncoder<V> _encoder;
  
  /// 值解码器
  final ValueDecoder<V> _decoder;
  
  /// 键哈希器
  final KeyHasher<K> _keyHasher;
  
  /// 当前缓存大小
  int _currentSize = 0;
  
  /// 是否已初始化
  bool _initialized = false;
  
  /// 构造函数
  /// 
  /// [cachePath] 缓存目录路径
  /// [maxSize] 缓存最大大小（字节）
  /// [maxAge] 缓存项最大存活时间
  /// [encoder] 值编码器函数
  /// [decoder] 值解码器函数
  /// [keyHasher] 键哈希器函数
  DiskCache({
    required String cachePath,
    required int maxSize,
    required Duration maxAge,
    required ValueEncoder<V> encoder,
    required ValueDecoder<V> decoder,
    required KeyHasher<K> keyHasher,
  }) : _cachePath = cachePath,
       _maxSize = maxSize,
       _maxAge = maxAge,
       _encoder = encoder,
       _decoder = decoder,
       _keyHasher = keyHasher {
    _init();
  }
  
  /// 初始化缓存
  Future<void> _init() async {
    if (_initialized) return;
    
    try {
      // 确保缓存目录存在
      final dir = Directory(_cachePath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // 计算当前缓存大小
      await _calculateCacheSize();
      
      _initialized = true;
    } catch (e) {
      debugPrint('初始化磁盘缓存失败: $e');
    }
  }
  
  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }
  
  @override
  Future<V?> get(K key) async {
    await _ensureInitialized();
    
    final filePath = _getFilePath(key);
    final file = File(filePath);
    
    if (await file.exists()) {
      try {
        // 检查是否过期
        final stat = await file.stat();
        final now = DateTime.now();
        final fileAge = now.difference(stat.modified);
        
        if (fileAge > _maxAge) {
          // 缓存已过期，删除文件
          await file.delete();
          return null;
        }
        
        // 读取并解码数据
        final bytes = await file.readAsBytes();
        return await _decoder(bytes);
      } catch (e) {
        debugPrint('读取缓存文件失败: $e');
        return null;
      }
    }
    
    return null;
  }
  
  @override
  Future<void> put(K key, V value) async {
    await _ensureInitialized();
    
    final filePath = _getFilePath(key);
    final file = File(filePath);
    
    try {
      // 确保目录存在
      final dir = Directory(path.dirname(filePath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      
      // 编码并写入数据
      final bytes = await _encoder(value);
      await file.writeAsBytes(bytes);
      
      // 更新缓存大小
      final fileSize = bytes.length;
      _currentSize += fileSize;
      
      // 检查缓存大小并清理
      if (_currentSize > _maxSize) {
        await _trimCacheIfNeeded();
      }
    } catch (e) {
      debugPrint('写入缓存文件失败: $e');
    }
  }
  
  @override
  Future<void> invalidate(K key) async {
    await _ensureInitialized();
    
    final filePath = _getFilePath(key);
    final file = File(filePath);
    
    if (await file.exists()) {
      try {
        final fileSize = await file.length();
        await file.delete();
        _currentSize -= fileSize;
      } catch (e) {
        debugPrint('删除缓存文件失败: $e');
      }
    }
  }
  
  @override
  Future<void> clear() async {
    await _ensureInitialized();
    
    try {
      final dir = Directory(_cachePath);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
      
      _currentSize = 0;
    } catch (e) {
      debugPrint('清空缓存目录失败: $e');
    }
  }
  
  @override
  Future<int> size() async {
    await _ensureInitialized();
    return _currentSize;
  }
  
  @override
  Future<bool> containsKey(K key) async {
    await _ensureInitialized();
    
    final filePath = _getFilePath(key);
    final file = File(filePath);
    
    return await file.exists();
  }
  
  /// 获取缓存文件路径
  String _getFilePath(K key) {
    final hashedKey = _keyHasher(key);
    return path.join(_cachePath, hashedKey);
  }
  
  /// 计算当前缓存大小
  Future<void> _calculateCacheSize() async {
    _currentSize = 0;
    final dir = Directory(_cachePath);
    
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          _currentSize += await entity.length();
        }
      }
    }
  }
  
  /// 清理过大的缓存
  Future<void> _trimCacheIfNeeded() async {
    if (_currentSize <= _maxSize) return;
    
    try {
      final dir = Directory(_cachePath);
      if (!await dir.exists()) return;
      
      // 获取所有缓存文件及其修改时间
      final files = <File, DateTime>{};
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          files[entity] = stat.modified;
        }
      }
      
      // 按修改时间排序
      final sortedFiles = files.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      // 删除最旧的文件，直到缓存大小合适
      int deletedSize = 0;
      for (final entry in sortedFiles) {
        if (_currentSize - deletedSize <= _maxSize * 0.8) {
          // 已经删除足够多，保留80%的空间
          break;
        }
        
        final file = entry.key;
        final fileSize = await file.length();
        await file.delete();
        deletedSize += fileSize;
      }
      
      // 更新当前缓存大小
      _currentSize -= deletedSize;
    } catch (e) {
      debugPrint('清理缓存失败: $e');
    }
  }
}
