import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../application/config/app_config.dart';

class PathHelper {
  // 获取作品首页缩略图路径 (列表展示用)
  static Future<String> getWorkCoverThumbnailPath(String workId) async {
    // 使用和 StoragePaths 一致的路径结构
    final thumbnailPath = path.join(AppConfig.dataPath, AppConfig.storageFolder,
        AppConfig.worksFolder, workId, AppConfig.thumbnailFile);

    // 确保父目录存在
    final directory = Directory(path.dirname(thumbnailPath));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    debugPrint('Getting work cover thumbnail path: $thumbnailPath');
    return thumbnailPath;
  }

  // 获取作品目录路径
  static Future<String> getWorkDirectory(String workId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'works', workId);
  }

  // 获取作品图片路径 (原始或导入后的图片)
  static Future<String?> getWorkImagePath(String workId, int index) async {
    final workDir = path.join(AppConfig.dataPath, 'storage', 'works', workId);
    final imagePath =
        path.join(workDir, 'pictures', index.toString(), 'imported.png');

    final imageFile = File(imagePath);
    if (await imageFile.exists()) {
      return imagePath;
    }

    // 尝试查找其他格式
    final formats = ['.jpg', '.jpeg', '.png', '.webp'];
    for (final format in formats) {
      final originalPath =
          path.join(workDir, 'pictures', index.toString(), 'original$format');
      final originalFile = File(originalPath);
      if (await originalFile.exists()) {
        return originalPath;
      }
    }

    return null;
  }

  // 获取作品内特定图片的缩略图路径
  static Future<String?> getWorkImageThumbnailPath(
      String workId, int index) async {
    final workDir = path.join(AppConfig.dataPath, 'storage', 'works', workId);
    final thumbnailPath =
        path.join(workDir, 'pictures', index.toString(), 'thumbnail.jpg');

    final file = File(thumbnailPath);
    if (await file.exists()) {
      return thumbnailPath;
    }
    return null;
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

  // 检查作品首页缩略图是否存在
  static Future<bool> workCoverThumbnailExists(String workId) async {
    final thumbnailPath = await getWorkCoverThumbnailPath(workId);
    final file = File(thumbnailPath);
    return await file.exists();
  }
}
