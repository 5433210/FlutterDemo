import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../infrastructure/cache/services/image_cache_service.dart';
import '../../infrastructure/image/image_processor.dart';
import '../../infrastructure/logging/logger.dart';
import '../../infrastructure/storage/storage_interface.dart';
import 'character_image_service.dart';

/// 集字图片服务实现
class CharacterImageServiceImpl implements CharacterImageService {
  final IStorage _storage;
  final ImageCacheService _imageCacheService;
  final ImageProcessor _imageProcessor;

  // 🚀 性能优化：缓存命中率统计
  int _cacheHits = 0;
  int _cacheMisses = 0;
  final Map<String, DateTime> _lastLogTime = {};

  // 🚀 性能优化：批量请求去重
  final Map<String, Future<Uint8List?>> _pendingRequests = {};
  
  // 🚀 优化：静态去重集合
  static final Set<String> _loggedFormatChecks = <String>{};
  static final Set<String> _loggedDeduplications = <String>{};
  static final Set<String> _loggedExistenceChecks = <String>{};
  static int _processedImageCount = 0;

  CharacterImageServiceImpl({
    required IStorage storage,
    required ImageCacheService imageCacheService,
    required ImageProcessor imageProcessor,
  })  : _storage = storage,
        _imageCacheService = imageCacheService,
        _imageProcessor = imageProcessor;

  /// 清除所有图片缓存
  @override
  Future<void> clearAllImageCache() async {
    try {
      AppLogger.info(
        '开始清除所有字符图像缓存',
        tag: 'character_image_service',
        data: {
          'operation': 'clear_all_image_cache_start',
        },
      );
      await _imageCacheService.clearAll();
      AppLogger.info(
        '字符图像缓存清除完成',
        tag: 'character_image_service',
        data: {
          'operation': 'clear_all_image_cache_complete',
        },
      );
    } catch (e) {
      AppLogger.error(
        '清除字符图像缓存失败',
        tag: 'character_image_service',
        error: e,
        data: {
          'operation': 'clear_all_image_cache_failed',
        },
      );
    }
  }

