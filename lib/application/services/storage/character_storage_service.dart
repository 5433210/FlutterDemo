import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../../utils/cache/path_cache.dart';
import '../../../utils/config/logging_config.dart';

final characterStorageServiceProvider =
    Provider<CharacterStorageService>((ref) {
  return CharacterStorageService();
});

// 辅助函数：解析JSON
Map<String, dynamic> jsonDecode(String jsonString) {
  // 简单实现，实际应使用dart:convert库
  return {};
}

// 辅助函数：字符串化JSON
String jsonEncode(Map<String, dynamic> json) {
  // 简单实现，实际应使用dart:convert库
  return json.toString();
}

class CharacterStorageService {
  // 存储根目录
  late String _baseStoragePath;

  // 字符存储子目录
  late String _charactersPath;

  // 缓存目录
  late String _cachePath;

  // 是否已初始化
  bool _initialized = false;

  // 清理临时文件
  Future<void> cleanupTemporaryFiles() async {
    await _ensureInitialized();

    try {
      final cacheDir = Directory(_cachePath);
      if (await cacheDir.exists()) {
        // 删除7天前创建的文件
        final now = DateTime.now();
        await for (final entity in cacheDir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            final fileAge = now.difference(stat.modified).inDays;

            if (fileAge > 7) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      print('清理临时文件失败: $e');
    }
  }

  // 删除字符数据
  Future<void> deleteCharacter(String characterId) async {
    await _ensureInitialized();

    final characterDir = path.join(_charactersPath, characterId);
    final dir = Directory(characterDir);

    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  // 获取二值化图像路径
  Future<String> getBinaryImagePath(String characterId) async {
    final characterDir = await getCharacterDirectory(characterId);
    return path.join(characterDir, 'binary.png');
  }

  // 获取字符存储目录
  Future<String> getCharacterDirectory(String characterId) async {
    await _ensureInitialized();

    final characterDir = path.join(_charactersPath, characterId);
    await Directory(characterDir).create(recursive: true);

    return characterDir;
  }

  // 获取元数据
  Future<Map<String, dynamic>?> getMetadata(String characterId) async {
    final characterDir = await getCharacterDirectory(characterId);
    final filePath = path.join(characterDir, 'metadata.json');

    final file = File(filePath);
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      return jsonDecode(jsonString);
    }

    return null;
  }

  // 获取原始图像路径
  Future<String> getOriginalImagePath(String characterId) async {
    final characterDir = await getCharacterDirectory(characterId);
    return path.join(characterDir, 'original.png');
  }

  // 获取存储信息
  Future<StorageInfo> getStorageInfo() async {
    await _ensureInitialized();

    try {
      // 获取字符数量
      final charactersDir = Directory(_charactersPath);
      int characterCount = 0;
      if (await charactersDir.exists()) {
        final items = await charactersDir.list().toList();
        characterCount = items.whereType<Directory>().length;
      }

      // 获取存储大小
      int totalSize = 0;
      await for (final entity in charactersDir.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }

      return StorageInfo(
        characterCount: characterCount,
        totalSizeBytes: totalSize,
      );
    } catch (e) {
      print('获取存储信息失败: $e');
      return StorageInfo(
        characterCount: 0,
        totalSizeBytes: 0,
      );
    }
  }

  // 获取SVG轮廓路径
  Future<String?> getSvgOutlinePath(String characterId) async {
    final characterDir = await getCharacterDirectory(characterId);
    final filePath = path.join(characterDir, 'outline.svg');

    if (await File(filePath).exists()) {
      return filePath;
    }

    return null;
  }

  // 获取缩略图路径
  Future<String> getThumbnailPath(String characterId) async {
    // Check cache first
    final cachedPath = PathCache.getCachedThumbnailPath(characterId);
    if (cachedPath != null) {
      if (LoggingConfig.verboseThumbnailLogging) {
        LoggingConfig.debugPrint(
            'CharacterStorageService - Using cached thumbnail path for ID: $characterId');
      }
      return cachedPath;
    }

    final characterDir = await getCharacterDirectory(characterId);
    final thumbnailPath = path.join(characterDir, 'thumbnail.jpg');

    if (LoggingConfig.verboseThumbnailLogging) {
      LoggingConfig.debugPrint(
          'CharacterStorageService - Generated thumbnail path for ID: $characterId');
    }

    // Cache the result
    PathCache.cacheThumbnailPath(characterId, thumbnailPath);

    return thumbnailPath;
  }

  // 检查存储空间是否足够
  Future<bool> hasEnoughStorage(int requiredBytes) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final stat = await FileStat.stat(appDir.path);

      // 这是一个粗略的实现，实际应该获取可用空间
      // 由于Flutter没有直接API获取可用空间，这里简化处理
      return true;
    } catch (e) {
      print('检查存储空间失败: $e');
      return false;
    }
  }

