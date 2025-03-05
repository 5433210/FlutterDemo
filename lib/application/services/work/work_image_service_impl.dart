import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../domain/models/image/work_image_info.dart';
import '../../../domain/models/image/work_image_size.dart';
import '../../../infrastructure/logging/logger.dart';
import '../../../utils/path_helper.dart';
import '../image_service.dart';
import 'work_image_service.dart';

/// WorkImageService 的实现
class WorkImageServiceImpl implements WorkImageService {
  final ImageService _imageService;

  const WorkImageServiceImpl(this._imageService);

  @override
  Future<WorkImageInfo> addImageToWork(
      String workId, File imageFile, int index) async {
    try {
      AppLogger.debug('添加图片到作品',
          tag: 'WorkImageService',
          data: {'workId': workId, 'index': index, 'path': imageFile.path});

      // 确保工作目录存在
      await PathHelper.ensureWorkDirectoryExists(workId);

      // 创建图片目录
      final imageDirPath = await PathHelper.getWorkImagePath(workId, index);
      final dir = Directory(imageDirPath!);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 生成带时间戳的唯一文件名，避免文件名冲突
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final originalExt = path.extension(imageFile.path);

      // 安全获取原始路径
      final originalWorkPath =
          await PathHelper.getOriginalWorkPath(workId, index, originalExt);

      // 构建路径
      final String originalBasePath = path.join(
          path.dirname(originalWorkPath), 'original_$timestamp$originalExt');

      final String importedPath =
          path.join(imageDirPath, 'imported_$timestamp.png');
      final String thumbnailPath =
          path.join(imageDirPath, 'thumbnail_$timestamp.png');

      // 复制原始图片
      final originalFile = await imageFile.copy(originalBasePath);

      // 处理并优化图片
      final optimizedFile = await _imageService.optimizeImage(
        originalFile,
        maxWidth: 2048,
        maxHeight: 2048,
        quality: 85,
      );

      // 保存处理后的图片
      final importedFile = await optimizedFile.copy(importedPath);

      // 创建缩略图
      final tempThumbnail =
          await _imageService.createTempThumbnail(optimizedFile);
      final thumbnailFile = await tempThumbnail.copy(thumbnailPath);

      // 获取图片尺寸信息
      final imageBytes = await optimizedFile.readAsBytes();
      final image = await decodeImageFromList(imageBytes);

      return WorkImageInfo(
        fileSize: await optimizedFile.length(),
        format: originalExt.replaceFirst('.', ''),
        path: importedPath,
        size: WorkImageSize(
          width: image.width,
          height: image.height,
        ),
        thumbnail: thumbnailPath,
        original: originalBasePath,
      );
    } catch (e, stack) {
      AppLogger.error('添加图片到作品失败',
          tag: 'WorkImageService',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'index': index});
      rethrow;
    }
  }

  @override
  Future<void> cleanupTempImages({int maxAgeInHours = 24}) {
    return _imageService.cleanupTempImages(maxAgeInHours: maxAgeInHours);
  }

  @override
  Future<File> createTempImageFile(String originalPath,
      {String? prefix, String? suffix}) async {
    // 修复对私有方法的调用方式，改为使用我们自己的实现
    try {
      // 创建一个临时文件并返回
      final tempDir = await _getTempImageDir();

      // 生成唯一文件名
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomId = const Uuid().v4().substring(0, 8);
      final extension = path.extension(originalPath);

      // 构建文件名
      String fileName = '${prefix ?? 'temp_'}$timestamp';
      if (suffix != null && suffix.isNotEmpty) fileName += '_$suffix';
      fileName += '_$randomId$extension';

      final filePath = path.join(tempDir.path, fileName);

      // 确保目录存在
      await PathHelper.ensureDirectoryExists(path.dirname(filePath));

      // 创建并返回文件
      return File(filePath);
    } catch (e, stack) {
      AppLogger.error('创建临时图片文件失败',
          tag: 'WorkImageService',
          error: e,
          stackTrace: stack,
          data: {'originalPath': originalPath});
      rethrow;
    }
  }

  @override
  Future<String?> getImageThumbnail(String workId, int imageIndex) async {
    try {
      final thumbnailPath =
          await PathHelper.getWorkThumbnailPath(workId, imageIndex);
      if (thumbnailPath != null && await File(thumbnailPath).exists()) {
        return thumbnailPath;
      }
      return null;
    } catch (e) {
      AppLogger.warning('获取图片缩略图失败',
          tag: 'WorkImageService',
          error: e,
          data: {'workId': workId, 'index': imageIndex});
      return null;
    }
  }

  @override
  Future<String> moveToPermStorage(
      File tempFile, String workId, int imageIndex) {
    return _imageService.moveToPermStorage(tempFile, workId, imageIndex);
  }

  @override
  Future<void> processWorkImage(String workId, File file, int index) async {
    // 单独处理一张图片
    try {
      await _imageService.processWorkImages(workId, [file]);
    } catch (e, stack) {
      AppLogger.error('处理单张图片失败',
          tag: 'WorkImageService',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'index': index});
      rethrow;
    }
  }

  @override
  Future<File> rotateImage(File file, int angle,
      {bool preserveSize = false}) async {
    // 使用 ImageService 的旋转方法
    return await _imageService.rotateImage(file, angle,
        preserveSize: preserveSize);
  }

  // 实现获取临时目录的辅助方法
  Future<Directory> _getTempImageDir() async {
    final appDir = await PathHelper.getAppDataPath();
    final tempDirPath = path.join(appDir, 'temp_work_images');
    final tempDir = Directory(tempDirPath);

    // 确保目录存在
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }

    return tempDir;
  }
}
