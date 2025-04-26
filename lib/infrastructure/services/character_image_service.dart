import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../cache/character_image_cache_service.dart';
import '../image/image_processor.dart';
import '../storage/storage_interface.dart';

/// 集字图片服务
class CharacterImageService {
  final IStorage _storage;
  final CharacterImageCacheService _cacheService;
  final ImageProcessor _imageProcessor;

  CharacterImageService({
    required IStorage storage,
    required CharacterImageCacheService cacheService,
    required ImageProcessor imageProcessor,
  })  : _storage = storage,
        _cacheService = cacheService,
        _imageProcessor = imageProcessor;

  /// 清除所有图片缓存
  Future<void> clearAllImageCache() async {
    try {
      debugPrint('开始清除所有字符图像缓存');
      await _cacheService.clearAllCache();
      debugPrint('字符图像缓存清除完成');
    } catch (e) {
      debugPrint('清除字符图像缓存失败: $e');
    }
  }

  /// 获取可用的图片格式
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
      if (await hasCharacterImage(
          id, 'square-transparent', 'png-transparent')) {
        debugPrint('找到square-transparent格式: $id');
        return {'type': 'square-transparent', 'format': 'png-transparent'};
      }

      // 检查缩略图格式（如果之前没有优先检查）
      if (!preferThumbnail && await hasCharacterImage(id, 'thumbnail', 'jpg')) {
        debugPrint('找到thumbnail格式: $id');
        return {'type': 'thumbnail', 'format': 'jpg'};
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
  Future<Uint8List?> getCharacterImage(
      String id, String type, String format) async {
    try {
      final imagePath = _getImagePath(id, type, format);

      // 使用IStorage检查文件是否存在
      if (await _storage.fileExists(imagePath)) {
        // 使用IStorage读取文件内容
        final bytes = await _storage.readFile(imagePath);
        return bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
      }

      // 如果请求的格式不存在，尝试使用另一种格式
      if (format == 'svg-outline') {
        // 尝试加载PNG-binary格式
        final pngPath = _getImagePath(id, 'square-binary', 'png-binary');
        if (await _storage.fileExists(pngPath)) {
          debugPrint('SVG格式不存在，使用PNG-binary格式代替: $id, $type');
          final bytes = await _storage.readFile(pngPath);
          return bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
        }

        // 尝试加载PNG-transparent格式
        final pngTransPath =
            _getImagePath(id, 'square-transparent', 'png-transparent');
        if (await _storage.fileExists(pngTransPath)) {
          debugPrint('SVG格式不存在，使用PNG-transparent格式代替: $id, $type');
          final bytes = await _storage.readFile(pngTransPath);
          return bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
        }
      } else if (format == 'png-binary' || format == 'png-transparent') {
        // 尝试加载SVG格式
        final svgPath = _getImagePath(id, 'square-outline', 'svg-outline');
        if (await _storage.fileExists(svgPath)) {
          debugPrint('PNG格式不存在，使用SVG格式代替: $id, $type');
          final bytes = await _storage.readFile(svgPath);
          return bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
        }

        // 如果是png-binary，尝试加载png-transparent
        if (format == 'png-binary') {
          final pngTransPath =
              _getImagePath(id, 'square-transparent', 'png-transparent');
          if (await _storage.fileExists(pngTransPath)) {
            debugPrint('PNG-binary格式不存在，使用PNG-transparent格式代替: $id, $type');
            final bytes = await _storage.readFile(pngTransPath);
            return bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
          }
        }

        // 如果是png-transparent，尝试加载png-binary
        if (format == 'png-transparent') {
          final pngBinaryPath =
              _getImagePath(id, 'square-binary', 'png-binary');
          if (await _storage.fileExists(pngBinaryPath)) {
            debugPrint('PNG-transparent格式不存在，使用PNG-binary格式代替: $id, $type');
            final bytes = await _storage.readFile(pngBinaryPath);
            return bytes.isNotEmpty ? Uint8List.fromList(bytes) : null;
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('获取字符图片失败: $e');
      return null;
    }
  }

  /// 获取处理后的字符图片
  Future<Uint8List?> getProcessedCharacterImage(String characterId, String type,
      String format, Map<String, dynamic> transform) async {
    try {
      // 1. 尝试从缓存获取
      final cachedImage =
          await _cacheService.getCachedImage(characterId, type, transform);

      if (cachedImage != null) {
        return cachedImage;
      }

      // 2. 如果缓存不存在，加载原始图片
      final originalImage = await getCharacterImage(characterId, type, format);
      if (originalImage == null) {
        return null;
      }

      // 3. 使用ImageProcessor处理图片
      final processedImage = await _imageProcessor.processCharacterImage(
          originalImage, format, transform);

      // 4. 缓存处理结果
      await _cacheService.cacheImage(
          characterId, type, transform, processedImage);

      return processedImage;
    } catch (e) {
      debugPrint('获取处理后的字符图片失败: $e');
      return null;
    }
  }

  /// 检查图片是否存在
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
