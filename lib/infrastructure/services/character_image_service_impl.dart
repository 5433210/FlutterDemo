import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../cache/services/image_cache_service.dart';
import '../image/image_processor.dart';
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
      debugPrint('开始清除所有字符图像缓存');
      await _imageCacheService.clearAll();
      debugPrint('字符图像缓存清除完成');
    } catch (e) {
      debugPrint('清除字符图像缓存失败: $e');
    }
  }

  /// 获取可用的图片格式
  @override
  Future<Map<String, String>?> getAvailableFormat(String id,
      {bool preferThumbnail = false}) async {
    try {
      debugPrint('获取字符图片可用格式: $id, 优先使用缩略图: $preferThumbnail');

      // 如果优先使用预览图，则先检查非方形格式
      if (preferThumbnail) {
        // 优先检查binary格式（非方形二值化图像）
        if (await hasCharacterImage(id, 'binary', 'png')) {
          debugPrint('找到binary格式: $id');
          return {'type': 'binary', 'format': 'png'};
        }
        // 其次检查transparent格式（非方形透明图像）
        if (await hasCharacterImage(id, 'transparent', 'png')) {
          debugPrint('找到transparent格式: $id');
          return {'type': 'transparent', 'format': 'png'};
        }
        // 最后检查thumbnail格式
        if (await hasCharacterImage(id, 'thumbnail', 'jpg')) {
          debugPrint('找到thumbnail格式: $id');
          return {'type': 'thumbnail', 'format': 'jpg'};
        }
      }

      // 优先检查square-binary格式
      if (await hasCharacterImage(id, 'square-binary', 'png-binary')) {
        debugPrint('找到square-binary格式: $id');
        return {'type': 'square-binary', 'format': 'png-binary'};
      }

      // 其次检查square-transparent格式
      if (await hasCharacterImage(id, 'square-transparent', 'png-transparent')) {
        debugPrint('找到square-transparent格式: $id');
        return {'type': 'square-transparent', 'format': 'png-transparent'};
      }

      // 最后检查square-outline格式
      if (await hasCharacterImage(id, 'square-outline', 'svg-outline')) {
        debugPrint('找到square-outline格式: $id');
        return {'type': 'square-outline', 'format': 'svg-outline'};
      }

      // 如果没有找到任何格式，返回默认格式
      debugPrint('未找到任何格式，返回默认格式: $id');
      return {'type': 'square-binary', 'format': 'png-binary'};
    } catch (e) {
      debugPrint('获取字符图片可用格式失败: $e');
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
      
      // 尝试从缓存获取
      final cachedData = await _imageCacheService.getBinaryImage(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }

      // 使用IStorage检查文件是否存在
      if (await _storage.fileExists(imagePath)) {
        // 使用IStorage读取文件内容
        final bytes = await _storage.readFile(imagePath);
        final data = bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
        
        // 缓存数据
        if (data != null) {
          await _imageCacheService.cacheBinaryImage(cacheKey, data);
        }
        
        return data;
      }

      return null;
    } catch (e) {
      debugPrint('获取字符图片失败: $e');
      return null;
    }
  }

  /// 获取处理后的字符图片
  @override
  Future<Uint8List?> getProcessedCharacterImage(String characterId, String type,
      String format, Map<String, dynamic> transform) async {
    try {
      // 生成缓存键
      final cacheKey = _imageCacheService.generateCacheKey(
          characterId, type, transform);
      
      // 使用getProcessedImage方法处理图像
      return await _imageCacheService.getProcessedImage(
        cacheKey,
        () => getCharacterImage(characterId, type, format),
        (originalImage) => _imageProcessor.processCharacterImage(
            originalImage, format, transform),
      );
    } catch (e) {
      debugPrint('获取处理后的字符图片失败: $e');
      return null;
    }
  }

  /// 检查图片是否存在
  @override
  Future<bool> hasCharacterImage(String id, String type, String format) async {
    try {
      final imagePath = _getImagePath(id, type, format);
      // 使用IStorage检查文件是否存在
      return await _storage.fileExists(imagePath);
    } catch (e) {
      debugPrint('检查字符图片是否存在失败: $e');
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
