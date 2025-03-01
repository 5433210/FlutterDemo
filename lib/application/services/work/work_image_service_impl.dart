import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../domain/value_objects/image/work_image_info.dart';
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
      String workId, File file, int position) async {
    try {
      AppLogger.info('添加图片到作品',
          tag: 'WorkImageService',
          data: {'workId': workId, 'position': position});

      // 使用 ImageService 处理图片
      final processedImages = await _imageService.processWorkImages(
        workId,
        [file],
      );

      if (processedImages.isEmpty) {
        throw Exception('图片处理失败');
      }

      // 返回处理后的图片信息
      return processedImages.first;
    } catch (e, stack) {
      AppLogger.error('添加图片失败',
          tag: 'WorkImageService',
          error: e,
          stackTrace: stack,
          data: {'workId': workId, 'position': position});
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
  Future<File> rotateImage(File file, int angle) {
    return _imageService.rotateImage(file, angle);
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
