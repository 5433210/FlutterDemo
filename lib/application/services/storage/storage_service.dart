import 'dart:io';

import '../../../domain/services/work_image_storage_interface.dart';
import '../../../infrastructure/storage/storage_interface.dart';

/// Storage Service Implementation
class StorageService {
  final IStorage _storage;
  final IWorkImageStorage _workImageStorage;

  StorageService({
    required IStorage storage,
    required IWorkImageStorage workImageStorage,
  })  : _storage = storage,
        _workImageStorage = workImageStorage;

  /// 创建占位图
  Future<void> createPlaceholderImage(String path) async {
    await _storage.createPlaceholderImage(path);
  }

  /// 确保目录存在
  Future<void> ensureDirectoryExists(String path) async {
    await _storage.ensureDirectoryExists(path);
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String path) async {
    return _storage.fileExists(path);
  }

  /// 获取应用数据路径
  Future<String> getAppDataPath() async {
    return _storage.getAppDataPath();
  }

  /// 获取临时目录
  Future<Directory> getTempDirectory() async {
    return _storage.getTempDirectory();
  }

  /// 获取作品封面路径
  Future<String> getWorkCoverPath(String workId) async {
    return _workImageStorage.getWorkCoverThumbnailPath(workId);
  }

  /// 获取作品图片目录
  Future<String> getWorkImageDir(String workId, String imageId) async {
    return _workImageStorage.getWorkImageDir(workId, imageId);
  }

  /// 获取作品图片缩略图路径
  Future<String> getWorkImageThumbnailPath(
      String workId, String imageId) async {
    return _workImageStorage.getWorkImageThumbnailPath(workId, imageId);
  }

  /// 获取已导入作品图片路径
  Future<String> getWorkImportedImagePath(String workId, String imageId) async {
    return _workImageStorage.getWorkImportedImagePath(workId, imageId);
  }

  /// 获取作品原始图片路径
  Future<String> getWorkOriginalImagePath(
      String workId, String imageId, String ext) async {
    return _workImageStorage.getWorkOriginalImagePath(workId, imageId, ext);
  }
}
