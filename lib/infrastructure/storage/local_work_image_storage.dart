import 'dart:io';

import 'package:path/path.dart' as path;

import '../../application/config/app_config.dart';
import '../../domain/services/work_image_storage_interface.dart';
import 'storage_interface.dart';

class LocalWorkImageStorage implements IWorkImageStorage {
  final IStorage _storage;

  LocalWorkImageStorage(this._storage);

  @override
  Future<void> deleteWorkImage(String workId, String imagePath) async {
    try {
      await _storage.deleteFile(imagePath);
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to delete work image',
        workId,
        imagePath,
        e,
      );
    }
  }

  @override
  Future<void> ensureWorkDirectoryExists(String workId) async {
    try {
      final workPath = await getWorkPath(workId);
      await _storage.ensureDirectoryExists(workPath);

      // 创建作品子目录结构
      await _storage.ensureDirectoryExists(path.join(workPath, 'pictures'));
      await _storage.ensureDirectoryExists(path.join(workPath, 'thumbnails'));

      // 确保封面目录存在
      final thumbnailPath = await getWorkCoverThumbnailPath(workId);
      await _storage.ensureDirectoryExists(path.dirname(thumbnailPath));
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to ensure work directory exists',
        workId,
        '',
        e,
      );
    }
  }

  @override
  Future<String> getWorkCoverThumbnailPath(String workId) async {
    try {
      final workDir = await getWorkPath(workId);
      final thumbnailPath = path.join(workDir, 'cover.jpg');

      // 确保父目录存在
      await _storage.ensureDirectoryExists(path.dirname(thumbnailPath));

      return thumbnailPath;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to get cover thumbnail path',
        workId,
        '',
        e,
      );
    }
  }

  @override
  Future<String> getWorkImageDir(String workId, String imageId) async {
    final workPath = await _getWorkBasePath(workId);
    return path.join(workPath, 'images', imageId);
  }

  @override
  Future<List<String>> getWorkImages(String workId) async {
    try {
      final workPath = await getWorkPath(workId);
      final directory = Directory(path.join(workPath, 'images'));

      if (!await directory.exists()) {
        return [];
      }

      final files = await directory
          .list()
          .where((entity) =>
              entity is File && !path.basename(entity.path).startsWith('.'))
          .map((entity) => entity.path)
          .toList();

      return files;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to get work images',
        workId,
        '',
        e,
      );
    }
  }

  @override
  Future<String> getWorkImageThumbnailPath(
      String workId, String imageId) async {
    try {
      final workDir = await getWorkPath(workId);
      final thumbnailPath =
          path.join(workDir, 'pictures', imageId, 'thumbnail.jpg');

      await _storage.ensureDirectoryExists(path.dirname(thumbnailPath));

      return thumbnailPath;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to get thumbnail path',
        workId,
        imageId,
        e,
      );
    }
  }

  @override
  Future<String> getWorkImportedImagePath(String workId, String imageId) async {
    try {
      final workDir = await getWorkPath(workId);
      return path.join(workDir, 'pictures', imageId, 'imported.png');
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to get imported image path',
        workId,
        imageId,
        e,
      );
    }
  }

  @override
  Future<String> getWorkOriginalImagePath(
      String workId, String imageId, String ext) async {
    try {
      final workPath = await getWorkPath(workId);
      final imagePath =
          path.join(workPath, 'pictures', imageId, 'original$ext');

      // 确保原始图片目录存在
      await _storage.ensureDirectoryExists(path.dirname(imagePath));

      return imagePath;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to get original image path',
        workId,
        imageId,
        e,
      );
    }
  }

  @override
  Future<String> getWorkPath(String workId) async {
    try {
      final appDataPath = await _storage.getAppDataPath();
      return path.join(
          appDataPath, AppConfig.storageFolder, AppConfig.worksFolder, workId);
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to get work path',
        workId,
        '',
        e,
      );
    }
  }

  @override
  Future<String> saveWorkImage(String workId, File image) async {
    try {
      final imageId = DateTime.now().millisecondsSinceEpoch.toString();
      final extension = path.extension(image.path);

      // 获取存储目录
      final imageDir = await getWorkImageDir(workId, imageId);
      await _storage.ensureDirectoryExists(imageDir);

      final targetPath = path.join(imageDir, 'original$extension');
      await image.copy(targetPath);

      return targetPath;
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to save work image',
        workId,
        image.path,
        e,
      );
    }
  }

  @override
  Future<bool> workCoverThumbnailExists(String workId) async {
    try {
      final thumbnailPath = await getWorkCoverThumbnailPath(workId);
      return await _storage.fileExists(thumbnailPath);
    } catch (e) {
      throw WorkImageStorageException(
        'Failed to check cover thumbnail exists',
        workId,
        '',
        e,
      );
    }
  }

  Future<String> _getWorkBasePath(String workId) async {
    final appDataPath = await _storage.getAppDataPath();
    return path.join(
        appDataPath, AppConfig.storageFolder, AppConfig.worksFolder, workId);
  }
}

/// Work图片存储异常
class WorkImageStorageException implements Exception {
  final String message;
  final String workId;
  final String path;
  final dynamic originalError;

  WorkImageStorageException(
      this.message, this.workId, this.path, this.originalError);

  @override
  String toString() =>
      'WorkImageStorageException: $message (workId: $workId, path: $path)';
}
