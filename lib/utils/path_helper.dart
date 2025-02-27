import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../infrastructure/logging/logger.dart';

class PathHelper {
  /// 返回一个最小的有效PNG文件字节数组 (1x1像素)
  Uint8List createMinimalPngBytes() {
    // 这是一个最小的有效PNG文件，1x1像素，红色
    return Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x02,
      0x00,
      0x00,
      0x00,
      0x90,
      0x77,
      0x53,
      0xDE,
      0x00,
      0x00,
      0x00,
      0x0C,
      0x49,
      0x44,
      0x41,
      0x54,
      0x08,
      0xD7,
      0x63,
      0xF8,
      0xCF,
      0xC0,
      0x00,
      0x00,
      0x03,
      0x01,
      0x01,
      0x00,
      0x18,
      0xDD,
      0x8D,
      0xB0,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82
    ]);
  }

  /// 创建有效的占位图像文件
  static Future<void> createPlaceholderImage(String filePath) async {
    try {
      final file = File(filePath);

      // 如果文件已经存在就不做任何操作
      if (await file.exists()) {
        // 检查文件大小，如果为0则需要替换
        if (await file.length() == 0) {
          await file.delete();
        } else {
          return; // 文件存在且有效
        }
      }

      // 确保父目录存在
      final directory = Directory(path.dirname(filePath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 创建一个最小的有效PNG文件 (1x1像素)
      final pngData = PathHelper().createMinimalPngBytes();
      await file.writeAsBytes(pngData);

      AppLogger.debug('创建有效占位图成功',
          tag: 'PathHelper', data: {'path': filePath, 'size': pngData.length});
    } catch (e, stack) {
      AppLogger.error('创建占位图失败',
          tag: 'PathHelper',
          error: e,
          stackTrace: stack,
          data: {'path': filePath});
    }
  }

  /// 确保目录存在
  static Future<void> ensureDirectoryExists(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
        AppLogger.debug('目录创建成功',
            tag: 'PathHelper', data: {'path': directoryPath});
      }
    } catch (e, stack) {
      // 特别处理目录已存在的情况
      if (e is FileSystemException && e.osError?.errorCode == 183) {
        // 183 表示 "当文件已存在时，无法创建该文件"
        // 这是正常的情况，目录可能在并发情况下被创建
        AppLogger.debug('目录已存在',
            tag: 'PathHelper', data: {'path': directoryPath});
        return;
      }

      AppLogger.error('确保目录存在失败',
          tag: 'PathHelper',
          error: e,
          stackTrace: stack,
          data: {'path': directoryPath});
      rethrow;
    }
  }

  /// 确保文件存在，如果不存在则创建一个空文件
  static Future<void> ensureFileExists(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        // 确保父目录存在
        final parentDir = path.dirname(filePath);
        await ensureDirectoryExists(parentDir);

        try {
          // 创建空文件
          await file.create();
          AppLogger.debug('文件创建成功',
              tag: 'PathHelper', data: {'path': filePath});
        } catch (e) {
          // 检查文件是否已经被创建（可能是并发请求导致）
          if (await file.exists()) {
            AppLogger.debug('文件已存在',
                tag: 'PathHelper', data: {'path': filePath});
            return;
          }
          rethrow;
        }
      }
    } catch (e, stack) {
      AppLogger.error('确保文件存在失败',
          tag: 'PathHelper',
          error: e,
          stackTrace: stack,
          data: {'path': filePath});
      rethrow;
    }
  }

  /// 确保作品目录结构存在
  static Future<void> ensureWorkDirectoryExists(String workId) async {
    try {
      AppLogger.debug('确保作品目录结构存在',
          tag: 'PathHelper', data: {'workId': workId});

      final workPath = await getWorkPath(workId);
      await ensureDirectoryExists(workPath);

      // 创建作品子目录结构
      await ensureDirectoryExists(path.join(workPath, 'pictures'));
      await ensureDirectoryExists(path.join(workPath, 'thumbnails'));

      // 在开发模式下，如果没有图片，创建一个测试用的占位图片
      if (kDebugMode) {
        final initialPictureDirPath = path.join(workPath, 'pictures', '0');
        await ensureDirectoryExists(initialPictureDirPath);

        final importedPath = path.join(initialPictureDirPath, 'imported.png');
        final thumbnailPath = path.join(initialPictureDirPath, 'thumbnail.jpg');

        // 检查文件是否存在，不存在则创建占位图
        if (!await File(importedPath).exists()) {
          await createPlaceholderImage(importedPath);
        }

        if (!await File(thumbnailPath).exists()) {
          await createPlaceholderImage(thumbnailPath);
        }

        // 创建作品缩略图
        final coverPath = path.join(workPath, 'cover.jpg');
        if (!await File(coverPath).exists()) {
          await createPlaceholderImage(coverPath);
        }

        AppLogger.debug('在开发模式下创建了占位图',
            tag: 'PathHelper', data: {'workId': workId});
      }

      // 确保封面目录存在
      final thumbnailPath = await getWorkCoverThumbnailPath(workId);
      await ensureDirectoryExists(path.dirname(thumbnailPath));
    } catch (e, stack) {
      AppLogger.error('确保作品目录结构存在失败',
          tag: 'PathHelper',
          error: e,
          stackTrace: stack,
          data: {'workId': workId});
      rethrow;
    }
  }

  // 获取应用数据路径
  static Future<String> getAppDataPath() async {
    try {
      // 检查是否有环境变量配置
      final String? envPath = Platform.environment['APP_DATA_PATH'];
      if (envPath != null && envPath.isNotEmpty) {
        final dir = Directory(envPath);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return envPath;
      }

      // 使用应用文档目录
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String dataPath = path.join(appDir.path, 'data');

      // 确保目录存在
      final dataDir = Directory(dataPath);
      if (!await dataDir.exists()) {
        await dataDir.create(recursive: true);
      }

      return dataPath;
    } catch (e, stack) {
      AppLogger.error('获取应用数据路径失败',
          tag: 'PathHelper', error: e, stackTrace: stack);
      rethrow;
    }
  }

  static Future<String> getOriginalWorkPath(
      String workId, int index, String extension) async {
    final workPath = await getWorkPath(workId);
    final imagePath =
        path.join(workPath, 'pictures', index.toString(), 'original$extension');

    // 确保原始图片目录存在
    await ensureDirectoryExists(path.dirname(imagePath));

    return imagePath;
  }

  // 获取作品首页缩略图路径 (列表展示用)
  static Future<String> getWorkCoverThumbnailPath(String workId) async {
    try {
      final workDir = await getWorkPath(workId);
      final thumbnailPath = path.join(workDir, 'cover.jpg');

      // 确保父目录存在
      final directory = Directory(path.dirname(thumbnailPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 如果文件不存在且是开发模式，创建一个占位图
      final file = File(thumbnailPath);
      if (kDebugMode && !await file.exists()) {
        await createPlaceholderImage(thumbnailPath);
      }

      return thumbnailPath;
    } catch (e, stack) {
      AppLogger.error('获取作品封面路径失败',
          tag: 'PathHelper',
          error: e,
          stackTrace: stack,
          data: {'workId': workId});
      rethrow;
    }
  }

  // 获取作品图片路径 (原始或导入后的图片)
  static Future<String?> getWorkImagePath(String workId, int index) async {
    try {
      final workDir = await getWorkPath(workId);
      final imageDirPath = path.join(workDir, 'pictures', index.toString());
      final imagePath = path.join(imageDirPath, 'imported.png');

      // 确保目录存在
      final directory = Directory(imageDirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 如果文件不存在且是开发模式，创建一个占位图
      final file = File(imagePath);
      if (kDebugMode && !await file.exists()) {
        await createPlaceholderImage(imagePath);
      }

      return imagePath;
    } catch (e, stack) {
      AppLogger.error('获取图片路径失败',
          tag: 'PathHelper',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'index': index});
      rethrow;
    }
  }

  // 获取作品内特定图片的缩略图路径
  static Future<String?> getWorkImageThumbnailPath(
      String workId, int index) async {
    try {
      final workDir = await getWorkPath(workId);
      final thumbnailDirPath = path.join(workDir, 'pictures', index.toString());
      final thumbnailPath = path.join(thumbnailDirPath, 'thumbnail.jpg');

      // 确保目录存在
      final directory = Directory(thumbnailDirPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // 如果文件不存在且是开发模式，创建一个占位图
      final file = File(thumbnailPath);
      if (kDebugMode && !await file.exists()) {
        await createPlaceholderImage(thumbnailPath);
      }

      return thumbnailPath;
    } catch (e, stack) {
      AppLogger.error('获取缩略图路径失败',
          tag: 'PathHelper',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'index': index});
      rethrow;
    }
  }

  // 获取作品目录路径
  static Future<String> getWorkPath(String workId) async {
    final worksDir = await getWorksPath();
    return path.join(worksDir, workId);
  }

  static Future<String> getWorksPath() async {
    final appDataPath = await getAppDataPath();
    return path.join(appDataPath, 'works');
  }

  // 较短的别名方法，保持向后兼容
  static Future<String?> getWorkThumbnailPath(String workId,
      [int? index]) async {
    if (index == null) {
      // 无索引时返回封面缩略图
      return getWorkCoverThumbnailPath(workId);
    } else {
      // 有索引时返回特定图片缩略图
      return getWorkImageThumbnailPath(workId, index);
    }
  }

  static Future<bool> isFileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      AppLogger.error('检查文件是否存在失败',
          tag: 'PathHelper', error: e, data: {'path': filePath});
      return false;
    }
  }

  /// 检查作品首页缩略图是否存在
  static Future<bool> workCoverThumbnailExists(String workId) async {
    try {
      final thumbnailPath = await getWorkCoverThumbnailPath(workId);
      final file = File(thumbnailPath);
      return await file.exists();
    } catch (e) {
      AppLogger.error('检查缩略图是否存在失败',
          tag: 'PathHelper', error: e, data: {'workId': workId});
      return false;
    }
  }
}
