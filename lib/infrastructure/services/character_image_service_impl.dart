import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../cache/services/image_cache_service.dart';
import '../image/image_processor.dart';
import '../logging/logger.dart';
import '../storage/storage_interface.dart';
import 'character_image_service.dart';

/// 集字图片服务实现
class CharacterImageServiceImpl implements CharacterImageService {
  final IStorage _storage;
  final ImageCacheService _imageCacheService;
  final ImageProcessor _imageProcessor;

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
      AppLogger.debug(
        '获取可用格式',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'preferThumbnail': preferThumbnail,
          'operation': 'get_available_format',
        },
      );

      // 如果优先使用预览图，则先检查非方形格式
      if (preferThumbnail) {
        // 优先检查binary格式（非方形二值化图像）
        AppLogger.debug(
          '检查binary格式',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'format': 'binary',
            'operation': 'check_format',
          },
        );
        if (await hasCharacterImage(id, 'binary', 'png')) {
          AppLogger.debug(
            '找到binary格式',
            tag: 'character_image_service',
            data: {
              'characterId': id,
              'type': 'binary',
              'format': 'png',
              'operation': 'format_found',
            },
          );
          return {'type': 'binary', 'format': 'png'};
        }
        // 其次检查transparent格式（非方形透明图像）
        AppLogger.debug(
          '检查transparent格式',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'format': 'transparent',
            'operation': 'check_format',
          },
        );
        if (await hasCharacterImage(id, 'transparent', 'png')) {
          AppLogger.debug(
            '找到transparent格式',
            tag: 'character_image_service',
            data: {
              'characterId': id,
              'type': 'transparent',
              'format': 'png',
              'operation': 'format_found',
            },
          );
          return {'type': 'transparent', 'format': 'png'};
        }
        // 最后检查thumbnail格式
        AppLogger.debug(
          '检查thumbnail格式',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'format': 'thumbnail',
            'operation': 'check_format',
          },
        );
        if (await hasCharacterImage(id, 'thumbnail', 'jpg')) {
          AppLogger.debug(
            '找到thumbnail格式',
            tag: 'character_image_service',
            data: {
              'characterId': id,
              'type': 'thumbnail',
              'format': 'jpg',
              'operation': 'format_found',
            },
          );
          return {'type': 'thumbnail', 'format': 'jpg'};
        }
      }

      // 优先检查square-binary格式
      AppLogger.debug(
        '检查square-binary格式',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'format': 'square-binary',
          'operation': 'check_format',
        },
      );
      if (await hasCharacterImage(id, 'square-binary', 'png-binary')) {
        AppLogger.debug(
          '找到square-binary格式',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'type': 'square-binary',
            'format': 'png-binary',
            'operation': 'format_found',
          },
        );
        return {'type': 'square-binary', 'format': 'png-binary'};
      }

      // 其次检查square-transparent格式
      AppLogger.debug(
        '检查square-transparent格式',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'format': 'square-transparent',
          'operation': 'check_format',
        },
      );
      if (await hasCharacterImage(
          id, 'square-transparent', 'png-transparent')) {
        AppLogger.debug(
          '找到square-transparent格式',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'type': 'square-transparent',
            'format': 'png-transparent',
            'operation': 'format_found',
          },
        );
        return {'type': 'square-transparent', 'format': 'png-transparent'};
      }

      // 最后检查square-outline格式
      AppLogger.debug(
        '检查square-outline格式',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'format': 'square-outline',
          'operation': 'check_format',
        },
      );
      if (await hasCharacterImage(id, 'square-outline', 'svg-outline')) {
        AppLogger.debug(
          '找到square-outline格式',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'type': 'square-outline',
            'format': 'svg-outline',
            'operation': 'format_found',
          },
        );
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
      AppLogger.debug(
        '尝试获取字符图像',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'type': type,
          'format': format,
          'imagePath': imagePath,
          'operation': 'get_character_image',
        },
      );
      final cacheKey = 'file:$imagePath';

      // 尝试从缓存获取
      final cachedData = await _imageCacheService.getBinaryImage(cacheKey);
      if (cachedData != null) {
        AppLogger.debug(
          '从缓存获取图像',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'type': type,
            'format': format,
            'cacheKey': cacheKey,
            'dataSize': cachedData.length,
            'operation': 'get_image_from_cache',
          },
        );
        return cachedData;
      }

      // 使用IStorage检查文件是否存在
      AppLogger.debug(
        '检查文件是否存在',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'imagePath': imagePath,
          'operation': 'check_file_exists',
        },
      );
      final fileExists = await _storage.fileExists(imagePath);
      AppLogger.debug(
        '文件存在检查结果',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'imagePath': imagePath,
          'fileExists': fileExists,
          'operation': 'file_exists_result',
        },
      );

      if (fileExists) {
        // 使用IStorage读取文件内容
        AppLogger.debug(
          '读取文件内容',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'imagePath': imagePath,
            'operation': 'read_file_content',
          },
        );
        final bytes = await _storage.readFile(imagePath);
        AppLogger.debug(
          '文件读取完成',
          tag: 'character_image_service',
          data: {
            'characterId': id,
            'imagePath': imagePath,
            'bytesRead': bytes.length,
            'operation': 'file_read_complete',
          },
        );
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

  /// 获取处理后的字符图片
  @override
  Future<Uint8List?> getProcessedCharacterImage(String characterId, String type,
      String format, Map<String, dynamic> transform) async {
    try {
      // 生成缓存键
      final cacheKey =
          _imageCacheService.generateCacheKey(characterId, type, transform);

      AppLogger.debug(
        '获取处理后的字符图片',
        tag: 'character_image_service',
        data: {
          'characterId': characterId,
          'type': type,
          'format': format,
          'transform': transform,
          'cacheKey': cacheKey,
          'operation': 'get_processed_character_image',
        },
      );

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
      AppLogger.debug(
        '检查图像文件',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'type': type,
          'format': format,
          'imagePath': imagePath,
          'operation': 'has_character_image',
        },
      );
      // 使用IStorage检查文件是否存在
      final exists = await _storage.fileExists(imagePath);
      AppLogger.debug(
        '文件存在检查结果',
        tag: 'character_image_service',
        data: {
          'characterId': id,
          'type': type,
          'format': format,
          'imagePath': imagePath,
          'exists': exists,
          'operation': 'file_exists_check_result',
        },
      );
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
