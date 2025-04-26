import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../storage/storage_interface.dart';

/// 集字图片缓存服务
class CharacterImageCacheService {
  final IStorage _storage;

  CharacterImageCacheService({
    required IStorage storage,
  }) : _storage = storage;

  /// 保存缓存图片
  Future<void> cacheImage(String characterId, String type,
      Map<String, dynamic> transform, Uint8List imageData) async {
    final cacheKey = _generateCacheKey(characterId, type, transform);
    final cachePath = _getCachePath(cacheKey);

    // 确保缓存目录存在
    final directory = path.dirname(cachePath);
    await _storage.ensureDirectoryExists(directory);

    // 使用IStorage写入文件
    await _storage.writeFile(cachePath, imageData);
  }

  /// 清理过期缓存
  Future<void> cleanExpiredCache() async {
    final cacheDirPath =
        path.join(_storage.getAppDataPath(), 'cache', 'characters');
    if (!await _storage.directoryExists(cacheDirPath)) {
      return;
    }

    final now = DateTime.now();
    final files = await _storage.listDirectoryFiles(cacheDirPath);

    for (final filePath in files) {
      try {
        final modifiedTime = await _storage.getFileModifiedTime(filePath);
        final cacheAge = now.difference(modifiedTime);

        // 删除超过7天的缓存
        if (cacheAge.inDays > 7) {
          await _storage.deleteFile(filePath);
        }
      } catch (e) {
        // 记录错误但继续处理其他文件
        debugPrint('清理缓存文件失败: $filePath, 错误: $e');
      }
    }
  }

  /// 清除所有缓存
  Future<void> clearAllCache() async {
    try {
      debugPrint('开始清除所有字符图像缓存');
      final cacheDirPath =
          path.join(_storage.getAppDataPath(), 'cache', 'characters');

      // 检查缓存目录是否存在
      if (!await _storage.directoryExists(cacheDirPath)) {
        debugPrint('缓存目录不存在，无需清除');
        return;
      }

      // 获取所有缓存文件
      final files = await _storage.listDirectoryFiles(cacheDirPath);
      debugPrint('找到 ${files.length} 个缓存文件');

      // 删除所有缓存文件
      int deletedCount = 0;
      for (final filePath in files) {
        try {
          await _storage.deleteFile(filePath);
          deletedCount++;
        } catch (e) {
          debugPrint('删除缓存文件失败: $filePath, 错误: $e');
        }
      }

      debugPrint('成功删除 $deletedCount 个缓存文件');
    } catch (e) {
      debugPrint('清除所有缓存失败: $e');
    }
  }

  /// 获取缓存图片
  Future<Uint8List?> getCachedImage(
      String characterId, String type, Map<String, dynamic> transform) async {
    final cacheKey = _generateCacheKey(characterId, type, transform);
    final cachePath = _getCachePath(cacheKey);

    // 使用IStorage检查文件是否存在
    if (await _storage.fileExists(cachePath)) {
      // 检查缓存是否过期
      final modifiedTime = await _storage.getFileModifiedTime(cachePath);
      final now = DateTime.now();
      final cacheAge = now.difference(modifiedTime);

      // 缓存有效期为7天
      if (cacheAge.inDays < 7) {
        // 使用IStorage读取文件内容
        final data = await _storage.readFile(cachePath);
        return Uint8List.fromList(data);
      }
    }

    return null;
  }

  /// 生成缓存键
  String _generateCacheKey(
      String characterId, String type, Map<String, dynamic> transform) {
    // 将变换参数序列化为字符串，并计算其哈希值
    // 这确保了即使是相同的CharacterID，不同的变换参数也会生成不同的缓存键
    final transformString = jsonEncode(transform);
    final transformHash = md5.convert(utf8.encode(transformString)).toString();

    // 缓存键包含字符ID、类型和变换参数的哈希值
    return '$characterId-$type-$transformHash';
  }

  /// 获取缓存路径
  String _getCachePath(String cacheKey) {
    // 使用缓存键创建唯一的文件路径
    return path.join(
        _storage.getAppDataPath(), 'cache', 'characters', '$cacheKey.png');
  }
}