  /// 获取可用的图片格式
  @override
  Future<Map<String, String>?> getAvailableFormat(String id,
      {bool preferThumbnail = false}) async {
    try {
      // 🚀 优化：减少格式检查的详细日志，只在首次检查或出错时记录
      if (!_loggedFormatChecks.contains(id)) {
        AppLogger.debug(
          '获取可用格式',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'preferThumbnail': preferThumbnail,
            'operation': 'get_available_format',
            'optimization': 'first_check_only',
          },
        );
        _loggedFormatChecks.add(id);
      }

      // 如果优先使用预览图，则先检查非方形格式
      if (preferThumbnail) {
        // 优先检查binary格式（非方形二值化图像）
        // 🚀 优化：移除频繁的格式检查日志
        if (await hasCharacterImage(id, 'binary', 'png')) {
          // 🚀 优化：只在首次找到格式时记录
          return {'type': 'binary', 'format': 'png'};
        }
        // 其次检查transparent格式（非方形透明图像）
        // 🚀 优化：移除频繁的格式检查日志
        if (await hasCharacterImage(id, 'transparent', 'png')) {
          // 🚀 优化：只在首次找到格式时记录
          return {'type': 'transparent', 'format': 'png'};
        }
        // 最后检查thumbnail格式
        // 🚀 优化：移除频繁的格式检查日志
        if (await hasCharacterImage(id, 'thumbnail', 'jpg')) {
          // 🚀 优化：只在首次找到格式时记录
          return {'type': 'thumbnail', 'format': 'jpg'};
        }
      }

      // 优先检查square-binary格式
      // 🚀 优化：移除频繁的格式检查日志
      if (await hasCharacterImage(id, 'square-binary', 'png-binary')) {
        // 🚀 优化：只在首次找到格式时记录
        return {'type': 'square-binary', 'format': 'png-binary'};
      }

      // 其次检查square-transparent格式
      // 🚀 优化：移除频繁的格式检查日志
      if (await hasCharacterImage(
          id, 'square-transparent', 'png-transparent')) {
        // 🚀 优化：只在首次找到格式时记录
        return {'type': 'square-transparent', 'format': 'png-transparent'};
      }

      // 最后检查square-outline格式
      // 🚀 优化：移除频繁的格式检查日志
      if (await hasCharacterImage(id, 'square-outline', 'svg-outline')) {
        // 🚀 优化：只在首次找到格式时记录
        return {'type': 'square-outline', 'format': 'svg-outline'};
      }

      // 如果没有找到任何格式，返回默认格式
      AppLogger.warning(
        '未找到任何格式，返回默认格式',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'defaultType': 'square-binary',
          'defaultFormat': 'png-binary',
          'operation': 'format_not_found_use_default',
        },
      );
      return {'type': 'square-binary', 'format': 'png-binary'};
    } catch (e) {
      AppLogger.error(
        '获取字符图片可用格式失败',
        tag: 'character_image_service',
        error: e,
        data: {
          'characterId': id,
          'preferThumbnail': preferThumbnail,
          'operation': 'get_available_format_failed',
        },
      );
      // 返回默认格式
      return {'type': 'square-binary', 'format': 'png-binary'};
    }
  }

  /// 获取原始字符图片
  @override
  Future<Uint8List?> getCharacterImage(
      String id, String type, String format) async {
    try {
      final imagePath = _getImagePath(id, type, format);
      final cacheKey = 'file:$imagePath';

      // 🚀 优化：防止重复请求
      if (_pendingRequests.containsKey(cacheKey)) {
      // 🚀 优化：减少复用正在进行的图像请求的详细日志
      // 只在首次复用或特定情况下记录
      if (!_loggedDeduplications.contains(cacheKey)) {
        _loggedDeduplications.add(cacheKey);
        AppLogger.debug(
          '复用正在进行的图像请求',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'cacheKey': cacheKey,
            'optimization': 'request_deduplication_first_log',
          },
        );
        // 防止集合过大
        if (_loggedDeduplications.length > 500) {
          _loggedDeduplications.clear();
        }
      }
        return await _pendingRequests[cacheKey]!;
      }

      // 创建请求Future
      final requestFuture =
          _loadCharacterImageInternal(id, type, format, imagePath, cacheKey);
      _pendingRequests[cacheKey] = requestFuture;

      try {
        return await requestFuture;
      } finally {
        _pendingRequests.remove(cacheKey);
      }
    } catch (e) {
      AppLogger.error(
        '获取字符图片失败',
        tag: 'character_image_service',
        error: e,
        data: {
          'characterId': id,
          'type': type,
          'format': format,
          'operation': 'get_character_image_failed',
        },
      );
      return null;
    }
  }

  /// 🚀 内部图像加载方法
  Future<Uint8List?> _loadCharacterImageInternal(String id, String type,
      String format, String imagePath, String cacheKey) async {
    // 尝试从缓存获取
    final cachedData = await _imageCacheService.getBinaryImage(cacheKey);
    if (cachedData != null) {
      _cacheHits++;

      // 🚀 优化：减少重复日志，每个图像每分钟最多记录一次
      final now = DateTime.now();
      final lastLog = _lastLogTime[cacheKey];
      if (lastLog == null || now.difference(lastLog).inMinutes >= 1) {
        AppLogger.debug(
          '从缓存获取图像',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'type': type,
            'format': format,
            'cacheKey': cacheKey,
            'dataSize': cachedData.length,
            'cacheHitRate': _getCacheHitRate(),
            'operation': 'get_image_from_cache',
          },
        );
        _lastLogTime[cacheKey] = now;
      }
      return cachedData;
    }

    _cacheMisses++;

    // 使用IStorage检查文件是否存在
    final fileExists = await _storage.fileExists(imagePath);

    if (fileExists) {
      // 使用IStorage读取文件内容
      final bytes = await _storage.readFile(imagePath);
      final data = bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;

      // 缓存数据
      if (data != null) {
        await _imageCacheService.cacheBinaryImage(cacheKey, data);
        AppLogger.info(
          '缓存图像数据',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'type': type,
            'format': format,
            'cacheKey': cacheKey,
            'dataSize': data.length,
            'cacheHitRate': _getCacheHitRate(),
            'operation': 'cache_image_data',
          },
        );
      } else {
        AppLogger.warning(
          '文件内容为空',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'imagePath': imagePath,
            'operation': 'file_content_empty',
          },
        );
      }

      return data;
    } else {
      AppLogger.warning(
        '文件不存在',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'imagePath': imagePath,
          'operation': 'file_not_exists',
        },
      );
    }

    return null;
  }

  /// 🚀 获取缓存命中率
  double _getCacheHitRate() {
    final total = _cacheHits + _cacheMisses;
    return total > 0 ? _cacheHits / total : 0.0;
  }

  /// 🚀 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'hitRate': _getCacheHitRate(),
      'pendingRequests': _pendingRequests.length,
    };
  }

  /// 获取处理后的字符图片
  @override
  Future<Uint8List?> getProcessedCharacterImage(String characterId, String type,
      String format, Map<String, dynamic> transform) async {
    try {
      // 生成缓存键
      final cacheKey =
          _imageCacheService.generateCacheKey(characterId, type, transform);

      // 🚀 优化：减少处理后图片获取的详细日志，使用里程碑记录
      _processedImageCount++;
      if (_processedImageCount % 30 == 0) {
        AppLogger.debug(
          '处理字符图片里程碑',
          tag: 'character_image_service',
          data: {
            'processedCount': _processedImageCount,
            'recentType': type,
            'recentFormat': format,
            'operation': 'processed_image_milestone',
          },
        );
      }

      // 使用getProcessedImage方法处理图像
      return await _imageCacheService.getProcessedImage(
        cacheKey,
        () => getCharacterImage(characterId, type, format),
        (originalImage) => _imageProcessor.processCharacterImage(
            originalImage, format, transform),
      );
    } catch (e) {
      AppLogger.error(
        '获取处理后的字符图片失败',
        tag: 'character_image_service',
        error: e,
        data: {
          'characterId': characterId,
          'type': type,
          'format': format,
          'transform': transform,
          'operation': 'get_processed_character_image_failed',
        },
      );
      return null;
    }
  }

  /// 检查图片是否存在
  @override
  Future<bool> hasCharacterImage(String id, String type, String format) async {
    try {
      final imagePath = _getImagePath(id, type, format);
      // 🚀 优化：减少文件存在检查的详细日志，只在出错或首次检查时记录
      final checkKey = '$id-$type-$format';
      if (!_loggedExistenceChecks.contains(checkKey)) {
        _loggedExistenceChecks.add(checkKey);
        if (_loggedExistenceChecks.length > 1000) {
          // 清理旧记录，防止内存泄漏
          _loggedExistenceChecks.clear();
        }
      }
      // 使用IStorage检查文件是否存在
      final exists = await _storage.fileExists(imagePath);
      // 🚀 优化：只在文件不存在或检查出错时记录详细信息
      if (!exists) {
        AppLogger.debug(
          '文件不存在',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'type': type,
            'format': format,
            'imagePath': imagePath,
            'operation': 'file_not_found',
          },
        );
      }
      return exists;
    } catch (e) {
      AppLogger.error(
        '检查字符图片是否存在失败',
        tag: 'character_image_service',
        error: e,
        data: {
          'characterId': id,
          'type': type,
          'format': format,
          'operation': 'has_character_image_failed',
        },
      );
      return false;
    }
  }

  /// 获取图片路径
  String _getImagePath(String id, String type, String format) {
    // 根据CharacterStorageService中的定义获取正确的文件路径
    switch (type) {
      case 'square-binary':
        return path.join(_storage.getAppDataPath(), 'characters', id,
            '$id-square-binary.png');
      case 'square-transparent':
        return path.join(_storage.getAppDataPath(), 'characters', id,
            '$id-square-transparent.png');
      case 'square-outline':
        return path.join(_storage.getAppDataPath(), 'characters', id,
            '$id-square-outline.svg');
      case 'thumbnail':
        return path.join(
            _storage.getAppDataPath(), 'characters', id, '$id-thumbnail.jpg');
      case 'square-thumbnail':
        return path.join(_storage.getAppDataPath(), 'characters', id,
            '$id-square-thumbnail.jpg');
      default:
        // 默认使用square-binary
        return path.join(_storage.getAppDataPath(), 'characters', id,
            '$id-square-binary.png');
    }
  }
}
