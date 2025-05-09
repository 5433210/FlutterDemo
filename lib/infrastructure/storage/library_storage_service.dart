import 'dart:io';
import 'dart:typed_data';

import '../../../infrastructure/logging/logger.dart';
import '../cache/services/image_cache_service.dart';
import 'library_storage_interface.dart';

/// 图库存储服务
class LibraryStorageService {
  final ILibraryStorage _storage;
  final ImageCacheService _imageCache;

  LibraryStorageService({
    required ILibraryStorage storage,
    required ImageCacheService imageCache,
  })  : _storage = storage,
        _imageCache = imageCache;

  /// 保存图库项目
  Future<String> saveLibraryItem(
    String itemId,
    Uint8List bytes,
    String extension,
  ) async {
    try {
      // 保存原始文件
      final filePath = await _storage.saveLibraryItem(itemId, bytes, extension);

      // 缓存二进制数据
      await _imageCache.cacheBinaryImage(itemId, bytes);

      AppLogger.debug(
        '已保存图库项目',
        data: {
          'itemId': itemId,
          'extension': extension,
          'filePath': filePath,
          'size': bytes.length,
        },
      );

      return filePath;
    } catch (e, stackTrace) {
      AppLogger.error(
        '保存图库项目失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'itemId': itemId,
          'extension': extension,
          'size': bytes.length,
        },
      );
      rethrow;
    }
  }

  /// 保存缩略图
  Future<String> saveThumbnail(String itemId, Uint8List bytes) async {
    try {
      // 保存缩略图文件
      final thumbPath = await _storage.saveThumbnail(itemId, bytes);

      // 缓存缩略图
      final cacheKey = _imageCache.generateCacheKey(
        itemId,
        'thumbnail',
        {'type': 'thumbnail'},
      );
      await _imageCache.cacheBinaryImage(cacheKey, bytes);

      AppLogger.debug(
        '已保存缩略图',
        data: {
          'itemId': itemId,
          'thumbPath': thumbPath,
          'size': bytes.length,
        },
      );

      return thumbPath;
    } catch (e, stackTrace) {
      AppLogger.error(
        '保存缩略图失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'itemId': itemId,
          'size': bytes.length,
        },
      );
      rethrow;
    }
  }

  /// 获取图库项目
  Future<Uint8List?> getLibraryItem(String itemId, String extension) async {
    try {
      // 尝试从缓存获取
      final cachedData = await _imageCache.getBinaryImage(itemId);
      if (cachedData != null) {
        return cachedData;
      }

      // 从存储获取
      final filePath = await _storage.getLibraryItemPath(itemId, extension);
      if (!await _storage.fileExists(filePath)) {
        return null;
      }

      final bytes = await _storage.readFile(filePath);
      final uint8Bytes = Uint8List.fromList(bytes);

      // 缓存数据
      await _imageCache.cacheBinaryImage(itemId, uint8Bytes);

      return uint8Bytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        '获取图库项目失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'itemId': itemId,
          'extension': extension,
        },
      );
      rethrow;
    }
  }

  /// 获取缩略图
  Future<Uint8List?> getThumbnail(String itemId) async {
    try {
      // 尝试从缓存获取
      final cacheKey = _imageCache.generateCacheKey(
        itemId,
        'thumbnail',
        {'type': 'thumbnail'},
      );
      final cachedData = await _imageCache.getBinaryImage(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      // 从存储获取
      final thumbPath = await _storage.getThumbnailPath(itemId);
      if (!await _storage.fileExists(thumbPath)) {
        return null;
      }

      final bytes = await _storage.readFile(thumbPath);
      final uint8Bytes = Uint8List.fromList(bytes);

      // 缓存数据
      await _imageCache.cacheBinaryImage(cacheKey, uint8Bytes);

      return uint8Bytes;
    } catch (e, stackTrace) {
      AppLogger.error(
        '获取缩略图失败',
        error: e,
        stackTrace: stackTrace,
        data: {'itemId': itemId},
      );
      rethrow;
    }
  }

  /// 删除图库项目
  Future<void> deleteLibraryItem(String itemId) async {
    try {
      // 删除存储文件
      await _storage.deleteLibraryItem(itemId);

      // 清除缓存
      _imageCache.evictImage(itemId);

      AppLogger.debug(
        '已删除图库项目',
        data: {'itemId': itemId},
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '删除图库项目失败',
        error: e,
        stackTrace: stackTrace,
        data: {'itemId': itemId},
      );
      rethrow;
    }
  }

  /// 获取图库项目信息
  Future<FileInfo> getLibraryItemInfo(String itemId, String extension) async {
    try {
      return await _storage.getLibraryItemInfo(itemId, extension);
    } catch (e, stackTrace) {
      AppLogger.error(
        '获取图库项目信息失败',
        error: e,
        stackTrace: stackTrace,
        data: {
          'itemId': itemId,
          'extension': extension,
        },
      );
      rethrow;
    }
  }

  /// 获取缩略图信息
  Future<FileInfo> getThumbnailInfo(String itemId) async {
    try {
      return await _storage.getThumbnailInfo(itemId);
    } catch (e, stackTrace) {
      AppLogger.error(
        '获取缩略图信息失败',
        error: e,
        stackTrace: stackTrace,
        data: {'itemId': itemId},
      );
      rethrow;
    }
  }
}
