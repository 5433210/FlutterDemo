import 'dart:io';

import '../../../domain/models/work/work_image.dart';
import '../../../domain/repositories/work_image_repository.dart';
import '../../../infrastructure/image/image_processor.dart';
import '../storage/work_storage_service.dart';
import './service_errors.dart';

/// 作品图片服务
///
/// 职责:
/// 1. 维护图片文件与数据的一致性
/// 2. 协调存储和数据库操作
/// 3. 处理图片业务逻辑
/// 4. 管理图片生命周期
class WorkImageService with WorkServiceErrorHandler {
  final WorkStorageService _storage;
  final ImageProcessor _processor;
  final WorkImageRepository _repository;

  WorkImageService({
    required WorkStorageService storage,
    required ImageProcessor processor,
    required WorkImageRepository repository,
  })  : _storage = storage,
        _processor = processor,
        _repository = repository;

  /// 清理作品图片
  Future<void> cleanupWorkImages(String workId) async {
    return handleOperation(
      'cleanupWorkImages',
      () async {
        // 删除图片文件
        await _storage.deleteWorkDirectory(workId);

        // 删除数据库记录
        await _repository.getAllByWorkId(workId).then((images) {
          if (images.isNotEmpty) {
            final imageIds = images.map((e) => e.id).toList();
            return _repository.deleteMany(workId, imageIds);
          }
        });
      },
      data: {'workId': workId},
    );
  }

  /// 删除图片
  Future<void> deleteImage(String workId, String imageId) async {
    return handleOperation(
      'deleteImage',
      () async {
        await _storage.deleteWorkImage(workId, imageId);
        await _repository.delete(workId, imageId);
      },
      data: {'workId': workId, 'imageId': imageId},
    );
  }

  /// 批量删除图片
  Future<void> deleteImages(String workId, List<String> imageIds) async {
    return handleOperation(
      'deleteImages',
      () async {
        for (final imageId in imageIds) {
          await _storage.deleteWorkImage(workId, imageId);
        }
        await _repository.deleteMany(workId, imageIds);
      },
      data: {'workId': workId, 'count': imageIds.length},
    );
  }

  /// 导入图片
  Future<WorkImage> importImage(String workId, File file) async {
    return handleOperation(
      'importImage',
      () async {
        // 生成图片ID
        final imageId = DateTime.now().millisecondsSinceEpoch.toString();

        // 保存原始文件
        final originalPath = await _storage.saveOriginalImage(
          workId,
          imageId,
          file,
        );

        // 处理并保存导入图片
        final processedImage = await _processor.processImage(
          file,
          maxWidth: 2400,
          maxHeight: 2400,
          quality: 90,
        );
        final importedPath = await _storage.saveImportedImage(
          workId,
          imageId,
          processedImage,
        );

        // 生成并保存缩略图
        final thumbnail = await _processor.processImage(
          file,
          maxWidth: 200,
          maxHeight: 200,
          quality: 80,
        );
        final thumbnailPath = await _storage.saveThumbnail(
          workId,
          imageId,
          thumbnail,
        );

        // 获取图片信息
        final info = await _storage.getWorkImageInfo(importedPath);

        // 创建工作图片实体
        final image = WorkImage(
          id: imageId,
          workId: workId,
          path: importedPath,
          originalPath: originalPath,
          thumbnailPath: thumbnailPath,
          format: _getImageFormat(file),
          size: info['size'] ?? 0,
          width: info['width'] ?? 0,
          height: info['height'] ?? 0,
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
          index: await _getNextImageIndex(workId),
        );

        // 保存到数据库
        await _repository.create(workId, image);
        return image;
      },
      data: {'workId': workId, 'file': file.path},
    );
  }

  /// 批量导入图片
  Future<List<WorkImage>> importImages(String workId, List<File> files) async {
    return handleOperation(
      'importImages',
      () async {
        final images = <WorkImage>[];
        for (final file in files) {
          final image = await importImage(workId, file);
          images.add(image);
        }
        updateCover(workId, images.first.id);
        return await _repository.saveMany(images);
      },
      data: {'workId': workId, 'fileCount': files.length},
    );
  }

  /// 优化图片
  Future<File> optimizeImage(File file) async {
    return handleOperation(
      'optimizeImage',
      () => _processor.optimizeImage(file),
      data: {'path': file.path},
    );
  }

  /// 更新图片顺序
  Future<void> reorderImages(String workId, List<String> imageIds) async {
    return handleOperation(
      'reorderImages',
      () async {
        for (int i = 0; i < imageIds.length; i++) {
          await _repository.updateIndex(workId, imageIds[i], i);
        }
      },
      data: {'workId': workId, 'count': imageIds.length},
    );
  }

  /// 旋转图片
  Future<WorkImage> rotateImage(WorkImage image, int degrees) async {
    return handleOperation(
      'rotateImage',
      () async {
        final file = File(image.path);
        final rotated = await _processor.rotateImage(file, degrees);
        await rotated.copy(image.path);

        final thumbnail = await _processor.processImage(
          rotated,
          maxWidth: 200,
          maxHeight: 200,
          quality: 80,
        );
        await thumbnail.copy(image.thumbnailPath);

        final info = await _storage.getWorkImageInfo(image.path);
        final updated = image.copyWith(
          width: info['width'] ?? 0,
          height: info['height'] ?? 0,
          updateTime: DateTime.now(),
        );

        await _repository.saveMany([updated]);
        return updated;
      },
      data: {
        'workId': image.workId,
        'imageId': image.id,
        'degrees': degrees,
      },
    );
  }

  /// 更新封面
  Future<void> updateCover(String workId, String imageId) async {
    return handleOperation(
      'updateCover',
      () async {
        // 获取源图片
        final importedPath = _storage.getImportedPath(workId, imageId);
        final sourceFile = File(importedPath);
        if (!await sourceFile.exists()) {
          throw FileSystemException('源图片不存在', importedPath);
        }

        // 保存封面导入图
        await _storage.saveCoverImported(workId, sourceFile);

        // 生成并保存封面缩略图
        final thumbnail = await _processor.processImage(
          sourceFile,
          maxWidth: 200,
          maxHeight: 200,
          quality: 80,
        );
        await _storage.saveCoverThumbnail(workId, thumbnail);
      },
      data: {'workId': workId, 'imageId': imageId},
    );
  }

  /// 获取图片格式
  String _getImageFormat(File file) {
    return file.path.split('.').last.toLowerCase();
  }

  /// 获取下一个图片索引
  Future<int> _getNextImageIndex(String workId) async {
    return await _repository.getNextIndex(workId);
  }
}