  // 保存二值化图像
  Future<String> saveBinaryImage(
      String characterId, Uint8List imageData) async {
    final characterDir = await getCharacterDirectory(characterId);

    final filePath = path.join(characterDir, 'binary.png');
    await File(filePath).writeAsBytes(imageData);

    return filePath;
  }

  // 保存元数据
  Future<void> saveMetadata(
      String characterId, Map<String, dynamic> metadata) async {
    final characterDir = await getCharacterDirectory(characterId);

    final filePath = path.join(characterDir, 'metadata.json');
    await File(filePath).writeAsString(jsonEncode(metadata));
  }

  // 保存原始裁剪图像
  Future<String> saveOriginalImage(
      String characterId, Uint8List imageData) async {
    final characterDir = await getCharacterDirectory(characterId);

    final filePath = path.join(characterDir, 'original.png');
    await File(filePath).writeAsBytes(imageData);

    return filePath;
  }

  // 保存SVG轮廓
  Future<String?> saveSvgOutline(String characterId, String? svgData) async {
    if (svgData == null) return null;

    final characterDir = await getCharacterDirectory(characterId);

    final filePath = path.join(characterDir, 'outline.svg');
    await File(filePath).writeAsString(svgData);

    return filePath;
  }

  // 保存缩略图
  Future<String> saveThumbnail(String characterId, Uint8List imageData) async {
    final characterDir = await getCharacterDirectory(characterId);

    final filePath = path.join(characterDir, 'thumbnail.jpg');
    await File(filePath).writeAsBytes(imageData);

    return filePath;
  }

  /// Checks if a thumbnail exists and logs its details if enabled
  Future<bool> thumbnailExists(String path) async {
    final exists = await PathCache.fileExists(path);

    if (exists && LoggingConfig.verboseThumbnailLogging) {
      final size = await PathCache.fileSize(path);
      LoggingConfig.debugPrint(
          'CharacterStorageService - Thumbnail exists: $path (Size: $size bytes)');
    }

    return exists;
  }

  // 确保初始化完成
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await _init();
    }
  }

  // 初始化存储路径
  Future<void> _init() async {
    if (_initialized) return;

    try {
      // 获取应用文档目录
      final appDir = await getApplicationDocumentsDirectory();

      // 设置基础存储路径
      _baseStoragePath = path.join(appDir.path, 'storage');

      // 设置字符存储路径
      _charactersPath = path.join(_baseStoragePath, 'characters');

      // 设置缓存路径
      final tempDir = await getTemporaryDirectory();
      _cachePath = path.join(tempDir.path, 'character_cache');

      // 确保目录存在
      await Directory(_baseStoragePath).create(recursive: true);
      await Directory(_charactersPath).create(recursive: true);
      await Directory(_cachePath).create(recursive: true);

      _initialized = true;
    } catch (e) {
      print('初始化字符存储服务失败: $e');
      rethrow;
    }
  }
}

// 存储信息模型
class StorageInfo {
  final int characterCount;
  final int totalSizeBytes;

  StorageInfo({
    required this.characterCount,
    required this.totalSizeBytes,
  });

  // 格式化的总大小
  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      final kb = totalSizeBytes / 1024;
      return '${kb.toStringAsFixed(2)} KB';
    } else if (totalSizeBytes < 1024 * 1024 * 1024) {
      final mb = totalSizeBytes / (1024 * 1024);
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      final gb = totalSizeBytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(2)} GB';
    }
  }
}
