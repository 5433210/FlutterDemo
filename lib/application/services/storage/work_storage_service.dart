import 'dart:io';

import 'package:demo/infrastructure/storage/storage_interface.dart';
import 'package:path/path.dart' as path;

import '../../../infrastructure/logging/logger.dart';

/// 作品存储服务
///
/// 职责:
/// 1. 作品文件目录管理
/// 2. 作品文件命名规则
/// 3. 文件版本管理
/// 4. 图片格式处理
class WorkStorageService {
  final IStorage _storage;

  WorkStorageService({
    required IStorage storage,
  }) : _storage = storage;

  /// 创建作品目录结构
  Future<void> createWorkDirectories(String workId) async {
    try {
      await _storage.createDirectory(getWorkPath(workId));
      await _storage.createDirectory(getWorkImagesPath(workId));
      await _storage.createDirectory(getWorkCoverPath(workId));
    } catch (e, stack) {
      _handleError(
        '创建作品目录失败',
        e,
        stack,
        data: {'workId': workId},
      );
    }
  }

  /// 删除作品目录
  Future<void> deleteWorkDirectory(String workId) async {
    try {
      final workPath = getWorkPath(workId);
      await _storage.deleteDirectory(workPath);
    } catch (e, stack) {
      _handleError(
        '删除作品目录失败',
        e,
        stack,
        data: {'workId': workId},
      );
    }
  }

  /// 删除作品图片
  Future<void> deleteWorkImage(String workId, String imageId) async {
    try {
      final imagePath = getWorkImagePath(workId, imageId);
      await _storage.deleteDirectory(imagePath);
    } catch (e, stack) {
      _handleError(
        '删除作品图片失败',
        e,
        stack,
        data: {
          'workId': workId,
          'imageId': imageId,
        },
      );
    }
  }

  /// 获取作品导入图片路径
  String getImportedPath(String workId, String imageId) =>
      path.join(getWorkImagePath(workId, imageId), 'imported.png');

  /// 获取作品元数据文件路径
  String getMetadataPath(String workId) =>
      path.join(getWorkPath(workId), 'metadata.json');

  /// 获取作品原始图片路径
  String getOriginalPath(String workId, String imageId) => path.join(
      getWorkImagePath(workId, imageId), 'original.${_getExtension(imageId)}');

  /// 获取作品缩略图路径
  String getThumbnailPath(String workId, String imageId) =>
      path.join(getWorkImagePath(workId, imageId), 'thumbnail.jpg');

  /// 获取作品封面导入图路径
  String getWorkCoverImportedPath(String workId) =>
      path.join(getWorkCoverPath(workId), 'imported.png');

  /// 获取作品封面目录路径
  String getWorkCoverPath(String workId) =>
      path.join(getWorkPath(workId), 'cover');

  /// 获取作品封面缩略图路径
  String getWorkCoverThumbnailPath(String workId) =>
      path.join(getWorkCoverPath(workId), 'thumbnail.jpg');

  /// 获取作品图片
  Future<File> getWorkImage(String path) async {
    if (!await _storage.fileExists(path)) {
      throw FileSystemException('文件不存在', path);
    }
    return File(path);
  }

  /// 获取图片信息
  Future<Map<String, int>> getWorkImageInfo(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('文件不存在', path);
    }

    return {
      'size': await file.length(),
      'width': 0, // TODO: 实现图片尺寸获取
      'height': 0,
    };
  }

  /// 获取作品图片路径
  String getWorkImagePath(String workId, String imageId) =>
      path.join(getWorkImagesPath(workId), imageId);

  /// 获取图片大小
  Future<int> getWorkImageSize(String path) => _storage.getFileSize(path);

  /// 获取作品图片目录路径
  String getWorkImagesPath(String workId) =>
      path.join(getWorkPath(workId), 'images');

  /// 获取作品目录路径
  String getWorkPath(String workId) =>
      (path.join(_storage.getAppDataPath(), 'works', workId));

  /// 检查作品图片是否存在
  Future<bool> hasWorkImage(String path) => _storage.fileExists(path);

  /// 保存作品封面导入图
  Future<String> saveCoverImported(String workId, File file) async {
    final targetPath = getWorkCoverImportedPath(workId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 保存作品封面缩略图
  Future<String> saveCoverThumbnail(String workId, File file) async {
    final targetPath = getWorkCoverThumbnailPath(workId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 保存作品导入图片
  Future<String> saveImportedImage(
    String workId,
    String imageId,
    File file,
  ) async {
    final targetPath = getImportedPath(workId, imageId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 保存作品元数据
  Future<void> saveMetadata(String workId, String content) async {
    final targetPath = getMetadataPath(workId);
    await _storage.writeFile(targetPath, content.codeUnits);
  }

  /// 保存作品原始图片
  Future<String> saveOriginalImage(
    String workId,
    String imageId,
    File file,
  ) async {
    final targetPath = getOriginalPath(workId, imageId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 保存作品缩略图
  Future<String> saveThumbnail(
    String workId,
    String imageId,
    File file,
  ) async {
    final targetPath = getThumbnailPath(workId, imageId);
    await _storage.copyFile(file.path, targetPath);
    return targetPath;
  }

  /// 获取文件扩展名
  String _getExtension(String imageId) {
    // 从图片ID或其他元数据获取扩展名
    return 'png';
  }

  /// 统一错误处理
  void _handleError(
    String message,
    Object error,
    StackTrace stack, {
    Map<String, dynamic>? data,
  }) {
    AppLogger.error(
      message,
      error: error,
      stackTrace: stack,
      tag: 'WorkStorageService',
      data: data,
    );
    throw error;
  }
}
